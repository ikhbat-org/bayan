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

    /// <summary>The method holding line <paramref name="at"/> (or its class) carries <c>[Trait("Snapshot", "skip")]</c>.</summary>
    private static bool IsSkipped(string[] lines, int at)
    {
        var tag = "[Trait(\"Snapshot\", \"skip\")]";
        foreach (var kind in new[] { " void ", " class " })
        {
            var decl = at;
            while (decl >= 0 && !(lines[decl].TrimStart().StartsWith("public") && lines[decl].Contains(kind))) decl--;
            for (var j = decl - 1; j >= 0 && (lines[j].TrimStart().StartsWith('[') || lines[j].TrimStart().StartsWith("///")); j--)
                if (lines[j].Contains(tag)) return true;
            if (decl < 0) break;
        }
        return false;
    }
}
