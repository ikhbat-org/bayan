using System.Diagnostics;

namespace Bayan.Tests;

public sealed class PeakSamplerTests
{
    // ci run 43572300146 (macOS): doctor exited before the first scaled 300 ms wait, so no sample was taken.
    [Fact]
    public void AProcessShorterThanTheOldFirstWaitIsSampled()
    {
        var psi = OperatingSystem.IsWindows()
            ? new ProcessStartInfo("powershell", "-NoProfile -Command Start-Sleep -Milliseconds 80")
            : new ProcessStartInfo("/bin/sleep", "0.08");
        var (exit, _, _, peak) = PeakSampler.Run(psi);
        Assert.Equal(0, exit);
        Assert.True(peak > 0, "no working-set sample was taken");
    }
}
