using System.Runtime.CompilerServices;
using System.Text;
using Bayan.Semantics.Symbols;
using Bayan.Syntax.Ast;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Packages;
using Bayan.Syntax.Text;

namespace Bayan.Semantics;

/// <summary>
/// Casing rules (spec §5.1): types are <c>PascalCase</c>, everything else <c>camelCase</c>,
/// acronyms longer than two letters are written as words (<c>HttpClient</c>, <c>IO</c>).
/// Scripts without case (Arabic, …) are not constrained. Also the grammar checker (BYN5xxx).
/// </summary>
public static class Naming
{
    internal static void CheckType(Compilation c, SourceText source, Name name)
    {
        if (name.Text == "_") return;
        var fixedName = ToPascal(name.Text);
        if (fixedName != name.Text)
            c.Report(DiagnosticCodes.TypeCasing, source, name.Span, [name.Text],
                help: $"rename it `{fixedName}`", fix: new Fix(name.Span, fixedName));
    }

    /// <summary>An interface name is <c>I</c>, then an uppercase letter, then PascalCase (<c>IShape</c>).</summary>
    internal static void CheckInterface(Compilation c, SourceText source, Name name)
    {
        if (name.Text.Length > 1 && name.Text[0] == 'I' && char.IsUpper(name.Text[1]))
        {
            CheckType(c, source, name);
            return;
        }
        var fixedName = "I" + ToPascal(name.Text);
        c.Report(DiagnosticCodes.InterfaceName, source, name.Span, [name.Text], label: "an interface name",
            help: $"rename it to `{fixedName}`", fix: new Fix(name.Span, fixedName));
    }

    internal static void CheckValue(Compilation c, SourceText source, Name name)
    {
        if (name.Text == "_") return;
        var fixedName = ToCamel(name.Text);
        if (fixedName != name.Text)
            c.Report(DiagnosticCodes.ValueCasing, source, name.Span, [name.Text],
                help: char.IsUpper(name.Text[0]) && fixedName.Length > 0
                    ? $"rename it `{fixedName}`; only types are PascalCase"
                    : $"rename it `{fixedName}`",
                fix: new Fix(name.Span, fixedName));
    }

    /// <summary>
    /// Grammar rules on the members of <paramref name="s"/> (spec §5.2, <c>docs/bayan-grammar.md</c>):
    /// BYN50xx are pattern contracts on all code, BYN51xx word-class lints on the public API only (J84).
    /// Math vocabulary (J70) is exempt from BYN5001 and BYN5014; typestate states are not members and are not checked.
    /// </summary>
    internal static void CheckMembers(Compilation c, StructSymbol s)
    {
        var source = s.File.Source;
        var grammar = GrammarOf(c);
        foreach (var fn in s.Methods)
        {
            var name = fn.Decl!.Name;
            var noArgs = !fn.IsStatic && fn.Parameters.Count == 0;
            var isPublic = s.Access == Accessibility.Public && fn.Access == Accessibility.Public;
            if (fn.IsMutating && !fn.ReturnType.IsBool) CheckParticiple(c, grammar, source, name);
            CheckParticleName(c, s, source, name, fn.IsStatic);
            CheckWords(c, grammar, source, name, fn.IsMutating ? "verbs" : fn.ReturnType.IsBool ? "adjectives" : "nouns");
            if (noArgs && fn.IsMutating && IsStateName(fn.Name))
                c.Report(DiagnosticCodes.StateMemberMutates, source, name.Span, [fn.Name], label: "declared `ref this`",
                    help: "remove `ref this` so it only reads, or name the action with a verb");
            if (fn.Name.Length > 3 && fn.Name.StartsWith("try", StringComparison.Ordinal) && char.IsUpper(fn.Name[3])
                && s.Methods.FirstOrDefault(m => m.Fails && m.Name == char.ToLowerInvariant(fn.Name[3]) + fn.Name[4..]) is { } failing
                && fn.ReturnType is not OptionalType && !fn.ReturnType.IsBool && !fn.ReturnType.IsError)
                c.Report(DiagnosticCodes.TryWrongReturn, source, fn.Decl.ReturnType.Span, [fn.Name[3..], failing.ReturnType.DisplayName, failing.Name],
                    label: $"returns `{fn.ReturnType.DisplayName}`",
                    help: $"change it to return `{failing.ReturnType.DisplayName}?` or `bool`, or remove `{fn.Name}` and call `try {failing.Name}()`");
            if (isPublic && fn.IsMutating && Words(fn.Name) is [var first, ..] && Nouns.Contains(first.ToLowerInvariant()))
                c.Report(DiagnosticCodes.NounOnMutator, source, name.Span, [fn.Name],
                    help: "rename it with the verb for what it does to `this`");
            if (isPublic && noArgs && !fn.IsMutating && fn.ReturnType.IsBool)
                CheckBoolState(c, source, name);
        }
        foreach (var p in s.Properties)
        {
            CheckParticleName(c, s, source, p.Decl.Name, isStatic: false);
            CheckWords(c, grammar, source, p.Decl.Name, p.Type.IsBool ? "adjectives" : "nouns");
            if (p.Type.IsBool && s.Access == Accessibility.Public && p.Access == Accessibility.Public) CheckBoolState(c, source, p.Decl.Name);
        }
        if (s.Access != Accessibility.Public) return;
        foreach (var f in s.Fields.Where(f => f.Access == Accessibility.Public && !IsRenamed(f.Decl)))
        {
            if (!CheckCount(c, grammar, source, f.Decl.Name, f.Type)) CheckNumber(c, grammar, source, f.Decl.Name, f.Type);
        }
        foreach (var p in s.Properties.Where(p => p.Access == Accessibility.Public && !IsRenamed(p.Decl)))
        {
            if (!CheckCount(c, grammar, source, p.Decl.Name, p.Type)) CheckNumber(c, grammar, source, p.Decl.Name, p.Type);
        }
        foreach (var fn in s.Methods.Where(fn => fn.Access == Accessibility.Public))
            foreach (var p in fn.Parameters)
                if (p.Syntax is { } syntax) CheckNumber(c, grammar, source, syntax.Name, p.Type);
        CheckDoer(c, grammar, source, s.Module, s.Decl, s.Decl.Name, s.Methods.Where(fn => fn.Access == Accessibility.Public),
            s.Fields.Where(f => f.Access == Accessibility.Public).Select(f => f.Decl.Name.Text)
                .Concat(s.Properties.Where(p => p.Access == Accessibility.Public).Select(p => p.Decl.Name.Text)));
    }

