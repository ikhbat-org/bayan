using System.Text.RegularExpressions;

namespace Bayan.Tests;

/// <summary>
/// Mutation recording (<c>scripts/selfhost/mutate-batch.sh</c>) runs the driver family under <c>BAYAN_SNAPSHOT</c> with
/// <c>Snapshot!=skip</c>. These classes run their binaries in a way <c>replay.py</c> cannot replay (cwd, env, tree
/// changes), so a recorded build with no replayable run fails mutant 0 (review 233d35d finding 7).
/// </summary>
public sealed class SnapshotSkipTraitTests
{
    public static TheoryData<Type> Unreplayable => [typeof(SelfhostDefaultT3Tests), typeof(SelfhostDefaultT4Tests), typeof(SelfhostDefaultT9Tests)];

    [Theory]
    [MemberData(nameof(Unreplayable))]
    public void IsSkippedBySnapshotRecording(Type type)
    {
        var traits = type.GetCustomAttributesData().Where(a => a.AttributeType == typeof(TraitAttribute))
            .Select(a => (Name: a.ConstructorArguments[0].Value as string, Value: a.ConstructorArguments[1].Value as string));
        Assert.Contains(("Snapshot", "skip"), traits);
    }

    /// <summary>
    /// Single tests that cannot record: <c>format</c> rewrites its input in place, so two recorded runs differ; <c>--time</c>
    /// prints timings; a 1 ms bound is skipped under a snapshot, so no kill is seen. Each failed every emitter or driver
    /// file of the 2026-11-09 nightly at recording.
    /// </summary>
    public static TheoryData<Type, string> UnreplayableMethods => new()
    {
        { typeof(SelfhostDriverT1Tests), nameof(SelfhostDriverT1Tests.FormatAsCliApp) },
        { typeof(SelfhostEmitterSpeedTests), nameof(SelfhostEmitterSpeedTests.OneMegabyteLowerAndEmitWithinTenTimes) },
        { typeof(SelfhostEmitterNoPanicLawTests), nameof(SelfhostEmitterNoPanicLawTests.ARunPastItsBoundIsKilledAndNamed) },
        { typeof(SelfhostEmitterHarnessTests), nameof(SelfhostEmitterHarnessTests.CleanInputsExitLikeBuild) },
        { typeof(SelfhostParserTests), nameof(SelfhostParserTests.OneMegabyteWithinTenTimes) },
    };

    [Theory]
    [MemberData(nameof(UnreplayableMethods))]
    public void MethodIsSkippedBySnapshotRecording(Type type, string method)
    {
        var traits = type.GetMethod(method)!.GetCustomAttributesData().Where(a => a.AttributeType == typeof(TraitAttribute))
            .Select(a => (Name: a.ConstructorArguments[0].Value as string, Value: a.ConstructorArguments[1].Value as string));
        Assert.Contains(("Snapshot", "skip"), traits);
    }

    /// <summary>
    /// A successful <c>--time</c> run prints timings, so its two recorded runs differ and the whole family's recording fails
    /// (2026-11-10: <c>CleanInputsExitLikeBuild</c>, a fourth such test, found only at recording). Every test line passing
    /// <c>"--time"</c> sits in a method or class tagged <c>Snapshot=skip</c>, or says <c>// snapshot: deterministic</c> (an
    /// error path, which prints no timing).
    /// </summary>
    [Fact]
    public void EveryTimeRunIsSkippedOrMarkedDeterministic()
    {
        var unmarked = new List<string>();
        foreach (var file in Directory.GetFiles(Path.Combine(Golden.RepoRoot, "tests", "Bayan.Tests"), "*.cs"))
        {
            if (Path.GetFileName(file) == nameof(SnapshotSkipTraitTests) + ".cs") continue;
            var lines = File.ReadAllLines(file);
            for (var i = 0; i < lines.Length; i++)
            {
                if (!lines[i].Contains("\"--time\"") || lines[i].Contains("// snapshot: deterministic")) continue;
                if (!IsSkipped(lines, i)) unmarked.Add($"{Path.GetFileName(file)}:{i + 1}");
            }
        }
        Assert.True(unmarked.Count == 0, "untagged --time runs: " + string.Join(", ", unmarked));
    }

