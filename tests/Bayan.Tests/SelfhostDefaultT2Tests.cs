using System.Reflection;
using Bayan.Cli;
using Bayan.Syntax.Ast;

namespace Bayan.Tests;

/// <summary>
/// 017 T2: <c>bayan features --used</c> of the self-hosted driver. The expected output is <see cref="CliApp.Run"/> in-process on the
/// same argv; the name tables of <c>selfhost/driver/features.byn</c> are checked against the C# syntax types by reflection.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed class SelfhostDefaultT2Tests
{
    private static string FeaturesPath => Path.Combine(SelfhostDriverHarness.DriverDir, "features.byn");

    private static (int Exit, string Out, string Err) Oracle(string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString().ReplaceLineEndings("\n"), stderr.ToString().ReplaceLineEndings("\n"));
    }

    private static void AssertSameAsCs(params string[] args)
    {
        var expected = Oracle(args);
        var actual = SelfhostDriverHarness.Run(args);
        var label = string.Join(' ', args);
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", expected.Out, actual.Out);
        SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", expected.Err, actual.Err);
    }

    private static string Fresh(string name, string source)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t2-features", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "main.byn"), source);
        return dir;
    }

    private const string Decls = """
        type Id = i64
        enum Color {
            red
            green
        }
        union error Oops {
            bad
            worse(i64 code)
        }
        struct Point {
            public i64 x
            public i64 y
            public i64 sum => x + y
        }
        interface IShape {
            i64 area()
        }
        i64 twice(i64 x) => (x * 2)
        void main() {
            let p = Point { x: 1, y: 2 }
            print($"{p.sum} {twice(2)}")
        }

        @cases((1, 2), (3, 4)) because "two pairs"
        test "pairs" (i64 a, i64 b) {
            assert(a < b)
        }
        """;

    private const string Rich = """
        struct Point {
            i64 x
            i64 y
            requires x >= 0
        }

        enum Color {
            red
            green
        }

        union error E {
            bad
        }

        i64 first(Point p) fails E {
            fail .bad if p.x < 0
            return p.x
        }

        void main() {
            var s = "abc"
            let p = Point { x: 1, y: 2 }
            let n = first(p) catch 0
            for i in 0..3 { print($"{s.length} {i} {n}") }
            switch Color.red {
                case .red: print("r")
                default: print("o")
            }
        }
        """;

    public static IEnumerable<object[]> Rows()
    {
        var sample = Fresh("sample", "void main() {\n    var s = \"abc\"\n    if s.length > 1 {\n        print(s)\n    }\n}\n");
        var rich = Fresh("rich", Rich);
        var withTests = Fresh("tests", "i64 twice(i64 x) => x * 2\n\nvoid main() {\n    print($\"{twice(2)}\")\n}\n");
        File.WriteAllText(Path.Combine(withTests, "main.test.byn"), "test \"twice\" {\n    assert twice(2) == 4\n}\n");
        var broken = Fresh("broken", "void main() {\n    let x: i32 = \"no\"\n}\n");
        var warned = Fresh("warned", "void main() {\n    var x = 1\n    print($\"{x}\")\n}\n");
        var project = Path.Combine(Golden.RepoRoot, "tmp", "t2-features", "project");
        if (Directory.Exists(project)) Directory.Delete(project, recursive: true);
        Directory.CreateDirectory(Path.GetDirectoryName(project)!);
        Oracle(new[] { "new", project });
        var decls = Fresh("decls", Decls);
        File.WriteAllText(Path.Combine(decls, "notes.txt"), "not a module\n");
        Directory.CreateDirectory(Path.Combine(decls, "sub.byn"));
        var driver = SelfhostDriverHarness.DriverDir;
        var selfhost = Path.GetDirectoryName(driver)!;
        return new[]
        {
            new[] { "features" },
            new[] { "features", "." },
            new[] { "features", sample },
            new[] { "features", "--used", sample },
            new[] { sample, "features", "--used" },
            new[] { "features", "--used", rich },
            new[] { "features", "--used", withTests },
            new[] { "features", "--used", withTests, "--package", withTests },
            new[] { "features", "--used", warned },
            new[] { "features", "--used", broken },
            new[] { "features", "--used", broken, "--diagnostics", "json" },
            new[] { "features", "--used", Path.Combine(sample, "missing") },
            new[] { "features", "--used", sample, "extra" },
            new[] { "features", "--used", sample, "--mode", "bogus" },
            new[] { "features", "--used", sample, "-o", "x" },
            new[] { "features", "--used", project },
            new[] { "features", "--used", Path.Combine(project, "src", "app", "main.byn"), "--package", Path.Combine(project, "src", "app") },
            new[] { "features", "--used", project, "--package", project },
            new[] { "features", "--used", decls },
            new[] { "features", "--used", decls, "--package", decls },
            new[] { "features", "--used", Path.Combine(decls, "main.byn"), "--package", decls },
            new[] { "features", "--used", driver, "--package", selfhost },
        }.Select(a => new object[] { a });
    }

    [Theory]
    [MemberData(nameof(Rows))]
    public void FeaturesMatchesTheCSharpCli(string[] args) => AssertSameAsCs(args);

    /// <summary>Every program of <c>tests/cases/{run,typed,parse,diag}/</c>: each file alone (`--package` its directory, as the golden `types` rows do): the node kinds and diagnostics the corpus touches, errors included.</summary>
    [Fact]
    public void FeaturesMatchesTheCSharpCliOnTheCorpus()
    {
        foreach (var dir in new[] { "run", "typed", "parse", "diag" })
            foreach (var file in Directory.GetFiles(Path.Combine(Golden.CasesRoot, dir), "*.byn", SearchOption.TopDirectoryOnly).Order(StringComparer.Ordinal))
                AssertSameAsCs("features", "--used", file, "--package", Path.GetDirectoryName(file)!);
    }

    private static IEnumerable<string> Concrete(Type baseType) =>
        typeof(Node).Assembly.GetTypes().Where(t => baseType.IsAssignableFrom(t) && !t.IsAbstract).Select(t => t.Name).Order(StringComparer.Ordinal);

    private static string Pascal(string kind) => char.ToUpperInvariant(kind[0]) + kind[1..];

    private static readonly HashSet<string> AllTypeNames = typeof(Node).Assembly.GetTypes().Select(t => t.Name).ToHashSet(StringComparer.Ordinal);

    /// <summary>The (case, name) pairs of the arms `case .kind: return "Name"` in the body of the function <paramref name="function"/>.</summary>
    private static List<(string Kind, string Name)> ReturnArms(string function)
    {
        var source = File.ReadAllText(FeaturesPath);
        var start = source.IndexOf($" {function}(", StringComparison.Ordinal);
        Assert.True(start >= 0, $"features.byn has no {function}");
        var end = source.IndexOf("\n}\n", start, StringComparison.Ordinal);
        return System.Text.RegularExpressions.Regex.Matches(source[start..end], "case \\.(\\w+): return \"(\\w+)\"")
            .Select(m => (m.Groups[1].Value, m.Groups[2].Value)).ToList();
    }

    /// <summary>The (case, name) pairs of the arms `case .kind(let n):` then `t2Add("Name", ...)` in <c>t2Declarations</c>.</summary>
    private static List<(string Kind, string Name)> DeclarationArms() =>
        System.Text.RegularExpressions.Regex.Matches(File.ReadAllText(FeaturesPath), "case \\.(\\w+)\\(let n\\):(?:\\s|//[^\\n]*)+t2Add\\(\"(\\w+)\"")
            .Select(m => (m.Groups[1].Value, m.Groups[2].Value)).ToList();

    private static void AssertTable(List<(string Kind, string Name)> arms, IEnumerable<string> required, string what)
    {
        Assert.True(arms.Count > 10, $"{what}: only {arms.Count} arms found");
        var wrong = arms.Where(a => Pascal(a.Kind) != a.Name).Select(a => $".{a.Kind} -> \"{a.Name}\"").ToList();
        Assert.True(wrong.Count == 0, $"{what}: an arm names another kind: {string.Join(", ", wrong)}");
        var unknown = arms.Where(a => !AllTypeNames.Contains(a.Name)).Select(a => a.Name).ToList();
        Assert.True(unknown.Count == 0, $"{what}: no C# type is named {string.Join(", ", unknown)}");
        var duplicate = arms.GroupBy(a => a.Name).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
        Assert.True(duplicate.Count == 0, $"{what}: two arms give {string.Join(", ", duplicate)}");
        var missing = required.Except(arms.Select(a => a.Name)).ToList();
        Assert.True(missing.Count == 0, $"{what}: no arm for {string.Join(", ", missing)}");
    }

    /// <summary>Every <c>GetType().Name</c> <c>Features.Declarations</c> can yield has an arm in the driver's table, and each arm maps its case to that exact name.</summary>
    [Fact]
    public void TheDeclarationNameTableCoversTheCSharpDeclarations()
    {
        var table = File.ReadAllText(FeaturesPath);
        var names = Concrete(typeof(Decl)).ToList();
        Assert.True(names.Count > 15);
        AssertTable(DeclarationArms(), names, "t2Declarations");
        foreach (var n in new[] { nameof(AttributeSyntax), nameof(BecauseClause) })
            Assert.Contains($"\"{n}\"", table);
    }

    /// <summary>The bound nodes' syntax kinds: every concrete <c>Expr</c>, <c>Stmt</c> and <c>Pattern</c> record has an arm, and each arm maps its kind to that exact name.</summary>
    [Fact]
    public void TheSyntaxNameTablesCoverTheExprStmtAndPatternRecords()
    {
        var exprArms = ReturnArms("t2ExprName");
        var nodeArms = ReturnArms("t2NodeName");
        var names = Concrete(typeof(Expr)).Concat(Concrete(typeof(Stmt))).Concat(Concrete(typeof(Pattern))).ToList();
        AssertTable(exprArms, names.Where(n => n.EndsWith("Expr", StringComparison.Ordinal)), "t2ExprName");
        AssertTable(nodeArms, names.Where(n => !n.EndsWith("Expr", StringComparison.Ordinal)), "t2NodeName");
    }
}
