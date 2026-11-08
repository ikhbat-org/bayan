using System.Diagnostics;
using System.Text;
using Bayan.Semantics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>Region analysis computes each <c>ref this</c> method's changed fields once, not once per call path.</summary>
[Collection(nameof(PerfBounds))]
public sealed class RegionAnalysisPerfTests
{
    [Fact]
    public void TwoHundredMethodsCallingEachOtherCheckQuickly()
    {
        const int count = 200;
        var src = new StringBuilder("struct P {\n    List<i64> xs\n    i64 n\n\n");
        for (var i = 0; i < count; i++)
        {
            src.Append($"    void m{i}(ref this) {{\n        n += 1\n");
            for (var j = 1; j <= 10 && i + j < count; j++)
                src.Append($"        if n > {j} {{ m{i + j}() }}\n");
            src.Append("    }\n");
        }
        src.Append("}\n\nvoid main() {\n    var p = P { xs: List<i64>(), n: 0 }\n    p.m0()\n}\n");
        // Wall clock, minimum of 3 runs, in the serial PerfBounds collection: the minimum drops a one-off stall, and no other class runs meanwhile. No reference workload or CPU-time measure: neither is cheap here, and process CPU time also counts the test host's other threads.
        var bound = TimeSpan.FromSeconds(5);
        var times = new TimeSpan[3];
        for (var run = 0; run < times.Length; run++)
        {
            var watch = Stopwatch.StartNew();
            var c = Compilation.Create([new SourceText("perf.byn", Encoding.UTF8.GetBytes(src.ToString()))], ".");
            watch.Stop();
            times[run] = watch.Elapsed;
            Assert.DoesNotContain(c.Diagnostics.Items, d => d.IsError);
        }
        Assert.True(times.Min() < bound, $"took {string.Join(", ", times)} (bound {bound})");
    }
}

/// <summary>Serial collection for the wall-clock perf bounds, so no other test class loads the machine while they time.</summary>
[CollectionDefinition(nameof(PerfBounds), DisableParallelization = true)]
public sealed class PerfBounds;
