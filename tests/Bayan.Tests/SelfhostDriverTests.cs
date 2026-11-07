using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Reflection;
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
    [InlineData("format")]
    [InlineData("audit")]
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
    [InlineData("NO_COLOR", "1", "auto", false)]
    [InlineData("NO_COLOR", "1", "always", false)]
    [InlineData("NO_COLOR", "", "auto", false)]
    [InlineData("FORCE_COLOR", "1", "auto", false)]
    [InlineData("FORCE_COLOR", "0", "auto", false)]
    [InlineData("FORCE_COLOR", "1", "never", false)]
    [InlineData("TERM", "dumb", "auto", false)]
    [InlineData("TERM", "dumb", "always", true)]
    [InlineData("TERM", "xterm", "auto", false)]
    [InlineData("COLORTERM", "truecolor", "always", false)]
    [InlineData("BAYAN_THEME", "light", "always", false)]
    [InlineData("COLORFGBG", "0;15", "always", false)]
    [InlineData("LANG", "C", "auto", false)]
    [InlineData("LANG", "en_US.UTF-8", "auto", false)]
    [InlineData("LANG", "en_US.utf8", "auto", false)]
    [InlineData("LC_CTYPE", "POSIX", "auto", false)]
    [InlineData("LC_ALL", "C", "auto", false)]
    public void TheEnvironmentDecidesTheStyleAsCliAppRun(string name, string value, string color, bool ascii)
    {
        // CliApp.Run reads Environment.GetEnvironmentVariable, so the C# side is `Decide` over the same variable.
        string? Env(string k) => k == name ? value : "";
        var expected = TerminalStyle.Decide(color, ascii, false, Env, 0);
        string[] args = ascii ? ["--ascii", "--color", color, "version"] : ["--color", color, "version"];
        Assert.Equal(StyleLine(expected, expected, false), ProbeStyle(StyleEnvironment(name, value), args));
    }

    [Theory]
    [InlineData("LC_ALL", "C", "LANG", "en_US.UTF-8")]
    [InlineData("LC_ALL", "", "LANG", "C")]
    [InlineData("LC_CTYPE", "en_US.UTF-8", "LANG", "C")]
    [InlineData("LC_ALL", "de_DE.UTF-8", "LC_CTYPE", "C")]
    public void TheFirstNonEmptyLocaleDecidesTheSymbols(string first, string firstValue, string second, string secondValue)
    {
        var env = StyleEnvironment(first, firstValue);
        env[second] = secondValue;
        var expected = TerminalStyle.Decide("auto", false, false, k => env.GetValueOrDefault(k), 0);
        Assert.Equal(StyleLine(expected, expected, false), ProbeStyle(env, ["version"]));
    }

    [Theory]
    [InlineData("NO_COLOR", "1", "auto", true, 80)]
    [InlineData("FORCE_COLOR", "1", "auto", false, 80)]
    [InlineData("TERM", "dumb", "auto", true, 80)]
    [InlineData("TERM", "xterm", "auto", true, 0)]
    [InlineData("LANG", "C", "auto", true, 80)]
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
/// 017 T7: the driver reads the process environment as <c>CliApp.Run</c> does, so the oracle is <c>Decide</c> over <see cref="Environment.GetEnvironmentVariable(string)"/>.
/// Runs alone (the collection is not parallel) because it sets <c>FORCE_COLOR</c> and <c>NO_COLOR</c> in the process.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDriverStyleEnvironmentTests
{
    [Theory]
    [InlineData("FORCE_COLOR")]
    [InlineData("NO_COLOR")]
    public void TheStyleIsDecidedFromTheProcessEnvironment(string name)
    {
        var saved = Environment.GetEnvironmentVariable(name);
        Environment.SetEnvironmentVariable(name, "1");
        try
        {
            foreach (var args in new[] { new[] { "version" }, ["--color", "auto", "version"], ["--ascii", "version"] })
                Assert.Equal(SelfhostDriverT1Tests.CsStyle(args, Environment.GetEnvironmentVariable), SelfhostDriverT1Tests.ProbeStyle(new Dictionary<string, string>(), args));
        }
        finally { Environment.SetEnvironmentVariable(name, saved); }
    }

    /// <summary><c>progress.byn</c> with <c>dctx.byn</c> (its <c>DStyle</c>) and a probe <c>main</c>: <c>fit &lt;phase&gt; &lt;room&gt; &lt;ascii&gt;</c>, <c>visible &lt;text&gt;</c>, <c>line &lt;phase&gt; &lt;width&gt; &lt;ascii&gt; &lt;tty&gt; &lt;json&gt;</c> (start, tick, done on stderr).</summary>
    private const string ProgressProbe = """

        i32 main(ReadOnlySpan<string> args) uses alloc, console, env {
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
            var p = start(in style, by: args[4] == "true", through: args[5] == "true", for: args[1], immediate: true)
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
