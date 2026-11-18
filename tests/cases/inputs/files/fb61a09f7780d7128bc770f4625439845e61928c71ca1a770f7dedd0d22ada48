using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.RegularExpressions;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 022 T9: the style lints at the severities of a manifest's <c>lints</c>, through <c>check .</c> of the stage-1 driver against the C# CLI.
/// <c>CheckAsCliApp</c> checks a folder case's <c>main.byn</c> as a file (its <c>package.byn</c> is then a module, BYN1012 on both
/// sides) and <c>DiagAsCSharpCli</c> passes <c>--package</c>, which reads no manifest; only the project branch reads <c>lints</c>. So each
/// <c>style-severity-*</c> and <c>style-functions-length-*</c> folder case is laid out as a project, <c>package.byn</c> and
/// <c>src/app/main.byn</c>, under <c>tmp/t9/</c>. The expected exit code and streams come from the C# CLI run on the same directory.
/// </summary>
public sealed class SelfhostDriverStyleLintsTests
{
    private static string Mask(string text) => Regex.Replace(text, @" in \d+\.\d\ds", " in masked");

    public static TheoryData<string> Cases()
    {
        var data = new TheoryData<string>();
        foreach (var name in Golden.Cases("diag").Cast<object[]>().Select(r => (string)r[0]))
        {
            var folder = name.Split('/') is ["diag", var f, "main.byn"] ? f : null;
            if (folder is not null && (folder.StartsWith("style-severity-", StringComparison.Ordinal) || folder.StartsWith("style-functions-length-", StringComparison.Ordinal)))
                data.Add(folder);
        }
        return data;
    }

    private static string Project(string folder)
    {
        var source = Path.Combine(Golden.CasesRoot, "diag", folder);
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t9", folder);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(Path.Combine(dir, "src", "app"));
        File.Copy(Path.Combine(source, "package.byn"), Path.Combine(dir, "package.byn"));
        File.Copy(Path.Combine(source, "main.byn"), Path.Combine(dir, "src", "app", "main.byn"));
        return dir;
    }

    private static (int Exit, string Out, string Err) Start(string program, string[] prefix, string cwd, params string[] args)
    {
        var psi = new ProcessStartInfo(program)
        {
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            StandardOutputEncoding = Encoding.UTF8,
            RedirectStandardError = true,
            StandardErrorEncoding = Encoding.UTF8,
            UseShellExecute = false,
            WorkingDirectory = cwd,
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
    public void CoversTheFolderCases() => Assert.Equal(6, Cases().Count);

    [Theory]
    [MemberData(nameof(Cases))]
    public void CheckProjectAsCSharpCli(string folder) => Compare(folder, SelfhostDriverHarness.Build());

    /// <summary>The same rows through stage 2, the bootstrap-built <c>bayan</c>.</summary>
    [Theory]
    [MemberData(nameof(Cases))]
    public void CheckProjectAsStage2(string folder) => Compare(folder, BootstrapTests.Stage2Executable());

    private static void Compare(string folder, string program, [CallerMemberName] string test = "")
    {
        var dir = Project(folder);
        var expected = Start("dotnet", [typeof(CliApp).Assembly.Location], dir, "check", ".");
        // spec 019 R10: the C# run with the project as input/, the seconds masked
        if (SelfhostExport.Cli(["check", "."], expected.Exit, Mask(expected.Out), Mask(expected.Err), [dir],
            new Dictionary<string, string> { ["compare"] = "seconds-masked\n" }, test: test)) return;
        var actual = Start(program, [], dir, "check", ".");
        Assert.Equal(expected.Exit, actual.Exit);
        SelfhostEmitterHarness.AssertSame($"stdout of `check .` in {folder}", Mask(expected.Out), Mask(actual.Out));
        SelfhostEmitterHarness.AssertSame($"stderr of `check .` in {folder}", Mask(expected.Err), Mask(actual.Err));
    }
}
