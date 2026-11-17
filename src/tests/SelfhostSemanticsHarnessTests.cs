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

    /// <summary>The export directory this class's tests write to: the class is dropped from the export, so its cases
    /// never land in <c>BAYAN_EXPORT_DIR</c>, while its assertions still run with an export active.</summary>
    private static readonly string OwnExport = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-harness");

    /// <summary>Runs <paramref name="body"/> with the export pointed at <paramref name="dir"/>.</summary>
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
    public void RunsAndSplitsSections() => ExportingTo(OwnExport, () =>
    {
        var s = SelfhostSemanticsHarness.RunSections(Main);
        Assert.Equal(["before"], s[""]);
        SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "a2"]);
        Assert.Empty(s["beta"]);
    });

    /// <summary>With an export directory the section is still compared, and its program and C# lines are written as a
    /// case; a derived comparison names its printed section and normal form, and a call with no program is listed.</summary>
    [Fact]
    public void ExportWritesTheCase()
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "export-sem-test");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        ExportingTo(dir, () =>
        {
            var s = SelfhostSemanticsHarness.RunSections(Main);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1", "a2"]);
            Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "alpha", ["again"], nameof(ExportWritesTheCase)));
            SelfhostSemanticsHarness.AssertSection(new() { ["sorted"] = ["a1", "a2"] }, "sorted", ["a1", "a2"], run: s, printed: "alpha", compare: "sorted");
            SelfhostSemanticsHarness.AssertSection(new() { ["none"] = ["x"] }, "none", ["x"], noExport: "no program");
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
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\tExportWritesTheCase\tnone\tno program\n", File.ReadAllText(Path.Combine(dir, "sem", "UNEXPORTED.tsv")));
        Assert.Equal($"{nameof(SelfhostSemanticsHarnessTests)}\t3\n", File.ReadAllText(Path.Combine(dir, "sem", "counts.tsv")));
    }

    [Fact]
    public void FirstDifferingLineFails() => ExportingTo(OwnExport, () =>
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\nl2\n");
        var e = Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "L2"]));
        Assert.Contains("line 2", e.Message);
    });

    [Fact]
    public void CountMismatchMissingAndEmptyFail() => ExportingTo(OwnExport, () =>
    {
        var s = SelfhostSemanticsHarness.Sections("== x\nl1\n== empty\n");
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "x", ["l1", "l2"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "missing", ["l1"]));
        Assert.ThrowsAny<Exception>(() => SelfhostSemanticsHarness.AssertSection(s, "empty", []));
    });

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