    /// <summary>
    /// BYN5104 and BYN5105 on the rest of a module's public API, once top-level signatures are declared: the parameters of
    /// public top-level functions, a public interface's getters and its methods' parameters, and the payload fields of a
    /// public union or error set (the struct members are <see cref="CheckMembers"/>'s).
    /// </summary>
    internal static void CheckSignatures(Compilation c, ModuleSymbol module)
    {
        var grammar = GrammarOf(c);
        foreach (var fn in module.AllFunctions.Where(f => f is { Kind: FunctionKind.Function, Owner: null, Interface: null, IsInstance: false, Access: Accessibility.Public }))
            foreach (var p in fn.Parameters)
                if (p.Syntax is { } syntax) CheckNumber(c, grammar, fn.File!.Source, syntax.Name, p.Type);
        foreach (var i in module.Interfaces.Where(i => i.Access == Accessibility.Public))
        {
            var source = i.File.Source;
            foreach (var member in i.Decl.Members)
            {
                var (decl, name) = member switch { GetterDecl g => ((Decl?)g, g.Name), PropertyDecl p => (p, p.Name), _ => (null, null!) };
                if (decl is null || IsRenamed(decl) || i.Properties.FirstOrDefault(g => g.Location?.Span == name.Span) is not { } getter) continue;
                if (!CheckCount(c, grammar, source, name, getter.ReturnType)) CheckNumber(c, grammar, source, name, getter.ReturnType);
            }
            foreach (var fn in i.Methods)
                foreach (var p in fn.Parameters)
                    if (p.Syntax is { } syntax) CheckNumber(c, grammar, source, syntax.Name, p.Type);
            CheckDoer(c, grammar, source, i.Module, i.Decl, i.Decl.Name, i.Methods, i.Properties.Select(g => g.Name));
        }
        foreach (var u in module.Unions.Where(u => u.Access == Accessibility.Public))
            foreach (var v in u.Decl.Variants)
                CheckPayload(c, grammar, u.File.Source, v.Fields, u.Find(v.Name.Text)?.Fields);
        foreach (var set in module.ErrorSets.Where(s => s.Access == Accessibility.Public))
        {
            var source = module.Files.First(f => f.Tree.Root.Members.Contains(set.Decl)).Source;
            foreach (var v in set.Decl.Variants)
                CheckPayload(c, grammar, source, v.Fields, set.Find(v.Name.Text)?.Fields);
        }
    }

