using Bayan.Semantics;
using Bayan.Syntax.Packages;
using SourceText = Bayan.Syntax.Text.SourceText;

namespace Bayan.Tests;

/// <summary>
/// Spec 018 T8: BYN5106 (a type named for a doer without its verb) and BYN5107 (a tool that changes <c>this</c>) of revision
/// 0021 Part 4, ported to naming.byn (<c>checkDoer</c>, <c>actsAs</c>, <c>t8DeclRenamed</c>, <c>doerVerb</c>, <c>isTool</c>,
/// <c>doerNouns</c> and their calls in <c>checkMembersWith</c> and <c>checkSignatures</c>) and codes.byn, with the Part 3 fixes
/// 5a (<c>checkParticiple</c> reads a <c>forms</c> key as <c>-ed</c> only for a verb, <c>isVerb</c>) and 5b (manifest.byn's
/// <c>t10CheckOverlap</c> skips a list that is not all words), against the C# <c>Naming</c> and <c>Manifest</c>. Programs compare
/// as <c>code line:col message</c> with label, help and fix. Every expected line is computed from the C#.
/// </summary>
public sealed class SelfhostRevisionT8Tests
{
    /// <summary>Each program: its name, the code it must report (null: neither BYN5106 nor BYN5107), its <c>package.byn</c> (or null) and its <c>main.byn</c>.</summary>
    private static readonly (string Name, string? Code, string? Package, string Text)[] Programs =
    [
        ("doer-without-verb", "BYN5106", null, """
            public struct Row {
                public i64 id
            }

            public struct CsvParser {
                i64 n

                public Row read() => Row { id: n }
            }

            public struct RowBuilder {
                i64 n

                Row build() => Row { id: n }
            }

            public interface ITableWriter {
                void flush(Row row)
            }

            public struct TableCodec {
                i64 n

                public Row convert() => Row { id: n }
            }

            public type distinct RowLoader = i64

            public struct RowScheduler {
            }

            print("ok")
            """),
        ("doer-forms", null, null, """
            public union error ParseError { empty }

            public struct Row {
                public i64 id
            }

            public struct CsvParser {
                i64 n

                public Row parse() => Row { id: n }
            }

            public struct RowBuilder {
                i64 n

                public static RowBuilder build() => RowBuilder { n: 0 }
            }

            public struct RowReader {
                i64 n

                public Row? tryRead() => null
            }

            public struct RowWriter {
                i64 n

                public void writeInto(ref this, List<Row> rows) uses alloc {
                    n += 1
                }
            }

            public struct RowFormatter {
                i64 n

                public static Row formatOp(Row row) => row
            }

            public struct RowScanner {
                i64 n

                public static Row? tryScan() => null
            }

            public struct RowRecorder {
                i64 n

                public Row recordInto() => Row { id: n }
            }

            public struct RowRenderer {
                public i64 render
            }

            public struct RowHandler {
                i64 n

                public i64 handle => n
            }

            public interface ITableLoader {
                Row load()
            }

            public interface ITableEncoder {
                i64 encode
            }

            public struct TableCodec {
                i64 n

                public Row encode() => Row { id: n }
            }

            public struct LineCodec {
                i64 n

                public static Row decodeOp(Row row) => row
            }

            public struct Carrier {
                i64 n
            }

            public struct Ledger {
                i64 n
            }

            public struct User {
                i64 n
            }

            print("ok")
            """),
        ("doer-exempt", null, null, """
            public struct Row {
                public i64 id
            }

            public type TableParser = string -> i64

            @json
            public struct CsvParser {
                public i64 id
            }

            struct RowBuilder {
                i64 n
            }

            interface ITableWriter {
                void flush(Row row)
            }

            public struct CsvPärser {
                i64 n
            }

            public struct Pointer {
                i64 n
            }

            public struct HashOp {
                i64 n
            }

            public struct __ {
                i64 n
            }

            print("ok")
            """),
        // `std.json`'s `JsonReader` has no `read` member; the standard library is not checked (Q1191).
        ("doer-std", null, null, """
            import std.json

            void main() {
                let r = json.JsonReader.over("[1]")
                print("ok")
            }
            """),
        ("instrument-changes-this", "BYN5107", null, """
            public struct Order {
                public i64 id
            }

            public struct OrderHasher {
                i64 seed

                public i64 hash(ref this, Order order) {
                    seed += order.id
                    return seed
                }

                void reseed(ref this) {
                    seed = 0
                }
            }

            public struct OrderComparer {
                i64 calls

                public i64 compare(ref this, Order a, to Order b) {
                    calls += 1
                    return a.id - b.id
                }

                public void reset(ref this) {
                    calls = 0
                }
            }

            public interface IOrderCodec {
                i64 encode(ref this, Order order)
                Order decode(i64 id)
            }

            public struct LineCodec {
                i64 n

                public i64 encode(Order order) => order.id + n
            }

            public struct OrderBuilder {
                i64 n

                public void build(ref this) {
                    n += 1
                }
            }

            struct QuietHasher {
                i64 seed

                public i64 hash(ref this) {
                    seed += 1
                    return seed
                }
            }

            print("ok")
            """),
        ("doer-project-verb", "BYN5106", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["upsert", "reindex", "stage", "tally", "ship", "shipp", "plow", "relay", "fix", "a", "go", "tax"],
                },
            }
            """, """
            public struct Row {
                public i64 id
            }

