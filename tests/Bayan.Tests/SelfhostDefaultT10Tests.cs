using System.Text;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Lowering;
using Bayan.Semantics;
using Bayan.Semantics.Binding;
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
    /// The emitter's <c>main.byn</c>: <c>coverage|mutate[-skip|-tests] dir paths…</c> (<c>-skip</c>: each path's name is a skip file; <c>-tests</c>: compiled with tests); for every path, <c>== name</c>, then <c>errors</c>, or one
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
                let options = CompilationOptions { includeTests: mode.contains("-tests") }
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
                if mode.endsWith("-skip") {
                    skip.append("-")
                    skip.append(Path.fileName(file))
                }
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
    private static string Expected(IEnumerable<string> inputs, string dir, bool mutate = false, bool skipped = false, bool tests = false)
    {
        var sb = new StringBuilder();
        foreach (var input in inputs)
        {
            sb.Append("== ").Append(Path.GetFileName(input)).Append('\n');
            var c = Compilation.Create([Golden.Load(input)], dir, new CompilationOptions(IncludeTests: tests));
            if (c.Diagnostics.HasErrors)
            {
                sb.Append("errors\n");
                continue;
            }
            var skip = skipped ? new HashSet<string>(StringComparer.Ordinal) { "-", Path.GetFileName(input) } : null;
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

    /// <summary>The edge fixture's counters, site JSON (with the input skipped too) and the C of both builds match the C#.</summary>
    [Fact]
    public void EdgeFixtureMatchesTheCSharpInBothModes()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var input = Path.Combine(dir, "e.byn");
            File.WriteAllText(input, EdgeText);
            string[] inputs = [input];
            foreach (var mode in new[] { "coverage", "mutate", "coverage-skip", "mutate-skip" })
            {
                var expected = Expected(inputs, dir, mutate: mode.StartsWith("mutate"), skipped: mode.EndsWith("-skip"));
                Assert.DoesNotContain("errors\n", expected);
                var (exit, output, error) = SelfhostParserTests.Run(Build(), [mode, dir, .. inputs]);
                Assert.True(exit == 0, $"exit {exit}\n{error}");
                SelfhostEmitterHarness.AssertSame($"edge {mode}", expected, output);
            }
            var c = Compilation.Create([Golden.Load(input)], dir);
            Assert.False(c.Diagnostics.HasErrors);
            foreach (var flag in new[] { "--coverage", "--mutate" })
            {
                var expected = ExpectedC(c, BuildMode.Safe, mutate: flag == "--mutate");
                var (exit, output, error) = SelfhostEmitterHarness.Run(flag, "--package", dir, input);
                Assert.True(exit == 0, $"{flag}: exit {exit}\n{error}");
                SelfhostEmitterHarness.AssertSame($"edge {flag}", expected, output);
            }
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    public static TheoryData<string> RunCases => Golden.Cases("run");

    /// <summary>The C a <c>--coverage</c> (CliApp.cs:639-641) or <c>--mutate</c> (CliApp.cs:840-842) build of <paramref name="c"/> emits.</summary>
    private static string ExpectedC(Compilation c, BuildMode mode, bool mutate)
    {
        var program = mutate
            ? Lowerer.Lower(c, Schemata.Build(c).Switches)
            : Lowerer.Lower(c, coverage: CoverageInstrumenter.Instrument(c).Probes);
        return CEmitter.Emit(program, mode == BuildMode.Debug);
    }

    private static void SameC(string input, string flag)
    {
        var dir = Path.GetDirectoryName(input)!;
        var mode = SelfhostEmitterHarness.ModeOf(input);
        var c = Compilation.Create([Golden.Load(input)], dir);
        if (c.Diagnostics.HasErrors) return;
        Toolchain.TryParseMode(mode, out var buildMode);
        var expected = ExpectedC(c, buildMode, mutate: flag == "--mutate");
        var (exit, output, error) = SelfhostEmitterHarness.Run(flag, "--mode", mode, "--package", dir, input);
        Assert.True(exit == 0, $"{input}: exit {exit}\n{error}");
        SelfhostEmitterHarness.AssertSame($"{Path.GetFileName(input)} {flag}", expected, output);
    }

    /// <summary><c>bayan-emit --coverage</c> on every <c>run/</c> input emits the C# coverage build's C.</summary>
    [Theory]
    [MemberData(nameof(RunCases))]
    public void CoverageCMatchesTheCSharpOnEveryRunInput(string name)
    {
        if (name.EndsWith(".test.byn", StringComparison.Ordinal)) return;
        SameC(Path.Combine(Golden.CasesRoot, name), "--coverage");
    }

    /// <summary><c>bayan-emit --mutate</c> on every <c>run/</c> input emits the C# mutate build's C.</summary>
    [Theory]
    [MemberData(nameof(RunCases))]
    public void MutateCMatchesTheCSharpOnEveryRunInput(string name)
    {
        if (name.EndsWith(".test.byn", StringComparison.Ordinal)) return;
        SameC(Path.Combine(Golden.CasesRoot, name), "--mutate");
    }

    /// <summary>The fixtures' C in both builds and with both flags (error probes of <c>try</c>/<c>catch</c>, branch probes, folds), and an input with errors fails as <c>bayan build</c> does.</summary>
    [Fact]
    public void FixtureCMatchesAndAnInputWithErrorsFailsAsBuildDoes()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var bad = Path.Combine(dir, "a.byn");
            File.WriteAllText(bad, "void main() { let x: i64 = \"no\" }\n");
            foreach (var (file, text) in new[] { ("b.byn", FailFixture), ("w.byn", WideFixture) })
            {
                var input = Path.Combine(dir, file);
                File.WriteAllText(input, text);
                foreach (var flag in new[] { "--coverage", "--mutate" })
                {
                    var c = Compilation.Create([Golden.Load(input)], dir);
                    Assert.False(c.Diagnostics.HasErrors);
                    var expected = ExpectedC(c, BuildMode.Safe, mutate: flag == "--mutate");
                    Assert.Contains(flag == "--mutate" ? "byn_mutant_is(" : "byn_cov[", expected);
                    var (exit, output, error) = SelfhostEmitterHarness.Run(flag, "--package", dir, input);
                    Assert.True(exit == 0, $"{file} {flag}: exit {exit}\n{error}");
                    SelfhostEmitterHarness.AssertSame($"{file} {flag}", expected, output);
                }
                // Both flags: `Lowerer.Lower` given the switches and the probes, so a statement under a mutant switch has one probe.
                var both = Compilation.Create([Golden.Load(input)], dir);
                var bothC = CEmitter.Emit(Lowerer.Lower(both, Schemata.Build(both).Switches, CoverageInstrumenter.Instrument(both).Probes));
                var bothRun = SelfhostEmitterHarness.Run("--coverage", "--mutate", "--package", dir, input);
                Assert.True(bothRun.Exit == 0, $"{file} both: exit {bothRun.Exit}\n{bothRun.Err}");
                SelfhostEmitterHarness.AssertSame($"{file} --coverage --mutate", bothC, bothRun.Out);
            }
            foreach (var flag in new[] { "--coverage", "--mutate" })
                SelfhostEmitterHarness.SameAsCli($"errors {flag}", ["build", "--emit-c", bad], [flag, bad]);
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>
    /// The rich fixture (compound assignments, <c>while true</c>, <c>unless</c>, payload variants, indexes from the end, a getter, a
    /// method, a lambda, a generic, control characters in a literal, a <c>try</c> inside a mutated sum and a test): counters, site
    /// JSON and the C of <c>--coverage</c>, <c>--tests --coverage</c>, <c>--mutate</c> and a plain build, by path and by <c>--package</c>.
    /// </summary>
    [Fact]
    public void RichFixtureMatchesTheCSharpInEveryBuild()
    {
        var dir = Path.Combine(Path.GetTempPath(), "bayan-017-t10-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var input = Path.Combine(dir, "r.byn");
            File.WriteAllText(input, RichFixture);
            string[] inputs = [input];
            foreach (var mode in new[] { "coverage", "mutate", "coverage-tests", "mutate-tests" })
            {
                var (exit, output, error) = SelfhostParserTests.Run(Build(), [mode, dir, .. inputs]);
                Assert.True(exit == 0, $"exit {exit}\n{error}");
                var expected = Expected(inputs, dir, mutate: mode.StartsWith("mutate"), tests: mode.EndsWith("-tests"));
                SelfhostEmitterHarness.AssertSame($"rich {mode}", expected, output);
            }
            var c = Compilation.Create([Golden.Load(input)], dir);
            Assert.False(c.Diagnostics.HasErrors);
            var tested = Compilation.Create([Golden.Load(input)], dir, new CompilationOptions(IncludeTests: true));
            Assert.False(tested.Diagnostics.HasErrors);
            var cases = new (string[] Args, string Expected)[]
            {
                (["--coverage", "--package", dir, input], ExpectedC(c, BuildMode.Safe, mutate: false)),
                (["--coverage", input], ExpectedC(c, BuildMode.Safe, mutate: false)),
                (["--mutate", input], ExpectedC(c, BuildMode.Safe, mutate: true)),
                (["--mutate", "--mode", "debug", "--package", dir, input], ExpectedC(c, BuildMode.Debug, mutate: true)),
                (["--tests", "--coverage", "--package", dir, input], ExpectedC(tested, BuildMode.Safe, mutate: false)),
                (["--package", dir, input], CliApp.EmitC(c, BuildMode.Safe)),
                ([input], CliApp.EmitC(c, BuildMode.Safe)),
            };
            foreach (var (args, expected) in cases)
            {
                var (exit, output, error) = SelfhostEmitterHarness.Run(args);
                Assert.True(exit == 0, $"{string.Join(' ', args)}: exit {exit}\n{error}");
                SelfhostEmitterHarness.AssertSame($"rich {string.Join(' ', args[..^1])}", expected, output);
            }
            Assert.Equal(2, SelfhostEmitterHarness.Run("--coverage", "--package", dir).Exit); // no-oracle: Q814 `--package` without a file is usage
        }
        finally
        {
            Directory.Delete(dir, recursive: true);
        }
    }

    private const string RichFixture = """
        union error E {
            a
            b(i64 code)
            c(i64 code)
        }

        struct Point {
            i64 x
            i64 y

            i64 sum => x + y

            i64 scaled(i64 k) => x * k + y
        }

        T pick<T>(move T a) => a

        i64 risky(i64 x) fails E {
            fail .b(code: x) if x > 10
            fail .c(code: 1) if x == 3
            unless x != 4 { fail .a }
            return x * 2
        }

        i64 chain(i64 x) fails E {
            let v = (try risky(x)) + 1
            return v - 1
        }

        i64 loops(i64 n) {
            var total: i64 = 0
            var i: i64 = 0
            while true {
                if i >= n { break }
                total += i
                total -= 1
                total *= 2
                total /= 2
                total %= 1000
                i += 1
            }
            var xs = [1, 2, 3]
            xs[0] = 7
            xs[^1] = 9
            do {
                total += 1
            } while false
            var flag = false
            flag = true
            if flag && true { total -= 1 }
            let small: i32 = -5
            let f: i64 -> i64 = a => a + 1
            return total + xs[0] + xs[^1] + i64(small) + f(1) + pick(1)
        }

        string escapes() => "a\rb\u{0C}c\u{08}d\u{01}e"

        void main() {
            let p = Point { x: 1, y: 2 }
            let r = chain(2) catch 0
            let q = risky(20) catch 5
            print($"{p.sum} {p.scaled(3)} {r} {q} {loops(5)} {escapes()}")
        }

        test "loops count" {
            assert loops(3) > -100
        }
        """;

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

        i64 plusNever(i64 x) => x + panic("no")

        bool andNever(bool a) => a && panic("no")

        void ifNever(i64 x) {
            if panic("no") { print("a") }
        }

        void main() {
            print($"{folds(2)} {half(3.0)} {twice(1.0)} {quoted()}")
            if folds(0) < 0 {
                print($"{plusNever(1)} {andNever(a: true)}")
                ifNever(1)
            }
        }
        """;

    /// <summary>
    /// The edge fixture (generic function and method instantiated twice, an <c>out</c> argument to an uninitialized local, <c>k++</c>,
    /// a suffixed literal, an index by a variable and by a <c>u</c> literal, <c>i8</c> -128, constant conditions, a <c>catch</c> of a
    /// variant, <c>unless</c> and <c>s unless c</c> on a constant (a literal whose value is not its keyword's), a function failing a
    /// set and its <c>except</c> union, a <c>try</c> on <c>Io.readFile</c>, a never-typed operand and control characters inside a mutated condition);
    /// <c>{ctl}</c> and the line break after <c>&amp;&amp;</c> are replaced by <see cref="EdgeText"/>.
    /// </summary>
    private const string EdgeFixture = """
        union error G {
            a
        }

        union error H {
            p(i64 code)
            q(i64 code)
        }

        union error N = H except .q

        union error K {
            m(i64 code)
            n(string why)
        }

        struct Cell<T> {
            T value

            i64 take(i64 n) fails H {
                fail .p (code: n) if n < 0
                return -n
            }
        }

        T keep<T>(move T a, by i64 n, as bool flip) fails H {
            let m = -n
            let on = true
            var k = 0
            k++
            k += 2
            if m > 5 && on { fail H.q (code: m) }
            if !flip { return a }
            return a
        }

        T? opt<T>(move T a) {
            return a
        }

        i64 narrow(i64 n) fails N {
            fail .p (code: n) if n < 0
            return n
        }

        i64 kf(i64 n) fails K {
            fail .m (code: n) if n < 0
            return n
        }

        i64 wide(i64 n) fails H {
            return try narrow(n)
        }

        i64 both(i64 n) fails H, N {
            fail H.p (code: n) if n < 0
            return n
        }

        void setIt(out i64 v) {
            v = 4
        }

        i64 only() fails G {
            fail .a
        }

        i64 load() fails IoError {
            let b = try Io.readFile("none.txt")
            return b.length
        }

        string raw() {
            return "ab"
        }

        const enabled: bool = true

        const limit: i64 = 3

        i64 edges(i64 x) fails G {
            var u: i64
            setIt(out u)
            var w: i64
            w = 1
            w += 2
            let s = 5u
            let small: i8 = -128
            let q = 7 / 1
            let d = 7 * -2
            let arr: i64[3] = [1, 2, 3]
            let j = 1
            let a1 = arr[j] + arr[1u] + arr[2ul] + -limit
            var n = 0
            do {
                n += 1
                if n > 3 { break }
            } while true
            while false { n += 1 }
            unless false { n += 2 }
            n += 4 unless false
            n += 5 unless true
            if enabled { n += 1 }
            let v = only() catch (G.a) 3
            let ok = x > 0 || panic("negative")
            let odd = x > 0 &&
                raw() != "{ctl}"
            return n + u + w + i64(s) + i64(small) + q + d + a1 + v + x + (odd ? 1 : 0) + (ok ? 1 : 0)
        }

        i64 total() {
            let c = Cell<i64> { value: 1 }
            let t = Cell<string> { value: "t" }
            let r = c.take(2) catch 0
            let rt = t.take(2) catch 0
            let k1 = keep(1, by: 2, as: true) catch 0
            let k2 = keep("s", by: 2, as: false) catch ""
            let v2 = only() catch (G.a) 4
            let e = edges(1) catch 0
            let l = load() catch 0
            let o1 = opt(1) ?? 0
            let o2 = opt("s") ?? "n"
            let nw = wide(1) catch 0
            let nk = kf(1) catch 0
            let nb = both(1) catch 0
            print($"{o1} {o2} {nw} {nk} {nb}")
            print($"{k2} {raw()}")
            return r + rt + k1 + v2 + e + l
        }

        void main() {
            print($"{total()}")
        }
        """;

    private static string EdgeText => EdgeFixture.Replace("&&\n", "&&\r\n").Replace("{ctl}", "a\tb\u0001c\bd\fe");

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
