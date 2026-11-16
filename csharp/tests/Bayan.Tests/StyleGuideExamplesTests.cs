using System.Text;
using System.Text.RegularExpressions;
using Bayan.Cli;
using Bayan.Syntax.Parsing;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// Reads <c>docs/bayan-style.md</c> (spec 022 R1): each <c>###</c> heading has a <c>Do:</c> and a <c>Don't:</c> <c>bayan</c> block.
/// Under <c>## Style lints</c>, the Don't block reports the lint of the heading and the Do block none of the five; elsewhere the
/// layout engine turns the Don't block into the Do block, byte for byte, at width 120 or the width a "Shown at width N." sentence
/// in the section names. The naming guideline is not a layout rule and is skipped.
/// </summary>
public sealed partial class StyleGuideExamplesTests
{
    private static readonly string[] s_lintCodes = ["BYN1072", "BYN1073", "BYN1074", "BYN1075", "BYN1076"];

    [GeneratedRegex(@"^### (?<title>.+?)\n(?<body>.*?)(?=^#{2,3} |\z)", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex Sections();

    [GeneratedRegex(@"^Do:\n\n```bayan\n(?<do>.*?)```\n\nDon't:\n\n```bayan\n(?<dont>.*?)```", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex Pairs();

    [GeneratedRegex(@"Shown at width (?<width>\d+)\.")]
    private static partial Regex ShownAtWidth();

    private static IEnumerable<(string Title, string Do, string Dont, bool Lint, int Width)> Examples()
    {
        var doc = File.ReadAllText(Path.Combine(Golden.RepoRoot, "docs", "bayan-style.md")).Replace("\r\n", "\n");
        var lints = doc.IndexOf("\n## Style lints", StringComparison.Ordinal);
        foreach (Match section in Sections().Matches(doc))
        {
            if (Pairs().Match(section.Groups["body"].Value) is not { Success: true } pair) continue;
            var width = ShownAtWidth().Match(section.Groups["body"].Value) is { Success: true } w ? int.Parse(w.Groups["width"].Value) : 120;
            yield return (section.Groups["title"].Value, pair.Groups["do"].Value, pair.Groups["dont"].Value, section.Index > lints, width);
        }
    }

    public static TheoryData<string> LayoutCases => Titles(lint: false);

    public static TheoryData<string> LintCases => Titles(lint: true);

    private static TheoryData<string> Titles(bool lint)
    {
        var data = new TheoryData<string>();
        foreach (var e in Examples().Where(e => e.Lint == lint && e.Title != "Naming")) data.Add(e.Title);
        return data;
    }

    [Fact]
    public void TheDocHasLayoutAndLintPairs()
    {
        Assert.True(Examples().Count(e => !e.Lint) >= 20, "layout pairs");
        Assert.Equal(5, Examples().Count(e => e.Lint));
    }

    [Theory]
    [MemberData(nameof(LayoutCases))]
    public void DontFormatsToDo(string title)
    {
        var e = Examples().First(e => e.Title == title);
        var (output, skipped) = Layout.Apply(Encoding.UTF8.GetBytes(e.Dont), new LayoutOptions(Width: e.Width));
        Assert.Null(skipped);
        Assert.Equal(e.Do, Encoding.UTF8.GetString(output));
    }

    [Theory]
    [MemberData(nameof(LintCases))]
    public void DontReportsTheLintAndDoReportsNone(string title)
    {
        var e = Examples().First(e => e.Title == title);
        var code = Regex.Match(title, @"BYN\d{4}").Value;
        Assert.Contains(code, s_lintCodes);
        Assert.Contains(code, CodesOf(e.Dont));
        Assert.Empty(CodesOf(e.Do));
    }

    /// <summary>The style lint codes <c>bayan check</c> finds in <paramref name="source"/>: the lint pass needs no types, so a fragment is enough.</summary>
    private static string[] CodesOf(string source) =>
        [.. SyntaxTree.Parse(new SourceText("example.byn", Encoding.UTF8.GetBytes(source))).StyleLints.Select(d => d.Code).Distinct()];
}
