using System.Text;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;
using Bayan.Testing;

namespace Bayan.Tests;

/// <summary>
/// 017 T10: <c>selfhost/emitter/coverage.byn</c> (CoverageInstrumenter.cs:33-200) and <c>schemata.byn</c> (Mutator.cs,
/// Schemata.cs) against the C# on every <c>run/</c> input, through a generated emitter main that prints the counters.
/// </summary>
public sealed class SelfhostDefaultT10Tests
{
    /// <summary>
    /// The emitter's <c>main.byn</c>: <c>coverage|mutate[-skip] dir paths…</c> (<c>-skip</c>: each path's name is a skip file); for every path, <c>== name</c>, then <c>errors</c>, or one
    /// line per counter (<c>coverage</c>), or the not-emitted counts, the switch count and the site map (<c>mutate</c>).
    /// </summary>
    private const string Main = """
        import lexer
        import semantics

        type CompilationOptions = semantics.CompilationOptions

        string t10Opt(string? s) => s ?? "-"

        i32 main(ReadOnlySpan<string> args) {
            let mode = args[0]
            let dir = args[1]
            for k in 2..args.length {
                let file = args[k]
                print($"== {Path.fileName(file)}")
                let bytes = Io.readFile(file) catch return 1
                var sources = List<lexer.SourceText>()
                sources.append(lexer.SourceText.create(Path.fileName(file), from: move bytes))
                let options = CompilationOptions {}
                var c = semantics.create(from: move sources, at: dir, by: in options)
                var failed = false
                for d in c.diagnostics {
                    if !d.isWarning { failed = true }
                }
                if failed {
                    print("errors")
                    continue
                }
                var skip = List<string>()
                if mode.endsWith("-skip") { skip.append(Path.fileName(file)) }
                if mode.startsWith("mutate") {
                    let schema = buildSchema(ref c, for: in skip)
                    for op in mutatorOperators() { print($"notEmitted {op} {schema.notEmitted.tryGet(at: op) ?? 0}") }
                    print($"switches {schema.switches.length}")
                    Io.stdout.write(sitesJson(in schema))
                    continue
                }
                let map = instrument(ref c, for: in skip)
                print($"count {map.probes.count} statements {map.probes.statements.length} branches {map.probes.branches.length} errors {map.probes.errors.length}")
                for x in map.counters {
                    var outcome = "-"
                    if (x.outcome is { } o) { outcome = o ? "true" : "false" }
                    print($"{x.id} {x.kind} {x.file} {x.line}:{x.column} {t10Opt(x.function)} {t10Opt(x.variant)} {t10Opt(x.origin)} {outcome}")
                }
            }
            return 0
        }
        """;

    private static string RunDir => Path.Combine(Golden.CasesRoot, "run");

    private static List<string> RunInputs() =>
        Directory.GetFiles(RunDir, "*.byn")
            .Where(p => !p.EndsWith(".test.byn", StringComparison.Ordinal))
            .Order(StringComparer.Ordinal)
            .ToList();

    /// <summary>What the generated main prints for <paramref name="inputs"/>, computed by the C# compiler and instrumenter.</summary>
    private static string Expected(IEnumerable<string> inputs, string dir, bool mutate = false, bool skipped = false)
    {
        var sb = new StringBuilder();
        foreach (var input in inputs)
        {
            sb.Append("== ").Append(Path.GetFileName(input)).Append('\n');
            var c = Compilation.Create([Golden.Load(input)], dir);
            if (c.Diagnostics.HasErrors)
            {
                sb.Append("errors\n");
                continue;
            }
            var skip = skipped ? new HashSet<string>(StringComparer.Ordinal) { Path.GetFileName(input) } : null;
            if (mutate)
            {
                var schema = Schemata.Build(c, skip);
                foreach (var op in Mutator.Operators) sb.Append($"notEmitted {op} {schema.NotEmitted[op]}\n");
                sb.Append($"switches {schema.Switches.Count}\n");
                sb.Append(schema.SitesJson());
                continue;
            }
            var map = CoverageInstrumenter.Instrument(c, skip);
            var p = map.Probes;
            sb.Append($"count {p.Count} statements {p.Statements.Count} branches {p.Branches.Count} errors {p.Errors.Count}\n");
            foreach (var x in map.Counters)
                sb.Append($"{x.Id} {x.Kind} {x.File} {x.Line}:{x.Column} {x.Function ?? "-"} {x.Variant ?? "-"} {x.Origin ?? "-"} {(x.Outcome is { } o ? (o ? "true" : "false") : "-")}\n");
        }
        return sb.ToString();
    }

