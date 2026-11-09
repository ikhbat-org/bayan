using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Bayan.Backend.C;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 017 T12: <c>bayan dist</c> of the self-hosted driver (<c>selfhost/driver/dist.byn</c>, <c>compareVersions</c> in
/// <c>selfhost/semantics/manifest.byn</c>). Every row runs one argv sequence on two trees seeded alike, the C# <c>bayan</c> (its assembly
/// under <c>dotnet</c>) on the first and the stage-2 driver on the second, and compares per step the exit code and the streams (the root
/// masked), and after the last the whole <c>dist/</c> tree: relative names, Unix modes, and the text of <c>SHA256SUMS</c>,
/// <c>BUILDINFO.json</c>, <c>VERSION</c> and any other text file. The executables' bytes are not compared (their names, modes and the
/// consistency of <c>SHA256SUMS</c> with each tree's own executables are). The expected values are the C#'s run, never typed.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed class SelfhostDefaultT12Tests
{
    /// <summary>One argv run on both trees; <see cref="Before"/> runs on each tree first, <see cref="Env"/> adds variables (null unsets; <c>&lt;root&gt;</c> is the tree).</summary>
    private sealed record Step(string[] Args, Action<string>? Before = null, (string Name, string? Value)[]? Env = null);

    private static string Fresh(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t12", name);
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        return dir;
    }

    private static (int Exit, string Out, string Err) Bayan(bool driver, string cwd, (string Name, string? Value)[] env, string[] args)
    {
        var psi = new ProcessStartInfo(driver ? SelfhostDriverHarness.Build() : "dotnet") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, WorkingDirectory = cwd };
        if (!driver) psi.ArgumentList.Add(typeof(CliApp).Assembly.Location);
        psi.Environment["BAYAN_CACHE"] = Path.Combine(cwd, "cache");
        psi.Environment.Remove("BAYAN_CC");
        foreach (var (name, value) in env)
            if (value is null) psi.Environment.Remove(name); else psi.Environment[name] = value;
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"));
    }

    /// <summary>The root, the OS message of a failed cache write the elapsed time and the staging directory of a compiler diagnostic (the driver cannot set the compiler's working directory, so it prints the path the C# prints bare) masked.</summary>
    private static string Masked(string text, string root)
    {
        var masked = Regex.Replace(text.Replace(root, "<root>"), @"<root>/cache/v1/tmp/[^/\s]+/", "");
        masked = Regex.Replace(masked, @"(cannot write the build output or cache \(<root>[^)]*\)): .*", "$1: <message>");
        return Regex.Replace(masked, @" in \d+\.\d+s", " in <time>");
    }

    /// <summary>A new app <c>tally</c> in <paramref name="root"/>, made by the C#; <paramref name="options"/> go to <c>new</c>.</summary>
    private static Action<string> NewApp(params string[] options) => root =>
    {
        var exit = CliApp.Run(["new", Path.Combine(root, "tally"), "--vcs", "none", .. options], new StringWriter(), new StringWriter());
        Assert.Equal(CliApp.ExitOk, exit);
    };

    private static string Project(string root) => Path.Combine(root, "tally");

    private static void SetVersion(string root, string version)
    {
        var path = Path.Combine(Project(root), "package.byn");
        File.WriteAllText(path, Regex.Replace(File.ReadAllText(path), "version: \"[^\"]*\"", $"version: \"{version}\""));
    }

    private static string Camel(string kebab) => Regex.Replace(kebab, "-(.)", m => m.Groups[1].Value.ToUpperInvariant());

    /// <summary>
    /// The tree under <paramref name="dist"/>: one line per entry, with the Unix mode of a file, and for a text file its content with the
    /// hashes of <c>SHA256SUMS</c> masked (checked against the tree's own executables here). An executable is its name and mode only.
    /// </summary>
    private static string Describe(string dist)
    {
        if (!Directory.Exists(dist)) return "<no dist>";
        var lines = new List<string>();
        foreach (var path in Directory.EnumerateFileSystemEntries(dist, "*", SearchOption.AllDirectories).OrderBy(p => Path.GetRelativePath(dist, p).Replace('\\', '/'), StringComparer.Ordinal))
        {
            var relative = Path.GetRelativePath(dist, path).Replace('\\', '/');
            if (Directory.Exists(path)) { lines.Add(relative + "/"); continue; }
            var mode = OperatingSystem.IsWindows() ? "" : Convert.ToString((int)File.GetUnixFileMode(path), 8);
            var bytes = File.ReadAllBytes(path);
            var isText = !bytes.Contains((byte)0) && relative.Split('/')[^1] is not ("tally" or "tally.exe" or "tally.wasm");
            if (!isText) { lines.Add($"{relative} {mode} <binary>"); continue; }
            var text = Encoding.UTF8.GetString(bytes);
            if (relative.EndsWith("SHA256SUMS", StringComparison.Ordinal))
            {
                foreach (var line in text.Split('\n', StringSplitOptions.RemoveEmptyEntries))
                    Assert.Equal(Convert.ToHexStringLower(SHA256.HashData(File.ReadAllBytes(Path.Combine(Path.GetDirectoryName(path)!, line[66..])))), line[..64]);
                text = Regex.Replace(text, "^[0-9a-f]{64}", "<hash>", RegexOptions.Multiline);
            }
            lines.Add($"{relative} {mode}\n{text}");
        }
        return string.Join("\n", lines);
    }

    private static string Inputs(string root)
    {
        var file = Path.Combine(Project(root), "dist");
        IEnumerable<string> infos = Directory.Exists(file) ? Directory.EnumerateFiles(file, "BUILDINFO.json", SearchOption.AllDirectories).Order(StringComparer.Ordinal) : [];
        return string.Join("\n", infos.Select(i => Regex.Match(File.ReadAllText(i), "\"inputs\": \"(sha256:[0-9a-f]{64})\"").Groups[1].Value));
    }

    /// <summary>
    /// The steps on two trees seeded alike (the C#'s first); exit code and masked streams compared per step, then the <c>dist/</c> trees, and
    /// the inputs hash each <c>BUILDINFO.json</c> prints against <see cref="Dist.InputsHash"/> of the tree. The C#'s masked stdout per step.
    /// </summary>
    private static List<(int Exit, string Out, string Err)> Same(string name, Action<string> seed, params Step[] steps) => Same(name, seed, outside: false, steps);

    private static List<(int Exit, string Out, string Err)> Same(string name, Action<string> seed, bool outside, params Step[] steps)
    {
        var dir = outside ? Directory.CreateTempSubdirectory("bayan-t12-").FullName : Fresh(name);
        var a = Path.Combine(dir, "cs");
        var b = Path.Combine(dir, "s2");
        var results = new List<(int, string, string)>();
        try
        {
            foreach (var root in new[] { a, b })
            {
                Directory.CreateDirectory(root);
                seed(root);
            }
            foreach (var step in steps)
            {
                (string, string?)[] Env(string root) => [.. (step.Env ?? []).Select(e => (e.Name, e.Value?.Replace("<root>", root)))];
                step.Before?.Invoke(a);
                var expected = Bayan(false, a, Env(a), step.Args);
                step.Before?.Invoke(b);
                var actual = Bayan(true, b, Env(b), step.Args);
                var label = $"{name}: {string.Join(' ', step.Args)}";
                Assert.True(expected.Exit == actual.Exit, $"exit of `{label}`: C# {expected.Exit}, driver {actual.Exit}\n{expected.Err}\n{actual.Err}");
                SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Masked(expected.Out, a), Masked(actual.Out, b));
                SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", Masked(expected.Err, a), Masked(actual.Err, b));
                results.Add((expected.Exit, Masked(expected.Out, a), Masked(expected.Err, a)));
            }
            SelfhostEmitterHarness.AssertSame($"dist tree of `{name}`", Masked(Describe(Path.Combine(Project(a), "dist")), a), Masked(Describe(Path.Combine(Project(b), "dist")), b));
            var inputs = Inputs(b);
            SelfhostEmitterHarness.AssertSame($"inputs of `{name}`", Inputs(a), inputs);
            var distinct = inputs.Split('\n', StringSplitOptions.RemoveEmptyEntries).Distinct().ToList();
            if (distinct.Count == 1) Assert.Equal(Dist.InputsHash(Project(b)), distinct[0]);
            return results;
        }
        finally
        {
            if (outside) TestDirs.Delete(dir);
        }
    }

    private static Step DistStep(params string[] args) => new(["dist", "tally", .. args]);

    // ── the layout, the messages, --force (OutputTests.DistWritesAVersionDirectoryAndLatest, AVersionDirectoryIsImmutableWithoutForce) ──

    [Fact]
    public void ADistWritesAVersionDirectoryAndLatest()
    {
        var r = Same("layout", NewApp(), DistStep(), DistStep(), DistStep("--force"));
        Assert.Equal(0, r[0].Exit);
        Assert.Equal(CliApp.ExitUsage, r[1].Exit);
        Assert.Contains("`dist/0.1.0/` already exists", r[1].Err);
        Assert.Equal(0, r[2].Exit);
    }

    [Fact]
    public void ForceReplacesTheVersionDirectory()
    {
        Same("force", NewApp(), DistStep(),
            new Step(["dist", "tally", "--force"], root => File.WriteAllText(Path.Combine(Project(root), "dist", "0.1.0", "marker"), "")));
    }

    /// <summary>The <c>--target</c> of each name the C# knows, and <c>host</c>: both sides build it or both refuse it the same way.</summary>
    [Theory]
    [InlineData("host")]
    [InlineData("linux-x64")]
    [InlineData("linux-arm64")]
    [InlineData("macos-x64")]
    [InlineData("macos-arm64")]
    [InlineData("windows-x64")]
    [InlineData("windows-arm64")]
    [InlineData("wasm32")]
    public void ATargetIsBuilt(string target)
    {
        Same($"target-{target}", NewApp(), DistStep("--target", target));
    }

    [Fact]
    public void AllTargetsAreBuilt()
    {
        Same("target-all", NewApp(), DistStep("--target", "all"));
    }

    [Fact]
    public void ABadTargetIsRefused()
    {
        var r = Same("target-bad", NewApp(), DistStep("--target", "nope"), DistStep("--target", "all", "--mode", "fast"));
        Assert.Equal(CliApp.ExitUsage, r[0].Exit);
        Assert.Contains("unknown target `nope` (expected host, all, ", r[0].Err);
    }

    /// <summary><c>dist.targets</c> of the manifest: the host named twice (by <c>host</c> and by its name) is one target.</summary>
    [Fact]
    public void TheManifestTargetsAreDeduplicated()
    {
        Same("targets-manifest", root =>
        {
            NewApp()(root);
            var manifest = Path.Combine(Project(root), "package.byn");
            File.WriteAllText(manifest, File.ReadAllText(manifest).Replace("[.host]", $"[.host, .{Camel(Targets.Host!)}]"));
        }, DistStep());
    }

    [Fact]
    public void ABadManifestTargetIsRefused()
    {
        var r = Same("targets-manifest-bad", root =>
        {
            NewApp()(root);
            var manifest = Path.Combine(Project(root), "package.byn");
            File.WriteAllText(manifest, File.ReadAllText(manifest).Replace("[.host]", "[.host, .nowhere]"));
        }, DistStep());
        Assert.NotEqual(0, r[0].Exit);
    }

    [Fact]
    public void TheManifestModeIsTheDefault()
    {
        Same("mode-manifest", root =>
        {
            NewApp()(root);
            var manifest = Path.Combine(Project(root), "package.byn");
            Assert.Contains("mode:", File.ReadAllText(manifest));
            File.WriteAllText(manifest, Regex.Replace(File.ReadAllText(manifest), @"mode: \.\w+", "mode: .fast"));
        }, DistStep(), DistStep("--mode", "debug", "--force"));
    }

    // ── arguments ────────────────────────────────────────────────────────────────

    [Theory]
    [InlineData("--mode", "debug")]
    [InlineData("--mode", "fast")]
    [InlineData("--mode", "bogus")]
    [InlineData("--diagnostics", "json")]
    [InlineData("--diagnostics", "text")]
    [InlineData("--diagnostics", "bad")]
    [InlineData("--diagnostics")]
    [InlineData("--target")]
    [InlineData("--mode")]
    [InlineData("--nope")]
    public void AnArgumentIsParsedAsTheCSharpDoes(params string[] args)
    {
        Same($"args-{string.Join('-', args)}", NewApp(), DistStep(args));
    }

    [Fact]
    public void ASecondPathIsAnUnexpectedArgument()
    {
        var r = Same("args-two-paths", NewApp(), new Step(["dist", "tally", "other"]));
        Assert.Contains("unexpected argument `other`", r[0].Err);
    }

    [Fact]
    public void ATargetAfterThePathAndAFlagBeforeIt()
    {
        Same("args-order", NewApp(), new Step(["dist", "--allow-dirty", "--target", "host", "tally"]));
    }

    [Fact]
    public void TheCurrentDirectoryIsTheDefaultPath()
    {
        Same("args-dot", root =>
        {
            NewApp()(root);
            foreach (var f in Directory.GetFileSystemEntries(Project(root))) Directory.Move(f, Path.Combine(root, Path.GetFileName(f)));
            Directory.Delete(Project(root));
        }, outside: false, new Step(["dist"]));
    }

    [Fact]
    public void AScriptAndADirectoryWithoutAManifestHaveNoDist()
    {
        var r = Same("not-project", NewApp(), new Step(["dist", Path.Combine("tally", "src", "app", "main.byn")]), new Step(["dist", "."]));
        Assert.Contains("have no dist", r[0].Err);
        Assert.Contains("have no dist", r[1].Err);
    }

    [Fact]
    public void ALibraryHasNoDistYet()
    {
        var r = Same("library", NewApp("--lib"), DistStep());
        Assert.Contains("library distribution arrives later", r[0].Err);
    }

    [Fact]
    public void ABrokenProgramIsNotDistributed()
    {
        var r = Same("broken", root =>
        {
            NewApp()(root);
            File.AppendAllText(Path.Combine(Project(root), "src", "app", "main.byn"), "\ni32 broken() { return \"no\" }\n");
        }, DistStep());
        Assert.Equal(CliApp.ExitFailure, r[0].Exit);
    }

    /// <summary>A cache that cannot be written fails the build: the staging directory is removed and the exit is the toolchain's.</summary>
    [Fact]
    public void AFailedBuildLeavesNoStaging()
    {
        var r = Same("toolchain", NewApp(), DistStep(), new Step(["dist", "tally", "--force"], root => { File.WriteAllText(Path.Combine(root, "cachefile"), ""); }, [("BAYAN_CACHE", "<root>/cachefile")]));
        Assert.Equal(CliApp.ExitToolchain, r[1].Exit);
    }

    // ── git (Dist.ReadSource; OutputTests.ADirtyGitTreeNeedsAllowDirty) ────────────────

    private static void Git(string dir, params string[] args)
    {
        var git = Toolchain.FindOnPath("git")!;
        var psi = new ProcessStartInfo(git) { WorkingDirectory = dir, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in (string[])["-c", "user.name=t12", "-c", "user.email=t12@example.org", "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", .. args]) psi.ArgumentList.Add(a);
        psi.Environment["GIT_AUTHOR_DATE"] = psi.Environment["GIT_COMMITTER_DATE"] = "2026-01-01T00:00:00Z";
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEnd();
        var stderr = p.StandardError.ReadToEnd();
        p.WaitForExit();
        Assert.True(p.ExitCode == 0, $"git {string.Join(' ', args)}: {stdout}{stderr}");
    }

    private static Action<string> InRepo(bool commit) => root =>
    {
        NewApp()(root);
        Git(Project(root), "init", "--quiet");
        if (commit)
        {
            Git(Project(root), "add", "-A");
            Git(Project(root), "commit", "--quiet", "-m", "first");
        }
    };

    [Fact]
    public void ACleanRepositoryRecordsItsCommit()
    {
        var r = Same("git-clean", InRepo(true), DistStep());
        Assert.Equal(0, r[0].Exit);
    }

    [Fact]
    public void ARepositoryWithoutACommitIsDirty()
    {
        var r = Same("git-nocommit", InRepo(false), DistStep(), DistStep("--allow-dirty"));
        Assert.Equal(CliApp.ExitUsage, r[0].Exit);
        Assert.Contains("--allow-dirty", r[0].Err);
    }

    [Fact]
    public void ADirtyTreeNeedsAllowDirty()
    {
        var r = Same("git-dirty", InRepo(true), new Step(["dist", "tally"], root => File.AppendAllText(Path.Combine(Project(root), "src", "app", "main.byn"), "\n")), DistStep("--allow-dirty"));
        Assert.Equal(CliApp.ExitUsage, r[0].Exit);
        Assert.Equal(0, r[1].Exit);
    }

    /// <summary>The enclosing repository ignores the project: no commit is traced, and the tree is not dirty.</summary>
    [Fact]
    public void AnIgnoredProjectHasNoSource()
    {
        Same("git-ignored", root =>
        {
            NewApp()(root);
            Git(root, "init", "--quiet");
            File.WriteAllText(Path.Combine(root, ".gitignore"), "tally/\n");
        }, DistStep());
    }

    [Fact]
    public void AProjectOutsideAnyRepositoryHasNoSource()
    {
        var r = Same("git-outside", NewApp(), outside: true, DistStep());
        Assert.Equal(0, r[0].Exit);
    }

    /// <summary>The host named with an empty <c>dist.targets</c> falls back to the host; two targets are listed in the manifest's order.</summary>
    [Fact]
    public void AnEmptyManifestTargetListMeansTheHost()
    {
        Same("targets-empty", root =>
        {
            NewApp()(root);
            var manifest = Path.Combine(Project(root), "package.byn");
            File.WriteAllText(manifest, File.ReadAllText(manifest).Replace("[.host]", "[]"));
        }, DistStep());
    }

    [Fact]
    public void SeveralManifestTargetsAreBuiltInOrder()
    {
        var other = Targets.Host == "linux-x64" ? "linux-arm64" : "linux-x64";
        Same("targets-two", root =>
        {
            NewApp()(root);
            var manifest = Path.Combine(Project(root), "package.byn");
            File.WriteAllText(manifest, File.ReadAllText(manifest).Replace("[.host]", $"[.{Camel(other)}, .host]"));
        }, DistStep());
    }

    /// <summary>A staging directory a killed run left is replaced, not merged into.</summary>
    [Fact]
    public void AStaleStagingDirectoryIsReplaced()
    {
        Same("stale-staging", root =>
        {
            NewApp()(root);
            Directory.CreateDirectory(Path.Combine(Project(root), "dist", ".0.1.0.tmp"));
            File.WriteAllText(Path.Combine(Project(root), "dist", ".0.1.0.tmp", "leftover"), "x");
            Directory.CreateDirectory(Path.Combine(Project(root), "dist", ".latest.tmp"));
            File.WriteAllText(Path.Combine(Project(root), "dist", ".latest.tmp", "leftover"), "x");
        }, DistStep());
    }

    /// <summary>A file named like a version is not a release.</summary>
    [Fact]
    public void AFileNamedLikeAVersionIsNotARelease()
    {
        Same("file-version", root =>
        {
            NewApp()(root);
            Directory.CreateDirectory(Path.Combine(Project(root), "dist"));
            File.WriteAllText(Path.Combine(Project(root), "dist", "7.7.7"), "x");
        }, DistStep());
    }

    /// <summary>With no <c>git</c> on the path nothing is traced: the compiler is the only tool left there.</summary>
    [Fact]
    public void WithoutGitThereIsNoSource()
    {
        if (OperatingSystem.IsWindows()) return;
        var cc = Toolchain.FindOnPath("cc");
        Assert.NotNull(cc);
        Same("git-absent", root =>
        {
            NewApp()(root);
            Directory.CreateDirectory(Path.Combine(root, "bin"));
            File.CreateSymbolicLink(Path.Combine(root, "bin", "cc"), cc!);
        }, outside: false, new Step(["dist", "tally"], null, [("PATH", "<root>/bin")]));
    }

    /// <summary>A project inside <c>.git/</c> is in no work tree: <c>--is-inside-work-tree</c> prints <c>false</c>.</summary>
    [Fact]
    public void AProjectInsideTheGitDirectoryHasNoSource()
    {
        Same("git-inside-gitdir", root =>
        {
            Git(root, "init", "--quiet");
            var exit = CliApp.Run(["new", Path.Combine(root, ".git", "tally"), "--vcs", "none"], new StringWriter(), new StringWriter());
            Assert.Equal(CliApp.ExitOk, exit);
        }, new Step(["dist", Path.Combine(".git", "tally")]));
    }

    /// <summary>A repository whose index is unreadable: <c>status</c> fails and the tree counts as dirty.</summary>
    [Fact]
    public void AFailingStatusCountsAsDirty()
    {
        var r = Same("git-bad-index", root =>
        {
            InRepo(true)(root);
            File.WriteAllText(Path.Combine(Project(root), ".git", "index"), "not an index");
        }, DistStep());
        Assert.Equal(CliApp.ExitUsage, r[0].Exit);
    }

    // ── RefreshLatest and Manifest.CompareVersions (OutputTests.LatestIsTheHighestVersionNotTheNewestBuild) ──

    private static Step Release(string version) => new(["dist", "tally"], root => SetVersion(root, version));

    /// <summary>
    /// Releases in the order given; <c>latest/</c> is the highest by semantic version after each: numeric not lexical, a release above its
    /// prereleases, prerelease text ordinally (<c>rc.10</c> below <c>rc.2</c>, a prefix below the longer), build metadata ignored. A stray
    /// directory and file beside the versions, and a version holding a subdirectory and a file of an odd mode, are copied or skipped as the C# does.
    /// </summary>
    [Fact]
    public void LatestIsTheHighestVersionNotTheNewestBuild()
    {
        Same("latest", root =>
        {
            NewApp()(root);
            var dist = Path.Combine(Project(root), "dist");
            Directory.CreateDirectory(Path.Combine(dist, "notes"));
            File.WriteAllText(Path.Combine(dist, "stray.txt"), "x");
            var deep = Path.Combine(dist, "0.0.1", "sub", "deep");
            Directory.CreateDirectory(deep);
            File.WriteAllText(Path.Combine(deep, "tool"), "t");
            File.WriteAllText(Path.Combine(dist, "0.0.1", "top"), "t");
            if (!OperatingSystem.IsWindows())
            {
                File.SetUnixFileMode(Path.Combine(deep, "tool"), (UnixFileMode)Convert.ToInt32("751", 8));
                File.SetUnixFileMode(Path.Combine(dist, "0.0.1", "top"), (UnixFileMode)Convert.ToInt32("444", 8));
            }
        },
            Release("0.1.0"), Release("0.2.0-rc.1"), Release("0.0.9"), Release("0.2.0"), Release("0.10.0"),
            Release("0.10.0-b"), Release("1.0.0-rc.2"), Release("1.0.0-rc.10"), Release("1.0.0-rc"), Release("1.0.0-b"),
            Release("1.0.0-rc.2+meta"), Release("1.0.0+build"), Release("1.0.0"), Release("1.0.1"), Release("1.1.0"), Release("2.0.0"));
    }

    [Fact]
    public void AnOlderVersionLeavesLatestAlone()
    {
        var r = Same("latest-old", NewApp(), Release("3.0.0"), Release("2.9.9"), Release("3.0.0-z"));
        Assert.Contains("is 3.0.0", r[2].Out);
    }

    [Fact]
    public void ForcingTheHighestVersionRefreshesLatest()
    {
        Same("latest-force", NewApp(), Release("1.0.0"), new Step(["dist", "tally", "--force"], root => File.WriteAllText(Path.Combine(Project(root), "src", "app", "extra.txt"), "")));
    }

    // ── InputsHash follows no link (CliMemoryBoundsTests.M4_InputsHashDoesNotFollowLinks) ────

    /// <summary>
    /// A link to a directory (a loop, and one to a sibling holding sources), a link to a file, a dangling link, a <c>.BYN</c> file and a hidden
    /// directory under <c>src/</c>: the hash printed equals the C#'s and <see cref="Dist.InputsHash"/>'s, and with the links removed it is the same.
    /// </summary>
    [Fact]
    public void TheInputsHashDoesNotFollowLinks()
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Fresh("inputs-links");
        var inputs = new List<string>();
        foreach (var variant in new[] { "plain", "links" })
        {
            var cs = Path.Combine(dir, variant, "cs");
            var s2 = Path.Combine(dir, variant, "s2");
            foreach (var root in new[] { cs, s2 })
            {
                Directory.CreateDirectory(root);
                NewApp()(root);
                var src = Path.Combine(Project(root), "src");
                Directory.CreateDirectory(Path.Combine(src, ".hidden"));
                File.WriteAllText(Path.Combine(src, ".hidden", "h.byn"), "// hidden\n");
                File.WriteAllText(Path.Combine(src, "Upper.BYN"), "// upper\n");
                Directory.CreateDirectory(Path.Combine(src, "util"));
                File.WriteAllText(Path.Combine(src, "util", "u.byn"), "// util\n");
                if (variant == "links")
                {
                    Directory.CreateSymbolicLink(Path.Combine(src, "loop"), "..");
                    Directory.CreateSymbolicLink(Path.Combine(src, "alias"), "util");
                    Directory.CreateSymbolicLink(Path.Combine(src, "link.byn"), Path.Combine("util", "u.byn"));
                    Directory.CreateSymbolicLink(Path.Combine(src, "dangling.byn"), "nowhere.byn");
                }
            }
            var expected = Bayan(false, cs, [], ["dist", "tally"]);
            var actual = Bayan(true, s2, [], ["dist", "tally"]);
            Assert.True(expected.Exit == 0 && actual.Exit == 0, expected.Err + actual.Err);
            Assert.Equal(Inputs(cs), Inputs(s2));
            Assert.EndsWith(Dist.InputsHash(Project(s2)), Inputs(s2));
            inputs.Add(Inputs(s2));
        }
        Assert.Equal(inputs[0], inputs[1]);
    }

    /// <summary>A link to the source directory itself is followed as the C# does (the root of the enumeration), a link below it is not.</summary>
    [Fact]
    public void AnInputsRootThatIsALinkIsFollowed()
    {
        if (OperatingSystem.IsWindows()) return;
        Same("inputs-root-link", root =>
        {
            NewApp()(root);
            var src = Path.Combine(Project(root), "src");
            Directory.Move(src, Path.Combine(root, "real-src"));
            Directory.CreateSymbolicLink(src, Path.Combine(root, "real-src"));
        }, DistStep());
    }

    [Fact]
    public void AnAppWithoutItsSourceDirectoryIsRefused()
    {
        var r = Same("inputs-nosrc", root =>
        {
            NewApp()(root);
            Directory.Delete(Path.Combine(Project(root), "src"), recursive: true);
        }, DistStep());
        Assert.NotEqual(0, r[0].Exit);
    }

    // ── main.byn `run`: the arms around `dist` (the function is touched by the `dist` arm, so every arm runs here) ──

    /// <summary>Every other command of <c>run</c>, and its refusals, through both drivers: the same streams as the C#.</summary>
    [Theory]
    [InlineData("--ascii")]
    [InlineData("--color", "bogus", "help")]
    [InlineData("help")]
    [InlineData("--ascii", "-h")]
    [InlineData("lex", "tally/src/app/main.byn")]
    [InlineData("types", "tally/src/app/main.byn")]
    [InlineData("format", "tally/src/app/main.byn", "--check")]
    [InlineData("audit", "tally")]
    [InlineData("features", "tally")]
    [InlineData("explain", "BYN1001")]
    [InlineData("check", "tally")]
    [InlineData("build", "tally")]
    [InlineData("run", "tally")]
    [InlineData("cache", "path")]
    [InlineData("clean")]
    [InlineData("init", "other")]
    [InlineData("tally/src/app/main.byn")]
    [InlineData("tally/src/app/main.byn", "extra")]
    [InlineData("missing.byn")]
    [InlineData("new", "other", "--vcs", "none")]
    [InlineData("frob")]
    [InlineData("fmt")]
    public void EveryOtherArmOfRunIsTheCSharps(params string[] args)
    {
        Same($"run-{string.Join('-', args).Replace('/', '_')}", NewApp(), new Step(args));
    }

    /// <summary>The commands the driver does not port refuse by name (spec Q4); the C# runs them, so the streams differ by design.</summary>
    [Theory]
    [InlineData("parse", "tally/src/app/main.byn")]
    [InlineData("test")]
    [InlineData("mutate")]
    public void ARefusedArmNamesItsCommand(params string[] args)
    {
        var dir = Fresh($"refused-{args[0]}");
        NewApp()(dir);
        var (exit, _, stderr) = Bayan(true, dir, [], args);
        Assert.NotEqual(0, exit);
        Assert.Contains($"`{args[0]}` is not available in the self-hosted compiler", stderr);
    }

    /// <summary>The version line and the doctor report name the build (the C#'s commit, the driver's <c>selfhost</c>): checked on the driver alone.</summary>
    [Fact]
    public void TheVersionAndDoctorArmsAnswer()
    {
        var (exit, stdout, _) = SelfhostDriverHarness.Run("--version");
        Assert.Equal(0, exit);
        Assert.StartsWith("bayan ", stdout);
        Assert.Equal(stdout, SelfhostDriverHarness.Run("version").Out);
        Assert.Equal(0, SelfhostDriverHarness.Run("doctor").Exit);
    }

    [Fact]
    public void TheDistArmRoutesToTheCommand()
    {
        var (exit, _, stderr) = SelfhostDriverHarness.Run("dist", "--bogus");
        Assert.Equal(CliApp.ExitUsage, exit);
        Assert.Equal("bayan: unexpected argument `--bogus`\nusage: bayan dist [<dir>] [--target <t>|all] [--mode debug|safe|fast] [--force] [--allow-dirty]\n", stderr);
    }
}
