using Bayan.Semantics;
using Bayan.Semantics.Binding;
using Bayan.Syntax.Ast;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// 017 P2 (Q1076, Q1096): the syntax facts each selfhost bound node records against C#'s <c>BoundNode.Syntax</c>,
/// compared in-process. For every node of every function and test body (<c>BoundTree.Descendants</c>, as
/// <c>Features.ToJson</c> walks them) one line: <c>Syntax</c>'s span and record type, then the facts
/// <c>Features</c>, <c>Mutator</c> and <c>CoverageInstrumenter</c> read from it.
/// </summary>
public sealed class SelfhostDefaultP2Tests
{
    private const string Main = """
        i32 main(ReadOnlySpan<string> args) {
            for i in 0..args.length {
                var c = fromPath(args[i], by: in CompilationOptions { includeTests: true }, wholeDirectory: false)
                Io.stdout.write(p2Print(in c, at: args[i]))
            }
            return 0
        }

        """ + Lines;

    /// <summary>
    /// <c>args[0]</c> compiled, then <c>withFile</c> again for each triple after it: a section name, the path the
    /// text replaces, and the file it is read from. Each section prints the diagnostics, then the bound nodes.
    /// </summary>
    private const string WithFileMain = """
        import lexer

        i32 main(ReadOnlySpan<string> args) {
            var c = fromPath(args[0], by: in CompilationOptions { includeTests: true, capabilities: ["fs"] })
            var i = 1
            while i + 2 < args.length {
                let text = lexer.SourceText.create(args[i + 1], from: t11ReadAllBytes(args[i + 2]))
                let next = withFile(in c, from: in text)
                c = move next
                print($"== {args[i]}")
                if c.diagnostics.length == 0 { print("(no diagnostics)") }
                for d in c.diagnostics {
                    let pos = linePosition(c.files[d.file].text.span, at: d.span.start)
                    print($"diag {d.code} {c.files[d.file].displayPath} {pos.line}:{pos.column} {d.message} | {d.label} | {d.help}")
                }
                Io.stdout.write(p2Print(in c, at: $"{args[i]} nodes"))
                i += 3
            }
            return 0
        }

        """ + Lines;

    private const string Lines = """
        string p2Print(in Ctx c, at string path) uses alloc {
            var sb = StrBuf()
            sb.append($"== {path}\n")
            var functions = List<FuncId>()
            var seen: Map<FuncId, bool> = []
            for m in 0..c.modules.length {
                for f in c.modules[m].allFunctions {
                    unless seen.contains(f) { functions.append(f) }
                    seen[f] = true
                }
                for t in c.modules[m].tests {
                    let f = c.tests[t].function
                    unless seen.contains(f) { functions.append(f) }
                    seen[f] = true
                }
            }
            for fn in functions {
                let body = c.functions[fn].body
                if body == -1 || boundKind(body) != .block { continue }
                for n in descendants(in c, for: body) { sb.append($"{p2Line(in c, for: n)}\n") }
            }
            return $"{sb.finish()}"
        }

        string p2Span(TextSpan s) uses alloc => $"{s.start}..{s.end}"

        string p2Line(in Ctx c, for BNode n) uses alloc {
            // A node records one `Syntax`: ` both` (never in the C# lines) when it has the two.
            let other = nodeSyntax(in c, for: n)
            if (exprSyntax(in c, for: n) is { } e) {
                var sb = StrBuf()
                sb.append($"{p2Span(e.span)} {e.kind}")
                if e.kind == .binaryExpr { sb.append($" {e.binaryOp} right {p2Span(e.right)}") }
                if e.kind == .unaryExpr { sb.append($" {e.op} operand {p2Span(exprSyntaxNode(in c, at: e.operand).span)}") }
                if e.kind == .literalExpr {
                    sb.append($" {e.literalKind}")
                    if (e.suffix is { } x) { sb.append($" suffix {p2Span(x)}") }
                }
                if e.becauseKeyword { sb.append(" because") }
                if other is not null { sb.append(" both") }
                return $"{sb.finish()}"
            }
            if (other is { } s) {
                var sb = StrBuf()
                sb.append($"{p2Span(s.span)} {s.kind}")
                if s.kind == .assignStmt { sb.append($" {s.assignOp} target {p2Span(s.target)}") }
                if (s.value is { } v) { sb.append($" value {p2Span(v)}") }
                return $"{sb.finish()}"
            }
            return $"{p2Span(nodeSpan(in c, for: n))} -"
        }
        """;

    private static string Span(Node n) => $"{n.Span.Start}..{n.Span.End}";

    private static string Lower(string name) => char.ToLowerInvariant(name[0]) + name[1..];

    private static string Keyword(string name) => name is "Not" or "And" or "Or" or "Float" or "True" or "False" or "Null" ? Lower(name) + "Keyword" : Lower(name);

