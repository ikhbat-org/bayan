using System.Runtime.CompilerServices;
using Bayan.Cli;

namespace Bayan.Tests;

/// <summary>
/// The shared case recorder of the export mode (spec 019 R10): with <c>BAYAN_EXPORT_DIR</c> set (or <see cref="Override"/>), a
/// compare call writes <c>&lt;kind&gt;/&lt;Class&gt;/&lt;test&gt;[-n]/</c> with its input and the C# compiler's output instead of
/// asserting. When the process exits, each <c>&lt;kind&gt;/counts.tsv</c> lists the cases written per class.
/// </summary>
public static class SelfhostExport
{
    /// <summary>The export directory a test sets for its own async flow, ahead of <c>BAYAN_EXPORT_DIR</c>; empty clears it.</summary>
    internal static readonly AsyncLocal<string?> Override = new();

    /// <summary>The class and test a case is filed under when a test runs another class's test, ahead of the caller's.</summary>
    internal static readonly AsyncLocal<(string Cls, string Test)?> Caller = new();

    /// <summary>The export directory: <see cref="Override"/>, else <c>BAYAN_EXPORT_DIR</c> when set, else null; a relative path
    /// is taken from the repo root.</summary>
    public static string? Dir =>
        (Override.Value ?? Environment.GetEnvironmentVariable("BAYAN_EXPORT_DIR")) is { Length: > 0 } dir ? Path.GetFullPath(dir, Golden.RepoRoot) : null;

    private static readonly Lock ExportLock = new();

    private static readonly Dictionary<string, int> Calls = new(StringComparer.Ordinal);

    private static readonly HashSet<string> Written = new(StringComparer.Ordinal);

    private static readonly HashSet<string> Unexported = new(StringComparer.Ordinal);

    /// <summary>A file name with the characters illegal in one replaced by <c>_</c>.</summary>
    private static string Safe(string s)
    {
        var invalid = Path.GetInvalidFileNameChars().Concat(['/', '\\', ':', '*', '?', '"', '<', '>', '|']).ToHashSet();
        return new string(s.Select(ch => invalid.Contains(ch) || char.IsControl(ch) ? '_' : ch).ToArray());
    }

    /// <summary>
    /// Creates <c>&lt;root&gt;/&lt;kind&gt;/&lt;cls&gt;/&lt;name&gt;</c>, empty; a second call with the same name adds <c>-2</c>,
    /// <c>-3</c>, … in call order.
    /// </summary>
    internal static string Case(string root, string kind, string cls, string name)
    {
        var key = Path.Combine(root, kind, Safe(cls), Safe(name));
        string dir;
        lock (ExportLock)
        {
            if (Written.Count == 0) AppDomain.CurrentDomain.ProcessExit += (_, _) => WriteCounts();
            var n = Calls[key] = Calls.GetValueOrDefault(key) + 1;
            dir = n == 1 ? key : $"{key}-{n}";
            Written.Add(dir);
        }
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        return dir;
    }

    /// <summary>A compare call that writes no case: appends <paramref name="columns"/> as a row of <c>&lt;kind&gt;/UNEXPORTED.tsv</c>
    /// (a previous process's file is replaced).</summary>
    internal static void NotExported(string root, string kind, params string[] columns)
    {
        lock (ExportLock)
        {
            var dir = Path.Combine(root, kind);
            Directory.CreateDirectory(dir);
            var path = Path.Combine(dir, "UNEXPORTED.tsv");
            if (Unexported.Add(path)) File.Delete(path);
            File.AppendAllText(path, string.Join('\t', columns) + "\n");
        }
    }

    /// <summary>Writes each kind's <c>counts.tsv</c>: each class and the cases this process wrote for it.</summary>
    internal static void WriteCounts()
    {
        lock (ExportLock)
        {
            foreach (var kind in Written.GroupBy(d => Path.GetDirectoryName(Path.GetDirectoryName(d))!))
            {
                var counts = kind.GroupBy(d => Path.GetFileName(Path.GetDirectoryName(d))!).OrderBy(g => g.Key, StringComparer.Ordinal);
                File.WriteAllText(Path.Combine(kind.Key, "counts.tsv"), string.Concat(counts.Select(g => $"{g.Key}\t{g.Count()}\n")));
            }
        }
    }

