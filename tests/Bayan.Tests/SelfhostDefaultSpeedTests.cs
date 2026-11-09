using System.Diagnostics;
using Bayan.Backend.C;
using Bayan.Cli;
using Xunit.Abstractions;

namespace Bayan.Tests;

/// <summary>
/// 017 T15 (R6): stage 2 (the self-hosted <c>bayan</c> built by stage 1 in <see cref="BootstrapTests"/>) builds
/// <c>selfhost/driver</c> with <c>build --mode safe --package selfhost selfhost/driver -o &lt;tmp out&gt;</c> no slower than
/// 2 times <see cref="CliApp.Run"/> in-process on the same argv, each run with a fresh empty <c>BAYAN_CACHE</c> under <c>tmp/</c>.
/// Median of 3 runs per side when <c>BAYAN_LAW_TIER</c> is <c>full</c>, 1 run per side otherwise.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDefaultSpeedTests(ITestOutputHelper output)
{
    private const double Bound = 2;

    private static bool Full => Environment.GetEnvironmentVariable("BAYAN_LAW_TIER") == "full";

    private static int Runs => Full ? 3 : 1;

    private static double Median(List<double> times) => times.Order().ElementAt(times.Count / 2);

    private static void Reset(string dir)
    {
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
    }

    [Fact]
    public void Stage2BuildsDriverWithinTwoTimesCliAppRun()
    {
        if (Environment.GetEnvironmentVariable("BAYAN_SKIP_TIMING") == "1") return;
        var stage2 = BootstrapTests.Stage2Executable();
        var root = Path.Combine(Golden.RepoRoot, "tmp", "default-speed");
        var outDir = Path.Combine(root, "out");
        var outPath = Path.Combine("tmp", "default-speed", "out", Targets.ExecutableName("bayan", Targets.Host ?? ""));
        string[] args = ["build", "--mode", "safe", "--package", "selfhost", "selfhost/driver", "-o", outPath];

        var savedCwd = Environment.CurrentDirectory;
        var savedCache = Environment.GetEnvironmentVariable("BAYAN_CACHE");
        var csharp = new List<double>();
        var selfhost = new List<double>();
        try
        {
            Environment.CurrentDirectory = Golden.RepoRoot;
            for (var i = 0; i < Runs; i++)
            {
                Reset(outDir);
                var csCache = Path.Combine(root, $"cache-cs-{i}");
                Reset(csCache);
                Environment.SetEnvironmentVariable("BAYAN_CACHE", csCache);
                var stdout = new StringWriter();
                var stderr = new StringWriter();
                var clock = Stopwatch.StartNew();
                var exit = CliApp.Run(args, stdout, stderr);
                csharp.Add(clock.Elapsed.TotalSeconds);
                Assert.True(exit == 0, $"CliApp.Run exited {exit}\n{stderr}");
                Assert.DoesNotContain("from cache", stdout.ToString(), StringComparison.Ordinal);

                Reset(outDir);
                var s2Cache = Path.Combine(root, $"cache-stage2-{i}");
                Reset(s2Cache);
                Environment.SetEnvironmentVariable("BAYAN_CACHE", s2Cache);
                clock.Restart();
                var (code, s2Out, err) = SelfhostParserTests.Run(stage2, args);
                selfhost.Add(clock.Elapsed.TotalSeconds);
                Assert.True(code == 0, $"stage 2 exited {code}\n{err}");
                Assert.DoesNotContain("from cache", s2Out, StringComparison.Ordinal);
            }
        }
        finally
        {
            Environment.CurrentDirectory = savedCwd;
            Environment.SetEnvironmentVariable("BAYAN_CACHE", savedCache);
        }

        var (csharpSeconds, stage2Seconds) = (Median(csharp), Median(selfhost));
        output.WriteLine($"CliApp.Run {csharpSeconds:F2} s, stage 2 {stage2Seconds:F2} s, ratio {stage2Seconds / csharpSeconds:F2}");
        Assert.True(stage2Seconds <= Bound * csharpSeconds, $"stage 2 takes {stage2Seconds:F2} s, more than {Bound}x CliApp.Run's {csharpSeconds:F2} s");
    }
}
