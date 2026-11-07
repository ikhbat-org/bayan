using System.Text.RegularExpressions;
using Bayan.Cli;

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

    [Fact]
    public void ADoctorOfThisMachine()
    {
        foreach (var args in Argvs()) Same([], args);
    }

    [Fact]
    public void ExplainStillDispatches() => Same([], "explain", "BYN0003");

    [Fact]
    public void AWorkingCompilerFromTheEnvironmentAndNoZigOrGit()
    {
        var dir = Fresh("bare");
        var cc = Script(dir, "fakecc", 0, "fakecc 1.0");
        foreach (var args in Argvs())
        {
            var text = Same([("BAYAN_CC", cc), ("PATH", Path.Combine(dir, "empty"))], args);
            Assert.Contains("not found; building for other targets needs it", text);
        }
        var spaced = Same([("BAYAN_CC", $"  {cc}   -O2 "), ("PATH", Path.Combine(dir, "empty"))], "doctor");
        Assert.Contains($"{cc} -O2 (fakecc 1.0)", spaced);
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
        Assert.Contains($"{Path.Combine(dir, "zig")} cc (0.99.0)", text);
        Assert.Contains($"git         {Path.Combine(dir, "git")} (git version 9.9)", text);
        var broken = Fresh("path-broken");
        Script(broken, "zig", 1, "x");
        Script(broken, "git", 1, "x");
        foreach (var args in Argvs())
        {
            Assert.Contains("can't be run", Same([("BAYAN_CC", null), ("PATH", broken)], args));
            Assert.Contains("reinstall git", Same([("BAYAN_CC", Path.Combine(broken, "zig")), ("PATH", broken)], args));
        }
        var cc = Fresh("path-cc");
        Script(cc, "cc", 1, "x");
        Assert.Contains("`" + Path.Combine(cc, "cc") + "` can't be run", Same([("BAYAN_CC", null), ("PATH", cc)], "doctor"));
        var good = Fresh("path-gcc");
        Script(good, "gcc", 0, "gcc (GCC) 1.2");
        Assert.Contains($"{Path.Combine(good, "gcc")} (gcc (GCC) 1.2)", Same([("BAYAN_CC", null), ("PATH", good)], "doctor"));
        var stderrOnly = Fresh("path-stderr");
        var script = Path.Combine(stderrOnly, "zig");
        Executable(script, "#!/bin/sh\necho '  on stderr  ' >&2\nexit 0\n");
        Assert.Contains("(on stderr)", Same([("BAYAN_CC", null), ("PATH", stderrOnly)], "doctor"));
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
}
