using System.Diagnostics;
using System.Text;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 022 T9: <c>bayan fix</c> of the stage-1 driver against the C# CLI, on the inputs of the FormatTests fix cases. Each case is laid out
/// twice under <c>tmp/t9-fix/</c>, once per CLI; the expected exit code, streams (with the case directory masked) and file bytes come from
/// the C# run. A file is fixed twice, as in <c>FixClearsItsLintAndIsIdempotent</c>.
/// </summary>
public sealed class SelfhostDriverFixTests
{
    private const string DoesNotFormat = "void main() {\n    let x = 1\n    if x == 1 || x == 2 { print(\"y\") }\n    let ok  =  true\n    print($\"{ok}\")\n}\n";

    private const string NamedTwice = "// ── Helpers ──────\nbool f(i32 x) {\n    return x == 1 || x == 2\n}\n";

    private const string Unparsable = "void f(bool c) {\n    if c { return }\n    let x = (1 +\n}\n";

    public static TheoryData<string, string> Cases() => new()
    {
        // FixClearsItsLintAndIsIdempotent, FixKeepsTheSameC: a diag case as `main.byn`, fixed through its directory.
        { "diag", "style-sections-banner" },
        { "diag", "style-conditions-patterns" },
        { "diag", "style-literals-empty" },
        { "diag", "style-optionals-bind" },
        { "diag", "style-guards-postfix" },
        { "diag", "style-lambdas-it" },
        // FixKeepsAComment.
        { "diag", "style-fix-keeps-comments" },
        { "diag", "style-fix-keeps-line-comments" },
        // FixGivesTheFixedRunCase: a run case, fixed as a file.
        { "run", "style-fix-conditions-patterns" },
        { "run", "style-fix-optionals-bind" },
        { "run", "style-fix-literals-empty" },
        { "run", "style-fix-sections-banner" },
        // FixDoesNotFormat.
        { "text", "no-format" },
        // FixNamesAFileOnce: the directory, named twice.
        { "twice", "named-twice" },
        // FixRefusesAFileThatDoesNotParse.
        { "unparsable", "parse-error" },
        // FixMissingPathExitsTwo.
        { "missing", "nope.byn" },
    };

    private static string Layout(string kind, string name, string side)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t9-fix", side, kind + "-" + name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, "main.byn");
        switch (kind)
        {
            case "diag": File.Copy(Path.Combine(Golden.CasesRoot, "diag", name + ".byn"), file); return dir;
            case "run": File.Copy(Path.Combine(Golden.CasesRoot, "run", name + ".byn"), file); return file;
            case "text": File.WriteAllText(file, DoesNotFormat); return dir;
            case "twice": File.WriteAllText(file, NamedTwice); return dir;
            case "unparsable": File.WriteAllText(file, Unparsable); return dir;
            default: return Path.Combine(dir, name);
        }
    }

    private static (int Exit, string Out, string Err) Start(string program, string[] prefix, params string[] args)
    {
        var psi = new ProcessStartInfo(program)
        {
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            StandardOutputEncoding = Encoding.UTF8,
            RedirectStandardError = true,
            StandardErrorEncoding = Encoding.UTF8,
            UseShellExecute = false,
            WorkingDirectory = Golden.RepoRoot,
        };
        foreach (var a in prefix) psi.ArgumentList.Add(a);
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        p.StandardInput.Close();
        var stdout = p.StandardOutput.ReadToEndLfAsync();
        var stderr = p.StandardError.ReadToEndLfAsync();
        var waitMs = TestTime.Scale(300_000);
        if (!p.WaitForExit(waitMs))
        {
            p.Kill();
            Assert.Fail($"{program} {string.Join(' ', args)}: timed out after {waitMs} ms");
        }
        return (p.ExitCode, stdout.Result, stderr.Result);
    }

    [Fact]
    public void CoversTheFormatTestsFixInputs() => Assert.Equal(16, Cases().Count);

    [Theory]
    [MemberData(nameof(Cases))]
    public void FixAsCSharpCli(string kind, string name) => Compare(kind, name, "selfhost", SelfhostDriverHarness.Build());

    /// <summary>The same rows through stage 2, the bootstrap-built <c>bayan</c>.</summary>
    [Theory]
    [MemberData(nameof(Cases))]
    public void FixAsStage2(string kind, string name) => Compare(kind, name, "stage2", BootstrapTests.Stage2Executable());

    private static void Compare(string kind, string name, string side, string program)
    {
        var expectedPath = Layout(kind, name, "cs-" + side);
        var actualPath = Layout(kind, name, side);
        var expectedDir = kind == "run" || kind == "missing" ? Path.GetDirectoryName(expectedPath)! : expectedPath;
        var actualDir = kind == "run" || kind == "missing" ? Path.GetDirectoryName(actualPath)! : actualPath;
        string[] Args(string path) => kind == "twice" ? ["fix", path, Path.Combine(path, ".")] : ["fix", path];
        for (var pass = 1; pass <= 2; pass++)
        {
            var expected = Start("dotnet", [typeof(CliApp).Assembly.Location], Args(expectedPath));
            var actual = Start(program, [], Args(actualPath));
            Assert.Equal(expected.Exit, actual.Exit);
            SelfhostEmitterHarness.AssertSame($"stdout of fix pass {pass} on {kind}/{name}", expected.Out.Replace(expectedDir, "<dir>"), actual.Out.Replace(actualDir, "<dir>"));
            SelfhostEmitterHarness.AssertSame($"stderr of fix pass {pass} on {kind}/{name}", expected.Err.Replace(expectedDir, "<dir>"), actual.Err.Replace(actualDir, "<dir>"));
            var expectedFile = Path.Combine(expectedDir, "main.byn");
            if (File.Exists(expectedFile))
                Assert.Equal(File.ReadAllBytes(expectedFile), File.ReadAllBytes(Path.Combine(actualDir, "main.byn")));
        }
    }
}
