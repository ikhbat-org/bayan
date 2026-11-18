using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using Bayan.Cli;

namespace Bayan.Tests;

// Spec 019 T15c export counts (BAYAN_EXPORT_DIR=tmp/export-cli, cli/counts.tsv) against tests/inventory-019.tsv, class: tests / cases.
// - SelfhostDriverT2Tests: 761 / 774. ACleanProgramAsCliApp writes 4 cases and ArgumentErrorsAsCliApp 13 (one per oracle call, +15);
//   MaskKeepsVersionLikeLinesOnOtherStreams and RefusesWhatItDoesNotPort compare nothing with C# and write none (-2).
// - SelfhostDriverT3Tests: 62 / 70. TargetHostFromIsTheTableName writes a probe case per table name and per no-host pair (11, +10);
//   AnUnwritableScratchDirectory... and FindOnPathOnWindows... are no-oracle and write none (-2).
// - SelfhostDriverT5Tests: 16 / 764. EmitC and RunAs write a case per run/ input (336 each); the others one per C# run;
//   TheCsBuildsTheDriver compares two C# builds of the driver and writes none; EmitsAPackageAsCliApp (2 calls) and one
//   FailuresAsCliApp call take the repo's own src/ as input and are rows of cli/UNEXPORTED.tsv.
// - SelfhostDriverMutateTests: 46 / 58. MutateExternalAsCliAppDoes writes 7 and TestMutateAsCliAppDoes 8 (+13);
//   RunsInTheSerialToolchainCollection compares nothing with C# and writes none (-1).
// - SelfhostDriverStyleLintsTests: 13 / 12. CoversTheFolderCases is a guard over the folder list and writes none.
// - SelfhostDriverApiTests: 2 / 1. EveryIndexedEntryPointExists checks the index against the source and writes none.
// - SelfhostDriverRuntimeTests: 2 / 0. Both compare runtime.byn's constants with runtime/ files: no C# CLI run, no case.
// - SelfhostDriverT8Tests (SelfhostDriverInventoryTests.cs): 5 / 0. They check C#-emitted C against the runtime inventory doc;
//   nothing is compared with the self-hosted side, so there is no case.

/// <summary>
/// 012 T2: <c>lex</c>, <c>parse --ast</c>, <c>types</c> and <c>check</c> of the driver against <see cref="CliApp.Run"/> (R2).
/// The expected exit code and streams come from the C# run in-process; only the elapsed seconds of <c>check</c>'s summary are masked.
/// No style flag is passed: the dumps and diagnostics render plain in the driver (no-style: Q947).
/// </summary>
public sealed class SelfhostDriverT2Tests
{
    private static string Mask(string text) => Regex.Replace(text, @" in \d+\.\d\ds", " in masked");

    /// <summary>The version line's commit part differs by design (spec Q3); only stdout of `version` and `--version` has one.</summary>
    private static string MaskVersion(string text) => Regex.Replace(text, @"^(bayan \S+) \(.*\)$", "$1 (masked)", RegexOptions.Multiline);

