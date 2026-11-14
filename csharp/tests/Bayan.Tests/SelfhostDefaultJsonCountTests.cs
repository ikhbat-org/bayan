using System.Diagnostics;
using System.Text.RegularExpressions;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// 017 R1 (Q1267): <c>bayan test lib/std/json</c> passes as many tests under the stage-2 driver as under the C# CLI. Both counts
/// are read from the two runs' summary lines, never typed, so the spec states "the same count" and no number.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Snapshot", "skip")]  // runs a child process with its own BAYAN_CACHE, which RunRecorded/replay.py cannot replay
public sealed class SelfhostDefaultJsonCountTests
{
    private static string PassCount(bool driver)
    {
        var cache = Path.Combine(Golden.RepoRoot, "tmp", "json-count", driver ? "stage2" : "cs");
        TestDirs.Delete(cache);
        Directory.CreateDirectory(cache);
        var psi = new ProcessStartInfo(driver ? SelfhostDriverHarness.Build() : "dotnet") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, WorkingDirectory = Golden.RepoRoot };
        if (!driver) psi.ArgumentList.Add(typeof(CliApp).Assembly.Location);
        psi.Environment["BAYAN_CACHE"] = cache;
        psi.Environment.Remove("BAYAN_CC");
        psi.ArgumentList.Add("test");
        psi.ArgumentList.Add("lib/std/json");
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        var text = stdout.Result + stderr.Result;
        Assert.True(p.ExitCode == 0, $"{(driver ? "stage 2" : "C#")} bayan test lib/std/json exited {p.ExitCode}: {text}");
        var match = Regex.Match(text, @"(\d+) passed");
        Assert.True(match.Success, $"no 'N passed' line from {(driver ? "stage 2" : "the C# CLI")}: {text}");
        return match.Groups[1].Value;
    }

    [Fact]
    public void Stage2PassesAsManyJsonTestsAsTheCsCli()
    {
        var expected = PassCount(driver: false);
        Assert.NotEqual("0", expected);
        Assert.Equal(expected, PassCount(driver: true));
    }
}
