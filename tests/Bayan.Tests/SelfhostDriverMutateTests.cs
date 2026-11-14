using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Reflection;
using Bayan.Backend.C;
using Bayan.Cli;
using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

/// <summary>
/// 017 T13: `mutate` and `test --mutate` through the driver against <see cref="CliApp.Run(string[], TextWriter, TextWriter)"/>. Each side
/// runs with <c>BAYAN_CACHE</c> and <c>CI</c> set in this process (<see cref="CliEnvironmentTests.WithTerminalEnv"/>), so the class is in
/// the serial <see cref="ToolchainEnvironment"/> collection: run in parallel, it moved the cache of every in-process build under other
/// tests (InstrumentedRunLawTests failed with a missing <c>tmp/t13-mutate-cache</c> path, 2026-11-13 and 2026-11-14).
/// </summary>
[Collection(nameof(ToolchainEnvironment))]
public sealed class SelfhostDriverMutateTests
{
    private const string MutateSites = SelfhostDriverT1Tests.MutateSites;

    private static string MutateDir(string name) => SelfhostDriverT1Tests.MutateDir(name);

    private static (int Exit, string Out, string Err) Oracle(string[] args) => SelfhostDriverT1Tests.Oracle(args);

    [Fact]
    public void RunsInTheSerialToolchainCollection()
    {
        var collection = typeof(SelfhostDriverMutateTests).CustomAttributes.SingleOrDefault(a => a.AttributeType == typeof(CollectionAttribute));
        Assert.Equal(nameof(ToolchainEnvironment), collection?.ConstructorArguments[0].Value);
    }

    /// <summary>
    /// 017 T13: the mutation report's measured timing masked: every value on the summary's <c>timing:</c> line, 0 included (a fast
    /// host rounds a mean to 0 on one side and not the other, 008 W6), and the JSON's seconds but an exact 0 (`mutate --binary`'s
    /// build time and share, no mutant run), which is deterministic and compared, as is the rest.
    /// </summary>
    private static string MaskMutation(string text) =>
        Regex.Replace(Regex.Replace(text, @"^timing: .*$", m => Regex.Replace(m.Value, @"(?<= )[0-9.E+-]+(?= s|%)", "<t>"), RegexOptions.Multiline),
            "\"(build_s|mean_mutant_s|max_mutant_s|total_s|mutant_share_of_build)\": (?!0[,\\n])[^,\\n]+", "\"$1\": <t>");

    /// <summary>
    /// 017 T13: <paramref name="args"/> through <c>CliApp.Run</c> and the driver with <paramref name="env"/> and a cache of each
    /// side's own; stdout and <paramref name="report"/> (when given, deleted before each side) masked by <see cref="MaskMutation"/>.
    /// </summary>
    private static void AssertMutateAsCs(string? report, (string, string?)[] env, params string[] args)
    {
        string Side(bool driver)
        {
            var cache = Path.Combine(Golden.RepoRoot, "tmp", "t13-mutate-cache", driver ? "driver" : "csharp");
            var text = "";
            CliEnvironmentTests.WithTerminalEnv(() =>
            {
                if (report is not null && File.Exists(report)) File.Delete(report);
                var (exit, stdout, stderr) = driver ? SelfhostDriverHarness.Run(args) : Oracle(args);
                text = $"exit: {exit}\n--- stdout ---\n{MaskMutation(stdout)}--- stderr ---\n{stderr}";
                if (report is not null) text += $"--- report ---\n{(File.Exists(report) ? MaskMutation(File.ReadAllText(report)) : "(none)")}";
            }, [("CI", "1"), ("BAYAN_CACHE", cache), .. env]);
            return text;
        }
        SelfhostEmitterHarness.AssertSame($"`{string.Join(' ', args)}`", Side(driver: false), Side(driver: true));
    }


