using Bayan.Semantics;
using Bayan.Syntax.Packages;
using SourceText = Bayan.Syntax.Text.SourceText;

namespace Bayan.Tests;

/// <summary>
/// Spec 018 T4: the word classes of revision 0021 Part 3, ported to naming.byn (<c>buildLexicon</c>, <c>checkWords</c>,
/// <c>isNounOnly</c>, <c>offer</c>, <c>lowerGrammar</c>), manifest.byn (<c>t10CheckOverlap</c>, the <c>collectives</c> key) and codes.byn
/// (the BYN5014 text) against the C# <c>Lexicon</c>, <c>Naming</c> and <c>Manifest</c>. The built lexicon is compared as sets; programs
/// and manifests as <c>code line:col message</c> with label and help. Every expected line is computed from the C#.
/// </summary>
public sealed class SelfhostRevisionT4Tests
{
    /// <summary>Each program: its name, its <c>package.byn</c> (or null) and its <c>main.byn</c>.</summary>
    private static readonly (string Name, string? Package, string Text)[] Programs =
    [
        ("unknown-ref-this", null, """
            struct Bag {
                i64 n
                void zorkify(ref this) { n += 1 }
            }
            """),
        ("unknown-bool", null, """
            struct Bag {
                bool zorky => true
                bool zork() => true
            }
            """),
        ("unknown-other", null, """
            struct Bag {
                i64 zorks => 1
                i64 zork() => 1
            }
            """),
        ("collective-and-plural", null, """
            struct Bag {
                i64 buffer => 1
                i64 history => 1
                i64 catalog => 1
                i64 metadata => 1
                i64 matrices => 1
                i64 people => 1
                i64 criteria => 1
                i64 indices => 1
                bool isOverdue => true
            }
            """),
        ("project-collective", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    collectives: ["ledger", "Roster"],
                },
            }
            """, """
            struct Bag {
                i64 ledger => 1
                i64 roster => 1
                i64 ledgers => 1
            }
            """),
        ("forms-for-a-verb", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["upsert"],
                    forms: ["upsert": "upserted"],
                },
            }
            """, """
            struct Bag {
                i64 n
                void upserted(ref this) { n += 1 }
            }
            """),
        ("forms-for-a-noun", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    nouns: ["criterion"],
                    forms: ["criterion": "criteria"],
                },
            }
            """, """
            struct Bag {
                i64 n
                void criteria(ref this) { n += 1 }
            }
            """),
        ("forms-for-a-verb-and-noun", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["record"],
                    nouns: ["record"],
                    forms: ["record": "recorded"],
                },
            }
            """, """
            struct Bag {
                i64 n
                void recorded(ref this) { n += 1 }
            }
            """),
        ("every-class", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["upsert"],
                    nouns: ["sku", "criterion"],
                    adjectives: ["kyc"],
                    collectives: ["ledger"],
                    forms: ["upsert": "upserted", "criterion": "criteria", "sku": "skus"],
                },
            }
            """, """
            union error ParseError {
                bad
            }

            public struct Probe {
                i64 n
                public void fetchAccountActiveCatalogPeopleFromThenUpsertSkuKycLedger(ref this) { n += 1 }
                public void upserted(ref this) { n += 1 }
                public void criteria(ref this) { n += 1 }
                public void isReady(ref this) { n += 1 }
                public void total(ref this) { n += 1 }
                public void fetch(ref this) { n += 1 }
                i64 parse() fails ParseError {
                    fail .bad
                }
                i64 tryParse() => 1
                i64? tryLoad() => 1
                bool tryOpen() => true
                Missing tryScan() => 1
                i64 tryZip() => 1
                i64 trying() => 1
                i64 withArgs(i64 a) => a
                public i64 withArgsPublic(i64 a) => a
                public i64 account() => 1
                bool hidden => true
                i64 abc1d() => 1
                i64 fetchSqrt() => 1
                void widgeted(ref this) { n += 1 }
                bool flip(ref this) {
                    n += 1
                    return true
                }
                public bool ready() => true
                public bool isDone() => true
                public bool containsKey() => true
                public bool fresh => true
                public bool isOld => true
                i64 sqrt() => 1
                i64 café() => 1
                i64 x() => 1
                i64 v2() => 1
                i64 at() => 1
                i64 toList() => 1
                i64 toString() => 1
                i64 asSpan() => 1
                i64 fromList() => 1
                i64 ascii() => 1
                static i64 toName() => 1
                i64 load() fails ParseError {
                    fail .bad
                }
                i64 scan() fails ParseError {
                    fail .bad
                }
                i64 open() fails ParseError {
                    fail .bad
                }
            }
            struct Hidden {
                i64 n
                void fetch(ref this) { n += 1 }
                public bool ready() => true
            }
            """),
        ("verb-and-noun-form", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    verbs: ["upsert"],
                    nouns: ["upsert"],
                    forms: ["upsert": "upserted"],
                },
            }
            """, """
            struct Bag {
                i64 n
                void upserted(ref this) { n += 1 }
            }
            """),
    ];

    private const string Header = """
        Package {
            name: "local/shop",
            version: "0.1.0",
            grammar: Grammar {

        """;

    private static string ManifestText(string fields) => Header + fields + "    },\n}\n";

    /// <summary>Each manifest: its name and its <c>package.byn</c>.</summary>
    private static readonly (string Name, string Text)[] Manifests =
    [
        ("verb-and-noun", ManifestText("""
                    verbs: ["record"],
                    nouns: ["record"],
                    collectives: ["ledger"],

            """)),
        ("noun-and-adjective", ManifestText("""
                    nouns: ["x"],
                    adjectives: ["x"],

            """)),
        ("noun-then-verb", ManifestText("""
                    nouns: ["record"],
                    verbs: ["record"],

            """)),
        ("same-list-repeat", ManifestText("""
                    nouns: ["x", "x"],
                    collectives: ["ledger", "ledger"],

            """)),
        ("case-differs", ManifestText("""
                    verbs: ["Fetch"],
                    adjectives: ["fetch"],

            """)),
        ("collective-and-noun", ManifestText("""
                    nouns: ["ledger"],
                    collectives: ["Ledger"],

            """)),
        ("collective-not-a-list", ManifestText("""
                    collectives: "ledger",
                    nouns: ["ledger"],

            """)),
        ("collective-mixed-list", ManifestText("""
                    nouns: ["a"],
                    collectives: [1, "a"],

            """)),
        ("grammar-not-an-object", "Package {\n    name: \"local/shop\",\n    version: \"0.1.0\",\n    grammar: 5,\n}\n"),
        ("grammar-wrong-object", "Package {\n    name: \"local/shop\",\n    version: \"0.1.0\",\n    grammar: Style {},\n}\n"),
        ("forms-invalid", ManifestText("        forms: [\"a\"],\n")),
        ("forms-empty-list", ManifestText("        forms: [],\n")),
        ("forms-map", ManifestText("        forms: [\"upsert\": \"upserted\"],\n")),
    ];

    public static TheoryData<string> Names() => new(Programs.Select(p => p.Name).Concat(Manifests.Select(m => "m-" + m.Name)));

    private static readonly Lazy<Dictionary<string, List<string>>> Sections = new(() =>
        SelfhostSemanticsHarness.RunSections(MainSource(),
            Programs.Select(p => p.Name).Concat(Manifests.Select(m => "m-" + m.Name)).SelectMany(n => new[] { n, Dir(n) }).ToArray()));

    [Theory]
    [MemberData(nameof(Names))]
    public void DiagnosticsAreTheCSharps(string name)
    {
        var section = $"diags.{name}";
        var expected = name.StartsWith("m-", StringComparison.Ordinal) ? ExpectedManifest(Dir(name)) : ExpectedProgram(Dir(name));
        var actual = new Dictionary<string, List<string>> { [section] = Sections.Value[section] };
        // A program with no diagnostic prints nothing on either side; it is here for the code it runs.
        if (expected.Count == 0) Assert.Empty(actual[section]);
        else SelfhostSemanticsHarness.AssertSection(actual, section, expected);
    }

    /// <summary>The built lexicon, every word, as sets against the C# <c>Lexicon</c>.</summary>
    [Fact]
    public void LexiconIsTheCSharps()
    {
        var expected = new List<string>();
        foreach (var (kind, words) in new[]
        {
            ("verb", Lexicon.Verbs), ("noun", Lexicon.Nouns), ("adjective", Lexicon.Adjectives),
            ("collective", Lexicon.Collectives), ("irregular", Lexicon.IrregularPlurals),
        })
            expected.AddRange(words.Select(w => $"{kind} {w}"));
        var actual = Sections.Value["lexicon"];
        Assert.Equal(expected.Count, actual.Count);
        SelfhostSemanticsHarness.AssertSection(new() { ["lexicon"] = actual.Order(StringComparer.Ordinal).ToList() }, "lexicon",
            expected.Order(StringComparer.Ordinal).ToList());
    }

    /// <summary>The program's (or manifest's) directory under <c>tmp/revision-t4/</c>, written on each call (the same text each time).</summary>
    private static string Dir(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "revision-t4", name);
        Directory.CreateDirectory(dir);
        foreach (var f in Directory.GetFiles(dir)) File.Delete(f);
        if (name.StartsWith("m-", StringComparison.Ordinal))
        {
            File.WriteAllText(Path.Combine(dir, "package.byn"), Manifests.Single(m => "m-" + m.Name == name).Text);
            return dir;
        }
        var p = Programs.Single(p => p.Name == name);
        File.WriteAllText(Path.Combine(dir, "main.byn"), p.Text.EndsWith('\n') ? p.Text : p.Text + "\n");
        if (p.Package is { } package) File.WriteAllText(Path.Combine(dir, "package.byn"), package.EndsWith('\n') ? package : package + "\n");
        return dir;
    }

    private static List<string> ExpectedProgram(string dir)
    {
        var c = Compilation.Create([Golden.Load(Path.Combine(dir, "main.byn"))], dir, new CompilationOptions());
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

        string t4At(Ctx c, for FileId file, at i64 offset) {
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

        string t4Words(string kind, by in List<string> words) {
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
            print(t4Words("verbs", by: in m.grammar.verbs))
            print(t4Words("nouns", by: in m.grammar.nouns))
            print(t4Words("adjectives", by: in m.grammar.adjectives))
            print(t4Words("collectives", by: in m.grammar.collectives))
        }

        void showProgram(string name, at string dir) {
            var sources = List<lexer.SourceText>()
            sources.append(lexer.SourceText.create("main.byn", from: t11ReadAllBytes($"{dir}/main.byn")))
            let options = CompilationOptions { includeTests: false, library: false, skipOwnershipCheck: false, capabilities: null, packageName: null }
            var c = create(from: move sources, at: dir, by: options)
            print($"== diags.{name}")
            for d in c.diagnostics {
                print($"{d.code} {t4At(c, for: d.file, at: d.span.start)} {d.message}")
                if d.label.length > 0 { print($"  label {d.label}") }
                if d.help.length > 0 { print($"  help {d.help}") }
                if d.hasFix { print($"  fix {t4At(c, for: d.file, at: d.fixSpan.start)}-{t4At(c, for: d.file, at: d.fixSpan.end)} {d.fixReplacement}") }
            }
        }

        i32 main(ReadOnlySpan<string> args) {
            var lex = Ctx {
                files: List<SourceFile>(),
                modules: List<Mod>(),
                diagnostics: List<Diag>(),
                bags: List<DiagBag>(),
            }
            buildLexicon(ref lex)
            print("== lexicon")
            for w in lex.lexiconVerbs { print($"verb {w}") }
            for w in lex.lexiconNouns { print($"noun {w}") }
            for w in lex.lexiconAdjectives { print($"adjective {w}") }
            for w in lex.lexiconCollectives { print($"collective {w}") }
            for w in lex.lexiconIrregularPlurals { print($"irregular {w}") }
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
