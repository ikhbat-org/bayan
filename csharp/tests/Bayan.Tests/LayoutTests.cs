using System.Text;
using Bayan.Cli;
using Bayan.Syntax.Parsing;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

public sealed class LayoutTests
{
    private static string Lay(string source)
    {
        var (output, skipped) = Layout.Apply(Encoding.UTF8.GetBytes(source), new LayoutOptions());
        Assert.Null(skipped);
        return Encoding.UTF8.GetString(output);
    }

    private static (int Exit, string Out, string Err) Run(params string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString(), stderr.ToString());
    }

    /// <summary>A fresh file under <c>tmp/layout/</c> holding <paramref name="text"/>.</summary>
    private static string Fresh(string name, string text)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "layout", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, "main.byn");
        File.WriteAllText(file, text);
        return file;
    }

    // ── Hygiene ──

    [Fact]
    public void LineEndingsBecomeLf() => Assert.Equal("let a = 1\nlet b = 2\n", Lay("let a = 1\r\nlet b = 2\r\n"));

    [Fact]
    public void TrailingWhitespaceIsDropped() => Assert.Equal("let a = 1 // one\nlet b = 2\n", Lay("let a = 1 // one \t\nlet b = 2   \n"));

    [Fact]
    public void AFinalNewlineIsAdded() => Assert.Equal("let a = 1\n", Lay("let a = 1"));

    [Fact]
    public void ExtraFinalNewlinesAreDropped() => Assert.Equal("let a = 1\n", Lay("let a = 1\n\n\n"));

    [Fact]
    public void AnEmptyFileStaysEmpty() => Assert.Equal("", Lay(""));

    // ── Indentation ──

    [Fact]
    public void BlocksIndentOneLevel() => Assert.Equal(
        "void main() {\n    let a = 1\n    if a > 0 {\n        print(a)\n    }\n}\n",
        Lay("void main() {\nlet a = 1\n  if a > 0 {\n print(a)\n      }\n}\n"));

    [Fact]
    public void AWaslLineGoesOneLevelDeeper() => Assert.Equal(
        "void main() {\n    let s = xs\n        .map(f)\n        ?? ys\n}\n",
        Lay("void main() {\n    let s = xs\n    .map(f)\n  ?? ys\n}\n"));

    [Fact]
    public void ALineAfterAnOperatorContinues() => Assert.Equal(
        "void main() {\n    let s = a +\n        b\n    print(s)\n}\n",
        Lay("void main() {\n    let s = a +\nb\n    print(s)\n}\n"));

    [Fact]
    public void HeaderClausesTakeTwoLevels() => Assert.Equal(
        "public Money quote(Cart cart)\n        expects cart.total > 0\n        uses db\n        fails QuoteError {\n    return cart.total\n}\n",
        Lay("public Money quote(Cart cart)\n    expects cart.total > 0\n    uses db\n    fails QuoteError {\n    return cart.total\n}\n"));

    [Fact]
    public void AWrappedConditionTakesTwoLevels() => Assert.Equal(
        "void main() {\n    if a\n            and b {\n        print(a)\n    }\n}\n",
        Lay("void main() {\n    if a\n    and b {\n        print(a)\n    }\n}\n"));

    [Fact]
    public void ACloserSitsAtItsOpenersLevel() => Assert.Equal(
        "void main() {\n    f(\n        1,\n        2\n    )\n    let xs = [\n        1,\n    ]\n}\n",
        Lay("void main() {\n    f(\n1,\n            2\n        )\n    let xs = [\n  1,\n  ]\n}\n"));

    [Fact]
    public void ACommentLineTakesTheNextLinesLevel() => Assert.Equal(
        "void main() {\n    // first\n    let a = 1\n    // last\n}\n",
        Lay("void main() {\n// first\n    let a = 1\n        // last\n}\n"));

    // ── Spacing ──

    [Fact]
    public void BinaryOperatorsTakeOneSpaceEachSide() => Assert.Equal(
        "let a = b + c - d == e && f || g ?? h\n",
        Lay("let a=b+c  -d==e&&f||g??h\n"));

    [Fact]
    public void ArrowsAndAssignmentsAreSpaced() => Assert.Equal(
        "bool isA(rune c) => c == 'a'\n",
        Lay("bool isA(rune c)=>c=='a'\n"));

    [Fact]
    public void RangesAreTight() => Assert.Equal("for i in 0..10 { print(i) }\nfor i in 0..<n { print(i) }\n",
        Lay("for i in 0 .. 10 { print(i) }\nfor i in 0 ..< n { print(i) }\n"));

    [Fact]
    public void UnaryOperatorsAreTight() => Assert.Equal("let a = -b\nlet c = !d\n", Lay("let a = - b\nlet c = ! d\n"));

    [Fact]
    public void AColonTakesASpaceAfterOnly() => Assert.Equal(
        "let p = Point { x: 1, y: 2 }\nf(ref c, by: d)\n",
        Lay("let p = Point{x :1,y:2}\nf(ref c , by :d)\n"));

    [Fact]
    public void TernaryAndConformanceColonsAreSpaced() => Assert.Equal(
        "let a = b ? c : d\nstruct S : I { i32 x }\n",
        Lay("let a = b ? c:d\nstruct S: I { i32 x }\n"));

    [Fact]
    public void GroupsAreNotPaddedAndCallsAreTight() => Assert.Equal(
        "let a = f(x, y)[0]\n",
        Lay("let a = f ( x,y ) [ 0 ]\n"));

    [Fact]
    public void ASpaceBeforeAParenAfterAKeywordOrLiteralIsKept() => Assert.Equal(
        "test \"positive\" (i32 n) {\n    assert(n > 0)\n}\n",
        Lay("test \"positive\" (i32 n) {\n    assert(n > 0)\n}\n"));

    [Fact]
    public void GenericsPointersAndUnitsStayTight() => Assert.Equal(
        "List<i32> xs = make()\nu8* p = q\nlet t = 30s\nlet s = a >> 2\n",
        Lay("List<i32> xs = make()\nu8* p = q\nlet t = 30s\nlet s = a >> 2\n"));

    [Fact]
    public void ATrailingCommentTakesOneSpace() => Assert.Equal(
        "let a = 1 // a  note\nlet b = 2 // b\n",
        Lay("let a = 1      // a  note\nlet b = 2// b\n"));

    [Fact]
    public void StringContentsAreNotTouched() => Assert.Equal(
        "let a = \"x  =  y \"\nlet b = $\"{ a+1 }  -\"\n",
        Lay("let a  =  \"x  =  y \"\nlet b = $\"{ a+1 }  -\"\n"));

    // ── Blank lines ──

    [Fact]
    public void BlankLineRunsCollapseToOne() => Assert.Equal(
        "void main() {\n    let a = 1\n\n    let b = 2\n}\n",
        Lay("void main() {\n\n    let a = 1\n\n\n\n    let b = 2\n\n}\n"));

    [Fact]
    public void ABlankLineGoesBetweenTopLevelDeclarations() => Assert.Equal(
        "void f() {\n}\n\nvoid g() {\n}\n",
        Lay("void f() {\n}\nvoid g() {\n}\n"));

    [Fact]
    public void OneLineDeclarationsOfOneKindStayTogether() => Assert.Equal(
        "struct A { i32 x }\nstruct B { i32 y }\n\ntype F = i32 -> bool\n\nvoid f() {\n}\n",
        Lay("struct A { i32 x }\nstruct B { i32 y }\ntype F = i32 -> bool\nvoid f() {\n}\n"));

    [Fact]
    public void AnAuthorsBlankLineBetweenOneLinersIsKept() => Assert.Equal(
        "struct A { i32 x }\n\nstruct B { i32 y }\n",
        Lay("struct A { i32 x }\n\n\nstruct B { i32 y }\n"));

    // ── Idempotence, @unformatted ──

    private const string Messy =
        "struct Order{i64 total\n  str  name}\r\n" +
        "public Money quote(Cart cart)\n expects cart.total>0\n uses db {\n\n" +
        "let x=[1,2 ,3]   // three\n" +
        "  if x.length>0\n  and ok {\n print(x[0])\n}\n\n\n" +
        "    // done\n}\n";

    [Fact]
    public void LayoutIsIdempotent()
    {
        var once = Lay(Messy);
        Assert.NotEqual(Messy, once);
        Assert.Equal(once, Lay(once));
    }

    [Fact]
    public void AnUnformattedDeclarationKeepsItsBytes()
    {
        const string table = "@unformatted because \"a table\"\nvoid t() {\n  let grid = [\n  1,   0,\n  0,   1,\n  ]\n}\n";
        Assert.Equal(table + "\nvoid f() {\n    let a = 1\n}\n", Lay(table + "void f() {\nlet a=1\n}\n"));
    }

    [Fact]
    public void AnUnformattedMemberKeepsItsBytes()
    {
        const string source = "struct S {\n    @unformatted because \"columns\"\n    i32 f() {\n      return   1\n    }\n  i32 g() {\nreturn   2\n}\n}\n";
        Assert.Equal(
            "struct S {\n    @unformatted because \"columns\"\n    i32 f() {\n      return   1\n    }\n    i32 g() {\n        return 2\n    }\n}\n",
            Lay(source));
    }

    // ── Safety net ──

    [Fact]
    public void ABlockCommentIsSkipped()
    {
        var source = "let a = 1 /* b */\n"u8.ToArray();
        var (output, skipped) = Layout.Apply(source, new LayoutOptions());
        Assert.NotNull(skipped);
        Assert.Equal(source, output);
    }

    [Theory]
    [InlineData("tokens", "let a = 1\nlet b = 2\n", "let a = 1\nlet b = 3\n", "the tokens changed")]
    [InlineData("diagnostics", "let a = 1\nlet b = 2\n", "let a = 1 let b = 2\n", "the diagnostics changed")]
    [InlineData("comments", "let a = 1 // one\n", "let a = 1 // two\n", "the comments changed")]
    public void ADifferenceKeepsTheInput(string name, string source, string broken, string reason)
    {
        Layout.OutputHook = _ => Encoding.UTF8.GetBytes(broken);
        try
        {
            var bytes = Encoding.UTF8.GetBytes(source.Replace("=", "  =  "));
            var (output, skipped) = Layout.Apply(bytes, new LayoutOptions());
            Assert.Equal(reason, skipped);
            Assert.Equal(bytes, output);

            var file = Fresh(name, source.Replace("=", "  =  "));
            var (exit, _, stderr) = Run("format", file);
            Assert.Equal(CliApp.ExitOk, exit);
            Assert.Contains($"bayan format: layout skipped for {file}: {reason}", stderr);
            Assert.Equal(source.Replace("=", "  =  "), File.ReadAllText(file));
        }
        finally { Layout.OutputHook = null; }
    }

    // ── Corpus ──

    /// <summary>
    /// Every corpus file that <c>bayan format</c> lays out as it is: no error stops it, and no fix rewrites it first.
    /// </summary>
    public static IEnumerable<object[]> Corpus() =>
        new[] { Golden.CasesRoot, Path.Combine(Golden.RepoRoot, "src"), Path.Combine(Golden.RepoRoot, "lib") }
            .SelectMany(root => Directory.EnumerateFiles(root, "*.byn", SearchOption.AllDirectories))
            .Where(f => !SyntaxTree.Parse(new SourceText(f, File.ReadAllBytes(f))).Diagnostics.Any(d => d.IsError || d.Fix is not null))
            .Order(StringComparer.Ordinal)
            .Select(f => new object[] { Path.GetRelativePath(Golden.RepoRoot, f) });

    [Theory]
    [MemberData(nameof(Corpus))]
    public void TheCorpusLaysOutOnceAndForAll(string file)
    {
        var source = File.ReadAllBytes(Path.Combine(Golden.RepoRoot, file));
        var (once, skipped) = Layout.Apply(source, new LayoutOptions());
        Assert.Null(skipped);
        var (twice, again) = Layout.Apply(once, new LayoutOptions());
        Assert.Null(again);
        Assert.Equal(Encoding.UTF8.GetString(once), Encoding.UTF8.GetString(twice));
    }
}
