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

    /// <summary>Under <c>BAYAN_EXPORT_DIR</c> the section is not compared: its program and C# lines are written as a case.</summary>
    [Fact]
    public void ExportWritesTheCase()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-test");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        var old = Environment.GetEnvironmentVariable("BAYAN_EXPORT_DIR");
        try
        {
            Environment.SetEnvironmentVariable("BAYAN_EXPORT_DIR", dir);
            var s = SelfhostSemanticsHarness.RunSections(Main);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "differs"]);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["again"]);
            SelfhostSemanticsHarness.WriteExportCounts();
        }
        finally
        {
            Environment.SetEnvironmentVariable("BAYAN_EXPORT_DIR", old);
        }
        var cases = Path.Combine(dir, "sem", nameof(SelfhostSemanticsHarnessTests));
        Assert.Equal(Main, File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha", "input.byn")));
        Assert.Equal("== alpha\na1\ndiffers\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha", "expected.sections")));
        Assert.False(File.Exists(Path.Combine(cases, "ExportWritesTheCase-alpha", "args")));
        Assert.Equal("== alpha\nagain\n", File.ReadAllText(Path.Combine(cases, "ExportWritesTheCase-alpha-2", "expected.sections")));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\t2\n", File.ReadAllText(Path.Combine(dir, "sem", "counts.tsv")));
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
