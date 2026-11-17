using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

namespace Bayan.Tests;

/// <summary>
/// 024 T12 (R3, R9): the sabk tests run through the bootstrap stage-2 driver, and the recorded reference files are re-recorded and compared byte for byte.
/// 024 T13 (R4, R5, R8): the end-to-end program sabk writes is linked with the runtime by the system linker and run.
/// Arm64 macOS only: the recorders need <c>zig cc</c>, <c>clang</c>, <c>otool</c> and <c>nm</c> on that host.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]  // BootstrapTests.Stage2Executable builds the stages; one collection runs serially, so (b) never wipes tmp/sabk under (c)
public sealed class SabkTests
{
    private static bool Supported => RuntimeInformation.IsOSPlatform(OSPlatform.OSX) && RuntimeInformation.OSArchitecture == Architecture.Arm64;

    private const string Skip = "sabk tests need arm64 macOS (024 R9)";

    private static (int Exit, string Out, string Err) RunInRoot(string program, params string[] args)
    {
        var psi = new ProcessStartInfo(program) { WorkingDirectory = Golden.RepoRoot, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result, stderr.Result);
    }

    [Fact]
    public void SabkSourceTestsPass()
    {
        if (!Supported) { Console.WriteLine(Skip); return; }
        var (exit, o, e) = RunInRoot(BootstrapTests.Stage2Executable(), "test", "--package", "src", "src/sabk");
        var passed = Regex.Match(o, @"◆ (\d+) passed");
        var failed = Regex.Match(o, @"✗ (\d+) failed");
        Assert.True(passed.Success, $"no pass count in the summary (exit {exit}):\n{o}\n{e}");
        Assert.True(int.Parse(passed.Groups[1].Value) > 0, $"no sabk test passed:\n{o}\n{e}");
        Assert.False(failed.Success && int.Parse(failed.Groups[1].Value) > 0, $"sabk tests failed:\n{o}\n{e}");
        Assert.Equal(0, exit);
    }

    [Fact]
    public void RecordedReferenceFilesAreCurrent()
    {
        if (!Supported) { Console.WriteLine(Skip); return; }
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "sabk");
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        foreach (var (script, input, tracked) in new[]
        {
            ("record-encodings.sh", "encodings.s", "encodings.tsv"),
            ("record-macho.sh", "macho.s", "macho-expected.txt"),
        })
        {
            var data = Path.Combine(Golden.RepoRoot, "src", "sabk", "testdata");
            var actual = Path.Combine(dir, tracked);
            var (exit, o, e) = RunInRoot("bash", Path.Combine(Golden.RepoRoot, "scripts", "sabk", script), Path.Combine(data, input), actual);
            Assert.True(exit == 0, $"{script} failed (exit {exit}):\n{o}\n{e}");
            Assert.True(File.ReadAllBytes(Path.Combine(data, tracked)).AsSpan().SequenceEqual(File.ReadAllBytes(actual)), $"{tracked} differs from what {script} records; re-run the script");
        }
    }

    /// <summary>(c) R8 end to end. The sabk entry <c>src/sabk/e2e.test.byn</c> writes <c>tmp/sabk/salam.o</c>; the runtime is compiled
    /// with <c>clang</c> here (not the driver's cached zig object) and both are linked by <c>clang</c>, which runs <c>/usr/bin/ld</c> and shows
    /// its warnings (R5). The program prints "Salam, world!" (<c>byn_print</c> adds the newline) and exits with 35 + 7.</summary>
    [Fact]
    public void EndToEndProgramLinksAndRuns()
    {
        if (!Supported) { Console.WriteLine(Skip); return; }
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "sabk");
        var obj = Path.Combine(dir, "salam.o");
        if (File.Exists(obj)) File.Delete(obj);
        var (exit, o, e) = RunInRoot(BootstrapTests.Stage2Executable(), "test", "--package", "src", "src/sabk", "--only", "salam.o");
        Assert.True(exit == 0 && o.Contains("◆ 1 passed"), $"the sabk e2e entry failed (exit {exit}):\n{o}\n{e}");
        Assert.True(File.Exists(obj), $"the sabk e2e entry wrote no {obj}");

        var rt = Path.Combine(dir, "bayan-rt.o");
        (exit, o, e) = RunInRoot("clang", "-c", "-O2", "-DBYN_NDEBUG", Path.Combine(Golden.RepoRoot, "runtime", "bayan-rt.c"), "-o", rt);
        Assert.True(exit == 0, $"clang -c runtime/bayan-rt.c failed (exit {exit}):\n{o}\n{e}");
        var exe = Path.Combine(dir, "salam");
        (exit, o, e) = RunInRoot("clang", obj, rt, "-o", exe);
        Assert.True(exit == 0, $"the link failed (exit {exit}):\n{o}\n{e}");
        Assert.Equal("", e);
        Assert.Equal("", o);
        (exit, o, e) = RunInRoot(exe);
        Assert.Equal("Salam, world!\n", o);
        Assert.Equal("", e);
        Assert.Equal(42, exit);

        // The same program written by hand and assembled by clang. Compared: each section's segname, sectname, align and
        // flags in load-command order (otool -l), and the sorted symbol list as section-or-undefined, linkage and name
        // (nm -m). Not compared: addresses, sizes, offsets and relocation counts, which follow from instruction choices.
        var reference = Path.Combine(dir, "salam-ref.o");
        (exit, o, e) = RunInRoot("clang", "-c", "-target", "arm64-apple-macos15", Path.Combine(Golden.RepoRoot, "src", "sabk", "testdata", "salam.s"), "-o", reference);
        Assert.True(exit == 0, $"clang -c salam.s failed (exit {exit}):\n{o}\n{e}");
        Assert.Equal(Sections(reference), Sections(obj));
        Assert.Equal(Symbols(reference), Symbols(obj));
    }

    /// <summary>One "segname sectname align flags" line per section of <c>otool -l</c>.</summary>
    private static List<string> Sections(string obj)
    {
        var (exit, o, e) = RunInRoot("otool", "-l", obj);
        Assert.True(exit == 0, $"otool -l {obj} failed:\n{e}");
        var result = new List<string>();
        Dictionary<string, string>? section = null;
        foreach (var raw in o.Split('\n'))
        {
            var line = raw.Trim();
            if (line == "Section") { section = new(); continue; }
            if (section is null) continue;
            var m = Regex.Match(line, @"^(sectname|segname|align|flags) (.*)$");
            if (!m.Success) continue;
            section[m.Groups[1].Value] = m.Groups[2].Value;
            if (m.Groups[1].Value == "flags")
            {
                result.Add($"{section["segname"]} {section["sectname"]} {section["align"]} {section["flags"]}");
                section = null;
            }
        }
        Assert.NotEmpty(result);
        return result;
    }

    /// <summary><c>nm -m</c> lines without the address column, sorted: "(__TEXT,__text) external _main".</summary>
    private static List<string> Symbols(string obj)
    {
        var (exit, o, e) = RunInRoot("nm", "-m", obj);
        Assert.True(exit == 0, $"nm -m {obj} failed:\n{e}");
        var result = o.Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(l => Regex.Replace(l, @"^[0-9a-f]*\s+", "")).ToList();
        result.Sort(StringComparer.Ordinal);
        Assert.NotEmpty(result);
        return result;
    }
}
