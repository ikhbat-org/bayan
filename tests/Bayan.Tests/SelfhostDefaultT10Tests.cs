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
    /// <summary>The emitter's <c>main.byn</c>: for every path after the package directory, <c>== name</c>, then <c>errors</c> or one line per counter.</summary>
    private const string Main = """
        import lexer
        import semantics

        type CompilationOptions = semantics.CompilationOptions

        string t10Opt(string? s) => s ?? "-"

        i32 main(ReadOnlySpan<string> args) {
            let dir = args[0]
            for k in 1..args.length {
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
                let skip = List<string>()
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
    private static string Expected(IEnumerable<string> inputs, string dir)
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
            var map = CoverageInstrumenter.Instrument(c);
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
        var (exit, output, error) = SelfhostParserTests.Run(Build(), [RunDir, .. inputs]);
        Assert.True(exit == 0, $"exit {exit}\n{error}");
        SelfhostEmitterHarness.AssertSame("coverage counters", Expected(inputs, RunDir), output);
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
            var (exit, output, error) = SelfhostParserTests.Run(Build(), [dir, .. inputs]);
            Assert.True(exit == 0, $"exit {exit}\n{error}");
            SelfhostEmitterHarness.AssertSame("coverage failure path", expected, output);
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>`fail`, `try` and `catch` origins, a guarded statement, `&amp;&amp;`/`||` operands, a switch guard and a generic method.</summary>
    private const string FailFixture = """
        union error E {
            a
            b
        }

        union error F {
            c
        }

        struct Box<T> {
            T value
            T get() => value
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

        void main() {
            let b = Box<i64> { value: 1 }
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