    /// <summary><c>CliApp.Run</c> in-process; under the export it records the run in <paramref name="form"/> (spec 019 R10).</summary>
    private static (int Exit, string Out, string Err) Oracle(string[] args, SelfhostDriverT1Tests.ExportForm? form = null, [CallerMemberName] string test = "")
    {
        var staged = SelfhostExport.Dir is null ? null : SelfhostDriverT1Tests.StageInputs(args.Where(SelfhostDriverT1Tests.IsPath));
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        var result = (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
        if (staged is not null) SelfhostDriverT1Tests.Record(args, result, staged, form, nameof(SelfhostDriverT2Tests), test, "");
        return result;
    }

    private static void AssertSameAsCs(string[] args, [CallerMemberName] string test = "")
    {
        Func<string, string> out_ = args is ["version"] or ["--version"] ? t => MaskVersion(Mask(t)) : Mask;
        var expected = Oracle(args, new(args is ["version"] or ["--version"] ? "version-seconds-masked" : "seconds-masked", Out: out_, Err: Mask), test);
        if (SelfhostExport.Dir is not null) return;
        var actual = SelfhostDriverHarness.Run(args);
        var label = string.Join(' ', args);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", out_(expected.Out), out_(actual.Out));
        SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", Mask(expected.Err), Mask(actual.Err));
    }

    private static string Case(string name) => Path.Combine(Golden.CasesRoot, name);

    /// <summary>
    /// `types` and `check` compile the whole directory of a file as one entry module, so a case among its siblings in
    /// `tests/cases/<kind>/` would fail on their top-level statements. The case is copied alone (a multi-module case with
    /// its directory) under `tmp/t2/`, and both sides run on the copy.
    /// </summary>
    private static string Isolated(string name)
    {
        var source = Case(name);
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t2", name.Replace(".byn", ""));
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var from = name.Split('/').Length > 2 ? Path.GetDirectoryName(source) : null;
        if (from is null)
        {
            File.Copy(source, Path.Combine(dir, Path.GetFileName(source)));
            return Path.Combine(dir, Path.GetFileName(source));
        }
        foreach (var file in Directory.EnumerateFiles(from, "*", SearchOption.AllDirectories))
        {
            var target = Path.Combine(dir, Path.GetRelativePath(from, file));
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            File.Copy(file, target);
        }
        return Path.Combine(dir, "main.byn");
    }

    public static TheoryData<string> LexCases => Golden.Cases("lex");
    public static TheoryData<string> ParseCases => Golden.Cases("parse");

    [Theory]
    [MemberData(nameof(LexCases))]
    public void LexAsCliApp(string name) => AssertSameAsCs(["lex", Case(name)]);

    [Theory]
    [MemberData(nameof(ParseCases))]
    public void ParseAstAsCliApp(string name) => AssertSameAsCs(["parse", "--ast", Case(name)]);

    public static TheoryData<string> TypedCases => Golden.Cases("typed");
    public static TheoryData<string> DiagCases => Golden.Cases("diag");

    [Theory]
    [MemberData(nameof(TypedCases))]
    public void TypesAsCliApp(string name) => AssertSameAsCs(["types", Isolated(name)]);

    /// <summary>`check` prints `checked <name> in <n.nn>s` on success; <see cref="Mask"/> replaces the seconds on both sides.</summary>
    [Theory]
    [MemberData(nameof(DiagCases))]
    public void CheckAsCliApp(string name) => AssertSameAsCs(["check", Isolated(name)]);

    [Fact]
    public void ACleanProgramAsCliApp()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t2", "clean");
        Directory.CreateDirectory(dir);
        var main = Path.Combine(dir, "main.byn");
        File.WriteAllText(main, "void main() {\n    print(\"hi\")\n}\n");
        AssertSameAsCs(["check", main]);
        AssertSameAsCs(["check", main, "--diagnostics", "json"]);
        AssertSameAsCs(["types", main]);
        AssertSameAsCs(["types", Isolated("diag/ambiguous-variant.byn")]);
    }

    /// <summary>`Mask` leaves a line that looks like a version line alone; only `MaskVersion` (for `version` stdout) rewrites it.</summary>
    [Fact]
    public void MaskKeepsVersionLikeLinesOnOtherStreams()
    {
        Assert.Equal("bayan 1 (x)\n", Mask("bayan 1 (x)\n"));
        Assert.Equal("bayan 1 (masked)\n", MaskVersion("bayan 1 (x)\n"));
    }

    /// <summary>A file named `-` in the working directory is parsed, not stdin (CliApp.cs:128, :1107); both sides see the test process's cwd.</summary>
    [Fact]
    public void ParsesAFileNamedDash()
    {
        var dash = Path.Combine(Directory.GetCurrentDirectory(), "-");
        File.Copy(Case("parse/assert.byn"), dash, overwrite: true);
        try
        {
            if (SelfhostExport.Dir is null) Assert.Equal(0, Oracle(["parse", "--ast", "-"]).Exit);
            AssertSameAsCs(["parse", "--ast", "-"]);
        }
        finally { File.Delete(dash); }
    }

