using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;
using Bayan.Backend.C;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 012 T7 (R10): the golden cases of <c>lex</c>, <c>parse</c>, <c>typed</c>, <c>diag</c> and <c>run</c> through stage 2, the executable
/// <see cref="BootstrapTests"/> builds. Commands, per C# test: <c>LexerTests</c> <c>lex FILE</c> (<c>.tokens</c>); <c>ParserTests</c>
/// <c>parse --ast FILE</c> (<c>.ast</c>); <c>TypedDumpTests</c> <c>types --package DIR FILE</c> (<c>.types</c>), run in <c>DIR</c> on the
/// bare file name as <c>Golden.Load</c> names it; <c>RunTests</c> <c>run --package DIR [--mode M] FILE [-- ARGS]</c> (<c>.stdout</c>,
/// <c>.exitcode</c> and the optional <c>.stderr</c>). The comparison is <see cref="Golden.Compare"/> as in the C# tests.
/// <c>DiagTests</c> renders with <c>RenderAll</c>, which no command prints (the CLI adds a path line and a summary), so the
/// dispatcher's ruling (Q1052) is: stage 2's <c>check</c> and the C# CLI's (<c>dotnet bayan.dll</c>), same arguments and directory, agree on
/// exit code, stdout and stderr (elapsed seconds masked); the <c>.diag</c> files stay <c>DiagTests</c>'. The same ruling for <c>run</c>
/// stderr: stage 2's equals the C# CLI's on the case, since both print the compile warnings before the program's own output.
/// A <c>run/</c> input is left out when its file name ends in <c>.test.byn</c> (<c>RunTests</c> runs those with <c>bayan test -v</c>) or a
/// <c>.stdin</c> file with the same name beside it exists (spec Q5: stage 2's <c>run</c> feeds no stdin). The only skips are the two <c>diag/</c> cases in <see cref="DiagSkips"/> (Q1052).
/// The <c>.test.byn</c> cases go through <c>test</c> instead (017 T11): <see cref="TestAsCSharpCli"/> and <see cref="CasesTypeMismatchAsCSharpTest"/>.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed class SelfhostDriverGoldenTests
{
    private const ulong Seed = 0x9E3779B97F4A7C15;

    private const int QuickDivisor = 12;

    private static bool Full => Environment.GetEnvironmentVariable("BAYAN_LAW_TIER") == "full";

    internal static List<string> Pick(List<string> names)
    {
        if (Full) return names;
        var order = Enumerable.Range(0, names.Count).ToArray();
        var state = Seed;
        for (var i = order.Length - 1; i > 0; i--)
        {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            var j = (int)(state % (ulong)(i + 1));
            (order[i], order[j]) = (order[j], order[i]);
        }
        var keep = order.Take((names.Count + QuickDivisor - 1) / QuickDivisor).ToHashSet();
        return names.Where((_, i) => keep.Contains(i)).ToList();
    }

    private static TheoryData<string> Rows(string kind, Func<string, bool>? keep = null)
    {
        var data = new TheoryData<string>();
        foreach (var name in Pick([.. Golden.Cases(kind).Cast<object[]>().Select(r => (string)r[0]).Where(n => keep?.Invoke(n) ?? true)]))
            data.Add(name);
        return data;
    }

    private static bool InScope(string name) =>
        !name.EndsWith(".test.byn", StringComparison.Ordinal) && !File.Exists(Path.ChangeExtension(Path_(name), ".stdin"));

    public static TheoryData<string> Lex => Rows("lex");
    public static TheoryData<string> Parse => Rows("parse");
    public static TheoryData<string> Typed => Rows("typed");
    public static TheoryData<string> Diag => Rows("diag", name => !DiagSkips.ContainsKey(name));

    /// <summary>
    /// Listed skips of <c>diag/</c>: cases whose <c>.diag</c> holds a code that no C# CLI <c>check</c> invocation prints (Q1052), so comparing
    /// stage 2 with the CLI would pass without covering it. <see cref="DiagSkipsAreGapsInTheCli"/> checks each is still such a gap.
    /// </summary>
    private static readonly Dictionary<string, string> DiagSkips = new()
    {
        ["diag/capability-exceeded/main.byn"] = "Q1052", // BYN6004 needs the manifest's capabilities; `check .` stops at the missing src/app, `--package` ignores package.byn
        ["diag/std-imports-package/main.byn"] = "Q1052", // BYN2033 needs the case's stdlib/ as the std library: the CLI reads only the shipped std and stops at BYN2032
    };
    /// <summary>
    /// <c>BAYAN_GOLDEN_SHARD=i/n</c> (0 &lt;= i &lt; n) keeps the <c>run/</c> cases whose index among the in-scope ones is i modulo n, so the slow
    /// theory can run in slices that each fit a time limit; unset keeps them all. Every case is built twice (stage 2 and the C# CLI).
    /// </summary>
    public static TheoryData<string> Run
    {
        get
        {
            var shard = Environment.GetEnvironmentVariable("BAYAN_GOLDEN_SHARD")?.Split('/');
            var data = new TheoryData<string>();
            var index = 0;
            foreach (var name in Pick([.. Golden.Cases("run").Cast<object[]>().Select(r => (string)r[0]).Where(InScope)]))
            {
                if (shard is not [var i, var n] || index++ % int.Parse(n) == int.Parse(i)) data.Add(name);
            }
            return data;
        }
    }

    private sealed record Result(int Exit, string Stdout, string Stderr);

    private static Result Start(string program, string[] prefix, string cwd, string[] args, (string Name, string? Value)[]? env = null)
    {
        var psi = new ProcessStartInfo(program)
        {
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            StandardOutputEncoding = Encoding.UTF8,
            RedirectStandardError = true,
            StandardErrorEncoding = Encoding.UTF8,
            UseShellExecute = false,
            WorkingDirectory = cwd,
        };
        foreach (var a in prefix) psi.ArgumentList.Add(a);
        foreach (var a in args) psi.ArgumentList.Add(a);
        foreach (var (name, value) in env ?? []) psi.Environment[name] = value;
        using var p = Process.Start(psi)!;
        p.StandardInput.Close();
        var stdout = p.StandardOutput.ReadToEndLfAsync();
        var stderr = p.StandardError.ReadToEndLfAsync();
        var waitMs = TestTime.Scale(300_000);
        if (!p.WaitForExit(waitMs))
        {
            p.Kill();
            Assert.Fail($"{program} {string.Join(' ', args)}: timed out after {waitMs} ms");
        }
        return new Result(p.ExitCode, stdout.Result, stderr.Result);
    }

    private static Result Stage2(string cwd, params string[] args) => Start(BootstrapTests.Stage2Executable(), [], cwd, args);

    private static Result CSharp(string cwd, params string[] args) => Start("dotnet", [typeof(CliApp).Assembly.Location], cwd, args);

    /// <summary>L028's mask: the elapsed seconds of <c>check</c>'s summary.</summary>
    private static string Mask(string text) => Regex.Replace(text, @"[0-9]+\.[0-9]{2}s", "<t>s");

    private static string Path_(string name) => Path.Combine(Golden.CasesRoot, name);

    /// <summary>A fresh empty directory under <c>tmp/golden/</c> for <paramref name="name"/>.</summary>
    private static string Work(string name)
    {
        var work = Path.Combine(Golden.RepoRoot, "tmp", "golden", Path.ChangeExtension(name, null).Replace('/', '_'));
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        return work;
    }

    private static string? Failure(string name, string extension, string actual, bool optional = false)
    {
        var expected = Path.ChangeExtension(Path_(name), extension);
        if (optional && actual.Length == 0 && !File.Exists(expected)) return null;
        // Never updates, whatever BAYAN_UPDATE says: the goldens are the C# tests' to write, stage 2 must not (R10).
        return Golden.Compare(expected, actual, update: false).Failure;
    }

    [Theory]
    [MemberData(nameof(Lex))]
    public void LexGolden(string name)
    {
        if (Failure(name, ".tokens", Stage2(Golden.RepoRoot, "lex", Path_(name)).Stdout) is { } f) Assert.Fail(f);
    }

    [Theory]
    [MemberData(nameof(Parse))]
    public void ParseGolden(string name)
    {
        if (Failure(name, ".ast", Stage2(Golden.RepoRoot, "parse", "--ast", Path_(name)).Stdout) is { } f) Assert.Fail(f);
    }

    [Theory]
    [MemberData(nameof(Typed))]
    public void TypedGolden(string name)
    {
        var dir = Path.GetDirectoryName(Path_(name))!;
        var r = Stage2(dir, "types", "--package", dir, Path.GetFileName(name));
        Assert.True(r.Exit == 0, r.Stderr);
        if (Failure(name, ".types", r.Stdout) is { } f) Assert.Fail(f);
    }

    /// <summary>The <c>check</c> arguments and directory for a diag case: a package directory is checked as a project, a file with <c>--package</c> on its directory.</summary>
    private static (string Cwd, string[] Args) DiagCommand(string name)
    {
        var path = Path_(name);
        var dir = Path.GetDirectoryName(path)!;
        // `--all` lifts the 20-diagnostic cap that hid map-copy's and input-paren-braceless-body's codes. A package directory without `src/`
        // (the CLI stops at the missing entry module) is checked as its `main.byn` with `--package`, as DiagTests compiles it.
        if (name.Count(c => c == '/') > 1) return Directory.Exists(Path.Combine(dir, "src")) ? (dir, ["check", "--all", "."]) : (dir, ["check", "--all", "--package", dir, "main.byn"]);
        return (dir, ["check", "--all", "--package", dir, Path.GetFileName(path)]);
    }

    private static HashSet<string> Codes(string text) => [.. Regex.Matches(text, @"BYN[0-9]+").Select(m => m.Value)];

    [Theory]
    [MemberData(nameof(Diag))]
    public void DiagAsCSharpCli(string name)
    {
        var (cwd, args) = DiagCommand(name);
        var expected = CSharp(cwd, args);
        var actual = Stage2(cwd, args);
        Assert.Equal(expected.Exit, actual.Exit);
        Assert.Equal(Mask(expected.Stdout), Mask(actual.Stdout));
        Assert.Equal(Mask(expected.Stderr), Mask(actual.Stderr));
        var missing = Codes(File.ReadAllText(Path.ChangeExtension(Path_(name), ".diag"))).Except(Codes(expected.Stdout + expected.Stderr)).ToList();
        Assert.True(missing.Count == 0, $"{name}: the C# CLI's check does not print {string.Join(", ", missing)} from its .diag");
    }

    [Fact]
    public void DiagSkipsAreGapsInTheCli()
    {
        foreach (var name in DiagSkips.Keys)
        {
            var (cwd, args) = DiagCommand(name);
            var expected = CSharp(cwd, args);
            Assert.NotEmpty(Codes(File.ReadAllText(Path.ChangeExtension(Path_(name), ".diag"))).Except(Codes(expected.Stdout + expected.Stderr)));
        }
    }

    /// <summary>
    /// 017 T11: cases-type-mismatch's BYN2202 needs IncludeTests, which <c>check</c> never sets; the C# <c>test --all</c> (CliApp.cs:618) does,
    /// and so does the driver's <c>test</c> (test.byn <c>testCommand</c>), so the case is compared through <c>test</c> instead of skipped.
    /// </summary>
    [Fact]
    public void CasesTypeMismatchAsCSharpTest()
    {
        var tests = Path_("diag/cases-type-mismatch.test.byn");
        var dir = Path.GetDirectoryName(tests)!;
        string[] args = ["test", "--all", "--package", dir, Path.GetFileName(tests)];
        var cs = CSharp(dir, args);
        Assert.Empty(Codes(File.ReadAllText(Path.ChangeExtension(tests, ".diag"))).Except(Codes(cs.Stdout + cs.Stderr)));
        var actual = Start(SelfhostDriverHarness.Build(), [], dir, args);
        Assert.Equal(cs.Exit, actual.Exit);
        Assert.Equal(Mask(cs.Stdout), Mask(actual.Stdout));
        Assert.Equal(Mask(cs.Stderr), Mask(actual.Stderr));
    }

    /// <summary>The <c>test</c> runs this class compares: every <c>run/*.test.byn</c> alone in a directory, with each of these flags.</summary>
    public static IEnumerable<object[]> TestRuns() =>
        from name in Golden.Cases("run").Cast<object[]>().Select(r => (string)r[0]).Where(n => n.EndsWith(".test.byn", StringComparison.Ordinal))
        from flag in new[] { "", "-v", "--json", "--coverage" }
        select new object[] { name, flag };

    /// <summary>L028's mask for <c>test</c>: the elapsed seconds, and the timings of <c>results.json</c> and <c>bayan-quality.json</c>.</summary>
    private static string MaskTest(string text) => Regex.Replace(Mask(text), @"""(durationMs|build_s|total_s)"": [0-9.E+-]+", "\"$1\": <t>");

    /// <summary>
    /// 017 T11 (L028): the C# CLI (<c>dotnet bayan.dll</c>) and the driver's harness build run <paramref name="args"/> one after the other in
    /// <paramref name="cwd"/>, each after its <c>out/</c> directories are removed, and agree on exit code, stdout, stderr and every file under an
    /// <c>out/test</c> (seconds and timings masked).
    /// </summary>
    private static void AssertTestAsCSharp(string cwd, string[] args, (string Name, string? Value)[]? env = null)
    {
        Result Once(Func<Result> run, out Dictionary<string, string> files)
        {
            foreach (var dir in Directory.GetDirectories(cwd, "out", SearchOption.AllDirectories)) Directory.Delete(dir, recursive: true);
            var r = run();
            files = Directory.GetDirectories(cwd, "out", SearchOption.AllDirectories).Select(d => Path.Combine(d, "test")).Where(Directory.Exists)
                .SelectMany(d => Directory.GetFiles(d, "*", SearchOption.AllDirectories)).Where(f => f.EndsWith(".json") || f.EndsWith(".cov.txt")).ToDictionary(f => Path.GetRelativePath(cwd, f), f => MaskTest(File.ReadAllText(f)));
            return r;
        }
        var expected = Once(() => Start("dotnet", [typeof(CliApp).Assembly.Location], cwd, args, env), out var expectedFiles);
        var actual = Once(() => Start(SelfhostDriverHarness.Build(), [], cwd, args, env), out var actualFiles);
        var what = string.Join(' ', args);
        Assert.True(expected.Exit == actual.Exit, $"{what}: exit {actual.Exit}, the C# CLI's {expected.Exit}\n{actual.Stdout}{actual.Stderr}");
        Assert.Equal(MaskTest(expected.Stdout), MaskTest(actual.Stdout));
        Assert.Equal(MaskTest(expected.Stderr), MaskTest(actual.Stderr));
        Assert.Equal(expectedFiles.Keys.Order(StringComparer.Ordinal), actualFiles.Keys.Order(StringComparer.Ordinal));
        foreach (var (file, text) in expectedFiles) Assert.Equal(text, actualFiles[file]);
    }

    /// <summary>017 T11 (L028): <c>test</c> on each <c>run/*.test.byn</c> (the cases <c>RunTests</c> runs with <c>bayan test -v</c>), its directory named as the case.</summary>
    [Theory]
    [MemberData(nameof(TestRuns))]
    public void TestAsCSharpCli(string name, string flag)
    {
        var stem = Path.GetFileName(name)[..^".test.byn".Length];
        var work = Work($"test/{stem}{flag}.byn");
        Directory.CreateDirectory(Path.Combine(work, stem));
        File.Copy(Path_(name), Path.Combine(work, stem, Path.GetFileName(name)));
        AssertTestAsCSharp(work, flag.Length == 0 ? ["test", stem] : ["test", flag, stem]);
    }

    private static (int Code, string Out) Git(string dir, params string[] args) =>
        Scaffold.Git(Toolchain.FindOnPath("git")!, dir, ["-c", "core.hooksPath=" + Path.Combine(dir, ".no-hooks"), "-c", "user.name=test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", .. args]);

    /// <summary>
    /// 017 T11 (L028): the project rows of <c>CliEnvironmentTests</c> (<c>TestChanged*</c>, <c>TestOnly*</c>): an app whose entry module imports
    /// <c>money</c>, each with a test, committed to a fresh repository, then <c>--changed</c>, <c>--base</c> and <c>--only</c> as those tests run them.
    /// </summary>
    [Fact]
    public void TestChangedAndOnlyAsCSharpCli()
    {
        if (Toolchain.FindOnPath("git") is null) return;
        var work = Work("test/changed");
        var app = Path.Combine(work, "tally");
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", app, "--vcs", "none"], new StringWriter(), new StringWriter()));
        Directory.CreateDirectory(Path.Combine(app, "src", "money"));
        File.WriteAllText(Path.Combine(app, "src", "money", "money.byn"), "public i64 cents(i64 units) {\n    return units * 100\n}\n\ntest \"cents\" {\n    assert(cents(2) == 200)\n}\n");
        File.WriteAllText(Path.Combine(app, "src", "app", "main.byn"), "import money\n\nstring greeting() {\n    return \"Hello, world!\"\n}\n\ntest \"in main\" {\n    assert(money.cents(1) == 100)\n}\n\nprint(greeting())\n");
        Assert.Equal(0, Git(app, "init", "--quiet", "-b", "work").Code);
        Assert.Equal(0, Git(app, "add", "-A").Code);
        Assert.Equal(0, Git(app, "commit", "--quiet", "-m", "start").Code);

        AssertTestAsCSharp(work, ["test", "-v", "tally"]);
        AssertTestAsCSharp(work, ["test", "tally", "--changed"]);
        AssertTestAsCSharp(work, ["test", "tally", "--base", "no-such-ref"]);
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--only", "cent"]);
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--only", " "]);
        AssertTestAsCSharp(work, ["test", "tally", "--only", "nothing", "--only", "else"]);
        AssertTestAsCSharp(work, ["test", "tally", "--only", "nothing", "--changed"]);
        File.AppendAllText(Path.Combine(app, "src", "money", "money.byn"), "\n");
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--changed"]);
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--changed", "--only", "cents", "--only", "main"]);
        File.WriteAllText(Path.Combine(app, "tests", "extra.test.byn"), "test \"extra\" {\n    assert(false)\n}\n");
        AssertTestAsCSharp(work, ["test", "tally", "--changed", "--json"]);
        AssertTestAsCSharp(work, ["test", "tally", "--changed"]);
        Assert.Equal(0, Git(app, "add", "-A").Code);
        Assert.Equal(0, Git(app, "commit", "--quiet", "-m", "more").Code);
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--base", "HEAD~1"]);

        var loose = Path.Combine(work, "loose");
        Directory.CreateDirectory(loose);
        File.WriteAllText(Path.Combine(loose, "main.byn"), "void main() {\n}\n\ntest \"t\" {\n    assert(true)\n}\n");
        AssertTestAsCSharp(work, ["test", "loose", "--changed"], [("GIT_CEILING_DIRECTORIES", work)]);
        AssertTestAsCSharp(work, ["test", Path.Combine("loose", "main.byn"), "--changed"], [("GIT_CEILING_DIRECTORIES", work)]);

        File.WriteAllText(Path.Combine(app, "notes.txt"), "not a module\n");
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--changed"]);
        File.AppendAllText(Path.Combine(app, "package.byn"), "\n");
        AssertTestAsCSharp(work, ["test", "-v", "tally", "--changed"]);
        var noGit = Path.Combine(work, "no-git");
        Directory.CreateDirectory(noGit);
        AssertTestAsCSharp(work, ["test", "tally", "--changed"], [("PATH", noGit)]);
    }

    /// <summary>017 T11 (L028): <c>CliEnvironmentTests.ATestThatRunsTooLongIsReportedAsTimedOut</c>, the text C# prints at CliApp.cs:723.</summary>
    [Fact]
    public void TestTimeoutAsCSharpCli()
    {
        var work = Work("test/timeout");
        File.WriteAllText(Path.Combine(work, "main.byn"), "void main() {\n}\n\ntest \"loops\" {\n    while true {\n    }\n}\n");
        AssertTestAsCSharp(work, ["test", "main.byn"], [("BAYAN_TEST_TIMEOUT_MS", "300")]);
    }

    /// <summary>
    /// 017 T11 (L028): each status of CliApp.cs:715 (<c>pass</c>, <c>pending</c> from <c>todo</c>, <c>panic</c> from a failed assert, <c>fail</c>
    /// from an error a test lets through <c>try</c>, exit 1), which the <c>run/*.test.byn</c> rows never reach for <c>fail</c> and <c>pending</c>.
    /// </summary>
    [Theory]
    [InlineData("")]
    [InlineData("-v")]
    [InlineData("--json")]
    public void TestStatusesAsCSharpCli(string flag)
    {
        var work = Work($"test/statuses{flag}");
        var app = Path.Combine(work, "tally");
        Directory.CreateDirectory(app);
        File.WriteAllText(Path.Combine(app, "main.byn"), "void main() {\n    print(\"hi\")\n}\n");
        File.WriteAllText(Path.Combine(app, "main.test.byn"), "union error E {\n    /// Below zero.\n    bad\n}\n\ni64 check(i64 n) fails E {\n    fail .bad if n < 0\n    return n\n}\n\n"
            + "test \"adds\" {\n    assert(1 + 1 == 2)\n}\n\ntest \"later\" {\n    todo(\"split by weight\")\n}\n\ntest \"is false\" {\n    assert(false)\n}\n\n"
            + "test \"throws\" {\n    let n = try check(-1)\n    assert(n == 0)\n}\n");
        AssertTestAsCSharp(work, flag.Length == 0 ? ["test", "tally"] : ["test", flag, "tally"]);
    }

    /// <summary>
    /// 017 T11 (L028): the failure details of CliApp.cs:994 <c>FailureDetail</c> (a <c>\r</c> line end, more than three <c>  at </c> lines, a
    /// <c>panic: assert </c> message with an unindented line after it), a passing test's output under <c>-v</c>, more than three failures (no
    /// rerun line), an output over BoundedCapture's 128 KiB, and a name with each JSON escape of TestReport.cs.
    /// </summary>
    [Theory]
    [InlineData("")]
    [InlineData("-v")]
    [InlineData("-v --json")]
    public void TestFailuresAsCSharpCli(string flags)
    {
        var work = Work($"test/failures{flags.Replace(" ", "").Replace("-", "_")}");
        var app = Path.Combine(work, "fails");
        Directory.CreateDirectory(app);
        File.WriteAllText(Path.Combine(app, "main.byn"), "void main() {\n}\n\n"
            + "test \"out\" {\n    print(\"one\\r\")\n    print(\"two\")\n}\n\n"
            + "test \"cr\" {\n    print(\"cr\\r\")\n    let x = 1\n    assert(x == 2)\n}\n\n"
            + "test \"frames\" {\n    for i in 0..4 {\n        print($\"  at f{i}\")\n    }\n    panic(\"deep\")\n}\n\n"
            + "test \"big\" {\n    for i in 0..3000 {\n        print(\"0123456789012345678901234567890123456789012345678901234567890123456789\")\n    }\n    panic(\"big\")\n}\n\n"
            + "test \"plain\" {\n    panic(\"assert this\\nnext\")\n}\n\n"
            + "test \"esc \\\\ \\u{8}\\t\\u{c}\\r\\u{7f}\\u{85}\\u{2028}\\u{2029}\\u{1F600}\\\"\" {\n}\n");
        AssertTestAsCSharp(work, ["test", .. flags.Split(' ', StringSplitOptions.RemoveEmptyEntries), "fails"]);
    }

    /// <summary>
    /// 017 T11 (L028): <c>--coverage</c> and <c>--mode debug</c> (CliApp.cs:812 <c>WriteCoverage</c>, QualityReport.cs:109 <c>Coverage</c>, its
    /// listing and summary, Gates.cs:15 <c>Coverage</c>) on an app with a missed line, branch and error path, whole and partial (<c>--only</c>),
    /// then with a test past <c>BAYAN_TEST_TIMEOUT_MS</c> (unknown counters); <c>test</c> with no path inside the project; a build with no C
    /// compiler on <c>PATH</c>.
    /// </summary>
    [Fact]
    public void TestCoverageAsCSharpCli()
    {
        var work = Work("test/coverage");
        var app = Path.Combine(work, "cov");
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", app, "--vcs", "none"], new StringWriter(), new StringWriter()));
        File.Delete(Path.Combine(app, "tests", "app.test.byn"));
        var main = Path.Combine(app, "src", "app", "main.byn");
        File.WriteAllText(main, "import std.json\n\nunion error DigitError {\n    empty\n    bad\n}\n\n"
            + "i64 digit(string s) fails DigitError {\n    fail .empty if s.length == 0\n    fail .empty if s == \" \"\n    fail .bad if s == \"x\"\n    return s.length\n}\n\n"
            + "i64 sign(i64 n) {\n    if n < 0 {\n        return -1\n    }\n    return 1\n}\n\n"
            + "i64 unused(i64 n) {\n    if n > 0 { return 1 }\n    return 0\n}\n\n"
            + "test \"digit\" {\n    let d = try digit(\"ab\")\n    assert(d == 2)\n    let e = digit(\"\") catch -1\n    assert(e == -1)\n}\n\n"
            + "test \"sign\" {\n    assert(sign(3) == 1)\n}\n\n"
            + "test \"parse\" {\n    let p = json.Json.parse(\"1\") catch { return }\n}\n\n"
            + "print($\"{sign(1)}\")\n\ntest \"tail\" {\n    assert(sign(2) == 1)\n}");
        AssertTestAsCSharp(work, ["test", "--coverage", "cov"]);
        AssertTestAsCSharp(work, ["test", "--coverage", "--json", "cov"]);
        AssertTestAsCSharp(work, ["test", "--coverage", "--only", "sign", "cov"]);
        AssertTestAsCSharp(work, ["test", "--mode", "debug", "cov"]);
        AssertTestAsCSharp(work, ["test", "--mode", "debug", "--only", "sign", "cov"]);
        AssertTestAsCSharp(app, ["test"]);
        var noCc = Path.Combine(work, "no-cc");
        Directory.CreateDirectory(noCc);
        AssertTestAsCSharp(work, ["test", "cov"], [("PATH", noCc), ("BAYAN_CACHE", Path.Combine(work, "cc-cache"))]);
        AssertTestAsCSharp(work, ["test", "--json", "cov"], [("PATH", noCc), ("BAYAN_CACHE", Path.Combine(work, "cc-cache"))]);
        AssertTestAsCSharp(work, ["test", "--diagnostics", "json", "cov"], [("PATH", noCc), ("BAYAN_CACHE", Path.Combine(work, "cc-cache"))]);
        File.AppendAllText(main, "\n\ntest \"loops\" {\n    while true {\n    }\n}\n");
        AssertTestAsCSharp(work, ["test", "--coverage", "cov"], [("BAYAN_TEST_TIMEOUT_MS", "5000")]);
        AssertTestAsCSharp(work, ["test", "--mode", "debug", "cov"], [("BAYAN_TEST_TIMEOUT_MS", "5000")]);
    }

    /// <summary>
    /// 017 T11 (L028): Gates.cs:51 <c>Fmt</c> with one and two leading zeros in the thousandths (lines 10/111, 9.009%; branches 2/22, 9.091%)
    /// and an empty tally (error paths 0/0), in the <c>--coverage</c> summary and the <c>--mode debug</c> line.
    /// </summary>
    [Fact]
    public void TestPercentagesAsCSharpCli()
    {
        var work = Work("test/percentages");
        var app = Path.Combine(work, "fmt");
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", app, "--vcs", "none"], new StringWriter(), new StringWriter()));
        File.Delete(Path.Combine(app, "tests", "app.test.byn"));
        File.WriteAllText(Path.Combine(app, "src", "app", "main.byn"), "void main() {\n}\n\ni64 hit(i64 k) {\n    var n = k\n    if n > 0 { n += 1 }\n"
            + string.Concat(Enumerable.Repeat("    n += 1\n", 7)) + "    return n\n}\n\ni64 miss(i64 k) {\n    var n = k\n"
            + string.Concat(Enumerable.Repeat("    if n > 0 { n += 1 }\n", 10)) + string.Concat(Enumerable.Repeat("    n += 1\n", 89))
            + "    return n\n}\n\ntest \"hit\" {\n    assert(hit(1) + hit(-1) > 0)\n}\n");
        AssertTestAsCSharp(work, ["test", "--coverage", "fmt"]);
        AssertTestAsCSharp(work, ["test", "--mode", "debug", "fmt"]);
    }

    /// <summary>The argument lists of <see cref="TestArgumentsAsCSharpCli"/>: each flag of CliApp.cs:610 (<c>ParseBuild</c> for <c>test</c>) and its errors.</summary>
    public static TheoryData<string[]> TestArguments() => new()
    {
        new[] { "test", "tally", "--", "x" },
        new[] { "test", "--mode", "safe", "tally" },
        new[] { "test", "--mode", "fast", "tally" },
        new[] { "test", "--mode", "bad", "tally" },
        new[] { "test", "--diagnostics", "json", "tally" },
        new[] { "test", "--diagnostics", "text", "tally" },
        new[] { "test", "--diagnostics", "xml", "tally" },
        new[] { "test", "-o", "out", "tally" },
        new[] { "test", "--emit-c", "tally" },
        new[] { "test", "--target", "host", "tally" },
        new[] { "test", "--target", "nope", "tally" },
        new[] { "test", "--all", "tally" },
        new[] { "test", "--mutate", "--coverage", "tally" },
        new[] { "test", "--mutate", "--json", "tally" },
        new[] { "test", "--run", "x", "tally" },
        new[] { "test", "--package", "tally", "tally" },
        new[] { "test", "tally", "extra" },
        new[] { "test", "--bogus" },
        new[] { "test" },
        new[] { "test", "missing" },
        new[] { "test", "--json", "-v", "tally" },
        new[] { "test", "--coverage", "tally" },
        new[] { "test", "--coverage", "proj" },
        new[] { "test", "--coverage", "-v", "proj" },
        new[] { "test", "--json", "proj" },
        new[] { "test", "--mode", "safe", "proj" },
        new[] { "test", "--verbose", "tally" },
        new[] { "test", "-v", "lib" },
        new[] { "test", "--mode", "debug", "proj" },
        new[] { "test", "--mode", "debug", "--json", "proj" },
        new[] { "test", "tally", "--mode" },
        new[] { "test", "tally", "--diagnostics" },
        new[] { "test", "tally", "--base" },
        new[] { "test", "tally", "--run" },
        new[] { "test", "tally", "--package" },
        new[] { "features" },
        new[] { "dist" },
    };

    /// <summary>
    /// 017 T11 (L028): <c>test</c> with each of its flags, against the C# CLI, on <c>tally</c> (the <c>test-control-chars</c> tests of
    /// <c>StyleTests</c>, whose names exercise the JSON escapes) and <c>proj</c> (a fresh <c>bayan new</c> app, so <c>out/test/</c> is written).
    /// </summary>
    [Theory]
    [MemberData(nameof(TestArguments))]
    public void TestArgumentsAsCSharpCli(string[] args)
    {
        var work = Work($"test/args-{string.Join('_', args).Replace("-", "").Replace(".", "")}");
        var tally = Path.Combine(work, "tally");
        Directory.CreateDirectory(tally);
        File.WriteAllText(Path.Combine(tally, "main.byn"), "void main() {\n    print(\"hi\")\n}\n");
        File.WriteAllText(Path.Combine(tally, "main.test.byn"), "test \"ok\\u{1b}]0;PWNED\\u{7}\" {\n    assert(true)\n}\n\ntest \"later\\u{1b}[2J\" {\n    todo(\"soon\")\n}\n\n"
            + "test \"y\\u{1b}]0;PWNED\\u{7}\\u{1b}[2J\" {\n    panic(\"boom\\u{1b}[2J\\u{9b}31m\")\n}\n");
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", Path.Combine(work, "proj"), "--vcs", "none"], new StringWriter(), new StringWriter()));
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", Path.Combine(work, "lib"), "--lib", "--vcs", "none"], new StringWriter(), new StringWriter()));
        AssertTestAsCSharp(work, args);
    }

    /// <summary>BAYAN_UPDATE=1 must not make a comparison write its expected file (R10).</summary>
    [Fact]
    public void ComparisonsNeverWriteGoldens()
    {
        var name = "lex/bad-chars.byn";
        var golden = Path.ChangeExtension(Path_(name), ".tokens");
        var before = File.ReadAllBytes(golden);
        var saved = Environment.GetEnvironmentVariable("BAYAN_UPDATE");
        Environment.SetEnvironmentVariable("BAYAN_UPDATE", "1");
        try
        {
            Assert.True(Golden.UpdateMode);
            Assert.NotNull(Failure(name, ".tokens", "not the tokens\n"));
        }
        finally
        {
            Environment.SetEnvironmentVariable("BAYAN_UPDATE", saved);
        }
        Assert.Equal(before, File.ReadAllBytes(golden));
    }

    /// <summary>The usage, failure and <c>--diagnostics json</c> paths of <c>types</c> and <c>check</c>, against <c>CliApp.Run</c> in this process, through the harness build the coverage gate measures; exit code, stdout and stderr (the usage and failure rows write only to stderr).</summary>
    [Theory]
    [InlineData("types")]
    [InlineData("check")]
    [InlineData("types", "--package", "diag", "diag/ambiguous-variant.byn")]
    [InlineData("check", "--diagnostics", "json", "--package", "typed", "typed/constrained-by-argument.byn")]
    public void TypesAndCheckAsCliApp(params string[] args)
    {
        args = [.. args.Select(a => a is "diag" or "typed" || a.EndsWith(".byn") ? Path.Combine(Golden.CasesRoot, a) : a)];
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        var actual = SelfhostDriverHarness.Run(args);
        Assert.Equal(exit, actual.Exit);
        Assert.Equal(Mask(stdout.ToString().ReplaceLineEndings("\n")), Mask(actual.Out));
        Assert.Equal(Mask(stderr.ToString().ReplaceLineEndings("\n")), Mask(actual.Err));
    }

    [Theory]
    [MemberData(nameof(Run))]
    public void RunGolden(string name)
    {
        var input = Path_(name);
        var head = File.ReadLines(input).Take(2).ToList();
        if (OperatingSystem.IsWindows() ? head.Contains("// os: unix") : head.Contains("// os: windows")) return;
        var args = new List<string> { "run", "--package", Path.GetDirectoryName(input)! };
        if ((head.FirstOrDefault() ?? "") is { } first && first.StartsWith("// mode: ", StringComparison.Ordinal)) args.AddRange(["--mode", first["// mode: ".Length..].Trim()]);
        args.Add(input);
        var argsFile = Path.ChangeExtension(input, ".args");
        if (File.Exists(argsFile)) args.AddRange(["--", .. File.ReadAllLines(argsFile)]);
        var r = Stage2(Work(name), [.. args]);
        var pending = File.Exists(Path.ChangeExtension(input, ".pending"));
        var code = PanicExit.Portable(r.Exit);
        var failures = new[]
        {
            Failure(name, ".stdout", r.Stdout),
            Failure(name, ".exitcode", code == 0 ? "" : code + "\n", optional: true),
        }.Where(f => f is not null).ToList();
        // The stderr ruling (Q1052): the C# CLI's `run` on the same case.
        var expected = CSharp(Work(name), [.. args]);
        if (expected.Stderr != r.Stderr) failures.Add($"{name}: stderr differs from the C# CLI's\n--- C#\n{expected.Stderr}\n--- stage 2\n{r.Stderr}");
        if (pending)
        {
            if (failures.Count == 0) Assert.Fail($"{name} now matches its expected output; delete its .pending file");
            return;
        }
        if (failures.Count > 0) Assert.Fail(string.Join("\n", failures));
    }

    public static IEnumerable<object[]> DiagJson() =>
        from command in new[] { "check", "build" }
        from file in Directory.GetFiles(Path.Combine(Golden.CasesRoot, "diag-json"), "*.byn").Order(StringComparer.Ordinal)
        // listed skip (017 T7, Q1118): `build` of `fix-and-help`, which has only a warning, goes on to the native build, which this row does not run
        where !(command == "build" && Path.GetFileNameWithoutExtension(file) == "fix-and-help")
        select new object[] { command, Path.GetFileNameWithoutExtension(file) };

    /// <summary>
    /// 017 T7 (L028): every <c>diag-json/*.byn</c> through stage 2's <c>check --diagnostics json</c> and <c>build --diagnostics json</c>, run in the
    /// case's directory with `--package` (the file alone, as <c>DiagJsonTests</c> compiles it), against its <c>.jsonl</c> with the directory taken off the file name; <c>build</c> stops at the errors, before a toolchain.
    /// </summary>
    [Theory]
    [MemberData(nameof(DiagJson))]
    public void DiagJsonGolden(string command, string name)
    {
        var dir = Path.Combine(Golden.CasesRoot, "diag-json");
        var failing = File.ReadAllText(Path.Combine(dir, name + ".jsonl")).Contains("\"severity\":\"error\"", StringComparison.Ordinal);
        var r = Stage2(dir, command, "--package", dir, "--diagnostics", "json", name + ".byn");
        Assert.Equal(failing ? CliApp.ExitFailure : CliApp.ExitOk, r.Exit);
        Assert.Equal("", r.Stdout);
        if (Failure("diag-json/" + name + ".byn", ".jsonl", r.Stderr.Replace((dir + Path.DirectorySeparatorChar).Replace("\\", "\\\\", StringComparison.Ordinal), "")) is { } f) Assert.Fail(f);
    }
}
