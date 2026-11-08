using System.Text;
using Bayan.Lowering;
using Bayan.Semantics;
using Bayan.Semantics.Binding;
using Bayan.Syntax.Ast;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>A bound error expression implies a reported error; lowering one with none reported is an internal compiler error (Q1100).</summary>
public sealed class LoweringInvariantTests
{
    [Fact]
    public void AnErrorNodeReachingLoweringIsAnInternalCompilerError()
    {
        var e = Lowerer.CannotLower(new BoundErrorExpr(new BreakStmt(new TextSpan(0, 0), null)));
        Assert.IsType<InternalCompilerError>(e);
        Assert.StartsWith("internal compiler error:", e.Message);
    }

    [Fact]
    public void AnyOtherNodeIsOnlyUnlowerable()
    {
        var e = Lowerer.CannotLower(new BoundBlock(new BreakStmt(new TextSpan(0, 0), null), []));
        Assert.Equal("cannot lower BoundBlock", e.Message);
    }

    private static Compilation Compile() => Compilation.Create(
        [new SourceText("main.byn", Encoding.UTF8.GetBytes("struct A { i64 x = 1 }\nlet a = A {}\nprint($\"{a.x}\")\n"))], ".");

    [Fact]
    public void AnErrorNodeInAFieldDefaultFailsTheEntryCheck()
    {
        var c = Compile();
        Assert.False(c.Diagnostics.HasErrors);
        Lowerer.RequireNoErrorNodes(c);
        var field = c.Modules.SelectMany(m => m.Structs).First(s => s.Name == "A").Fields[0];
        field.Default = new BoundErrorExpr(field.Decl);
        Assert.Throws<InternalCompilerError>(() => Lowerer.Lower(c));
    }

    [Fact]
    public void AnErrorNodeInABodyFailsTheEntryCheck()
    {
        var c = Compile();
        var main = c.EntryModule.Main!;
        main.Body = new BoundBlock(main.Body!.Syntax, [.. main.Body.Statements, new BoundExprStmt(main.Body.Syntax, new BoundErrorExpr(main.Body.Syntax))]);
        var lookups = new CountingMutants();
        Assert.Throws<InternalCompilerError>(() => Lowerer.Lower(c, lookups));
        // Only the entry check throws before lowering looks at a node: lowering main alone reaches the error node after other statements.
        Assert.Equal(0, lookups.Lookups);
    }

    [Fact]
    public void AnErrorNodeInAStructInstanceDefaultFailsTheEntryCheck()
    {
        var c = Compilation.Create(
            [new SourceText("main.byn", Encoding.UTF8.GetBytes("struct B<T> { i64 x = 1 }\nlet b = B<i64> {}\nprint($\"{b.x}\")\n"))], ".");
        Assert.False(c.Diagnostics.HasErrors);
        Lowerer.RequireNoErrorNodes(c);
        var field = c.StructInstances.First(s => s.Name == "B").Fields[0];
        field.Default = new BoundErrorExpr(field.Decl);
        Assert.Throws<InternalCompilerError>(() => Lowerer.RequireNoErrorNodes(c));
    }

    /// <summary>A mutant table that is empty and counts how often lowering asks it about a node.</summary>
    private sealed class CountingMutants : IReadOnlyDictionary<BoundNode, BoundMutantSwitch>
    {
        public int Lookups { get; private set; }
        public bool TryGetValue(BoundNode key, out BoundMutantSwitch value) { Lookups++; value = null!; return false; }
        public BoundMutantSwitch this[BoundNode key] => throw new KeyNotFoundException();
        public IEnumerable<BoundNode> Keys => [];
        public IEnumerable<BoundMutantSwitch> Values => [];
        public int Count => 0;
        public bool ContainsKey(BoundNode key) => false;
        public IEnumerator<KeyValuePair<BoundNode, BoundMutantSwitch>> GetEnumerator() => Enumerable.Empty<KeyValuePair<BoundNode, BoundMutantSwitch>>().GetEnumerator();
        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
    }
}