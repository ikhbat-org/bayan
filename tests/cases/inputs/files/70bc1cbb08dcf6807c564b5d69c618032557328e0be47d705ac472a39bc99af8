using System.Text.RegularExpressions;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// The 012 cross-file skeleton: every entry point <c>docs/specs/012-self-hosted-bootstrap/012-api.md</c> indexes is
/// declared, with exactly that signature, in its owner file under <c>src/</c>.
/// </summary>
public sealed class SelfhostDriverApiTests
{
    private static readonly Regex Entry = new(@"^- (T\d+) (\S+\.byn): (.+?)  ← (\S+) (.+)$");

    [Fact]
    public void EveryIndexedEntryPointExists()
    {
        var index = Path.Combine(Golden.RepoRoot, "docs", "specs", "012-self-hosted-bootstrap", "012-api.md");
        var entries = File.ReadLines(index).Where(l => l.StartsWith("- T", StringComparison.Ordinal)).ToList();
        Assert.NotEmpty(entries);
        var files = new Dictionary<string, string[]>(StringComparer.Ordinal);
        var missing = new List<string>();
        foreach (var line in entries)
        {
            var m = Entry.Match(line);
            Assert.True(m.Success, $"malformed index line: {line}");
            var file = m.Groups[2].Value;
            if (!files.TryGetValue(file, out var lines))
                files[file] = lines = File.ReadAllLines(Path.Combine(SelfhostSemanticsHarness.SelfhostDir, file));
            var signature = m.Groups[3].Value;
            if (!lines.Any(l => SelfhostSemanticsApiTests.SignatureStarts(l.StartsWith("public ", StringComparison.Ordinal) ? l["public ".Length..] : l, signature)))
                missing.Add($"{m.Groups[1].Value} {file}: {signature}");
        }
        Assert.True(missing.Count == 0, $"not declared verbatim in its file:\n{string.Join('\n', missing)}");
    }

    [Fact]
    public void VersionConstantIsTheCompilersVersion()
    {
        var main = File.ReadAllText(Path.Combine(SelfhostDriverHarness.DriverDir, "main.byn"));
        var version = Regex.Match(main, @"^const version: string = ""([^""]+)""$", RegexOptions.Multiline).Groups[1].Value;
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["--version"], stdout, stderr));
        // spec 019 R10: the C# version line, its parenthesised part masked as SelfhostDriverT1Tests does
        if (SelfhostExport.Cli(["--version"], CliApp.ExitOk, Regex.Replace(stdout.ToString().ReplaceLineEndings("\n"), @"^(bayan \S+) \(.*\)$", "$1 (masked)", RegexOptions.Multiline),
            stderr.ToString().ReplaceLineEndings("\n"), extra: new Dictionary<string, string> { ["compare"] = "version-masked\n" })) return;
        Assert.StartsWith($"bayan {version} (", stdout.ToString());
    }
}