    /// <summary>The line the generated main prints for <paramref name="node"/>.</summary>
    private static string Line(BoundNode node)
    {
        var line = $"{Span(node.Syntax)} {Lower(node.Syntax.GetType().Name)}";
        switch (node.Syntax)
        {
            case BinaryExpr b: line += $" {Keyword(b.Op.ToString())} right {Span(b.Right)}"; break;
            case UnaryExpr u: line += $" {Keyword(u.Op.ToString())} operand {Span(u.Operand)}"; break;
            case LiteralExpr l: line += $" {Keyword(l.Kind.ToString())}" + (l.Suffix is { } x ? $" suffix {Span(x)}" : ""); break;
            case CallExpr { Because: not null }: line += " because"; break;
            case AssignStmt a: line += $" {Keyword(a.Op.ToString())} target {Span(a.Target)} value {Span(a.Value)}"; break;
            case ReturnStmt { Value: { } v }: line += $" value {Span(v)}"; break;
        }
        return line;
    }

    /// <summary>The C# lines for <paramref name="path"/>, walked as <c>Features.ToJson</c> walks a compilation.</summary>
    private static List<string> Expected(string path) =>
        Nodes(Compilation.FromPath(path, new CompilationOptions(IncludeTests: true), wholeDirectory: false));

    private static List<string> Nodes(Compilation c)
    {
        var functions = c.Modules.SelectMany(m => m.AllFunctions.Concat(m.Tests.Select(t => t.Function))).Distinct();
        return functions.Select(f => f.Body).OfType<BoundBlock>().SelectMany(BoundTree.Descendants).Select(Line).ToList();
    }

    private static void AssertSameAsCSharp(IReadOnlyList<string> paths)
    {
        var sections = SelfhostSemanticsHarness.RunSections(Main, paths.ToArray());
        var compared = 0;
        foreach (var path in paths)
        {
            var expected = Expected(path);
            compared += expected.Count;
            Assert.True(sections.TryGetValue(path, out var actual), $"{path}: not printed");
            SelfhostEmitterHarness.AssertSame(path, string.Join("\n", expected), string.Join("\n", actual!));
        }
        Assert.True(compared > 0, "the oracle produced no lines");
    }

    private static List<string> Corpus()
    {
        var paths = new List<string>();
        foreach (var dir in new[] { "run", "diag" })
        {
            var root = Path.Combine(Golden.CasesRoot, dir);
            foreach (var file in Directory.EnumerateFiles(root, "*.byn", SearchOption.AllDirectories).Order(StringComparer.Ordinal))
            {
                var parent = Path.GetDirectoryName(file)!;
                var path = parent == root ? file : Path.Combine(root, Path.GetRelativePath(root, parent).Split(Path.DirectorySeparatorChar)[0]);
                if (!paths.Contains(path)) paths.Add(path);
            }
        }
        return paths;
    }

    [Fact]
    public void CorpusBoundNodesRecordTheCSharpSyntax() => AssertSameAsCSharp(Corpus());

    /// <summary>Statements and patterns the corpus binds only without error, each in a broken form: the nodes the binder builds on its error paths.</summary>
    private static readonly (string Name, string Text)[] ErrorPaths =
    [
        ("unless.byn", """
            void main() {
                let x = 1
                unless x == 2 { print("a") }
            }
            """),
        ("assign.byn", """
            struct P {
                i64 x = 0
            }

            @sealed
            struct S {
                i64 n = 0
            }

            void g(P p) {
                p.x++
                p.x += 1
            }

            void t(ref S s) {
                s.n++
            }

            void main() {
                var a = 1
                a ??= 2
                a += nope
                a <<= 2
                var f = 1.5
                f <<= 2
                var s = "x"
                s += "y"
                var b = true
                b += 1
                b++
                nope++
                g(P {})
            }
            """),
        ("fail.byn", """
            union error E {
                bad
            }

            union error F {
                withCode(i64 code)
            }

            void h() fails E {
                fail 3
            }

            void k() fails F {
                fail .withCode
            }

            void m() fails F {
                fail F.withCode
            }

            void w() fails E {
                defer panicking (p) fail E.bad
                h()
            }

            void v() {
                return panic("x")
            }

            void main() {}
            """),
        ("patterns.byn", """
            struct P {
                i64 x = 0
            }

            struct Order {
                i64 id
                states {
                    draft
                    paid(i64 payment)
                }
            }

            union error E {
                bad
            }

            i64 sw(i64 n, (i64, i64) t, Order o, P q) {
                switch n {
                    case 1..5: return 1
                    case [1, 2]: return 2
                    case P x: return 3
                    case (1, 2): return 4
                    case P(1): return 5
                    case P.x(1): return 6
                    default: {}
                }
                switch t {
                    case (1, 2): return 7
                    default: {}
                }
                switch o {
                    case .paid: return 8
                    case .nope: return 9
                    default: {}
                }
                return 0
            }

            i64 parse(i64 n) fails E => n

            i64 handle(i64 n) => parse(n) catch switch {
                E e => 0,
            }

            void main() {}
            """),
        ("assert.test.byn", """
            union error E {
                bad
            }

            i64 g() => 1

            i64 f() fails E => 1

            test "t" {
                assert g() fails i64
                assert f() fails i64
            }
            """),
        ("default.byn", """
            union error E {
                bad
            }

            i64 p() fails E => 1

            i64 d(i64 x = p() catch switch { _ => return 2 }) => x

            i64 e(i64 x = p() catch switch { _ => fail E.bad }) fails E => x

            i64 g() fails E => try e()

            void main() {
                let a = d()
                print($"{a}")
            }
            """),
        ("move.byn", """
            struct Box {
                i64 v = 0
            }

            void take(string s) {}

            void main() {
                let b = Box {}
                take(move b)
            }
            """),
        ("empty.byn", """
            union error Z {}

            struct N {
                requires 1 == 1
            }

            i64 pz() fails Z => 1

            i64 hz() => pz() catch switch {
                Z z => 0,
            }

            void main() {}
            """),
    ];

