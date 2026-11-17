using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;

namespace Bayan.Tests;

/// <summary>Arm64 macOS only, as the sabk tests (024 R9): the shared runner of L046 and L047.</summary>
internal static class SabkLaw
{
    internal static bool Supported => RuntimeInformation.IsOSPlatform(OSPlatform.OSX) && RuntimeInformation.OSArchitecture == Architecture.Arm64;

    internal const string Skip = "sabk tests need arm64 macOS (024 R9)";

    internal static (int Exit, string Out, string Err) RunInRoot(string program, params string[] args)
    {
        var psi = new ProcessStartInfo(program) { WorkingDirectory = Golden.RepoRoot, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result, stderr.Result);
    }

    /// <summary>Runs the sabk source tests whose title contains <paramref name="only"/>; asserts exactly <paramref name="count"/> ran and all passed.</summary>
    internal static void RunBayanTests(string only, int count)
    {
        var (exit, o, e) = RunInRoot(BootstrapTests.Stage2Executable(), "test", "--package", "src", "src/sabk", "--only", only);
        Assert.True(exit == 0 && o.Contains($"◆ {count} passed"), $"{only} failed (exit {exit}):\n{o}\n{e}");
    }
}

/// <summary>
/// Law L046 (spec 024 R3): <c>encode</c> returns the reference assembler's word for every form of the subset. Checked:
/// the recorded <c>src/sabk/testdata/encodings.tsv</c>, and a sweep written here at test time: for every form, every
/// register each operand takes, every immediate range edge, then seeded random operands. The sweep's text is assembled by
/// <c>scripts/sabk/record-encodings.sh</c> (the pinned <c>zig cc</c>, read back with <c>otool -t</c>), and the Bayān test
/// "L046:" in <c>src/sabk/enc/encode.test.byn</c> compares each row with <c>encode</c>. Label forms branch to a label at
/// their own address, so the assembler's offset field is zero; <c>adrp</c> and <c>@PAGEOFF</c> name an undefined symbol,
/// so it emits the field zero for the relocation.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L046")]
public sealed class SabkEncoderLawTests
{
    private const int Seed = 46;

    private const int RandomPerForm = 40;

    /// <summary><c>Base</c> is a memory base: x0-x30 or sp at either width.</summary>
    private enum Slot { General, GeneralOrZero, GeneralOrSp, Base }

    /// <summary>One form: its id, width (x or w), register operand slots, immediate operands (edges plus a random draw),
    /// the text from the drawn values, and the operand combinations the assembler accepts.</summary>
    private sealed record Form(string Id, char Width, Slot[] Regs, (long[] Edges, Func<Random, long> Draw)[] Imms, Func<string[], long[], string> Text, bool Label = false, Func<string[], bool>? Valid = null);

    private static string[] Registers(Slot slot, char width)
    {
        if (slot == Slot.Base) width = 'x';
        var r = Enumerable.Range(0, 31).Select(n => $"{width}{n}").ToList();
        if (slot == Slot.GeneralOrZero) r.Add(width == 'x' ? "xzr" : "wzr");
        if (slot is Slot.GeneralOrSp or Slot.Base && width == 'x') r.Add("sp");
        return r.ToArray();
    }

    private static readonly string[] Conds = ["eq", "ne", "hs", "lo", "mi", "pl", "vs", "vc", "hi", "ls", "ge", "lt", "gt", "le", "al"];

    private static readonly string[] Shifts = ["lsl", "lsr", "asr"];

    private static (long[], Func<Random, long>) Range(long lo, long hi, long step = 1) =>
        (new[] { lo, lo + step, hi - step, hi }.Distinct().ToArray(), r => lo + step * r.NextInt64((hi - lo) / step + 1));

    private static (long[], Func<Random, long>) OneOf(int n) => (Enumerable.Range(0, n).Select(i => (long)i).ToArray(), r => r.Next(n));

    private static int Num(string reg) => reg is "sp" or "xzr" or "wzr" ? 31 : int.Parse(reg[1..]);

