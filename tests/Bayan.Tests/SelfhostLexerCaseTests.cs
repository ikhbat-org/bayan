using System.Text;
using System.Text.Json.Nodes;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;
using Xunit.Abstractions;

namespace Bayan.Tests;

/// <summary>
/// <c>lexer.firstIsUpper</c> / <c>lexer.firstIsLower</c> (Q1142), driven by a test <c>main</c>. The expected lines are what the
/// C# parser computes with <c>char.IsUpper(s[0])</c> / <c>char.IsLower(s[0])</c> on the same strings.
/// </summary>
public sealed class SelfhostLexerCaseTests(ITestOutputHelper output)
{
    private static readonly string[] Inputs =
    [
        "", "A", "Z", "a", "z", "Å", "Å", "Ω", "ω", "ǅ", "_", "7", "\U0001D400", "\U0001D41A", "Äx", "Δx",
    ];

    [Fact]
    public void FirstScalarCaseMatchesCSharpCharIsUpperAndIsLower()
    {
        var (exit, text) = RunCases(SelfhostSemanticsHarness.SnapshotDir, SelfhostSemanticsHarness.CoverageDir);
        output.WriteLine(text);
        Assert.Equal(0, exit);
        var expected = string.Concat(Inputs.Select(s => $"{(s.Length > 0 && char.IsUpper(s[0]) ? "true" : "false")} {(s.Length > 0 && char.IsLower(s[0]) ? "true" : "false")}\n"));
        Assert.Equal(expected, text);
    }

    /// <summary>The test <c>main</c> built and run. Under <paramref name="snapshot"/> its build is listed in <c>manifest.json</c>
    /// and its run is recorded through <see cref="SelfhostLexerTests.RunIn"/>: a listed build without a recorded run fails
    /// mutant 0 of the lexer group's batch mutation run (<c>replay: no recorded run of …</c>).</summary>
    internal static (int Exit, string Out) RunCases(string? snapshot, string? coverage)
    {
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var selfhost = Path.Combine(Golden.RepoRoot, "selfhost");
        var program = new StringBuilder("import lexer\n\nvoid main() {\n");
        foreach (var s in Inputs)
            program.Append($"    print($\"{{lexer.firstIsUpper(\"{s}\".bytes)}} {{lexer.firstIsLower(\"{s}\".bytes)}}\")\n");
        program.Append("}\n");
        var c = Compilation.Create([SourceText.FromString(Path.Combine(selfhost, "t-case.byn"), program.ToString())], packageRoot: selfhost);
        if (c.Diagnostics.HasErrors) Assert.Fail($"did not build:\n{DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true)}");
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal), snapshot, coverage, Environment.GetEnvironmentVariable("BAYAN_COVERAGE_FILES"));
        if (!build.Succeeded) Assert.Fail($"did not build:\n{build.Errors}");
        var (exit, text, _) = SelfhostLexerTests.RunIn(snapshot, build.ExecutablePath!, []);
        return (exit, text);
    }
}

/// <summary>Not in the <c>SelfhostLexer</c> filter: <see cref="SelfhostLexerCaseTests"/> under a snapshot directory.</summary>
public sealed class LexerCaseSnapshotRecordingTests
{
    /// <summary>Spec 013 R14: every build the case test lists in <c>manifest.json</c> has a run in <c>runs.jsonl</c>, so the
    /// lexer group's mutant 0 replays. Break-test: run the build through a bare <c>Process.Start</c> again.</summary>
    [Fact]
    [Trait("Snapshot", "skip")]
    public void EveryListedBuildHasARecordedRun()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "selfhost-lexer-case-snap");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Assert.Equal(0, SelfhostLexerCaseTests.RunCases(dir, null).Exit);
        var builds = JsonNode.Parse(File.ReadAllText(Path.Combine(dir, "manifest.json")))!["builds"]!.AsArray().Select(b => (string)b!["binary"]!).ToList();
        Assert.NotEmpty(builds);
        var runs = File.Exists(Path.Combine(dir, "runs.jsonl"))
            ? File.ReadAllLines(Path.Combine(dir, "runs.jsonl")).Select(l => (string)JsonNode.Parse(l)!["program"]!).ToHashSet(StringComparer.Ordinal)
            : [];
        Assert.All(builds, b => Assert.Contains(b, runs));
    }
}