    [Fact]
    public void ErrorPathNodesRecordTheCSharpSyntax()
    {
        var scratch = Directory.CreateTempSubdirectory("p2-errors-");
        try
        {
            var paths = new List<string>();
            foreach (var (name, text) in ErrorPaths)
            {
                var dir = Directory.CreateDirectory(Path.Combine(scratch.FullName, Path.GetFileNameWithoutExtension(name).Replace('.', '-')));
                var file = Path.Combine(dir.FullName, name);
                File.WriteAllText(file, text + "\n");
                Assert.True(Expected(file).Count > 0, $"{name}: no bound nodes, so nothing is compared:\n" +
                    string.Join("\n", Compilation.FromPath(file, new CompilationOptions(IncludeTests: true), wholeDirectory: false).Diagnostics.Items.Select(Diag)));
                paths.Add(file);
            }
            AssertSameAsCSharp(paths);
        }
        finally { scratch.Delete(recursive: true); }
    }

    private static string Diag(Diagnostic d)
    {
        var (line, col) = d.Source!.GetLinePosition(d.Span.Start);
        return $"diag {d.Code} {d.Source!.Path} {line}:{col} {d.Message} | {d.Label} | {d.Help}";
    }

    /// <summary>
    /// Compilation.cs:129 <c>WithFile</c>: the entry file and an imported file replaced in turn, each step from the
    /// last, so the second keeps the first's text (and looks past it for the import); a broken text reports from the replacement (the failure path), and a
    /// path the program does not read changes nothing.
    /// </summary>
    [Fact]
    public void WithFileRebindsAFileFromTextAsCSharpDoes()
    {
        var dir = Path.Combine(Golden.CasesRoot, "run", "alias-field-default-import");
        var main = Path.Combine(dir, "main.byn");
        var sub = File.ReadAllText(Path.Combine(dir, "sub", "sub.byn"));
        var entry = File.ReadAllText(main);
        var steps = new (string Name, string Path, string Text)[]
        {
            ("main broken", main, entry.Replace("h.inner.a", "h.inner.zz")),
            ("sub", "sub/sub.byn", sub.Replace("i64 a = 3", "i64 a = 3\n    public string b = \"x\"")),
            ("main fixed", main, entry.Replace("h.inner.a", "h.inner.b")),
            ("unread", Path.Combine(dir, "nope.byn"), "this is not Bayan"),
        };
        foreach (var step in steps) Assert.NotEqual(step.Path == main ? entry : sub, step.Text);
        var scratch = Directory.CreateTempSubdirectory("p2-withfile-");
        try
        {
            var args = new List<string> { Path.GetFullPath(dir) };
            for (var i = 0; i < steps.Length; i++)
            {
                var file = Path.Combine(scratch.FullName, $"{i}.byn");
                File.WriteAllText(file, steps[i].Text);
                args.AddRange([steps[i].Name, steps[i].Path, file]);
            }
            var sections = SelfhostSemanticsHarness.RunSections(WithFileMain, args.ToArray());
            var c = Compilation.FromPath(dir, new CompilationOptions(IncludeTests: true, Capabilities: ["fs"]));
            foreach (var step in steps)
            {
                c = c.WithFile(new SourceText(step.Path, System.Text.Encoding.UTF8.GetBytes(step.Text)));
                SelfhostSemanticsHarness.AssertSection(sections, step.Name, c.Diagnostics.Items.Select(Diag).ToList() is { Count: > 0 } d ? d : ["(no diagnostics)"]);
                SelfhostSemanticsHarness.AssertSection(sections, $"{step.Name} nodes", Nodes(c));
            }
        }
        finally { scratch.Delete(recursive: true); }
    }
}
