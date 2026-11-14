using System.Diagnostics;

namespace Bayan.Tests;

/// <summary>Runs a process to its exit, sampling its working set at start and then every <see cref="IntervalMs"/>; the peak is 0
/// when no sample was taken. The interval is not scaled by <see cref="TestTime"/>: a slower host needs samples at least as often,
/// and a 100 ms (300 ms on CI) first wait missed a <c>doctor</c> run that exited sooner on a fast macOS runner.</summary>
internal static class PeakSampler
{
    internal const int IntervalMs = 10;

    internal static (int Exit, string Out, string Err, long Peak) Run(ProcessStartInfo psi)
    {
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.UseShellExecute = false;
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        long peak = 0;
        do
        {
            try
            {
                p.Refresh();
                peak = Math.Max(peak, Math.Max(p.WorkingSet64, p.PeakWorkingSet64));
            }
            catch (InvalidOperationException) { }
        }
        while (!p.WaitForExit(IntervalMs));
        return (p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"), peak);
    }
}
