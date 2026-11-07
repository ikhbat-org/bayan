using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Reflection;
using Bayan.Cli;
using Bayan.Syntax.Diagnostics;

namespace Bayan.Tests;

/// <summary>
/// 012 T1: the driver's dispatch, usage and global options against <see cref="CliApp.Run"/> (R2), and its refusals (R3).
/// The expected lines come from the C# run in-process; only the version line's parenthesised part is masked (spec Q3).
/// </summary>
public sealed class SelfhostDriverT1Tests
{
    private static string Mask(string text) => Regex.Replace(text, @"^(bayan \S+) \(.*\)$", "$1 (masked)", RegexOptions.Multiline);

    /// <summary><see cref="CliApp.Run(string[], TextWriter, TextWriter)"/> in-process, the oracle of R2 (no terminal), line ends read as LF.</summary>
    private static (int Exit, string Out, string Err) Oracle(string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
    }

    private static void AssertSameAsCs(params string[] args)
    {
        var expected = Oracle(args);
        var actual = SelfhostDriverHarness.Run(args);
        var label = string.Join(' ', args);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Mask(expected.Out), Mask(actual.Out));
        SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", expected.Err, actual.Err);
    }

    public static IEnumerable<object[]> Corpus() => new[]
    {
        new string[] { },
        new[] { "version" },
        new[] { "--version" },
        new[] { "help" },
        new[] { "--help" },
        new[] { "-h" },
        new[] { "frobnicate" },
        new[] { "fmt" },
        new[] { "--ascii" },
        new[] { "--ascii", "help" },
        new[] { "--color", "never", "version" },
        new[] { "--color=always", "-h" },
        new[] { "version", "--color", "never" },
        new[] { "--color", "sometimes", "help" },
        new[] { "--color=bad", "help" },
        new[] { "--color" },
        new[] { "--" },
        new[] { "--bogus" },
        new[] { "missing-script.byn" },
        new[] { "--ascii", "fmt", "--color", "never" },
        new[] { "version", Path.Combine(SelfhostDriverHarness.DriverDir, "main.byn"), "--color", "bad" },
    }.Select(a => new object[] { a });

    [Theory]
    [MemberData(nameof(Corpus))]
    public void MatchesTheCSharpCli(string[] args) => AssertSameAsCs(args);

    [Theory]
    [InlineData("doctor")]
    [InlineData("format")]
    [InlineData("audit")]
    [InlineData("features")]
    [InlineData("explain")]
    [InlineData("test")]
    [InlineData("mutate")]
    [InlineData("new")]
    [InlineData("dist")]
    [InlineData("init")]
    public void RefusesWhatItDoesNotPort(string command)
    {
        var (exit, stdout, stderr) = SelfhostDriverHarness.Run(command, "x");
        Assert.Equal(CliApp.ExitUsage, exit);
        Assert.Equal("", stdout);
        // no-oracle: Q917 (the C# never prints the refusal of spec Q4; `CliApp.Run` runs these commands)
        Assert.Equal($"error: `{command}` is not available in the self-hosted compiler; use the C# `bayan`\n", stderr);
    }

    /// <summary>`build` and `run` reach their commands (T5, T6): a missing path fails as the C# does.</summary>
    [Fact]
    public void DispatchesBuildAndRun()
    {
        var missing = Path.Combine(Golden.RepoRoot, "tmp", "t1-driver", "missing.byn");
        AssertSameAsCs("build", missing);
        AssertSameAsCs("run", missing);
    }

    [Fact]
    public void AScriptRunsAndAGlobalOptionBeforeItIsTaken()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t1-driver");
        Directory.CreateDirectory(dir);
        var script = Path.Combine(dir, "tool.byn");
        File.WriteAllText(script, "print(\"hi\")\n");
        // the script runs (T6); `--color bad` after it is its own argument (CliApp.cs:97, :328)
        // (the C# program inherits the test process's stdout, so only the exit code is comparable)
        string[] runArgs = ["--ascii", script, "--color", "bad"];
        Assert.Equal(Oracle(runArgs).Exit, SelfhostDriverHarness.Run(runArgs).Exit);
        AssertSameAsCs(dir);
        // a directory named like a script is not one (`File.Exists`)
        Directory.CreateDirectory(Path.Combine(dir, "d.byn"));
        AssertSameAsCs(Path.Combine(dir, "d.byn"));
    }

    private static string StyleLine(Style? out_, Style? err, bool tty) =>
        $"out {Fmt(out_)} err {Fmt(err)} tty {tty.ToString().ToLowerInvariant()}";

    private static string Fmt(Style? s) => $"{(s!.Colors is not null).ToString().ToLowerInvariant()} {(s.Symbols == Symbols.Ascii).ToString().ToLowerInvariant()} {s.Width}";

    /// <summary>
    /// The style state `Run` sets (CliApp.cs:40) with no environment variable set: the colour and `--ascii` come from the C#
    /// <c>TakeGlobalOptions</c> itself, then <c>Decide</c> as `Run` calls it, over an empty environment so the test process's
    /// <c>NO_COLOR</c>, <c>FORCE_COLOR</c>, <c>TERM</c> and locale cannot change the expected line (`Run` takes no environment).
    /// </summary>
    internal static string CsStyle(string[] args)
    {
        var call = new object[] { args, new StringWriter() };
        var taken = typeof(CliApp).GetMethod("TakeGlobalOptions", BindingFlags.NonPublic | BindingFlags.Static)!.Invoke(null, call);
        var (color, ascii) = ((string Color, bool Ascii))taken!;
        var style = TerminalStyle.Decide(color, ascii, false, _ => null, 0);
        return StyleLine(style, style, false);
    }

    internal static string ProbeStyle(IReadOnlyDictionary<string, string> env, string[] args)
    {
        var (exit, stdout, _) = SelfhostDriverHarness.RunProbe(env, ["style", .. args]);
        Assert.Equal(CliApp.ExitOk, exit);
        return stdout.TrimEnd('\n').Split('\n')[^1];
    }

    [Theory]
    [InlineData("--color", "always", "version")]
    [InlineData("--color", "never", "version")]
    [InlineData("--color", "auto", "version")]
    [InlineData("--ascii", "version")]
    [InlineData("--color=always", "--ascii", "version")]
    [InlineData("--ascii", "--color", "never", "version")]
    [InlineData("version")]
    public void DecidesTheStyleAsCliAppRun(params string[] args) =>
        Assert.Equal(CsStyle(args), ProbeStyle(new Dictionary<string, string>(), args));

    [Theory]
    [InlineData("NO_COLOR", "1", "always", false)]
    [InlineData("FORCE_COLOR", "1", "never", false)]
    [InlineData("TERM", "dumb", "always", true)]
    public void AnExplicitFlagDecidesWhateverTheEnvironmentSays(string name, string value, string color, bool ascii)
    {
        // CliApp.Run reads Environment.GetEnvironmentVariable, so the C# side is `Decide` over the same variable, the process
        // environment itself left alone for the other tests. The driver reads no environment (Q919): these are the cases where a flag decides.
        string? Env(string k) => k == name ? value : null;
        var expected = TerminalStyle.Decide(color, ascii, false, Env, 0);
        string[] args = ascii ? ["--ascii", "--color", color, "version"] : ["--color", color, "version"];
        Assert.Equal(StyleLine(expected, expected, false), ProbeStyle(new Dictionary<string, string> { [name] = value }, args));
    }

    [Theory]
    [InlineData("auto", false, true, 80)]
    [InlineData("auto", false, true, 0)]
    [InlineData("auto", true, false, 80)]
    [InlineData("never", true, true, 80)]
    [InlineData("always", false, false, 80)]
    public void DecideMatchesTerminalStyleWithNoEnvironment(string color, bool ascii, bool tty, int width)
    {
        var expected = TerminalStyle.Decide(color, ascii, tty, _ => null, width);
        var actual = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "decide", color, ascii ? "true" : "false", tty ? "true" : "false", width.ToString()).Out;
        Assert.Equal(Fmt(expected) + "\n", actual);
    }

    [Fact]
    public void RefuseLibraryAsCliAppDoes()
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "t1-driver-lib");
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        var lib = Path.Combine(root, "cleanlib");
        Directory.CreateDirectory(Path.Combine(lib, "src", "cleanlib"));
        File.WriteAllText(Path.Combine(lib, "package.byn"), "Package {\n    name: \"local/cleanlib\",\n    version: \"0.1.0\",\n    edition: 2027,\n    kind: .lib,\n}\n");
        File.WriteAllText(Path.Combine(lib, "src", "cleanlib", "main.byn"), "public i32 one() => 1\n");
        var plain = Path.Combine(root, "plain");
        Directory.CreateDirectory(plain);
        File.WriteAllText(Path.Combine(plain, "main.byn"), "i32 main() => 0\n");
        foreach (var (path, refused) in new[] { (lib, true), (plain, false) })
        {
            var expected = Oracle(["build", "--emit-c", path]);
            Assert.Equal(refused ? CliApp.ExitUsage : CliApp.ExitOk, expected.Exit);
            var (exit, stdout, stderr) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "library", path, "build");
            Assert.Equal(0, exit);
            Assert.Equal(refused ? "true\n" : "false\n", stdout);
            SelfhostEmitterHarness.AssertSame($"stderr for {Path.GetFileName(path)}", expected.Err, stderr);
        }
    }

    [Fact]
    public void IsScriptAsCliAppDoes()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t1-driver-script");
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "a.byn"), "#!/usr/bin/env bayan\nprint(\"x\")\n");
        File.WriteAllText(Path.Combine(dir, "b.byn"), "print(\"x\")\n");
        File.WriteAllText(Path.Combine(dir, "c.byn"), "#");
        File.WriteAllText(Path.Combine(dir, "d.byn"), "#!");
        File.WriteAllText(Path.Combine(dir, "e.byn"), "#x\n");
        var isScript = typeof(CliApp).GetMethod("IsScript", BindingFlags.NonPublic | BindingFlags.Static)!;
        foreach (var path in new[] { "a.byn", "b.byn", "c.byn", "d.byn", "e.byn", "missing.byn", "." }.Select(n => Path.GetFullPath(Path.Combine(dir, n))))
        {
            var expected = ((bool)isScript.Invoke(null, [path])!).ToString().ToLowerInvariant();
            Assert.Equal(expected + "\n", SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "isscript", path).Out);
        }
    }

    /// <summary>`bayan format --check` over `selfhost/driver/` with the pinned `bayan`. Skipped on Windows: `bash scripts/pinned-bayan.sh` exits 127 on wp1 (work/todo.md, 012 T28).</summary>
    [Fact]
    public void SourcesAreFormatted()
    {
        if (OperatingSystem.IsWindows()) return;
        var pinned = Run("bash", Path.Combine(Golden.RepoRoot, "scripts", "pinned-bayan.sh"));
        Assert.Equal(0, pinned.Exit);
        var bayan = pinned.Out.Trim().Split('\n')[^1].Trim();
        var (exit, stdout, stderr) = Run(bayan, "format", "--check", SelfhostDriverHarness.DriverDir);
        Assert.True(exit == 0, $"bayan format --check selfhost/driver:\n{stdout}{stderr}");
    }

    private static (int Exit, string Out, string Err) Run(string program, params string[] args)
    {
        var psi = new ProcessStartInfo(program) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, WorkingDirectory = Golden.RepoRoot };
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result, stderr.Result);
    }
}

