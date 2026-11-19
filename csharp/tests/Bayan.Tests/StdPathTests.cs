using System.Diagnostics;
using System.Globalization;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// Spec 014's slice (011 P2), 014 T1, T2 and T3: <c>Path.isRooted</c>, <c>Path.fileName</c>, <c>Path.directoryName</c>, <c>Path.combine</c> (both forms), <c>Path.fullPath</c> and <c>Path.relative</c> give what .NET's
/// <c>Path.IsPathRooted</c>, <c>Path.GetFileName</c>, <c>Path.GetDirectoryName</c>, <c>Path.Combine</c>, <c>Path.GetFullPath</c> and <c>Path.GetRelativePath</c> give on the same OS, over a seeded corpus
/// with Windows-shaped inputs. On Windows the .NET calls use Windows rules, so the same corpus checks both separators, drive
/// letters, UNC and case-insensitive <c>relative</c> there. Both sides run in the test process's working directory, so relative
/// inputs resolve alike.
/// </summary>
public sealed class StdPathTests
{
    internal static readonly string[] Atoms =
        ["a", "b", "B", "abc", "ABC", "x y", "é", ".", "..", "...", "", "C:", "c:", "C:x", "file.txt", ".hidden", "~", "UNC", "?", "server", "share"];

    internal static readonly string[] Shapes =
    [
        "", " ", "/", "//", "\\", "\\\\", "a", "/a", "a/", "/a/", "a/b", "a//b", "./a", "../a", ".", "..", "a/.", "a/..", "/a/b/",
        "C:", "C:\\", "C:/", "C:x", "C:\\x", "C:/x\\y", "c:\\X\\", "1:\\x", "\\x", "/x\\y", "\\\\server\\share", "\\\\server\\share\\",
        "\\\\server\\share\\x", "//server/share/x", "\\\\server", "\\\\?\\C:\\x", "\\\\.\\C:\\x", "\\\\?\\UNC\\server\\share\\x", "\\??\\C:\\x",
        "a\\b", "a b/c d", "/é/ü", "file.txt", "/dir.d/", "a/b.c.d",
    ];

    internal static List<string> Corpus(int seed, int count)
    {
        var random = new Random(seed);
        var seps = new[] { "/", "\\", "//", "\\\\", "/\\" };
        var list = new List<string>(Shapes);
        while (list.Count < count)
        {
            var sb = new StringBuilder();
            if (random.Next(3) == 0) sb.Append(seps[random.Next(seps.Length)]);
            var parts = random.Next(1, 5);
            for (var i = 0; i < parts; i++)
            {
                if (i > 0) sb.Append(seps[random.Next(seps.Length)]);
                sb.Append(Atoms[random.Next(Atoms.Length)]);
            }
            if (random.Next(4) == 0) sb.Append(seps[random.Next(seps.Length)]);
            list.Add(sb.ToString());
        }
        return list;
    }

    internal static List<(string From, string To)> Pairs(int seed, int count)
    {
        var random = new Random(seed);
        var paths = Corpus(seed, count);
        var pairs = new List<(string, string)>
        {
            ("/a/b", "/a/b/c"), ("/a/b", "/a/B/c"), ("/A/b", "/a/b"), ("/a/b", "/a/c"), ("/a/b", "/x"), ("/a/b/", "/a/b"), ("/a/b", "/a/b/"),
            ("/a", "/a/./b/../c"), ("a", "b"), ("a", "../x"), ("/", "/a"), ("/a", "/"), ("/a/b", "/a/bc"), ("/a/bc", "/a/b"), ("/a/b", "/a/b/c/"),
            ("C:\\x", "C:\\y"), ("C:\\x", "c:\\X\\y"), ("C:\\x", "D:\\x"), ("C:x", "C:y"), ("\\\\server\\share\\a", "\\\\server\\share\\b"),
            ("\\\\server\\share\\a", "\\\\SERVER\\Share\\a\\b"), ("\\\\s1\\share\\a", "\\\\s2\\share\\a"), ("C:/a/b", "C:\\a\\c"), ("/..", "/a"),
            // Letters that differ only by case beyond ASCII: `char.ToUpperInvariant` per UTF-16 unit for the common part, and
            // `OrdinalIgnoreCase` for a Windows root, where `ſ` and a surrogate pair fold differently. Bytes that are not UTF-8 are
            // in InvalidUtf8MatchesDotNet, since no Bayan string holds them.
            ("/é/a", "/É/b"), ("/É/a", "/é/b"), ("/ß/a", "/ẞ/b"), ("/ı/a", "/I/b"), ("/i/a", "/İ/b"), ("/ς/a", "/Σ/b"), ("/σ/a", "/Σ/b"),
            ("/ſ/a", "/S/b"), ("/ǅ/a", "/ǆ/b"), ("/ɐ/a", "/Ɐ/b"), ("/\U00010428/a", "/\U00010400/b"), ("/\U00010400/a", "/\U00010400/b"),
            ("/a\U00010428", "/a\U00010400"), ("/\uFFFD/a", "/\uFFFD/b"), ("/é", "/É"), ("/éa/b", "/Éa"), ("/a/é/", "/A/É"),
            ("\\\\é\\share\\a", "\\\\É\\share\\b"), ("\\\\ſ\\share\\a", "\\\\S\\share\\b"), ("\\\\ς\\share\\a", "\\\\Σ\\share\\b"),
            ("\\\\\U00010428\\s\\a", "\\\\\U00010400\\s\\b"), ("C:\\é\\a", "c:\\É\\b"),
            // 8.3 short names: .NET expands a `~` segment that exists, and keeps a tail that does not (on Windows).
            ("C:\\PROGRA~1\\a", "C:\\Program Files\\b"), ("C:\\Program Files\\a", "C:\\PROGRA~1"), ("C:\\PROGRA~1\\NOPE~1\\x", "C:\\Program Files\\NOPE~1"),
            ("C:\\NOPE~1\\a", "C:\\NOPE~1\\b"), ("\\\\.\\C:\\PROGRA~1\\a", "\\\\.\\C:\\Program Files"), ("~1/a", "~1/b"),
        };
        for (var i = 0; i < count; i++)
        {
            var from = paths[random.Next(paths.Count)];
            // Half the targets share the source's start, so the common-prefix arms get exercised.
            var to = random.Next(2) == 0 ? from + "/" + paths[random.Next(paths.Count)] : paths[random.Next(paths.Count)];
            pairs.Add((from, to));
        }
        return pairs;
    }

