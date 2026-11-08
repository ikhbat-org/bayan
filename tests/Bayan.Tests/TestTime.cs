using System.Globalization;

namespace Bayan.Tests;

/// <summary>Multiplies the tests' fixed timeouts by <c>$BAYAN_TEST_TIME_SCALE</c> (a positive number; 1 when unset or invalid), so a loaded machine or CI can ask for more time.</summary>
internal static class TestTime
{
    internal static double Factor => Parse(Environment.GetEnvironmentVariable("BAYAN_TEST_TIME_SCALE"));

    internal static double Parse(string? text) =>
        double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var f) && double.IsFinite(f) && f > 0 ? f : 1;

    internal static int Scale(int ms) => (int)Math.Min(int.MaxValue, Math.Ceiling(ms * Factor));

    internal static TimeSpan Scale(TimeSpan span) => span * Factor;
}