    /// <summary>
    /// The program the C# side compiled: one plain file as <c>input.&lt;ext&gt;</c>, with <c>input.name</c> holding the file's
    /// own name when it differs; a directory, or a <c>main.byn</c> (which the C# compiles with its directory, as
    /// <see cref="SelfhostEmitterHarness.Isolate"/> copies it), as the tree under <c>input/</c>; several paths each under <c>input/&lt;name&gt;</c>.
    /// </summary>
    internal static void WriteInput(string dir, IReadOnlyList<string> paths)
    {
        var trees = paths.Select(p => Directory.Exists(p) ? p : Path.GetFileName(p) == "main.byn" ? Path.GetDirectoryName(Path.GetFullPath(p))! : null).ToList();
        if (paths.Count == 1 && trees[0] is null)
        {
            var fileName = Path.GetFileName(paths[0]);
            var dot = fileName.IndexOf('.');
            var staged = "input" + (dot < 0 ? "" : fileName[dot..]);
            File.Copy(paths[0], Path.Combine(dir, staged));
            if (fileName != staged) WriteExpected(dir, "input.name", fileName + "\n");
            return;
        }
        for (var i = 0; i < paths.Count; i++)
        {
            var target = paths.Count == 1 ? Path.Combine(dir, "input") : Path.Combine(dir, "input", Path.GetFileName(Path.TrimEndingDirectorySeparator(trees[i] ?? paths[i])));
            if (trees[i] is not { } tree)
            {
                Directory.CreateDirectory(Path.GetDirectoryName(target)!);
                File.Copy(paths[i], target, overwrite: true);
                continue;
            }
            Directory.CreateDirectory(target);
            foreach (var d in Directory.EnumerateDirectories(tree, "*", SearchOption.AllDirectories))
                Directory.CreateDirectory(Path.Combine(target, Path.GetRelativePath(tree, d)));
            foreach (var f in Directory.EnumerateFiles(tree, "*", SearchOption.AllDirectories))
            {
                var to = Path.Combine(target, Path.GetRelativePath(tree, f));
                Directory.CreateDirectory(Path.GetDirectoryName(to)!);
                File.Copy(f, to, overwrite: true);
            }
        }
    }

    /// <summary>One value, UTF-8 without a BOM, LF line endings.</summary>
    internal static void WriteExpected(string dir, string fileName, string text) =>
        File.WriteAllText(Path.Combine(dir, fileName), text.Replace("\r\n", "\n"), new System.Text.UTF8Encoding(false));

    /// <summary>The text of an <c>args</c> file: one argument per line, inside one <c>\</c> written <c>\\</c>, LF <c>\n</c> and CR <c>\r</c>.</summary>
    internal static string Args(IEnumerable<string> args) =>
        string.Concat(args.Select(a => a.Replace("\\", "\\\\").Replace("\n", "\\n").Replace("\r", "\\r") + "\n"));

    /// <summary>
    /// Under the export: writes <c>cli/&lt;Class&gt;/&lt;test&gt;[-n]</c> with <c>args</c> (one per line), <c>expected.exitcode</c>,
    /// <c>expected.stdout</c> and <c>expected.stderr</c> of a C# <c>CliApp.Run</c>, the <paramref name="inputs"/> it read (see
    /// <see cref="WriteInput"/>) and each <paramref name="extra"/> file, and returns true, so the caller returns without asserting;
    /// otherwise false. The class is <paramref name="cls"/> or else <paramref name="file"/>'s stem, both replaced by <see cref="Caller"/> when set.
    /// </summary>
    public static bool Cli(IReadOnlyList<string> args, int exit, string stdout, string stderr, IReadOnlyList<string>? inputs = null,
        IReadOnlyDictionary<string, string>? extra = null, string? cls = null, [CallerMemberName] string test = "", [CallerFilePath] string file = "")
    {
        if (Dir is not { } root) return false;
        if (Caller.Value is { } caller) (cls, test) = caller;
        var dir = Case(root, "cli", cls ?? Path.GetFileNameWithoutExtension(file), test);
        if (inputs is not null) WriteInput(dir, inputs);
        WriteExpected(dir, "args", Args(args));
        WriteExpected(dir, "expected.exitcode", $"{exit}\n");
        WriteExpected(dir, "expected.stdout", stdout);
        WriteExpected(dir, "expected.stderr", stderr);
        foreach (var (name, text) in extra ?? new Dictionary<string, string>()) WriteExpected(dir, name, text);
        return true;
    }
}