    private static void CheckPayload(Compilation c, Grammar grammar, SourceText source, UnionField[] fields, List<ParameterSymbol>? declared)
    {
        foreach (var f in fields)
            if (declared?.FirstOrDefault(p => p.Location?.Span == f.Name.Span) is { } field
                && !CheckCount(c, grammar, source, f.Name, field.Type))
                CheckNumber(c, grammar, source, f.Name, field.Type);
    }

    /// <summary>
    /// BYN5106 and BYN5107 on a public struct or interface named for a doer or a tool by its last word (revision 0021 Part 4):
    /// a built-in doer (<see cref="Doers"/>), <c>codec</c> (<c>encode</c> or <c>decode</c>), or a project verb's regular doer
    /// noun (<c>upsert</c> → <c>upserter</c>, <c>scan</c> → <c>scanner</c>). BYN5106: a public member, static or instance, is
    /// named its verb or a derived form (<c>tryX</c>, <c>xInto</c>, <c>xOp</c>). BYN5107: a tool (<see cref="Tools"/>) has no
    /// public <c>ref this</c> member. Other "-er" words (<c>Carrier</c>, <c>User</c>), function-type aliases and stored function
    /// fields are not types named for a doer here and are not checked, nor is the standard library.
    /// </summary>
    private static void CheckDoer(Compilation c, Grammar grammar, SourceText source, ModuleSymbol module, Decl decl, Name name, IEnumerable<FunctionSymbol> methods, IEnumerable<string> others)
    {
        // The standard library is not checked (Q1191): `std.json`'s `JsonReader` reads with `next`.
        if (module.Directory.StartsWith("<std>/", StringComparison.Ordinal) || IsRenamed(decl) || !name.Text.All(char.IsAscii) || Words(name.Text) is not [.., var last]) return;
        var noun = last.ToLowerInvariant();
        string[] verbs = noun == "codec" ? ["encode", "decode"]
            : Doers.TryGetValue(noun, out var verb) ? [verb]
            : grammar.Verbs.Where(v => DoerNouns(v).Contains(noun)).Order(StringComparer.Ordinal).Take(1).ToArray();
        if (verbs.Length == 0) return;
        var members = methods.ToList();
        bool Acts(string m) => verbs.Any(v => m == v || m == "try" + char.ToUpperInvariant(v[0]) + v[1..] || m == v + "Into" || m == v + "Op");
        if (!members.Select(m => m.Name).Concat(others).Any(Acts))
            c.Report(DiagnosticCodes.DoerWithoutVerb, source, name.Span, [name.Text, verbs[0]],
                help: $"add a member named {string.Join(" or ", verbs.Select(v => $"`{v}`"))}, or rename the type for what it is");
        if (!Tools.Contains(noun)) return;
        foreach (var m in members.Where(m => m.IsMutating && m.Decl is not null))
            c.Report(DiagnosticCodes.InstrumentChangesThis, source, m.Decl!.Name.Span, [name.Text, m.Name],
                help: "remove `ref this` and keep fixed settings in fields, or rename the type as a doer if it is fed data step by step");
    }

    /// <summary>The built-in doer and tool nouns and their verbs (revision 0021 Part 4); <c>codec</c> is <see cref="CheckDoer"/>'s.</summary>
    private static readonly Dictionary<string, string> Doers = new()
    {
        ["parser"] = "parse", ["builder"] = "build", ["reader"] = "read", ["writer"] = "write", ["recorder"] = "record",
        ["encoder"] = "encode", ["decoder"] = "decode", ["scanner"] = "scan", ["loader"] = "load", ["scheduler"] = "schedule",
        ["renderer"] = "render", ["formatter"] = "format", ["handler"] = "handle", ["hasher"] = "hash", ["comparer"] = "compare",
    };

    /// <summary>The tool nouns of BYN5107: a tool keeps fixed settings and does not change <c>this</c>.</summary>
    private static readonly HashSet<string> Tools = ["hasher", "comparer", "codec"];

    /// <summary>A verb's doer noun by regular spelling: <c>-er</c>, <c>-r</c> after <c>e</c>, <c>-ier</c> after a consonant and <c>y</c>, and a doubled final consonant (<c>scanner</c>).</summary>
    private static IEnumerable<string> DoerNouns(string verb)
    {
        if (verb.Length < 2) yield break;
        if (verb[^1] == 'e') { yield return verb + "r"; yield break; }
        if (verb[^1] == 'y' && !IsVowel(verb[^2])) { yield return verb[..^1] + "ier"; yield break; }
        yield return verb + "er";
        if (!IsVowel(verb[^1]) && !"wxy".Contains(verb[^1]) && IsVowel(verb[^2])) yield return verb + verb[^1] + "er";
    }

