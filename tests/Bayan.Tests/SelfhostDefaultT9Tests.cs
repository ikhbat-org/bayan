using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// 017 T9: the build cache of the self-hosted driver (<c>selfhost/driver/sha256.byn</c>, <c>cache.byn</c>). A probe build runs the
/// driver's functions; each case compares their output with the C# on the same input: <see cref="SHA256.HashData(byte[])"/> for
/// <c>sha256</c>, <see cref="Toolchain.Build"/>'s <c>Key</c> for the program key, <see cref="Toolchain.ScriptKey"/>,
/// <see cref="Toolchain.Lookup"/> and <see cref="Toolchain.LookupScript"/> with <c>BAYAN_CACHE</c> set for both. What needs a rename,
/// a write time or an executable bit is blocked (Q1111, Q1112).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
public sealed class SelfhostDefaultT9Tests
{
    private const string ProbeMain = """

        i32 main(ReadOnlySpan<string> args) uses alloc, console, env, fs {
            if args[0] == "sha256" {
                for i in 1..args.length {
                    let bytes = Io.readFile(args[i]) catch List<u8>()
                    Io.stdout.write($"{Hex.encode(sha256(bytes.span).span)}\n")
                }
                return 0
            }
            if args[0] == "key" {
                let source = Io.readText(args[1]) catch ""
                let compiler = ccFindCompiler()
                let flags = ccFlags(args[2], for: null)
                Io.stdout.write($"{t9Key(args[2], for: targetHost(), by: in compiler, through: in flags, from: source)}\n")
                return 0
            }
            if args[0] == "scriptkey" {
                let bytes = Io.readFile(args[1]) catch List<u8>()
                Io.stdout.write($"{scriptKey(bytes.span, by: args[2], for: args[3])}\n")
                return 0
            }
            if args[0] == "lookup" {
                let exe = lookup(args[1], by: args[2]) catch {
                    Io.stdout.write("fails\n")
                    return 0
                }
                Io.stdout.write($"{exe ?? "null"}\n")
                return 0
            }
            let exe = lookupScript(args[1], by: args[2])
            Io.stdout.write($"{exe ?? "null"}\n")
            return 0
        }
        """;

