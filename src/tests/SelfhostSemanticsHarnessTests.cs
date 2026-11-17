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

    [Fact]
    public void RunsAndSplitsSections()
    {
        var s = SelfhostSemanticsHarness.RunSections(Main);
        Assert.Equal(["before"], s[""]);
        SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "a2"]);
        Assert.Empty(s["beta"]);
    }

    /// <summary>With an export directory the section is not compared: its program and C# lines are written as a case, a
    /// derived comparison names its printed section and normal form, and a call with no program is listed instead.</summary>
    [Fact]
    public void ExportWritesTheCase()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-test");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        var old = SelfhostSemanticsHarness.ExportOverride.Value;
        try
        {
            // An AsyncLocal, not the environment variable: tests running in parallel keep asserting.
            SelfhostSemanticsHarness.ExportOverride.Value = dir;
            var s = SelfhostSemanticsHarness.RunSections(Main);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "differs"]);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["again"]);
            SelfhostSemanticsHarness.AssertSection(new() { ["sorted"] = ["a1", "a2"] }, "sorted", ["a2", "a1"], run: s, printed: "alpha", compare: "sorted");
            SelfhostSemanticsHarness.AssertSection(new() { ["none"] = ["x"] }, "none", ["y"], noExport: "no program");
            SelfhostSemanticsHarness.WriteExportCounts();
        }
        finally
        {
            SelfhostSemanticsHarness.ExportOverride.Value = old;
        }
        var cases = Path.Combine(dir, "sem", nameof(SelfhostSemanticsHarnessTests));
        Assert.Equal(Main, File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha", "input.byn")));
        Assert.Equal("== alpha\na1\ndiffers\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha", "expected.sections")));
        Assert.False(File.Exists(Path.Combine(cases, "ExportWritesTheCase-alpha", "args")));
        Assert.False(File.Exists(Path.Combine(cases, "ExportWritesTheCase-alpha", "compare")));
        Assert.Equal("== alpha\nagain\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha-2", "expected.sections")));
        Assert.Equal(Main, File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-sorted", "input.byn")));
        Assert.Equal("== alpha\na2\na1\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-sorted", "expected.sections")));
        Assert.Equal("sorted\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-sorted", "compare")));
        Assert.False(Directory.Exists(Path.Combine(cases, "ExportWritesTheCase-none")));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\tExportWritesTheCase\tnone\tno program\n", File.ReadAllText(Path.Combine(dir, "sem", "UNEXPORTED.tsv")));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\t3\n", File.ReadAllText(Path.Combine(dir, "sem", "counts.tsv")));
    }

    [Fact]
    public void FirstDifferingLineFails()
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\nl2\n");
        var e = Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "L2"]));
        Assert.Contains("line 2", e.Message);
    }

    [Fact]
    public void CountMismatchMissingAndEmptyFail()
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\n== empty\n");
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "l2"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "missing", ["l1"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "empty", []));
    }

    [Fact]
    public void RepeatedSectionFails() =>
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.Sections("== x\n== x\n"));

    [Fact]
    public void BuildErrorFailsWithTheComplaint()
    {
        var e = Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.Build("i32 main() => undefinedName"));
        Assert.Contains("BYN", e.Message);
    }
}