    [Fact]
    public void CoverageCountersMatchTheCSharpOnEveryRunInput()
    {
        var inputs = RunInputs();
        Assert.NotEmpty(inputs);
        var (exit, output, error) = SelfhostParserTests.Run(Build(), ["coverage", RunDir, .. inputs]);
        Assert.True(exit == 0, $"exit {exit}\n{error}");
        SelfhostEmitterHarness.AssertSame("coverage counters", Expected(inputs, RunDir), output);
    }

    [Fact]
    public void SitesJsonMatchesTheCSharpOnEveryRunInput()
    {
        var inputs = RunInputs();
        Assert.NotEmpty(inputs);
        var (exit, output, error) = SelfhostParserTests.Run(Build(), ["mutate", RunDir, .. inputs]);
        Assert.True(exit == 0, $"exit {exit}\n{error}");
        SelfhostEmitterHarness.AssertSame("sites json", Expected(inputs, RunDir, mutate: true), output);
    }

    /// <summary>The failure path for <c>--mutate</c>: an input with errors gets no site map, and the fixture's mutants that do not re-bind are not emitted.</summary>
    [Fact]
    public void MutateSkipsAnInputWithErrorsAndMarksMutantsThatDoNotRebind()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var bad = Path.Combine(dir, "a.byn");
            File.WriteAllText(bad, "void main() { let x: i64 = \"no\" }\n");
            var good = Path.Combine(dir, "b.byn");
            File.WriteAllText(good, FailFixture);
            string[] inputs = [bad, good];
            var expected = Expected(inputs, dir, mutate: true);
            Assert.Contains("errors\n", expected);
            Assert.Contains("\"variant\"", expected);
            Assert.Contains("\"emitted\": false", expected);
            var (exit, output, error) = SelfhostParserTests.Run(Build(), ["mutate", dir, .. inputs]);
            Assert.True(exit == 0, $"exit {exit}\n{error}");
            SelfhostEmitterHarness.AssertSame("mutate failure path", expected, output);
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>The failure path: an input that does not compile gets no counters on either side, and the walk goes on to the next input.</summary>
    [Fact]
    public void AnInputWithErrorsGetsNoCountersAndTheNextStillDoes()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var bad = Path.Combine(dir, "a.byn");
            File.WriteAllText(bad, "void main() { let x: i64 = \"no\" }\n");
            var good = Path.Combine(dir, "b.byn");
            File.WriteAllText(good, FailFixture);
            string[] inputs = [bad, good];
            var expected = Expected(inputs, dir);
            Assert.Contains("errors\n", expected);
            Assert.Contains(" error ", expected);
            var (exit, output, error) = SelfhostParserTests.Run(Build(), ["coverage", dir, .. inputs]);
            Assert.True(exit == 0, $"exit {exit}\n{error}");
            SelfhostEmitterHarness.AssertSame("coverage failure path", expected, output);
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>Constant folds on <c>*</c>, <c>/</c> and <c>%</c> (negative and wide operands), floats, an escaped string, an uninitialized local, <c>do</c>/<c>while</c> and negation, in both modes, and with the input skipped.</summary>
    [Fact]
    public void FoldsFloatsAndEscapesMatchTheCSharpInBothModes()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var input = Path.Combine(dir, "w.byn");
            File.WriteAllText(input, WideFixture);
            string[] inputs = [input];
            foreach (var mode in new[] { "coverage", "mutate", "coverage-skip", "mutate-skip" })
            {
                var expected = Expected(inputs, dir, mutate: mode.StartsWith("mutate"), skipped: mode.EndsWith("-skip"));
                Assert.DoesNotContain("errors\n", expected);
                if (mode == "coverage-skip") Assert.Contains("count 0 ", expected);
                var (exit, output, error) = SelfhostParserTests.Run(Build(), [mode, dir, .. inputs]);
                Assert.True(exit == 0, $"exit {exit}\n{error}");
                SelfhostEmitterHarness.AssertSame($"wide {mode}", expected, output);
            }
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    private const string WideFixture = """
        i64 folds(i64 x) {
            let a = 6 * 7
            let b = 9 / 3
            let r = 10 % 4
            let k = 3037000499 * 3037000499
            let d = -7 / 2
            let e = -7 % 3
            let z = 5 - 5
            let o = 4611686018427387904 / 2
            var u: i64
            u = x
            var n = 0
            do {
                n += 1
            } while n < 3
            return a + b + r + u + n + -x + d + e + z + k / 3037000499 + -5 + o / 2305843009213693952
        }

        f64 half(f64 v) => v / 2.0 + 1.5

        f64 twice(f64 v) {
            return v * 2.0 + -5.0
        }

        string quoted() => "tab\there \"q\" back\\slash"

        void main() {
            print($"{folds(2)} {half(3.0)} {twice(1.0)} {quoted()}")
        }
        """;

