using System.Text.RegularExpressions;

namespace Bayan.Tests;

/// <summary>
/// The 010 cross-file skeleton: every entry point <c>docs/specs/010-self-hosted-semantics/010-api.md</c>
/// indexes is declared, with exactly that signature, in its owner file under <c>src/semantics</c>.
/// </summary>
public sealed class SelfhostSemanticsApiTests
{
    private static readonly Regex Entry = new(@"^- (T\d+) (\S+\.byn): (.+?)  ← (\S+) (.+)$");

    [Fact]
    public void EveryIndexedEntryPointExists()
    {
        var index = Path.Combine(Golden.RepoRoot, "docs", "specs", "010-self-hosted-semantics", "010-api.md");
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
                files[file] = lines = Declarations(File.ReadAllLines(Path.Combine(SelfhostSemanticsHarness.SemanticsDir, file)));
            var signature = m.Groups[3].Value;
            if (!lines.Any(l => SignatureStarts(l.StartsWith("public ", StringComparison.Ordinal) ? l["public ".Length..] : l, signature)))
                missing.Add($"{m.Groups[1].Value} {file}: {signature}");
        }
        Assert.True(missing.Count == 0, $"not declared verbatim in the owner file:\n{string.Join('\n', missing)}");
    }

    /// <summary>
    /// <paramref name="lines"/> with each parameter list that `bayan format` wrapped one parameter per line (a line ending in
    /// <c>(</c>, then the parameters, then a line starting with <c>)</c>) joined back into one line, and a `uses` clause on the next line joined to it, as the index writes them.
    /// </summary>
    internal static string[] Declarations(string[] lines)
    {
        var result = new List<string>(lines.Length);
        for (var i = 0; i < lines.Length; i++)
        {
            var line = lines[i];
            var close = i + 1;
            if (line.EndsWith('(')) while (close < lines.Length && !lines[close].TrimStart().StartsWith(')')) close++;
            if (line.EndsWith('(') && close < lines.Length)
            {
                var parameters = lines[(i + 1)..close].Select(p => p.Trim().TrimEnd(','));
                line += string.Join(", ", parameters) + lines[close].TrimStart();
                i = close;
            }
            if (i + 1 < lines.Length && lines[i + 1].TrimStart().StartsWith("uses ", StringComparison.Ordinal))
                line += " " + lines[++i].TrimStart();
            result.Add(line);
        }
        return [.. result];
    }

    /// <summary>Whether <paramref name="line"/> begins with <paramref name="signature"/> and then ends or opens the body (an effect clause after a 010 signature is allowed).</summary>
    internal static bool SignatureStarts(string line, string signature)
    {
        if (!line.StartsWith(signature, StringComparison.Ordinal)) return false;
        var rest = line[signature.Length..];
        return rest.Length == 0 || rest.StartsWith(" =>", StringComparison.Ordinal) || rest.StartsWith(" {", StringComparison.Ordinal)
            || rest.StartsWith(" uses ", StringComparison.Ordinal);
    }
}