            public struct RowUpserter {
                i64 n

                public Row read() => Row { id: n }
            }

            public struct RowReindexer {
                i64 n

                public Row reindex() => Row { id: n }
            }

            public struct RowStager {
                i64 n
            }

            public struct RowTallier {
                i64 n
            }

            public struct RowShipper {
                i64 n
            }

            public struct RowPlower {
                i64 n
            }

            public struct RowPlowwer {
                i64 n
            }

            public struct RowRelayer {
                i64 n
            }

            public struct RowFixer {
                i64 n
            }

            public struct RowFixxer {
                i64 n
            }

            public struct RowAer {
                i64 n
            }

            public struct RowGoer {
                i64 n
            }

            public struct RowTaxer {
                i64 n
            }

            public struct RowStageer {
                i64 n
            }

            print("ok")
            """),
        ("forms-class", "BYN5001", """
            Package {
                name: "local/crew",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["regrind"],
                    nouns: ["criterion"],
                    adjectives: ["good"],
                    collectives: ["staff"],
                    forms: ["regrind": "reground", "criterion": "criteria", "good": "better", "staff": "staves", "frob": "frobnicated"],
                },
            }
            """, """
            public struct Crew {
                i64 count

                public void reground(ref this) {
                    count += 1
                }

                public void criteria(ref this) {
                    count += 1
                }

                public void staves(ref this) {
                    count += 1
                }

                public void better(ref this) {
                    count += 1
                }

                public void frobnicated(ref this) {
                    count += 1
                }
            }

            print("ok")
            """),
        // The rest of `CheckOverlap` around the 5b skip: a verb that is also a noun, a repeat in one list, a word in two
        // other lists, a grammar field that is not a list.
        ("m-overlap", "BYN3102", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["record"],
                    nouns: ["record", "x", "x"],
                    adjectives: ["Record", "x"],
                    collectives: "ledger",
                },
            }
            """, ""),
        // A manifest only (the C# `Manifest.Parse`): `Compilation.Create` does not surface its diagnostics.
        ("m-collective-mixed-list", "BYN3102", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    nouns: ["a"],
                    collectives: [1, "a"],
                },
            }
            """, ""),
    ];

    public static TheoryData<string> Names() => new(Programs.Select(p => p.Name));

    private static readonly Lazy<Dictionary<string, List<string>>> Sections = new(() =>
        SelfhostSemanticsHarness.RunSections(MainSource(), Programs.SelectMany(p => new[] { p.Name, Dir(p.Name) }).ToArray()));

    [Theory]
    [MemberData(nameof(Names))]
    public void DiagnosticsAreTheCSharps(string name)
    {
        var section = $"diags.{name}";
        var expected = name.StartsWith("m-", StringComparison.Ordinal) ? ExpectedManifest(Dir(name)) : ExpectedProgram(Dir(name));
        // Each program names the code it is for, so a dropped check fails here; a clean program reports neither T8 code.
        var code = Programs.Single(p => p.Name == name).Code;
        if (code is null) Assert.DoesNotContain(expected, l => l.StartsWith("BYN5106 ", StringComparison.Ordinal) || l.StartsWith("BYN5107 ", StringComparison.Ordinal));
        else Assert.Contains(expected, l => l.StartsWith(code + " ", StringComparison.Ordinal));
        var actual = new Dictionary<string, List<string>> { [section] = Sections.Value[section] };
        if (expected.Count == 0) Assert.Empty(actual[section]);
        else SelfhostSemanticsHarness.AssertSection(actual, section, expected);
    }

    /// <summary>The program's directory under <c>tmp/revision-t8/</c>, written on each call (the same text each time).</summary>
    private static string Dir(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "revision-t8", name);
        Directory.CreateDirectory(dir);
        foreach (var f in Directory.GetFiles(dir)) File.Delete(f);
        var p = Programs.Single(p => p.Name == name);
        if (name.StartsWith("m-", StringComparison.Ordinal))
        {
            File.WriteAllText(Path.Combine(dir, "package.byn"), p.Package!.EndsWith('\n') ? p.Package : p.Package + "\n");
            return dir;
        }
        File.WriteAllText(Path.Combine(dir, "main.byn"), p.Text.EndsWith('\n') ? p.Text : p.Text + "\n");
        if (p.Package is { } package) File.WriteAllText(Path.Combine(dir, "package.byn"), package.EndsWith('\n') ? package : package + "\n");
        return dir;
    }

    private static List<string> ExpectedProgram(string dir)
    {
        var c = Compilation.Create([Golden.Load(Path.Combine(dir, "main.byn"))], dir, new CompilationOptions(IncludeTests: true));
        var lines = new List<string>();
        foreach (var d in c.Diagnostics.Items)
        {
            string At(int offset) => d.Source is { } s ? $"{s.GetLinePosition(offset).Line}:{s.GetLinePosition(offset).Column}" : "?";
            lines.Add($"{d.Code} {At(d.Span.Start)} {d.Message}");
            if (!string.IsNullOrEmpty(d.Label)) lines.Add($"  label {d.Label}");
            if (!string.IsNullOrEmpty(d.Help)) lines.Add($"  help {d.Help}");
            if (d.Fix is { } f) lines.Add($"  fix {At(f.Span.Start)}-{At(f.Span.End)} {f.Replacement}");
        }
        return lines.SelectMany(l => l.Split('\n')).Where(l => l.Length > 0).ToList();
    }

    private static List<string> ExpectedManifest(string dir)
    {
        var source = SourceText.FromString("package.byn", File.ReadAllText(Path.Combine(dir, "package.byn")));
        var m = Manifest.Parse(source);
        var lines = new List<string>();
        foreach (var d in m.Diagnostics)
        {
            var p = source.GetLinePosition(d.Span.Start);
            lines.Add($"{d.Code} {p.Line}:{p.Column} {d.Message}");
            if (!string.IsNullOrEmpty(d.Label)) lines.Add($"  label {d.Label}");
            if (!string.IsNullOrEmpty(d.Help)) lines.Add($"  help {d.Help}");
        }
        foreach (var (kind, words) in new[]
        {
            ("verbs", m.Grammar.Verbs), ("nouns", m.Grammar.Nouns), ("adjectives", m.Grammar.Adjectives), ("collectives", m.Grammar.Collectives),
        })
            lines.Add(kind + string.Concat(words.Order(StringComparer.Ordinal).Select(w => " " + w)));
        return lines.SelectMany(l => l.Split('\n')).Where(l => l.Length > 0).ToList();
    }

    private static string MainSource() => """
        import lexer
        import parser

        string t8At(Ctx c, for FileId file, at i64 offset) {
            if file < 0 { return "?" }
            let p = linePosition(c.files[file].text.span, at: offset)
            return $"{p.line}:{p.column}"
        }

        bool lessBytes(string a, by string b) {
            let x = a.bytes
            let y = b.bytes
            var i: i64 = 0
            while i < x.length && i < y.length {
                if x[i] != y[i] { return x[i] < y[i] }
                i += 1
            }
            return x.length < y.length
        }

        string t8Words(string kind, by List<string> words) {
            var sorted = List<string>()
            for w in words { sorted.append(w) }
            for i in 1..sorted.length {
                var j = i
                while j > 0 && lessBytes(sorted[j], by: sorted[j - 1]) {
                    let a = sorted[j]
                    sorted[j] = sorted[j - 1]
                    sorted[j - 1] = a
                    j -= 1
                }
            }
            var sb = StrBuf()
            sb.append(kind)
            for w in sorted { sb.append($" {w}") }
            return $"{sb.finish()}"
        }

        void showManifest(string name, at string dir) {
            let bytes = t11ReadAllBytes($"{dir}/package.byn")
            let m = manifestParse(lexer.SourceText.create("package.byn", from: t11ReadAllBytes($"{dir}/package.byn")))
            print($"== diags.{name}")
            for d in m.diagnostics {
                let p = linePosition(bytes.span, at: d.span.start)
                print($"{d.code} {p.line}:{p.column} {d.message}")
                if d.label.length > 0 { print($"  label {d.label}") }
                if d.help.length > 0 { print($"  help {d.help}") }
            }
            print(t8Words("verbs", by: m.grammar.verbs))
            print(t8Words("nouns", by: m.grammar.nouns))
            print(t8Words("adjectives", by: m.grammar.adjectives))
            print(t8Words("collectives", by: m.grammar.collectives))
        }

        void showProgram(string name, at string dir) {
            var sources = List<lexer.SourceText>()
            sources.append(lexer.SourceText.create("main.byn", from: t11ReadAllBytes($"{dir}/main.byn")))
            let options = CompilationOptions { includeTests: true, library: false, skipOwnershipCheck: false, capabilities: null, packageName: null }
            var c = create(from: move sources, at: dir, by: options)
            print($"== diags.{name}")
            for d in c.diagnostics {
                print($"{d.code} {t8At(c, for: d.file, at: d.span.start)} {d.message}")
                if d.label.length > 0 { print($"  label {d.label}") }
                if d.help.length > 0 { print($"  help {d.help}") }
                if d.hasFix { print($"  fix {t8At(c, for: d.file, at: d.fixSpan.start)}-{t8At(c, for: d.file, at: d.fixSpan.end)} {d.fixReplacement}") }
            }
        }

        i32 main(ReadOnlySpan<string> args) {
            var i: i64 = 0
            while i + 1 < args.length {
                if args[i].startsWith("m-") {
                    showManifest(args[i], at: args[i + 1])
                } else {
                    showProgram(args[i], at: args[i + 1])
                }
                i += 2
            }
            return 0
        }
        """;
}
