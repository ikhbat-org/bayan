using System.Text.RegularExpressions;
using System.Diagnostics;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// 017 T5: <c>bayan doctor</c> of the self-hosted driver (<c>selfhost/driver/doctor.byn</c>). Each row runs <see cref="CliApp.Run"/> and the
/// driver on the same argv and environment and compares stdout, stderr and exit code; the commit of the version line and the
/// OS message of an unwritable cache differ by construction (Q1091, Q1093) and are masked.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed partial class SelfhostDefaultT5Tests
{
    [GeneratedRegex(@"\(commit [^)]*\)")]
    private static partial Regex Commit();

    [GeneratedRegex(@"isn't writable: [^\u001b\n]*")]
    private static partial Regex Message();

    private static string Mask(string text) => Message().Replace(Commit().Replace(text, "(commit <c>)"), "isn't writable: <message>");

    private static string Fresh(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t5-doctor", name);
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        return dir;
    }

    /// <summary>The fake tools are shell scripts, which Windows cannot start: there both sides still run through <c>Same</c> (the argument is evaluated), but only Unix asserts what they print.</summary>
    private static void UnixContains(string expected, string actual) { if (!OperatingSystem.IsWindows()) Assert.Contains(expected, actual); }

    private static string Script(string dir, string name, int exit, string output)
    {
        var path = Path.Combine(dir, name);
        return Executable(path, $"#!/bin/sh\necho '{output}'\nexit {exit}\n");
    }

    /// <summary>Writes a shell script (the fake tools of these rows are Unix only).</summary>
    private static string Executable(string path, string text)
    {
        File.WriteAllText(path, text);
        if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(path, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        return path;
    }

    private static void WithEnv((string Name, string? Value)[] vars, Action body)
    {
        (string Name, string? Value)[] all =
        [
            ("NO_COLOR", null), ("FORCE_COLOR", null), ("TERM", null), ("COLORTERM", null), ("BAYAN_THEME", null),
            ("COLORFGBG", null), ("LC_ALL", null), ("LC_CTYPE", null), ("LANG", "en_US.UTF-8"), .. vars,
        ];
        var saved = all.Select(v => (v.Name, Value: Environment.GetEnvironmentVariable(v.Name))).ToArray();
        foreach (var (name, value) in all) Environment.SetEnvironmentVariable(name, value);
        try
        {
            body();
        }
        finally
        {
            foreach (var (name, value) in saved.Reverse()) Environment.SetEnvironmentVariable(name, value);
        }
    }

    private static (int Exit, string Out, string Err) Oracle(string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
    }

    /// <summary>Both sides under <paramref name="vars"/>; returns the driver's stdout for the test to look at.</summary>
    private static string Same((string Name, string? Value)[] vars, params string[] args)
    {
        SelfhostDriverHarness.Build();
        var result = "";
        WithEnv(vars, () =>
        {
            var expected = Oracle(args);
            var actual = SelfhostDriverHarness.Run(args);
            var label = string.Join(' ', args);
            Assert.Equal(expected.Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Mask(expected.Out), Mask(actual.Out));
            SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", expected.Err, actual.Err);
            result = actual.Out;
        });
        return result;
    }

    private static string[][] Argvs() => [["doctor"], ["--color", "always", "doctor"], ["--ascii", "doctor"]];

    /// <summary><c>doctor</c> reaches the driver's own checks (moved from <c>SelfhostDriverT1Tests</c>, which runs in parallel with this collection's
    /// <c>BAYAN_CC</c>/<c>BAYAN_CACHE</c> changes and with tests that fill the shared cache whose program count <c>doctor</c> prints).</summary>
    [Fact]
    public void DispatchesDoctorAsCliApp() => Same([("BAYAN_CACHE", Fresh("dispatch"))], "doctor");

    [Fact]
    public void ADoctorOfThisMachine()
    {
        foreach (var args in Argvs()) Same([], args);
    }

    [Fact]
    public void ExplainStillDispatches() => Same([], "explain", "BYN0003");

    /// <summary>T5 edits `run`, whose `cache` and `clean` arms are T3's: the guard gates every line of a touched function.</summary>
    [Fact]
    public void CacheAndCleanStillDispatch()
    {
        var cache = Fresh("dispatch");
        Same([("BAYAN_CACHE", cache)], "cache", "stats");
        Same([("BAYAN_CACHE", cache)], "clean");
    }

    [Fact]
    public void AWorkingCompilerFromTheEnvironmentAndNoZigOrGit()
    {
        var dir = Fresh("bare");
        var cc = Script(dir, "fakecc", 0, "fakecc 1.0");
        foreach (var args in Argvs())
        {
            var text = Same([("BAYAN_CC", cc), ("PATH", Path.Combine(dir, "empty"))], args);
            UnixContains("not found; building for other targets needs it", text);
        }
        var spaced = Same([("BAYAN_CC", $"  {cc}   -O2 "), ("PATH", Path.Combine(dir, "empty"))], "doctor");
        UnixContains($"{cc} -O2 (fakecc 1.0)", spaced);
    }

    [Fact]
    public void NoCompilerAtAll()
    {
        var dir = Fresh("none");
        foreach (var args in Argvs())
        {
            var text = Same([("BAYAN_CC", null), ("PATH", Path.Combine(dir, "empty"))], args);
            Assert.Contains("none found", text);
        }
    }

    /// <summary>The C# throws IndexOutOfRangeException on <c>compiler[0]</c>; the driver panics (Q1095).</summary>
    [Fact]
    public void ACompilerFromTheEnvironmentThatNamesNoProgram()
    {
        SelfhostDriverHarness.Build();
        WithEnv([("BAYAN_CC", "   ")], () =>
        {
            Assert.Throws<IndexOutOfRangeException>(() => Oracle(["doctor"]));
            var actual = SelfhostDriverHarness.Run("doctor");
            Assert.NotEqual(0, actual.Exit);
            Assert.Contains("BAYAN_CC is set but names no program", actual.Err); // no-oracle: Q1095
        });
    }

    [Fact]
    public void ACompilerFromTheEnvironmentThatCannotRun()
    {
        var dir = Fresh("broken-env");
        var failing = Script(dir, "failcc", 1, "nope");
        foreach (var args in Argvs())
        {
            Assert.Contains("BAYAN_CC is `", Same([("BAYAN_CC", Path.Combine(dir, "missing"))], args));
            Assert.Contains("BAYAN_CC is `", Same([("BAYAN_CC", failing)], args));
        }
    }

    [Fact]
    public void ToolsOnThePath()
    {
        var dir = Fresh("path");
        Script(dir, "zig", 0, "0.99.0");
        Script(dir, "git", 0, "git version 9.9");
        var text = Same([("BAYAN_CC", null), ("PATH", dir)], "doctor");
        UnixContains($"{Path.Combine(dir, "zig")} cc (0.99.0)", text);
        UnixContains($"git         {Path.Combine(dir, "git")} (git version 9.9)", text);
        var broken = Fresh("path-broken");
        Script(broken, "zig", 1, "x");
        Script(broken, "git", 1, "x");
        foreach (var args in Argvs())
        {
            UnixContains("can't be run", Same([("BAYAN_CC", null), ("PATH", broken)], args));
            UnixContains("reinstall git", Same([("BAYAN_CC", Path.Combine(broken, "zig")), ("PATH", broken)], args));
        }
        var cc = Fresh("path-cc");
        Script(cc, "cc", 1, "x");
        UnixContains("`" + Path.Combine(cc, "cc") + "` can't be run", Same([("BAYAN_CC", null), ("PATH", cc)], "doctor"));
        var good = Fresh("path-gcc");
        Script(good, "gcc", 0, "gcc (GCC) 1.2");
        UnixContains($"{Path.Combine(good, "gcc")} (gcc (GCC) 1.2)", Same([("BAYAN_CC", null), ("PATH", good)], "doctor"));
        var stderrOnly = Fresh("path-stderr");
        var script = Path.Combine(stderrOnly, "zig");
        Executable(script, "#!/bin/sh\necho '  on stderr  ' >&2\nexit 0\n");
        UnixContains("(on stderr)", Same([("BAYAN_CC", null), ("PATH", stderrOnly)], "doctor"));
    }

    [Fact]
    public void AnUnwritableCache()
    {
        var blocker = Path.Combine(Fresh("cache"), "file");
        File.WriteAllText(blocker, "");
        foreach (var args in Argvs())
            Assert.Contains("isn't writable", Same([("BAYAN_CACHE", blocker)], args));
        Assert.Contains("isn't writable", Same([("BAYAN_CACHE", Path.Combine(blocker, "sub"))], "doctor"));
    }

    [Fact]
    public void ACacheWithPrograms()
    {
        var cache = Fresh("programs");
        var program = Path.Combine(cache, "v1", "programs", "a");
        Directory.CreateDirectory(program);
        File.WriteAllBytes(Path.Combine(program, "program"), new byte[1_700_000]);
        Directory.CreateDirectory(Path.Combine(cache, "v1", "programs", "b"));
        File.WriteAllBytes(Path.Combine(cache, "v1", "programs", "b", "program"), new byte[10]);
        Directory.CreateDirectory(Path.Combine(program, "nested"));
        File.WriteAllBytes(Path.Combine(cache, "v1", "programs", "stray"), new byte[5]);
        var text = Same([("BAYAN_CACHE", cache)], "doctor");
        Assert.Contains("(writable, 2 programs, 1.6 MB)", text);
        var home = Fresh("home");
        Same([("BAYAN_CACHE", null), ("HOME", home), ("XDG_CACHE_HOME", Path.Combine(home, "xdg"))], "doctor");
        Same([("BAYAN_CACHE", null), ("HOME", home), ("XDG_CACHE_HOME", "relative")], "doctor");
    }

    [Fact]
    public void ACacheDirectoryThatCannotTakeAFile()
    {
        if (OperatingSystem.IsWindows()) return;
        var cache = Fresh("readonly");
        File.SetUnixFileMode(cache, UnixFileMode.UserRead | UnixFileMode.UserExecute);
        try
        {
            foreach (var args in Argvs())
                Assert.Contains("isn't writable", Same([("BAYAN_CACHE", cache)], args));
        }
        finally
        {
            File.SetUnixFileMode(cache, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
    }

    [Fact]
    public void AProgramFileThatCannotBeRead()
    {
        if (OperatingSystem.IsWindows()) return;
        var cache = Fresh("unreadable");
        var program = Path.Combine(cache, "v1", "programs", "a");
        Directory.CreateDirectory(program);
        var file = Path.Combine(program, "program");
        File.WriteAllBytes(file, new byte[10]);
        File.SetUnixFileMode(file, UnixFileMode.None);
        try
        {
            Assert.Contains("(writable, 1 programs,", Same([("BAYAN_CACHE", cache)], "doctor"));
        }
        finally
        {
            File.SetUnixFileMode(file, UnixFileMode.UserRead | UnixFileMode.UserWrite);
        }
    }

    // ── Render on the doctor-ok and doctor-fail shapes of StyleTests (Q1094) ────────────────────────

    private const string ProbeMain = """

        i32 main(ReadOnlySpan<string> args) uses alloc, console {
            var checks = List<T5Check>()
            checks.append(T5Check { level: .ok, name: "bayan", detail: "<version> (commit a1b2c3d4e5f6)", fix: null })
            checks.append(T5Check { level: .ok, name: "host", detail: "<host>", fix: null })
            if args[0] == "ok" {
                checks.append(T5Check { level: .ok, name: "C compiler", detail: "zig cc (0.14.1)", fix: null })
                checks.append(T5Check { level: .ok, name: "zig", detail: "/usr/local/bin/zig (0.14.1)", fix: null })
                checks.append(T5Check { level: .ok, name: "git", detail: "/usr/bin/git (git version 2.47.0)", fix: null })
                checks.append(T5Check { level: .ok, name: "cache", detail: "~/.cache/bayan (writable, 3 programs, 1.2 MB)", fix: null })
            } else {
                checks.append(T5Check { level: .broken, name: "C compiler", detail: "none found", fix: "install zig (https://ziglang.org), or set BAYAN_CC to a C compiler" })
                checks.append(T5Check { level: .note, name: "zig", detail: "not found; building for other targets needs it", fix: "install zig (https://ziglang.org)" })
                checks.append(T5Check { level: .ok, name: "git", detail: "/usr/bin/git (git version 2.47.0)", fix: null })
                checks.append(T5Check { level: .broken, name: "cache", detail: "~/.cache/bayan isn't writable: Permission denied", fix: "set BAYAN_CACHE to a writable directory" })
            }
            let style = DStyle { color: args[1] != "plain", ascii: args[1] == "ascii", palette: 2 }
            Io.stdout.write(t5Render(in checks, by: style))
            return 0
        }
        """;

    private static readonly Lazy<(string? Path, string Error)> Probe = new(() =>
    {
        var sources = Directory.GetFiles(SelfhostDriverHarness.DriverDir, "*.byn").Order(StringComparer.Ordinal)
            .Select(p => Path.GetFileName(p) == "main.byn"
                ? SourceText.FromString(p, File.ReadAllText(p).Replace("i32 main(ReadOnlySpan<string> args) {", "i32 driverMain(ReadOnlySpan<string> args) {") + ProbeMain + "\n")
                : SourceText.FromFile(p)).ToList();
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var c = Compilation.Create(sources, packageRoot: SelfhostSemanticsHarness.SelfhostDir);
        if (c.Diagnostics.HasErrors) return (null, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal));
        return build.Succeeded ? (build.ExecutablePath, "") : (null, build.Errors);
    });

    private static string RenderedByTheDriver(string shape, string style)
    {
        var (path, error) = Probe.Value;
        if (path is null) Assert.Fail($"selfhost/driver with the render probe did not build:\n{error}");
        var (exit, stdout, _) = SelfhostParserTests.Run(path!, shape, style);
        Assert.Equal(0, exit);
        return stdout.ReplaceLineEndings("\n");
    }

    /// <summary>The stdout section of a <c>tests/cases/style</c> file.</summary>
    private static string Golden_(string name)
    {
        var text = File.ReadAllText(Path.Combine(Golden.RepoRoot, "tests", "cases", "style", name)).ReplaceLineEndings("\n");
        const string head = "# Doctor.Render\n--- stdout ---\n";
        Assert.StartsWith(head, text);
        var end = text.IndexOf("--- stderr ---\n", StringComparison.Ordinal);
        return text[head.Length..end];
    }

    [Theory]
    [InlineData("ok", "plain")]
    [InlineData("fail", "plain")]
    public void RendersThePlainStyleFiles(string shape, string style)
    {
        Assert.Equal(Golden_($"doctor-{shape}.{style}"), RenderedByTheDriver(shape, style));
    }

    /// <summary>The <c>.ascii</c> files are coloured with ASCII symbols and the <c>.color</c> files are truecolor, both on a dark terminal (`DPalette.truecolorDark`, Q1117).</summary>
    [Theory]
    [InlineData("ok", "color")]
    [InlineData("fail", "color")]
    [InlineData("ok", "ascii")]
    [InlineData("fail", "ascii")]
    public void RendersTheColourFiles(string shape, string style) =>
        Assert.Equal(Golden_($"doctor-{shape}.{style}"), RenderedByTheDriver(shape, style));
}
