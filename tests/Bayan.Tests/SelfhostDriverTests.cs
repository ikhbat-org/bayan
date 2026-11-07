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
    /// CliTests.cs:172 <c>AuditReportsALoopingFileLink</c>: a <c>loop.byn</c> that links to itself is reported and the walk goes on; stdout and exit equal the C#'s, stderr up to the message.
    /// Listed skips (Q1106, no builtin reports a link target): CliTests.cs:146 <c>AuditWalksSymlinkCyclesOnce</c> and CliTests.cs:158 <c>AuditWalksASymlinkToAParentOfTheRootOnce</c>
    /// (the driver walks a link to a parent 33 times where the C# resolves it and walks once), and CliMemoryBoundsTests.cs:162-200's symlink-outward row.
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

    /// <summary><c>manifestFor</c> against the private <c>Format.ManifestFor</c>: the directory of the nearest <c>package.byn</c> (or none) for each file, and how many directories the cache holds after, with the second file of a directory answered from the cache. <c>Manifest.Read</c> is a stub (Q1107), so the manifest itself is not compared.</summary>
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

    /// <summary><c>packageNames</c> against the private <c>Format.PackageNames</c> where the C# set is empty (files holding only a comment, an unreadable one, a missing directory); <c>OtherUses</c> is a stub (Q1107), so a set with names is not compared.</summary>
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
        (Dictionary<string, string>, string[][]) One(string text, params string[] args) => (new() { ["main.byn"] = text }, [[.. args, "{D}/main.byn"]]);
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
            "unreadable-dir" => (new() { ["locked/a.byn"] = "let a = true;\n", ["b.byn"] = Fixable }, [["{D}"]]),
            "nested-bin" => (new() { ["src/bin/x.byn"] = "unsafe void poke() {\n}\n" + Unless }, [["--check", "{D}"]]),
            "scratch-dirs" => (new() { [".worktrees/x/a.byn"] = Unless, ["tmp/b.byn"] = Unless, ["src/ok.byn"] = Unless }, [["--check", "{D}"]]),
            "state-lines" => Twice(Diag("state-line-input.byn")),
            "line-join-member" => One(Diag("line-join-member.byn")),
            "line-join-enum-shorthand" => One(Diag("line-join-enum-shorthand.byn")),
            "line-join-and" => One(Diag("line-join-and.byn")),
            "line-join-quiet" => One(Diag("line-join-quiet.byn"), "--check"),
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
        var d = dir;
        return [.. runs.Select(args => (string[])["format", .. args.Select(a => a.Replace("{D}", d))])];
    }

    /// <summary>Every file under <paramref name="dir"/> with its Unix mode and text, in ordinal order; a temp file left behind shows here.</summary>
    private static string Tree(string dir) => string.Join("", Directory.GetFiles(dir, "*", SearchOption.AllDirectories)
        .Order(StringComparer.Ordinal)
        .Select(f => $"== {Path.GetRelativePath(dir, f)} {(OperatingSystem.IsWindows() ? "" : File.GetUnixFileMode(f).ToString())}\n{File.ReadAllText(f)}"));

    /// <summary>
    /// <c>format</c> on a fresh tree per side, at the same path: each run's exit, stdout and stderr, and the files after, equal the C#'s.
    /// Not here: rows needing the package style or the collectors (primitive renames, Q1121), the C# test hooks
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
    public void FormatAsCliApp(string name)
    {
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
            var prefix = $"bayan: {target}: ";
            Assert.StartsWith(prefix, expected.Err);
            Assert.StartsWith(prefix, actual.Err);
        }
        finally { File.SetUnixFileMode(target, open); }
    }

    /// <summary>
    /// A read-only file in a read-only directory fails to be written on both sides (the C#'s temp file, the driver's in-place write, Q1122)
    /// and is reported; stderr is compared up to the .NET message.
    /// </summary>
    [Fact]
    public void FormatReportsAnUnwritableFileAsCliApp()
    {
        if (OperatingSystem.IsWindows()) return;
        var args = FormatRow("a-fix", out var dir)[0];
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
    /// Stage 2's <c>format --check</c> over <c>selfhost/</c> and <c>tests/cases/run/</c> equals the C#'s, except the C#'s
    /// <c>would format</c> line for <c>csharp-primitive-names.byn</c>, a primitive rename the stage-2 driver does not make (Q1121).
    /// </summary>
    [Theory]
    [InlineData("selfhost")]
    [InlineData("tests/cases/run")]
    public void SourcesFormatCheckAsCliApp(string tree)
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Path.Combine(Golden.RepoRoot, tree);
        var expected = Oracle(["format", "--check", dir]);
        var skipped = $"would format {Path.Combine(dir, "csharp-primitive-names.byn")}\n";
        var expectedOut = expected.Out.Replace(skipped, "");
        var expectedExit = expected.Exit == CliApp.ExitFailure && expectedOut == "" && expected.Err == "" ? CliApp.ExitOk : expected.Exit;
        var (exit, stdout, stderr) = Run(BootstrapTests.Stage2Executable(), "format", "--check", dir);
        Assert.Equal(expectedExit, exit);
        SelfhostEmitterHarness.AssertSame($"stdout of format --check {tree}", expectedOut, stdout.ReplaceLineEndings("\n"));
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