    private static List<Form> Forms()
    {
        var forms = new List<Form>();
        Slot G = Slot.General, Z = Slot.GeneralOrZero, S = Slot.GeneralOrSp, B = Slot.Base;
        foreach (var w in new[] { 'x', 'w' })
        {
            var shiftMax = w == 'x' ? 3 : 1;
            foreach (var m in new[] { "movz", "movk" })
                forms.Add(new($"{m}-{w}", w, [Z], [Range(0, 65535), OneOf(shiftMax + 1)], (r, i) => $"{m} {r[0]}, #{i[0]}, lsl #{i[1] * 16}"));
            forms.Add(new($"mov-reg-{w}", w, [Z, Z], [], (r, i) => $"mov {r[0]}, {r[1]}"));
            foreach (var m in new[] { "add", "sub" })
                forms.Add(new($"{m}-imm-{w}", w, [S, S], [Range(0, 4095), OneOf(2)], (r, i) => $"{m} {r[0]}, {r[1]}, #{i[0]}{(i[1] == 1 ? ", lsl #12" : "")}"));
            forms.Add(new($"subs-imm-{w}", w, [Z, S], [Range(0, 4095), OneOf(2)], (r, i) => $"subs {r[0]}, {r[1]}, #{i[0]}{(i[1] == 1 ? ", lsl #12" : "")}"));
            forms.Add(new($"cmp-imm-{w}", w, [S], [Range(0, 4095), OneOf(2)], (r, i) => $"cmp {r[0]}, #{i[0]}{(i[1] == 1 ? ", lsl #12" : "")}"));
            var amountMax = w == 'x' ? 63 : 31;
            foreach (var m in new[] { "add", "sub", "subs", "and", "orr", "eor" })
                forms.Add(new($"{m}-reg-{w}", w, [Z, Z, Z], [OneOf(3), Range(0, amountMax)], (r, i) => $"{m} {r[0]}, {r[1]}, {r[2]}, {Shifts[i[0]]} #{i[1]}"));
            forms.Add(new($"cmp-reg-{w}", w, [Z, Z], [OneOf(3), Range(0, amountMax)], (r, i) => $"cmp {r[0]}, {r[1]}, {Shifts[i[0]]} #{i[1]}"));
            foreach (var m in new[] { "mul", "sdiv" })
                forms.Add(new($"{m}-{w}", w, [Z, Z, Z], [], (r, i) => $"{m} {r[0]}, {r[1]}, {r[2]}"));
            forms.Add(new($"msub-{w}", w, [Z, Z, Z, Z], [], (r, i) => $"msub {r[0]}, {r[1]}, {r[2]}, {r[3]}"));
            forms.Add(new($"neg-{w}", w, [Z, Z], [], (r, i) => $"neg {r[0]}, {r[1]}"));
            forms.Add(new($"cset-{w}", w, [Z], [OneOf(14)], (r, i) => $"cset {r[0]}, {Conds[i[0]]}"));
            forms.Add(new($"csel-{w}", w, [Z, Z, Z], [OneOf(15)], (r, i) => $"csel {r[0]}, {r[1]}, {r[2]}, {Conds[i[0]]}"));
            var size = w == 'x' ? 8 : 4;
            foreach (var m in new[] { "ldr", "str" })
                forms.Add(new($"{m}-{w}", w, [Z, B], [Range(0, 4095 * size, size)], (r, i) => $"{m} {r[0]}, [{r[1]}, #{i[0]}]"));
            foreach (var m in new[] { "ldur", "stur" })
                forms.Add(new($"{m}-{w}", w, [Z, B], [Range(-256, 255)], (r, i) => $"{m} {r[0]}, [{r[1]}, #{i[0]}]"));
            foreach (var m in new[] { "cbz", "cbnz" })
                forms.Add(new($"{m}-{w}", w, [Z], [], (r, i) => $"{m} {r[0]}, {{label}}", Label: true));
        }
        forms.Add(new("mov-sp", 'x', [S, S], [], (r, i) => $"mov {r[0]}, {r[1]}", Valid: r => r[0] == "sp" || r[1] == "sp"));
        foreach (var m in new[] { "stp", "ldp" })
        {
            // The assembler rejects as unpredictable a writeback base that is also a transfer register, and an ldp of one register twice.
            Func<string[], bool> pair(bool writeback) => r => (m == "stp" || Num(r[0]) != Num(r[1])) && (!writeback || (r[2] != $"x{Num(r[0])}" && r[2] != $"x{Num(r[1])}"));
            forms.Add(new($"{m}-x-off", 'x', [Z, Z, S], [Range(-512, 504, 8)], (r, i) => $"{m} {r[0]}, {r[1]}, [{r[2]}, #{i[0]}]", Valid: pair(false)));
            forms.Add(new($"{m}-x-pre", 'x', [Z, Z, S], [Range(-512, 504, 8)], (r, i) => $"{m} {r[0]}, {r[1]}, [{r[2]}, #{i[0]}]!", Valid: pair(true)));
            forms.Add(new($"{m}-x-post", 'x', [Z, Z, S], [Range(-512, 504, 8)], (r, i) => $"{m} {r[0]}, {r[1]}, [{r[2]}], #{i[0]}", Valid: pair(true)));
        }
        forms.Add(new("b", 'x', [], [], (r, i) => "b {label}", Label: true));
        forms.Add(new("bl", 'x', [], [], (r, i) => "bl {label}", Label: true));
        forms.Add(new("b-cond", 'x', [], [OneOf(15)], (r, i) => $"b.{Conds[i[0]]} {{label}}", Label: true));
        foreach (var m in new[] { "br", "blr", "ret" })
            forms.Add(new(m, 'x', [G], [], (r, i) => $"{m} {r[0]}"));
        forms.Add(new("adrp", 'x', [Z], [], (r, i) => $"adrp {r[0]}, _sym@PAGE"));
        forms.Add(new("add-pageoff", 'x', [S, S], [], (r, i) => $"add {r[0]}, {r[1]}, _sym@PAGEOFF"));
        forms.Add(new("adr", 'x', [Z], [], (r, i) => $"adr {r[0]}, {{label}}", Label: true));
        return forms;
    }

    /// <summary>The sweep rows as (form id, assembler text, label form): per form, each register of each slot with the
    /// rest drawn, each immediate edge with the rest drawn, then <see cref="RandomPerForm"/> fully drawn rows.</summary>
    private static List<(string Form, string Text, bool Label)> Sweep()
    {
        var rng = new Random(Seed);
        var rows = new List<(string, string, bool)>();
        foreach (var f in Forms())
        {
            var sets = f.Regs.Select(s => Registers(s, f.Width)).ToArray();
            void Add(int fixedReg, string? reg, int fixedImm, long imm)
            {
                for (var attempt = 0; attempt < 1000; attempt++)
                {
                    var r = sets.Select(s => s[rng.Next(s.Length)]).ToArray();
                    if (fixedReg >= 0) r[fixedReg] = reg!;
                    var i = f.Imms.Select(m => m.Draw(rng)).ToArray();
                    if (fixedImm >= 0) i[fixedImm] = imm;
                    if (f.Valid is { } valid && !valid(r)) continue;
                    rows.Add((f.Id, f.Text(r, i), f.Label));
                    return;
                }
            }
            for (var s = 0; s < sets.Length; s++)
                foreach (var reg in sets[s]) Add(s, reg, -1, 0);
            for (var k = 0; k < f.Imms.Length; k++)
                foreach (var edge in f.Imms[k].Edges) Add(-1, null, k, edge);
            for (var n = 0; n < RandomPerForm; n++) Add(-1, null, -1, 0);
        }
        return rows;
    }

    [Fact]
    public void EncodeMatchesTheReferenceAssembler()
    {
        if (!SabkLaw.Supported) { Console.WriteLine(SabkLaw.Skip); return; }
        var (exit, o, e) = SabkLaw.RunInRoot("bash", "-c", "zig=zig; command -v zig >/dev/null 2>&1 || zig=/Users/sy/.local/bin/zig; \"$zig\" version");
        var pinned = File.ReadAllText(Path.Combine(Golden.RepoRoot, ".zig-version")).Trim();
        Assert.True(exit == 0 && o.Trim() == pinned, $"the reference assembler is zig {pinned} (.zig-version); found {o.Trim()} {e}");

        var dir = Path.Combine(Golden.RepoRoot, "tmp", "sabk-law046");
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        var rows = Sweep();
        var s = new StringBuilder(".text\n");
        for (var n = 0; n < rows.Count; n++)
        {
            var (form, text, label) = rows[n];
            if (label) s.Append($"Lsw{n}:\n");
            s.Append($"// form: {form}\n    {text.Replace("{label}", $"Lsw{n}")}\n");
        }
        File.WriteAllText(Path.Combine(dir, "sweep.s"), s.ToString());
        (exit, o, e) = SabkLaw.RunInRoot("bash", Path.Combine(Golden.RepoRoot, "scripts", "sabk", "record-encodings.sh"), Path.Combine(dir, "sweep.s"), Path.Combine(dir, "sweep.tsv"));
        Assert.True(exit == 0, $"record-encodings.sh failed on the sweep (exit {exit}):\n{o}\n{e}");

        SabkLaw.RunBayanTests("L046:", 1);
        // The Bayān test writes how many sweep rows it compared, so a sweep it did not read cannot pass.
        var checkedRows = File.ReadAllText(Path.Combine(dir, "checked.txt")).Trim();
        Assert.Equal(rows.Count.ToString(), checkedRows);
    }
}

/// <summary>
/// Law L047 (spec 024 R7): every allocation <c>allocate</c> returns is sound. The Bayān tests "L047:" in
/// <c>src/sabk/check/sound.test.byn</c> run <c>checkAllocation</c> over every SIR test function there and over a seeded
/// generated set (straight-line, loop and call shapes, 0-40 live values, every vreg written on every path before it is
/// read), assert the generated set is accepted, zero findings, every assigned x19-x28 in <c>usedCalleeSaved</c> and
/// <c>frameSize</c> covering every assigned spill slot, and report the first counterexample.
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L047")]
public sealed class SabkAllocationLawTests
{
    [Fact]
    public void AllocationIsSound()
    {
        if (!SabkLaw.Supported) { Console.WriteLine(SabkLaw.Skip); return; }
        SabkLaw.RunBayanTests("L047:", 2);
    }
}
