using System.Diagnostics;
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
                    triple = targetTriple(args[3])
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

    /// <summary>A cross target (`-target` in the flags, the target in the key) needs zig on <c>PATH</c> for the C# side.</summary>
    [Theory]
    [InlineData("arithmetic.byn", "safe", null)]
    [InlineData("arithmetic.byn", "debug", null)]
    [InlineData("arithmetic.byn", "fast", null)]
    [InlineData("arithmetic.byn", "safe", "linux-x64")]
    [InlineData("arithmetic.byn", "debug", "windows-x64")]
    public void TheProgramKeyOfARunInputIsTheCSharpKey(string input, string mode, string? target)
    {
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

    [Fact]
    public void RememberScriptAsToolchain()
    {
        var dir = Fresh("remember");
        var cs = Path.Combine(dir, "cs", "cache");
        var self = Path.Combine(dir, "self", "cache");
        With("BAYAN_CACHE", cs, () => { Toolchain.RememberScript("skey", Key); return 0; });
        Driver(self, "remember", "skey", Key);
        SelfhostEmitterHarness.AssertSame("cache after remembering", Names(cs), Names(self));
        Assert.Equal(File.ReadAllText(Path.Combine(cs, "v1", "scripts", "skey")), File.ReadAllText(Path.Combine(self, "v1", "scripts", "skey")));
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
    /// The root, the elapsed seconds, the OS message of a failed write, and a script key masked: <c>Toolchain.CompilerBuild</c> is
    /// a hash of the C# assembly, the driver's is its version (Q1148).
    /// </summary>
    private static string Masked(string text, string root) =>
        Regex.Replace(Regex.Replace(Regex.Replace(text.Replace(root, "<root>"), @"[0-9]+\.[0-9]{2}s", "<t>s"),
            @"(cannot write the build output or cache \(<root>[^)]*\)): .*", "$1: <message>"), @"scripts/[0-9a-f]{64}", "scripts/<skey>");

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
            step.Before?.Invoke(a);
            var expected = Bayan(false, a, step.Env ?? [], step.Args);
            step.Before?.Invoke(b);
            var actual = Bayan(true, b, step.Env ?? [], step.Args);
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
                File.WriteAllBytes(Path.Combine(entry, "program"), [1, 2, 3]);
            }));
        Assert.DoesNotContain("from cache", outs[0]);
        Assert.Contains("from cache", outs[1]);
        Assert.Contains("from cache", outs[2]);
        Assert.DoesNotContain("from cache", outs[3]);
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
        Same($"max-mb-{mb.Length}-{mb[0]}", Old, new Step(["build", "arithmetic.byn"], Env: [("BAYAN_CACHE_MAX_MB", mb)]));
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

    // ── still blocked ───────────────────────────────────────────────────────────────────────

    [Fact(Skip = "Q1148: `compilerBuild` is the driver's version, not a hash of the running driver (Toolchain.cs:506), so CacheTests.ScriptKeysDependOnTheCompilerBuild has no driver row")]
    public void AScriptKeyNamesTheRunningDriver() { }

    [Fact(Skip = "Q1149: `Io.run` has no timeout, so CliMemoryBoundsTests.M7_AHungCCompilerIsKilledAndTheBuildFails (BAYAN_CC_TIMEOUT_S) has no driver row")]
    public void AHungCCompilerIsKilled() { }

    [Fact(Skip = "Q1149: no sleep between the tries of `replaceFile`, and a held destination needs Windows (CacheTests.ReplaceFileRetriesWhileDestinationIsOpen)")]
    public void ReplaceFileRetriesWhileTheDestinationIsOpen() { }
}
