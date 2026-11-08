using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Reflection;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

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

    /// <summary>L028: every <c>tests/cases/diag-json/*.byn</c> through <c>check</c> and <c>build</c> with <c>--diagnostics json</c>, against <c>CliApp.Run</c>; <c>build</c> fails on these before any toolchain is reached.</summary>
    [Theory]
    [MemberData(nameof(DiagJsonCases))]
    public void DiagnosticsJsonAsCliAppDoes(string command, string name)
    {
        var path = Path.Combine(Golden.CasesRoot, "diag-json", name + ".byn");
        AssertSameAsCs(command, "--diagnostics", "json", path);
        var expected = Oracle([command, "--diagnostics", "json", path]);
        Assert.Equal(CliApp.ExitFailure, expected.Exit);
        Assert.StartsWith("{\"code\":\"BYN", expected.Err);
    }

    public static IEnumerable<object[]> DiagJsonCases() =>
        from command in new[] { "check", "build" }
        from file in Directory.GetFiles(Path.Combine(Golden.CasesRoot, "diag-json"), "*.byn").Order(StringComparer.Ordinal)
        select new object[] { command, Path.GetFileNameWithoutExtension(file) };

    /// <summary>CliTests.cs:451-487: the format after `--diagnostics`, on <c>run</c> too, and the unknown-format usage error.</summary>
    [Fact]
    public void DiagnosticsJsonArgumentsAsCliAppDoes()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t7-diag-json");
        Directory.CreateDirectory(dir);
        var bad = Path.Combine(dir, "bad.byn");
        File.WriteAllText(bad, "i32 x = \"no\"\nvar y = 1\n");
        AssertSameAsCs("run", "--diagnostics", "json", bad);
        AssertSameAsCs("check", "--diagnostics", "text", bad);
        AssertSameAsCs("check", "--diagnostics", "xml", bad);
        AssertSameAsCs("check", "--diagnostics");
        AssertSameAsCs("build", "--diagnostics", "xml", bad);
        AssertSameAsCs("run", "--diagnostics", "xml", bad);
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
    [InlineData("test")]
    [InlineData("mutate")]
    [InlineData("dist")]
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
    internal static string CsStyle(string[] args, Func<string, string?>? env = null)
    {
        var call = new object[] { args, new StringWriter() };
        var taken = typeof(CliApp).GetMethod("TakeGlobalOptions", BindingFlags.NonPublic | BindingFlags.Static)!.Invoke(null, call);
        var (color, ascii) = ((string Color, bool Ascii))taken!;
        var style = TerminalStyle.Decide(color, ascii, false, env ?? (_ => null), 0);
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

    private static readonly string[] s_styleVariables = ["TERM", "NO_COLOR", "FORCE_COLOR", "COLORTERM", "BAYAN_THEME", "COLORFGBG", "LC_ALL", "LC_CTYPE", "LANG"];

    /// <summary>The nine variables <c>Decide</c> reads, every one set (empty where not given) so the test process's own environment cannot reach the probe.</summary>
    private static Dictionary<string, string> StyleEnvironment(string name, string value)
    {
        var env = s_styleVariables.ToDictionary(v => v, _ => "");
        env[name] = value;
        return env;
    }

    [Theory]
    [InlineData("NO_COLOR", "1", "auto", true, 80)]
    [InlineData("FORCE_COLOR", "1", "auto", false, 80)]
    [InlineData("TERM", "dumb", "auto", true, 80)]
    [InlineData("TERM", "xterm", "auto", true, 0)]
    [InlineData("LANG", "C", "auto", true, 80)]
    // no-oracle: Q919 `CliApp.Run` takes a `Terminal` for the tty arm and the driver cannot be given one, so this row calls `decideStyle` itself against `Decide`; the environment arms are compared through `Run` in `SelfhostDriverStyleEnvironmentTests`
    public void DecideReadsTheEnvironmentOnATerminal(string name, string value, string color, bool tty, int width)
    {
        var expected = TerminalStyle.Decide(color, false, tty, k => k == name ? value : "", width);
        var actual = SelfhostDriverHarness.RunProbe(StyleEnvironment(name, value), "decide", color, "false", tty ? "true" : "false", width.ToString()).Out;
        Assert.Equal(Fmt(expected) + "\n", actual);
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

    private const string AuditSource = "@allow(BYN2230) because \"kept for the C ABI\"\nvoid toHex() {\n}\n\nunsafe void poke() {\n}\n\n"
        + "void main() {\n    let k = input.trustUnchecked() because \"a fixture\"\n    unsafe because \"raw write\" {\n    }\n}\n\nextern i32 puts(cstr s)\n";

    /// <summary>The fixture tree of one <c>audit</c> row under <c>tmp/t6-audit/</c> and its arguments, with <c>{D}</c> replaced by the tree.</summary>
    private static string[] AuditRow(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t6-audit", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        void Write(string relative, string text)
        {
            var file = Path.Combine(dir, relative);
            Directory.CreateDirectory(Path.GetDirectoryName(file)!);
            File.WriteAllText(file, text);
        }
        switch (name)
        {
            case "bypasses":
                Write("main.byn", AuditSource);
                return ["audit", dir];
            case "file":
                Write("main.byn", AuditSource);
                return ["audit", Path.Combine(dir, "main.byn")];
            case "ascii":
                Write("main.byn", AuditSource);
                return ["--ascii", "audit", dir];
            case "color":
                Write("main.byn", AuditSource);
                return ["--color", "always", "audit", dir];
            case "edges":
                // `because` first, after a bare `)`, after a call, a name, a paren group, with no string reason; `unsafe` with `because`, at the end of file, before a brace.
                Write("a.byn", "because \"first\"\n");
                Write("b.byn", ") because \"stray\"\n(1) because \"group\"\nfoo(1) because \"call\"\nlet é = bar(2, (3)) because \"unicode\"\nx because y\n@a(1) because \"attr\"\nunsafe because \"b\" {\n}\nunsafe fn f() {\n}\nextern\nunsafe");
                return ["audit", Path.Combine(dir, "b.byn")];
            case "edges-two":
                Write("a.byn", "because \"first\"\n");
                Write("c.byn", "(1) because \"opens the file\"\n");
                Write("b.byn", ") because \"stray\"\n(1) because \"group\"\nfoo(1) because \"call\"\nlet é = bar(2, (3)) because \"unicode\"\nx because y\n@a(1) because \"attr\"\nunsafe because \"b\" {\n}\nunsafe fn f() {\n}\nextern\nunsafe");
                return ["audit", dir];
            case "tree":
                // M3: scratch directories are not entered, a nested `bin` is; `package.byn` is not audited; files list in ordinal order.
                foreach (var f in new[] { "b.byn", "a.byn", "src/bin/x.byn", "src/obj/y.byn", "src/node_modules/z.byn", "src/deep/q.byn", ".worktrees/x/w.byn", "tmp/t.byn", "bin/r.byn", "dist/d.byn", "obj/o.byn", "node_modules/n.byn", "notes.txt", "weird.byn/inner.byn" })
                    Write(f, "unsafe void " + Path.GetFileNameWithoutExtension(f) + "() {\n}\n");
                Write("package.byn", "unsafe void pkg() {\n}\n");
                return ["audit", dir];
            case "empty":
                return ["audit", dir];
            case "one":
                Write("main.byn", "unsafe void poke() {\n}\n");
                return ["audit", dir];
            case "unreadable-file":
                Write("main.byn", "unsafe void poke() {\n}\n");
                Write("a.byn", "unsafe void peek() {\n}\n");
                return ["audit", dir];
            case "unreadable-dir":
                Write("main.byn", "unsafe void poke() {\n}\n");
                Write("locked/b.byn", "unsafe void peek() {\n}\n");
                return ["audit", dir];
            case "locked-root-dir":
                Write("main.byn", "unsafe void poke() {\n}\n");
                return ["audit", dir];
            case "locked-root-file":
                Write("main.byn", "unsafe void poke() {\n}\n");
                return ["audit", Path.Combine(dir, "main.byn")];
            case "uppercase":
                Write("A.BYN", "unsafe void a() {\n}\n");
                Write("b.Byn", "unsafe void b() {\n}\n");
                Write("c.bxn", "unsafe void c() {\n}\n");
                Write("d.byx", "unsafe void d() {\n}\n");
                return ["audit", dir];
            case "dangling-link":
                Write("main.byn", AuditSource);
                File.CreateSymbolicLink(Path.Combine(dir, "broken.byn"), "/nonexistent");
                return ["audit", dir];
            case "cycle":
                Write("main.byn", "unsafe void poke() {\n}\n");
                Directory.CreateDirectory(Path.Combine(dir, "sub"));
                Directory.CreateSymbolicLink(Path.Combine(dir, "sub", "up"), "..");
                Directory.CreateSymbolicLink(Path.Combine(dir, "sub", "up2"), "..");
                return ["audit", dir];
            case "parent-link":
                Write("outside.byn", "unsafe void prod() {\n}\n");
                Write("dir/main.byn", "unsafe void peek() {\n}\n");
                Directory.CreateSymbolicLink(Path.Combine(dir, "dir", "link"), "..");
                return ["audit", Path.Combine(dir, "dir")];
            case "file-link":
                Write("main.byn", "unsafe void poke() {\n}\n");
                File.CreateSymbolicLink(Path.Combine(dir, "alias.byn"), "main.byn");
                return ["audit", dir];
            case "missing":
                return ["audit", Path.Combine(dir, "nope")];
            case "no-path":
                return ["audit"];
            case "option":
                return ["audit", "-x"];
            case "two-paths":
                return ["audit", dir, dir];
            default:
                throw new ArgumentException(name);
        }
    }

    /// <summary><c>bayan audit</c> against <see cref="CliApp.Run"/> on the same tree: exit code, stdout and stderr (M3's file list included).</summary>
    [Theory]
    [InlineData("bypasses")]
    [InlineData("file")]
    [InlineData("ascii")]
    [InlineData("color")]
    [InlineData("edges")]
    [InlineData("edges-two")]
    [InlineData("tree")]
    [InlineData("empty")]
    [InlineData("one")]
    [InlineData("missing")]
    [InlineData("no-path")]
    [InlineData("option")]
    [InlineData("two-paths")]
    [InlineData("uppercase")]
    public void AuditAsCliApp(string name) => AssertSameAsCs(AuditRow(name));

    /// <summary>
    /// The walk through links against <see cref="CliApp.Run"/>, exit, stdout and stderr: CliTests.cs:146 <c>AuditWalksSymlinkCyclesOnce</c> (<c>cycle</c>),
    /// CliTests.cs:158 <c>AuditWalksASymlinkToAParentOfTheRootOnce</c> (<c>parent-link</c>) and a file link to a file listed once (<c>file-link</c>);
    /// bounded in time as the C# tests are, since a walk that does not resolve <c>up -> ..</c> doubles at each level.
    /// </summary>
    [Theory]
    [InlineData("cycle")]
    [InlineData("parent-link")]
    [InlineData("file-link")]
    public async Task AuditWalksLinksAsCliApp(string name)
    {
        if (OperatingSystem.IsWindows()) return;
        var args = AuditRow(name);
        await Task.Factory.StartNew(() => AssertSameAsCs(args), TaskCreationOptions.LongRunning).WaitAsync(TestTime.Scale(TimeSpan.FromSeconds(120)));
    }

    /// <summary>The commands <c>run</c> hands to a file of their own, by their usage or missing-path paths, against <see cref="CliApp.Run"/>.</summary>
    [Theory]
    [InlineData("lex")]
    [InlineData("parse")]
    [InlineData("types")]
    [InlineData("check")]
    [InlineData("explain")]
    [InlineData("explain", "BYN0003")]
    [InlineData("new")]
    [InlineData("init", "{D}/missing")]
    [InlineData("cache")]
    [InlineData("cache", "stats", "extra")]
    [InlineData("clean", "{D}/missing")]
    public void DispatchesToTheOtherCommandsAsCliApp(params string[] args)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t6-dispatch");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        AssertSameAsCs([.. args.Select(a => a.Replace("{D}", dir))]);
    }

    /// <summary><c>doctor</c> reaches the driver's own checks; only the commit of its version row (spec Q1091) is masked.</summary>
    [Fact]
    public void DispatchesDoctorAsCliApp()
    {
        static string Commit(string text) => Regex.Replace(text, @"\(commit [^)]*\)", "(commit masked)");
        var expected = Oracle(["doctor"]);
        var actual = SelfhostDriverHarness.Run("doctor");
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame("stdout of `doctor`", Commit(expected.Out), Commit(actual.Out));
        SelfhostEmitterHarness.AssertSame("stderr of `doctor`", expected.Err, actual.Err);
    }

    /// <summary>An unreadable file or directory is reported and the rest audited; the .NET message after the path differs from the driver's, so stderr is compared up to it.</summary>
    [Theory]
    [InlineData("unreadable-file", "a.byn")]
    [InlineData("unreadable-dir", "locked")]
    [InlineData("locked-root-dir", "")]
    [InlineData("locked-root-file", "")]
    public void AuditReportsWhatItCannotReadAsCliApp(string name, string locked)
    {
        if (OperatingSystem.IsWindows()) return;
        var args = AuditRow(name);
        var target = Path.Combine(args[1], locked);
        File.SetUnixFileMode(target, UnixFileMode.None);
        try
        {
            try { _ = Directory.Exists(target) ? Directory.GetFiles(target) : [File.ReadAllText(target)]; return; }
            catch (UnauthorizedAccessException) { }
            var expected = Oracle(args);
            var actual = SelfhostDriverHarness.Run(args);
            Assert.Equal(CliApp.ExitFailure, expected.Exit);
            Assert.Equal(expected.Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
            var prefix = $"bayan: {target}: ";
            Assert.StartsWith(prefix, expected.Err);
            Assert.StartsWith(prefix, actual.Err);
        }
        finally { File.SetUnixFileMode(target, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
    }

    /// <summary>
    /// CliTests.cs:172 <c>AuditReportsALoopingFileLink</c>: a <c>loop.byn</c> that links to itself is reported and the walk goes on; stdout and exit equal the C#'s, stderr up to the message
    /// (the C#'s "Too many levels of symbolic links", the driver's <c>IoError</c>, Q1106).
    /// </summary>
    [Fact]
    public void AuditReportsALoopingFileLinkAsCliApp()
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t6-loop");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(Path.Combine(dir, "sub"));
        File.WriteAllText(Path.Combine(dir, "main.byn"), "void main() {\n}\n");
        File.WriteAllText(Path.Combine(dir, "sub", "b.byn"), "unsafe void peek() {\n}\n");
        File.CreateSymbolicLink(Path.Combine(dir, "loop.byn"), "loop.byn");
        string[] args = ["audit", dir];
        var expected = Oracle(args);
        var actual = SelfhostDriverHarness.Run(args);
        Assert.Equal(CliApp.ExitFailure, expected.Exit);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
        var prefix = $"bayan: {Path.Combine(dir, "loop.byn")}: ";
        Assert.StartsWith(prefix, expected.Err);
        Assert.StartsWith(prefix, actual.Err);
    }

    /// <summary>A dangling <c>broken.byn -> /nonexistent</c>: both report the path and exit 1, by different routes (the C# lists it as a file and fails to read it, the driver takes it for a directory and fails to list it); stderr is compared up to the path's message (Q1106).</summary>
    [Fact]
    public void AuditReportsADanglingLinkAsCliApp()
    {
        if (OperatingSystem.IsWindows()) return;
        var args = AuditRow("dangling-link");
        var expected = Oracle(args);
        var actual = SelfhostDriverHarness.Run(args);
        Assert.Equal(CliApp.ExitFailure, expected.Exit);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
        var prefix = $"bayan: {Path.Combine(args[1], "broken.byn")}: ";
        Assert.StartsWith(prefix, expected.Err);
        Assert.StartsWith(prefix, actual.Err);
    }

    private static void Chmod(string path, UnixFileMode mode)
    {
        if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(path, mode);
    }

    private static string WalkTree(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t6-walk", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        foreach (var f in new[] { "a.byn", "sub/b.byn", "sub/deep/c.byn", "other/d.byn", "locked/e.byn", "package.byn" })
        {
            Directory.CreateDirectory(Path.GetDirectoryName(Path.Combine(dir, f))!);
            File.WriteAllText(Path.Combine(dir, f), "// c\n");
        }
        return dir;
    }

    /// <summary><c>bynFiles</c> against <c>Format.BynFiles</c>: the files listed (in ordinal order, .NET's order being unspecified), the exit, and the stderr lines up to the path's message; with each <c>within</c> bound, and silent as <c>PackageNames</c> calls it.</summary>
    [Theory]
    [InlineData("", false, false)]
    [InlineData("", true, false)]
    [InlineData("{D}", false, false)]
    [InlineData("{D}/sub", false, false)]
    [InlineData("{D}/sub/", false, false)]
    [InlineData("/nonexistent/within", false, false)]
    [InlineData("{D}", true, true)]
    [InlineData("", false, true)]
    public void WalkAsFormatBynFiles(string within, bool silent, bool locked)
    {
        if (locked && OperatingSystem.IsWindows()) return;
        var dir = WalkTree($"{(within == "" ? "none" : "bound")}-{silent}-{locked}");
        within = within.Replace("{D}", dir);
        var lockedDir = Path.Combine(dir, "locked");
        if (locked) Chmod(lockedDir, UnixFileMode.None);
        try
        {
            if (locked) { try { _ = Directory.GetFiles(lockedDir); return; } catch (UnauthorizedAccessException) { } }
            var exit = CliApp.ExitOk;
            var err = new StringWriter();
            var files = Format.BynFiles(dir, silent ? TextWriter.Null : err, ref exit, within == "" ? null : within);
            var expected = string.Join("", files.Order(StringComparer.Ordinal).Select(f => f + "\n")) + $"exit {exit}\n";
            var (code, stdout, stderr) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "walk", dir, within == "" ? "-" : within, silent ? "true" : "false");
            Assert.Equal(0, code);
            var lines = stdout.Split('\n').ToList();
            var tail = lines.Where(l => l.StartsWith("exit ")).ToList();
            var got = string.Join("", lines.Where(l => l.EndsWith(".byn")).Order(StringComparer.Ordinal).Select(f => f + "\n")) + string.Join("", tail.Select(t => t + "\n"));
            SelfhostEmitterHarness.AssertSame("walk", expected, got);
            var prefix = $"bayan: {lockedDir}: ";
            Assert.Equal(!silent && locked, err.ToString().StartsWith(prefix));
            Assert.Equal(!silent && locked, stderr.StartsWith(prefix));
            if (!locked || silent) Assert.Equal("", stderr);
        }
        finally { if (locked) Chmod(lockedDir, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
    }

    /// <summary><c>manifestFor</c> against the private <c>Format.ManifestFor</c>: the directory of the nearest <c>package.byn</c> (or none) for each file, and how many directories the cache holds after, with the second file of a directory answered from the cache. <c>The manifest itself is not compared.</summary>
    [Fact]
    public void ManifestForAsFormat()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t6-manifest");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        foreach (var f in new[] { "pkg/package.byn", "pkg/src/x.byn", "pkg/src/deep/y.byn", "pkg/src/z.byn", "loose/w.byn" })
        {
            Directory.CreateDirectory(Path.GetDirectoryName(Path.Combine(dir, f))!);
            File.WriteAllText(Path.Combine(dir, f), f.EndsWith("package.byn") ? "Package {\n    name: \"local/p\",\n    version: \"0.1.0\",\n    edition: 2027,\n    kind: .app,\n}\n" : "");
        }
        var files = new[] { "pkg/src/x.byn", "pkg/src/deep/y.byn", "pkg/src/z.byn", "loose/w.byn", "pkg/package.byn" }.Select(f => Path.Combine(dir, f)).ToArray();
        var method = typeof(Format).GetMethod("ManifestFor", BindingFlags.NonPublic | BindingFlags.Static)!;
        var cache = (System.Collections.IDictionary)Activator.CreateInstance(method.GetParameters()[1].ParameterType)!;
        var expected = new List<string>();
        foreach (var f in files)
        {
            var found = method.Invoke(null, [f, cache]);
            expected.Add(found is System.Runtime.CompilerServices.ITuple t ? (string)t[1]! : "none");
        }
        expected.Add(cache.Count.ToString());
        var (code, stdout, _) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), ["manifest", .. files]);
        Assert.Equal(0, code);
        SelfhostEmitterHarness.AssertSame("manifestFor", string.Join("\n", expected) + "\n", stdout);
    }

    /// <summary><c>packageNames</c> against the private <c>Format.PackageNames</c> where the C# set is empty (files holding only a comment, an unreadable one, a missing directory).</summary>
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public void PackageNamesAsFormat(bool missing)
    {
        var dir = WalkTree($"names-{missing}");
        if (missing) dir = Path.Combine(dir, "nope");
        var locked = Path.Combine(dir, "a.byn");
        var lockIt = !missing && !OperatingSystem.IsWindows();
        if (lockIt) Chmod(locked, UnixFileMode.None);
        try
        {
            var method = typeof(Format).GetMethod("PackageNames", BindingFlags.NonPublic | BindingFlags.Static)!;
            var expected = (IEnumerable<string>)method.Invoke(null, [dir])!;
            Assert.Empty(expected);
            var (code, stdout, stderr) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "names", dir);
            Assert.Equal(0, code);
            Assert.Equal("", stdout);
            Assert.Equal("", stderr);
        }
        finally { if (lockIt) Chmod(locked, UnixFileMode.UserRead | UnixFileMode.UserWrite); }
    }

    /// <summary><c>packageNames</c> over files with names equals the private <c>Format.PackageNames</c> (as sets): the identifiers other than a type, a callee or receiver, or a member after a dot.</summary>
    [Fact]
    public void PackageNamesWithNamesAsFormat()
    {
        var dir = WalkTree("names-some");
        File.WriteAllText(Path.Combine(dir, "a.byn"), "struct Box { weight: long }\nlong grow(Box b) => long(b.weight) + int.max\nvoid main() {\n    let w = grow(Box { weight: 1 })\n    let i8 = w\n}\n");
        File.WriteAllText(Path.Combine(dir, "sub", "b.byn"), "double half(double x) => x / 2\n");
        var method = typeof(Format).GetMethod("PackageNames", BindingFlags.NonPublic | BindingFlags.Static)!;
        var expected = ((IEnumerable<string>)method.Invoke(null, [dir])!).Order(StringComparer.Ordinal).ToList();
        Assert.NotEmpty(expected);
        var (code, stdout, stderr) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), "names", dir);
        Assert.Equal(0, code);
        Assert.Equal("", stderr);
        var got = stdout.Split('\n', StringSplitOptions.RemoveEmptyEntries).Order(StringComparer.Ordinal).ToList();
        SelfhostEmitterHarness.AssertSame("package names", string.Join("\n", expected), string.Join("\n", got));
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

    /// <summary>
    /// The files of one <c>format</c> row (FormatTests.cs, CliTests.cs, CliMemoryBoundsTests.cs) and its runs, each the arguments after
    /// <c>format</c>, with <c>{D}</c> the row's tree under <c>tmp/t8-format/</c>.
    /// </summary>
    private static (Dictionary<string, string> Files, string[][] Runs) FormatRowSpec(string name)
    {
        const string Fixable = "let a = true\nif (a) { print(\"x\") }\n";
        const string Formatted = "let a = true\nif a { print(\"x\") }\n";
        const string Unless = "let a = true\nunless !a { print(\"y\") }\n";
        const string Package = "Package {\n    name: \"local/shop\",\n    version: \"0.1.0\",\n    style: Style {  },\n}\n";
        const string ErrorSets = "union error E {\n    a\n}\nunion error F {\n    b\n}\nunion error G {\n    c\n}\ninterface IShape {\n    i64 area()\n}\n";
        const string Body = " {\n    print(\"g\")\n    return 1\n}\n";
        string Diag(string file) => File.ReadAllText(Path.Combine(Golden.CasesRoot, "diag", file));
        (Dictionary<string, string>, string[][]) One(string text, params string[] args) => (new() { ["main.byn"] = text }, args.Contains("--check") ? [[.. args, "{D}/main.byn"]] : [[.. args, "--check", "{D}/main.byn"], [.. args, "{D}/main.byn"]]);
        string Pkg(string style) => $"Package {{\n    name: \"local/shop\",\n    version: \"0.1.0\",\n    style: Style {{ {style} }},\n}}\n";
        const string WordsAndCSharp = "bool f(bool a, bool b, int n) => a and not b or n is not 0\nvoid main() {\n    let x: nint = 3\n    switch x {\n        case 1 or 2: print(\"a\")\n        default: print(\"b\")\n    }\n    print(\"s\") if not f(true, false, 1) and x > 0\n}\n";
        const string SymbolsAndSized = "bool f(bool a, bool b, i32 n) => a && !b || n is not 0\nvoid main() {\n    let x: isize = 3\n    switch x {\n        case 1 or 2: print(\"a\")\n        default: print(\"b\")\n    }\n    print(\"s\") if !f(true, false, 1) && x > 0\n}\n";
        const string IdempotentInput = "struct Box { weight: long }\nadd(a: int, b: i32) -> long { return a + b; }\nvoid main() {\n    let a = true\n    if (a && !false) { print(\"x\") }\n    unless !a { print(\"y\") }\n    int t = add(1, 2)\n    print($\"{t}\") if not a or t is not 0\n}\n";
        (Dictionary<string, string>, string[][]) Twice(string text) => (new() { ["main.byn"] = text }, [["{D}/main.byn"], ["--check", "{D}/main.byn"]]);
        return name switch
        {
            "no-path" => (new(), [[]]),
            "dash" => (new(), [["-x"]]),
            "bad-option" => (new(), [["-x", "{D}/main.byn"]]),
            "two-paths" => (new() { ["a.byn"] = Fixable, ["b.byn"] = Fixable }, [["{D}/a.byn", "{D}/b.byn"]]),
            "missing" => (new(), [["{D}/missing.byn"]]),
            "a-fix" => One(Fixable),
            "two-fixes" => One("let a = true\nunless !a { print(\"y\") }\nif (a) { print(\"x\") }\n"),
            "two-fixes-one-line" => One("let a = true\nlet b = true\nif (a) { if (b) { print(\"x\") } }\n"),
            "attributes" => One("/* one\n   two */\nbool isA(char c) => c == 'a'\n[Cases(1, 2)]\ntest \"positive\" (i32 n) {\n    assert(n > 0)\n}\n"),
            "requires" => One("type distinct Percent = i32 requires value in 0..=100\n"),
            "delegates" => One("struct Order { i64 total }\ndelegate bool OrderFilter(Order order)\ntype F = i32 => bool\n"),
            "declarations" => One("struct Box { weight: i64 }\nunion Event { timeout(after: i64) }\nadd(a: i64, i64 b) -> i64 { return a + b }\nmain() {\n    i64 t = add(1, 2)\n    i64 u = 0\n    u = t\n    const i64 k = 3\n    print($\"{u}{k}\")\n}\n"),
            "shorthand-uses" => One("union error E {\n    a\n}\nunion error F {\n    b\n}\ni32!E g() fails F uses console {\n    print(\"g\")\n    return 1\n}\n"),
            "shorthand-comment" => One(ErrorSets + "i32!E g() // keep me\n    fails F\n    uses console" + Body),
            "shorthand-lines" => One(ErrorSets + "i32!E g()\n    fails F\n    uses console" + Body),
            "shorthand-column-0" => One(ErrorSets + "i32 g()\nfails F\nuses console" + Body),
            "shorthand-where" => One(ErrorSets + "i64!E g<T>(T x) fails F where T : IShape expects true" + Body),
            "shorthand-two-fails" => One(ErrorSets + "i32!E g() fails F uses console fails G, E" + Body),
            "shorthand-two-uses" => One(ErrorSets + "i32!E g() fails F uses console uses fs" + Body),
            "second-run" => (new() { ["main.byn"] = Fixable }, [["{D}/main.byn"], ["{D}/main.byn"]]),
            "statement-attributes" => Twice("i32 clamp(i32 x) {\n    @unobservable because \"the caller never passes 0\"\n    if x <= 0 {\n        return 0\n    }\n    @unobservable(boundary) because \"x is at most 100\"\n    return x\n}\n"),
            "round3" => Twice(
                "/* Shapes. */\nunion Shape { circle(f64 r), square(f64 side) }\nenum Size { /* small */ s, m /* medium */, l }\n" +
                "unique struct File {\n    i64 fd\n}\nerror enum StockError {\n    outOfStock\n}\n" +
                "distinct type Percent = i32 requires value in 0..=100\n[Derive(Json)]\nstruct Parcel {\n    weight: i64\n}\n" +
                "i32 twice(i32 n) noalloc => n * 2\nbool isA(char c) => c == 'a'\n" +
                "Shape pick(Shape s) {\n    switch s {\n        case _ except .circle: return s\n        default: return s\n    }\n}\n" +
                "add(a: i64, i64 b) -> i64 {\n    return a + b;\n}\n" +
                "void run(Arena arena) {\n    context (allocator: arena) {\n        print(\"x\")\n    }\n}\n" +
                "main() {\n    i64 t = add(1, b: 2); print($\"{t}\")\n    if t > 0 {\n        print(\"pos\")\n    }\n    else {\n        print(\"other\")\n    }\n" +
                "    let u: Untrusted<string> = Untrusted(\"x\")\n    print(trust(u, reason: \"checked\"))\n}\n"),
            "words" => One("let a = true\nlet b = false\nif a and not b or b { print(\"x\") }\n"),
            "not-tab" => One("let b = true\nlet c = not\tb\n"),
            "pattern-not" => One("void main() {\n    let x: i32? = null\n    let a = true\n    if x is not null and not a { print(\"x\") }\n    if a or not\n        a { print(\"y\") }\n}\n"),
            "member" => One("i64 f(Box b) => b.long\n"),
            "question-dot" => One("void main() {\n    let n = b?.size\n}\n"),
            "a-real-error" => One("let a = true\nif (a) { print(\"x\"; }\n"),
            "error-dir" => (new() { ["a.byn"] = "let a = true\nif (a) { print(\"x\"; }\n", ["b.byn"] = Fixable }, [["{D}"]]),
            "no-fix" => One("i32!Foo? f() { return 1 }\n"),
            "two-no-fix" => One("i32!Foo? f() { return 1 }\ni32!Bar? g() { return 1 }\nlet a = true\nlet b = a and a\n"),
            "formatted" => One(Formatted),
            "check-changed" => One(Fixable, "--check"),
            "check-formatted" => (new() { ["main.byn"] = Formatted }, [["--check", "{D}"]]),
            "check-clean" => (new() { ["main.byn"] = "bool f(bool a, bool b, i32 n) => a && !b || n is not 0\nvoid main() {\n    let x: isize = 3\n    switch x {\n        case 1 or 2: print(\"a\")\n        default: print(\"b\")\n    }\n    print(\"s\") if !f(true, false, 1) && x > 0\n}\n" }, [["--check", "{D}"]]),
            "check-broken" => (new() { ["main.byn"] = Unless, ["z.byn"] = "let b = (\nlet c = (\n" }, [["--check", "{D}"]]),
            "directory" => (new() { ["b.byn"] = Fixable, ["a.byn"] = Formatted, ["sub/c.byn"] = Fixable, ["notes.txt"] = Fixable }, [["{D}"]]),
            "recursive" => (new() { ["sub/deep/main.byn"] = Fixable }, [["{D}"]]),
            "package" => (new() { ["package.byn"] = Package, ["a.byn"] = Fixable, ["b.byn"] = "let b = true\nunless !b { print(\"y\") }\n" }, [["{D}"], ["{D}/a.byn"]]),
            "no-temp-file" => (new() { ["main.byn"] = Fixable }, [["{D}"]]),
            "executable" => (new() { ["script.byn"] = "#!/usr/bin/env bayan\nlet a = true\nif (a) { print(\"x\") }\n" }, [["{D}/script.byn"]]),
            "unreadable-package" => (new() { ["package.byn"] = Pkg("booleans: .words"), ["main.byn"] = Fixable }, [["{D}/main.byn"]]),
            "unreadable-dir" => (new() { ["locked/a.byn"] = "let a = true;\n", ["b.byn"] = Fixable }, [["{D}"]]),
            "nested-bin" => (new() { ["src/bin/x.byn"] = "unsafe void poke() {\n}\n" + Unless }, [["--check", "{D}"]]),
            "scratch-dirs" => (new() { [".worktrees/x/a.byn"] = Unless, ["tmp/b.byn"] = Unless, ["src/ok.byn"] = Unless }, [["--check", "{D}"]]),
            "outward-links" => (new() { ["fixture/.worktrees/x/a.byn"] = Unless, ["fixture/tmp/b.byn"] = Unless, ["fixture/src/ok.byn"] = Unless, ["outside/c.byn"] = Unless }, [["--check", "{D}/fixture"]]),
            "package-link-outside" => (new() { ["outside/x.byn"] = "long i8(long x) => x\n", ["pkg/package.byn"] = Pkg("primitives: .csharp"), ["pkg/main.byn"] = "void main() {\n    let n = i8(3)\n}\n" }, [["{D}/pkg/main.byn"]]),
            "state-lines" => Twice(Diag("state-line-input.byn")),
            "line-join-member" => One(Diag("line-join-member.byn")),
            "line-join-enum-shorthand" => One(Diag("line-join-enum-shorthand.byn")),
            "line-join-and" => One(Diag("line-join-and.byn")),
            "line-join-quiet" => One(Diag("line-join-quiet.byn"), "--check"),
            "defaults" => One(WordsAndCSharp),
            "package-style" => (new() { ["package.byn"] = Pkg("booleans: .words, primitives: .csharp"), ["src/main.byn"] = SymbolsAndSized }, [["{D}"]]),
            "csharp-project" => (new() { ["package.byn"] = Pkg("primitives: .csharp"), ["src/main.byn"] = "long twice(int n) => n * 2\n\nvoid main() {\n    let r: double = 0.5\n    print($\"{twice(3)} {r}\")\n}\n" }, [["{D}"]]),
            "spacing-blanks" => (new() { ["package.byn"] = Pkg("booleans: .words"), ["main.byn"] = "bool f(bool a, bool b) => a\t&&\tb\nbool g(bool a, bool b) => a ||\n    b\nbool h(bool a, bool b) => a &&\r\n    b\n" }, [["{D}/main.byn"]]),
            "spacing" => (new() { ["package.byn"] = Pkg("booleans: .words"), ["main.byn"] = "bool f(bool a, bool b) => a&&!b||!(a)\n" }, [["{D}/main.byn"]]),
            "primitive-names" => (new() { ["package.byn"] = Pkg("primitives: .csharp"), ["main.byn"] = "struct P { i8: int }\nvoid main() {\n    let u8 = 1\n    let p = P { i8: 3 }\n    let w: i8 = 2\n    print($\"{u8}{p.i8}{w}\")\n}\n" }, [["{D}/main.byn"]]),
            "conv-sized" => One("void main() {\n    let y = 1\n    let z: long = long(y)\n    let a = int.tryFrom(y)\n    let b = long.max\n}\n"),
            "conv-csharp" => (new() { ["package.byn"] = Pkg("primitives: .csharp"), ["main.byn"] = "void main() {\n    let y = 1\n    let a = i32.tryFrom(y)\n    let b = i64.max\n    let c = i8(y)\n}\n" }, [["{D}/main.byn"]]),
            "conv-declared" => (new() { ["package.byn"] = Pkg("primitives: .csharp"), ["main.byn"] = "void main() {\n    let i8 = 1\n    let n = i8.foo\n    let m = i8(2)\n}\n" }, [["{D}/main.byn"]]),
            "conv-declared-package" => (new() { ["package.byn"] = Pkg("primitives: .csharp"), ["a.byn"] = "long i8(long x) => x + 1000\n", ["main.byn"] = "void main() {\n    let n = i8(3)\n}\n" }, [["{D}"], ["{D}/main.byn"]]),
            "bad-style" => (new() { ["package.byn"] = Pkg("booleans: .both"), ["main.byn"] = WordsAndCSharp }, [["{D}/main.byn"]]),
            "bad-style-directory" => (new() { ["package.byn"] = Pkg("booleans: .both"), ["a.byn"] = WordsAndCSharp, ["other/b.byn"] = Fixable }, [["{D}"]]),
            "check-style" => (new() { ["a.byn"] = WordsAndCSharp, ["b.byn"] = SymbolsAndSized }, [["--check", "{D}"]]),
            "check-style-clean" => (new() { ["main.byn"] = SymbolsAndSized }, [["--check", "{D}"]]),
            "idempotent-empty" => (new() { ["main.byn"] = IdempotentInput }, [["{D}/main.byn"], ["--check", "{D}/main.byn"], ["{D}/main.byn"]]),
            "idempotent-package" => (new() { ["package.byn"] = Pkg("booleans: .words, primitives: .csharp"), ["main.byn"] = IdempotentInput }, [["{D}/main.byn"], ["--check", "{D}/main.byn"], ["{D}/main.byn"]]),
            _ => throw new ArgumentException(name),
        };
    }

    /// <summary>The <c>executable</c> row's mode (FormatTests.cs:551).</summary>
    private const UnixFileMode Executable = UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute
        | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute;

    /// <summary>Writes the row's tree afresh and returns its runs, each a full argument list.</summary>
    private static string[][] FormatRow(string name, out string dir)
    {
        var (files, runs) = FormatRowSpec(name);
        dir = Path.Combine(Golden.RepoRoot, "tmp", "t8-format", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        foreach (var (rel, text) in files)
        {
            var path = Path.Combine(dir, rel);
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            File.WriteAllText(path, text);
            if (name == "executable" && !OperatingSystem.IsWindows()) File.SetUnixFileMode(path, Executable);
        }
        if (name == "outward-links")
        {
            Directory.CreateSymbolicLink(Path.Combine(dir, "fixture", "link"), Path.Combine(dir, "outside"));
            Directory.CreateSymbolicLink(Path.Combine(dir, "fixture", "inner-link"), Path.Combine(dir, "fixture", "tmp"));
        }
        if (name == "package-link-outside") Directory.CreateSymbolicLink(Path.Combine(dir, "pkg", "vendor"), "../outside");
        var d = dir;
        return [.. runs.Select(args => (string[])["format", .. args.Select(a => a.Replace("{D}", d))])];
    }

    /// <summary>Every file under <paramref name="dir"/> with its Unix mode and text, in ordinal order; a temp file left behind shows here.</summary>
    private static string Tree(string dir) => string.Join("", Directory.GetFiles(dir, "*", SearchOption.AllDirectories)
        .Order(StringComparer.Ordinal)
        .Select(f => $"== {Path.GetRelativePath(dir, f)} {(OperatingSystem.IsWindows() ? "" : File.GetUnixFileMode(f).ToString())}\n{File.ReadAllText(f)}"));

    /// <summary>
    /// <c>format</c> on a fresh tree per side, at the same path: each run's exit, stdout and stderr, and the files after, equal the C#'s.
    /// <c>outward-links</c> is CliMemoryBoundsTests.cs:162 <c>M3_FormatSkipsScratchDirectoriesAndOutwardLinks</c> and <c>package-link-outside</c> is
    /// <c>FormatTests.PackageNamesSkipALinkLeavingThePackage</c>; their links are made by <see cref="FormatRow"/>. Not here: the C# test hooks
    /// <c>Format.MaxPasses</c> and <c>Format.RewriteHook</c> and <c>WriteReplacing</c>'s temp file and rename (Q1111, Q1122).
    /// </summary>
    [Theory]
    [InlineData("no-path")]
    [InlineData("dash")]
    [InlineData("bad-option")]
    [InlineData("two-paths")]
    [InlineData("missing")]
    [InlineData("a-fix")]
    [InlineData("two-fixes")]
    [InlineData("two-fixes-one-line")]
    [InlineData("attributes")]
    [InlineData("requires")]
    [InlineData("delegates")]
    [InlineData("declarations")]
    [InlineData("shorthand-uses")]
    [InlineData("shorthand-comment")]
    [InlineData("shorthand-lines")]
    [InlineData("shorthand-column-0")]
    [InlineData("shorthand-where")]
    [InlineData("shorthand-two-fails")]
    [InlineData("shorthand-two-uses")]
    [InlineData("second-run")]
    [InlineData("statement-attributes")]
    [InlineData("round3")]
    [InlineData("words")]
    [InlineData("not-tab")]
    [InlineData("pattern-not")]
    [InlineData("member")]
    [InlineData("question-dot")]
    [InlineData("a-real-error")]
    [InlineData("error-dir")]
    [InlineData("no-fix")]
    [InlineData("two-no-fix")]
    [InlineData("formatted")]
    [InlineData("check-changed")]
    [InlineData("check-formatted")]
    [InlineData("check-clean")]
    [InlineData("check-broken")]
    [InlineData("directory")]
    [InlineData("recursive")]
    [InlineData("package")]
    [InlineData("no-temp-file")]
    [InlineData("executable")]
    [InlineData("nested-bin")]
    [InlineData("scratch-dirs")]
    [InlineData("state-lines")]
    [InlineData("line-join-member")]
    [InlineData("line-join-enum-shorthand")]
    [InlineData("line-join-and")]
    [InlineData("line-join-quiet")]
    [InlineData("defaults")]
    [InlineData("package-style")]
    [InlineData("csharp-project")]
    [InlineData("spacing")]
    [InlineData("spacing-blanks")]
    [InlineData("primitive-names")]
    [InlineData("conv-sized")]
    [InlineData("conv-csharp")]
    [InlineData("conv-declared")]
    [InlineData("conv-declared-package")]
    [InlineData("bad-style")]
    [InlineData("bad-style-directory")]
    [InlineData("check-style")]
    [InlineData("check-style-clean")]
    [InlineData("idempotent-empty")]
    [InlineData("idempotent-package")]
    [InlineData("outward-links")]
    [InlineData("package-link-outside")]
    public void FormatAsCliApp(string name)
    {
        if (OperatingSystem.IsWindows() && name is "outward-links" or "package-link-outside") return;
        var runs = FormatRow(name, out var dir);
        var expected = runs.Select(Oracle).ToList();
        var expectedTree = Tree(dir);
        FormatRow(name, out _);
        for (var i = 0; i < runs.Length; i++)
        {
            var actual = SelfhostDriverHarness.Run(runs[i]);
            Assert.Equal(expected[i].Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame($"stdout of `{name}` run {i}", expected[i].Out, actual.Out);
            SelfhostEmitterHarness.AssertSame($"stderr of `{name}` run {i}", expected[i].Err, actual.Err);
        }
        SelfhostEmitterHarness.AssertSame($"files after `{name}`", expectedTree, Tree(dir));
    }

    /// <summary>
    /// An unreadable file or directory is reported and the rest formatted (FormatTests.cs:494, :520); the .NET message after the path differs,
    /// so stderr is compared up to it.
    /// </summary>
    [Theory]
    [InlineData("directory", "a.byn")]
    [InlineData("unreadable-dir", "locked")]
    [InlineData("unreadable-package", "package.byn")]
    public void FormatReportsAnUnreadablePathAsCliApp(string name, string locked)
    {
        if (OperatingSystem.IsWindows()) return;
        var args = FormatRow(name, out var dir)[0];
        var target = Path.Combine(dir, locked);
        var isDir = Directory.Exists(target);
        var open = isDir ? UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute : UnixFileMode.UserRead | UnixFileMode.UserWrite;
        File.SetUnixFileMode(target, UnixFileMode.None);
        try
        {
            try
            {
                if (isDir) _ = Directory.GetFiles(target);
                else _ = File.ReadAllText(target);
                return; // root reads it anyway
            }
            catch (UnauthorizedAccessException) { }
            var expected = Oracle(args);
            File.SetUnixFileMode(target, open);
            var expectedTree = Tree(dir);
            FormatRow(name, out _);
            File.SetUnixFileMode(target, UnixFileMode.None);
            var actual = SelfhostDriverHarness.Run(args);
            File.SetUnixFileMode(target, open);
            Assert.Equal(CliApp.ExitFailure, expected.Exit);
            Assert.Equal(expected.Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
            SelfhostEmitterHarness.AssertSame("files after", expectedTree, Tree(dir));
            // An unreadable `package.byn` is reported against the file being formatted, as `FormatIoError` in `Run`.
            var prefix = $"bayan: {(name == "unreadable-package" ? Path.Combine(dir, "main.byn") : target)}: ";
            Assert.StartsWith(prefix, expected.Err);
            Assert.StartsWith(prefix, actual.Err);
        }
        finally { File.SetUnixFileMode(target, open); }
    }

    /// <summary><c>format loop.byn</c> with <c>loop.byn -> loop.byn</c>: <c>RealPath(file)</c> fails inside <c>Run</c>'s <c>try</c> on both sides; stderr is compared up to the message (Q1106).</summary>
    [Fact]
    public void FormatReportsALoopingFileLinkAsCliApp()
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t8-loop");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var loop = Path.Combine(dir, "loop.byn");
        File.CreateSymbolicLink(loop, "loop.byn");
        string[] args = ["format", loop];
        var expected = Oracle(args);
        var actual = SelfhostDriverHarness.Run(args);
        Assert.Equal(CliApp.ExitFailure, expected.Exit);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
        Assert.StartsWith($"bayan: {loop}: ", expected.Err);
        Assert.StartsWith($"bayan: {loop}: ", actual.Err);
    }

    /// <summary>
    /// A read-only file in a read-only directory fails to be written on both sides (the C#'s temp file, the driver's in-place write, Q1122)
    /// and is reported; stderr is compared up to the .NET message.
    /// </summary>
    [Fact]
    public void FormatReportsAnUnwritableFileAsCliApp()
    {
        if (OperatingSystem.IsWindows()) return;
        var args = FormatRow("a-fix", out var dir)[^1];
        var target = Path.Combine(dir, "main.byn");
        const UnixFileMode Open = UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute;
        void Lock()
        {
            File.SetUnixFileMode(target, UnixFileMode.UserRead);
            File.SetUnixFileMode(dir, UnixFileMode.UserRead | UnixFileMode.UserExecute);
        }
        void Unlock()
        {
            File.SetUnixFileMode(dir, Open);
            File.SetUnixFileMode(target, UnixFileMode.UserRead | UnixFileMode.UserWrite);
        }
        Lock();
        try
        {
            try
            {
                File.WriteAllText(Path.Combine(dir, "probe"), "");
                File.Delete(Path.Combine(dir, "probe"));
                return; // root writes it anyway
            }
            catch (UnauthorizedAccessException) { }
            var expected = Oracle(args);
            Unlock();
            var expectedTree = Tree(dir);
            FormatRow("a-fix", out _);
            Lock();
            var actual = SelfhostDriverHarness.Run(args);
            Unlock();
            Assert.Equal(CliApp.ExitFailure, expected.Exit);
            Assert.Equal(expected.Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame("stdout", expected.Out, actual.Out);
            SelfhostEmitterHarness.AssertSame("files after", expectedTree, Tree(dir));
            var prefix = $"bayan: {target}: ";
            Assert.StartsWith(prefix, expected.Err);
            Assert.StartsWith(prefix, actual.Err);
        }
        finally { Unlock(); }
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

    /// <summary>
    /// Stage 2's <c>format --check</c> over <c>selfhost/</c> and <c>tests/cases/run/</c> equals the C#'s.
    /// </summary>
    [Theory]
    [InlineData("selfhost")]
    [InlineData("tests/cases/run")]
    public void SourcesFormatCheckAsCliApp(string tree)
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Path.Combine(Golden.RepoRoot, tree);
        var expected = Oracle(["format", "--check", dir]);
        var (exit, stdout, stderr) = Run(BootstrapTests.Stage2Executable(), "format", "--check", dir);
        Assert.Equal(expected.Exit, exit);
        SelfhostEmitterHarness.AssertSame($"stdout of format --check {tree}", expected.Out, stdout.ReplaceLineEndings("\n"));
        SelfhostEmitterHarness.AssertSame($"stderr of format --check {tree}", expected.Err, stderr.ReplaceLineEndings("\n"));
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
/// 017 T7: the driver reads the process environment as <c>CliApp.Run</c> does, so the oracle is <c>Decide</c> over <see cref="Environment.GetEnvironmentVariable(string)"/>.
/// Runs alone (the collection is not parallel) because it sets <c>FORCE_COLOR</c> and <c>NO_COLOR</c> in the process.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDriverStyleEnvironmentTests
{
    private const string AuditFixture = "@allow(BYN2230) because \"kept for the C ABI\"\nvoid toHex() {\n}\n\nunsafe void poke() {\n}\n";

    private static readonly string[] s_audit = Fixture("audit", AuditFixture, "audit");

    private static string[] Fixture(string name, string source, params string[] command)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t7-env", name);
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, "main.byn");
        File.WriteAllText(file, source);
        return [.. command, file];
    }

    /// <summary>What the probe prints for <paramref name="args"/>: the command's own output, without the style line the probe appends.</summary>
    private static (int Exit, string Out, string Err) Probe(string[] args)
    {
        var (exit, stdout, stderr) = SelfhostDriverHarness.RunProbe(new Dictionary<string, string>(), ["style", .. args]);
        return (exit, stdout[..stdout.LastIndexOf("\nout ", StringComparison.Ordinal)], stderr);
    }

    private static (int Exit, string Out, string Err) Oracle(string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
    }

    /// <summary>
    /// The painted output of <c>audit</c> (a warning, a note and a success line) under the environment, as <c>CliApp.Run</c>
    /// prints it in this process. <c>vars</c> is <c>NAME=value</c> pairs separated by <c>|</c>; the driver process inherits them.
    /// </summary>
    [Theory]
    [InlineData("NO_COLOR=1", "auto")]
    [InlineData("NO_COLOR=1", "always")]
    [InlineData("NO_COLOR=", "always")]
    [InlineData("FORCE_COLOR=1", "auto")]
    [InlineData("FORCE_COLOR=0", "auto")]
    [InlineData("FORCE_COLOR=1", "never")]
    [InlineData("NO_COLOR=1|FORCE_COLOR=1", "auto")]
    [InlineData("TERM=dumb|FORCE_COLOR=1", "auto")]
    [InlineData("TERM=dumb", "always")]
    [InlineData("TERM=xterm", "always")]
    [InlineData("LANG=C", "always")]
    [InlineData("LC_ALL=C|LANG=en_US.UTF-8", "always")]
    [InlineData("LC_ALL=|LC_CTYPE=POSIX", "always")]
    [InlineData("LC_ALL=de_DE.utf8|LANG=C", "always")]
    [InlineData("COLORTERM=", "always")]
    [InlineData("COLORTERM=truecolor", "always")]
    [InlineData("COLORTERM=24bit", "always")]
    [InlineData("COLORTERM=256color", "always")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=light", "always")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=dark", "always")]
    [InlineData("COLORTERM=24bit|BAYAN_THEME=light", "always")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=other|COLORFGBG=0;15", "always")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=light|COLORFGBG=15;0", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;15", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;7", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;8", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;9", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=15;0", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=7", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=default;15", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;1x", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;16", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;99999999999999999999", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;2147483647", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;2147483648", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;00000000000000000009", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;x99999999999999999999", "always")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;99999999999999999999", "never")]
    [InlineData("COLORTERM=truecolor|COLORFGBG=0;2147483648", "never")]
    [InlineData("COLORTERM=truecolor|FORCE_COLOR=1|BAYAN_THEME=light", "auto")]
    public void TheEnvironmentPaintsAsCliAppRun(string vars, string color)
    {
        var pairs = vars.Split('|').Select(v => v.Split('=', 2)).Select(v => (v[0], (string?)v[1])).ToArray();
        CliEnvironmentTests.WithTerminalEnv(() =>
        {
            string[] args = ["--color", color, .. s_audit];
            var expected = Oracle(args);
            var actual = Probe(args);
            Assert.Equal(expected.Exit, actual.Exit);
            Assert.Equal(expected.Out, actual.Out);
            Assert.Equal(expected.Err, actual.Err);
        }, pairs);
    }

    /// <summary>The oracle rows above only mean something if the environment changes the output: each palette paints its own SGR codes.</summary>
    [Theory]
    [InlineData("COLORTERM=", "\u001b[33m")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=light", "\u001b[38;2;138;83;0m")]
    [InlineData("COLORTERM=truecolor|BAYAN_THEME=dark", "\u001b[38;2;242;193;78m")]
    [InlineData("COLORTERM=24bit|COLORFGBG=0;15", "\u001b[38;2;138;83;0m")]
    public void ThePaletteIsTheOneTheEnvironmentNames(string vars, string warning)
    {
        var pairs = vars.Split('|').Select(v => v.Split('=', 2)).Select(v => (v[0], (string?)v[1])).ToArray();
        CliEnvironmentTests.WithTerminalEnv(() => Assert.Contains(warning + "no reason given", Probe(["--color", "always", .. s_audit]).Out), pairs);
    }

    /// <summary><c>progress.byn</c> with <c>dctx.byn</c> (its <c>DStyle</c>) and a probe <c>main</c>: <c>fit &lt;phase&gt; &lt;room&gt; &lt;ascii&gt;</c>, <c>visible &lt;text&gt;</c>, <c>line &lt;phase&gt; &lt;width&gt; &lt;ascii&gt; &lt;tty&gt; &lt;json&gt;</c> (start, tick, done on stderr).</summary>
    private const string ProgressProbe = """

        i32 main(ReadOnlySpan<string> args) uses alloc, clock, console, env {
            if args[0] == "timed" {
                // timed <phase> <after ms> <ascii> <wait ms>: a timer start, a busy wait, done
                var after: i64 = 0
                for b in args[2].bytes {
                    after = after * 10 + i64(b) - 48
                }
                var wait: i64 = 0
                for b in args[4].bytes {
                    wait = wait * 10 + i64(b) - 48
                }
                let timedStyle = DStyle { ascii: args[3] == "true" }
                var timed = start(in timedStyle, by: true, through: false, for: args[1], after: after * 1000000)
                let begun = Io.monotonicNanos()
                while Io.monotonicNanos() - begun < wait * 1000000 {}
                done(ref timed)
                return 0
            }
            if args[0] == "fit" {
                let ascii = args[3] == "true"
                var room: i64 = 0
                for b in args[2].bytes {
                    room = room * 10 + i64(b) - 48
                }
                Io.stdout.write(fit(args[1], to: room, by: ascii ? "..." : "…", for: ascii ? 3 : 1))
                return 0
            }
            if args[0] == "visible" {
                Io.stdout.write(visible(args[1]))
                return 0
            }
            var width: i64 = 0
            for b in args[2].bytes {
                width = width * 10 + i64(b) - 48
            }
            var extra: i64 = 0
            if args.length > 6 {
                for b in args[6].bytes {
                    extra = extra * 10 + i64(b) - 48
                }
            }
            let style = DStyle { ascii: args[3] == "true", width: width }
            var p = start(in style, by: args[4] == "true", through: args[5] == "true", for: args[1], after: 0)
            for _ in 0..extra {
                tick(ref p)
            }
            done(ref p)
            if extra > 0 {
                done(ref p)
                tick(ref p)
            }
            return 0
        }
        """;

    private static readonly Lazy<(string? Path, string Error)> ProgressBuilt = new(() =>
    {
        // progress.byn is read unchanged (so its coverage counts with the driver's); the probe main is a file of its own
        var sources = new[] { "dctx.byn", "progress.byn" }.Select(f => SourceText.FromFile(Path.Combine(SelfhostDriverHarness.DriverDir, f))).ToList();
        sources.Add(SourceText.FromString(Path.Combine(SelfhostDriverHarness.DriverDir, "progressprobe.byn"), ProgressProbe + "\n"));
        var c = Compilation.Create(sources, packageRoot: SelfhostSemanticsHarness.SelfhostDir);
        if (c.Diagnostics.HasErrors) return (null, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal));
        return build.Succeeded ? (build.ExecutablePath, "") : (null, build.Errors);
    });

    private static (int Exit, string Out, string Err) RunProgress(IReadOnlyDictionary<string, string> env, params string[] args)
    {
        var (path, error) = ProgressBuilt.Value;
        if (path is null) Assert.Fail($"progress.byn with the probe main did not build:\n{error}");
        var psi = new ProcessStartInfo(path!) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var (k, v) in env) psi.Environment[k] = v;
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result, stderr.Result);
    }

    private static string TrueFalse(bool b) => b ? "true" : "false";

    [Theory]
    [InlineData("testing wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww", 35, false)]
    [InlineData("testing wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww", 35, true)]
    [InlineData("testing www", 35, false)]
    [InlineData("漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢", 35, false)]
    [InlineData("漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢漢xy", 35, false)]
    [InlineData("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\u0301", 35, false)]
    [InlineData("\u02ff\u0300\u036f\u0370\u10ff\u1100\u115f\u1160\u2e7f\u2e80\ua4cf\ua4d0\uabff\uac00\ud7a3\ud7a4\uf8ff\uf900\ufaff\ufb00\ufe2f\ufe30\ufe4f\ufe50\ufeff\uff00\uff60\uff61\uffdf\uffe0\uffe6\uffe7\U0001f2ff\U0001f300\U0001f64f\U0001f650\U0001f8ff\U0001f900\U0001f9ff\U0001fa00\U00020000\U0003fffd\U0003fffe", 100, false)]
    [InlineData("abcdef", 2, true)]
    [InlineData("abcdef", 0, false)]
    [InlineData("😀😀😀😀", 5, false)]
    public void FitCutsTheLineAsProgressDoes(string phase, int room, bool ascii)
    {
        var symbols = ascii ? Symbols.Ascii : Symbols.Unicode;
        var expected = Progress.Fit(phase, room, symbols.Ellipsis);
        var (exit, stdout, _) = RunProgress(new Dictionary<string, string>(), "fit", phase, room.ToString(), TrueFalse(ascii));
        Assert.Equal(0, exit);
        Assert.Equal(expected, stdout);
    }

    [Theory]
    [InlineData("plain")]
    [InlineData("a\u001b]0;PWNED\u0007b")]
    [InlineData("tab\there\u007f\u0085")]
    [InlineData("bidi\u202eevil\u2066x\u061c\u200f")]
    [InlineData("é漢😀")]
    [InlineData("é漢😀\u001b\u0085x")]
    [InlineData("\u061c\u200d\u200e\u200f\u2029\u202a\u202b\u202c\u202d\u202e\u202f\u2065\u2066\u2067\u2068\u2069\u206a\u009f\u00a0\u007e\u001f\u0020")]
    [InlineData("")]
    public void VisibleEscapesControlsAsTerminalStyleDoes(string text)
    {
        var (exit, stdout, _) = RunProgress(new Dictionary<string, string>(), "visible", text);
        Assert.Equal(0, exit);
        Assert.Equal(TerminalStyle.Visible(text), stdout);
    }

    [Theory]
    [InlineData("compiling", 100, false, true, false, "")]
    [InlineData("compiling", 100, true, true, false, "")]
    [InlineData("compiling", 100, false, false, false, "")]
    [InlineData("compiling", 100, false, true, true, "")]
    [InlineData("compiling", 100, false, true, false, "1")]
    [InlineData("testing y\u001b]0;PWNED\u0007\u001b[2J", 100, false, true, false, "")]
    [InlineData("testing wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww", 40, true, true, false, "")]
    [InlineData("testing wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww", 40, false, true, false, "")]
    public void TheLineIsDrawnAndClearedAsProgressDoes(string phase, int width, bool ascii, bool tty, bool json, string ci) =>
        AssertLine(phase, width, ascii, tty, json, ci, 0);

    /// <summary>The timer's later ticks, <c>Done</c> twice and a tick after <c>Done</c>.</summary>
    [Theory]
    [InlineData(false, 3)]
    [InlineData(true, 3)]
    [InlineData(false, 1)]
    public void LaterTicksAndASecondDoneAsProgressDoes(bool ascii, int extra) =>
        AssertLine("compiling", 100, ascii, true, false, "", extra);

    /// <summary>The timer (a zero threshold draws once and starts none, so waiting adds no frame): a threshold passed (one frame, two frames after a second interval; one for ASCII) or not (nothing), as the C# <c>Timer</c> draws it.</summary>
    [Theory]
    [InlineData(false, 1, 150)]
    [InlineData(false, 1, 400)]
    [InlineData(true, 1, 400)]
    [InlineData(false, 0, 400)]
    [InlineData(true, 0, 400)]
    [InlineData(false, 10000, 150)]
    [InlineData(true, 10000, 150)]
    public void TheTimerDrawsAsProgressDoes(bool ascii, int afterMs, int waitMs)
    {
        var style = Style.Plain with { Symbols = ascii ? Symbols.Ascii : Symbols.Unicode };
        var writer = new StringWriter();
        using (var progress = Progress.Start(writer, style, true, false, _ => null, "compiling", TimeSpan.FromMilliseconds(afterMs)))
        {
            Thread.Sleep(waitMs);
            progress.Done();
        }
        var (exit, _, stderr) = RunProgress(new Dictionary<string, string> { ["CI"] = "" }, "timed", "compiling", afterMs.ToString(), TrueFalse(ascii), waitMs.ToString());
        Assert.Equal(0, exit);
        Assert.Equal(writer.ToString(), stderr);
        Assert.Equal(afterMs > waitMs, stderr.Length == 0);
    }

    // listed skip: ProgressTests.cs rows with stderr a terminal. The law runs without one, and the driver has no tty test (Q919), so
    // `Progress` is never on in a driver run; `TheLineIsDrawnAndClearedAsProgressDoes` and `TheTimerDrawsAsProgressDoes` run `start` with `by: true` directly.

    private static void AssertLine(string phase, int width, bool ascii, bool tty, bool json, string ci, int extra)
    {
        var style = Style.Plain with { Symbols = ascii ? Symbols.Ascii : Symbols.Unicode, Width = width };
        var writer = new StringWriter();
        using (var progress = Progress.Start(writer, style, tty, json, name => name == "CI" ? ci : null, phase, TimeSpan.Zero))
        {
            var tick = typeof(Progress).GetMethod("Tick", BindingFlags.NonPublic | BindingFlags.Instance)!;
            for (var i = 0; i < extra; i++) tick.Invoke(progress, null);
            progress.Done();
            if (extra > 0)
            {
                progress.Done();
                tick.Invoke(progress, null);
            }
        }
        var (exit, _, stderr) = RunProgress(new Dictionary<string, string> { ["CI"] = ci }, "line", phase, width.ToString(), TrueFalse(ascii), TrueFalse(tty), TrueFalse(json), extra.ToString());
        Assert.Equal(0, exit);
        Assert.Equal(writer.ToString(), stderr);
    }
}

