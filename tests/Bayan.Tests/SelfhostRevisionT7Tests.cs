using Bayan.Semantics;

namespace Bayan.Tests;

/// <summary>
/// Spec 018 T7: BYN5104 (number agreement, both message forms) and BYN5105 (count names) of revision 0021 Part 4, ported to
/// naming.byn (<c>checkMembersWith</c>'s tail, <c>checkSignatures</c>, <c>checkPayload</c>, <c>isRenamed</c>, <c>checkNumber</c>,
/// <c>checkCount</c>, <c>isPlural</c>, <c>looksPlural</c>, <c>singular</c>, <c>plural</c>, <c>isNoun</c>, <c>matchCase</c>) and codes.byn,
/// against the C# <c>Naming</c>. Programs compare as <c>code line:col message</c> with label, help and fix. Every expected line is
/// computed from the C#.
/// </summary>
public sealed class SelfhostRevisionT7Tests
{
    /// <summary>Each program: its name, its <c>package.byn</c> (or null) and its <c>main.byn</c>.</summary>
    private static readonly (string Name, string? Package, string Text)[] Programs =
    [
        ("struct-members", null, """
            public struct Line {
                public i64 grams
            }

            public struct Order {
                public List<Line> line
                public Line lines
                public Map<string, i64> weight
                public List<Line> lineItems
                public Line firstLine
                public i64[4] totals
                public Map<string, Line> lineByName
                public List<Line> modulesByDir
                public List<Line> byPath
                public List<Line> covered
                public Line people
                public List<Line> item => List<Line>()
                public Line entries => Line { grams: 1 }

                public void add(ref this, Line items, to List<Line> entry) uses alloc {
                    line.append(items)
                }
                void hide(Line items) {}
            }

            print("ok")
            """),
        ("positions", null, """
            public struct Line {
                public i64 grams
            }

            public i64 total(List<Line> line) => line.length

            public i64 weigh(Line lines) => lines.grams

            public interface IOrder {
                List<Line> item
                i64 linesCount
                Line lines => Line { grams: 1 }
                @json(name: "entry")
                List<Line> entry
                i64 weigh(List<Line> line)
            }

            public union Delivery {
                shipped(List<Line> item, i64 numBoxes)
                held(string reasons)
                none
            }

            public union error OrderError {
                rejected(List<Line> line)
                counted(i64 numberOfItems)
            }

            i64 hidden(List<Line> line) => line.length

            interface IHidden {
                List<Line> item
            }

            union Hidden {
                kept(List<Line> item)
            }

            union error HiddenError {
                lost(List<Line> line)
            }

            void main() {
                print($"{hidden(List<Line>())}")
            }
            """),
        ("exempt", null, """
            public struct Line {
                public i64 grams
            }

            public struct Order {
                public List<u8> buffer
                public List<Line> history
                public Map<string, i64> data
                public Untrusted<List<Line>> draft
                public Untrusted<List<Line>> drafts
                public List<Line>? entry
                public string titles
                public i64 cents
                public bool isLines
                @json(name: "line")
                public List<Line> line
                @column("item")
                public List<Line> item
                List<Line> hidden
                Line others
            }

            struct Draft {
                public List<Line> line
            }

            print("ok")
            """),
        ("count-name", null, """
            public struct Order {
                public i64 linesCount
                public i64 numLines
                public i64 numberOfItems
                public i64 lineCount
                public i64 length
                public i64 totalLinesCount
                public i64 Count
                public i64 numberOf
                public i64 peopleCount
                public u8 numEntries
                public string numLines2
                @json(name: "numLines")
                public i64 numLinesRenamed
                i64 hiddenLinesCount
            }

            struct Draft {
                public i64 numItems
            }

            print("ok")
            """),
        ("project-forms", """
            Package {
                name: "local/shop",
                version: "0.1.0",
                grammar: Grammar {
                    nouns: ["criterion", "sku", "box"],
                    collectives: ["Ledger"],
                    forms: ["criterion": "criteria", "sku": "skus"],
                },
            }
            """, """
            public struct Box {
                public i64 grams
            }

            public struct Shelf {
                public List<Box> criterion
                public Box criteria
                public List<Box> sku
                public Box skus
                public List<Box> box
                public Box boxes
                public List<Box> ledger
                public i64 numCriteria
                public i64 skusCount
                public i64 numberOfBoxes
            }

            print("ok")
            """),
    ];

    public static TheoryData<string> Names() => new(Programs.Select(p => p.Name));

    private static readonly Lazy<Dictionary<string, List<string>>> Sections = new(() =>
        SelfhostSemanticsHarness.RunSections(MainSource(), Programs.SelectMany(p => new[] { p.Name, Dir(p.Name) }).ToArray()));

    [Theory]
    [MemberData(nameof(Names))]
    public void DiagnosticsAreTheCSharps(string name)
    {
        var section = $"diags.{name}";
        var expected = ExpectedProgram(Dir(name));
        // Every program reports at least one BYN5104 or BYN5105, so a dropped check fails here.
        Assert.Contains(expected, l => l.StartsWith("BYN5104 ", StringComparison.Ordinal) || l.StartsWith("BYN5105 ", StringComparison.Ordinal));
        SelfhostSemanticsHarness.AssertSection(new() { [section] = Sections.Value[section] }, section, expected);
    }

    /// <summary>The program's directory under <c>tmp/revision-t7/</c>, written on each call (the same text each time).</summary>
    private static string Dir(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "revision-t7", name);
        Directory.CreateDirectory(dir);
        foreach (var f in Directory.GetFiles(dir)) File.Delete(f);
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

    private static string MainSource() => """
        import lexer
        import parser

        string t7At(Ctx c, for FileId file, at i64 offset) {
            if file < 0 { return "?" }
            let p = linePosition(c.files[file].text.span, at: offset)
            return $"{p.line}:{p.column}"
        }

        void showProgram(string name, at string dir) {
            var sources = List<lexer.SourceText>()
            sources.append(lexer.SourceText.create("main.byn", from: t11ReadAllBytes($"{dir}/main.byn")))
            let options = CompilationOptions { includeTests: false, library: false, skipOwnershipCheck: false, capabilities: null, packageName: null }
            var c = create(from: move sources, at: dir, by: options)
            print($"== diags.{name}")
            for d in c.diagnostics {
                print($"{d.code} {t7At(c, for: d.file, at: d.span.start)} {d.message}")
                if d.label.length > 0 { print($"  label {d.label}") }
                if d.help.length > 0 { print($"  help {d.help}") }
                if d.hasFix { print($"  fix {t7At(c, for: d.file, at: d.fixSpan.start)}-{t7At(c, for: d.file, at: d.fixSpan.end)} {d.fixReplacement}") }
            }
        }

        i32 main(ReadOnlySpan<string> args) {
            var i: i64 = 0
            while i + 1 < args.length {
                showProgram(args[i], at: args[i + 1])
                i += 2
            }
            return 0
        }
        """;
}
