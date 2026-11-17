using System.Runtime.CompilerServices;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// The shared build-and-run harness for the 011 emitter tests: the top-level <c>src/emitter/*.byn</c> built
/// once per run with <c>packageRoot: src/</c> (the nested <c>emitter.cprint</c> import resolves through
/// <c>Compilation.cs:187</c>), in <c>fast</c> mode, then run as a process.
/// </summary>
public static class SelfhostEmitterHarness
{
    public static string EmitterDir => Path.Combine(SelfhostSemanticsHarness.SelfhostDir, "emitter");

    private static readonly Lazy<(string? Path, string Error)> Built = new(BuildNow);

    /// <summary>The built <c>bayan-emit</c>; fails the test with the compiler's complaint.</summary>
    public static string Build()
    {
        var (path, error) = Built.Value;
        if (path is null) Assert.Fail($"src/emitter did not build:\n{error}");
        return path!;
    }

    private static (string? Path, string Error) BuildNow()
    {
        var sources = Directory.GetFiles(EmitterDir, "*.byn").Order(StringComparer.Ordinal).Select(SourceText.FromFile).ToList();
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var c = Compilation.Create(sources, packageRoot: SemanticsDir);
        if (c.Diagnostics.HasErrors) return (null, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal));
        return build.Succeeded ? (build.ExecutablePath, "") : (null, build.Errors);
    }

    private static string SemanticsDir => SelfhostSemanticsHarness.SelfhostDir;

    /// <summary>Runs the built <c>bayan-emit</c> with <paramref name="args"/>.</summary>
    public static (int Exit, string Out, string Err) Run(params string[] args) => SelfhostParserTests.Run(Build(), args);

    /// <summary>
    /// Fails with the first line where <paramref name="actual"/> differs from <paramref name="expected"/>, CRLF read as LF. With
    /// <c>BAYAN_EXPORT_DIR</c> set and an <paramref name="input"/> (the program the C# side compiled), writes the case instead (spec 019 R10);
    /// without one, lists the call in <c>emit-c/UNEXPORTED.tsv</c>, and asserts nothing either way.
    /// </summary>
    public static void AssertSame(string name, string expected, string actual, string? input = null,
        [CallerMemberName] string test = "", [CallerFilePath] string file = "")
    {
        if (SelfhostExport.Dir is { } root)
        {
            if (input is null)
            {
                var (cls, member) = ExportName(test, file);
                SelfhostExport.NotExported(root, "emit-c", cls, member, name);
                return;
            }
            var dir = ExportCase(root, name, test, file);
            SelfhostExport.WriteInput(dir, [input]);
            SelfhostExport.WriteExpected(dir, "expected.c", expected);
            return;
        }
        // The C# CLI on Windows ends some lines with Environment.NewLine; the self-hosted runtime writes LF (Q816).
        var e = expected.Replace("\r\n", "\n").Split('\n');
        var a = actual.Replace("\r\n", "\n").Split('\n');
        for (var i = 0; i < Math.Max(e.Length, a.Length); i++)
        {
            var el = i < e.Length ? e[i] : "<end>";
            var al = i < a.Length ? a[i] : "<end>";
            if (el != al) Assert.Fail($"{name}: line {i + 1} differs\nexpected: {el}\nactual:   {al}");
        }
    }

    /// <summary>A golden case copied to <c>tmp/t12-tests/&lt;slug&gt;/</c> (a directory case whole), so the CLIs see it alone; returns its entry file.</summary>
    public static string Isolate(string name)
    {
        var source = Path.Combine(Golden.CasesRoot, name);
        var caseDir = Path.GetDirectoryName(source)!;
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "t12-tests", name.Replace('/', '_'));
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        if (Path.GetFileName(source) != "main.byn") File.Copy(source, Path.Combine(dir, Path.GetFileName(source)));
        else
        {
            foreach (var file in Directory.EnumerateFiles(caseDir, "*", SearchOption.AllDirectories))
            {
                var target = Path.Combine(dir, Path.GetRelativePath(caseDir, file));
                Directory.CreateDirectory(Path.GetDirectoryName(target)!);
                File.Copy(file, target);
            }
        }
        return Path.Combine(dir, Path.GetFileName(source));
    }

    /// <summary>The mode the C# run harness builds <paramref name="path"/> in: its <c>// mode:</c> first line, else <c>safe</c> (RunTests.cs:75-78).</summary>
    public static string ModeOf(string path)
    {
        var first = File.ReadLines(path).FirstOrDefault() ?? "";
        if (first.StartsWith("// mode: ", StringComparison.Ordinal) && Toolchain.TryParseMode(first["// mode: ".Length..].Trim(), out var mode))
            return CliApp.ModeName(mode);
        return "safe";
    }

    /// <summary>
    /// The app of <c>CacheTests.ACallerIsRecheckedWhenACalleeStartsOrStopsStoringAnArgument</c> (CacheTests.cs:135-153): <c>bayan new</c>, then its
    /// <c>main.byn</c> and <c>keep.byn</c> with the callee that <c>copies</c> its argument or <c>stores</c> it (the latter is rejected, BYN3002).
    /// </summary>
    public static string CacheApp(string name, bool stores)
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "t12-tests", name);
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        Directory.CreateDirectory(root);
        var app = Path.Combine(root, "tally");
        Assert.Equal(CliApp.ExitOk, CliApp.Run(["new", app, "--vcs", "none"], new StringWriter(), new StringWriter()));
        var callee = Path.Combine(app, "src", "keep", "keep.byn");
        Directory.CreateDirectory(Path.GetDirectoryName(callee)!);
        File.WriteAllText(callee, stores
            ? "public void pass(string s, to ref string g) {\n    g = s\n}\n"
            : "public void pass(string s, to ref string g) {\n    g = \"\"\n}\n");
        File.WriteAllText(Path.Combine(app, "src", "app", "main.byn"),
            "import keep\n\nvar kept = \"\"\n{\n    using let arena = Arena()\n    keep.pass(\"ann\".copy(to: arena), to: ref kept)\n}\nprint(kept)\n");
        return app;
    }

    /// <summary>
    /// The C that <c>bayan test -v &lt;dir&gt;</c> builds for the test file <paramref name="input"/> copied alone into <paramref name="work"/>
    /// (RunTests.cs:122-131): <c>CliApp.Compile</c> of the whole directory with tests, in the mode <c>ParseBuildOptions</c> gives without
    /// <c>--mode</c> (<c>Safe</c>, CliApp.cs:154), then <c>CliApp.Test</c>'s <c>Lowerer.Lower</c> and <c>CEmitter.Emit</c> (CliApp.cs:620-621,
    /// no probes outside <c>Debug</c>), which is <c>EmitC</c>. Null when the C# rejects the input.
    /// </summary>
    public static string? TestRunC(string input, string work)
    {
        if (Directory.Exists(work)) Directory.Delete(work, recursive: true);
        Directory.CreateDirectory(work);
        File.Copy(input, Path.Combine(work, Path.GetFileName(input)));
        if (CliApp.ParseBuildOptions(["-v", work], new StringWriter(), allowOutput: false, allowTestJson: true, allowVerbose: true) is not { } o) return null;
        if (CliApp.Compile(o, new StringWriter(), includeTests: true) is not { } compiled) return null;
        return CliApp.EmitC(compiled.Compilation, o.Mode);
    }

    /// <summary><c>CliApp.Run(cli)</c> against <c>bayan-emit self</c> (with <paramref name="namedBy"/> stripped from the C# text): stdout and stderr by <see cref="AssertSame"/>, then the exit code.</summary>
    public static void SameAsCli(string name, string[] cli, string[] self, string? namedBy = null,
        [CallerMemberName] string test = "", [CallerFilePath] string file = "")
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(cli, stdout, stderr);
        // `namedBy`: a directory whose prefix the C# prints on a source's name, which `--package` gives as the file name alone (RunTests.cs:80).
        string Named(string text) => namedBy is null ? text : text.Replace(namedBy.TrimEnd('/', '\\') + Path.DirectorySeparatorChar, "");
        if (SelfhostExport.Dir is { } root)
        {
            var dir = ExportCase(root, name, test, file);
            SelfhostExport.WriteInput(dir, cli.Where(a => File.Exists(a) || Directory.Exists(a)).ToList());
            SelfhostExport.WriteExpected(dir, "args", string.Concat(cli.Select(a => a + "\n")));
            SelfhostExport.WriteExpected(dir, "expected.c", Named(stdout.ToString()));
            SelfhostExport.WriteExpected(dir, "expected.stderr", Named(stderr.ToString()));
            SelfhostExport.WriteExpected(dir, "expected.exitcode", $"{exit}\n");
            return;
        }
        var (actualExit, actualOut, actualErr) = Run(self);
        AssertSame($"{name} stderr", Named(stderr.ToString()), actualErr);
        AssertSame($"{name} stdout", Named(stdout.ToString()), actualOut);
        Assert.True(exit == actualExit, $"{name}: exit {actualExit}, expected {exit}");
    }

    /// <summary><see cref="SelfhostSemanticsHarness.Sections"/> of a <c>bayan-emit</c> run's <paramref name="stdout"/>, kept with its <paramref name="args"/> (see <see cref="Recorded"/>).</summary>
    public static Dictionary<string, List<string>> Sections(string stdout, params string[] args) =>
        Recorded(SelfhostSemanticsHarness.Sections(stdout), args);

    /// <summary><paramref name="sections"/>; under <c>BAYAN_EXPORT_DIR</c> the <c>bayan-emit</c> <paramref name="args"/> that printed them are kept for <see cref="AssertSection(Dictionary{string, List{string}}, string, IReadOnlyList{string}, string, string)"/>'s case.</summary>
    public static Dictionary<string, List<string>> Recorded(Dictionary<string, List<string>> sections, params string[] args)
    {
        if (SelfhostExport.Dir is not null) SectionArgs.AddOrUpdate(sections, args);
        return sections;
    }

    private static readonly ConditionalWeakTable<Dictionary<string, List<string>>, string[]> SectionArgs = new();

    /// <summary>
    /// <see cref="SelfhostSemanticsHarness.AssertSection"/> of a <c>bayan-emit</c> run. Under <c>BAYAN_EXPORT_DIR</c> it asserts nothing and writes
    /// <c>emit-c/&lt;Class&gt;/&lt;test&gt;[-n]</c> (class and test by <see cref="ExportName"/>) with the fixture the run read (<see cref="SelfhostExport.WriteInput"/>),
    /// <c>args</c> (the fixture as its name in the case) and <c>expected.sections</c> (the <c>== section</c> header, none for <c>""</c>, and the C# lines);
    /// a run not kept by <see cref="Recorded"/> is listed in <c>emit-c/UNEXPORTED.tsv</c>.
    /// </summary>
    public static void AssertSection(Dictionary<string, List<string>> actual, string section, IReadOnlyList<string> expected,
        [CallerMemberName] string test = "", [CallerFilePath] string file = "")
    {
        if (SelfhostExport.Dir is not { } root)
        {
            SelfhostSemanticsHarness.AssertSection(actual, section, expected);
            return;
        }
        var (cls, member) = ExportName(test, file);
        if (!SectionArgs.TryGetValue(actual, out var args))
        {
            SelfhostExport.NotExported(root, "emit-c", cls, member, section);
            return;
        }
        var dir = SelfhostExport.Case(root, "emit-c", cls, member);
        var inputs = args.Where(File.Exists).Distinct().ToList();
        if (inputs.Count > 0) SelfhostExport.WriteInput(dir, inputs);
        // The fixture as WriteInput names it in the case; another path as ExportCase keeps it.
        string Arg(string a)
        {
            if (!inputs.Contains(a)) return Portable(a);
            var name = Path.GetFileName(a);
            return inputs.Count > 1 ? $"input/{name}" : "input" + (name.IndexOf('.') is var dot and >= 0 ? name[dot..] : "");
        }
        SelfhostExport.WriteExpected(dir, "args", string.Concat(args.Select(a => Arg(a) + "\n")));
        SelfhostExport.WriteExpected(dir, "expected.sections",
            section == "" ? string.Join('\n', expected) : $"== {section}\n" + string.Concat(expected.Select(l => l + "\n")));
    }

    // ── Export (spec 019 R10) ────────────────────────────────────────────────────

    /// <summary>
    /// The class and test a case is filed under: those of the <c>[Fact]</c>/<c>[Theory]</c> frame on the stack (a call through a
    /// private helper, or a class that does not match its file as <c>SelfhostEmitterHarnessTests</c> in <c>SelfhostEmitterParityTests.cs</c>);
    /// off the test's thread (a <c>Parallel.ForEach</c>) the caller's file stem and member.
    /// </summary>
    private static (string Cls, string Test) ExportName(string test, string file)
    {
        var frame = new System.Diagnostics.StackTrace().GetFrames().Select(f => f.GetMethod())
            .FirstOrDefault(m => m is not null && m.IsDefined(typeof(FactAttribute), false));
        return (frame?.DeclaringType?.Name ?? Path.GetFileNameWithoutExtension(file), frame?.Name ?? test);
    }

    /// <summary>
    /// Creates <c>emit-c/&lt;Class&gt;/&lt;test&gt;[-&lt;row&gt;]</c> under <paramref name="root"/>, class and test by <see cref="ExportName"/>.
    /// The row is <paramref name="name"/> (the theory row, or the call's label, so a <c>Parallel.ForEach</c> names its cases the same
    /// on every run); a second call with the same name adds <c>-2</c>, <c>-3</c>, … in call order.
    /// </summary>
    private static string ExportCase(string root, string name, string test, string file)
    {
        var (cls, member) = ExportName(test, file);
        return SelfhostExport.Case(root, "emit-c", cls, $"{member}-{Portable(name)}");
    }

    /// <summary>A path in <paramref name="text"/> kept from the repo root, or past a fixture's per-run directory under the temp root (T21's <c>bayan-t21-&lt;guid&gt;</c>).</summary>
    private static string Portable(string text) =>
        System.Text.RegularExpressions.Regex.Replace(text.Replace(Golden.RepoRoot + Path.DirectorySeparatorChar, ""),
            System.Text.RegularExpressions.Regex.Escape(Path.GetTempPath()) + @"[^/\\]*[/\\]", "");
}