    /// <summary>017 T13: ExternalSite.cs:14 `ReadAll` on site maps it refuses and on ones it reads (duplicates, a null mark).</summary>
    [Theory]
    [InlineData("not json")]
    [InlineData("[1]")]
    [InlineData("{ \"sites\": [] }")]
    [InlineData("{ \"version\": \"1\", \"sites\": [] }")]
    [InlineData("{ \"version\": 2, \"sites\": [] }")]
    [InlineData("{ \"version\": 1.5, \"sites\": [] }")]
    [InlineData("{ \"version\": 1 }")]
    [InlineData("{ \"version\": 1, \"sites\": 3 }")]
    [InlineData("{ \"version\": 1, \"sites\": [3] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": \"one\", \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": null, \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": null, \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\", \"emitted\": \"yes\" }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\", \"unobservable\": 3 }] }")]
    [InlineData("{ \"version\": 1, \"sites\": [{ \"id\": 99999999999, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\" }] }")]
    [InlineData("{ \"version\": -1, \"sites\": [] }")]
    [InlineData("{ \"version\": 1, \"version\": 2, \"sites\": [] }")]
    [InlineData("\uFEFF{ \"version\": 1, \"sites\": [] }")]
    [InlineData("{ \"version\": 2, \"version\": 1, \"sites\": [{ \"id\": -3, \"file\": \"a\", \"line\": 1, \"column\": 1, \"operator\": \"o\", \"original\": \"a\", \"mutated\": \"b\", \"unobservable\": null, \"emitted\": false }] }")]
    public void MutateSiteMapsAsCliAppDoes(string map)
    {
        var dir = MutateDir("sites");
        var bin = Path.Combine(dir, "prog");
        var sites = bin + ".sites.json";
        File.WriteAllText(bin, "");
        File.WriteAllText(sites, map);
        AssertMutateAsCs(Path.Combine(dir, "bayan-quality.json"), [], "mutate", "--binary", bin, "--sites", sites, "--", "true");
    }

    /// <summary>
    /// 017 T13: CliApp.cs:918 `File.ReadAllText` on a site map in each encoding its byte order mark names (UTF-16 and UTF-32, each byte
    /// order), and on bytes it decodes with U+FFFD: invalid UTF-8 (each maximal subpart, and a sequence cut off by the end); lone UTF-16
    /// surrogates in each byte order, an odd trailing byte and a high surrogate as the last unit; UTF-32 values past U+10FFFF or in the
    /// surrogate range in each byte order, and a partial last unit. Also a UTF-16 map without a byte order mark and a one-byte map, which
    /// the C# refuses as a site map.
    /// </summary>
    [Theory]
    [InlineData("utf16le")]
    [InlineData("utf16be")]
    [InlineData("utf32le")]
    [InlineData("utf32be")]
    [InlineData("utf8-ff")]
    [InlineData("utf8-truncated")]
    [InlineData("utf8-overlong")]
    [InlineData("utf8-end")]
    [InlineData("utf16le-lone")]
    [InlineData("utf16be-lone")]
    [InlineData("utf16be-odd")]
    [InlineData("utf32le-invalid")]
    [InlineData("utf32be-invalid")]
    [InlineData("utf16le-high-end")]
    [InlineData("utf32le-partial")]
    [InlineData("utf16le-nobom")]
    [InlineData("short")]
    public void MutateEncodedSiteMapsAsCliAppDoes(string encoding)
    {
        var dir = MutateDir($"encoded-{encoding}");
        var bin = Path.Combine(dir, "prog");
        var sites = bin + ".sites.json";
        File.WriteAllText(bin, "");
        static string Map(string file) => "{ \"version\": 1, \"sites\": [{ \"id\": 1, \"file\": \"" + file + "\", \"line\": 1, \"column\": 1, \"operator\": \"bool\", \"original\": \"t\", \"mutated\": \"f\" }] }";
        static byte[] With(System.Text.Encoding e, string text) => [.. e.GetPreamble(), .. e.GetBytes(text)];
        static byte[] Split(byte[] bytes, string at, byte[] insert)
        {
            var i = System.Text.Encoding.Latin1.GetString(bytes).IndexOf(at, StringComparison.Ordinal);
            return [.. bytes[..i], .. insert, .. bytes[i..]];
        }
        var utf16le = new System.Text.UnicodeEncoding(bigEndian: false, byteOrderMark: true);
        var utf16be = new System.Text.UnicodeEncoding(bigEndian: true, byteOrderMark: true);
        var utf32le = new System.Text.UTF32Encoding(bigEndian: false, byteOrderMark: true);
        var utf32be = new System.Text.UTF32Encoding(bigEndian: true, byteOrderMark: true);
        var good = Map("a\u00e9\U0001F600.byn");
        File.WriteAllBytes(sites, encoding switch
        {
            "utf16le" => With(utf16le, good),
            "utf16be" => With(utf16be, good),
            "utf32le" => With(utf32le, good),
            "utf32be" => With(utf32be, good),
            "utf8-ff" => Split(System.Text.Encoding.UTF8.GetBytes(Map("a.byn")), ".byn", [0xFF]),
            "utf8-truncated" => Split(System.Text.Encoding.UTF8.GetBytes(Map("a.byn")), ".byn", [0xE2, 0x82]),
            "utf8-overlong" => Split(System.Text.Encoding.UTF8.GetBytes(Map("a.byn")), ".byn", [0xC0, 0x80, 0xED, 0xA0, 0x80, 0xE0, 0x80, 0xF0, 0x80, 0xF4, 0x90, 0xE2, 0x82, 0xAC, 0xF4, 0x8F, 0xBF, 0xBF]),
            "utf8-end" => [.. System.Text.Encoding.UTF8.GetPreamble(), .. System.Text.Encoding.UTF8.GetBytes(Map("a.byn")), 0xE2],
            "utf16le-lone" => [.. utf16le.GetPreamble(), .. Split(utf16le.GetBytes(Map("a.byn")), ".\0b\0", [0x00, 0xD8, 0x41, 0x00, 0x00, 0xD8, 0x21, 0xFF, 0x00, 0xDC])],
            "utf16be-lone" => [.. utf16be.GetPreamble(), .. Split(utf16be.GetBytes(Map("a.byn")), "\0.\0b", [0xD8, 0x00, 0x00, 0x41, 0xD8, 0x00, 0xFF, 0x21, 0xDC, 0x00])],
            "utf16le-high-end" => [.. With(utf16le, good), 0x00, 0xD8],
            "utf32le-partial" => [.. With(utf32le, good), 0x41],
            "short" => [0x31],
            "utf16be-odd" => [.. With(utf16be, good), 0x41],
            "utf32le-invalid" => [.. utf32le.GetPreamble(), .. Split(utf32le.GetBytes(Map("a.byn")), ".\0\0\0b", [0x00, 0x00, 0x11, 0x00, 0x00, 0xD8, 0x00, 0x00])],
            "utf32be-invalid" => [.. utf32be.GetPreamble(), .. Split(utf32be.GetBytes(Map("a.byn")), "\0\0\0.\0\0\0b", [0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0xD8, 0x00])],
            _ => utf16le.GetBytes(good),
        });
        AssertMutateAsCs(Path.Combine(dir, "bayan-quality.json"), [], "mutate", "--binary", bin, "--sites", sites, "--", "true");
    }

