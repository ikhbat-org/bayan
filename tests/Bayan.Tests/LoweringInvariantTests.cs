using Bayan.Lowering;
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
}
