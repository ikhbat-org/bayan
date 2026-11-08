using System.Diagnostics;
using System.Text;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;
using Xunit.Abstractions;

namespace Bayan.Tests;

/// <summary>
/// <c>lexer.firstIsUpper</c> / <c>lexer.firstIsLower</c> (Q1142), driven by a test <c>main</c>. The expected lines are what the
/// C# parser computes with <c>char.IsUpper(s[0])</c> / <c>char.IsLower(s[0])</c> on the same strings.
/// </summary>
public sealed class SelfhostLexerCaseTests(ITestOutputHelper output)
{
    private static readonly string[] Inputs =
    [
        "", "A", "Z", "a", "z", "Å", "Å", "Ω", "ω", "ǅ", "_", "7", "\U0001D400", "\U0001D41A", "Äx", "Δx",
    ];

    [Fact]
    public async Task FirstScalarCaseMatchesCSharpCharIsUpperAndIsLower()
    {
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var selfhost = Path.Combine(Golden.RepoRoot, "selfhost");
        var program = new StringBuilder("import lexer\n\nvoid main() {\n");
        foreach (var s in Inputs)
            program.Append($"    print($\"{{lexer.firstIsUpper(\"{s}\".bytes)}} {{lexer.firstIsLower(\"{s}\".bytes)}}\")\n");
        program.Append("}\n");
        var c = Compilation.Create([SourceText.FromString(Path.Combine(selfhost, "t-case.byn"), program.ToString())], packageRoot: selfhost);
        if (c.Diagnostics.HasErrors) Assert.Fail($"did not build:\n{DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true)}");
        var build = Toolchain.Build(CliApp.EmitC(c, BuildMode.Fast), BuildMode.Fast);
        if (!build.Succeeded) Assert.Fail($"did not build:\n{build.Errors}");
        var psi = new ProcessStartInfo(build.ExecutablePath!) { RedirectStandardOutput = true, StandardOutputEncoding = Encoding.UTF8, UseShellExecute = false };
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndLfAsync();
        var text = await stdout;
        await p.WaitForExitAsync();
        output.WriteLine(text);
        Assert.Equal(0, p.ExitCode);
        var expected = string.Concat(Inputs.Select(s => $"{(s.Length > 0 && char.IsUpper(s[0]) ? "true" : "false")} {(s.Length > 0 && char.IsLower(s[0]) ? "true" : "false")}\n"));
        Assert.Equal(expected, text);
    }
}
