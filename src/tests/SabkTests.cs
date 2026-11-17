using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

namespace Bayan.Tests;

/// <summary>
/// 024 T12 (R3, R9): the sabk tests run through the bootstrap stage-2 driver, and the recorded reference files are re-recorded and compared byte for byte.
/// Arm64 macOS only: the recorders need <c>zig cc</c>, <c>clang</c>, <c>otool</c> and <c>nm</c> on that host.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]  // BootstrapTests.Stage2Executable builds the stages
public sealed class SabkTests
{
    private static bool Supported => RuntimeInformation.IsOSPlatform(OSPlatform.OSX) && RuntimeInformation.OSArchitecture == Architecture.Arm64;

    private const string Skip = "sabk tests need arm64 macOS (024 R9)";

    private static (int Exit, string Out, string Err) RunInRoot(string program, params string[] args)
    {
        var psi = new ProcessStartInfo(program) { WorkingDirectory = Golden.RepoRoot, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result, stderr.Result);
    }

    [Fact]
    public void SabkSourceTestsPass()
    {
        if (!Supported) { Console.WriteLine(Skip); return; }
        var (exit, o, e) = RunInRoot(BootstrapTests.Stage2Executable(), "test", "--package", "src", "src/sabk");
        var passed = Regex.Match(o, @"◆ (\d+) passed");
        var failed = Regex.Match(o, @"✗ (\d+) failed");
        Assert.True(passed.Success, $"no pass count in the summary (exit {exit}):\n{o}\n{e}");
        Assert.True(int.Parse(passed.Groups[1].Value) > 0, $"no sabk test passed:\n{o}\n{e}");
        Assert.False(failed.Success && int.Parse(failed.Groups[1].Value) > 0, $"sabk tests failed:\n{o}\n{e}");
        Assert.Equal(0, exit);
    }

    [Fact]
    public void RecordedReferenceFilesAreCurrent()
    {
        if (!Supported) { Console.WriteLine(Skip); return; }
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "sabk");
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        foreach (var (script, input, tracked) in new[]
        {
            ("record-encodings.sh", "encodings.s", "encodings.tsv"),
            ("record-macho.sh", "macho.s", "macho-expected.txt"),
        })
        {
            var data = Path.Combine(Golden.RepoRoot, "src", "sabk", "testdata");
            var actual = Path.Combine(dir, tracked);
            var (exit, o, e) = RunInRoot("bash", Path.Combine(Golden.RepoRoot, "scripts", "sabk", script), Path.Combine(data, input), actual);
            Assert.True(exit == 0, $"{script} failed (exit {exit}):\n{o}\n{e}");
            Assert.True(File.ReadAllBytes(Path.Combine(data, tracked)).AsSpan().SequenceEqual(File.ReadAllBytes(actual)), $"{tracked} differs from what {script} records; re-run the script");
        }
    }
}