/// <summary>The export path itself: <see cref="SelfhostEmitterParityTests.CacheAppEmitsTheSameC"/> with the export set writes its case.</summary>
public sealed class SelfhostEmitterExportTests
{
    [Fact]
    public void ACompareCallWritesItsInputAndTheCSharpC()
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "export-test-emit-c");
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        var old = SelfhostExport.Override.Value;
        try
        {
            // An AsyncLocal, not the environment variable: tests running in parallel keep their own setting.
            SelfhostExport.Override.Value = root;
            new SelfhostEmitterParityTests().CacheAppEmitsTheSameC();
        }
        finally { SelfhostExport.Override.Value = old; }
        var dir = Path.Combine(root, "emit-c", nameof(SelfhostEmitterParityTests), "CacheAppEmitsTheSameC-copies");
        var app = Path.Combine(Golden.RepoRoot, "tmp", "t12-tests", "cache-copies", "tally");
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(["build", "--emit-c", app], stdout, stderr);
        Assert.Equal(["build", "--emit-c", app], File.ReadAllLines(Path.Combine(dir, "args")));
        Assert.Equal(stdout.ToString(), File.ReadAllText(Path.Combine(dir, "expected.c")));
        Assert.Equal(stderr.ToString(), File.ReadAllText(Path.Combine(dir, "expected.stderr")));
        Assert.Equal($"{exit}\n", File.ReadAllText(Path.Combine(dir, "expected.exitcode")));
        Assert.Equal(File.ReadAllText(Path.Combine(app, "src", "app", "main.byn")), File.ReadAllText(Path.Combine(dir, "input", "src", "app", "main.byn")));
        Assert.Equal(File.ReadAllText(Path.Combine(app, "src", "keep", "keep.byn")), File.ReadAllText(Path.Combine(dir, "input", "src", "keep", "keep.byn")));
        Assert.Single(Directory.GetDirectories(Path.Combine(root, "emit-c", nameof(SelfhostEmitterParityTests))));
    }

    /// <summary><see cref="SelfhostEmitterT6Tests.Strings_EscapeAndFieldNamesMatchCSharp"/>: an <c>AssertSection</c> writes the fixture, <c>args</c> and <c>expected.sections</c>.</summary>
    [Fact]
    public void ASectionCompareWritesTheFixtureArgsAndSections()
    {
        var root = Path.Combine(Golden.RepoRoot, "tmp", "export-test-emit-c-sections");
        if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        var old = SelfhostExport.Override.Value;
        try
        {
            SelfhostExport.Override.Value = root;
            new SelfhostEmitterT6Tests().Strings_EscapeAndFieldNamesMatchCSharp();
        }
        finally { SelfhostExport.Override.Value = old; }
        var dir = Path.Combine(root, "emit-c", nameof(SelfhostEmitterT6Tests), nameof(SelfhostEmitterT6Tests.Strings_EscapeAndFieldNamesMatchCSharp));
        Assert.Equal(["args", "expected.sections", "input.byn"], Directory.GetFiles(dir).Select(f => Path.GetFileName(f)).Order(StringComparer.Ordinal).ToArray());
        Assert.Equal("i64 f(i64 x) => x\n\nbool g(bool b) => b\n", File.ReadAllText(Path.Combine(dir, "input.byn")));
        Assert.Equal("strings\ninput.byn\n\n", File.ReadAllText(Path.Combine(dir, "args")));
        var sections = File.ReadAllLines(Path.Combine(dir, "expected.sections"));
        Assert.Equal("== strings", sections[0]);
        Assert.Equal(new[] { "int", "main", "name", "typeof", "Int", "class" }.Select(CEmitter.FieldName), sections[^6..]);
        Assert.False(File.Exists(Path.Combine(root, "emit-c", "UNEXPORTED.tsv")));
    }
}