/// <summary>
/// 012 T23: the style oracle of <see cref="SelfhostDriverT1Tests"/> does not read the test process's environment.
/// Runs alone (the collection is not parallel) because it sets <c>FORCE_COLOR</c> and <c>NO_COLOR</c> in the process.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDriverStyleEnvironmentTests
{
    [Theory]
    [InlineData("FORCE_COLOR")]
    [InlineData("NO_COLOR")]
    public void TheStyleOracleIgnoresTheProcessEnvironment(string name)
    {
        var saved = Environment.GetEnvironmentVariable(name);
        Environment.SetEnvironmentVariable(name, "1");
        try
        {
            foreach (var args in new[] { new[] { "version" }, ["--color", "auto", "version"], ["--ascii", "version"] })
                Assert.Equal(SelfhostDriverT1Tests.CsStyle(args), SelfhostDriverT1Tests.ProbeStyle(new Dictionary<string, string>(), args));
        }
        finally { Environment.SetEnvironmentVariable(name, saved); }
    }
}

/// <summary>
/// 017 T3: <c>cache stats</c> and <c>clean</c> against <see cref="CliApp.Run"/> (L028): the same argv on two identical trees,
/// stdout, stderr, exit code and the tree left behind compared, the cache and root paths masked. The oracle runs in-process, so
/// it sets <c>BAYAN_CACHE</c> and the working directory of the test process (hence the collection).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDriverT1TestsCacheCleanTests
{
    private static readonly string Base = Path.Combine(Golden.RepoRoot, "tmp", "driver-t3");

    /// <summary>A fresh tree under <c>tmp/driver-t3/&lt;name&gt;/&lt;side&gt;</c>, filled by <paramref name="seed"/> (given the root).</summary>
    private static string Tree(string name, string side, Action<string> seed)
    {
        var root = Path.Combine(Base, side, name);
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        Directory.CreateDirectory(root);
        seed(root);
        return root;
    }

    private static void File_(string path, int size)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllBytes(path, new byte[size]);
    }

    private static string Listing(string root) => !Directory.Exists(root) ? "" : string.Join("\n",
        Directory.EnumerateFileSystemEntries(root, "*", SearchOption.AllDirectories)
            .Select(p => Path.GetRelativePath(root, p).Replace('\\', '/') + (File.Exists(p) ? $" {new FileInfo(p).Length}" : "/")).Order(StringComparer.Ordinal));

    private static string Masked(string text, string root) => Regex.Replace(text.Replace(root, "<root>"), @"[0-9]+\.[0-9]{2}s", "<t>s");

    /// <summary>The environment a run gets: <c>BAYAN_CACHE</c> and the rest, a null value unsetting the variable.</summary>
    private static readonly string[] Variables = ["BAYAN_CACHE", "HOME", "XDG_CACHE_HOME"];

    private static (int Exit, string Out, string Err) Cs(string root, IReadOnlyDictionary<string, string?> env, params string[] args)
    {
        var saved = (Environment.CurrentDirectory, Variables.Select(Environment.GetEnvironmentVariable).ToArray());
        Environment.CurrentDirectory = root;
        foreach (var v in Variables) Environment.SetEnvironmentVariable(v, env.GetValueOrDefault(v));
        try
        {
            var stdout = new StringWriter();
            var stderr = new StringWriter();
            var exit = CliApp.Run(args, stdout, stderr);
            return (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
        }
        finally
        {
            Environment.CurrentDirectory = saved.CurrentDirectory;
            for (var i = 0; i < Variables.Length; i++) Environment.SetEnvironmentVariable(Variables[i], saved.Item2[i]);
        }
    }

    private static (int Exit, string Out, string Err) Stage2(string root, IReadOnlyDictionary<string, string?> env, params string[] args)
    {
        var psi = new ProcessStartInfo(SelfhostDriverHarness.Build()) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, WorkingDirectory = root };
        foreach (var v in Variables)
            if (env.GetValueOrDefault(v) is { } value) psi.Environment[v] = value; else psi.Environment.Remove(v);
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"));
    }

    /// <summary>The same argv on two trees; <paramref name="env"/> maps a tree's root to the variables (default: only <c>BAYAN_CACHE</c> = <c>&lt;root&gt;/cache</c>).</summary>
    private static void Same(string name, Action<string> seed, Func<string, Dictionary<string, string?>>? env, params string[] args)
    {
        var a = Tree(name, "cs", seed);
        var b = Tree(name, "s2", seed);
        env ??= r => new() { ["BAYAN_CACHE"] = Path.Combine(r, "cache") };
        var expected = Cs(a, env(a), args);
        var actual = Stage2(b, env(b), args);
        var label = $"{name}: {string.Join(' ', args)}";
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Masked(expected.Out, a), Masked(actual.Out, b));
        SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", Masked(expected.Err, a), Masked(actual.Err, b));
        SelfhostEmitterHarness.AssertSame($"tree of `{label}`", Listing(a), Listing(b));
    }

    private static void Same(string name, Action<string> seed, params string[] args) => Same(name, seed, null, args);

    private static void Nothing(string root) { }

    private static void Seeded(string root) => Seeded(root, "cache");

    private static void Seeded(string root, string cache)
    {
        var data = Path.Combine(root, cache, "v1");
        Directory.CreateDirectory(Path.Combine(data, "programs", "k1", "nested"));
        File_(Path.Combine(data, "programs", "k1", "prog"), 1_572_864);
        File_(Path.Combine(data, "programs", "k1", "prog.sha256"), 64);
        File_(Path.Combine(data, "programs", "k2", "prog"), 100_000);
        File_(Path.Combine(data, "programs", "stray.txt"), 7);
        File_(Path.Combine(data, "scripts", "a"), 1);
        File_(Path.Combine(data, "scripts", "b"), 1);
        File_(Path.Combine(data, "scripts", "c.tmp"), 1);
        File_(Path.Combine(root, cache, "keep.txt"), 3);
    }

    private static void Project(string root)
    {
        Directory.CreateDirectory(root);
        File.WriteAllText(Path.Combine(root, "package.byn"), "package demo\n");
        File_(Path.Combine(root, "out", "safe", "x", "main.c"), 10);
        File_(Path.Combine(root, "out", "safe", "x", "demo"), 20);
        File_(Path.Combine(root, "dist", "demo.tar"), 30);
        File_(Path.Combine(root, "other", "keep"), 1);
    }

    private static void SeededProject(string root) { Project(root); Seeded(root); }

    [Fact] public void StatsOfNoCache() => Same("stats-none", Nothing, "cache", "stats");
    [Fact] public void StatsOfASeededCache() => Same("stats-seeded", Seeded, "cache", "stats");
    [Fact] public void CacheWithoutStatsIsUsage() => Same("cache-usage", Seeded, "cache");
    [Fact] public void CacheWithAnotherArgumentIsUsage() => Same("cache-other", Seeded, "cache", "wipe");
    [Fact] public void CacheStatsWithAnExtraArgumentIsUsage() => Same("cache-extra", Seeded, "cache", "stats", "more");
    [Fact] public void CleanCacheOutsideAProject() => Same("clean-cache", Seeded, "clean", "--cache");
    [Fact] public void CleanCacheOfAnEmptyCache() => Same("clean-cache-empty", Nothing, "clean", "--cache");
    [Fact] public void CleanCacheInAProject() => Same("clean-cache-project", SeededProject, "clean", "--cache");
    [Fact] public void CleanAProjectInTheWorkingDirectory() => Same("clean-cwd", Project, "clean");
    [Fact] public void CleanAProjectKeepsDistWithoutTheFlag() => Same("clean-nodist", Project, "clean", ".");
    [Fact] public void CleanAProjectWithDist() => Same("clean-dist", Project, "clean", "--dist");
    [Fact] public void CleanAProjectWithDistAndCache() => Same("clean-all", SeededProject, "clean", "--dist", "--cache");
    [Fact] public void CleanAProjectByPathWithCache() => Same("clean-path", s => { Project(Path.Combine(s, "app")); Seeded(s); }, "clean", "app", "--cache");
    [Fact] public void CleanAProjectWithNothingBuilt() => Same("clean-nothing", s => File.WriteAllText(Path.Combine(s, "package.byn"), "package demo\n"), "clean", "--dist");
    [Fact] public void CleanOutsideAProject() => Same("clean-not-project", Nothing, "clean");
    [Fact] public void CleanAMissingDirectory() => Same("clean-missing", Nothing, "clean", "nowhere");
    [Fact] public void CleanDistOutsideAProject() => Same("clean-dist-not-project", Nothing, "clean", "--dist");
    [Fact] public void CleanAnUnknownOptionIsUsage() => Same("clean-option", Project, "clean", "--bogus");
    [Fact] public void CleanTwoPathsIsUsage() => Same("clean-two", Project, "clean", ".", "other");

    private static void SeededDefaults(string root)
    {
        Seeded(root, Path.Combine("home", "Library", "Caches", "bayan"));
        Seeded(root, Path.Combine("home", ".cache", "bayan"));
    }

    private static Dictionary<string, string?> Home(string root, string? cache) => new() { ["HOME"] = Path.Combine(root, "home"), ["BAYAN_CACHE"] = cache };

    [Fact] public void StatsOfTheDefaultCache() => Same("stats-default", SeededDefaults, r => Home(r, null), "cache", "stats");
    [Fact] public void StatsWithAnEmptyBayanCacheUsesTheDefault() => Same("stats-empty-var", SeededDefaults, r => Home(r, ""), "cache", "stats");
    [Fact] public void CleanCacheOfTheDefaultCache() => Same("clean-default", SeededDefaults, r => Home(r, null), "clean", "--cache");

    private static void Source(string root) => File.WriteAllText(Path.Combine(root, "main.byn"), "i32 main() {\n    return 0\n}\n");

    [Theory]
    [InlineData("lex")]
    [InlineData("parse", "--ast")]
    [InlineData("types")]
    [InlineData("check")]
    public void TheCommandsRunBeforeTheCacheArmsStillMatch(string command, string? option = null) =>
        Same("dispatch-" + command, Source, option is null ? [command, "main.byn"] : [command, option, "main.byn"]);
}
