using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>Spec 022 R7: the style lints are <c>bayan check</c> output, at the severity of <c>lints</c> in <c>package.byn</c>.</summary>
public sealed class StyleLintSeverityTests
{
    private const string Guard = "union error CartError {\n    empty\n}\n\nvoid check(List<i32> lines) fails CartError {\n    if lines.isEmpty {\n        fail .empty\n    }\n}\n\n"
        + "void main() fails CartError {\n    let lines: List<i32> = [1]\n    try check(lines)\n}\n";

    private static string Project(string name, string lints, string source)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "style-lints", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(Path.Combine(dir, "src", "app"));
        File.WriteAllText(Path.Combine(dir, "package.byn"), "Package {\n    name: \"local/style\",\n    version: \"0.1.0\",\n" + (lints.Length == 0 ? "" : $"    style: Style {{\n        lints: [{lints}],\n    }},\n") + "}\n");
        File.WriteAllText(Path.Combine(dir, "src", "app", "main.byn"), source);
        return dir;
    }

    private static (int Exit, string Out, string Err) Run(params string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString(), stderr.ToString());
    }

    [Fact]
    public void ErrorFailsCheck()
    {
        var (exit, _, err) = Run("check", Project("error", "\"guards.postfix\": .error", Guard));
        Assert.Equal(1, exit);
        Assert.Contains("error BYN1072", err);
    }

    [Fact]
    public void NoneIsSilent()
    {
        var (exit, _, err) = Run("check", Project("none", "\"guards.postfix\": .none", Guard));
        Assert.Equal(0, exit);
        Assert.DoesNotContain("BYN1072", err);
    }

    [Fact]
    public void WarningAndSuggestionPass()
    {
        var (exit, _, err) = Run("check", Project("warning", "\"guards.postfix\": .warning", Guard));
        Assert.Equal(0, exit);
        Assert.Contains("warning BYN1072", err);
        (exit, _, err) = Run("check", Project("suggestion", "", Guard));
        Assert.Equal(0, exit);
        Assert.Contains("note BYN1072", err);
    }

    [Fact]
    public void BuildRunAndTestDoNotReportThem()
    {
        var dir = Project("build", "\"guards.postfix\": .error", Guard);
        var (exit, _, err) = Run("build", dir, "--emit-c");
        Assert.Equal(0, exit);
        Assert.DoesNotContain("BYN1072", err);
        (exit, _, err) = Run("test", dir);
        Assert.DoesNotContain("BYN1072", err);
    }

    [Fact]
    public void FunctionsLengthIsOffByDefaultAndOnAtWarning()
    {
        var body = string.Concat(Enumerable.Range(1, 61).Select(i => $"    print(\"step {i}\")\n"));
        var source = "void main() {\n" + body + "}\n";
        Assert.DoesNotContain("BYN1076", Run("check", Project("length-off", "", source)).Err);
        var (exit, _, err) = Run("check", Project("length-on", "\"functions.length\": .warning", source));
        Assert.Equal(0, exit);
        Assert.Contains("warning BYN1076", err);
    }
}
