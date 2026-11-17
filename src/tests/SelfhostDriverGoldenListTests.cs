namespace Bayan.Tests;

/// <summary>
/// 019 T1: <c>bayan test --list-cases tests/cases</c> of the stage-2 driver lists every case once as <c>&lt;kind&gt;/&lt;case&gt;</c>, and
/// the count per kind equals what the xUnit classes see: <see cref="Golden.Cases"/> for the <c>.byn</c> kinds (a subdirectory case once), the
/// <c>Shapes</c> of <see cref="StyleTests"/> for <c>style</c>, and the named files of <c>new</c>, <c>out</c>, <c>emit</c> and <c>quality</c>.
/// </summary>
public sealed class SelfhostDriverGoldenListTests
{
    private static readonly string[] BynKinds = ["diag", "diag-json", "lex", "manifest", "parse", "run", "typed"];

    private static readonly (string Kind, string[] Files)[] FileKinds =
    [
        ("emit", ["run-c.sha256"]),
        ("new", ["app.tree", "lib.tree", "script.tree"]),
        ("out", ["dist.tree", "out.tree", "results-fail.json"]),
        ("quality", ["mutation-report.json"]),
    ];

    /// <summary>The cases the xUnit classes read, as <c>kind/case</c>, sorted ordinally.</summary>
    private static List<string> Expected()
    {
        var names = new List<string>();
        foreach (var kind in BynKinds)
            foreach (string file in Golden.Cases(kind))
            {
                var rel = file[..^".byn".Length];
                names.Add(Path.GetFileName(file) == "main.byn" ? rel[..^"/main".Length] : rel);
            }
        foreach (var shape in StyleTests.Shapes) names.Add("style/" + shape);
        foreach (var (kind, files) in FileKinds)
            foreach (var file in files) names.Add(kind + "/" + Path.GetFileNameWithoutExtension(file));
        names.Sort(StringComparer.Ordinal);
        return names;
    }

    [Fact]
    public void TheDriverListsEveryCaseTheXunitClassesRead()
    {
        var (exit, stdout, stderr) = SelfhostDriverHarness.Run("test", "--list-cases", Golden.CasesRoot);
        Assert.True(exit == 0, stderr);
        var listed = stdout.Split('\n', StringSplitOptions.RemoveEmptyEntries).ToList();
        Assert.Equal(listed.Count, listed.Distinct().Count());
        var expected = Expected();
        var counts = string.Join(", ", expected.GroupBy(n => n[..n.IndexOf('/')]).Select(g => $"{g.Key} {g.Count()}"));
        Assert.True(expected.SequenceEqual(listed.Order(StringComparer.Ordinal), StringComparer.Ordinal),
            $"expected {expected.Count} ({counts}), listed {listed.Count}\nmissing: {string.Join(" ", expected.Except(listed).Take(10))}\nextra: {string.Join(" ", listed.Except(expected).Take(10))}");
        Assert.Equal(expected, listed.Order(StringComparer.Ordinal).ToList());
    }

    [Fact]
    public void ANonDirectoryIsAUsageFailure()
    {
        var (exit, _, stderr) = SelfhostDriverHarness.Run("test", "--list-cases", Path.Combine(Golden.CasesRoot, "no-such-dir"));
        Assert.Equal(1, exit);
        Assert.Contains("not found", stderr);
    }
}
