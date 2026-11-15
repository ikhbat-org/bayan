using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Packages;

namespace Bayan.Tests;

/// <summary>
/// <c>tests/cases/manifest/*.byn</c> → <c>*.diag</c>: the manifest's diagnostics, or the fields
/// it read when there are none.
/// </summary>
public sealed class ManifestTests
{
    public static TheoryData<string> Cases => Golden.Cases("manifest");

    [Theory]
    [MemberData(nameof(Cases))]
    public void ManifestGolden(string name) =>
        Golden.Check(name, ".diag", path =>
        {
            var m = Manifest.Parse(Golden.Load(path));
            if (m.Diagnostics.Count > 0) return DiagnosticRenderer.RenderAll(m.Diagnostics);
            return $"name {m.Name}\nversion {m.Version}\nedition {m.Edition}\nkind {m.Kind}\n"
                + $"targets {string.Join(" ", m.DistTargets)}\nmode {m.DistMode}\n"
                + $"booleans {m.Booleans}\nprimitives {m.Primitives}\n";
        });

    [Theory]
    [InlineData("tally", true)]
    [InlineData("my-app2", true)]
    [InlineData("My-app", false)]
    [InlineData("my--app", false)]
    [InlineData("my-app-", false)]
    [InlineData("2app", false)]
    [InlineData("my_app", false)]
    public void KebabNames(string name, bool valid) => Assert.Equal(valid, Manifest.IsKebabName(name));

    [Theory]
    [InlineData("0.1.0", true)]
    [InlineData("10.20.30-rc.1", true)]
    [InlineData("1.0", false)]
    [InlineData("01.0.0", false)]
    [InlineData("1.0.0-", false)]
    [InlineData("1.0.0-rc..1", false)]
    [InlineData("1.0.0-a/b", false)]
    [InlineData("1.0.0-a\\b", false)]
    [InlineData("1.0.0-x-y.2", true)]
    [InlineData("1.0.0-rc.1+build.5", true)]
    [InlineData("1.0.0+", false)]
    [InlineData("1.0.0+a/b", false)]
    [InlineData("123456789012345678.0.0", true)]
    public void SemanticVersions(string version, bool valid) => Assert.Equal(valid, Manifest.IsSemanticVersion(version));

    /// <summary>A version names <c>dist/&lt;version&gt;/</c>, so it can't hold a path or overflow a <c>long</c>.</summary>
    [Theory]
    [InlineData("1.0.0-x/../..", false)]
    [InlineData("99999999999999999999.0.0", false)]
    [InlineData("1.0.0-rc.1", true)]
    public void ManifestVersions(string version, bool valid)
    {
        var text = $"Package {{ name: \"local/tally\", version: \"{version}\", edition: 2027, kind: .app }}";
        var m = Manifest.Parse(Bayan.Syntax.Text.SourceText.FromString("package.byn", text));
        if (valid)
        {
            Assert.Empty(m.Diagnostics);
            Assert.Equal(version, m.Version);
        }
        else Assert.Contains(m.Diagnostics, d => d.Message.Contains("`version` must be a semantic version string", StringComparison.Ordinal));
    }

    [Theory]
    [InlineData("0.2.0", "0.10.0", -1)]
    [InlineData("1.0.0", "1.0.0-rc.1", 1)]
    [InlineData("1.0.0-alpha", "1.0.0-beta", -1)]
    [InlineData("2.0.0", "2.0.0", 0)]
    [InlineData("1.0.0+build.5", "1.0.0", 0)]
    [InlineData("1.0.0-rc.1+x", "1.0.0", -1)]
    public void VersionOrder(string a, string b, int sign) => Assert.Equal(sign, Math.Sign(Manifest.CompareVersions(a, b)));

    private static Manifest ParseTests(string tests) =>
        Manifest.Parse(new Bayan.Syntax.Text.SourceText("package.byn",
            System.Text.Encoding.UTF8.GetBytes($"Package {{ name: \"local/t\", version: \"0.1.0\", test: Tests {{ {tests} }} }}")));

    [Fact]
    public void TestsFieldsDefaultWhenAbsent()
    {
        var m = ParseTests("nightly: [.fuzz]");
        Assert.Empty(m.Diagnostics);
        Assert.Null(m.MinLines);
        Assert.Null(m.MinBranches);
        Assert.Null(m.MinErrorPaths);
        Assert.Null(m.MinMutation);
        Assert.True(m.Summary);
    }

    [Fact]
    public void TestsFieldsParse()
    {
        var m = ParseTests("lines: 100, branches: 0, errorPaths: 90, mutation: 75, summary: false, diffCoverage: \"anything\", nightly: [.fuzz]");
        Assert.Empty(m.Diagnostics);
        Assert.Equal(100, m.MinLines);
        Assert.Equal(0, m.MinBranches);
        Assert.Equal(90, m.MinErrorPaths);
        Assert.Equal(75, m.MinMutation);
        Assert.False(m.Summary);
    }