    private const string Tag = "[Trait(\"Snapshot\", \"skip\")]";

    private static readonly Regex Member = new(@"^(?!(?:return|await|throw|new|else|yield)\b)(?:[\w<>\[\],.?()]+\s+)+\w+\s*\(.*\)\s*(?:=>.*|\{.*|where .*)?$");

    private static readonly Regex Class = new(@"\b(?:class|record|struct)\s+\w+");

    private static string[] Attributes(string[] lines, int decl)
    {
        var found = new List<string>();
        for (var j = decl - 1; j >= 0 && (lines[j].TrimStart().StartsWith('[') || lines[j].TrimStart().StartsWith("///")); j--) found.Add(lines[j]);
        return [.. found];
    }

    private static int Indent(string line) => line.Length - line.TrimStart().Length;

    /// <summary>
    /// The member holding line <paramref name="at"/> (the next member below when it is an attribute line) or one of its
    /// enclosing classes carries <c>[Trait("Snapshot", "skip")]</c>. A member is the nearest line above ending a signature
    /// <c>(...)</c> that is no attribute, of any access, return type and modifiers.
    /// </summary>
    internal static bool IsSkipped(string[] lines, int at)
    {
        while (at < lines.Length - 1 && lines[at].TrimStart().StartsWith('[')) at++;
        var decl = at;
        while (decl >= 0 && !(Member.IsMatch(lines[decl].Trim()) && !lines[decl].TrimStart().StartsWith('['))) decl--;
        if (decl < 0) return false;
        if (Attributes(lines, decl).Any(a => a.Contains(Tag))) return true;
        for (var (j, indent) = (decl - 1, Indent(lines[decl])); j >= 0; j--)
        {
            if (!Class.IsMatch(lines[j]) || lines[j].TrimStart().StartsWith("///") || Indent(lines[j]) >= indent) continue;
            if (Attributes(lines, j).Any(a => a.Contains(Tag))) return true;
            indent = Indent(lines[j]);
        }
        return false;
    }

    [Fact]
    public void IsSkippedFindsTheNearestEnclosingMember()
    {
        string[] Wrap(params string[] body) => ["public class C", "{", .. body, "}"];
        var tagged = new[] { "    [Fact, Trait(\"x\", \"y\")]", "    " + Tag, "    public void A()", "    {", "        Run(\"--time\");", "    }" };
        var a = Wrap(tagged);
        Assert.True(IsSkipped(a, 6), "(a) tagged public void method");
        var b = Wrap([.. tagged, "    private static string H(string x)", "    {", "        return Run(\"--time\");", "    }"]);
        Assert.False(IsSkipped(b, 10), "(b) untagged private static helper below a tagged method");
        var c = Wrap([.. tagged, "    [Fact]", "    public async Task B()", "    {", "        await Run(\"--time\");", "    }"]);
        Assert.False(IsSkipped(c, 11), "(c) untagged public async Task below a tagged method");
        var d = new[] { Tag, "public class C", "{", "    [Fact]", "    public async Task B()", "    {", "        await Run(\"--time\");", "    }", "}" };
        Assert.True(IsSkipped(d, 6), "(d) tagged class");
        var e = Wrap([.. tagged, "    [Theory]", "    [InlineData(\"--time\")]", "    public void T(string x)", "    {", "    }"]);
        Assert.False(IsSkipped(e, 10), "(e) InlineData on an untagged method below a tagged one");
        var f = Wrap("    [Theory]", "    " + Tag, "    [InlineData(\"--time\")]", "    public void T(string x)", "    {", "    }");
        Assert.True(IsSkipped(f, 5), "(f) InlineData on a tagged method");
    }
}
