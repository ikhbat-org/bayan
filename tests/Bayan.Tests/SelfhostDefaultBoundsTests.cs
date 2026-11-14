using System.Diagnostics;
using System.Text.RegularExpressions;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 017 T16 (R7): the rows of <c>CliMemoryBoundsTests</c> run through the bootstrap stage-2 driver (<c>BootstrapTests.Stage2Executable</c>), with the C# bounds. Each row that has an
/// argv runs it on the C# <c>bayan</c> and on the driver in two trees and compares exit, stdout, stderr and the files left; the
/// bound itself (peak memory, names kept, names swept) is asserted on the driver's tree. A row with no driver entry point is a
/// skip that names the Question; no bound is weakened. The three delegated rows (M4, the two M5 evict rows) run the T12 and T9 classes,
/// which use the stage-1 <c>SelfhostDriverHarness</c> driver (Q1228).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]  // the M4/M5 rows delegate to the T9 and T12 classes, which set BAYAN_CACHE in this process
public sealed class SelfhostDefaultBoundsTests
{
    private static string Fresh(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "selfhost-bounds", name);
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        return dir;
    }

    private sealed record Run(int Exit, string Out, string Err, long Peak);

    /// <summary>The C# <c>bayan</c> (its assembly under <c>dotnet</c>) or the bootstrap stage-2 driver in <paramref name="cwd"/>, <c>BAYAN_CACHE</c> = <c>&lt;cwd&gt;/cache</c>, sampling the peak working set.</summary>
    private static Run Start(bool driver, string cwd, (string Name, string? Value)[] env, params string[] args)
    {
        var psi = new ProcessStartInfo(driver ? BootstrapTests.Stage2Executable() : "dotnet") { WorkingDirectory = cwd };
        if (!driver) psi.ArgumentList.Add(typeof(CliApp).Assembly.Location);
        psi.Environment["BAYAN_CACHE"] = Path.Combine(cwd, "cache");
        psi.Environment.Remove("BAYAN_CC");
        foreach (var (name, value) in env)
            if (value is null) psi.Environment.Remove(name); else psi.Environment[name] = value;
        foreach (var a in args) psi.ArgumentList.Add(a);
        var (exit, stdout, stderr, peak) = PeakSampler.Run(psi);
        return new(exit, stdout, stderr, peak);
    }

    private static string Masked(string text, string root) => Regex.Replace(text.Replace(root, "<root>"), @"[0-9]+\.[0-9]{2}s", "<t>s");

    private static string Names(string root) => !Directory.Exists(root) ? "" : string.Join("\n",
        Directory.EnumerateFileSystemEntries(root, "*", SearchOption.AllDirectories)
            .Select(p => Path.GetRelativePath(root, p).Replace('\\', '/')).Order(StringComparer.Ordinal));

    /// <summary>The same argv on the C# tree and the driver tree (each seeded by <paramref name="seed"/>); returns both runs and both roots.</summary>
    private static (Run Cs, Run S2, string A, string B) Same(string name, Action<string> seed, (string Name, string? Value)[] env, string[] args, bool names = true)
    {
        var dir = Fresh(name);
        var a = Path.Combine(dir, "cs");
        var b = Path.Combine(dir, "s2");
        foreach (var root in new[] { a, b })
        {
            Directory.CreateDirectory(root);
            seed(root);
        }
        (string, string?)[] For(string root) => [.. env.Select(e => (e.Name, e.Value?.Replace("<root>", root)))];
        var expected = Start(false, a, For(a), args);
        var actual = Start(true, b, For(b), args);
        var label = $"{name}: {string.Join(' ', args)}";
        Assert.True(expected.Exit == actual.Exit, $"exit of `{label}`: C# {expected.Exit}, driver {actual.Exit}\n{expected.Err}\n{actual.Err}");
        SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Masked(expected.Out, a), Masked(actual.Out, b));
        SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", Masked(expected.Err, a), Masked(actual.Err, b));
        if (names) SelfhostEmitterHarness.AssertSame($"names of `{label}`", Names(a), Names(b));
        return (expected, actual, a, b);
    }

    private static (string, string?)[] NoEnv => [];

    // ── M1 ───────────────────────────────────────────────────────────────────────


    /// <summary>CliMemoryBoundsTests.M1_ATestPrintingUntilKilledStaysSmallAndReportsTheElidedBytes: peak bound 300 MB, the C#'s exit code, the elision line.</summary>
    private static Run Spam(bool driver)
    {
        var spam = "void main() {\n}\n\ntest \"spam\" {\n    while true {\n" +
            "        print(\"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\")\n" +
            "    }\n}\n";
        var root = Fresh(driver ? "spam-s2" : "spam-cs");
        File.WriteAllText(Path.Combine(root, "main.byn"), spam);
        var run = Start(driver, root, [("BAYAN_TEST_TIMEOUT_MS", TestTime.Scale(3000).ToString())], "test", "main.byn");
        Assert.True(run.Peak > 0, "no sample");
        Assert.True(run.Peak < 300L * 1024 * 1024, $"peak working set {run.Peak / 1024 / 1024} MB");
        Assert.Equal(CliApp.ExitTestFailure, run.Exit);
        Assert.Matches(@"… \d+ bytes omitted …", run.Out);
        return run;
    }

    /// <summary>The C# side of the row, the oracle the driver row is held to.</summary>
    [Fact]
    public void M1_TheCSharpTestPrintingUntilKilledStaysSmallAndReportsTheElidedBytes() => Spam(driver: false);

    /// <summary>The driver row (Q1227): stage 2's <c>Io.run</c> keeps a head and a tail, so a test printing until killed stays under the bound.</summary>
    [Fact]
    public void M1_ATestPrintingUntilKilledStaysSmallAndReportsTheElidedBytes() => Spam(driver: true);


    // ── M2 ───────────────────────────────────────────────────────────────────────
    // listed skip: M2_DiscardedOutputIsDrainedWithoutBuffering. Q1220: MutationRunner.Drain is reached by test --mutate, which the driver refuses until T13.


    // ── M3 ───────────────────────────────────────────────────────────────────────

    /// <summary>CliMemoryBoundsTests.M3_FormatSkipsScratchDirectoriesAndOutwardLinks: scratch directories and links outward are not walked.</summary>
    [Fact]
    public void M3_FormatSkipsScratchDirectoriesAndOutwardLinks()
    {
        if (OperatingSystem.IsWindows()) return;
        const string Unformatted = "let a = true\nunless !a { print(\"y\") }\n";
        void Seed(string root)
        {
            var fixture = Path.Combine(root, "fixture");
            var outside = Path.Combine(root, "outside");
            foreach (var file in new[] { ".worktrees/x/a.byn", "tmp/b.byn", "src/ok.byn" }.Select(f => Path.Combine(fixture, f)).Append(Path.Combine(outside, "c.byn")))
            {
                Directory.CreateDirectory(Path.GetDirectoryName(file)!);
                File.WriteAllText(file, Unformatted);
            }
            Directory.CreateSymbolicLink(Path.Combine(fixture, "link"), outside);
            Directory.CreateSymbolicLink(Path.Combine(fixture, "inner-link"), Path.Combine(fixture, "tmp"));
        }
        var (cs, s2, a, _) = Same("format", Seed, NoEnv, ["format", "--check", "fixture"]);
        // The in-process C# on the same tree: the same exit and the same single file as the C# process.
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(["format", "--check", Path.Combine(a, "fixture")], stdout, stderr);
        Assert.Equal(cs.Exit, exit);
        Assert.EndsWith("src/ok.byn\n", stdout.ToString().ReplaceLineEndings("\n") + stderr.ToString().ReplaceLineEndings("\n"));
        foreach (var run in new[] { cs, s2 })
        {
            var output = run.Out + run.Err;
            Assert.Equal(CliApp.ExitFailure, run.Exit);
            Assert.Contains("ok.byn", output);
            Assert.DoesNotContain("a.byn", output);
            Assert.DoesNotContain("b.byn", output);
            Assert.DoesNotContain("c.byn", output);
            Assert.DoesNotContain("inner-link", output);
        }
    }

    /// <summary>CliMemoryBoundsTests.M3_FormatAndAuditFindFilesUnderNestedBuildNamedDirectories.</summary>
    [Fact]
    public void M3_FormatAndAuditFindFilesUnderNestedBuildNamedDirectories()
    {
        void Seed(string root)
        {
            var file = Path.Combine(root, "src", "bin", "x.byn");
            Directory.CreateDirectory(Path.GetDirectoryName(file)!);
            File.WriteAllText(file, "unsafe void poke() {\n}\nlet a = true\nunless !a { print(\"y\") }\n");
        }
        var (_, format, _, _) = Same("nested-bin-format", Seed, NoEnv, ["format", "--check", "."]);
        Assert.Contains("x.byn", format.Out + format.Err);
        var (_, audit, _, _) = Same("nested-bin-audit", Seed, NoEnv, ["audit", "."]);
        Assert.Contains("unsafe void poke()", audit.Out);
    }

    // ── M5 ───────────────────────────────────────────────────────────────────────

    private static void Arithmetic(string root) => File.Copy(Path.Combine(Golden.CasesRoot, "run", "arithmetic.byn"), Path.Combine(root, "arithmetic.byn"));

    /// <summary>CliMemoryBoundsTests.M5_ABuildTrimsTheCacheToTheCap: <c>BAYAN_CACHE_MAX_MB</c> 1 over three 600 kB entries leaves the new entry and not the two oldest.</summary>
    [Fact]
    public void M5_ABuildTrimsTheCacheToTheCap()
    {
        void Seed(string root)
        {
            Arithmetic(root);
            var programs = Path.Combine(root, "cache", "v1", "programs");
            for (var i = 0; i < 3; i++)
            {
                var entry = Path.Combine(programs, "old" + i);
                Directory.CreateDirectory(entry);
                File.WriteAllBytes(Path.Combine(entry, "program"), new byte[600_000]);
                Directory.SetLastWriteTimeUtc(entry, DateTime.UtcNow.AddHours(-3 + i));
            }
        }
        var (cs, s2, a, b) = Same("evict-build", Seed, [("BAYAN_CACHE_MAX_MB", "1")], ["build", "arithmetic.byn"]);
        Assert.Equal(0, cs.Exit);
        Assert.Equal(0, s2.Exit);
        foreach (var root in new[] { a, b })
        {
            var left = Directory.GetDirectories(Path.Combine(root, "cache", "v1", "programs")).Select(d => Path.GetFileName(d)!).ToArray();
            // CliMemoryBoundsTests.cs:290 `Assert.Contains(build.Key!, left)`: the entry just built is the one directory that is not an old one.
            Assert.Single(left, n => !n.StartsWith("old", StringComparison.Ordinal));
            Assert.DoesNotContain("old0", left);
            Assert.DoesNotContain("old1", left);
        }
    }

    /// <summary>
    /// CliMemoryBoundsTests.M5_ABuildTagsTheCacheDataItOwnsAsACacheDirectory: <c>v1/CACHEDIR.TAG</c> with the signature, nothing loose in the
    /// cache root, <c>v1/</c> holding that one file after a script is remembered (a <c>#!</c> script through <c>run</c>), and the tag written
    /// again after a delete on a build hit and on a remembered-script lookup.
    /// </summary>
    [Fact]
    public void M5_ABuildTagsTheCacheDataItOwnsAsACacheDirectory()
    {
        var dir = Fresh("cachedir-tag");
        string[] roots = [Path.Combine(dir, "cs"), Path.Combine(dir, "s2")];
        foreach (var root in roots)
        {
            Directory.CreateDirectory(root);
            Arithmetic(root);
            Directory.CreateDirectory(Path.Combine(root, "sh"));
            File.WriteAllText(Path.Combine(root, "sh", "script.byn"), "#!/usr/bin/env bayan\nprint(\"hi\")\n");
        }
        for (var side = 0; side < 2; side++)
        {
            var root = roots[side];
            var v1 = Path.Combine(root, "cache", "v1");
            var tag = Path.Combine(v1, "CACHEDIR.TAG");
            Assert.Equal(0, Start(side == 1, root, NoEnv, "build", "arithmetic.byn").Exit);
            Assert.StartsWith("Signature: 8a477f597d28d172789f06886806bc55\n", File.ReadAllText(tag));
            Assert.Empty(Directory.GetFiles(Path.Combine(root, "cache")));
            var remembered = Start(side == 1, root, NoEnv, "run", "sh/script.byn");
            Assert.Equal(0, remembered.Exit);
            Assert.Empty(Directory.GetFiles(Path.Combine(root, "cache")));
            Assert.Single(Directory.GetFiles(v1));
            File.Delete(tag);
            var again = Start(side == 1, root, NoEnv, "build", "--verbose", "arithmetic.byn");
            Assert.Contains("from cache", again.Out + again.Err);
            Assert.True(File.Exists(tag));
            File.Delete(tag);
            // A build hit writes the tag too; only a lookup hit leaves the script pointer alone (a miss remembers it again).
            var pointer = Directory.GetFiles(Path.Combine(v1, "scripts")).Single();
            var old = new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            File.SetLastWriteTimeUtc(pointer, old);
            Assert.Equal(0, Start(side == 1, root, NoEnv, "run", "sh/script.byn").Exit);
            Assert.Equal(old, File.GetLastWriteTimeUtc(pointer));
            Assert.True(File.Exists(tag));
        }
        // The script key hashes the compiler build, which differs by design (Q1148); the rest of the names are compared.
        string Unkeyed(string root) => Regex.Replace(Names(root), @"scripts/[0-9a-f]{64}", "scripts/<key>");
        SelfhostEmitterHarness.AssertSame("names", Unkeyed(roots[0]), Unkeyed(roots[1]));
    }

    /// <summary>CliMemoryBoundsTests.M5_TheProgramCacheIsTrimmedLeastRecentlyUsedFirst, through the T9 row that compares the driver's <c>evict</c> with <see cref="Toolchain.Evict"/> on the same layout.</summary>
    [Fact]
    public void M5_TheProgramCacheIsTrimmedLeastRecentlyUsedFirst() => new SelfhostDefaultT9Tests().EvictTrimsTheOldestFirstAsToolchain();

    /// <summary>CliMemoryBoundsTests.M5_AnEntryUsedJustNowIsNotEvicted, through the T9 rows that compare the driver's <c>evict</c> with <see cref="Toolchain.Evict"/>.</summary>
    [Theory]
    [InlineData("1", 0)]
    [InlineData("1", 120)]
    [InlineData("2", 120)]
    public void M5_AnEntryUsedJustNowIsNotEvicted(string maxBytes, int minutes) => new SelfhostDefaultT9Tests().EvictKeepsAnEntryUsedJustNowAsToolchain(maxBytes, minutes);

    // ── M4 ───────────────────────────────────────────────────────────────────────

    /// <summary>CliMemoryBoundsTests.M4_InputsHashDoesNotFollowLinks, through the T12 row that runs <c>dist</c> on both sides and compares the printed inputs hash with and without links.</summary>
    [Fact]
    public void M4_InputsHashDoesNotFollowLinks() => new SelfhostDefaultT12Tests().TheInputsHashDoesNotFollowLinks();

    // ── M6, F13 ──────────────────────────────────────────────────────────────────

    /// <summary>
    /// CliMemoryBoundsTests.M6_StaleTemporaryDirectoriesAreSweptAndFreshOnesKept and F13_AStagingDirectoryLivesAsLongAsTheCompileTimeoutPlusTenMinutes
    /// through a build: stale <c>bayan-coverage-</c>/<c>-mutate-</c>/<c>-asan-</c> directories under <c>TMPDIR</c> and staging older than the
    /// timeout plus ten minutes go; fresh ones and a running one stay.
    /// </summary>
    [Theory]
    [InlineData(null)]
    [InlineData("7200")]
    public void M6_AndF13_ABuildSweepsStaleDirectories(string? timeout)
    {
        string[] seeded = ["bayan-coverage-old/", "bayan-mutate-old/", "bayan-asan-old/", "bayan-coverage-new/"];
        void Seed(string root)
        {
            Arithmetic(root);
            var temp = root + "-tmp";
            TestDirs.Delete(temp);
            foreach (var d in seeded) Directory.CreateDirectory(Path.Combine(temp, d));
            foreach (var d in new[] { "bayan-coverage-old", "bayan-mutate-old", "bayan-asan-old" })
                Directory.SetLastWriteTimeUtc(Path.Combine(temp, d), DateTime.UtcNow.AddHours(-2));
            var staging = Path.Combine(root, "cache", "v1", "tmp");
            foreach (var (key, minutes) in new[] { ("key-old", 180), ("key-running", 125), ("key-new", 0) })
            {
                Directory.CreateDirectory(Path.Combine(staging, key));
                Directory.SetLastWriteTimeUtc(Path.Combine(staging, key), DateTime.UtcNow.AddMinutes(-minutes));
            }
        }
        var (_, _, a, b) = Same($"sweep-{timeout}", Seed, [("TMPDIR", "<root>-tmp"), ("TMP", "<root>-tmp"), ("TEMP", "<root>-tmp"), ("BAYAN_CC_TIMEOUT_S", timeout)], ["build", "arithmetic.byn"], names: false);
        foreach (var root in new[] { a, b })
        {
            Assert.All(new[] { "bayan-coverage-old", "bayan-mutate-old", "bayan-asan-old" }, n => Assert.False(Directory.Exists(Path.Combine(root + "-tmp", n)), n));
            Assert.True(Directory.Exists(Path.Combine(root + "-tmp", "bayan-coverage-new")));
            var staging = Path.Combine(root, "cache", "v1", "tmp");
            Assert.Equal(timeout == "7200", Directory.Exists(Path.Combine(staging, "key-running")));
            Assert.False(Directory.Exists(Path.Combine(staging, "key-old")));
            Assert.True(Directory.Exists(Path.Combine(staging, "key-new")));
        }
    }

    // ── M7 ───────────────────────────────────────────────────────────────────────


    // ── F2 ───────────────────────────────────────────────────────────────────────

    /// <summary>CliMemoryBoundsTests.RunWithSweptWorkDir: another process deletes every <paramref name="prefix"/> directory under <c>TMPDIR</c> as soon as it appears.</summary>
    private static int RunWithSweptWorkDir(bool driver, string name, string prefix, string source, params string[] args)
    {
        var root = Fresh(name);
        File.WriteAllText(Path.Combine(root, "main.byn"), source);
        var temp = Path.Combine(root, "tmp");
        Directory.CreateDirectory(temp);
        using var stop = new CancellationTokenSource();
        var watcher = Task.Run(() =>
        {
            while (!stop.IsCancellationRequested)
            {
                foreach (var d in Directory.EnumerateDirectories(temp, prefix + "*"))
                    try { Directory.Delete(d, recursive: true); } catch (IOException) { }
                Thread.Sleep(5);
            }
        });
        var exit = Start(driver, root, [("TMPDIR", temp), ("BAYAN_CACHE", Path.Combine(root, "cache")), ("BAYAN_TEST_TIMEOUT_MS", TestTime.Scale(2000).ToString())], [.. args, "main.byn"]).Exit;
        stop.Cancel();
        watcher.Wait();
        return exit;
    }

    [Fact]
    public void F2_ACoverageWorkDirectoryAnotherProcessSweptDoesNotChangeTheExitCode()
    {
        if (OperatingSystem.IsWindows()) return;
        const string Spin = "void main() {\n}\n\ntest \"spin\" {\n    while true {\n    }\n}\n";
        var expected = RunWithSweptWorkDir(false, "swept-coverage-cs", "bayan-coverage-", Spin, "test", "--coverage");
        var actual = RunWithSweptWorkDir(true, "swept-coverage-s2", "bayan-coverage-", Spin, "test", "--coverage");
        Assert.Equal(CliApp.ExitTestFailure, expected);
        Assert.Equal(expected, actual);
    }


    // ── Q31 (plans 013, 014) ──────────────────────────────────────────────────────

    // Plan 014, max RSS of the driver's check and build --emit-c (macOS mb1 / Linux bayan-test01):
    //   after both arenas   check 396 / 472 MB,  emit-c 678 / 786 MB
    //   region arena off    check 582 / 670 MB,  emit-c 865 / 985 MB
    //   summary arena off   check 557 / 644 MB,  emit-c 839 / 958 MB
    //   plan 013 (before)   check 743 / 841 MB,  emit-c 1,026 / 1,155 MB
    // Bound = this host's after figure + half the smaller single-arena saving (about 80 MB), rounded, so either arena reverted
    // fails it. One bound for both hosts would sit within 5 MB of macOS's summary-off figure, hence one per OS. Sampled by
    // PeakSampler on macOS with an arena reverted: region 578 MB, summary 550 MB. emit-c has no bound: sampled on macOS
    // with the summary arena reverted it read 765 MB against 760, too close to tell a revert from noise. Windows was never
    // measured after plan 014, so it keeps plan 013's 1,700 MB.
    private static readonly long CheckPeakBoundMb = OperatingSystem.IsMacOS() ? 480 : OperatingSystem.IsLinux() ? 560 : 1700;

    // measured after the arenas, 64 files of 4 MB: doctor 33 MB on macOS, 15 MB on Linux; before: 543 MB and 514 MB.
    // bound = 3x the larger, rounded up.
    private const long DoctorPeakBoundMb = 100;

    /// <summary>Q31: <c>summarizeRegions</c> and each template's <c>analyzeRegions</c> run in arenas (plans 013, 014), so checking the driver stays bounded.</summary>
    [Fact]
    public void CheckOfTheDriverStaysBounded()
    {
        var dir = Fresh("check-driver");
        var psi = new ProcessStartInfo(BootstrapTests.Stage2Executable()) { WorkingDirectory = Golden.RepoRoot };
        psi.Environment["BAYAN_CACHE"] = Path.Combine(dir, "cache");
        foreach (var a in new[] { "check", "--package", "selfhost", "selfhost/driver" }) psi.ArgumentList.Add(a);
        var (exit, _, stderr, peak) = PeakSampler.Run(psi);
        Assert.True(exit == 0, stderr);
        Assert.True(peak > 0, "no working-set sample was taken");
        Assert.True(peak < CheckPeakBoundMb * 1024 * 1024, $"check of selfhost/driver peaked at {peak / (1024 * 1024)} MB, bound {CheckPeakBoundMb} MB");
    }

    /// <summary>Q31: <c>cacheStats</c> and <c>t1FileExists</c> read each cached file in an arena, so <c>doctor</c> does not grow with the cache.</summary>
    [Fact]
    public void DoctorOfALargeCacheStaysBounded()
    {
        var dir = Fresh("doctor-cache");
        var programs = Path.Combine(dir, "cache", "v1", "programs", "x");
        Directory.CreateDirectory(programs);
        var block = new byte[4 * 1024 * 1024];
        for (var i = 0; i < 64; i++) File.WriteAllBytes(Path.Combine(programs, $"f{i}"), block);
        var run = Start(true, dir, NoEnv, "doctor");
        Assert.Contains("256.0 MB", run.Out);
        Assert.True(run.Peak > 0, "no working-set sample was taken");
        Assert.True(run.Peak < DoctorPeakBoundMb * 1024 * 1024, $"doctor over a 256 MB cache peaked at {run.Peak / (1024 * 1024)} MB, bound {DoctorPeakBoundMb} MB");
    }


    // listed skips (no xunit skip: the guard rejects them), each with its Question:
    // - CliMemoryBoundsTests.M1_* stream rows (uneven writes, a pipe held open, a split character, an endless stream, under the cap):
    //   no driver entry point reads a Stream (Q1226).
    // - CliMemoryBoundsTests.M2_DiscardedOutputIsDrainedWithoutBuffering and F2_AMutateWorkDirectory...: test --mutate is T13's (Q1220).
    // - CliMemoryBoundsTests.M7_AHungCCompilerIsKilledAndTheBuildFails: cache.byn runs the C compiler with Io.run and no timeout (Q1149).
}
