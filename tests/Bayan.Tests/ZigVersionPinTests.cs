using System.Diagnostics;
using System.Text.RegularExpressions;
using Xunit;

namespace Bayan.Tests;

/// <summary>`.zig-version` pins the zig every host and CI job uses: the workflows install it, and a host whose zig differs fails here.</summary>
public sealed class ZigVersionPinTests
{
    private static string Pinned => File.ReadAllText(Path.Combine(Golden.RepoRoot, ".zig-version")).Trim();

    [Fact]
    public void PinIsAVersionNumber() => Assert.Matches(@"^\d+\.\d+\.\d+$", Pinned);

    [Theory]
    [InlineData("ci.yml")]
    [InlineData("mutation.yml")]
    public void WorkflowsInstallThePinnedZig(string workflow)
    {
        var text = File.ReadAllText(Path.Combine(Golden.RepoRoot, ".github", "workflows", workflow));
        Assert.Contains("bash scripts/ci/install-zig.sh", text);
        Assert.DoesNotContain("setup-zig", text);
    }

    [Fact]
    public void InstallScriptHoldsThePinnedSums()
    {
        var script = File.ReadAllText(Path.Combine(Golden.RepoRoot, "scripts", "ci", "install-zig.sh"));
        Assert.Equal(Pinned, Regex.Match(script, @"(?m)^sums_for=(\S+)").Groups[1].Value);
    }

    [Fact]
    public void HostZigIsThePinnedZig()
    {
        var zig = Bayan.Backend.C.Toolchain.FindOnPath("zig");
        Assert.True(zig is not null, $"expected zig {Pinned} (.zig-version), found no zig on PATH; install it with scripts/ci/install-zig.sh DEST");
        using var p = Process.Start(new ProcessStartInfo(zig!, "version") { RedirectStandardOutput = true, RedirectStandardError = true })!;
        var version = p.StandardOutput.ReadToEnd().Trim();
        p.WaitForExit();
        Assert.True(Pinned == version, PinMessage(Pinned, version, zig!));
    }

    [Fact]
    public void AMismatchNamesBothVersionsAndThePath() =>
        Assert.Equal("expected zig 0.17.0 (.zig-version), found 0.17.1 at /opt/homebrew/bin/zig; install 0.17.0 with scripts/ci/install-zig.sh DEST and put it first on PATH",
            PinMessage("0.17.0", "0.17.1", "/opt/homebrew/bin/zig"));

    private static string PinMessage(string pinned, string found, string path) =>
        $"expected zig {pinned} (.zig-version), found {found} at {path}; install {pinned} with scripts/ci/install-zig.sh DEST and put it first on PATH";
}