    /// <summary>A name under a rename attribute (<c>@json(name: …)</c>, <c>@column(…)</c>) is forced from outside and exempt from BYN5104 and BYN5105 (grammar guide §1).</summary>
    private static bool IsRenamed(Decl decl) => decl.Attributes.Any(a => a.Name.Text is "json" or "column");

    /// <summary>
    /// BYN5104: a collection (<c>List</c>, <c>Map</c>, spans, arrays, text views; <c>Untrusted</c>, <c>Owned</c> and
    /// <c>?</c> looked through) is named with a plural or a collective, anything else with a singular; the last word decides
    /// (revision 0021 Part 4), or the word before the first particle or function word. A <c>bool</c> is a state, not a noun, and a type parameter may be either; neither is checked.
    /// A collection is reported only when its last word is a known noun, so the plural in the message is always known; a number is never reported as plural.
    /// </summary>
    private static void CheckNumber(Compilation c, Grammar grammar, SourceText source, Name name, TypeSymbol type)
    {
        if (type.IsBool || type is TypeParameterType or ErrorType || name.Text == "_" || !name.Text.All(char.IsAscii)
            || WordSpans(name.Text) is not [_, ..] spans) return;
        // A particle or function word ends the head noun: `modulesByDir` is decided by `modules`; `byPath` and `inGroup` by none.
        bool IsLink(string w) => Lexicon.Particles.Contains(w.ToLowerInvariant()) || Lexicon.FunctionWords.Contains(w.ToLowerInvariant());
        if (IsLink(spans[0].Text)) return;
        var head = spans.FindIndex(1, w => IsLink(w.Text));
        var (start, text) = spans[head < 0 ? ^1 : head - 1];
        var word = text.ToLowerInvariant();
        if (Lexicon.Collectives.Contains(word) || grammar.Collectives.Contains(word)) return;
        var inner = type;
        while (inner is UntrustedType or OwnedType or OptionalType)
            inner = inner switch { UntrustedType u => u.Inner, OwnedType o => o.Inner, _ => ((OptionalType)inner).Inner };
        if (inner is ListType or MapType or SpanType or ArrayType or TextViewType)
        {
            // Only a noun has a plural: `covered`, `distinct` and `byKey` name a collection by what it holds or how it is keyed.
            if (LooksPlural(word, grammar) || !IsNoun(word, grammar)) return;
            var plural = name.Text[..start] + MatchCase(text, Plural(word, grammar)) + name.Text[(start + text.Length)..];
            c.Report(DiagnosticCodes.NumberAgreement, source, name.Span, [name.Text, plural],
                help: $"rename it `{plural}`", fix: new Fix(name.Span, plural));
        }
        // A number named with a plural is a quantity in units (`cents`, `grams`); a count is BYN5105's.
        else if (!inner.IsNumeric && IsPlural(word, grammar))
        {
            var singular = Singular(word, grammar) is { } one ? name.Text[..start] + MatchCase(text, one) + name.Text[(start + text.Length)..] : null;
            c.Report(DiagnosticCodes.NumberAgreementOne, source, name.Span, [name.Text, type.DisplayName],
                help: singular is null ? null : $"rename it `{singular}`", fix: singular is null ? null : new Fix(name.Span, singular));
        }
    }

    /// <summary>
    /// BYN5105: an integer that counts items is singular noun + <c>Count</c>; <c>&lt;plural&gt;Count</c>,
    /// <c>num&lt;Plural&gt;</c> and <c>numberOf&lt;Plural&gt;</c> are renamed (revision 0021 Part 4). <c>length</c> is not a count name. True when it reports, so BYN5104 does not report the name again.
    /// </summary>
    private static bool CheckCount(Compilation c, Grammar grammar, SourceText source, Name name, TypeSymbol type)
    {
        if (!type.IsInteger || !name.Text.All(char.IsAscii)) return false;
        var words = Words(name.Text);
        List<string> counted = words switch
        {
            [.. var rest, "Count"] when rest.Count > 0 => rest,
            ["num", .. var rest] when rest.Count > 0 => rest,
            ["number", "Of", .. var rest] when rest.Count > 0 => rest,
            _ => [],
        };
        if (counted.Count == 0) return false;
        var last = counted[^1].ToLowerInvariant();
        if (!IsPlural(last, grammar) || Singular(last, grammar) is not { } one) return false;
        var head = string.Concat(counted.SkipLast(1));
        var fixedName = head.Length == 0 ? one + "Count" : char.ToLowerInvariant(head[0]) + head[1..] + MatchCase(counted[^1], one) + "Count";
        c.Report(DiagnosticCodes.CountName, source, name.Span, [name.Text, fixedName],
            help: $"rename it `{fixedName}`", fix: new Fix(name.Span, fixedName));
        return true;
    }