    internal static string Literal(string s)
    {
        var sb = new StringBuilder("\"");
        foreach (var ch in s)
            sb.Append(ch switch { '\\' => "\\\\", '"' => "\\\"", _ => ch.ToString() });
        return sb.Append('"').ToString();
    }

    internal static string? Relative(string from, string to)
    {
        try { return Path.GetRelativePath(from, to); }
        catch (ArgumentException) { return null; }
    }

    internal static string? FullPath(string path)
    {
        try { return Path.GetFullPath(path); }
        catch (ArgumentException) { return null; }
    }

    [Fact]
    public async Task EachFunctionMatchesDotNet()
    {
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "std-path");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);

        var source = new StringBuilder();
        var expected = new List<string>();
        // Spec 019 T26: per call, the operation and its arguments, and .NET's result (see Export).
        var export = ExportDir is not null;
        var ops = new List<string>();
        var results = new List<string>();
        foreach (var p in Corpus(14, 300))
        {
            source.Append($"print(Path.isRooted({Literal(p)}) ? \"true\" : \"false\")\n");
            expected.Add(Path.IsPathRooted(p) ? "true" : "false");
            ops.Add($"isRooted {Hex(p)}");
            results.Add(expected[^1]);
            source.Append($"print(Path.fileName({Literal(p)}))\n");
            expected.Add(Path.GetFileName(p));
            ops.Add($"fileName {Hex(p)}");
            results.Add(Hex(expected[^1]));
            // .NET's null (a root, an empty path) prints as a marker no path in the corpus holds.
            source.Append($"print(Path.directoryName({Literal(p)}) ?? \"<null>\")\n");
            expected.Add(Path.GetDirectoryName(p) ?? "<null>");
            ops.Add($"directoryName {Hex(p)}");
            results.Add(Path.GetDirectoryName(p) is { } dn ? Hex(dn) : "null");
            // Relative inputs resolve against the working directory on both sides. .NET throws on an empty path (and on Windows a
            // blank one); that is FullPathPanicsWhereDotNetThrows.
            if (FullPath(p) is not { } full) continue;
            source.Append($"print(Path.fullPath({Literal(p)}))\n");
            expected.Add(full);
            ops.Add($"fullPath {Hex(p)}");
            results.Add(export ? CwdField(full, b => FullPathAt(p, b)) : "");
        }
        foreach (var (from, to) in Pairs(1014, 400))
        {
            // .NET throws on an empty path (and on Windows a blank one); the runtime panics there instead, so neither is in the program.
            if (Relative(from, to) is not { } r) continue;
            source.Append($"print(Path.relative(from: {Literal(from)}, to: {Literal(to)}))\n");
            expected.Add(r);
            ops.Add($"relative {Hex(from)} {Hex(to)}");
            results.Add(export ? CwdField(r, b => Relative(FullPathAt(from, b), FullPathAt(to, b))) : "");
        }
        // `combine` brackets its result: an empty one is a line too.
        foreach (var (a, b) in Pairs(2014, 200))
        {
            source.Append($"print($\"[{{Path.combine({Literal(a)}, {Literal(b)})}}]\")\n");
            expected.Add($"[{Path.Combine(a, b)}]");
            ops.Add($"combine {Hex(a)} {Hex(b)}");
            results.Add(Hex(Path.Combine(a, b)));
        }
        // Spans of 0-4 parts from the atoms and the shapes, which hold rooted ones, so a later rooted part restarts the result.
        var spanRandom = new Random(3014);
        var spanParts = Atoms.Concat(Shapes).ToArray();
        for (var i = 0; i < 300; i++)
        {
            var parts = Enumerable.Range(0, i % 5).Select(_ => spanParts[spanRandom.Next(spanParts.Length)]).ToArray();
            source.Append($"print($\"[{{Path.combine([{string.Join(", ", parts.Select(Literal))}])}}]\")\n");
            expected.Add($"[{Path.Combine(parts)}]");
            ops.Add(string.Join(' ', parts.Select(Hex).Prepend("combineAll")));
            results.Add(Hex(Path.Combine(parts)));
        }
        Assert.True(expected.Count > 900, $"only {expected.Count} lines");
        Export("std-path-each-function-matches-dotnet", ops, results);
        Assert.True(source.ToString().Split('\n').Count(l => l.StartsWith("print(Path.fullPath(\"") && !l.StartsWith("print(Path.fullPath(\"/")) > 100, "too few relative fullPath inputs");

        var c = Compilation.Create([new SourceText("paths.byn", Encoding.UTF8.GetBytes(source.ToString()))], dir);
        Assert.False(c.Diagnostics.HasErrors);
        var build = Toolchain.Build(CliApp.EmitC(c, BuildMode.Safe), BuildMode.Safe);
        Assert.True(build.Succeeded, build.Errors);
        var psi = new ProcessStartInfo(build.ExecutablePath!)
        {
            WorkingDirectory = Directory.GetCurrentDirectory(),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            StandardOutputEncoding = Encoding.UTF8,
        };
        using var proc = Process.Start(psi)!;
        var stderr = proc.StandardError.ReadToEndAsync();
        var stdout = await proc.StandardOutput.ReadToEndAsync();
        var waitMs = TestTime.Scale(120_000);
        Assert.True(proc.WaitForExit(waitMs), $"program timed out after {waitMs} ms");
        Assert.True(proc.ExitCode == 0, await stderr);
        var actual = stdout.Split('\n');
        Assert.Equal(expected.Count + 1, actual.Length);
        var source0 = source.ToString().Split('\n');
        for (var i = 0; i < expected.Count; i++)
            Assert.True(expected[i] == actual[i], $"line {i + 1}: {source0[i]}\n.NET: [{expected[i]}]\nBayan: [{actual[i]}]");
    }

    /// <summary>
    /// <c>Path.fullPath</c> panics, naming itself, on each input where <c>Path.GetFullPath</c> throws <c>ArgumentException</c> (empty,
    /// a NUL byte, and on Windows blank), and prints what it returns otherwise.
    /// </summary>
    [Fact]
    public async Task FullPathPanicsWhereDotNetThrows()
    {
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "std-path-full");
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        (string Path, string Panic)[] cases =
            [("", "the path is empty"), (" ", "the path is empty"), ("\0", "the path has a NUL byte"), ("a\0b", "the path has a NUL byte"), ("/a\0", "the path has a NUL byte")];
        foreach (var (p, panic) in cases)
        {
            var full = FullPath(p);
            // Only a blank path differs by OS: .NET throws on it on Windows alone.
            Assert.True(full is null || p == " ", $"GetFullPath([{p}]) does not throw ArgumentException");
            // Spec 019 T26: the blank row, `<cwd>/ ` with the working directory masked, or the panic where .NET throws.
            if (p == " ")
                Export("std-path-full-path-panics-where-dotnet-throws-space", [$"fullPath {Hex(p)}"],
                    [full is null ? $"panic {Hex($"Path.fullPath: {panic}")}" : Field(full, ("@CWD@", Directory.GetCurrentDirectory()))]);
            var source = $"print(Path.fullPath({Literal(p).Replace("\0", "\\0")}))\n";
            var c = Compilation.Create([new SourceText("full.byn", Encoding.UTF8.GetBytes(source))], dir);
            Assert.False(c.Diagnostics.HasErrors);
            var build = Toolchain.Build(CliApp.EmitC(c, BuildMode.Safe), BuildMode.Safe);
            Assert.True(build.Succeeded, build.Errors);
            var psi = new ProcessStartInfo(build.ExecutablePath!)
            {
                WorkingDirectory = Directory.GetCurrentDirectory(),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                StandardOutputEncoding = Encoding.UTF8,
            };
            using var proc = Process.Start(psi)!;
            var stderr = proc.StandardError.ReadToEndAsync();
            var stdout = await proc.StandardOutput.ReadToEndAsync();
            var waitMs = TestTime.Scale(120_000);
            Assert.True(proc.WaitForExit(waitMs), $"program timed out after {waitMs} ms");
            var err = (await stderr).ReplaceLineEndings("\n");
            if (full is null)
            {
                Assert.True(proc.ExitCode != 0, $"[{p}]: .NET throws, Bayan exits 0 with [{stdout}]");
                Assert.Equal($"panic: Path.fullPath: {panic}\n  at full.byn:1\n", err);
            }
            else
            {
                Assert.True(proc.ExitCode == 0, err);
                Assert.Equal(full + "\n", stdout);
            }
        }
    }

    /// <summary>
    /// <c>byn_path_relative</c> on bytes that are not UTF-8 gives what <c>Path.GetRelativePath</c> gives on their
    /// <c>Encoding.UTF8</c> decoding (each maximal invalid subpart one U+FFFD). Bayan text is always valid UTF-8 (literals,
    /// <c>Utf8.decode</c>, arguments and <c>Io</c> all check), so a native driver (<c>runtime/tests/path-relative-cases.c</c>)
    /// calls the runtime directly.
    /// </summary>
    [Fact]
    public async Task InvalidUtf8MatchesDotNet()
    {
        byte[][] bad =
        [
            [0xFF], [0xC0, 0xAF], [0xE2, 0x82], [0xED, 0xA0, 0x80], [0xE0, 0x80], [0xF4, 0x90], [0xF0, 0x90, 0x90], [0x80, 0x80],
            [0xC3], [0xFE, 0xC3, 0xA9],
        ];
        byte[][] good = [[], "a"u8.ToArray(), "é"u8.ToArray(), "É"u8.ToArray(), "\U00010428"u8.ToArray(), "\U00010400"u8.ToArray()];
        static byte[] Cat(params byte[][] parts) => parts.SelectMany(p => p).ToArray();
        var cwd = Encoding.UTF8.GetBytes(Directory.GetCurrentDirectory());
        var pairs = new List<(byte[] From, byte[] To)>();
        foreach (var b in bad)
            foreach (var g in good)
            {
                var seg = Cat(b, g);
                pairs.Add((Cat("/"u8.ToArray(), seg, "/a"u8.ToArray()), Cat("/"u8.ToArray(), seg, "/b"u8.ToArray())));
                pairs.Add((Cat("/"u8.ToArray(), g, b, "/a"u8.ToArray()), Cat("/"u8.ToArray(), g, "/b"u8.ToArray())));
                pairs.Add((Cat("/x/"u8.ToArray(), seg), Cat("/x/"u8.ToArray(), g, b, "/y"u8.ToArray())));
                pairs.Add((Cat("/x"u8.ToArray(), b), Cat("/x"u8.ToArray(), b, "/"u8.ToArray(), g)));
                pairs.Add((Cat(seg, "/a"u8.ToArray()), Cat(seg, "/b"u8.ToArray())));
                pairs.Add((Cat(cwd, "/"u8.ToArray(), b), Cat(b, "/"u8.ToArray(), g, "c"u8.ToArray())));
                pairs.Add((Cat("C:\\"u8.ToArray(), seg, "\\a"u8.ToArray()), Cat("c:\\"u8.ToArray(), seg, "\\b"u8.ToArray())));
                pairs.Add((Cat("\\\\"u8.ToArray(), seg, "\\s\\a"u8.ToArray()), Cat("\\\\"u8.ToArray(), seg, "\\s\\b"u8.ToArray())));
            }
        // Different bytes that decode to the same U+FFFD count are the same segment to .NET.
        foreach (var b1 in bad)
            foreach (var b2 in bad)
                pairs.Add((Cat("/"u8.ToArray(), b1, "/a"u8.ToArray()), Cat("/"u8.ToArray(), b2, "/b"u8.ToArray())));

        var input = new StringBuilder();
        var expected = new List<string>();
        var shown = new List<string>();
        foreach (var (from, to) in pairs)
        {
            // .NET throws on an empty path (and on Windows a blank one); the runtime panics there, so neither is a case.
            if (Relative(Encoding.UTF8.GetString(from), Encoding.UTF8.GetString(to)) is not { } r) continue;
            input.Append(Convert.ToHexStringLower(from)).Append(' ').Append(Convert.ToHexStringLower(to)).Append('\n');
            expected.Add(r);
            shown.Add($"{Convert.ToHexStringLower(from)} -> {Convert.ToHexStringLower(to)}");
        }
        Assert.True(expected.Count > 400, $"only {expected.Count} cases");
        if (ExportDir is { } export)
        {
            // Spec 019 T24b: the driver's stdin and, per case, the hex of .NET's result as the driver prints it.
            var os = Path.Combine(export, "runtime", OperatingSystem.IsWindows() ? "windows" : OperatingSystem.IsMacOS() ? "macos" : "linux");
            Directory.CreateDirectory(os);
            var utf8 = new UTF8Encoding(false);
            // A field that starts with the working directory holds `@CWD@` and the hex of the rest, so the file is the same on every host.
            var cwdHex = Convert.ToHexStringLower(cwd);
            var portable = string.Concat(input.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(line =>
                string.Join(' ', line.Split(' ').Select(f => f.StartsWith(cwdHex, StringComparison.Ordinal) ? "@CWD@" + f[cwdHex.Length..] : f)) + "\n"));
            File.WriteAllText(Path.Combine(os, "path-relative.in"), portable, utf8);
            File.WriteAllText(Path.Combine(os, "path-relative.expected"),
                string.Concat(expected.Select(r => Convert.ToHexStringLower(Encoding.UTF8.GetBytes(r)) + "\n")), utf8);
        }

        var actual = await RunDriver(input.ToString());
        Assert.Equal(expected.Count + 1, actual.Length);
        for (var i = 0; i < expected.Count; i++)
        {
            var got = Encoding.UTF8.GetString(Convert.FromHexString(actual[i]));
            Assert.True(expected[i] == got, $"case {i + 1}: {shown[i]}\n.NET: [{expected[i]}]\nruntime: [{got}] ({actual[i]})");
        }
    }

    /// <summary>
    /// <c>byn_path_full</c> on 8.3 short names gives <c>Path.GetFullPath</c>, step by step: an existing short name, one under a
    /// non-existent tail (the trimmed retry of <c>PathHelper.TryExpandShortFileName</c>), a <c>\\.\</c> device path and one past
    /// 260 units. <c>relative</c> from a root no target shares returns the target's full path, on both sides, so the driver shows it.
    /// Short names are Windows-only, and elsewhere every absolute path shares the root <c>/</c>.
    /// </summary>
    [Fact]
    public async Task ShortNamesExpandAsDotNet()
    {
        if (!OperatingSystem.IsWindows()) return;
        const string elsewhere = "\\\\?\\Z:\\";
        string[] paths =
        [
            "C:\\PROGRA~1\\a", "C:\\PROGRA~1", "C:\\PROGRA~1\\NOPE~1\\x", "C:\\NOPE~1\\a", "\\\\.\\C:\\PROGRA~1\\a",
            "C:\\PROGRA~1\\" + string.Join("\\", Enumerable.Repeat("abcdefghij", 30)),
        ];
        // Spec 019 T26: the driver's stdin and the hex of .NET's full path, which `relative` from another root gives (Windows only).
        Export("std-path-short-names-expand-as-dotnet", paths.Select(p => Hex(elsewhere) + " " + Hex(p)), paths.Select(p => Hex(Path.GetFullPath(p))));
        var actual = await RunDriver(string.Concat(paths.Select(p => Hex(elsewhere) + " " + Hex(p) + "\n")));
        Assert.Equal(paths.Length + 1, actual.Length);
        var steps = paths.Select((p, i) => (Path: p, Full: Path.GetFullPath(p), Relative: Relative(elsewhere, p),
            Runtime: Encoding.UTF8.GetString(Convert.FromHexString(actual[i])))).ToList();
        var report = string.Join("\n", steps.Select(s => $"{s.Path}\n  GetFullPath: [{s.Full}]\n  runtime:     [{s.Runtime}]"));
        Assert.True(steps.All(s => s.Relative == s.Full), "GetRelativePath from another root is not GetFullPath:\n" + report);
        Assert.True(steps.All(s => s.Runtime == s.Full), report);
    }

    /// <summary>Set by <see cref="InvalidUtf8ExportsFixtures"/> in place of <c>BAYAN_EXPORT_DIR</c>, so no other test sees it.</summary>
    private static readonly AsyncLocal<string?> ExportOverride = new();

    /// <summary>The directory <c>BAYAN_EXPORT_DIR</c> names (spec 019 T24b), or the override; null when unset.</summary>
    internal static string? ExportDir =>
        ExportOverride.Value ?? (Environment.GetEnvironmentVariable("BAYAN_EXPORT_DIR") is { Length: > 0 } dir ? dir : null);

    // Spec 019 T26 export format (StdEnvTests, StdFsTests, StdPathTests). Each row writes `runtime/<os>/<case>.in` and `<case>.expected`
    // under BAYAN_EXPORT_DIR (UTF-8, LF), `<case>` the class and test in kebab case. A line is fields separated by one space, and a field
    // may be empty: a word (an operation, `true`, `false`, `null`, `ok`, ...) or a string as the lowercase hex of its UTF-8. In a string
    // field a marker stands for a machine-specific part, between hex runs: `@ROOT@` the scratch root of an Fs fixture, `@RELROOT@` that
    // root relative to the working directory, `@TEMP@` Path.GetTempPath(), `@EXE@` the running executable, `@CWD@` the working directory
    // and `@CWD-n@` it less its last n components, `@CWDREL@` / `@CWDREL-n@` the same without the root, `@CWDTAIL-a-b@` its components
    // from the a-th last to before the b-th last, and `@UP@` / `@UP+k@` / `@UP-k@` `..` repeated (the working directory's component
    // count + k) times, joined by the separator. Fs fixtures and trees are StdFsTests.Tree lines.

    /// <summary>Spec 019 T26: writes <paramref name="input"/> and <paramref name="expected"/>, a line each, as <c>&lt;name&gt;.in</c> and <c>.expected</c> under <see cref="ExportDir"/>; nothing when it is unset.</summary>
    internal static void Export(string name, IEnumerable<string> input, IEnumerable<string> expected)
    {
        if (ExportDir is not { } export) return;
        var os = Path.Combine(export, "runtime", OperatingSystem.IsWindows() ? "windows" : OperatingSystem.IsMacOS() ? "macos" : "linux");
        Directory.CreateDirectory(os);
        var utf8 = new UTF8Encoding(false);
        File.WriteAllText(Path.Combine(os, name + ".in"), string.Concat(input.Select(l => l + "\n")), utf8);
        File.WriteAllText(Path.Combine(os, name + ".expected"), string.Concat(expected.Select(l => l + "\n")), utf8);
    }

    internal static string Hex(string s) => Convert.ToHexStringLower(Encoding.UTF8.GetBytes(s));

    /// <summary>The string field of <paramref name="s"/>: hex, with each occurrence of a mask's value replaced by its marker (the first mask that matches wins).</summary>
    internal static string Field(string s, params (string Marker, string Value)[] masks)
    {
        var sb = new StringBuilder();
        var run = new StringBuilder();
        for (var i = 0; i < s.Length;)
        {
            var m = masks.FirstOrDefault(m => m.Value.Length > 0 && string.CompareOrdinal(s, i, m.Value, 0, m.Value.Length) == 0);
            if (m.Marker is null) { run.Append(s[i++]); continue; }
            sb.Append(Hex(run.ToString())).Append(m.Marker);
            run.Clear();
            i += m.Value.Length;
        }
        return sb.Append(Hex(run.ToString())).ToString();
    }

    /// <summary>A working directory unlike the test's, deeper than any corpus input climbs, to find the results that depend on it.</summary>
    private static readonly string OtherCwd = Path.Combine([Path.GetPathRoot(Directory.GetCurrentDirectory())!, "t26", .. Enumerable.Range(1, 15).Select(i => $"w{i}")]);

    /// <summary>
    /// <c>Path.GetFullPath(<paramref name="path"/>)</c> with <paramref name="cwd"/> as the working directory, for <see cref="CwdField"/>.
    /// On Unix that is the two-argument form. On Windows the one-argument form resolves as GetFullPathNameW: any character before a
    /// colon is a drive (`1:\x` stays `1:\x`), and a drive-relative path (`C:x`) joins the working directory only on its drive (letter
    /// case aside), else that drive's own directory; the two-argument form takes only a letter as a drive (`1:\x` joins the base) and
    /// matches the drive by its own rule. So a colon second or two leading separators (drive, UNC, device) is the one-argument form, which
    /// does not move with the working directory, a drive-relative path on the working directory's drive joins it, and the rest (`x`,
    /// `\x`, `\??\`) is the two-argument form.
    /// </summary>
    private static string FullPathAt(string path, string cwd)
    {
        if (!OperatingSystem.IsWindows()) return Path.GetFullPath(path, cwd);
        static bool Sep(char c) => c is '\\' or '/';
        if (path.Length >= 2 && path[1] == ':')
            return (path.Length == 2 || !Sep(path[2])) && cwd.Length >= 2 && cwd[1] == ':' && char.ToUpperInvariant(path[0]) == char.ToUpperInvariant(cwd[0])
                ? Path.GetFullPath(Path.Join(cwd, path[2..]))
                : Path.GetFullPath(path);
        return path.Length >= 2 && Sep(path[0]) && Sep(path[1]) ? Path.GetFullPath(path) : Path.GetFullPath(path, cwd);
    }

    /// <summary>The value for <paramref name="cwd"/> of a working-directory marker (<c>CWD</c>, <c>CWDREL</c>, <c>CWDTAIL</c>, <c>UP</c>) with numbers <paramref name="a"/> and <paramref name="b"/>.</summary>
    private static string CwdMarker(string name, int a, int b, string cwd)
    {
        var root = Path.GetPathRoot(cwd)!;
        var parts = cwd[root.Length..].Split(Path.DirectorySeparatorChar, StringSplitOptions.RemoveEmptyEntries);
        var d = parts.Length;
        var sep = Path.DirectorySeparatorChar.ToString();
        return name switch
        {
            "CWD" => root + string.Join(sep, parts[..(d - a)]),
            "CWDREL" => string.Join(sep, parts[..(d - a)]),
            "CWDTAIL" => string.Join(sep, parts[(d - a)..(d - b)]),
            _ => string.Join(sep, Enumerable.Repeat("..", d + a)),
        };
    }

    private static string Unmask(string field, string cwd) =>
        string.Concat(Regex.Split(field, "(@[A-Z]+(?:[-+][0-9]+)*@)").Select(t => Regex.Match(t, "^@([A-Z]+)([-+][0-9]+)?(?:-([0-9]+))?@$") is { Success: true } m
            ? CwdMarker(m.Groups[1].Value, m.Groups[2].Success ? (m.Groups[1].Value == "UP" ? 1 : -1) * int.Parse(m.Groups[2].Value) : 0,
                m.Groups[3].Success ? int.Parse(m.Groups[3].Value) : 0, cwd)
            : Encoding.UTF8.GetString(Convert.FromHexString(t))));

    /// <summary>
    /// The field of <paramref name="result"/>, .NET's answer in the working directory, where <paramref name="at"/> gives the answer for a
    /// given one: plain hex when another directory gives the same, else a <c>..</c> run (a marker when its length differs elsewhere), then
    /// the working directory, its start or a run of its components as a marker, then hex; the first that gives back both answers.
    /// </summary>
    private static string CwdField(string result, Func<string, string?> at)
    {
        var cwd = Directory.GetCurrentDirectory();
        Assert.True(at(cwd) == result, $"[{result}] is not what the export's model gives");
        var other = at(OtherCwd);
        if (other == result) return Hex(result);
        var sep = Path.DirectorySeparatorChar;
        var parts = cwd[Path.GetPathRoot(cwd)!.Length..].Split(sep, StringSplitOptions.RemoveEmptyEntries);
        var d = parts.Length;
        var up = result.Split(sep).TakeWhile(s => s == "..").Count();
        var upText = up == 0 ? "" : result[..(3 * up - 1)];
        var upField = up == 0 || other?.Split(sep).TakeWhile(s => s == "..").Count() == up ? Hex(upText) : up == d ? "@UP@" : $"@UP{up - d:+0;-0}@";
        var rest = result[upText.Length..];
        var lead = up > 0 ? sep.ToString() : "";
        var candidates = new List<(string Marker, string Text)>();
        for (var n = 0; n < d; n++)
        {
            candidates.Add((n == 0 ? "@CWD@" : $"@CWD-{n}@", CwdMarker("CWD", n, 0, cwd)));
            candidates.Add((n == 0 ? "@CWDREL@" : $"@CWDREL-{n}@", CwdMarker("CWDREL", n, 0, cwd)));
        }
        for (var b = 0; b < d; b++)
            for (var a = d; a > b; a--)
                candidates.Add(($"@CWDTAIL-{a}-{b}@", CwdMarker("CWDTAIL", a, b, cwd)));
        foreach (var (marker, text) in candidates)
        {
            if (!(rest == lead + text || rest.StartsWith(lead + text + sep, StringComparison.Ordinal))) continue;
            var masked = upField + Hex(lead) + marker + Hex(rest[(lead.Length + text.Length)..]);
            if (Unmask(masked, cwd) == result && Unmask(masked, OtherCwd) == other) return masked;
        }
        if (upField + Hex(rest) is var plain && Unmask(plain, cwd) == result && Unmask(plain, OtherCwd) == other) return plain;
        Assert.Fail($"cannot mask the working directory in [{result}] ([{other}] elsewhere)");
        return "";
    }

    /// <summary>The export path: <see cref="InvalidUtf8MatchesDotNet"/> with an export directory writes the driver's fixtures.</summary>
    [Fact]
    public async Task InvalidUtf8ExportsFixtures()
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "std-path-export");
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        var old = ExportOverride.Value;
        try
        {
            ExportOverride.Value = root;
            await InvalidUtf8MatchesDotNet();
        }
        finally { ExportOverride.Value = old; }
        var os = Path.Combine(root, "runtime", OperatingSystem.IsWindows() ? "windows" : OperatingSystem.IsMacOS() ? "macos" : "linux");
        var input = File.ReadAllText(Path.Combine(os, "path-relative.in"));
        var expected = File.ReadAllText(Path.Combine(os, "path-relative.expected"));
        Assert.DoesNotContain('\r', input + expected);
        var cases = input.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        Assert.True(cases.Length > 400, $"only {cases.Length} cases");
        var lines = expected.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(cases.Length, lines.Length);
        // The first case is `/<FF>/a` to `/<FF>/b`.
        Assert.Equal("2fff2f61 2fff2f62", cases[0]);
        Assert.Equal(Convert.ToHexStringLower(Encoding.UTF8.GetBytes(Relative("/\uFFFD/a", "/\uFFFD/b")!)), lines[0]);
        // The cases from the working directory carry the marker, not its bytes.
        Assert.Contains(cases, l => l.StartsWith("@CWD@", StringComparison.Ordinal));
        var cwdHex = Convert.ToHexStringLower(Encoding.UTF8.GetBytes(Directory.GetCurrentDirectory()));
        Assert.DoesNotContain(cases.Concat(lines), l => l.Contains(cwdHex, StringComparison.Ordinal));
    }

    /// <summary>Runs <c>runtime/tests/path-relative-cases.c</c> on <paramref name="input"/> and returns its output lines.</summary>
    private static async Task<string[]> RunDriver(string input)
    {
        var driver = File.ReadAllText(Path.Combine(Golden.RepoRoot, "runtime", "tests", "path-relative-cases.c"));
        var build = Toolchain.Build(driver, BuildMode.Debug);
        Assert.True(build.Succeeded, build.Errors);
        var psi = new ProcessStartInfo(build.ExecutablePath!)
        {
            WorkingDirectory = Directory.GetCurrentDirectory(),
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        using var proc = Process.Start(psi)!;
        var stderr = proc.StandardError.ReadToEndAsync();
        var stdout = proc.StandardOutput.ReadToEndLfAsync();
        proc.StandardInput.Write(input);
        proc.StandardInput.Close();
        var output = await stdout;
        var waitMs = TestTime.Scale(120_000);
        Assert.True(proc.WaitForExit(waitMs), $"driver timed out after {waitMs} ms");
        Assert.True(proc.ExitCode == 0, await stderr);
        return output.Split('\n');
    }

    // The casing .NET's path comparisons use. `OrdinalCasing.ToUpper` (a unit outside a surrogate pair) and `CharUnicodeInfo.ToUpper`
    // (a pair's scalar) are what `OrdinalIgnoreCase` calls and are internal, so they are read by reflection; the test also checks
    // each against the public `OrdinalIgnoreCase` comparison.
    private static readonly Func<char, char> OrdinalUpper = typeof(object).Assembly.GetType("System.Globalization.OrdinalCasing")!
        .GetMethod("ToUpper", BindingFlags.Static | BindingFlags.NonPublic, [typeof(char)])!.CreateDelegate<Func<char, char>>();

    private static readonly Func<uint, uint> ScalarUpper = typeof(CharUnicodeInfo)
        .GetMethod("ToUpper", BindingFlags.Static | BindingFlags.NonPublic, [typeof(uint)])!.CreateDelegate<Func<uint, uint>>();

    // One block per OS whose .NET folds case in paths, since their casing differs; Linux compares ordinally and has none.
    private static readonly string TablesOs = OperatingSystem.IsWindows() ? "Windows" : "macOS";
    private static readonly string TablesBegin = $"/* BEGIN path case tables ({TablesOs})";
    private static readonly string TablesEnd = $"/* END path case tables ({TablesOs}) */";

    /// <summary><c>{first, last, step, delta}</c> runs (step 1 or 2) of the values in <paramref name="from"/>..<paramref name="to"/> that <paramref name="map"/> moves.</summary>
    private static List<int[]> Runs(int from, int to, Func<int, int> map)
    {
        var runs = new List<int[]>();
        for (var c = from; c <= to; c++)
        {
            var delta = map(c) - c;
            if (delta == 0) continue;
            if (runs.Count > 0 && runs[^1] is var r && r[3] == delta
                && (r[0] == r[1] ? c - r[1] is 1 or 2 : c - r[1] == r[2]))
            {
                if (r[0] == r[1]) r[2] = c - r[1];
                r[1] = c;
            }
            else
            {
                runs.Add([c, c, 1, delta]);
            }
        }
        return runs;
    }

    private static string Table(string decl, IEnumerable<int[]> rows, string empty)
    {
        var items = rows.Select(r => "{" + string.Join(", ", r.Select((v, i) => i < 2 && v >= 0 ? $"0x{v:X4}" : v.ToString())) + "}").ToList();
        if (items.Count == 0) items.Add(empty);
        var sb = new StringBuilder(decl).Append(" = {\n");
        for (var i = 0; i < items.Count; i += 4)
            sb.Append("    ").Append(string.Join(", ", items.Skip(i).Take(4))).Append(i + 4 < items.Count ? ",\n" : "\n");
        return sb.Append("};\n").ToString();
    }

    private static string GenerateTables()
    {
        var invariant = Runs(0, 0xFFFF, c => char.ToUpperInvariant((char)c));
        var ordinal = Enumerable.Range(0, 0x10000).Where(c => OrdinalUpper((char)c) != char.ToUpperInvariant((char)c))
            .Select(c => new[] { c, (int)OrdinalUpper((char)c) });
        var scalar = Runs(0x10000, 0x10FFFF, c => (int)ScalarUpper((uint)c));
        return TablesBegin + ": generated by StdPathTests.CaseTablesMatchDotNet from .NET's own casing; `BAYAN_UPDATE=1` rewrites them. */\n"
            + "/* `char.ToUpperInvariant` on a UTF-16 unit: {first, last, step, delta} runs. */\n"
            + Table("static const int32_t byn_path_upper_invariant[][4]", invariant, "{-1, -1, 1, 0}")
            + "/* `OrdinalCasing.ToUpper` (`OrdinalIgnoreCase` on a unit) where it differs from `char.ToUpperInvariant`: {unit, upper}. */\n"
            + Table("static const int32_t byn_path_upper_ordinal[][2]", ordinal, "{-1, -1}")
            + "/* `CharUnicodeInfo.ToUpper` (`OrdinalIgnoreCase` on a surrogate pair's scalar): {first, last, step, delta} runs. */\n"
            + Table("static const int32_t byn_path_upper_scalar[][4]", scalar, "{-1, -1, 1, 0}")
            + TablesEnd;
    }

    /// <summary>The rows of the C array named <paramref name="name"/> in <paramref name="block"/>.</summary>
    private static List<long[]> ParseTable(string block, string name)
    {
        var start = block.IndexOf(name + "[]", StringComparison.Ordinal);
        Assert.True(start >= 0, $"no {name} in the runtime");
        var body = block[block.IndexOf('{', start)..block.IndexOf("};", start, StringComparison.Ordinal)];
        return Regex.Matches(body, @"\{([^{}]*)\}")
            .Select(m => m.Groups[1].Value.Split(',').Select(v => v.Trim()).Select(v => v.StartsWith("0x") ? Convert.ToInt64(v[2..], 16) : long.Parse(v)).ToArray())
            .ToList();
    }

    /// <summary>What <c>byn_path_runs</c> gives for <paramref name="c"/>.</summary>
    private static long Lookup(List<long[]> runs, long c)
    {
        int lo = 0, hi = runs.Count;
        while (lo < hi)
        {
            var mid = (lo + hi) / 2;
            if (runs[mid][0] <= c) lo = mid + 1;
            else hi = mid;
        }
        return lo > 0 && runs[lo - 1] is var r && c <= r[1] && (c - r[0]) % r[2] == 0 ? c + r[3] : c;
    }

    /// <summary>
    /// The runtime's case tables (<c>runtime/bayan-rt.c</c>) give <c>char.ToUpperInvariant</c> and <c>OrdinalCasing.ToUpper</c> for
    /// every one of the 65,536 UTF-16 units, and <c>CharUnicodeInfo.ToUpper</c> for every scalar above U+FFFF, as this .NET does.
    /// Only the block for the running OS is checked and, with <c>BAYAN_UPDATE=1</c>, rewritten; the other is left as it is.
    /// </summary>
    [Fact]
    public void CaseTablesMatchDotNet()
    {
        if (!OperatingSystem.IsWindows() && !OperatingSystem.IsMacOS()) return;
        var path = Path.Combine(Golden.RepoRoot, "runtime", "bayan-rt.c");
        var text = File.ReadAllText(path);
        var begin = text.IndexOf(TablesBegin, StringComparison.Ordinal);
        var end = text.IndexOf(TablesEnd, StringComparison.Ordinal);
        Assert.True(begin >= 0 && end > begin, "no case tables in the runtime");
        var block = text[begin..(end + TablesEnd.Length)];
        var generated = GenerateTables();
        // Spec 019 T26: per range, each code .NET's casing moves, as `<table> <code> <upper>` in hex; a code not listed maps to itself.
        if (ExportDir is not null)
            Export("std-path-case-tables-match-dotnet", ["invariant 0000 ffff", "ordinal 0000 ffff", "scalar 10000 10ffff"],
                Enumerable.Range(0, 0x10000).Where(c => char.ToUpperInvariant((char)c) != c).Select(c => $"invariant {c:x4} {(int)char.ToUpperInvariant((char)c):x4}")
                    .Concat(Enumerable.Range(0, 0x10000).Where(c => OrdinalUpper((char)c) != c).Select(c => $"ordinal {c:x4} {(int)OrdinalUpper((char)c):x4}"))
                    .Concat(Enumerable.Range(0x10000, 0x100000).Where(c => ScalarUpper((uint)c) != c).Select(c => $"scalar {c:x} {ScalarUpper((uint)c):x}")));
        if (Golden.UpdateMode && block != generated)
        {
            File.WriteAllText(path, text[..begin] + generated + text[(end + TablesEnd.Length)..]);
            block = generated;
        }

        var invariant = ParseTable(block, "byn_path_upper_invariant");
        var ordinal = ParseTable(block, "byn_path_upper_ordinal").ToDictionary(r => r[0], r => r[1]);
        var scalar = ParseTable(block, "byn_path_upper_scalar");
        var wrong = new List<string>();
        for (var c = 0; c <= 0xFFFF; c++)
        {
            var upper = Lookup(invariant, c);
            if (upper != char.ToUpperInvariant((char)c)) wrong.Add($"ToUpperInvariant U+{c:X4}: C {upper:X4}, .NET {(int)char.ToUpperInvariant((char)c):X4}");
            var ord = ordinal.TryGetValue(c, out var o) ? o : upper;
            if (ord != OrdinalUpper((char)c)) wrong.Add($"OrdinalCasing U+{c:X4}: C {ord:X4}, .NET {(int)OrdinalUpper((char)c):X4}");
            if (!char.IsSurrogate((char)c) && !string.Equals(((char)c).ToString(), ((char)ord).ToString(), StringComparison.OrdinalIgnoreCase))
                wrong.Add($"OrdinalIgnoreCase U+{c:X4} vs U+{ord:X4}: not equal");
        }
        for (var c = 0x10000; c <= 0x10FFFF; c++)
        {
            var upper = Lookup(scalar, c);
            if (upper != ScalarUpper((uint)c)) wrong.Add($"CharUnicodeInfo.ToUpper U+{c:X}: C {upper:X}, .NET {ScalarUpper((uint)c):X}");
            else if (upper != c && !string.Equals(char.ConvertFromUtf32(c), char.ConvertFromUtf32((int)upper), StringComparison.OrdinalIgnoreCase))
                wrong.Add($"OrdinalIgnoreCase U+{c:X} vs U+{upper:X}: not equal");
        }
        Assert.True(wrong.Count == 0, $"{wrong.Count} differences (BAYAN_UPDATE=1 regenerates the tables):\n" + string.Join("\n", wrong.Take(20)));
        Assert.True(block == generated, "the case tables are not as generated (BAYAN_UPDATE=1 regenerates them)");
    }
}
