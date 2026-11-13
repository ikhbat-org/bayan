using System.Diagnostics;

namespace Bayan.Tests;

/// <summary>Runs a process to its exit, sampling its working set every 100 ms (scaled); the peak is 0 when no sample was taken.</summary>
internal static class PeakSampler
{
    internal static (int Exit, string Out, string Err, long Peak) Run(ProcessStartInfo psi)
    {
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.UseShellExecute = false;
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        long peak = 0;
        while (!p.WaitForExit(TestTime.Scale(100)))
        {
            try
            {
                p.Refresh();
                peak = Math.Max(peak, Math.Max(p.WorkingSet64, p.PeakWorkingSet64));
            }
            catch (InvalidOperationException) { }
        }
        return (p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"), peak);
    }
}