    [Theory]
    [InlineData("lines")]
    [InlineData("branches")]
    [InlineData("errorPaths")]
    [InlineData("mutation")]
    public void PercentFieldsRejectWrongTypeAndRange(string field)
    {
        foreach (var bad in new[] { "\"80\"", "true", "101", ".x" })
        {
            var m = ParseTests($"{field}: {bad}");
            var d = Assert.Single(m.Diagnostics);
            Assert.Equal("BYN3102", d.Code);
        }
    }

    [Fact]
    public void SummaryRejectsNonBool()
    {
        var d = Assert.Single(ParseTests("summary: 1").Diagnostics);
        Assert.Equal("BYN3102", d.Code);
    }

    private static Manifest ParseStyle(string style) =>
        Manifest.Parse(new Bayan.Syntax.Text.SourceText("package.byn",
            System.Text.Encoding.UTF8.GetBytes($"Package {{ name: \"local/t\", version: \"0.1.0\", style: Style {{ {style} }} }}")));

    [Fact]
    public void StyleKnobsDefaultWhenAbsent()
    {
        var m = ParseStyle("booleans: .words");
        Assert.Empty(m.Diagnostics);
        Assert.Equal(4, m.Indent);
        Assert.Equal(120, m.Width);
        Assert.Equal(AlignStyle.Runs, m.Align);
        Assert.Equal(TrailingCommaStyle.Multiline, m.TrailingCommas);
        Assert.Equal(5, m.Lints.Count);
        Assert.Equal(LintSeverity.None, m.Lints["functions.length"]);
        foreach (var name in new[] { "guards.postfix", "lambdas.it", "nesting.depth", "conditions.named" })
            Assert.Equal(LintSeverity.Suggestion, m.Lints[name]);
        Assert.Equal(4, Manifest.Parse(new Bayan.Syntax.Text.SourceText("package.byn",
            System.Text.Encoding.UTF8.GetBytes("Package { name: \"local/t\", version: \"0.1.0\" }"))).Indent);
    }

    [Fact]
    public void StyleKnobsParse()
    {
        var m = ParseStyle("indent: 2, width: 80, align: .none, trailingCommas: .never, lints: [\"guards.postfix\": .warning, \"functions.length\": .error, \"lambdas.it\": .none, \"nesting.depth\": .suggestion]");
        Assert.Empty(m.Diagnostics);
        Assert.Equal(2, m.Indent);
        Assert.Equal(80, m.Width);
        Assert.Equal(AlignStyle.None, m.Align);
        Assert.Equal(TrailingCommaStyle.Never, m.TrailingCommas);
        Assert.Equal(LintSeverity.Warning, m.Lints["guards.postfix"]);
        Assert.Equal(LintSeverity.Error, m.Lints["functions.length"]);
        Assert.Equal(LintSeverity.None, m.Lints["lambdas.it"]);
        Assert.Equal(LintSeverity.Suggestion, m.Lints["nesting.depth"]);
        Assert.Equal(LintSeverity.Suggestion, m.Lints["conditions.named"]);
        var explicitRuns = ParseStyle("align: .runs, trailingCommas: .multiline, lints: []");
        Assert.Empty(explicitRuns.Diagnostics);
        Assert.Equal(AlignStyle.Runs, explicitRuns.Align);
        Assert.Equal(TrailingCommaStyle.Multiline, explicitRuns.TrailingCommas);
    }

    [Theory]
    [InlineData("braces: .sameLine", "`style.braces` must be removed: there is no brace knob, `{` always ends the line")]
    [InlineData("maxLine: 100", "`style.maxLine` must be removed: use `style.width`")]
    [InlineData("trailingCommas: true", "`style.trailingCommas` must be `.multiline` or `.never`, not `true` or `false`")]
    [InlineData("trailingCommas: .always", "`style.trailingCommas` must be `.multiline` or `.never`")]
    [InlineData("indent: 0", "`style.indent` must be a positive integer, e.g. `4`")]
    [InlineData("width: \"80\"", "`style.width` must be a positive integer, e.g. `120`")]
    [InlineData("align: .left", "`style.align` must be `.runs` or `.none`")]
    [InlineData("lints: [\"guards.prefix\": .warning]", "`style.lints` must be a known lint name: `guards.postfix`, `lambdas.it`, `nesting.depth`, `functions.length`, `conditions.named`")]
    [InlineData("lints: [\"lambdas.it\": .loud]", "`style.lints` must be `.none`, `.suggestion`, `.warning` or `.error` for `lambdas.it`")]
    [InlineData("lints: [\"lambdas.it\"]", "`style.lints` must be a map from a lint name to `.none`, `.suggestion`, `.warning` or `.error`, e.g. `[\"guards.postfix\": .warning]`")]
    public void StyleRejects(string style, string message)
    {
        var d = Assert.Single(ParseStyle(style).Diagnostics);
        Assert.Equal("BYN3102", d.Code);
        Assert.Equal(message, d.Message);
    }

    [Fact]
    public void NamesConvertBetweenKebabAndCamel()
    {
        Assert.Equal("macos-arm64", Manifest.KebabOf("macosArm64"));
        Assert.Equal("myLib", Manifest.CamelOf("my-lib"));
    }
}