    private static readonly Lazy<(string? Path, string Error)> Probe = new(() =>
    {
        var sources = Directory.GetFiles(SelfhostDriverHarness.DriverDir, "*.byn").Order(StringComparer.Ordinal)
            .Select(p => Path.GetFileName(p) == "main.byn"
                ? SourceText.FromString(p, File.ReadAllText(p).Replace("i32 main(ReadOnlySpan<string> args) {", "i32 driverMain(ReadOnlySpan<string> args) {") + ProbeMain + "\n")
                : SourceText.FromFile(p)).ToList();
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var c = Compilation.Create(sources, packageRoot: SelfhostSemanticsHarness.SelfhostDir);
        if (c.Diagnostics.HasErrors) return (null, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal));
        return build.Succeeded ? (build.ExecutablePath, "") : (null, build.Errors);
    });

    /// <summary>Runs the probe with <c>BAYAN_CACHE</c> set to <paramref name="cache"/> (when given); its stdout.</summary>
    private static string Driver(string? cache, params string[] args)
    {
        var (path, error) = Probe.Value;
        if (path is null) Assert.Fail($"selfhost/driver with the T9 probe did not build:\n{error}");
        var psi = new ProcessStartInfo(path!) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        if (cache is not null) psi.Environment["BAYAN_CACHE"] = cache;
        psi.Environment.Remove("BAYAN_CC");
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        Assert.True(p.ExitCode == 0, $"probe exit {p.ExitCode}: {stderr.Result}");
        return stdout.Result.ReplaceLineEndings("\n");
    }

    /// <summary>Runs <paramref name="body"/> with <paramref name="variable"/> set (null: unset), then restores it.</summary>
    private static T With<T>(string variable, string? value, Func<T> body)
    {
        var saved = Environment.GetEnvironmentVariable(variable);
        Environment.SetEnvironmentVariable(variable, value);
        try { return body(); }
        finally { Environment.SetEnvironmentVariable(variable, saved); }
    }

    private static string Fresh(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t9-cache", name);
        TestDirs.Delete(dir);
        Directory.CreateDirectory(dir);
        return dir;
    }

    private static string Hex(byte[] bytes) => Convert.ToHexStringLower(SHA256.HashData(bytes));

    // ── sha256 (plan D5) ────────────────────────────────────────────────────────────────────

    [Fact]
    public void Sha256EqualsHashDataOnTheCorpus()
    {
        var dir = Fresh("sha256");
        var random = new Random(9);
        var files = new List<string>();
        var expected = new StringBuilder();
        foreach (var length in new[] { 0, 1, 3, 55, 56, 57, 63, 64, 65, 119, 120, 128, 1000, 1 << 20 })
        {
            var bytes = new byte[length];
            random.NextBytes(bytes);
            var file = Path.Combine(dir, $"in{length}");
            File.WriteAllBytes(file, bytes);
            files.Add(file);
            expected.Append(Hex(bytes)).Append('\n');
        }
        var abc = Path.Combine(dir, "abc");
        File.WriteAllBytes(abc, "abc"u8.ToArray());
        files.Add(abc);
        expected.Append(Hex("abc"u8.ToArray())).Append('\n');
        Assert.Equal(expected.ToString(), Driver(null, ["sha256", .. files]));
    }

    // ── the keys (Toolchain.cs:237, :498) ───────────────────────────────────────────────────

    [Theory]
    [InlineData("arithmetic.byn", "safe")]
    [InlineData("arithmetic.byn", "debug")]
    [InlineData("arithmetic.byn", "fast")]
    public void TheProgramKeyOfARunInputIsTheCSharpKey(string input, string mode)
    {
        var dir = Fresh($"key-{mode}");
        Assert.True(Toolchain.TryParseMode(mode, out var buildMode));
        var c = Compilation.FromPath(Path.Combine(Golden.RepoRoot, "tests", "cases", "run", input), wholeDirectory: false);
        Assert.False(c.Diagnostics.HasErrors);
        var cSource = CliApp.EmitC(c, buildMode);
        var cFile = Path.Combine(dir, "main.c");
        File.WriteAllText(cFile, cSource);
        var cache = Path.Combine(dir, "cache");
        var built = With("BAYAN_CC", null, () => With("BAYAN_CACHE", cache, () => Toolchain.Build(cSource, buildMode)));
        Assert.True(built.Succeeded, built.Errors);
        Assert.Equal($"{built.Key}\n", Driver(cache, "key", cFile, mode));
    }

    [Theory]
    [InlineData("safe", "0.2.0;bayan:12:34")]
    [InlineData("debug", "0.2.0")]
    [InlineData("fast", "")]
    public void TheScriptKeyIsTheCSharpKey(string mode, string build)
    {
        var dir = Fresh($"scriptkey-{mode}");
        var script = Path.Combine(dir, "tool.byn");
        File.WriteAllText(script, "#:mode fast\nvoid main() { print(\"hi\") }\n");
        Assert.True(Toolchain.TryParseMode(mode, out var buildMode));
        var expected = Toolchain.ScriptKey(File.ReadAllBytes(script), buildMode, build);
        Assert.Equal($"{expected}\n", Driver(null, "scriptkey", script, mode, build));
    }

    // ── Lookup and LookupScript (Toolchain.cs:289, :462) ────────────────────────────────────

    private const string Key = "4f2b1c0e9d8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c";

    /// <summary>A cache with <c>programs/&lt;Key&gt;/</c> laid out as <paramref name="shape"/> names.</summary>
    private static string Entry(string dir, string shape)
    {
        var cache = Path.Combine(dir, "cache");
        var entry = Path.Combine(cache, "v1", "programs", Key);
        TestDirs.Delete(cache);
        if (shape == "nodir") return cache;
        Directory.CreateDirectory(entry);
        var exe = Path.Combine(entry, "program");
        var bytes = Encoding.UTF8.GetBytes("not really a program\n");
        if (shape != "noexe") File.WriteAllBytes(exe, bytes);
        var sum = Path.Combine(entry, "program.sha256");
        var noSum = shape is "nosum" or "stagingfile" or "readonly";
        if (!noSum) File.WriteAllText(sum, (shape == "badsum" ? Hex([1, 2]) : Hex(bytes)) + (shape == "spaces" ? "  \r\n" : "\n"));
        if (shape == "badutf8") File.WriteAllBytes(sum, [0xff, 0xfe, 0x0a]);
        // `File.ReadAllText` drops a UTF-8 byte order mark; `Trim()` removes U+00A0 as `char.IsWhiteSpace`.
        if (shape == "bom") File.WriteAllBytes(sum, [0xef, 0xbb, 0xbf, .. Encoding.UTF8.GetBytes(Hex(bytes) + "\n")]);
        if (shape == "nbsp") File.WriteAllText(sum, Hex(bytes) + "\u00a0");
        // `Discard`'s `Directory.CreateDirectory(Staging)` fails with an `IOException` when `tmp` is a file.
        if (shape == "stagingfile") File.WriteAllText(Path.Combine(cache, "v1", "tmp"), "");
        if (shape == "unreadablesum" && !OperatingSystem.IsWindows()) File.SetUnixFileMode(sum, UnixFileMode.None);
        return cache;
    }

    private static string CSharpLookup(string cache, Func<string?> lookup) => With("BAYAN_CACHE", cache, () =>
    {
        try { return (lookup() ?? "null") + "\n"; }
        catch (UnauthorizedAccessException) { return "fails\n"; }
    });

    [Theory]
    [InlineData("hit")]
    [InlineData("spaces")]
    [InlineData("badsum")]
    [InlineData("noexe")]
    [InlineData("nosum")]
    [InlineData("nodir")]
    [InlineData("badutf8")]
    [InlineData("bom")]
    [InlineData("nbsp")]
    [InlineData("stagingfile")]
    public void LookupAsToolchain(string shape)
    {
        var dir = Fresh($"lookup-{shape}");
        var driver = Driver(Entry(dir, shape), "lookup", Key, "program");
        // The C# `Discard`s a damaged entry, so it runs second, on a fresh copy of the layout.
        var cache = Entry(dir, shape);
        Assert.Equal(CSharpLookup(cache, () => Toolchain.Lookup(Key, "program")), driver);
    }

    [Theory]
    [InlineData("program.sha256")]
    [InlineData("program")]
    public void LookupOfAnUnreadableFileFails(string name)
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Fresh($"lookup-unreadable-{name}");
        var cache = Entry(dir, "hit");
        var sum = Path.Combine(cache, "v1", "programs", Key, name);
        File.SetUnixFileMode(sum, UnixFileMode.None);
        try
        {
            Assert.Equal(CSharpLookup(cache, () => Toolchain.Lookup(Key, "program")), Driver(cache, "lookup", Key, "program"));
        }
        finally
        {
            File.SetUnixFileMode(sum, UnixFileMode.UserRead | UnixFileMode.UserWrite);
        }
    }

    /// <summary>
    /// An entry directory that can be searched but not read (0300) exists for <c>Directory.Exists</c>; with <c>v1/</c> and
    /// <c>programs/</c> read-only (0555), <c>Discard</c>'s <c>Directory.CreateDirectory(Staging)</c> throws.
    /// </summary>
    [Theory]
    [InlineData("noread")]
    [InlineData("readonly")]
    public void LookupWithAModeAsToolchain(string shape)
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Fresh($"lookup-mode-{shape}");
        var v1 = Path.Combine(dir, "cache", "v1");
        var programs = Path.Combine(v1, "programs");
        var entry = Path.Combine(programs, Key);
        string Layout()
        {
            var cache = Entry(dir, shape == "noread" ? "hit" : "readonly");
            if (shape == "noread") File.SetUnixFileMode(entry, UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            if (shape == "readonly")
                foreach (var d in new[] { programs, v1 })
                    File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserExecute | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute);
            return cache;
        }
        void Restore()
        {
            foreach (var d in new[] { v1, programs, entry })
                if (Directory.Exists(d)) File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
        try
        {
            var driver = Driver(Layout(), "lookup", Key, "program");
            Restore();
            var cache = Layout();
            Assert.Equal(CSharpLookup(cache, () => Toolchain.Lookup(Key, "program")), driver);
        }
        finally
        {
            Restore();
        }
    }

    [Theory]
    [InlineData("hit", "pointer")]
    [InlineData("hit", "bompointer")]
    [InlineData("hit", "nbsppointer")]
    [InlineData("hit", "nopointer")]
    [InlineData("nodir", "pointer")]
    [InlineData("hit", "unreadable")]
    [InlineData("unreadablesum", "pointer")]
    public void LookupScriptAsToolchain(string shape, string pointer)
    {
        if ((pointer == "unreadable" || shape == "unreadablesum") && OperatingSystem.IsWindows()) return;
        var dir = Fresh($"lookupscript-{shape}-{pointer}");
        string Layout()
        {
            var cache = Entry(dir, shape);
            var scripts = Path.Combine(cache, "v1", "scripts");
            Directory.CreateDirectory(scripts);
            var file = Path.Combine(scripts, "skey");
            if (pointer is "pointer" or "unreadable") File.WriteAllText(file, Key + "\n");
            if (pointer == "bompointer") File.WriteAllBytes(file, [0xef, 0xbb, 0xbf, .. Encoding.UTF8.GetBytes(Key + "\n")]);
            if (pointer == "nbsppointer") File.WriteAllText(file, "\u3000" + Key + "\u00a0");
            if (pointer == "unreadable") File.SetUnixFileMode(file, UnixFileMode.None);
            return cache;
        }
        var driver = Driver(Layout(), "lookupscript", "skey", "program");
        var cache = Layout();
        Assert.Equal(CSharpLookup(cache, () => Toolchain.LookupScript("skey", "program")), driver);
        if (pointer == "unreadable") File.SetUnixFileMode(Path.Combine(cache, "v1", "scripts", "skey"), UnixFileMode.UserRead | UnixFileMode.UserWrite);
    }
}
