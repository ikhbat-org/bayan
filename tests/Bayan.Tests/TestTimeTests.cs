namespace Bayan.Tests;

[Collection(nameof(ToolchainEnvironment))]
public sealed class TestTimeTests
{
    [Fact]
    public void AnUnsetScaleIsOne() => Assert.Equal(1, TestTime.Parse(null));

    [Fact]
    public void ASetScaleMultipliesMillisecondsAndSpans()
    {
        Assert.Equal(2.5, TestTime.Parse("2.5"));
        var saved = Environment.GetEnvironmentVariable("BAYAN_TEST_TIME_SCALE");
        Environment.SetEnvironmentVariable("BAYAN_TEST_TIME_SCALE", "2.5");
        try
        {
            Assert.Equal(1000, TestTime.Scale(400));
            Assert.Equal(TimeSpan.FromSeconds(5), TestTime.Scale(TimeSpan.FromSeconds(2)));
        }
        finally
        {
            Environment.SetEnvironmentVariable("BAYAN_TEST_TIME_SCALE", saved);
        }
    }

    [Fact]
    public void AHugeScaleIsCapped()
    {
        var saved = Environment.GetEnvironmentVariable("BAYAN_TEST_TIME_SCALE");
        Environment.SetEnvironmentVariable("BAYAN_TEST_TIME_SCALE", "1e12");
        try
        {
            Assert.Equal(TimeSpan.FromMilliseconds(int.MaxValue), TestTime.Scale(TimeSpan.FromMinutes(10)));
            Assert.Equal(int.MaxValue, TestTime.Scale(500));
        }
        finally
        {
            Environment.SetEnvironmentVariable("BAYAN_TEST_TIME_SCALE", saved);
        }
    }

    [Theory]
    [InlineData("")]
    [InlineData("abc")]
    [InlineData("0")]
    [InlineData("-3")]
    [InlineData("NaN")]
    [InlineData("Infinity")]
    public void AnInvalidScaleIsOne(string text) => Assert.Equal(1, TestTime.Parse(text));
}