    /// <summary>A plural the checker knows: an irregular plural, a project noun's <c>forms</c> entry (not a verb's, Q1207), or a regular plural of a known noun.</summary>
    private static bool IsPlural(string word, Grammar grammar) =>
        Lexicon.IrregularPlurals.Contains(word) || Singular(word, grammar) is not null;

    /// <summary>A word that may be a plural, for a collection's name: <see cref="IsPlural"/>, or any word ending in <c>s</c> but <c>ss</c>, <c>us</c> or <c>is</c>.</summary>
    private static bool LooksPlural(string word, Grammar grammar) =>
        IsPlural(word, grammar) || word.EndsWith('s') && !word.EndsWith("ss", StringComparison.Ordinal)
            && !word.EndsWith("us", StringComparison.Ordinal) && !word.EndsWith("is", StringComparison.Ordinal);

    /// <summary>The singular of <paramref name="word"/>: the project noun whose <c>forms</c> entry it is, else an irregular plural's singular (<see cref="Lexicon.IrregularSingulars"/>), else the first regular base (<see cref="Endings"/>) that is a known noun; null when none is known.</summary>
    private static string? Singular(string word, Grammar grammar)
    {
        if (grammar.Forms.FirstOrDefault(f => f.Value == word && IsNoun(f.Key, grammar)).Key is { } listed) return listed;
        if (Lexicon.IrregularSingulars.TryGetValue(word, out var irregular)) return irregular;
        if (word.EndsWith("ss", StringComparison.Ordinal) || word.EndsWith("us", StringComparison.Ordinal) || word.EndsWith("is", StringComparison.Ordinal)) return null;
        foreach (var (ending, replacements) in Endings.Where(e => e.Ending is "ies" or "es" or "s"))
        {
            if (word.Length <= ending.Length + 1 || !word.EndsWith(ending, StringComparison.Ordinal)) continue;
            foreach (var r in replacements)
                if (IsNoun(word[..^ending.Length] + r, grammar)) return word[..^ending.Length] + r;
        }
        return null;
    }

    /// <summary>The plural of <paramref name="word"/>: a project noun's <c>forms</c> entry, else the irregular plural whose singular it is (<see cref="Lexicon.IrregularSingulars"/>), else the regular spelling (<c>-s</c>, <c>-es</c>, <c>-ies</c>).</summary>
    private static string Plural(string word, Grammar grammar)
    {
        if (IsNoun(word, grammar) && grammar.Forms.TryGetValue(word, out var form)) return form;
        if (Lexicon.IrregularSingulars.FirstOrDefault(p => p.Value == word).Key is { } irregular) return irregular;
        if (word.Length > 1 && word[^1] == 'y' && !IsVowel(word[^2])) return word[..^1] + "ies";
        if (word.EndsWith('s') || word.EndsWith('x') || word.EndsWith('z') || word.EndsWith("ch", StringComparison.Ordinal) || word.EndsWith("sh", StringComparison.Ordinal))
            return word + "es";
        return word + "s";
    }

    private static bool IsNoun(string word, Grammar grammar) => Lexicon.Nouns.Contains(word) || grammar.Nouns.Contains(word);

    private static bool IsVerb(string word, Grammar grammar) => Lexicon.Verbs.Contains(word) || grammar.Verbs.Contains(word);

    /// <summary><paramref name="word"/> spelled with the first letter's case of <paramref name="like"/>: <c>Line</c>, <c>lines</c> → <c>Lines</c>.</summary>
    private static string MatchCase(string like, string word) =>
        word.Length > 0 && char.IsUpper(like[0]) ? char.ToUpperInvariant(word[0]) + word[1..] : word;