    [Fact]
    public void ArgumentErrorsAsCliApp()
    {
        var file = Case("lex/bad-chars.byn");
        AssertSameAsCs(["lex"]);
        AssertSameAsCs(["lex", file, file]);
        AssertSameAsCs(["lex", Case("lex/missing.byn")]);
        AssertSameAsCs(["parse", "--ast"]);
        AssertSameAsCs(["parse", "--ast", Case("parse/missing.byn")]);
        AssertSameAsCs(["parse", "--ast", "-"]);
        AssertSameAsCs(["types"]);
        AssertSameAsCs(["types", Case("typed/missing.byn")]);
        AssertSameAsCs(["types", file, "--bogus"]);
        AssertSameAsCs(["check", Case("diag/missing.byn")]);
        AssertSameAsCs(["check", file, "--json"]);
        AssertSameAsCs(["check", file, "--diagnostics", "json"]);
        AssertSameAsCs(["check", file, "--all"]);
    }

    /// <summary>The cases of <c>run</c> that precede and surround the T2 commands (the dispatch the T2 stubs were replaced in).</summary>
    public static IEnumerable<object[]> Dispatch() => new[]
    {
        new string[] { },
        new[] { "version" },
        new[] { "--version" },
        new[] { "help" },
        new[] { "-h" },
        new[] { "--help" },
        new[] { "frobnicate" },
        new[] { "fmt" },
        new[] { "missing-script.byn" },
        new[] { "--color", "bad", "help" },
    }.Select(a => new object[] { a });

    [Theory]
    [MemberData(nameof(Dispatch))]
    public void DispatchAsCliApp(string[] args) => AssertSameAsCs(args);

    [Fact]
    public void LexReadsStandardInput()
    {
        var file = Case("lex/bad-chars.byn");
        var expected = Oracle(["lex", file], new("stdout"));
        if (SelfhostExport.Dir is not null) return;
        var (exit, stdout, _, _, _) = SelfhostLexerTests.RunOnStdin(SelfhostDriverHarness.Build(), ["lex", "-"], File.ReadAllBytes(file), 30_000);
        Assert.Equal(expected.Exit, exit);
        SelfhostEmitterHarness.AssertSame("stdout of `lex -`", expected.Out, System.Text.Encoding.UTF8.GetString(stdout).ReplaceLineEndings("\n"));
    }

    /// <summary>The export path of <see cref="Oracle"/> (spec 019 R10): a lex row writes its case, the input as <c>input.byn</c>, stdout and stderr masked.</summary>
    [Fact]
    public void OracleExportsARowAsACase()
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "export-test-driver-t2");
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        var old = SelfhostExport.Override.Value;
        (int Exit, string Out, string Err) expected;
        try
        {
            SelfhostExport.Override.Value = root;
            LexAsCliApp("lex/bad-chars.byn");
            SelfhostExport.Override.Value = "";
            expected = Oracle(["lex", Case("lex/bad-chars.byn")]);
        }
        finally { SelfhostExport.Override.Value = old; }
        var dir = Path.Combine(root, "cli", nameof(SelfhostDriverT2Tests), nameof(LexAsCliApp));
        Assert.Equal("lex\n<repo>/tests/cases/lex/bad-chars.byn\n", File.ReadAllText(Path.Combine(dir, "args")));
        Assert.Equal($"{expected.Exit}\n", File.ReadAllText(Path.Combine(dir, "expected.exitcode")));
        Assert.Equal(Mask(expected.Out), File.ReadAllText(Path.Combine(dir, "expected.stdout")));
        Assert.Equal(Mask(expected.Err), File.ReadAllText(Path.Combine(dir, "expected.stderr")));
        Assert.Equal("seconds-masked\n", File.ReadAllText(Path.Combine(dir, "compare")));
        Assert.Equal(File.ReadAllText(Case("lex/bad-chars.byn")), File.ReadAllText(Path.Combine(dir, "input.byn")));
        Assert.False(Directory.Exists(dir + "-2"));
    }

    [Fact]
    public void RefusesWhatItDoesNotPort()
    {
        var file = Case("lex/bad-chars.byn");
        foreach (var args in new[] { new[] { "lex", "--json", file }, new[] { "parse", file } })
        {
            var (exit, stdout, stderr) = SelfhostDriverHarness.Run(args);
            Assert.Equal(CliApp.ExitUsage, exit); // no-oracle: Q917, Q940 the C# runs these (lex --json, parse without --ast); the refusal text is R3's (Q4)
            Assert.Equal("", stdout);
            Assert.StartsWith("error: `", stderr);
        }
    }
}
