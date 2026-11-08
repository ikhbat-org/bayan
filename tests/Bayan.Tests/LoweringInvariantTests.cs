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
        Assert.Throws<InternalCompilerError>(() => Lowerer.Lower(c));
    }
}
