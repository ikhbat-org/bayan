using System.Diagnostics;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
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
/// <see cref="Toolchain.Lookup"/> and <see cref="Toolchain.LookupScript"/> with <c>BAYAN_CACHE</c> set for both, and the trees
/// <c>Evict</c>, <c>SweepStale</c> and <c>RememberScript</c> leave. The build and run rows (L028) run the C# <c>bayan</c> and the
/// stage-2 driver on two trees seeded alike. The rows still blocked are skips naming their Question (Q1148, Q1149).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
[Trait("Law", "L028")]
[Trait("Snapshot", "skip")]  // the probe runs unrecorded with BAYAN_CACHE set, BAYAN_CC removed (review 233d35d finding 7)
public sealed class SelfhostDefaultT9Tests
{
    private const string ProbeMain = """

        i32 main(ReadOnlySpan<string> args) uses alloc, clock, console, env, fs {
            var d = newDCtx()
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
                var target: string? = targetHost()
                var triple: string? = null
                if args.length > 3 {
                    target = args[3]
                    // `-target` only when cross (Toolchain.cs:215, :228).
                    if args[3] != targetHost() { triple = targetTriple(args[3]) }
                }
                let flags = ccFlags(args[2], for: triple)
                Io.stdout.write($"{t9Key(args[2], for: target, by: in compiler, through: in flags, from: source)}\n")
                return 0
            }
            if args[0] == "scriptkey" {
                let bytes = Io.readFile(args[1]) catch List<u8>()
                Io.stdout.write($"{scriptKey(bytes.span, by: args[2], for: args[3])}\n")
                return 0
            }
            if args[0] == "lookup" {
                let exe = lookup(args[1], by: args[2], through: ref d) catch {
                    Io.stdout.write("fails\n")
                    return 0
                }
                Io.stdout.write($"{exe ?? "null"}\n")
                return 0
            }
            if args[0] == "evict" {
                let bytes = t9Digits(args[2], until: 9223372036854775807) ?? 0
                let entries = t9Digits(args[3], until: 9223372036854775807) ?? 0
                let seconds = t9Digits(args[4], until: 9223372036854775807) ?? 0
                evictWith(args[1], to: bytes, by: entries, until: seconds * 1000000000, through: ref d)
                return 0
            }
            if args[0] == "sweep" {
                sweepStale(args[1], by: (t9Digits(args[2], until: 9223372036854775807) ?? 0) * 1000000000)
                return 0
            }
            if args[0] == "tag" {
                tagCacheDirectory(ref d)
                return 0
            }
            if args[0] == "remember" {
                rememberScript(args[1], by: args[2], through: ref d)
                return 0
            }
            if args[0] == "replace" {
                replaceFile(args[1], from: args[2], through: ref d) catch {
                    Io.stdout.write("fails\n")
                    return 0
                }
                return 0
            }
            if args[0] == "age" {
                let seconds = t9Digits(args[1], until: 9223372036854775807) ?? 0
                for i in 2..args.length {
                    Fs.setModified(args[i], to: Time.fromNanos(Time.now().nanos - seconds * 1000000000)) catch { Io.stdout.write("fails\n") }
                }
                return 0
            }
            if args[0] == "sweeponce" {
                sweepOnce(ref d)
                Io.createDirectory(args[1]) catch { Io.stdout.write("fails\n") }
                Fs.setModified(args[1], to: Time.fromNanos(Time.now().nanos - 10800000000000)) catch { Io.stdout.write("fails\n") }
                sweepOnce(ref d)
                return 0
            }
            if args[0] == "temppath" {
                Io.stdout.write($"{t9TempPath()}\n")
                return 0
            }
            if args[0] == "unique" {
                Io.stdout.write($"{t9Unique(ref d)}\n{t9Unique(ref d)}\n")
                return 0
            }
            let exe = lookupScript(args[1], by: args[2], through: ref d)
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
    private static string Driver(string? cache, params string[] args) => Driver(cache, [], args);

    /// <summary>As <see cref="Driver(string?, string[])"/>, with <paramref name="env"/> added to the environment.</summary>
    private static string Driver(string? cache, (string Name, string Value)[] env, params string[] args)
    {
        var (path, error) = Probe.Value;
        if (path is null) Assert.Fail($"selfhost/driver with the T9 probe did not build:\n{error}");
        var psi = new ProcessStartInfo(path!) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        if (cache is not null) psi.Environment["BAYAN_CACHE"] = cache;
        psi.Environment.Remove("BAYAN_CC");
        foreach (var (name, value) in env) psi.Environment[name] = value;
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

    /// <summary>
    /// A cross target (`-target` in the flags, the target in the key) needs zig on <c>PATH</c> for the C# side; <c>host</c> is
    /// <c>Targets.Host</c> given by name, which is not cross.
    /// </summary>
    [Theory]
    [InlineData("arithmetic.byn", "safe", null)]
    [InlineData("arithmetic.byn", "debug", null)]
    [InlineData("arithmetic.byn", "fast", null)]
    [InlineData("arithmetic.byn", "safe", "linux-x64")]
    [InlineData("arithmetic.byn", "debug", "windows-x64")]
    [InlineData("arithmetic.byn", "debug", "host")]
    public void TheProgramKeyOfARunInputIsTheCSharpKey(string input, string mode, string? target)
    {
        if (target == "host") target = Targets.Host;
        if (target is not null && With("BAYAN_CC", null, Toolchain.FindCompiler) is not [_, "cc"]) return;
        var dir = Fresh($"key-{mode}-{target}");
        Assert.True(Toolchain.TryParseMode(mode, out var buildMode));
        var c = Compilation.FromPath(Path.Combine(Golden.RepoRoot, "tests", "cases", "run", input), wholeDirectory: false);
        Assert.False(c.Diagnostics.HasErrors);
        var cSource = CliApp.EmitC(c, buildMode);
        var cFile = Path.Combine(dir, "main.c");
        File.WriteAllText(cFile, cSource);
        var cache = Path.Combine(dir, "cache");
        var built = With("BAYAN_CC", null, () => With("BAYAN_CACHE", cache, () => Toolchain.Build(cSource, buildMode, target: target)));
        Assert.True(built.Succeeded, built.Errors);
        Assert.Equal($"{built.Key}\n", Driver(cache, ["key", cFile, mode, .. target is null ? Array.Empty<string>() : [target]]));
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
    /// <c>programs/</c> read-only (0555), <c>Discard</c>'s <c>Directory.CreateDirectory(Staging)</c> throws; with only
    /// <c>programs/</c> read-only its <c>Directory.Move</c> does, and with a read-only directory in the entry its <c>Directory.Delete</c>.
    /// </summary>
    [Theory]
    [InlineData("noread")]
    [InlineData("readonly")]
    [InlineData("programsreadonly")]
    [InlineData("subreadonly")]
    public void LookupWithAModeAsToolchain(string shape)
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = Fresh($"lookup-mode-{shape}");
        var v1 = Path.Combine(dir, "cache", "v1");
        var programs = Path.Combine(v1, "programs");
        var entry = Path.Combine(programs, Key);
        const UnixFileMode readOnly = UnixFileMode.UserRead | UnixFileMode.UserExecute | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute;
        string Layout()
        {
            var cache = Entry(dir, shape == "noread" ? "hit" : "readonly");
            if (shape == "noread") File.SetUnixFileMode(entry, UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            if (shape == "subreadonly")
            {
                Directory.CreateDirectory(Path.Combine(entry, "sub"));
                File.WriteAllText(Path.Combine(entry, "sub", "file"), "");
                File.SetUnixFileMode(Path.Combine(entry, "sub"), readOnly);
            }
            foreach (var d in shape switch { "readonly" => [programs, v1], "programsreadonly" => [programs], _ => Array.Empty<string>() })
                File.SetUnixFileMode(d, readOnly);
            return cache;
        }
        void Restore()
        {
            foreach (var d in new[] { v1, programs, entry })
                if (Directory.Exists(d)) File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            if (Directory.Exists(v1))
                foreach (var d in Directory.EnumerateDirectories(v1, "*", new EnumerationOptions { RecurseSubdirectories = true, IgnoreInaccessible = true }))
                    File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
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

    // ── Evict, SweepStale, RememberScript, ReplaceFile (Toolchain.cs:262, :361-456) ─────────

    /// <summary>The relative names under <paramref name="root"/>, a directory with a trailing <c>/</c>.</summary>
    private static string Names(string root) => !Directory.Exists(root) ? "" : string.Join("\n",
        Directory.EnumerateFileSystemEntries(root, "*", SearchOption.AllDirectories)
            .Select(p => Path.GetRelativePath(root, p).Replace('\\', '/') + (Directory.Exists(p) ? "/" : "")).Order(StringComparer.Ordinal));

    /// <summary>
    /// Two copies of a cache laid out by <paramref name="seed"/>, each with its entries aged in hours as <paramref name="ages"/> gives
    /// (relative path, hours): the C#'s by <see cref="Directory.SetLastWriteTimeUtc"/>, the driver's by the probe's <c>age</c>
    /// (<c>Fs.setModified</c>).
    /// </summary>
    private static (string Cs, string Self) Aged(string name, Action<string> seed, params (string Path, int Minutes)[] ages)
    {
        var dir = Fresh(name);
        var cs = Path.Combine(dir, "cs");
        var self = Path.Combine(dir, "self");
        foreach (var root in new[] { cs, self }) seed(root);
        foreach (var (path, minutes) in ages)
        {
            Directory.SetLastWriteTimeUtc(Path.Combine(cs, path), DateTime.UtcNow.AddMinutes(-minutes));
            Assert.Equal("", Driver(null, "age", (minutes * 60).ToString(System.Globalization.CultureInfo.InvariantCulture), Path.Combine(self, path)));
        }
        return (cs, self);
    }

    private static void Programs(string root, params string[] keys)
    {
        foreach (var key in keys)
        {
            var entry = Path.Combine(root, "cache", "v1", "programs", key);
            Directory.CreateDirectory(entry);
            File.WriteAllText(Path.Combine(entry, "program"), "x");
        }
    }

    /// <summary>CliMemoryBoundsTests.M5_TheProgramCacheIsTrimmedLeastRecentlyUsedFirst: the oldest go first, the kept key stays, a pointer to an evicted program goes.</summary>
    [Fact]
    public void EvictTrimsTheOldestFirstAsToolchain()
    {
        var (cs, self) = Aged("evict", root =>
        {
            Programs(root, "k0", "k1", "k2", "k3", "k4", "k5");
            var scripts = Path.Combine(root, "cache", "v1", "scripts");
            Directory.CreateDirectory(scripts);
            File.WriteAllText(Path.Combine(scripts, "old"), "k0\n");
            File.WriteAllText(Path.Combine(scripts, "new"), "k5\n");
        }, Enumerable.Range(0, 6).Select(i => ($"cache/v1/programs/k{i}", (10 - i) * 60)).ToArray());
        foreach (var (keep, entries) in new[] { ("k0", 3), ("k5", 1) })
        {
            With("BAYAN_CACHE", Path.Combine(cs, "cache"), () => { Toolchain.Evict(keep, long.MaxValue, entries, TimeSpan.FromMinutes(10)); return 0; });
            Driver(Path.Combine(self, "cache"), "evict", keep, long.MaxValue.ToString(System.Globalization.CultureInfo.InvariantCulture), entries.ToString(System.Globalization.CultureInfo.InvariantCulture), "600");
            SelfhostEmitterHarness.AssertSame($"cache after evicting to {entries} keeping {keep}", Names(cs), Names(self));
        }
        Assert.Equal("cache/\ncache/v1/\ncache/v1/programs/\ncache/v1/programs/k5/\ncache/v1/programs/k5/program\ncache/v1/scripts/\ncache/v1/scripts/new\ncache/v1/tmp/", Names(self));
    }

    /// <summary>CliMemoryBoundsTests.M5_AnEntryUsedJustNowIsNotEvicted, and a byte cap: entries younger than the minimum age stay.</summary>
    [Theory]
    [InlineData("1", 0)]
    [InlineData("1", 120)]
    [InlineData("2", 120)]
    public void EvictKeepsAnEntryUsedJustNowAsToolchain(string maxBytes, int minutes)
    {
        var (cs, self) = Aged($"evict-young-{maxBytes}-{minutes}", root => Programs(root, "a", "b", "c"),
            ("cache/v1/programs/b", minutes), ("cache/v1/programs/c", minutes * 2));
        With("BAYAN_CACHE", Path.Combine(cs, "cache"), () => { Toolchain.Evict("a", long.Parse(maxBytes, System.Globalization.CultureInfo.InvariantCulture), 4000, TimeSpan.FromMinutes(10)); return 0; });
        Driver(Path.Combine(self, "cache"), "evict", "a", maxBytes, "4000", "600");
        SelfhostEmitterHarness.AssertSame("cache after evicting", Names(cs), Names(self));
    }

    /// <summary>
    /// What is not an entry: a file in <c>programs/</c> (<c>EnumerateDirectories</c> skips it), a directory in an entry
    /// (<c>EnumerateFiles</c> skips it), a <c>.tmp</c> pointer and a directory in <c>scripts/</c>.
    /// </summary>
    [Fact]
    public void EvictSkipsWhatIsNotAnEntryAsToolchain()
    {
        var (cs, self) = Aged("evict-other", root =>
        {
            Programs(root, "k0", "k1");
            var v1 = Path.Combine(root, "cache", "v1");
            File.WriteAllText(Path.Combine(v1, "programs", "stray"), "");
            Directory.CreateDirectory(Path.Combine(v1, "programs", "k1", "sub"));
            var scripts = Path.Combine(v1, "scripts");
            Directory.CreateDirectory(Path.Combine(scripts, "dir"));
            File.WriteAllText(Path.Combine(scripts, "old"), "k0\n");
            File.WriteAllText(Path.Combine(scripts, "old.1.tmp"), "k0\n");
        }, ("cache/v1/programs/k0", 120), ("cache/v1/programs/k1", 60));
        With("BAYAN_CACHE", Path.Combine(cs, "cache"), () => { Toolchain.Evict("k1", long.MaxValue, 1, TimeSpan.FromMinutes(10)); return 0; });
        Driver(Path.Combine(self, "cache"), "evict", "k1", long.MaxValue.ToString(System.Globalization.CultureInfo.InvariantCulture), "1", "600");
        SelfhostEmitterHarness.AssertSame("cache after evicting", Names(cs), Names(self));
        Assert.False(Directory.Exists(Path.Combine(self, "cache", "v1", "programs", "k0")));
    }

    /// <summary>An entry that cannot be listed (0300) ends <c>Evict</c> before it removes anything (its caught <c>UnauthorizedAccessException</c>).</summary>
    [Fact]
    public void EvictStopsAtAnUnreadableEntryAsToolchain()
    {
        if (OperatingSystem.IsWindows()) return;
        var (cs, self) = Aged("evict-unreadable", root => Programs(root, "k0", "k1", "k2"),
            ("cache/v1/programs/k0", 180), ("cache/v1/programs/k1", 120), ("cache/v1/programs/k2", 60));
        string[] locked = [Path.Combine(cs, "cache", "v1", "programs", "k1"), Path.Combine(self, "cache", "v1", "programs", "k1")];
        foreach (var d in locked) File.SetUnixFileMode(d, UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        try
        {
            With("BAYAN_CACHE", Path.Combine(cs, "cache"), () => { Toolchain.Evict("k2", long.MaxValue, 1, TimeSpan.FromMinutes(10)); return 0; });
            Driver(Path.Combine(self, "cache"), "evict", "k2", long.MaxValue.ToString(System.Globalization.CultureInfo.InvariantCulture), "1", "600");
        }
        finally
        {
            foreach (var d in locked) File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
        SelfhostEmitterHarness.AssertSame("cache after evicting", Names(cs), Names(self));
    }

    /// <summary>
    /// CliMemoryBoundsTests.M6_StaleTemporaryDirectoriesAreSweptAndFreshOnesKept and F13 (a staging directory lives as long as
    /// <c>BAYAN_CC_TIMEOUT_S</c> plus ten minutes); a stale file with a swept prefix stays, as <c>EnumerateDirectories</c> skips it.
    /// </summary>
    [Theory]
    [InlineData(null)]
    [InlineData("7200")]
    [InlineData("0")]
    public void SweepStaleAsToolchain(string? timeout)
    {
        string[] stale = ["tmp/bayan-coverage-old", "tmp/bayan-mutate-old", "tmp/bayan-asan-old", "cache/v1/tmp/key-old", "cache/v1/tmp/key-running"];
        var (cs, self) = Aged($"sweep-{timeout}", root =>
        {
            foreach (var d in stale.Append("tmp/bayan-coverage-new").Append("cache/v1/tmp/key-new").Append("tmp/other-old"))
                Directory.CreateDirectory(Path.Combine(root, d));
            File.WriteAllText(Path.Combine(root, "tmp", "bayan-coverage-file"), "");
            File.WriteAllText(Path.Combine(root, "tmp", "bayan-coverage-old", "inside"), "");
        }, [.. stale.Select(d => (d, d.EndsWith("running", StringComparison.Ordinal) ? 125 : 180)), ("tmp/other-old", 180)]);
        File.SetLastWriteTimeUtc(Path.Combine(cs, "tmp", "bayan-coverage-file"), DateTime.UtcNow.AddHours(-3));
        Driver(null, "age", "10800", Path.Combine(self, "tmp", "bayan-coverage-file"));
        With("BAYAN_CC_TIMEOUT_S", timeout, () => With("BAYAN_CACHE", Path.Combine(cs, "cache"), () =>
        {
            Toolchain.SweepStale(Path.Combine(cs, "tmp"), TimeSpan.FromHours(1));
            return 0;
        }));
        Driver(Path.Combine(self, "cache"), timeout is null ? [] : [("BAYAN_CC_TIMEOUT_S", timeout)], "sweep", Path.Combine(self, "tmp"), "3600");
        SelfhostEmitterHarness.AssertSame("tree after the sweep", Names(cs), Names(self));
        Assert.Equal(timeout == "7200", Directory.Exists(Path.Combine(self, "cache", "v1", "tmp", "key-running")));
    }

    /// <summary>
    /// <c>SweepStale</c> over what <see cref="SweepStaleAsToolchain"/> has none of: a missing temp root, a stale file in staging, a
    /// stale directory holding a directory; off Windows a dangling link in staging and a stale directory that cannot be emptied (0555).
    /// </summary>
    [Fact]
    public void SweepStaleOfOtherEntriesAsToolchain()
    {
        var unix = !OperatingSystem.IsWindows();
        var (cs, self) = Aged("sweep-other", root =>
        {
            Directory.CreateDirectory(Path.Combine(root, "tmp", "bayan-coverage-nested", "sub"));
            File.WriteAllText(Path.Combine(root, "tmp", "bayan-coverage-nested", "sub", "inside"), "");
            Directory.CreateDirectory(Path.Combine(root, "cache", "v1", "tmp"));
            File.WriteAllText(Path.Combine(root, "cache", "v1", "tmp", "file-old"), "");
            if (!unix) return;
            Directory.CreateDirectory(Path.Combine(root, "tmp", "bayan-asan-locked"));
            File.WriteAllText(Path.Combine(root, "tmp", "bayan-asan-locked", "inside"), "");
            File.CreateSymbolicLink(Path.Combine(root, "cache", "v1", "tmp", "dangling"), "missing");
        }, [("tmp/bayan-coverage-nested/sub", 180), ("tmp/bayan-coverage-nested", 180), .. unix ? [("tmp/bayan-asan-locked", 180)] : Array.Empty<(string, int)>()]);
        File.SetLastWriteTimeUtc(Path.Combine(cs, "cache", "v1", "tmp", "file-old"), DateTime.UtcNow.AddHours(-3));
        Driver(null, "age", "10800", Path.Combine(self, "cache", "v1", "tmp", "file-old"));
        string[] locked = unix ? [Path.Combine(cs, "tmp", "bayan-asan-locked"), Path.Combine(self, "tmp", "bayan-asan-locked")] : [];
        foreach (var d in locked) if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserExecute);
        try
        {
            foreach (var temp in new[] { "missing", "tmp" })
            {
                With("BAYAN_CACHE", Path.Combine(cs, "cache"), () => { Toolchain.SweepStale(Path.Combine(cs, temp), TimeSpan.FromHours(1)); return 0; });
                Driver(Path.Combine(self, "cache"), "sweep", Path.Combine(self, temp), "3600");
                SelfhostEmitterHarness.AssertSame($"tree after the sweep of {temp}", Names(cs), Names(self));
            }
        }
        finally
        {
            foreach (var d in locked) if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(d, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
        Assert.False(Directory.Exists(Path.Combine(self, "tmp", "bayan-coverage-nested")));
    }

    /// <summary>Toolchain.cs:407 <c>SweepOnce</c>: a second call in one run sweeps nothing, so a staging entry made stale after the first stays.</summary>
    [Fact]
    public void ASecondSweepOnceDoesNothingAsToolchain()
    {
        var dir = Fresh("sweeponce");
        var temp = Path.Combine(dir, "tmp");
        Directory.CreateDirectory(temp);
        string Late(string side) => Path.Combine(dir, side, "cache", "v1", "tmp", "late");
        foreach (var side in new[] { "cs", "self" }) Directory.CreateDirectory(Path.GetDirectoryName(Late(side))!);
        var swept = typeof(Toolchain).GetField("s_swept", BindingFlags.NonPublic | BindingFlags.Static)!;
        var once = typeof(Toolchain).GetMethod("SweepOnce", BindingFlags.NonPublic | BindingFlags.Static)!;
        With("TMPDIR", temp, () => With("TMP", temp, () => With("BAYAN_CACHE", Path.Combine(dir, "cs", "cache"), () =>
        {
            swept.SetValue(null, 0);
            once.Invoke(null, null);
            Directory.CreateDirectory(Late("cs"));
            Directory.SetLastWriteTimeUtc(Late("cs"), DateTime.UtcNow.AddHours(-3));
            once.Invoke(null, null);
            return 0;
        })));
        Assert.Equal("", Driver(Path.Combine(dir, "self", "cache"), [("TMPDIR", temp), ("TMP", temp)], "sweeponce", Late("self")));
        SelfhostEmitterHarness.AssertSame("cache after two sweeps", Names(Path.Combine(dir, "cs")), Names(Path.Combine(dir, "self")));
        Assert.True(Directory.Exists(Late("self")));
    }

    /// <summary><c>Path.GetTempPath()</c> off Windows (the Windows arm of <c>t9TempPath</c> is Q1083's): <c>TMPDIR</c> empty is <c>/tmp/</c>.</summary>
    [Theory]
    [InlineData("")]
    [InlineData("/var/tmp/")]
    public void TheTempPathIsTheCSharpPath(string tmpdir)
    {
        if (OperatingSystem.IsWindows()) return;
        Assert.Equal(With("TMPDIR", tmpdir, Path.GetTempPath) + "\n", Driver(null, [("TMPDIR", tmpdir)], "temppath"));
    }

    /// <summary>Toolchain.cs:477 <c>RememberScript</c>; with <c>v1/scripts</c> a file its <c>Directory.CreateDirectory</c> throws and nothing is remembered.</summary>
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public void RememberScriptAsToolchain(bool scriptsIsAFile)
    {
        var dir = Fresh($"remember-{scriptsIsAFile}");
        var cs = Path.Combine(dir, "cs", "cache");
        var self = Path.Combine(dir, "self", "cache");
        if (scriptsIsAFile)
            foreach (var cache in new[] { cs, self })
            {
                Directory.CreateDirectory(Path.Combine(cache, "v1"));
                File.WriteAllText(Path.Combine(cache, "v1", "scripts"), "");
            }
        With("BAYAN_CACHE", cs, () => { Toolchain.RememberScript("skey", Key); return 0; });
        Driver(self, "remember", "skey", Key);
        SelfhostEmitterHarness.AssertSame("cache after remembering", Names(cs), Names(self));
        if (!scriptsIsAFile) Assert.Equal(File.ReadAllText(Path.Combine(cs, "v1", "scripts", "skey")), File.ReadAllText(Path.Combine(self, "v1", "scripts", "skey")));
        Assert.Equal(File.ReadAllText(Path.Combine(cs, "v1", "CACHEDIR.TAG")), File.ReadAllText(Path.Combine(self, "v1", "CACHEDIR.TAG")));
    }

    /// <summary>CacheTests.ReplaceFileRetriesWhileDestinationIsOpen off Windows: the file is replaced, no temporary is left; a missing directory fails.</summary>
    [Fact]
    public void ReplaceFilePublishesByRename()
    {
        var dir = Fresh("replace");
        var path = Path.Combine(dir, "target.txt");
        var source = Path.Combine(dir, "source.txt");
        File.WriteAllText(path, "before");
        File.WriteAllText(source, "after");
        Assert.Equal("", Driver(null, "replace", path, source));
        Assert.Equal("after", File.ReadAllText(path));
        Assert.Equal(["source.txt", "target.txt"], Directory.GetFiles(dir).Select(Path.GetFileName).Order(StringComparer.Ordinal));
        Assert.Equal("fails\n", Driver(null, "replace", Path.Combine(dir, "missing", "target.txt"), source));
        Assert.Equal(["source.txt", "target.txt"], Directory.GetFiles(dir).Select(Path.GetFileName).Order(StringComparer.Ordinal));
    }

    [Fact]
    public void UniqueNamesDiffer()
    {
        var names = Driver(null, "unique").Split('\n', StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(2, names.Length);
        Assert.NotEqual(names[0], names[1]);
        Assert.NotEqual(names[0], Driver(null, "unique").Split('\n')[0]);
    }

    // ── through stage 2 against the C# (L028; CacheTests.cs, CliMemoryBoundsTests.cs M5) ────

    /// <summary>One argv run on both trees; <see cref="Before"/> runs on each tree first, <see cref="Env"/> adds variables (null unsets).</summary>
    private sealed record Step(string[] Args, Action<string>? Before = null, (string Name, string? Value)[]? Env = null);

    /// <summary>The C# <c>bayan</c> (its assembly under <c>dotnet</c>) or the stage-2 driver, in <paramref name="cwd"/>, <c>BAYAN_CACHE</c> = <c>&lt;cwd&gt;/cache</c> and <c>BAYAN_CC</c> unset.</summary>
    private static (int Exit, string Out, string Err) Bayan(bool driver, string cwd, (string Name, string? Value)[] env, string[] args)
    {
        var psi = new ProcessStartInfo(driver ? SelfhostDriverHarness.Build() : "dotnet") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, WorkingDirectory = cwd };
        if (!driver) psi.ArgumentList.Add(typeof(CliApp).Assembly.Location);
        psi.Environment["BAYAN_CACHE"] = Path.Combine(cwd, "cache");
        psi.Environment.Remove("BAYAN_CC");
        foreach (var (name, value) in env)
            if (value is null) psi.Environment.Remove(name); else psi.Environment[name] = value;
        foreach (var a in args) psi.ArgumentList.Add(a);
        using var p = Process.Start(psi)!;
        var stdout = p.StandardOutput.ReadToEndAsync();
        var stderr = p.StandardError.ReadToEndAsync();
        p.WaitForExit();
        return (p.ExitCode, stdout.Result.ReplaceLineEndings("\n"), stderr.Result.ReplaceLineEndings("\n"));
    }

    /// <summary>
    /// The root, the elapsed seconds, the OS message of a failed write or a C compiler that does not start, a script key and the
    /// commit of <c>doctor</c> masked: <c>Toolchain.CompilerBuild</c> is a hash of the C# assembly, the driver's is its version (Q1148),
    /// and the driver's commit is <c>selfhost</c> (SelfhostDefaultT5Tests' mask).
    /// </summary>
    private static string Masked(string text, string root) =>
        Regex.Replace(Regex.Replace(Regex.Replace(Regex.Replace(Regex.Replace(text.Replace(root, "<root>"), @"[0-9]+\.[0-9]{2}s", "<t>s"),
            @"(cannot write the build output or cache \(<root>[^)]*\)): .*", "$1: <message>"), @"(cannot run the C compiler `[^`]*`): .*", "$1: <message>"),
            @"scripts/[0-9a-f]{64}", "scripts/<skey>"), @"\(commit [^)]*\)", "(commit <c>)");

    /// <summary>
    /// The steps on two trees seeded alike (the C#'s first); exit code and masked streams compared per step, the names of both trees
    /// after the last. The C#'s masked stdout per step.
    /// </summary>
    private static List<string> Same(string name, Action<string> seed, params Step[] steps)
    {
        var dir = Fresh(name);
        var a = Path.Combine(dir, "cs");
        var b = Path.Combine(dir, "s2");
        var outs = new List<string>();
        foreach (var root in new[] { a, b })
        {
            Directory.CreateDirectory(root);
            seed(root);
        }
        foreach (var step in steps)
        {
            // `<root>` in a variable's value is the tree's root.
            (string, string?)[] Env(string root) => [.. (step.Env ?? []).Select(e => (e.Name, e.Value?.Replace("<root>", root)))];
            step.Before?.Invoke(a);
            var expected = Bayan(false, a, Env(a), step.Args);
            step.Before?.Invoke(b);
            var actual = Bayan(true, b, Env(b), step.Args);
            var label = $"{name}: {string.Join(' ', step.Args)}";
            Assert.True(expected.Exit == actual.Exit, $"exit of `{label}`: C# {expected.Exit}, driver {actual.Exit}\n{expected.Err}\n{actual.Err}");
            SelfhostEmitterHarness.AssertSame($"stdout of `{label}`", Masked(expected.Out, a), Masked(actual.Out, b));
            SelfhostEmitterHarness.AssertSame($"stderr of `{label}`", Masked(expected.Err, a), Masked(actual.Err, b));
            outs.Add(Masked(expected.Out, a));
        }
        SelfhostEmitterHarness.AssertSame($"names of `{name}`", Masked(Names(a), a), Masked(Names(b), b));
        return outs;
    }

    private static void Arithmetic(string root) => File.Copy(Path.Combine(Golden.CasesRoot, "run", "arithmetic.byn"), Path.Combine(root, "arithmetic.byn"));

    /// <summary>CacheTests: a miss compiles, a second build hits and says so with <c>--verbose</c>, a damaged entry is rebuilt; the <c>v1/</c> names are the C#'s.</summary>
    [Fact]
    public void ASecondBuildLinksFromTheCache()
    {
        var outs = Same("hit", Arithmetic,
            new Step(["build", "--verbose", "arithmetic.byn"]),
            new Step(["build", "--verbose", "arithmetic.byn"]),
            new Step(["build", "arithmetic.byn"]),
            new Step(["build", "--verbose", "arithmetic.byn"], root =>
            {
                var entry = Directory.GetDirectories(Path.Combine(root, "cache", "v1", "programs")).Single();
                File.WriteAllBytes(Path.Combine(entry, OperatingSystem.IsWindows() ? "program.exe" : "program"), [1, 2, 3]);
            }),
            new Step(["--ascii", "build", "arithmetic.byn"]));
        Assert.DoesNotContain("from cache", outs[0]);
        Assert.Contains("from cache", outs[1]);
        Assert.Contains("from cache", outs[2]);
        Assert.DoesNotContain("from cache", outs[3]);
        Assert.Contains("- from cache", outs[4]);
    }

    /// <summary>
    /// A build that cannot publish its entry fails as <c>cannot write the build output or cache</c>, staging cleared: <c>programs</c>
    /// a file (<c>Directory.CreateDirectory(Programs)</c>), <c>programs/&lt;key&gt;</c> a file (<c>Directory.Move</c>'s
    /// <c>IOException</c> with no entry to look up), and off Windows <c>programs/</c> read-only (its <c>UnauthorizedAccessException</c>).
    /// </summary>
    [Theory]
    [InlineData("programsfile")]
    [InlineData("entryfile")]
    [InlineData("programsreadonly")]
    public void ABuildThatCannotPublishFails(string shape)
    {
        if (shape == "programsreadonly" && OperatingSystem.IsWindows()) return;
        const UnixFileMode readOnly = UnixFileMode.UserRead | UnixFileMode.UserExecute | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute;
        var programs = new List<string>();
        void Seed(string root)
        {
            Arithmetic(root);
            var dir = Path.Combine(root, "cache", "v1", "programs");
            Directory.CreateDirectory(Path.GetDirectoryName(dir)!);
            if (shape == "programsfile") File.WriteAllText(dir, "");
            if (shape != "programsreadonly") return;
            Directory.CreateDirectory(dir);
            if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(dir, readOnly);
            programs.Add(dir);
        }
        static void EntryAsAFile(string root)
        {
            var entry = Directory.GetDirectories(Path.Combine(root, "cache", "v1", "programs")).Single();
            Directory.Delete(entry, recursive: true);
            File.WriteAllText(entry, "");
        }
        try
        {
            var outs = shape == "entryfile"
                ? Same($"publish-{shape}", Seed, new Step(["build", "arithmetic.byn"]), new Step(["build", "arithmetic.byn"], EntryAsAFile))
                : Same($"publish-{shape}", Seed, new Step(["build", "arithmetic.byn"]));
            Assert.Equal("", outs[^1]);
        }
        finally
        {
            foreach (var dir in programs) if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(dir, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }
    }

    /// <summary>
    /// A C compiler <c>Compile</c> does not expect, found as <c>cc</c> on a <c>PATH</c> of one directory (the driver reads no
    /// <c>BAYAN_CC</c>, spec Q1): a file that cannot be run (<c>cannot run the C compiler</c>), a script that exits 0 and writes no
    /// executable, and one that writes the executable and a directory beside it, which <c>EnumerateFiles</c> keeps in the entry and
    /// <c>Evict</c> does not count. The directory is shared by both trees, since the program key hashes the compiler's path.
    /// <c>racedir</c>: a second build whose compiler makes an empty directory where the entry goes (named in <c>v1/racedir</c>), as
    /// another build would; <c>Directory.Move</c> refuses an existing destination, and the empty entry is no winner.
    /// </summary>
    [Theory]
    [InlineData("notexecutable")]
    [InlineData("noexe")]
    [InlineData("subdir")]
    [InlineData("racedir")]
    public void AnOddCCompiler(string shape)
    {
        if (OperatingSystem.IsWindows()) return;
        var bin = Fresh($"cc-bin-{shape}");
        var cc = Path.Combine(bin, "cc");
        File.WriteAllText(cc, shape switch
        {
            "notexecutable" => "",
            "noexe" => "#!/bin/sh\nexit 0\n",
            "subdir" => "#!/bin/sh\nout=\nwhile [ $# -gt 0 ]; do\n  if [ \"$1\" = -o ]; then out=$2; fi\n  shift\ndone\nprintf x > \"$out\"\ncase $out in */*) dir=${out%/*};; *) dir=.;; esac\n/bin/mkdir \"$dir/sub\"\n",
            _ => "#!/bin/sh\nout=\nwhile [ $# -gt 0 ]; do\n  if [ \"$1\" = -o ]; then out=$2; fi\n  shift\ndone\nprintf x > \"$out\"\ncase $out in */*) dir=${out%/*};; *) dir=.;; esac\nif [ -f \"$dir/../../racedir\" ]; then /bin/mkdir \"$(/bin/cat \"$dir/../../racedir\")\"; fi\n",
        });
        File.SetUnixFileMode(cc, shape == "notexecutable" ? UnixFileMode.UserRead | UnixFileMode.UserWrite : UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        static void Race(string root)
        {
            var entry = Directory.GetDirectories(Path.Combine(root, "cache", "v1", "programs")).Single();
            Directory.Delete(entry, recursive: true);
            File.WriteAllText(Path.Combine(root, "cache", "v1", "racedir"), entry);
        }
        var build = new Step(["build", "arithmetic.byn"], Env: [("PATH", bin)]);
        var outs = shape == "racedir"
            ? Same($"cc-{shape}", Arithmetic, build, build with { Before = Race })
            : Same($"cc-{shape}", Arithmetic, build);
        if (shape is "subdir" or "racedir") Assert.Contains("built arithmetic", outs[0]);
        if (shape == "racedir") Assert.Equal("", outs[1]);
    }

    /// <summary>CliMemoryBoundsTests.M5_ABuildTagsTheCacheDataItOwnsAsACacheDirectory: a build writes the tag, a hit writes it again.</summary>
    [Fact]
    public void ABuildTagsTheCache()
    {
        static void Untag(string root) => File.Delete(Path.Combine(root, "cache", "v1", "CACHEDIR.TAG"));
        Same("tag", Arithmetic,
            new Step(["build", "arithmetic.byn"]),
            new Step(["build", "arithmetic.byn"], Untag),
            new Step(["run", "arithmetic.byn"], Untag));
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t9-cache", "tag");
        var tag = File.ReadAllText(Path.Combine(dir, "s2", "cache", "v1", "CACHEDIR.TAG"));
        Assert.StartsWith("Signature: 8a477f597d28d172789f06886806bc55\n", tag);
        Assert.Equal(File.ReadAllText(Path.Combine(dir, "cs", "cache", "v1", "CACHEDIR.TAG")), tag);
    }

    /// <summary>CliTests.AnUnwritableCacheIsAToolchainProblem: <c>BAYAN_CACHE</c> names a file.</summary>
    [Fact]
    public void AnUnwritableCache()
    {
        Same("unwritable", root =>
            {
                Arithmetic(root);
                File.WriteAllText(Path.Combine(root, "cache"), "");
            },
            new Step(["build", "arithmetic.byn"]),
            new Step(["run", "arithmetic.byn"]),
            new Step(["build", "-o", "prog", "arithmetic.byn"]));
    }

    /// <summary>CliMemoryBoundsTests.M5_ABuildTrimsTheCacheToTheCap: <c>BAYAN_CACHE_MAX_MB</c> 1 evicts the oldest; 0 keeps all; digits only, else 2048.</summary>
    [Theory]
    [InlineData("1")]
    [InlineData("0")]
    [InlineData("+1")]
    [InlineData("1x")]
    [InlineData("99999999999999999999")]
    public void BayanCacheMaxMb(string mb)
    {
        void Old(string root)
        {
            Arithmetic(root);
            for (var i = 0; i < 3; i++)
            {
                var entry = Path.Combine(root, "cache", "v1", "programs", "old" + i);
                Directory.CreateDirectory(entry);
                File.WriteAllBytes(Path.Combine(entry, "program"), new byte[600_000]);
                Directory.SetLastWriteTimeUtc(entry, DateTime.UtcNow.AddHours(-3 + i));
            }
        }
        Same($"max-mb-{mb.Length}-{mb[0]}{mb[^1]}", Old, new Step(["build", "arithmetic.byn"], Env: [("BAYAN_CACHE_MAX_MB", mb)]));
    }

    /// <summary>CacheTests.ARememberedScriptStartsWithoutCompiling: with no C compiler on <c>PATH</c> a remembered script runs, a changed one fails.</summary>
    [Fact]
    public void ARememberedScriptStartsWithoutACompiler()
    {
        if (OperatingSystem.IsWindows()) return;
        var none = new (string, string?)[] { ("PATH", "") };
        Same("script", root => File.WriteAllText(Path.Combine(root, "hello.byn"), "#!/usr/bin/env bayan\n#:io threaded\n\nprint(\"hi\")\n"),
            new Step(["hello.byn"]),
            new Step(["hello.byn"], Env: none),
            new Step(["hello.byn"], root => File.AppendAllText(Path.Combine(root, "hello.byn"), "print(\"changed\")\n"), none));
    }

    /// <summary>CacheTests.ParallelBuildsNeverCorruptTheCache through the driver: every build succeeds, one entry per key, nothing staged.</summary>
    [Fact]
    public void ParallelBuildsNeverCorruptTheCache()
    {
        var dir = Fresh("parallel");
        Arithmetic(dir);
        var results = new (int Exit, string Out, string Err)[12];
        Parallel.For(0, results.Length, new ParallelOptions { MaxDegreeOfParallelism = 6 }, i =>
            results[i] = Bayan(true, dir, [], ["build", "--mode", i % 2 == 0 ? "debug" : "safe", "-o", $"prog{i}", "arithmetic.byn"]));
        foreach (var r in results) Assert.True(r.Exit == 0, r.Out + r.Err);
        Assert.Equal(2, Directory.GetDirectories(Path.Combine(dir, "cache", "v1", "programs")).Length);
        Assert.Empty(Directory.EnumerateFileSystemEntries(Path.Combine(dir, "cache", "v1", "tmp")));
        Assert.Empty(Directory.GetFiles(dir, "*.tmp"));
    }

    /// <summary>
    /// CliMemoryBoundsTests.M6_StaleTemporaryDirectoriesAreSweptAndFreshOnesKept and F13 through a build: the first build of a
    /// run sweeps <c>bayan-coverage-</c>/<c>-mutate-</c>/<c>-asan-</c> directories under <c>TMPDIR</c> older than an hour and
    /// staging entries older than <c>BAYAN_CC_TIMEOUT_S</c> plus ten minutes. <c>TMPDIR</c> (<c>TMP</c> on Windows) is a sibling of the tree
    /// (<c>&lt;root&gt;-tmp</c>), so what <c>dotnet</c> itself writes there is not compared; the seeded names are.
    /// </summary>
    [Theory]
    [InlineData(null)]
    [InlineData("7200")]
    public void ABuildSweepsStaleDirectories(string? timeout)
    {
        string[] seeded = ["bayan-coverage-old/", "bayan-coverage-old/inside", "bayan-mutate-old/", "bayan-asan-old/", "bayan-coverage-new/", "other-old/", "bayan-coverage-file"];
        void Seed(string root)
        {
            Arithmetic(root);
            var temp = root + "-tmp";
            TestDirs.Delete(temp);
            foreach (var d in seeded.Where(d => d.EndsWith('/'))) Directory.CreateDirectory(Path.Combine(temp, d));
            File.WriteAllText(Path.Combine(temp, "bayan-coverage-old", "inside"), "");
            File.WriteAllText(Path.Combine(temp, "bayan-coverage-file"), "");
            foreach (var d in new[] { "bayan-coverage-old", "bayan-mutate-old", "bayan-asan-old", "other-old" })
                Directory.SetLastWriteTimeUtc(Path.Combine(temp, d), DateTime.UtcNow.AddHours(-2));
            File.SetLastWriteTimeUtc(Path.Combine(temp, "bayan-coverage-file"), DateTime.UtcNow.AddHours(-2));
            var staging = Path.Combine(root, "cache", "v1", "tmp");
            foreach (var (key, minutes) in new[] { ("key-old", 180), ("key-running", 125), ("key-new", 0) })
            {
                Directory.CreateDirectory(Path.Combine(staging, key));
                Directory.SetLastWriteTimeUtc(Path.Combine(staging, key), DateTime.UtcNow.AddMinutes(-minutes));
            }
        }
        Same($"sweep-build-{timeout}", Seed,
            new Step(["build", "arithmetic.byn"], Env: [("TMPDIR", "<root>-tmp"), ("TMP", "<root>-tmp"), ("BAYAN_CC_TIMEOUT_S", timeout)]));
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t9-cache", $"sweep-build-{timeout}");
        string Left(string side) => string.Join("\n", seeded.Where(n => Path.Exists(Path.Combine(dir, side + "-tmp", n.TrimEnd('/')))));
        SelfhostEmitterHarness.AssertSame("seeded names left in TMPDIR", Left("cs"), Left("s2"));
        Assert.Equal("bayan-coverage-new/\nother-old/\nbayan-coverage-file", Left("s2"));
        Assert.Equal(timeout == "7200", Directory.Exists(Path.Combine(dir, "s2", "cache", "v1", "tmp", "key-running")));
        Assert.False(Directory.Exists(Path.Combine(dir, "s2", "cache", "v1", "tmp", "key-old")));
    }

    // ── the arms of `run` (main.byn, `ref d` since T9) ──────────────────────────────────────

    /// <summary>Each arm of main.byn <c>run</c>'s command switch that no other row of this class reaches, by an argv of that command.</summary>
    [Theory]
    [InlineData("doctor")]
    [InlineData("format")]
    [InlineData("audit")]
    [InlineData("features")]
    [InlineData("explain")]
    [InlineData("new")]
    [InlineData("cache")]
    [InlineData("clean --bogus")]
    [InlineData("init --bogus")]
    public void ACommandReachesItsArm(string argv)
    {
        var args = argv.Split(' ');
        Same($"arm-{args[0]}", _ => { }, new Step(args));
    }

    /// <summary>The arms that refuse: the C# runs these commands, the driver does not port them (spec Q4).</summary>
    [Theory]
    [InlineData("mutate")]
    public void ARefusedCommandReachesItsArm(string command)
    {
        var (exit, stdout, stderr) = SelfhostDriverHarness.Run(command);
        Assert.Equal(CliApp.ExitUsage, exit); // no-oracle: Q917 the C# runs these commands; the refusal text is R3's (Q4)
        Assert.Equal("", stdout);
        Assert.Equal($"error: `{command}` is not available in the self-hosted compiler; use the C# `bayan`\n", stderr);
    }

    // listed skips, still blocked:
    // - CacheTests.ScriptKeysDependOnTheCompilerBuild: `compilerBuild` is the driver's version, not a hash of the running driver
    //   (Toolchain.cs:506), so it has no driver row (Q1148).
    // - CliMemoryBoundsTests.M7_AHungCCompilerIsKilledAndTheBuildFails (BAYAN_CC_TIMEOUT_S): `Io.run` has no timeout, so it has no
    //   driver row (Q1149).
    // - CacheTests.ReplaceFileRetriesWhileDestinationIsOpen: no sleep between the tries of `replaceFile`, and a held destination
    //   needs Windows (Q1149).
}