    /// <summary>`fail`, `try` and `catch` origins, a guarded statement, `&amp;&amp;`/`||` operands, a switch guard, a method, and an assignment after a move whose removal does not re-bind.</summary>
    private const string FailFixture = """
        union error E {
            a
            b
        }

        union error F {
            c
        }

        struct Box {
            i64 value
            i64 get() => value
        }

        i64 f(i64 x) fails E, F {
            if x < 0 && x != -5 || x == 9 { fail .a }
            fail .b if x > 100
            fail .c if x == 7
            return x
        }

        i64 g(i64 x) fails E, F {
            let y = try f(x)
            let z = f(y) catch (E.a) 0
            let w = z switch {
                1 when y > 0 => 1,
                _ => z,
            }
            switch w {
                case 2 when y > 1:
                    return 2
                default:
                    return w
            }
        }

        i64 consume(move List<i64> xs) => xs.length

        i64 again() {
            var xs = List<i64>()
            let n = consume(move xs)
            xs = List<i64>()
            return n + xs.length
        }

        void main() {
            print($"{again()}")
            let b = Box { value: 1 }
            let r = g(b.get()) catch 0
            print($"{r}")
        }
        """;

    private static readonly Lazy<(string? Path, string Error)> Built = new(BuildNow);

    private static string Build()
    {
        var (path, error) = Built.Value;
        if (path is null) Assert.Fail($"selfhost/emitter with the T10 main did not build:\n{error}");
        return path!;
    }

    private static (string? Path, string Error) BuildNow()
    {
        var dir = SelfhostEmitterHarness.EmitterDir;
        var sources = Directory.GetFiles(dir, "*.byn")
            .Where(p => Path.GetFileName(p) != "main.byn")
            .Order(StringComparer.Ordinal)
            .Select(SourceText.FromFile)
            .ToList();
        sources.Add(SourceText.FromString(Path.Combine(dir, "main.byn"), Main));
        Environment.SetEnvironmentVariable("BAYAN_CACHE", Path.Combine(Golden.RepoRoot, "tmp", "cache"));
        var c = Compilation.Create(sources, packageRoot: SelfhostSemanticsHarness.SelfhostDir);
        if (c.Diagnostics.HasErrors) return (null, DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: true));
        var build = SelfhostSemanticsHarness.BuildFast(c, new HashSet<string>(StringComparer.Ordinal) { sources[^1].Path });
        return build.Succeeded ? (build.ExecutablePath, "") : (null, build.Errors);
    }
}
