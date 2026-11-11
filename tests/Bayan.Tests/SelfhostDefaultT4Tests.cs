using System.Diagnostics;
using System.Text;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// Spec 017 T4: <c>bayan new</c> and <c>bayan init</c> of <c>selfhost/driver/scaffold.byn</c> against the C# CLI (<c>Scaffold.cs</c>).
/// Each row runs the same argv under the C# process and the stage-1 driver in two fresh directories and compares stdout, stderr,
/// the exit code and the written tree (names, bytes, executable bit); the directory is masked as <c>&lt;D&gt;</c>.
/// </summary>
[Trait("Snapshot", "skip")]  // runs need cwd, PATH, closed stdin and change the tree (review 233d35d finding 7)
public sealed class SelfhostDefaultT4Tests
{
    private sealed record Result(int Exit, string Out, string Err);

    private static Result Start(string program, string[] prefix, string cwd, string[] args, string? path)
    {
        var psi = new ProcessStartInfo(program)
        {
            RedirectStandardOutput = true,
            StandardOutputEncoding = Encoding.UTF8,
            RedirectStandardError = true,
            StandardErrorEncoding = Encoding.UTF8,
            RedirectStandardInput = true,
            UseShellExecute = false,
            WorkingDirectory = cwd,
        };
        if (path is not null) psi.Environment["PATH"] = path;
        foreach (var a in prefix) psi.ArgumentList.Add(a);
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        p.StandardInput.Close();
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        Assert.True(p.WaitForExit(120_000), $"{program} {string.Join(' ', args)}: timed out");
        return new Result(p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"));
    }

    /// <summary>A fresh directory outside the repository (so `git init` has no enclosing work tree).</summary>
    private static string Fresh()
    {
        var dir = Directory.CreateTempSubdirectory("bayan-t4-").FullName;
        return Path.GetFullPath(dir);
    }

    /// <summary>Every file under <paramref name="root"/> with its bytes and, for a `#!` file, its executable bit; `.git` is a name only.</summary>
    private static string Tree(string root, bool plain = false)
    {
        var sb = new StringBuilder();
        foreach (var entry in Directory.EnumerateFileSystemEntries(root, "*", SearchOption.AllDirectories)
                                       .Select(f => Path.GetRelativePath(root, f).Replace('\\', '/'))
                                       .Where(f => f == ".git" || !f.StartsWith(".git/"))
                                       .Order(StringComparer.Ordinal))
        {
            var full = Path.Combine(root, entry);
            if (Directory.Exists(full)) { if (!plain) sb.Append("dir ").Append(entry).Append('\n'); continue; }
            sb.Append("=== ").Append(entry).Append('\n');
            var text = File.ReadAllText(full);
            if (!plain && text.StartsWith("#!", StringComparison.Ordinal) && !OperatingSystem.IsWindows())
                sb.Append("mode ").Append((File.GetUnixFileMode(full) & (UnixFileMode.UserExecute | UnixFileMode.GroupExecute | UnixFileMode.OtherExecute)) != 0 ? "x" : "-").Append('\n');
            sb.Append(text);
        }
        return sb.ToString();
    }

    private static string[] Words(string args) => args.Split(' ', StringSplitOptions.RemoveEmptyEntries);

    private static string Mask(string text, string dir) => text.Replace(dir, "<D>");

    /// <summary>Runs <paramref name="args"/> (with <c>{D}</c> standing for the directory) under both CLIs after <paramref name="setup"/>.</summary>
    private static void Same(string[] args, Action<string>? setup = null, string? path = null, string? relativeCwd = null, string? contains = null)
    {
        var cs = Fresh();
        var s1 = Fresh();
        try
        {
            setup?.Invoke(cs);
            setup?.Invoke(s1);
            var csCwd = relativeCwd is null ? cs : Path.Combine(cs, relativeCwd);
            var s1Cwd = relativeCwd is null ? s1 : Path.Combine(s1, relativeCwd);
            var expected = Start("dotnet", [typeof(CliApp).Assembly.Location], csCwd, [.. args.Select(a => a.Replace("{D}", cs))], path);
            var actual = Start(SelfhostDriverHarness.Build(), [], s1Cwd, [.. args.Select(a => a.Replace("{D}", s1))], path);
            Assert.Equal(Mask(expected.Out, cs), Mask(actual.Out, s1));
            if (contains is not null) Assert.Contains(contains, actual.Out);
            Assert.Equal(Mask(expected.Err, cs), Mask(actual.Err, s1));
            Assert.Equal(expected.Exit, actual.Exit);
            Assert.Equal(Mask(Tree(cs), cs), Mask(Tree(s1), s1));
        }
        finally
        {
            TestDirs.Delete(cs);
            TestDirs.Delete(s1);
        }
    }

    [Theory]
    [InlineData("new tally --vcs none")]
    [InlineData("new tally --vcs none --ci github")]
    [InlineData("new my-lib --lib --vcs none --ci github")]
    [InlineData("new myApp --vcs none --ci none")]
    [InlineData("new a1 --vcs none")]
    [InlineData("new a-1b --lib --vcs none")]
    [InlineData("new a-b-c --vcs none")]
    [InlineData("new tally/ --vcs none")]
    [InlineData("new {D}/abs --vcs none")]
    [InlineData("new tally --script")]
    [InlineData("new tally --lib --script --vcs none")]
    [InlineData("new {D}/abs --script")]
    [InlineData("new sub/tool --script")]
    public void NewWritesTheLayoutAsCSharp(string args) => Same(Words(args));

    [Theory]
    [InlineData("new tally")]
    [InlineData("new tally --vcs git")]
    [InlineData("new tally --lib --vcs git --ci github")]
    public void NewInitialisesGitAsCSharp(string args) => Same(Words(args));

    [Fact]
    public void NewWithoutGitOnThePathSaysSoAsCSharp() => Same(["new", "tally"], path: "");

    [Fact]
    public void RootedNewMatchesTheInProcessCSharp()
    {
        var cs = Fresh();
        var s1 = Fresh();
        try
        {
            var o = new StringWriter();
            var e = new StringWriter();
            var exit = CliApp.Run(["new", Path.Combine(cs, "tally"), "--lib", "--vcs", "none", "--ci", "github"], o, e);
            var actual = Start(SelfhostDriverHarness.Build(), [], s1, ["new", Path.Combine(s1, "tally"), "--lib", "--vcs", "none", "--ci", "github"], null);
            Assert.Equal(Mask(o.ToString().Replace("\r\n", "\n"), cs), Mask(actual.Out, s1));
            Assert.Equal(e.ToString(), actual.Err);
            Assert.Equal(exit, actual.Exit);
            Assert.Equal(Mask(Tree(cs), cs), Mask(Tree(s1), s1));
        }
        finally
        {
            TestDirs.Delete(cs);
            TestDirs.Delete(s1);
        }
    }

    [Fact]
    public void ScriptWithAnEmptyPathPanicsAtChmod()
    {
        // no-oracle: Q1089 (the C# sets the mode with File.SetUnixFileMode and succeeds; the driver starts `chmod` and panics)
        if (OperatingSystem.IsWindows()) return;
        var dir = Fresh();
        try
        {
            var r = Start(SelfhostDriverHarness.Build(), [], dir, ["new", "tally", "--script"], "");
            Assert.NotEqual(0, r.Exit);
            Assert.Contains("cannot make", r.Err);
            Assert.True(File.Exists(Path.Combine(dir, "tally.byn")));
            Assert.Equal((UnixFileMode)0, File.GetUnixFileMode(Path.Combine(dir, "tally.byn")) & (UnixFileMode.UserExecute | UnixFileMode.GroupExecute | UnixFileMode.OtherExecute));
        }
        finally { TestDirs.Delete(dir); }
    }

    [Fact]
    public void NewWithAGitKilledBySignalIsAsCSharp()
    {
        if (OperatingSystem.IsWindows()) return;
        var bin = Directory.CreateTempSubdirectory("bayan-t4-git-").FullName;
        try
        {
            var git = Path.Combine(bin, "git");
            File.WriteAllText(git, "#!/bin/sh\nkill -9 $$\n");
            File.SetUnixFileMode(git, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            Same(["new", "tally"], path: bin);
        }
        finally { TestDirs.Delete(bin); }
    }

    [Fact]
    public void NewInsideAGitRepositoryNotesItAsCSharp() =>
        Same(["new", "tally"], setup: dir => Assert.Equal(0, Start("git", [], dir, ["init", "--quiet"], null).Exit));

    [Theory]
    [InlineData("new")]
    [InlineData("new Bad_Name")]
    [InlineData("new 9lives")]
    [InlineData("new a--b")]
    [InlineData("new end-")]
    [InlineData("new struct --lib")]
    [InlineData("new struct --vcs none")]
    [InlineData("new a b")]
    [InlineData("new a --bogus")]
    [InlineData("new a --vcs hg")]
    [InlineData("new a --ci")]
    [InlineData("init --bogus")]
    [InlineData("init a b")]
    [InlineData("new a --vcs")]
    [InlineData("new a --ci hg")]
    [InlineData("new /")]
    [InlineData("new ~x")]
    [InlineData("new a~")]
    [InlineData("new a_b")]
    [InlineData("new a~b")]
    [InlineData("new a.b")]
    [InlineData("new a-B")]
    [InlineData("lex nowhere.byn")]
    [InlineData("parse --ast nowhere.byn")]
    [InlineData("types nowhere.byn")]
    [InlineData("check nowhere.byn")]
    public void NewAndInitRejectBadInputAsCSharp(string args) => Same(Words(args));

    [Fact]
    public void NewRefusesANonEmptyDirectoryAsCSharp() =>
        Same(["new", "tally", "--vcs", "none"], dir =>
        {
            Directory.CreateDirectory(Path.Combine(dir, "tally"));
            File.WriteAllText(Path.Combine(dir, "tally", "x.txt"), "x");
        });

    [Fact]
    public void NewAcceptsAnEmptyDirectoryAsCSharp() =>
        Same(["new", "tally", "--vcs", "none"], dir => Directory.CreateDirectory(Path.Combine(dir, "tally")));

    [Fact]
    public void NewRefusesAnExistingScriptAsCSharp() =>
        Same(["new", "tally", "--script"], dir => File.WriteAllText(Path.Combine(dir, "tally.byn"), "x"));

    [Theory]
    [InlineData("--vcs none")]
    [InlineData("--lib --vcs none --ci github")]
    [InlineData("--script")]
    [InlineData("")]
    public void InitWritesTheMissingFilesAsCSharp(string options) =>
        Same(["init", .. Words(options)], relativeCwd: "my-proj", setup: dir => Directory.CreateDirectory(Path.Combine(dir, "my-proj")));

    [Fact]
    public void InitSkipsFilesThatExistAsCSharp() =>
        Same(["init", "--vcs", "none"], relativeCwd: "proj", setup: dir =>
        {
            Directory.CreateDirectory(Path.Combine(dir, "proj"));
            File.WriteAllText(Path.Combine(dir, "proj", "README.md"), "mine\n");
            File.WriteAllText(Path.Combine(dir, "proj", ".gitignore"), "x\n");
        });

    [Fact]
    public void InitNamesAGivenDirectoryAsCSharp() =>
        Same(["init", "{D}/proj/", "--vcs", "none"], setup: dir => Directory.CreateDirectory(Path.Combine(dir, "proj")));

    [Fact]
    public void InitRefusesAPackageAsCSharp() =>
        Same(["init", "--vcs", "none"], relativeCwd: "proj", setup: dir =>
        {
            Directory.CreateDirectory(Path.Combine(dir, "proj"));
            File.WriteAllText(Path.Combine(dir, "proj", "package.byn"), "x");
        });

    [Fact]
    public void InitReportsAMissingDirectoryAsCSharp() => Same(["init", "nowhere"]);

    [Fact]
    public void InitRejectsABadDirectoryNameAsCSharp() =>
        Same(["init", "--vcs", "none"], relativeCwd: "Bad_Name", setup: dir => Directory.CreateDirectory(Path.Combine(dir, "Bad_Name")));

    [Fact]
    public void InitSaysWhenGitInitFailsAsCSharp() =>
        Same(["init"], relativeCwd: "proj", setup: dir =>
        {
            Directory.CreateDirectory(Path.Combine(dir, "proj"));
            File.WriteAllText(Path.Combine(dir, "proj", ".git"), "not a gitfile\n");
        }, contains: "`git init` failed");

    [Fact]
    public void InitInsideAGitDirectoryIsNotInsideAWorkTreeAsCSharp() =>
        Same(["init", "{D}/r/.git/refs"], setup: dir => Assert.Equal(0, Start("git", [], dir, ["init", "--quiet", "r"], null).Exit));

    [Theory]
    [InlineData("mutate")]
    public void StillRefusesTheCommandsOfTheOtherTasks(string command)
    {
        var dir = Fresh();
        try
        {
            var r = Start(SelfhostDriverHarness.Build(), [], dir, [command], null);
            Assert.Equal(CliApp.ExitUsage, r.Exit); // no-oracle: Q917 the C# runs these commands; the refusal text is R3's (Q4)
            Assert.Equal($"error: `{command}` is not available in the self-hosted compiler; use the C# `bayan`\n", r.Err);
        }
        finally { TestDirs.Delete(dir); }
    }

    [Fact]
    public void InitInitialisesGitAsCSharp() =>
        Same(["init"], relativeCwd: "proj", setup: dir => Directory.CreateDirectory(Path.Combine(dir, "proj")));

    [Theory]
    [InlineData("app", "--ci github")]
    [InlineData("lib", "--lib")]
    [InlineData("script", "--script")]
    public void NewMatchesTheTreeGoldens(string layout, string options)
    {
        var dir = Fresh();
        try
        {
            var r = Start(SelfhostDriverHarness.Build(), [], dir, ["new", Path.Combine(dir, "tally"), "--vcs", "none", .. options.Split(' ')], null);
            Assert.True(r.Exit == CliApp.ExitOk, r.Err);
            var result = Golden.Compare(Path.Combine(Golden.CasesRoot, "new", layout + ".tree"), Tree(dir, plain: true), false);
            if (result.Failure is { } failure) Assert.Fail(failure);
        }
        finally { TestDirs.Delete(dir); }
    }
}