    /// <summary>BYN5001: an <c>-ed</c> name is a changed copy or a view, so a member that takes <c>ref this</c> is a plain verb (revision 0005).</summary>
    private static void CheckParticiple(Compilation c, Grammar grammar, SourceText source, Name name)
    {
        // A form is read by its word's class: the -ed spelling for a verb only, the plural for a noun (revision 0021 Part 3).
        var stems = grammar.Forms.Where(f => f.Value == name.Text && IsVerb(f.Key, grammar)).Select(f => f.Key).ToList();
        if (stems.Count == 0) stems = ParticipleStems(name.Text);
        if (stems.Count == 0) return;
        var stem = stems.FirstOrDefault(w => IsVerb(w, grammar)) ?? stems[0];
        c.Report(DiagnosticCodes.ParticipleChangesThis, source, name.Span, [name.Text, stem],
            help: "name the member that changes `this` with the plain verb, and keep `-ed` for the copy or view");
    }

    /// <summary>
    /// BYN5009: a particle is not a member name, and no instance member spells a conversion with <c>to</c> or <c>as</c>:
    /// a view is a noun (<c>asSpan</c> → <c>span</c>), a conversion is <c>T(x)</c> (<c>toList</c> → <c>List(x)</c>).
    /// </summary>
    private static void CheckParticleName(Compilation c, StructSymbol s, SourceText source, Name name, bool isStatic)
    {
        if (Lexicon.Particles.Contains(name.Text))
        {
            c.Report(DiagnosticCodes.ParticleAsMemberName, source, name.Span, [name.Text],
                help: "rename the member, for example `tryGet(at:)` instead of `at(…)`");
            return;
        }
        if (isStatic || Words(name.Text) is not [var particle and ("to" or "as"), var first, ..] || !char.IsUpper(first[0])) return;
        var rest = name.Text[particle.Length..];
        var instead = particle == "as"
            ? char.ToLowerInvariant(rest[0]) + rest[1..]
            : $"{(Primitives.Contains(rest.ToLowerInvariant()) ? rest.ToLowerInvariant() : rest)}({ToCamel(s.Name)})";
        c.Report(DiagnosticCodes.ConversionMember, source, name.Span, [name.Text, particle, instead],
            help: "use a view noun, `copy()`, or a `T(x)` conversion");
    }

    /// <summary>The primitive type names a <c>toX</c> conversion is written in lowercase: <c>toString</c> → <c>string(x)</c>.</summary>
    private static readonly HashSet<string> Primitives =
    [
        "string", "bool", "rune", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "f32", "f64",
        "sbyte", "byte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double",
    ];

    /// <summary>
    /// BYN5014: every word of a member name is a word the checker knows, from <see cref="Lexicon"/> or the
    /// project's <c>grammar</c> (J85), directly or by a regular ending (<see cref="Bases"/>). Names with letters
    /// outside ASCII, single letters and math names are not checked. The help offers the three classes, the best guess
    /// first: <paramref name="guess"/> is <c>verbs</c> for a member that changes <c>this</c>, <c>adjectives</c> for a
    /// <c>bool</c> member (a state or condition), else <c>nouns</c>.
    /// </summary>
    private static void CheckWords(Compilation c, Grammar grammar, SourceText source, Name name, string guess)
    {
        if (Lexicon.Math.Contains(name.Text) || !name.Text.All(char.IsAscii)) return;
        foreach (var (start, text) in WordSpans(name.Text))
        {
            var word = text.ToLowerInvariant().TrimEnd("0123456789".ToCharArray());
            if (word.Length < 2 || !word.All(char.IsAsciiLetterLower) || Lexicon.Math.Contains(text.ToLowerInvariant())) continue;
            if (IsKnown(word, grammar)) continue;
            c.Report(DiagnosticCodes.UnknownWord, source, new TextSpan(name.Span.Start + start, text.Length), [word],
                help: $"add it to `grammar` in package.byn: {Offer(guess, word)}, {Offer(guess == "verbs" ? "nouns" : "verbs", word)} or {Offer(guess == "adjectives" ? "nouns" : "adjectives", word)}");
        }
    }

    private static string Offer(string field, string word) => $"`{field}: [\"{word}\"]`";

    private static bool IsKnown(string word, Grammar grammar)
    {
        bool Listed(string w) => Lexicon.Verbs.Contains(w) || Lexicon.Nouns.Contains(w) || Lexicon.Adjectives.Contains(w)
            || Lexicon.Collectives.Contains(w) || Lexicon.IrregularPlurals.Contains(w)
            || Lexicon.Particles.Contains(w) || Lexicon.FunctionWords.Contains(w)
            || grammar.Verbs.Contains(w) || grammar.Nouns.Contains(w) || grammar.Adjectives.Contains(w)
            || grammar.Collectives.Contains(w);
        return Listed(word) || grammar.Forms.ContainsValue(word) || Bases(word).Any(Listed);
    }

