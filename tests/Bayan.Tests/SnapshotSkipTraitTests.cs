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
    };

    [Theory]
    [MemberData(nameof(UnreplayableMethods))]
    public void MethodIsSkippedBySnapshotRecording(Type type, string method)
    {
        var traits = type.GetMethod(method)!.GetCustomAttributesData().Where(a => a.AttributeType == typeof(TraitAttribute))
            .Select(a => (Name: a.ConstructorArguments[0].Value as string, Value: a.ConstructorArguments[1].Value as string));
        Assert.Contains(("Snapshot", "skip"), traits);
    }
}
