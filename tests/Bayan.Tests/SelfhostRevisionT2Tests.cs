using Bayan.Semantics;

namespace Bayan.Tests;

/// <summary>
/// Spec 018 T2: the BYN7001 "doesn't narrow" help (states.byn <c>stateTestHelp</c>, the <c>thenOf</c> list binder2.byn's
/// <c>.ifStmt</c> case keeps) against the C# <c>StateTestHelp</c> and <c>_thenOf</c>. Each program is compiled by the generated
/// <c>create</c> and by the C# <c>Compilation.Create</c>, and every diagnostic is printed as <c>code line:col message</c> with its
/// label, help and fix. Every expected line is computed from the C#.
/// </summary>
public sealed class SelfhostRevisionT2Tests
{
    private const string Order = """
        struct Order {
            i64 id
            states {
                draft
                paid(i64 payment)
            }
            bool isPaid => this is .paid
            bool isDraft => this is .draft
            bool isBig => id > 10
            bool isPaidEmpty => this is .paid()
            bool isPaidBound => this is .paid p
            bool ready
            i64 ship(this is .paid) => id
        }

        """;

    /// <summary>Each program: its name and its <c>main.byn</c>. The first is the T1 golden.</summary>
    private static readonly (string Name, string Text)[] Programs =
    [
        ("golden", File.ReadAllText(Path.Combine(Golden.CasesRoot, "diag", "wrong-state-member-test.byn"))),
        ("not-this-is", Order + """
            i64 run(Order order) {
                if order.isBig {
                    return order.ship()
                }
                return 0
            }
            """),
        ("other-state", Order + """
            i64 run(Order order) {
                if order.isDraft {
                    return order.ship()
                }
                return 0
            }
            """),
        ("nested", Order + """
            i64 run(Order order, Order other) {
                if order.isPaid {
                    if other.isPaid {
                        return order.ship() + other.ship()
                    }
                    return order.ship()
                }
                return 0
            }
            """),
        ("else-branch", Order + """
            i64 run(Order order) {
                if order.isPaid {
                    return 1
                } else {
                    return order.ship()
                }
            }
            """),
        ("unless", Order + """
            i64 run(Order order) {
                unless order.isPaid {
                    return order.ship()
                }
                return 0
            }
            """),
        ("variant-no-payload", Order + """
            i64 run(Order order) {
                if order.isPaidEmpty {
                    return order.ship()
                }
                return 0
            }
            """),
        ("variant-binding", Order + """
            i64 run(Order order) {
                if order.isPaidBound {
                    return order.ship()
                }
                return 0
            }
            """),
        ("bool-field", Order + """
            i64 run(Order order) {
                if order.ready {
                    return order.ship()
                }
                return 0
            }
            """),
        ("non-member", Order + """
            i64 run(Order order, bool flag) {
                if flag {
                    return order.ship()
                }
                return 0
            }
            """),
        ("interface-default", """
            interface Gate {
                bool isPaid => this is .paid
            }

            struct Order : Gate {
                i64 id
                states {
                    draft
                    paid(i64 payment)
                }
                i64 ship(this is .paid) => id
            }

            i64 run(Order order) {
                if order.isPaid {
                    return order.ship()
                }
                return 0
            }
            """),
    ];

    public static TheoryData<string> Names() => new(Programs.Select(p => p.Name));

    private static readonly Lazy<Dictionary<string, List<string>>> Sections = new(() =>
        SelfhostSemanticsHarness.RunSections(MainSource(), Programs.SelectMany(p => new[] { p.Name, Dir(p.Name) }).ToArray()));

    [Theory]
    [MemberData(nameof(Names))]
    public void HelpIsTheCSharps(string name)
    {
        var section = $"diags.{name}";
        var expected = Expected(Dir(name));
        var actual = new Dictionary<string, List<string>> { [section] = Sections.Value[section] };
        SelfhostSemanticsHarness.AssertSection(actual, section, expected);
    }

    /// <summary>The program's directory under <c>tmp/revision-t2/</c>, written on each call (the same text each time).</summary>
    private static string Dir(string name)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "revision-t2", name);
        Directory.CreateDirectory(dir);
        var text = Programs.Single(p => p.Name == name).Text;
        File.WriteAllText(Path.Combine(dir, "main.byn"), text.EndsWith('\n') ? text : text + "\n");
        return dir;
    }

    private static List<string> Expected(string dir)
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

        string t2At(Ctx c, for FileId file, at i64 offset) {
            if file < 0 { return "?" }
            let p = linePosition(c.files[file].text.span, at: offset)
            return $"{p.line}:{p.column}"
        }

        i32 main(ReadOnlySpan<string> args) {
            var i: i64 = 0
            while i + 1 < args.length {
                let name = args[i]
                let dir = args[i + 1]
                var sources = List<lexer.SourceText>()
                sources.append(lexer.SourceText.create("main.byn", from: t11ReadAllBytes($"{dir}/main.byn")))
                let options = CompilationOptions { includeTests: false, library: false, skipOwnershipCheck: false, capabilities: null, packageName: null }
                var c = create(from: move sources, at: dir, by: options)
                print($"== diags.{name}")
                for d in c.diagnostics {
                    print($"{d.code} {t2At(c, for: d.file, at: d.span.start)} {d.message}")
                    if d.label.length > 0 { print($"  label {d.label}") }
                    if d.help.length > 0 { print($"  help {d.help}") }
                    if d.hasFix { print($"  fix {t2At(c, for: d.file, at: d.fixSpan.start)}-{t2At(c, for: d.file, at: d.fixSpan.end)} {d.fixReplacement}") }
                }
                i += 2
            }
            return 0
        }
        """;
}