/// <summary>The export path itself, with the directory set through <see cref="SelfhostExport.Override"/>.</summary>
public sealed class SelfhostExportTests
{
    private static string Fresh(string name)
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", name);
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        return root;
    }

    private static void ExportingTo(string dir, Action body)
    {
        var old = SelfhostExport.Override.Value;
        try
        {
            SelfhostExport.Override.Value = dir;
            body();
        }
        finally
        {
            SelfhostExport.Override.Value = old;
        }
    }

    [Fact]
    public void CliWritesTheCaseAndARepeatGetsARow()
    {
        var root = Fresh("export-test-cli");
        var work = Fresh("export-test-cli-input");
        Directory.CreateDirectory(work);
        var input = Path.Combine(work, "main.byn");
        File.WriteAllText(input, "print(\"hi\")\n");
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(["lex", input], stdout, stderr);
        Assert.False(SelfhostExport.Cli(["lex", input], exit, stdout.ToString(), stderr.ToString(), [input]));
        ExportingTo(root, () =>
        {
            Assert.True(SelfhostExport.Cli(["lex", input], exit, stdout.ToString(), stderr.ToString(), [input], cls: nameof(SelfhostExportTests)));
            Assert.True(SelfhostExport.Cli(["--version"], 0, "v\n", "", extra: new Dictionary<string, string> { ["stdin"] = "x\n" }, cls: nameof(SelfhostExportTests)));
        });
        var dir = Path.Combine(root, "cli", nameof(SelfhostExportTests), nameof(CliWritesTheCaseAndARepeatGetsARow));
        Assert.Equal($"lex\n{input}\n", File.ReadAllText(Path.Combine(dir, "args")));
        Assert.Equal($"{exit}\n", File.ReadAllText(Path.Combine(dir, "expected.exitcode")));
        Assert.Equal(stdout.ToString(), File.ReadAllText(Path.Combine(dir, "expected.stdout")));
        Assert.Equal(stderr.ToString(), File.ReadAllText(Path.Combine(dir, "expected.stderr")));
        Assert.Equal("print(\"hi\")\n", File.ReadAllText(Path.Combine(dir, "input", "main.byn")));
        Assert.Equal("--version\n", File.ReadAllText(Path.Combine(dir + "-2", "args")));
        Assert.Equal("x\n", File.ReadAllText(Path.Combine(dir + "-2", "stdin")));
        Assert.False(File.Exists(Path.Combine(dir + "-2", "input")));
    }

    /// <summary>The 2026-11-18 export contract: (a) <c>args</c> escapes <c>\</c>, LF and CR inside an argument; (b) a <c>sem</c>
    /// case's argument keeps its text with the repo root written <c>&lt;repo&gt;</c>; (c) a fixture staged under another name gets <c>input.name</c>.</summary>
    [Fact]
    public void ArgsEscapePathsKeepTheirTextAndAFixtureKeepsItsName()
    {
        var root = Fresh("export-test-contract");
        var work = Fresh("export-test-contract-input");
        Directory.CreateDirectory(Path.Combine(work, "sub"));
        var fixture = Path.Combine(work, "sub", "..") + "//a.byn";
        File.WriteAllText(fixture, "print(\"hi\")\n");
        File.WriteAllText(Path.Combine(work, "input.byn"), "print(\"hi\")\n");
        string[] args = ["lex", "a\nb", "c\rd", "e\\f", "g\r\nh", Golden.RepoRoot + "/tmp/../x//y", "./missing/../q"];
        ExportingTo(root, () =>
        {
            Assert.True(SelfhostExport.Cli(args, 0, "", "", [fixture], cls: nameof(SelfhostExportTests)));
            Assert.True(SelfhostExport.Cli(["lex"], 0, "", "", [Path.Combine(work, "input.byn")], cls: nameof(SelfhostExportTests)));
            var s = SelfhostSemanticsHarness.RunSections("i32 main() {\n    print(\"== alpha\")\n    print(\"a1\")\n    return 0\n}\n", args[1..]);
            SelfhostSemanticsHarness.AssertSection(s, "alpha", ["a1"], cls: nameof(SelfhostExportTests));
        });
        var dir = Path.Combine(root, "cli", nameof(SelfhostExportTests), nameof(ArgsEscapePathsKeepTheirTextAndAFixtureKeepsItsName));
        Assert.Equal($"lex\na\\nb\nc\\rd\ne\\\\f\ng\\r\\nh\n{Golden.RepoRoot}/tmp/../x//y\n./missing/../q\n", File.ReadAllText(Path.Combine(dir, "args")));
        Assert.Equal("print(\"hi\")\n", File.ReadAllText(Path.Combine(dir, "input.byn")));
        Assert.Equal("a.byn\n", File.ReadAllText(Path.Combine(dir, "input.name")));
        Assert.False(File.Exists(Path.Combine(dir + "-2", "input.name")));
        var sem = Path.Combine(root, "sem", nameof(SelfhostExportTests), nameof(ArgsEscapePathsKeepTheirTextAndAFixtureKeepsItsName));
        Assert.Equal("a\\nb\nc\\rd\ne\\\\f\ng\\r\\nh\n<repo>/tmp/../x//y\n./missing/../q\n", File.ReadAllText(Path.Combine(sem, "args")));
    }

    [Fact]
    public void AssertSameWithoutAnInputListsWithoutAsserting()
    {
        var root = Fresh("export-test-unexported");
        ExportingTo(root, () => SelfhostEmitterHarness.AssertSame("label", "a\n", "b\n"));
        Assert.Equal($"{nameof(SelfhostExportTests)}\t{nameof(AssertSameWithoutAnInputListsWithoutAsserting)}\tlabel\n",
            File.ReadAllText(Path.Combine(root, "emit-c", "UNEXPORTED.tsv")));
        ExportingTo("", () => Assert.ThrowsAny<Exception>(() => SelfhostEmitterHarness.AssertSame("label", "a\n", "b\n")));
    }
}