    /// <summary>
    /// 017 T13: `JsonDocument.Parse`'s depth limit (ExternalSite.cs:18): a site map nested <paramref name="depth"/> deep (the root object,
    /// then arrays in an extra member), at the limit and one past it.
    /// </summary>
    [Theory]
    [InlineData(64)]
    [InlineData(65)]
    public void MutateDeepSiteMapsAsCliAppDoes(int depth)
    {
        var dir = MutateDir($"deep-{depth}");
        var bin = Path.Combine(dir, "prog");
        var sites = bin + ".sites.json";
        File.WriteAllText(bin, "");
        File.WriteAllText(sites, "{ \"version\": 1, \"sites\": [], \"x\": " + new string('[', depth - 1) + new string(']', depth - 1) + " }");
        AssertMutateAsCs(Path.Combine(dir, "bayan-quality.json"), [], "mutate", "--binary", bin, "--sites", sites, "--", "true");
    }

    /// <summary>017 T13: MutationRunner.cs:85 `RunExternal` through `mutate`: each status, `BAYAN_BINARY`, and a baseline that fails or cannot start.</summary>
    [Fact]
    public void MutateExternalAsCliAppDoes()
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = MutateDir("external");
        var bin = Path.Combine(dir, "prog");
        var sites = bin + ".sites.json";
        File.WriteAllText(bin, "");
        File.WriteAllText(sites, MutateSites);
        var report = Path.Combine(dir, "bayan-quality.json");
        string[] Mutate(string script) => ["mutate", "--binary", bin, "--sites", sites, "--", "/bin/sh", "-c", script];
        AssertMutateAsCs(report, [], Mutate("[ \"$BAYAN_BINARY\" = \"" + Path.GetFullPath(bin) + "\" ] || exit 9; case $BAYAN_MUTANT in 2|4) exit 1;; 5) sleep 3;; esac; exit 0"));
        AssertMutateAsCs(report, [], Mutate("exit 3"));
        AssertMutateAsCs(report, [], Mutate("[ \"$BAYAN_MUTANT\" = 0 ] && sleep 3; exit 0"));
        AssertMutateAsCs(report, [("BAYAN_TEST_TIMEOUT_MS", "300")], Mutate("[ \"$BAYAN_MUTANT\" = 0 ] && sleep 3; exit 0"));
        AssertMutateAsCs(report, [], "mutate", "--binary", bin, "--sites", sites, "--", "nosuchcmd-xyz");
        AssertMutateAsCs(report, [], Mutate("kill -9 $$"));
        // each operator's suggestion (QualityReport.cs:47 `Suggest`): every site survives
        File.WriteAllText(sites, "{ \"version\": 1, \"sites\": [ { \"id\": 1, \"file\": \"c.byn\", \"line\": 1, \"column\": 1, \"operator\": \"boundary\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 2, \"file\": \"c.byn\", \"line\": 2, \"column\": 1, \"operator\": \"relational\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 3, \"file\": \"c.byn\", \"line\": 3, \"column\": 1, \"operator\": \"logical\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 4, \"file\": \"c.byn\", \"line\": 4, \"column\": 1, \"operator\": \"condition\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 5, \"file\": \"c.byn\", \"line\": 5, \"column\": 1, \"operator\": \"bool\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 6, \"file\": \"c.byn\", \"line\": 6, \"column\": 1, \"operator\": \"arithmetic\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 7, \"file\": \"c.byn\", \"line\": 7, \"column\": 1, \"operator\": \"literal\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 8, \"file\": \"c.byn\", \"line\": 8, \"column\": 1, \"operator\": \"negation\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 9, \"file\": \"c.byn\", \"line\": 9, \"column\": 1, \"operator\": \"statement\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 10, \"file\": \"c.byn\", \"line\": 10, \"column\": 1, \"operator\": \"emptyReturn\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 11, \"file\": \"c.byn\", \"line\": 11, \"column\": 1, \"operator\": \"variant\", \"original\": \"a\", \"mutated\": \"b\" }, { \"id\": 12, \"file\": \"c.byn\", \"line\": 12, \"column\": 1, \"operator\": \"mystery\", \"original\": \"a\", \"mutated\": \"b\" } ] }");
        AssertMutateAsCs(report, [], Mutate("exit 0"));
    }

    /// <summary>017 T13: `test --mutate` (CliApp.cs:855): killed, survived, timeout, marked, not-reached and not-emitted (MutantSchemataTests.cs:222) mutants, a pending and a failing test, and `--run`.</summary>
    [Fact]
    public void TestMutateAsCliAppDoes()
    {
        if (OperatingSystem.IsWindows()) return;
        var dir = MutateDir("tests");
        File.WriteAllText(Path.Combine(dir, "a.test.byn"), """
            i64 inc(i64 n) {
                var y = n
                @unobservable because "no test can see it"
                y += 0
                return n + 1
            }

            i64 spin(i64 n) {
                var i: i64 = 0
                while i < n {
                    i += 1
                }
                return i
            }

            i64 unused(i64 n) => n * 2

            u8 top() {
                return (250 + 4) + 1
            }

            test "inc" {
                assert inc(1) > 0
            }

            test "spin" {
                assert spin(2) == 2
            }

            test "nothing" {
                assert true
            }

            test "later" {
                todo("x")
            }

            test "broken" {
                assert inc(1) == 3
            }

            """);
        AssertMutateAsCs(null, [], "test", "--mutate", dir);
        var loose = MutateDir("run");
        File.WriteAllText(Path.Combine(loose, "a.test.byn"), "i64 inc(i64 n) {\n    return n + 1\n}\n\ntest \"inc\" {\n    assert inc(1) == 2\n}\n");
        var report = Path.Combine(loose, "out", "test", "bayan-quality.json");
        AssertMutateAsCs(report, [], "test", "--mutate", "--run", "\"$BAYAN_BINARY\" --test 0 >/dev/null", loose);
        AssertMutateAsCs(report, [], "test", "--mutate", "--run", "exit 0", Path.Combine(loose, "a.test.byn"));
        var project = MutateDir("project");
        File.WriteAllText(Path.Combine(project, "package.byn"), "Package {\n    name: \"local/inc\",\n    version: \"0.1.0\",\n    edition: 2027,\n    kind: .lib,\n}\n");
        Directory.CreateDirectory(Path.Combine(project, "src", "inc"));
        File.WriteAllText(Path.Combine(project, "src", "inc", "a.test.byn"), "i64 inc(i64 n) {\n    return n + 1\n}\n\ntest \"inc\" {\n    assert inc(1) == 2\n}\n");
        AssertMutateAsCs(Path.Combine(project, "out", "test", "bayan-quality.json"), [], "test", "--mutate", "--run", "exit 1", project);
        AssertMutateAsCs(null, [], "test", "--mutate", project);
        // CliApp.cs:878-879: the mutation gate under a manifest minimum, missed (a survivor) and met.
        var gated = MutateDir("gated");
        Directory.CreateDirectory(Path.Combine(gated, "src", "inc"));
        File.WriteAllText(Path.Combine(gated, "src", "inc", "a.test.byn"), "i64 inc(i64 n) {\n    return n + 1\n}\n\ntest \"inc\" {\n    assert inc(1) > 0\n}\n");
        foreach (var min in new[] { 100, 0 })
        {
            File.WriteAllText(Path.Combine(gated, "package.byn"), $"Package {{\n    name: \"local/inc\",\n    version: \"0.1.0\",\n    edition: 2027,\n    kind: .lib,\n    test: Tests {{ mutation: {min} }},\n}}\n");
            AssertMutateAsCs(null, [], "test", "--mutate", gated);
        }
        var noCc = MutateDir("no-cc");
        AssertMutateAsCs(null, [("PATH", noCc), ("BAYAN_CACHE", noCc)], "test", "--mutate", loose);
    }
}