    /// <summary>
    /// The words <paramref name="word"/> may be a regular form of: plurals and third person (<c>-s</c>, <c>-es</c>,
    /// <c>-ies</c>), <c>-ed</c>, <c>-ing</c>, doers (<c>-er</c>, <c>-or</c>), <c>-est</c>, <c>-ly</c>, and <c>un-</c>/<c>re-</c>;
    /// a doubled final consonant is undone (<c>runner</c> → <c>run</c>).
    /// </summary>
    private static IEnumerable<string> Bases(string word)
    {
        foreach (var (ending, replacements) in Endings)
        {
            if (word.Length <= ending.Length + 1 || !word.EndsWith(ending, StringComparison.Ordinal)) continue;
            var bare = word[..^ending.Length];
            foreach (var r in replacements) yield return bare + r;
            if (bare.Length >= 3 && bare[^1] == bare[^2]) yield return bare[..^1];
            if (ending == "ers") foreach (var b in Bases(word[..^1])) yield return b;
        }
        foreach (var prefix in new[] { "un", "re" })
        {
            if (word.Length <= prefix.Length + 2 || !word.StartsWith(prefix, StringComparison.Ordinal)) continue;
            yield return word[prefix.Length..];
            foreach (var b in Bases(word[prefix.Length..])) yield return b;
        }
    }

    private static readonly (string Ending, string[] Replacements)[] Endings =
    [
        ("ies", ["y"]), ("es", ["", "e"]), ("s", [""]), ("ied", ["y"]), ("ed", ["", "e"]), ("ing", ["", "e"]),
        ("ier", ["y"]), ("er", ["", "e"]), ("ers", []), ("or", ["", "e"]), ("est", ["", "e"]), ("ly", [""]),
    ];

    /// <summary>The project dictionary from <c>package.byn</c> beside the package's sources; empty without one.</summary>
    private static Grammar GrammarOf(Compilation c) => Grammars.GetValue(c, _ =>
    {
        var path = Path.Combine(c.DisplayRoot, "package.byn");
        var grammar = File.Exists(path) ? Manifest.Read(path).Grammar : new Grammar();
        var lower = new Grammar();
        lower.Verbs.UnionWith(grammar.Verbs.Select(w => w.ToLowerInvariant()));
        lower.Nouns.UnionWith(grammar.Nouns.Select(w => w.ToLowerInvariant()));
        lower.Adjectives.UnionWith(grammar.Adjectives.Select(w => w.ToLowerInvariant()));
        lower.Collectives.UnionWith(grammar.Collectives.Select(w => w.ToLowerInvariant()));
        foreach (var (word, form) in grammar.Forms) lower.Forms[word.ToLowerInvariant()] = form.ToLowerInvariant();
        return lower;
    });

    private static readonly ConditionalWeakTable<Compilation, Grammar> Grammars = new();

    private static void CheckBoolState(Compilation c, SourceText source, Name name)
    {
        if (IsStateName(name.Text) || NotStates.Any(w => name.Text.StartsWith(w, StringComparison.Ordinal))) return;
        var fixedName = "is" + char.ToUpperInvariant(name.Text[0]) + name.Text[1..];
        c.Report(DiagnosticCodes.BoolWithoutPrefix, source, name.Span, [name.Text],
            help: $"rename it `{fixedName}`", fix: new Fix(name.Span, fixedName));
    }

    /// <summary><c>isX</c>, <c>hasX</c>, <c>canX</c>: the prefix, then a capital.</summary>
    private static bool IsStateName(string name) =>
        new[] { "is", "has", "can" }.Any(p => name.Length > p.Length && name.StartsWith(p, StringComparison.Ordinal) && char.IsUpper(name[p.Length]));

