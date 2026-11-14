using System.Diagnostics;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>Runtime functions driven directly from C (<c>tests/native/*.c</c>, built against <c>bayan-rt.c</c>), and <c>Io.runBatch</c> on Windows.</summary>
public sealed class RuntimeNativeTests
{
    [Fact]
    public void BatchCommandLine()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "batch-cmdline.c"));
        Assert.Equal(
            """"
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "a b""
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" """
            refused
            refused
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "^&|<>()!""
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "a\""
            refused
            refused
            refused
            cmd.exe /d /e:ON /v:OFF /s /c ""C:\dir\X.CMD" "a""
            cmd.exe /d /e:ON /v:OFF /s /c ""./run.Bat" "a""
            refused
            refused
            refused
            cmd.exe /d /e:ON /v:OFF /s /c "".\x.bat" "a""
            cmd.exe /d /e:ON /v:OFF /s /c ""C:\x\y.cmd" "a""
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "x" "y z""
            cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd""
            refused

            """".ReplaceLineEndings("\n"),
            Run(Build(driver), []).Replace("\r\n", "\n"));
    }

    /// <summary>Each argument reaches the batch file as <c>%~N</c> unchanged.</summary>
    [Fact]
    public void RunBatchRoundTrips()
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "native", "run-batch");
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        var script = Path.Combine(work, "echo.cmd");
        File.WriteAllText(script, "@echo off\r\necho \"%~1\"\r\necho \"%~2\"\r\necho \"%~3\"\r\necho \"%~4\"\r\n");
        var program = $$"""
            void main() fails IoError {
                let args: string[4] = ["a b", "", "^&|<>()!", "a\\"]
                let r = try Io.runBatch("{{script.Replace("\\", "\\\\")}}", args.span)
                print($"exit {r.exitCode}")
                Io.stdout.write(r.stdout)
            }
            """;
        var c = Compilation.Create([SourceText.FromString("run-batch.byn", program)], work);
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        if (!OperatingSystem.IsWindows()) return;
        Assert.Equal("exit 0\n\"a b\"\n\"\"\n\"^&|<>()!\"\n\"a\\\"\n", Run(Build(CliApp.EmitC(c, BuildMode.Debug)), []).Replace("\r\n", "\n"));
    }

    /// <summary>
    /// Plan 007 step 8: <c>Io.run(…, timeout:)</c> on Windows terminates the child's Job object, so a background grandchild that
    /// holds the pipes (<c>start /b</c>) dies with it and the call returns <c>.timeout</c> long before either ping ends.
    /// </summary>
    [Fact]
    public void RunTimeoutKillsTheJob()
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "native", "run-timeout");
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        var program = """
            void main() {
                let args: string[2] = ["/c", "start /b ping -n 30 127.0.0.1 & ping -n 30 127.0.0.1"]
                let r = Io.run("cmd", args.span, timeout: Millis(200)) catch switch {
                    .timeout(let after, _, _) => {
                        print($"timeout {i64(after)}")
                        return
                    },
                    IoError e => {
                        print($"io {e}")
                        return
                    },
                }
                print($"exit {r.exitCode}")
            }
            """;
        var c = Compilation.Create([SourceText.FromString("run-timeout.byn", program)], work);
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        if (!OperatingSystem.IsWindows()) return;
        var exe = Build(CliApp.EmitC(c, BuildMode.Debug));
        var clock = Stopwatch.StartNew();
        Assert.Equal("timeout 200\n", Run(exe, []).Replace("\r\n", "\n"));
        Assert.True(clock.Elapsed < TimeSpan.FromSeconds(20), $"took {clock.Elapsed}");
    }

    /// <summary>
    /// The timeout also holds when the child ends in time but a background grandchild in its Job object keeps the pipes open
    /// (<c>start /b</c>): the drains get the same deadline, then the job is terminated.
    /// </summary>
    [Fact]
    public void RunTimeoutKillsTheJobAfterTheChildExits()
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "native", "run-timeout-exited");
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        var program = """
            void main() {
                let args: string[2] = ["/c", "start /b ping -n 30 127.0.0.1"]
                let r = Io.run("cmd", args.span, timeout: Millis(200)) catch switch {
                    .timeout(let after, _, _) => {
                        print($"timeout {i64(after)}")
                        return
                    },
                    IoError e => {
                        print($"io {e}")
                        return
                    },
                }
                print($"exit {r.exitCode}")
            }
            """;
        var c = Compilation.Create([SourceText.FromString("run-timeout-exited.byn", program)], work);
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        if (!OperatingSystem.IsWindows()) return;
        var exe = Build(CliApp.EmitC(c, BuildMode.Debug));
        var clock = Stopwatch.StartNew();
        Assert.Equal("timeout 200\n", Run(exe, []).Replace("\r\n", "\n"));
        Assert.True(clock.Elapsed < TimeSpan.FromSeconds(20), $"took {clock.Elapsed}");
    }

    /// <summary>
    /// After the deadline the drain joins are bounded even when <c>TerminateJobObject</c> fails and the tree runs on: the runtime
    /// is built with that call failing (<c>tests/native/run-terminate-fails.c</c>), and the call is <c>other</c> (5) well before
    /// the pings end. Windows only; elsewhere only the replaced text is checked.
    /// </summary>
    [Fact]
    public void RunTimeoutBoundsTheJoinsWhenTerminateFails()
    {
        const string terminate = "if (!TerminateJobObject(job, 1) ||";
        var runtime = Toolchain.RuntimeSource;
        Assert.Equal(1, runtime.Split(terminate).Length - 1);
        if (!OperatingSystem.IsWindows()) return;
        var compiler = Toolchain.FindCompiler();
        Assert.NotNull(compiler);
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "native", "run-terminate-fails");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        File.Copy(Path.Combine(Golden.RepoRoot, "tests", "native", "run-terminate-fails.c"), Path.Combine(dir, "main.c"));
        File.WriteAllText(Path.Combine(dir, "bayan-rt.c"), runtime.Replace(terminate, "if (true ||"));
        File.WriteAllText(Path.Combine(dir, "bayan-rt.h"), Toolchain.RuntimeHeader);
        var cc = new ProcessStartInfo(compiler[0]) { WorkingDirectory = dir, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in compiler[1..]) cc.ArgumentList.Add(a);
        foreach (var a in new[] { "-std=c11", "-w", "-O0", "-I.", "main.c", "bayan-rt.c", "-o", "program.exe", "-lshell32" }) cc.ArgumentList.Add(a);
        using (var p = Process.Start(cc)!)
        {
            var stdout = p.StandardOutput.ReadToEndLf();
            var stderr = p.StandardError.ReadToEndLf();
            p.WaitForExit();
            Assert.True(p.ExitCode == 0, stdout + stderr);
        }
        Assert.Equal("result 5 in time 1\n", Run(Path.Combine(dir, "program.exe"), []).Replace("\r\n", "\n"));
    }

    /// <summary>
    /// POSIX <c>Io.run</c> edges (<c>tests/native/io-run-posix.c</c>): a child that leaves its process group is signalled
    /// itself, so a 300 ms timeout ends in time; <c>timeout: Millis(i64.max)</c> never passes, so a child that exits at once
    /// reports exit 0; a deleted working directory does not stop <c>sh</c> on an absolute PATH, even after an empty entry;
    /// a child that leaves its group while a helper keeps the group alive is still signalled and reaped.
    /// </summary>
    [Fact]
    public void RunPosixEdges()
    {
        if (OperatingSystem.IsWindows()) return;
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "io-run-posix.c"));
        Assert.Equal(
            "left group: 11 in time 1\n" +
            "left group with helper: 11 in time 1 child gone 1\n" +
            "longest timeout: 0 code 0\n" +
            "deleted directory: 0 code 0\n" +
            "deleted directory, empty PATH entry: 0 code 0\n",
            Run(Build(driver), []));
    }

    /// <summary>
    /// L031: <c>byn_wait_status</c> never makes up an exit code. A failed wait or exit-code query is <c>other</c> whatever the raw
    /// status (0, or 259 = <c>STILL_ACTIVE</c>); a timeout is <c>timeout</c> with the detail untouched; a real SIGKILL status
    /// (POSIX only) is <c>signaled</c> with detail 9; exit 3 is 0 with code 3.
    /// </summary>
    [Fact]
    [Trait("Law", "L031")]
    public void WaitStatusMapping()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "wait-status.c"));
        Assert.Equal(
            "failed raw 0: 5 code -1 detail -1\n" +
            "query failed raw 259: 5 code -1 detail -1\n" +
            "failed raw 259: 5 code -1 detail -1\n" +
            "timed out: 11 code -1 detail -1\n" +
            (OperatingSystem.IsWindows() ? "" : "signaled: 10 code -1 detail 9\n") +
            "exit 3: 0 code 3 detail -1\n",
            Run(Build(driver), []).Replace("\r\n", "\n"));
    }

    /// <summary>A 0-byte request is out of memory to an allocator whose <c>realloc</c> returns NULL for it.</summary>
    [Fact]
    public void EmptyInputAsksNoZeroByteBlock()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "zero-resize.c"));
        Assert.Equal("hex 0, zero-byte requests 0\n", Run(Build(driver), []).Replace("\r\n", "\n"));
    }

    /// <summary>A growing <c>StrBuf</c> never frees or overwrites a block it outgrew: <c>append</c> after <c>finish()</c> is allowed (Q745).</summary>
    [Fact]
    public void StrBufGrowthKeepsTheOldBlock()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "strbuf-grow.c"));
        Assert.Equal("cap 128, taken text unchanged 1, old blocks handed back 0\n", Run(Build(driver), []).Replace("\r\n", "\n"));
    }

    /// <summary>
    /// <c>Io.readText</c>, <c>Io.stdin.readAll</c> and <c>Io.stdin.readAllBytes</c> release their buffer when the bytes are not UTF-8 or
    /// the read fails (a directory, as a file and as stdin). The heap is measured on macOS and glibc only.
    /// </summary>
    [Fact]
    public void FailedReadReleasesItsBuffer()
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "native", "io-read-release");
        Directory.CreateDirectory(work);
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "io-read-release.c"));
        var output = Run(Build(driver), [Path.Combine(work, "invalid.bin"), work]).Replace("\r\n", "\n");
        if (output == "unsupported\n")
        {
            Assert.True(OperatingSystem.IsWindows() || !OperatingSystem.IsMacOS() && !OperatingSystem.IsLinux() || IsMusl(), "heap introspection is missing on macOS or glibc Linux");
            return;
        }
        Assert.Equal("file 3 leaked 0, stdin 3 leaked 0, dir failed 1 leaked 0, dir stdin failed 1 leaked 0\n", output);
    }

    private static bool IsMusl() => OperatingSystem.IsLinux() && Directory.GetFiles("/lib", "ld-musl-*").Length > 0;

    /// <summary>A built program whose standard input is a directory: <c>Io.stdin.readAllBytes()</c> fails and the <c>catch</c> branch runs (prints -1).</summary>
    [Fact]
    public void StdinFromDirectoryTakesTheCatchBranch()
    {
        if (OperatingSystem.IsWindows()) return;
        const string program = """
            i64 count() {
                let bytes = Io.stdin.readAllBytes() catch {
                    return -1
                }
                return bytes.length
            }
            print($"{count()}")
            """;
        var c = Compilation.Create([SourceText.FromString("stdin-dir.byn", program)], Path.Combine(Golden.RepoRoot, "tmp"));
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var exe = Build(CliApp.EmitC(c, BuildMode.Debug));
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "native", "io-read-release");
        Directory.CreateDirectory(dir);
        var psi = new ProcessStartInfo("/bin/sh") { RedirectStandardOutput = true, UseShellExecute = false };
        psi.ArgumentList.Add("-c");
        psi.ArgumentList.Add("\"$0\" < \"$1\"");
        psi.ArgumentList.Add(exe);
        psi.ArgumentList.Add(dir);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndLf();
        p.WaitForExit();
        Assert.Equal(0, p.ExitCode);
        Assert.Equal("-1\n", stdout);
    }

    /// <summary><c>replace</c> with items read from the list itself releases the copy it takes of them.</summary>
    [Fact]
    public void AliasingReplaceReleasesItsCopy()
    {
        const string program = """
            var xs = List<i64>()
            xs.append(1)
            xs.append(2)
            xs.replace(at: 0..1, by: xs.span[1..2])
            print($"{xs[0]} {xs[1]}")
            """;
        var c = Compilation.Create([SourceText.FromString("replace.byn", program)], Path.Combine(Golden.RepoRoot, "tmp"));
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var code = CliApp.EmitC(c, BuildMode.Debug);
        const string counters = """
            #include <stdio.h>
            #include <stdlib.h>
            static int live_copies;
            static void report(void) { printf("live %d\n", live_copies); }
            static void* counted_copy(const void* p, int64_t n, byn_alloc* to) {
                if (live_copies++ == 0) atexit(report);
                return byn_copy_bytes(p, n, to);
            }
            static void counted_release(byn_alloc* from, void* p) {
                live_copies--;
                byn_release(from, p);
            }

            """;
        Assert.Contains("byn_copy_bytes(items.ptr", code);
        code = code.Replace("#include \"bayan-rt.h\"\n", "#include \"bayan-rt.h\"\n" + counters)
            .Replace("byn_copy_bytes(items.ptr", "counted_copy(items.ptr").Replace("byn_release(l->alloc", "counted_release(l->alloc");
        Assert.Equal("2 2\nlive 0\n", Run(Build(code), []).Replace("\r\n", "\n"));
    }

    /// <summary><c>byn_cov_flush</c> runs once when a panic aborts the program.</summary>
    [Fact]
    public void CovFlushRunsOnPanic()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "cov-flush.c"));
        var psi = new ProcessStartInfo(Build(driver)) { RedirectStandardOutput = true, StandardOutputEncoding = System.Text.Encoding.UTF8, RedirectStandardError = true, StandardErrorEncoding = System.Text.Encoding.UTF8, UseShellExecute = false };
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndLf();
        p.StandardError.ReadToEndLf();
        p.WaitForExit();
        Assert.NotEqual(0, p.ExitCode);
        Assert.Equal("flushed\n", stdout.Replace("\r\n", "\n"));
    }

    /// <summary>Seeded random checks of float and int formatting, UTF-8, search, sort, maps and hex against reference models.</summary>
    [Fact]
    public void RuntimePropertiesHold()
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "native", "runtime-properties.c"));
        Assert.Equal("ok\n", Run(Build(driver), []).Replace("\r\n", "\n"));
    }

    /// <summary>
    /// Q1227: <c>Io.run(…, timeout:)</c> keeps a stream as the C# test runner's <c>BoundedCapture</c> does. The same bytes, read by
    /// <c>cat</c> through the runtime and by <c>BoundedCapture.ReadAsync</c>, give the same text: empty, exactly the bound, one byte
    /// over it, and a character cut at both ends of the bound.
    /// </summary>
    [Fact]
    public async Task RunCaptureMatchesBoundedCapture()
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "native", "run-capture");
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        var program = """
            void main(ReadOnlySpan<string> args) fails IoError {
                let cat: string[1] = [args[0]]
                let r = try Io.run("cat", cat.span, timeout: Millis(60000))
                Io.stdout.write(r.stdout)
            }
            """;
        var c = Compilation.Create([SourceText.FromString("run-capture.byn", program)], work);
        Assert.False(c.Diagnostics.HasErrors, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        if (OperatingSystem.IsWindows()) return;
        var exe = Build(CliApp.EmitC(c, BuildMode.Debug));
        var keep = BoundedCapture.Keep;
        var cut = System.Text.Encoding.UTF8.GetBytes(new string('a', keep - 1) + "é" + new string('b', 70000) + "é" + new string('c', keep - 1));
        foreach (var bytes in new[] { Array.Empty<byte>(), "xy"u8.ToArray().Concat(new byte[2 * keep - 2].Select(_ => (byte)'z')).ToArray(), new byte[2 * keep + 1].Select(_ => (byte)'q').ToArray(), cut })
        {
            var file = Path.Combine(work, "stream.bin");
            File.WriteAllBytes(file, bytes);
            Assert.Equal(await BoundedCapture.ReadAsync(new MemoryStream(bytes)), Run(exe, [file]));
        }
    }

    private static string Build(string cSource)
    {
        var build = Toolchain.Build(cSource, BuildMode.Debug);
        Assert.True(build.Succeeded, build.Errors);
        return build.ExecutablePath!;
    }

    private static string Run(string exe, string[] args)
    {
        var psi = new ProcessStartInfo(exe) { RedirectStandardOutput = true, StandardOutputEncoding = System.Text.Encoding.UTF8, UseShellExecute = false };
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndLf();
        p.WaitForExit();
        Assert.Equal(0, p.ExitCode);
        return stdout;
    }
}