/// <summary>
/// 017 T7, L028: every <c>tests/cases/style/</c> shape of the commands the driver ports (<c>check</c>, <c>build</c>, <c>run</c>, <c>audit</c>), rendered in the
/// three renderings of <c>StyleTests</c> (colour on a dark truecolor terminal, plain, <c>--ascii</c>) and with <c>--color always</c>, <c>FORCE_COLOR</c>,
/// <c>NO_COLOR</c> and <c>TERM=dumb</c>, against <c>CliApp.Run</c> in this process under the same environment (no terminal, as the law runs).
/// Listed skips: <c>build-ok-cache</c> (the cache hit of <c>build</c> is not reported, T9 `build` cache); the shapes of commands the driver still refuses are <c>test-ok</c>, <c>test-fail</c>, <c>test-pending</c>, <c>test-verbose</c>,
/// <c>test-assert-values</c> and <c>test-control-chars</c> (T11 `test`); <c>diag-secondary</c> calls the renderer and
/// <c>CliApp.ReportToolchain</c> directly, no command prints it; <c>doctor-ok</c> and <c>doctor-fail</c> render fixed checks, which
/// <c>SelfhostDefaultT5Tests</c> compares to the same files. The SGR codes are compared for every shape.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed partial class SelfhostDriverStyleCaseTests
{
    private const string Ok = "void main() {\n    print(\"hi\")\n}\n";

    private const string Broken = "void main() {\n    let x = 1\n    x = 2\n    print($\"{x}\")\n}\n";

    private static readonly string Many = "void main() {\n    var y = 0\n" + string.Concat(Enumerable.Range(1, 25).Select(i => $"    y = x{i}\n")) + "}\n";

    public static TheoryData<string, string> Rows()
    {
        var data = new TheoryData<string, string>();
        foreach (var shape in new[] { "diag-error-fix", "diag-removal-fix", "diag-cap", "diag-cap-all", "diag-warning", "types-ok", "types-fail", "check-json", "build-ok", "build-ok-verbose", "build-fail", "build-ice", "check-ok", "run-fail", "audit" })
            foreach (var rendering in new[] { "color", "plain", "ascii", "always", "force", "no-color", "dumb" })
            {
                // listed skip: the fake C compiler of `build-ice` is a shell script
                if (shape == "build-ice" && OperatingSystem.IsWindows()) continue;
                data.Add(shape, rendering);
            }
        return data;
    }

    private static (string Source, string[][] Runs) Shape(string shape, string main, string output) => shape switch
    {
        "diag-error-fix" => ("void main() {\n    let total = 0\n    total += 1\n    print($\"{total}\")\n}\n", [["check", main]]),
        "diag-removal-fix" => ("i64 twice(i64 x) => x * 2\n\nvoid main() {\n    let n = try twice(2)\n    print($\"{n}\")\n}\n", [["check", main]]),
        "diag-warning" => ("void main() {\n    var x = 1\n}\n", [["check", main]]),
        "types-ok" => (Ok, [["types", main]]),
        "types-fail" => (Broken, [["types", main]]),
        "check-json" => (Ok, [["check", "--diagnostics", "json", main]]),
        "diag-cap" => (Many, [["check", main]]),
        "diag-cap-all" => (Many, [["check", "--all", main]]),
        "build-ok" => (Ok, [["build", "-o", output, main]]),
        "build-ok-verbose" => (Ok, [["build", "-v", "-o", output, main]]),
        "build-fail" => (Broken, [["build", "-o", output, main]]),
        // BYN4001: `PATH` holds only a `cc` script that refuses the C and exits 1, so the toolchain reports `Rejected`
        // (the driver does not read `BAYAN_CC`, spec Q1)
        "build-ice" => (Ok, [["build", "-o", output, main]]),
        "check-ok" => (Ok, [["check", main]]),
        "run-fail" => (Broken, [["run", main]]),
        "audit" => ("@allow(BYN2230) because \"kept for the C ABI\"\nvoid toHex() {\n}\n\nunsafe void poke() {\n}\n", [["audit", main]]),
        _ => throw new ArgumentException($"unknown shape `{shape}`", nameof(shape)),
    };

    [GeneratedRegex(@"\d+\.\d+s")]
    private static partial Regex Seconds();

    private static string Mask(string text) => Seconds().Replace(text.ReplaceLineEndings("\n"), "0.00s");

    [Theory]
    [MemberData(nameof(Rows))]
    public void RendersAsCliAppRun(string shape, string rendering)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t7-style", shape + "-" + rendering, "tally");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var main = Path.Combine(dir, "main.byn");
        var (source, runs) = Shape(shape, main, Path.Combine(dir, Targets.ExecutableName("tally", CliApp.HostTarget)));
        File.WriteAllText(main, source);
        var fakeBin = Path.Combine(dir, "fakebin");
        var fakeCc = Path.Combine(fakeBin, "cc");
        if (shape == "build-ice")
        {
            Directory.CreateDirectory(fakeBin);
            File.WriteAllText(fakeCc, "#!/bin/sh\necho \"main.byn:2:5: error: use of undeclared identifier 'l0_y'\" >&2\nexit 1\n");
            if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(fakeCc, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
        string[] flags = rendering switch
        {
            "color" or "always" or "dumb" => ["--color", "always"],
            "ascii" => ["--ascii", "--color", "always"],
            "plain" => ["--color", "never"],
            _ => [],
        };
        (string, string?)[] env = rendering switch
        {
            "color" or "ascii" => [("COLORTERM", "truecolor"), ("BAYAN_THEME", "dark"), ("CI", "1")],
            "force" => [("FORCE_COLOR", "1"), ("COLORTERM", "truecolor"), ("CI", "1")],
            "no-color" => [("NO_COLOR", "1"), ("FORCE_COLOR", "1"), ("CI", "1")],
            "dumb" => [("TERM", "dumb"), ("CI", "1")],
            _ => [("CI", "1")],
        };
        string Text(string text) => Mask(text);
        // each side builds into a cache of its own, so a hit on one is never a hit on the other
        string Side(bool driver)
        {
            var cache = Path.Combine(Golden.RepoRoot, "tmp", "t7-style-cache", shape + "-" + rendering + (driver ? "-driver" : "-csharp"));
            if (Directory.Exists(cache)) Directory.Delete(cache, recursive: true);
            var text = "";
            CliEnvironmentTests.WithTerminalEnv(() =>
            {
                foreach (var run in runs)
                {
                    string[] args = [.. flags, .. run];
                    var (exit, stdout, stderr) = driver ? SelfhostDriverHarness.Run(args) : Oracle(args);
                    text = $"exit: {exit}\n--- stdout ---\n{Text(stdout)}--- stderr ---\n{Text(stderr)}";
                }
            }, [.. env, ("BAYAN_CACHE", cache), .. shape == "build-ice" ? new (string, string?)[] { ("PATH", fakeBin) } : []]);
            return text;
        }
        Assert.Equal(Side(driver: false), Side(driver: true));
    }

    private static (int Exit, string Out, string Err) Oracle(string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString(), stderr.ToString());
    }
}
