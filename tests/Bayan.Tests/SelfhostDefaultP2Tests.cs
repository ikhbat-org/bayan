using Bayan.Semantics;
using Bayan.Semantics.Binding;
using Bayan.Syntax.Ast;

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
                return $"{sb.finish()}"
            }
            if (nodeSyntax(in c, for: n) is { } s) {
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
    private static List<string> Expected(string path)
    {
        var c = Compilation.FromPath(path, new CompilationOptions(IncludeTests: true), wholeDirectory: false);
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

    [Fact]
    public void Survey()
    {
        var paths = Corpus();
        var sections = SelfhostSemanticsHarness.RunSections(Main, paths.ToArray());
        File.WriteAllLines(Path.Combine(Golden.RepoRoot, "tmp", "p2-exp.txt"), paths.SelectMany(p => new[] { "== " + p }.Concat(Expected(p))));
        File.WriteAllLines(Path.Combine(Golden.RepoRoot, "tmp", "p2-act.txt"), paths.SelectMany(p => new[] { "== " + p }.Concat(sections.GetValueOrDefault(p) ?? []))); 
    }
}
