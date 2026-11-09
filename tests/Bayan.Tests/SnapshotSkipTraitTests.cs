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
}