    /// <summary>
    /// The verbs <paramref name="name"/> may be the <c>-ed</c> form of, most likely first; empty when it is
    /// not a participle. Only a single lowercase word ending in <c>-ed</c> counts: <c>sorted</c> → sort,
    /// <c>reversed</c> → reverse, <c>trimmed</c> → trim, <c>copied</c> → copy. Words ending in
    /// <c>-eed</c> (<c>need</c>, <c>speed</c>), words shorter than five letters (<c>red</c>, <c>bed</c>, <c>used</c>)
    /// and <see cref="NotParticiples"/> are not participles.
    /// </summary>
    public static List<string> ParticipleStems(string name)
    {
        var stems = new List<string>();
        if (name.Length < 5 || !name.EndsWith("ed", StringComparison.Ordinal) || name.EndsWith("eed", StringComparison.Ordinal)
            || !name.All(char.IsAsciiLetterLower) || NotParticiples.Contains(name)) return stems;
        var bare = name[..^2];
        if (bare.EndsWith('i')) stems.Add(bare[..^1] + "y");
        if (bare.Length >= 4 && bare[^1] == bare[^2] && !"aeiouls".Contains(bare[^1])) stems.Add(bare[..^1]);
        // `reversed`, `parsed`, `doubled`, `named` drop only the `d`; `sorted`, `joined` drop `ed`.
        var keepsE = "cuvz".Contains(bare[^1]) || (bare[^1] == 's' && bare[^2] != 's') || (bare[^1] == 'l' && !IsVowel(bare[^2]) && bare[^2] != 'l')
            || (bare.Length == 3 && !IsVowel(bare[0]) && IsVowel(bare[1]) && !IsVowel(bare[2]) && !"wxy".Contains(bare[2]));
        stems.AddRange(keepsE ? [name[..^1], bare] : [bare, name[..^1]]);
        return stems;
    }

    private static bool IsVowel(char ch) => "aeiou".Contains(ch);

    /// <summary>Common words ending in <c>-ed</c> that are not the <c>-ed</c> form of a verb.</summary>
    private static readonly HashSet<string> NotParticiples = ["hundred", "embed", "shred", "naked", "wicked", "sacred", "kindred"];

    /// <summary>The first word of a <c>ref this</c> member that names a thing, not an action (BYN5101).</summary>
    private static readonly HashSet<string> Nouns =
    [
        "size", "length", "total", "sum", "value", "values", "data", "item", "items", "element", "elements",
        "result", "results", "name", "id", "state", "status", "info", "content", "contents", "capacity",
        "amount", "number", "key", "keys", "entry", "entries", "node", "nodes",
    ];

    /// <summary>Verbs that ask a question and need no prefix (BYN5102): <c>contains</c>, <c>equals</c>, …; <c>tryX</c> is an attempt.</summary>
    private static readonly string[] NotStates = ["contains", "equals", "matches", "startsWith", "endsWith", "try"];

    public static string ToPascal(string name)
    {
        var words = Words(name);
        if (words.Count == 0) return name;
        var sb = new StringBuilder();
        foreach (var w in words) sb.Append(Capitalize(w));
        return sb.ToString();
    }

    public static string ToCamel(string name)
    {
        var words = Words(name);
        if (words.Count == 0) return name;
        var sb = new StringBuilder(words[0].ToLowerInvariant());
        foreach (var w in words.Skip(1)) sb.Append(Capitalize(w));
        return sb.ToString();
    }

    /// <summary>Two-letter acronyms stay uppercase (<c>IO</c>); other words are capitalized.</summary>
    private static string Capitalize(string word)
    {
        if (word.Length == 0) return word;
        if (word.Length == 2 && word.All(char.IsUpper)) return word;
        return char.ToUpperInvariant(word[0]) + word[1..].ToLowerInvariant();
    }

    /// <summary>
    /// Splits at underscores and case changes: <c>HTTPClient</c> → HTTP, Client;
    /// <c>parse_url</c> → parse, url; <c>IOError</c> → IO, Error. Uncased letters and digits
    /// stay with the word they follow.
    /// </summary>
    private static List<string> Words(string name) => WordSpans(name).Select(w => w.Text).ToList();

    /// <summary><see cref="Words"/>, each with its offset in <paramref name="name"/>.</summary>
    private static List<(int Start, string Text)> WordSpans(string name)
    {
        var words = new List<(int, string)>();
        var current = new StringBuilder();
        var start = 0;
        void Flush()
        {
            if (current.Length > 0) words.Add((start, current.ToString()));
            current.Clear();
        }
        for (var i = 0; i < name.Length; i++)
        {
            var ch = name[i];
            if (ch == '_')
            {
                Flush();
                continue;
            }
            if (char.IsUpper(ch) && current.Length > 0)
            {
                var prev = name[i - 1];
                var nextIsLower = i + 1 < name.Length && char.IsLower(name[i + 1]);
                if (char.IsLower(prev) || char.IsDigit(prev) || (char.IsUpper(prev) && nextIsLower)) Flush();
            }
            if (current.Length == 0) start = i;
            current.Append(ch);
        }
        Flush();
        return words;
    }
}
