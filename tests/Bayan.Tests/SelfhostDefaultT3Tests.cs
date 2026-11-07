using System.Diagnostics;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Reflection;
using Bayan.Cli;
using Bayan.Syntax.Diagnostics;

namespace Bayan.Tests;

/// <summary>
/// 017 T3: <c>cache stats</c> and <c>clean</c> against <see cref="CliApp.Run"/> (L028): the same argv on two identical trees,
/// stdout, stderr, exit code and the tree left behind compared, the cache and root paths masked. The oracle runs in-process, so
/// it sets <c>BAYAN_CACHE</c> and the working directory of the test process (hence the collection).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDefaultT3Tests
{
    private static readonly string Base = Path.Combine(Golden.RepoRoot, "tmp", "driver-t3");

    /// <summary>A fresh tree under <c>tmp/driver-t3/&lt;side&gt;/&lt;name&gt;</c>, filled by <paramref name="seed"/> (given the root).</summary>
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
        var culture = CultureInfo.CurrentCulture;
        CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
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
            CultureInfo.CurrentCulture = culture;
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
        File_(Path.Combine(data, "CACHEDIR.TAG"), 170);
        File_(Path.Combine(data, "programs", "k1", "program"), 1_572_864);
        File_(Path.Combine(data, "programs", "k1", "program.sha256"), 64);
        File_(Path.Combine(data, "programs", "k2", "program"), 100_000);
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

    private static void LinkedDist(string root)
    {
        var app = Path.Combine(root, "app");
        Project(app);
        File_(Path.Combine(root, "outside", "keep.txt"), 5);
        Directory.CreateSymbolicLink(Path.Combine(app, "dist", "link"), Path.Combine("..", "..", "outside"));
    }

    /// <summary>A project whose <c>out</c> (and <c>dist</c>, and the cache's <c>v1</c>) is a symlink to <c>outside/</c>, which holds files.</summary>
    private static void LinkedTop(string root)
    {
        Directory.CreateDirectory(root);
        File.WriteAllText(Path.Combine(root, "package.byn"), "package demo\n");
        File_(Path.Combine(root, "outside", "keep.txt"), 5);
        File_(Path.Combine(root, "outside", "sub", "f"), 6);
        Directory.CreateSymbolicLink(Path.Combine(root, "out"), "outside");
        Directory.CreateSymbolicLink(Path.Combine(root, "dist"), "outside");
        Directory.CreateDirectory(Path.Combine(root, "cache"));
        Directory.CreateSymbolicLink(Path.Combine(root, "cache", "v1"), Path.Combine("..", "outside"));
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
    [Fact]
    public void CleanDoesNotFollowASymlinkToADirectory()
    {
        if (OperatingSystem.IsWindows()) return;
        Same("clean-link", LinkedDist, "clean", "app", "--dist");
        Assert.True(File.Exists(Path.Combine(Base, "s2", "clean-link", "outside", "keep.txt")));
    }

    [Fact]
    public void CleanRemovesATopLevelSymlinkAndKeepsItsTarget()
    {
        if (OperatingSystem.IsWindows()) return;
        Same("clean-top-link", LinkedTop, "clean", "--dist", "--cache");
        Assert.True(File.Exists(Path.Combine(Base, "s2", "clean-top-link", "outside", "sub", "f")));
    }

    /// <summary>The C# throws (unhandled exception, exit 134); the driver panics: no `removed`, a non-zero exit, the tree kept (Q1085).</summary>
    [System.Runtime.Versioning.UnsupportedOSPlatform("windows")]
    private static void RefusesToReport(string name, Action<string> seed, string locked, string culprit)
    {
        var root = Tree(name, "s2", seed);
        var dir = Path.Combine(root, locked);
        File.SetUnixFileMode(dir, UnixFileMode.UserRead | UnixFileMode.UserExecute);
        try
        {
            var r = Stage2(root, new Dictionary<string, string?>(), "clean");
            Assert.NotEqual(0, r.Exit);
            Assert.DoesNotContain("removed", r.Out); // no-oracle: Q1085
            Assert.True(Directory.Exists(Path.Combine(root, "out")));
            Assert.Contains($"cannot remove {Path.Combine(root, culprit)}", r.Err); // no-oracle: Q1085
        }
        finally { File.SetUnixFileMode(dir, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
    }

    [Fact]
    public void CleanDoesNotReportAFileItCannotRemove()
    {
        if (OperatingSystem.IsWindows() || Environment.UserName == "root") return;
        RefusesToReport("clean-locked-file", r => { Project(r); File_(Path.Combine(r, "out", "locked", "f"), 1); }, Path.Combine("out", "locked"), Path.Combine("out", "locked", "f"));
    }

    [Fact]
    public void CleanDoesNotReportADirectoryItCannotRemove()
    {
        if (OperatingSystem.IsWindows() || Environment.UserName == "root") return;
        RefusesToReport("clean-locked-dir", r => { Project(r); Directory.CreateDirectory(Path.Combine(r, "out", "locked", "empty")); }, Path.Combine("out", "locked"), Path.Combine("out", "locked", "empty"));
    }

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
