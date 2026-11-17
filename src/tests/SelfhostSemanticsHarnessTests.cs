namespace Bayan.Tests;

public sealed class SelfhostSemanticsHarnessTests
{
    private const string Main = """
        i32 main() {
            print("before")
            print("== alpha")
            print("a1")
            print("a2")
            print("== beta")
            return 0
        }
        """;

    /// <summary>The class is dropped from the export: its tests run with the export cleared, so they assert as without
    /// <c>BAYAN_EXPORT_DIR</c> and write nothing into it.</summary>
    private const string NoExport = "";

    /// <summary>Runs <paramref name="body"/> with the export pointed at <paramref name="dir"/> (cleared when empty).</summary>
    private static void ExportingTo(string dir, Action body)
    {
        var old = SelfhostSemanticsHarness.ExportOverride.Value;
        try
        {
            // An AsyncLocal, not the environment variable: tests running in parallel keep their own setting.
            SelfhostSemanticsHarness.ExportOverride.Value = dir;
            body();
        }
        finally
        {
            SelfhostSemanticsHarness.ExportOverride.Value = old;
        }
    }

    [Fact]
    public void RunsAndSplitsSections() => ExportingTo(NoExport, () =>
    {
        var s = SelfhostSemanticsHarness.RunSections(Main);
        Assert.Equal(["before"], s[""]);
        SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "a2"]);
        Assert.Empty(s["beta"]);
    });

    /// <summary>With an export directory the section's program and C# lines are written as a case instead of compared;
    /// a derived comparison names its printed section and normal form.</summary>
    [Fact]
    public void ExportWritesTheCase()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-test");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        ExportingTo(dir, () =>
        {
            var s = SelfhostSemanticsHarness.RunSections(Main);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "a2"]);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["again"]);
            SelfhostSemanticsHarness.AssertSection(new() { ["sorted"] = ["a1", "a2"] }, "sorted", ["a1", "a2"], run: s, printed: "alpha", compare: "sorted");
            SelfhostSemanticsHarness.WriteExportCounts();
        });
        var cases = Path.Combine(dir, "sem", nameof(SelfhostSemanticsHarnessTests));
        Assert.Equal(Main, File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase", "input.byn")));
        Assert.Equal("alpha\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase", "section")));
        Assert.Equal("== alpha\na1\na2\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase", "expected.sections")));
        Assert.False(File.Exists(Path.Combine(cases, "ExportWritesTheCase", "args")));
        Assert.False(File.Exists(Path.Combine(cases, "ExportWritesTheCase", "compare")));
        Assert.Equal("== alpha\nagain\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-2", "expected.sections")));
        Assert.Equal(Main, File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-3", "input.byn")));
        Assert.Equal("sorted\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-3", "section")));
        Assert.Equal("== alpha\na1\na2\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-3", "expected.sections")));
        Assert.Equal("sorted\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-3", "compare")));
        Assert.False(Directory.Exists(Path.Combine(cases, "ExportWritesTheCase-4")));
        Assert.False(File.Exists(Path.Combine(dir, "sem", "UNEXPORTED.tsv")));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\t3\n", File.ReadAllText(Path.Combine(dir, "sem", "counts.tsv")));
    }

    /// <summary>With an export directory a call with a no-export reason, or for a section the program does not print,
    /// writes no case, lists one row each and does not assert, though its lines differ.</summary>
    [Fact]
    public void ExportListsWithoutAsserting()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-unexported");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        ExportingTo(dir, () =>
        {
            var s = SelfhostSemanticsHarness.RunSections(Main);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["other"], noExport: "no program");
            SelfhostSemanticsHarness.AssertSection(s, "gamma", ["g1"]);
        });
        Assert.False(Directory.Exists(Path.Combine(dir, "sem", nameof(SelfhostSemanticsHarnessTests))));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\tExportListsWithoutAsserting\talpha\tno program\n"
            + $"{nameof(SelfhostSemanticsHarnessTests)}\tExportListsWithoutAsserting\tgamma\tsection 'gamma' was not printed\n",
            File.ReadAllText(Path.Combine(dir, "sem", "UNEXPORTED.tsv")));
    }

    [Fact]
    public void FirstDifferingLineFails() => ExportingTo(NoExport, () =>
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\nl2\n");
        var e = Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "L2"]));
        Assert.Contains("line 2", e.Message);
    });

    [Fact]
    public void CountMismatchMissingAndEmptyFail() => ExportingTo(NoExport, () =>
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\n== empty\n");
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "l2"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "missing", ["l1"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "empty", []));
    });

    [Fact]
    public void RepeatedSectionFails() => ExportingTo(NoExport, () =>
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.Sections("== x\n== x\n")));

    [Fact]
    public void BuildErrorFailsWithTheComplaint() => ExportingTo(NoExport, () =>
    {
        var e = Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.Build("i32 main() => undefinedName"));
        Assert.Contains("BYN", e.Message);
    });
}
