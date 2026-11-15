using Bayan.Syntax.Ast;
using Bayan.Syntax.Lexing;
using Bayan.Syntax.Parsing;
using Bayan.Syntax.Text;

namespace Bayan.Cli;

/// <summary>The project's layout knobs (<c>style</c> in <c>package.byn</c>).</summary>
internal sealed record LayoutOptions(int Indent = 4, int Width = 120, bool AlignRuns = true, bool TrailingCommasMultiline = true);

/// <summary>
/// The layout pass of <c>bayan format</c> (docs/bayan-style-proposal.md §3): it rewrites only the whitespace between
/// tokens and the trailing commas before a closer. It joins and breaks lines only where spec §5 lets a line continue:
/// inside <c>( )</c> and <c>[ ]</c>, after <c>,</c> or <c>{</c>, and before a leading <c>.</c>, <c>&amp;&amp;</c>,
/// <c>||</c>, <c>and</c>, <c>or</c> or a clause keyword. Comments are the source bytes between token spans.
/// The output is kept only when it lexes to the same tokens (trailing commas aside), keeps the same comments and parses
/// with the same diagnostics; otherwise the input comes back with the reason.
/// </summary>
internal static class Layout
{
    /// <summary>Rounds of the engine over its own output: a join can fit only once a later break has shortened its line.</summary>
    private const int Rounds = 4;

    /// <summary>Test-only: replaces the laid-out bytes before the safety check, to force a difference.</summary>
    [ThreadStatic] internal static Func<byte[], byte[]>? OutputHook;

    /// <summary>A newline, or a <c>//</c> comment (or a <c>#!</c>/<c>#:</c> line at the top) without its trailing blanks.</summary>
    private readonly record struct GapItem(bool IsComment, int Start, int End);

    private sealed record Gap(List<GapItem> Items, bool HasNewline, bool HasBlank);

    /// <summary>An open <c>{</c>, <c>(</c>, <c>[</c> (or the file), with the level of its line and its current statement.</summary>
    private sealed class Frame
    {
        public TokenKind Opener;
        public int Line;
        public int Statement;
        public int StatementIndent;
        public bool Control;
        public bool Clause;
        public int Body = -1;
    }

    private enum Side : byte { Defer, Space, None, Keep }

    internal static (byte[] Output, string? SkipReason) Apply(byte[] source, LayoutOptions options)
    {
        var tokens = Lexer.Lex(new SourceText("layout", source)).Tokens.ToArray();
        var bom = source.Length >= 3 && source[0] == 0xEF && source[1] == 0xBB && source[2] == 0xBF ? 3 : 0;
        var gaps = Gaps(source, tokens, bom);
        if (gaps is null) return (source, "text between tokens that is neither whitespace nor a `//` comment");
        var tree = SyntaxTree.Parse(new SourceText("layout", source));
        var output = new Engine(source, tokens, gaps, bom, tree, options).Render();
        for (var round = 1; round < Rounds; round++)
        {
            var roundTokens = Lexer.Lex(new SourceText("layout", output)).Tokens.ToArray();
            if (Gaps(output, roundTokens, bom) is not { } roundGaps) break;
            var next = new Engine(output, roundTokens, roundGaps, bom, SyntaxTree.Parse(new SourceText("layout", output)), options).Render();
            if (next.AsSpan().SequenceEqual(output)) break;
            output = next;
        }
        if (OutputHook is not null) output = OutputHook(output);
        return Check(source, tokens, gaps, tree, output) is { } reason ? (source, reason) : (output, null);
    }

    /// <summary>The gap before each token, or null when one holds something other than blanks, newlines and line comments.</summary>
    private static Gap[]? Gaps(byte[] source, Token[] tokens, int bom)
    {
        var gaps = new Gap[tokens.Length];
        for (var i = 0; i < tokens.Length; i++)
        {
            var from = i == 0 ? bom : tokens[i - 1].End;
            var items = new List<GapItem>();
            var at = from;
            var blank = false;
            var lineEmpty = i == 0;
            while (at < tokens[i].Start)
            {
                var b = source[at];
                if (b is (byte)' ' or (byte)'\t' or (byte)'\r')
                {
                    at++;
                    continue;
                }
                if (b == '\n')
                {
                    if (lineEmpty && items.Count > 0) blank = true;
                    items.Add(new GapItem(false, at, at + 1));
                    lineEmpty = true;
                    at++;
                    continue;
                }
                var shebang = b == '#' && i == 0 && (at == from || source[at - 1] == '\n');
                if (!shebang && !(b == '/' && at + 1 < tokens[i].Start && source[at + 1] == '/')) return null;
                var end = at;
                while (end < tokens[i].Start && source[end] != '\n') end++;
                var trimmed = end;
                while (trimmed > at && source[trimmed - 1] is (byte)' ' or (byte)'\t' or (byte)'\r') trimmed--;
                items.Add(new GapItem(true, at, trimmed));
                lineEmpty = false;
                at = end;
            }
            gaps[i] = new Gap(items, items.Any(x => !x.IsComment), blank);
        }
        return gaps;
    }

    /// <summary>Why <paramref name="output"/> may not replace <paramref name="source"/>, or null when it may.</summary>
    private static string? Check(byte[] source, Token[] tokens, Gap[] gaps, SyntaxTree tree, byte[] output)
    {
        var after = Lexer.Lex(new SourceText("layout", output)).Tokens.ToArray();
        if (!Significant(source, tokens).SequenceEqual(Significant(output, after))) return "the tokens changed";
        if (!Adjacency(source, tokens).SequenceEqual(Adjacency(output, after))) return "the spacing the parser reads changed";
        var bom = output.Length >= 3 && output[0] == 0xEF && output[1] == 0xBB && output[2] == 0xBF ? 3 : 0;
        var afterGaps = Gaps(output, after, bom);
        if (afterGaps is null || !Comments(source, gaps).SequenceEqual(Comments(output, afterGaps))) return "the comments changed";
        var reparsed = SyntaxTree.Parse(new SourceText("layout", output));
        if (!tree.Diagnostics.Select(d => d.Code).SequenceEqual(reparsed.Diagnostics.Select(d => d.Code))) return "the diagnostics changed";
        return null;
    }

    /// <summary>The tokens as kind and text, less each trailing comma (a <c>,</c> before <c>)</c>, <c>]</c> or <c>}</c>).</summary>
    private static IEnumerable<(TokenKind, string)> Significant(byte[] bytes, Token[] tokens) =>
        tokens.Where((t, i) => !(t.Kind == TokenKind.Comma && i + 1 < tokens.Length
                                 && tokens[i + 1].Kind is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace))
            .Select(t => (t.Kind, System.Text.Encoding.UTF8.GetString(bytes, t.Start, t.Length)));

    /// <summary>
    /// Whether a gap goes before each significant token, at the positions where the parser reads it, and null elsewhere.
    /// Layout keeps the gap at those positions (<see cref="TriviaMatters"/>); this catches a rule that would not.
    /// </summary>
    private static IEnumerable<bool?> Adjacency(byte[] bytes, Token[] tokens) =>
        Enumerable.Range(0, tokens.Length)
            .Where(i => !(tokens[i].Kind == TokenKind.Comma && i + 1 < tokens.Length
                          && tokens[i + 1].Kind is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace))
            .Select(i => TriviaMatters(bytes, tokens, i) ? tokens[i].HasTriviaBefore : (bool?)null);

    /// <summary>
    /// Whether the parser branches on the gap before token <paramref name="i"/> (<c>HasTriviaBefore</c> in Parser.cs):
    /// <list type="bullet">
    /// <item><c>&gt;</c> then <c>&gt;</c> or <c>&gt;=</c> with no gap is a shift, <c>&gt;&gt;</c> or <c>&gt;&gt;=</c> (<c>AtShiftRight</c>, <c>IsAssignOp</c>, the binary-operator table);</item>
    /// <item><c>..</c> then <c>.</c> with no gap is a rest input, <c>T... name</c> (parameter lists);</item>
    /// <item>a <c>*</c> with no gap after a type is a pointer, <c>u8*</c>, and a type scan also wants a gap after the
    /// <c>*</c> run (<c>ScanType</c>, <c>ParseType</c>): <c>u8* p</c> is a declaration, <c>a*b</c> a product;</item>
    /// <item>a numeric suffix with no gap belongs to its literal, <c>30s</c> (<c>ParsePrimary</c>);</item>
    /// <item><c>unlikely</c> followed by a gap is the branch hint of <c>if unlikely (a)…</c>, not a call (<c>AtUnlikely</c>).</item>
    /// </list>
    /// The two other reads of <c>HasTriviaBefore</c> in Parser.cs only build a fix's text. The lexer keeps no state between
    /// tokens, so its adjacency shows in the tokens themselves, which <see cref="Check"/> compares; newlines the parser
    /// reads (<c>HasNewlineBefore</c>) are kept by the break and join rules and checked by the diagnostics.
    /// </summary>
    private static bool TriviaMatters(byte[] bytes, Token[] tokens, int i)
    {
        if (i == 0 || i >= tokens.Length) return false;
        var (before, kind) = (tokens[i - 1].Kind, tokens[i].Kind);
        return before == TokenKind.Greater && kind is TokenKind.Greater or TokenKind.GreaterEquals
            || before == TokenKind.DotDot && kind == TokenKind.Dot
            || kind == TokenKind.Star && (TypeEnd(before) || before == TokenKind.Star)
            || before == TokenKind.Star && !tokens[i - 1].HasTriviaBefore
            || kind == TokenKind.NumericSuffix
            || before == TokenKind.Identifier && bytes.AsSpan(tokens[i - 1].Start, tokens[i - 1].Length).SequenceEqual("unlikely"u8);
    }

    /// <summary>A token a type can end with, so that a <c>*</c> after it may make a pointer.</summary>
    private static bool TypeEnd(TokenKind kind) =>
        kind is TokenKind.Identifier or TokenKind.Greater or TokenKind.Question or TokenKind.CloseBracket || kind.IsContextualKeyword();

    private static IEnumerable<string> Comments(byte[] bytes, Gap[] gaps) =>
        gaps.SelectMany(g => g.Items).Where(x => x.IsComment)
            .Select(x => System.Text.Encoding.UTF8.GetString(CommentText(bytes, x)));

    /// <summary>A comment as written, with one space after its <c>//</c> run when text follows it directly (proposal §3.8).</summary>
    private static byte[] CommentText(byte[] bytes, GapItem item)
    {
        var text = bytes.AsSpan(item.Start, item.End - item.Start);
        var slashes = 0;
        while (slashes < text.Length && text[slashes] == '/') slashes++;
        if (slashes == 0 || slashes == text.Length || text[slashes] is (byte)' ' or (byte)'\t') return text.ToArray();
        return [.. text[..slashes], (byte)' ', .. text[slashes..]];
    }

    private sealed class Engine(byte[] source, Token[] tokens, Gap[] gaps, int bom, SyntaxTree tree, LayoutOptions options)
    {
        private readonly bool[] _lineStart = new bool[tokens.Length];
        private readonly int[] _level = new int[tokens.Length];
        private readonly bool[] _frozen = new bool[tokens.Length];
        private readonly bool[] _inHole = new bool[tokens.Length];
        private readonly bool[] _needsBlank = new bool[tokens.Length];
        private readonly int[] _match = new int[tokens.Length];
        private readonly bool[] _dropComma = new bool[tokens.Length];
        private readonly bool[] _addComma = new bool[tokens.Length];
        private readonly int[] _pad = new int[tokens.Length];
        private readonly int[] _commentPad = new int[tokens.Length];
        private readonly bool[] _tightAfter = new bool[tokens.Length];
        private readonly bool[] _tightBefore = new bool[tokens.Length];
        private readonly List<byte> _out = new(source.Length + source.Length / 8);

        public byte[] Render()
        {
            for (var i = 0; i < tokens.Length; i++) _lineStart[i] = i == 0 || gaps[i].HasNewline;
            Freeze();
            Match();
            Guide();
            Levels();
            Joins();
            Breaks();
            Levels();
            TopLevelBlanks();
            MemberBlanks();
            if (options.AlignRuns) Align();
            _out.AddRange(source.AsSpan(0, bom));
            for (var i = 0; i < tokens.Length; i++)
            {
                if (_dropComma[i]) continue;
                EmitGap(i);
                _out.AddRange(source.AsSpan(tokens[i].Start, tokens[i].Length));
                if (_addComma[i]) _out.Add((byte)',');
            }
            return [.. _out];
        }

        private TokenKind Kind(int i) => i >= 0 && i < tokens.Length ? tokens[i].Kind : TokenKind.EndOfFile;

        private string Text(int i) => System.Text.Encoding.UTF8.GetString(source, tokens[i].Start, tokens[i].Length);

        private bool Trivia(int i) => tokens[i].HasTriviaBefore;

        /// <summary>The first token starting at or after <paramref name="offset"/>.</summary>
        private int TokenAt(int offset)
        {
            int lo = 0, hi = tokens.Length - 1;
            while (lo < hi)
            {
                var mid = (lo + hi) / 2;
                if (tokens[mid].Start < offset) lo = mid + 1;
                else hi = mid;
            }
            return lo;
        }

        // ── Frozen gaps: `@unformatted because "…"` declarations (proposal §4.4); a hole's line breaks ──

        private void Freeze()
        {
            var depth = 0;
            for (var i = 0; i < tokens.Length; i++)
            {
                if (depth > 0) _inHole[i] = true;
                if (tokens[i].Kind == TokenKind.InterpolatedStringStart) depth++;
                else if (tokens[i].Kind == TokenKind.InterpolatedStringEnd && depth > 0) depth--;
            }
            foreach (var (start, end) in Unformatted(tree.Root.Members))
                for (var i = TokenAt(start) + 1; i < tokens.Length && tokens[i].End <= end; i++)
                    _frozen[i] = true;
        }

        private static IEnumerable<(int Start, int End)> Unformatted(Decl[] decls)
        {
            foreach (var decl in decls)
            {
                foreach (var a in decl.Attributes)
                    if (a.Name.Text == "unformatted" && a.Because is not null)
                        yield return (a.Span.Start, Math.Max(a.Span.End, decl.Span.End));
                var members = decl switch
                {
                    StructDecl s => s.Members,
                    InterfaceDecl n => n.Members,
                    ExtensionDecl e => e.Members,
                    _ => [],
                };
                foreach (var region in Unformatted(members)) yield return region;
            }
        }

        // ── Indentation (pass 5) ──────────────────────────────────────────────────────────

        /// <summary>The columns of the spaces and tabs that start the original line of token <paramref name="i"/>; a tab is a level.</summary>
        private int OriginalIndent(int i)
        {
            var at = tokens[i].Start;
            var n = 0;
            while (at > bom && source[at - 1] is (byte)' ' or (byte)'\t')
            {
                at--;
                n += source[at] == '\t' ? options.Indent : 1;
            }
            return n;
        }

        private void Levels()
        {
            var frames = new List<Frame> { new() { Opener = TokenKind.EndOfFile, Line = -1 } };
            for (var i = 0; i < tokens.Length;)
            {
                var j = i + 1;
                while (j < tokens.Length && !_lineStart[j]) j++;
                var top = frames[^1];
                var first = Kind(i);
                int level;
                // A `{` that ends a header clause or a wrapped condition opens a body at the statement's level.
                var body = -1;
                if (first == TokenKind.EndOfFile) level = 0;
                else if (first is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace)
                {
                    level = Math.Max(0, top.Line);
                    // `) {` closing a list opened on a clause or condition line opens that line's body.
                    body = top.Body;
                }
                else
                {
                    var inGroup = top.Opener is TokenKind.OpenParen or TokenKind.OpenBracket;
                    var before = Kind(i - 1);
                    bool continues;
                    if (i == 0 || before is TokenKind.OpenParen or TokenKind.OpenBracket or TokenKind.OpenBrace) continues = false;
                    // After `,` a line starts an entry, except in a top-level or clause list (`effect db = net,`, `uses net,`).
                    else if (before == TokenKind.Comma) continues = !inGroup && (frames.Count == 1 || top.Clause);
                    else if (!inGroup && gaps[i].HasBlank) continues = false;
                    else continues = IsWasl(i) || AfterLa(before);
                    if (!continues)
                    {
                        level = top.Line + 1;
                        top.Statement = level;
                        top.StatementIndent = OriginalIndent(i);
                        top.Control = first is TokenKind.IfKeyword or TokenKind.WhileKeyword or TokenKind.ForKeyword or TokenKind.UnlessKeyword;
                        top.Clause = false;
                    }
                    // A struct-level `requires` and a `catch` after `}` may sit at the statement's indentation (BYN5103 exempts them).
                    else if ((first == TokenKind.RequiresKeyword || first == TokenKind.CatchKeyword && before == TokenKind.CloseBrace)
                             && OriginalIndent(i) <= top.StatementIndent)
                        level = top.Statement;
                    else
                    {
                        var clause = IsClause(i);
                        level = top.Statement + (clause || top.Control || top.Clause ? 2 : 1);
                        if (clause || top.Control || top.Clause) body = top.Statement;
                        top.Clause |= clause;
                    }
                }
                _level[i] = level;
                for (var k = i; k < j; k++)
                {
                    switch (Kind(k))
                    {
                        case TokenKind.OpenParen or TokenKind.OpenBracket or TokenKind.OpenBrace or TokenKind.InterpolationStart:
                            var line = Kind(k) == TokenKind.OpenBrace && body >= 0 ? body : level;
                            frames.Add(new Frame { Opener = Kind(k), Line = line, Statement = line, StatementIndent = OriginalIndent(i), Body = body });
                            break;
                        case TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace or TokenKind.InterpolationEnd:
                            if (frames.Count > 1) frames.RemoveAt(frames.Count - 1);
                            break;
                    }
                }
                i = j;
            }
        }

        /// <summary>A token that joins the line it starts to the line before (waṣl), as the parser reads it.</summary>
        private bool IsWasl(int i) => Kind(i) is TokenKind.Dot or TokenKind.QuestionDot or TokenKind.QuestionQuestion
            or TokenKind.AmpAmp or TokenKind.BarBar or TokenKind.AndKeyword or TokenKind.OrKeyword or TokenKind.CatchKeyword
            or TokenKind.ExceptKeyword or TokenKind.RequiresKeyword or TokenKind.FailsKeyword or TokenKind.UsesKeyword
            || IsClause(i);

        /// <summary>A header clause keyword: <c>where</c>, <c>expects</c>, <c>uses</c>, <c>becomes</c> or <c>fails</c>.</summary>
        private bool IsClause(int i) => Kind(i) is TokenKind.FailsKeyword or TokenKind.UsesKeyword
            || Kind(i) == TokenKind.Identifier && Text(i) switch
            {
                "where" => Kind(i + 1) == TokenKind.Identifier && Kind(i + 2) == TokenKind.Colon,
                "becomes" => Kind(i + 1) == TokenKind.Dot,
                "expects" => Kind(i + 1) is TokenKind.Identifier or TokenKind.Bang or TokenKind.NotKeyword or TokenKind.ThisKeyword,
                _ => false,
            };

        /// <summary>Whether a line ending in <paramref name="kind"/> continues on the next (lā).</summary>
        private static bool AfterLa(TokenKind kind) => kind is
            TokenKind.Comma or TokenKind.FatArrow or TokenKind.OpenBrace or TokenKind.OpenParen or TokenKind.OpenBracket or
            TokenKind.Dot or TokenKind.DotDot or TokenKind.DotDotEquals or TokenKind.Question or TokenKind.QuestionQuestion or
            TokenKind.QuestionDot or TokenKind.Plus or TokenKind.Minus or TokenKind.Star or TokenKind.Slash or TokenKind.Percent or
            TokenKind.PlusPercent or TokenKind.MinusPercent or TokenKind.StarPercent or TokenKind.PlusBar or TokenKind.MinusBar or
            TokenKind.StarBar or TokenKind.Amp or TokenKind.AmpAmp or TokenKind.Bar or TokenKind.BarBar or TokenKind.Caret or
            TokenKind.EqualsEquals or TokenKind.BangEquals or TokenKind.Less or TokenKind.LessEquals or TokenKind.GreaterEquals or
            TokenKind.LessLess or TokenKind.AndKeyword or TokenKind.OrKeyword or TokenKind.IsKeyword or TokenKind.InKeyword or
            TokenKind.Equals or TokenKind.PlusEquals or TokenKind.MinusEquals or TokenKind.StarEquals or TokenKind.SlashEquals or
            TokenKind.PercentEquals or TokenKind.AmpEquals or TokenKind.BarEquals or TokenKind.CaretEquals or
            TokenKind.LessLessEquals or TokenKind.QuestionQuestionEquals;

        // ── Joins (pass 3) and breaks (pass 4): lists, chains, header clauses, conditions (proposal §3.4–§3.6) ──

        /// <summary>A member chain: its receiver's first token, its last token, the <c>.</c> of each link, and those that break.</summary>
        private sealed record Chain(int Start, int End, List<int> Dots, List<int> Breakable, int LambdaCalls);

        private static bool IsOpener(TokenKind kind) =>
            kind is TokenKind.OpenParen or TokenKind.OpenBracket or TokenKind.OpenBrace or TokenKind.InterpolationStart;

        private static bool IsCloser(TokenKind kind) =>
            kind is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace or TokenKind.InterpolationEnd;

        private void Match()
        {
            var open = new Stack<int>();
            for (var i = 0; i < tokens.Length; i++)
            {
                _match[i] = -1;
                if (IsOpener(Kind(i))) open.Push(i);
                else if (IsCloser(Kind(i)) && open.Count > 0)
                {
                    var o = open.Pop();
                    _match[o] = i;
                    _match[i] = o;
                }
            }
        }

        /// <summary>The columns token <paramref name="i"/> takes: its UTF-8 lead bytes.</summary>
        private int Columns(int i)
        {
            var n = 0;
            foreach (var b in source.AsSpan(tokens[i].Start, tokens[i].Length))
                if ((b & 0xC0) != 0x80) n++;
            return n;
        }

        private bool Multiline(int i) => source.AsSpan(tokens[i].Start, tokens[i].Length).Contains((byte)'\n');

        private int LineStartOf(int i)
        {
            while (i > 0 && !_lineStart[i]) i--;
            return i;
        }

        /// <summary>The first token after <paramref name="i"/> that starts a line, or the end of the file.</summary>
        private int LineEnd(int i)
        {
            for (i++; i < tokens.Length - 1; i++)
                if (_lineStart[i]) return i;
            return tokens.Length - 1;
        }

        /// <summary>The columns of tokens <c>[s, e)</c> written as one line from line start <paramref name="s"/>; 0 when a token spans lines.</summary>
        private int Width(int s, int e)
        {
            var width = _level[s] * options.Indent;
            for (var k = s; k < e; k++)
            {
                if (_dropComma[k]) continue;
                if (Multiline(k)) return 0;
                if (k > s && Space(k, tokens[k - 1].End)) width++;
                width += Columns(k) + (_addComma[k] ? 1 : 0);
            }
            return width;
        }

        /// <summary>Whether the structure over tokens <c>[from, to]</c> may change: none is frozen and it is not in an interpolation hole.</summary>
        private bool Editable(int from, int to)
        {
            if (_inHole[from]) return false;
            for (var k = from; k <= to; k++)
                if (_frozen[k]) return false;
            return true;
        }

        /// <summary>The tokens directly inside the list <c>(o, c)</c>, stepping over nested brackets.</summary>
        private IEnumerable<int> Items(int o, int c)
        {
            for (var k = o + 1; k < c; k++)
            {
                yield return k;
                if (IsOpener(Kind(k)) && _match[k] > k) k = _match[k];
            }
        }

        private bool TrailingComma(int c) => Kind(c - 1) == TokenKind.Comma && !_dropComma[c - 1];

        /// <summary>A <c>{</c> that opens a struct literal or a <c>with</c> update: a type name or <c>with</c>, then <c>name:</c>.</summary>
        private bool IsStructLiteral(int o) => Kind(o) == TokenKind.OpenBrace && _match[o] > o
            && Kind(o - 1) is TokenKind.Identifier or TokenKind.Greater or TokenKind.WithKeyword
            && Kind(o + 1) == TokenKind.Identifier && Kind(o + 2) == TokenKind.Colon;

        /// <summary>
        /// Whether the parser takes a trailing comma in the list <c>(o, c)</c>: an argument list, a <c>[ ]</c> literal or a
        /// struct literal. A parameter list (BYN1003), a lambda's, an index and a group do not.
        /// </summary>
        private bool CommaSafe(int o, int c)
        {
            switch (Kind(o))
            {
                case TokenKind.OpenBrace: return IsStructLiteral(o);
                case TokenKind.OpenBracket: return _lineStart[o] || !OperandEnd(Kind(o - 1));
                case TokenKind.OpenParen:
                    var name = o - 1;
                    if (_lineStart[o] || !(Kind(name) == TokenKind.Identifier || Kind(name).IsContextualKeyword()) || !CallLike(name)) return false;
                    if (Kind(c + 1) is TokenKind.OpenBrace or TokenKind.FatArrow or TokenKind.Arrow or TokenKind.RequiresKeyword || IsClause(c + 1))
                        return false;
                    if (InPattern(o)) return false;
                    // A spaced `?` is a ternary's; `T? name(` declares.
                    return _lineStart[name] || ExpressionBefore(Kind(name - 1)) || Kind(name - 1) == TokenKind.Question && Trivia(name - 1);
                default: return false;
            }
        }

        /// <summary>Whether the <c>(</c> at <paramref name="o"/> holds a pattern (<c>case .some(let x)</c>, <c>is .pair(a, b)</c>).</summary>
        private bool InPattern(int o)
        {
            if (Items(o, _match[o]).Any(k => (Kind(k - 1) == TokenKind.OpenParen && k - 1 == o || Kind(k - 1) == TokenKind.Comma)
                                             && Kind(k) is TokenKind.LetKeyword or TokenKind.VarKeyword))
                return true;
            for (var k = o - 1; k >= 0; k--)
            {
                if (IsCloser(Kind(k)) && _match[k] >= 0 && _match[k] < k) k = _match[k];
                else if (IsOpener(Kind(k)) || Kind(k) is TokenKind.Comma or TokenKind.Colon or TokenKind.Equals or TokenKind.FatArrow
                         || Kind(k) == TokenKind.Identifier && Text(k) == "where")
                    return false;
                else if (Kind(k) is TokenKind.CaseKeyword or TokenKind.IsKeyword or TokenKind.ExceptKeyword) return true;
                if (_lineStart[k]) return false;
            }
            return false;
        }

        /// <summary>Whether a name after <paramref name="kind"/> starts an expression, not a declaration (<c>Type name(</c>).</summary>
        private static bool ExpressionBefore(TokenKind kind) => kind switch
        {
            TokenKind.Identifier or TokenKind.Greater or TokenKind.Question or TokenKind.CloseBracket or TokenKind.CloseParen
                or TokenKind.Star => false,
            TokenKind.ReturnKeyword or TokenKind.TryKeyword or TokenKind.AwaitKeyword or TokenKind.InKeyword or TokenKind.IsKeyword
                or TokenKind.AndKeyword or TokenKind.OrKeyword or TokenKind.NotKeyword or TokenKind.IfKeyword or TokenKind.UnlessKeyword
                or TokenKind.WhileKeyword or TokenKind.ElseKeyword or TokenKind.FailKeyword or TokenKind.YieldKeyword
                or TokenKind.DeferKeyword or TokenKind.ErrdeferKeyword or TokenKind.AssertKeyword or TokenKind.CaseKeyword
                or TokenKind.MoveKeyword or TokenKind.RefKeyword or TokenKind.OutKeyword or TokenKind.SwitchKeyword => true,
            var k => !k.IsKeyword(),
        };

        /// <summary>
        /// Pass 3. A <c>( )</c> or <c>[ ]</c> list broken over lines joins when it fits, holds no comment, block or
        /// author's trailing comma (under <c>.multiline</c>). A chain broken only before its links joins when it fits and
        /// has fewer than three lambda calls. Under <c>.never</c> every trailing comma the parser can do without goes first.
        /// </summary>
        private void Joins()
        {
            if (!options.TrailingCommasMultiline)
                for (var c = 1; c < tokens.Length; c++)
                    if (IsCloser(Kind(c)) && _match[c] >= 0 && Kind(c - 1) == TokenKind.Comma && gaps[c - 1].Items.Count == 0
                        && CommaSafe(_match[c], c) && Editable(c - 1, c))
                        _dropComma[c - 1] = true;
            for (var o = 0; o < tokens.Length; o++)
            {
                if (Kind(o) is not (TokenKind.OpenParen or TokenKind.OpenBracket) || _match[o] < o) continue;
                var c = _match[o];
                if (!Joinable(o, c)) continue;
                if (TryJoin(o, c, Enumerable.Range(o + 1, c - o))) o = c;
            }
            foreach (var chain in Chains())
            {
                if (chain.LambdaCalls >= 3 || !chain.Dots.Any(d => _lineStart[d]) || !Editable(chain.Start, chain.End)) continue;
                var only = true;
                for (var k = chain.Start + 1; k <= chain.End && only; k++)
                    if (_lineStart[k] && (!chain.Dots.Contains(k) || gaps[k].Items.Any(x => x.IsComment))) only = false;
                if (only) TryJoin(chain.Start, chain.End, chain.Dots);
            }
        }

        private bool Joinable(int o, int c)
        {
            var broken = false;
            for (var k = o + 1; k <= c; k++)
            {
                broken |= _lineStart[k];
                if (gaps[k].Items.Any(x => x.IsComment) || _frozen[k] || _inHole[k] && _lineStart[k] || Multiline(k)
                    || Kind(k) is TokenKind.OpenBrace or TokenKind.CloseBrace
                    || Kind(k) == TokenKind.Comma && Kind(k + 1) is TokenKind.CloseParen or TokenKind.CloseBracket && !_dropComma[k])
                    return false;
            }
            return broken && !_frozen[o];
        }

        /// <summary>Clears the line breaks before <paramref name="breaks"/> when the line holding tokens <c>[from, to]</c> then fits.</summary>
        private bool TryJoin(int from, int to, IEnumerable<int> breaks)
        {
            var cleared = breaks.Where(k => _lineStart[k]).ToList();
            foreach (var k in cleared) _lineStart[k] = false;
            var s = LineStartOf(from);
            if (Width(s, LineEnd(to)) <= options.Width) return true;
            foreach (var k in cleared) _lineStart[k] = true;
            return false;
        }

        /// <summary>A <c>.</c> or <c>?.</c> and a name: a link of a member chain.</summary>
        private bool IsLink(int j) => Kind(j) is TokenKind.Dot or TokenKind.QuestionDot
            && (Kind(j + 1) == TokenKind.Identifier || Kind(j + 1).IsContextualKeyword());

        /// <summary>Whether the line from link <paramref name="j"/> holds a <c>=&gt;</c> outside brackets: a switch arm, not a link.</summary>
        private bool ArmLine(int j)
        {
            var depth = 0;
            for (var k = j; k < tokens.Length - 1 && (k == j || !_lineStart[k]); k++)
            {
                if (IsOpener(Kind(k))) depth++;
                else if (IsCloser(Kind(k))) depth--;
                else if (depth == 0 && Kind(k) == TokenKind.FatArrow) return true;
            }
            return false;
        }

        /// <summary>The member chains with two or more calls (<c>orders.where(…).take(50)</c>); a nested chain is its own.</summary>
        private List<Chain> Chains()
        {
            var chains = new List<Chain>();
            var used = new bool[tokens.Length];
            for (var i = 1; i < tokens.Length; i++)
            {
                if (used[i] || !IsLink(i) || _lineStart[i] && (gaps[i].HasBlank || ArmLine(i))) continue;
                var before = Kind(i - 1);
                if (!(before is TokenKind.Identifier or TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.ThisKeyword
                        or TokenKind.InterpolatedStringEnd || before.IsStringLiteral() || before.IsContextualKeyword()))
                    continue;
                var start = i - 1;
                if (IsCloser(Kind(start)) && _match[start] >= 0)
                {
                    start = _match[start];
                    if (Kind(start) != TokenKind.InterpolationStart && !_lineStart[start]
                        && (Kind(start - 1) == TokenKind.Identifier || Kind(start - 1).IsContextualKeyword()))
                        start--;
                }
                var dots = new List<int>();
                var breakable = new List<int>();
                int calls = 0, lambdas = 0, end = i, j = i;
                while (IsLink(j) && (j == i || !_lineStart[j] || !gaps[j].HasBlank && !ArmLine(j)))
                {
                    used[j] = true;
                    dots.Add(j);
                    var k = j + 2;
                    var call = false;
                    while (Kind(k) is TokenKind.OpenParen or TokenKind.OpenBracket && !_lineStart[k] && _match[k] > k)
                    {
                        if (Kind(k) == TokenKind.OpenParen && k == j + 2)
                        {
                            call = true;
                            if (HasLambda(k, _match[k])) lambdas++;
                        }
                        k = _match[k] + 1;
                    }
                    if (call) calls++;
                    if (call || breakable.Count > 0) breakable.Add(j);
                    end = k - 1;
                    j = k;
                }
                if (calls >= 2) chains.Add(new Chain(start, end, dots, breakable, lambdas));
            }
            return chains;
        }

        /// <summary>Whether the arguments <c>(o, c)</c> hold a lambda: a <c>=&gt;</c> or an implicit <c>it</c>.</summary>
        private bool HasLambda(int o, int c)
        {
            for (var k = o + 1; k < c; k++)
                if (Kind(k) == TokenKind.FatArrow || Kind(k) == TokenKind.Identifier && Text(k) == "it") return true;
            return false;
        }

        /// <summary>
        /// Pass 4. A chain with three or more lambda calls, or with one link already broken, breaks every link. A list
        /// broken over lines, or ending in the author's trailing comma, takes one item per line. Then each line past
        /// <c>width</c> breaks its condition, its header clauses, or its outermost chain or list, until every line fits or
        /// nothing is left to break.
        /// </summary>
        private void Breaks()
        {
            foreach (var chain in Chains())
                if ((chain.LambdaCalls >= 3 || chain.Breakable.Any(d => _lineStart[d])) && Editable(chain.Start, chain.End))
                    foreach (var d in chain.Breakable) _lineStart[d] = true;
            for (var o = 0; o < tokens.Length; o++)
            {
                if (Kind(o) is not (TokenKind.OpenParen or TokenKind.OpenBracket) || _match[o] < o) continue;
                var c = _match[o];
                if (!Editable(o, c) || !Items(o, c).Any(k => Kind(k) == TokenKind.Comma)) continue;
                if (_lineStart[c] || TrailingComma(c) || Items(o, c).Any(k => _lineStart[k])) BreakList(o, c);
            }
            for (var round = 0; round < tokens.Length; round++)
            {
                Levels();
                var chains = Chains();
                var changed = false;
                for (int s = 0, e; s < tokens.Length - 1; s = e)
                {
                    e = LineEnd(s);
                    if (!_frozen[s] && !_inHole[s] && Width(s, e) > options.Width && BreakLine(s, e, chains)) changed = true;
                }
                if (!changed) break;
            }
        }

        /// <summary>One item per line: a break after the opener and after each item, and the trailing comma the knob asks for.</summary>
        private void BreakList(int o, int c)
        {
            if (o + 1 < c) _lineStart[o + 1] = true;
            foreach (var k in Items(o, c))
                if (Kind(k) == TokenKind.Comma && k + 1 < c) _lineStart[k + 1] = true;
            _lineStart[c] = true;
            if (options.TrailingCommasMultiline && Kind(c - 1) != TokenKind.Comma && o + 1 < c && CommaSafe(o, c))
                _addComma[c - 1] = true;
        }

        /// <summary>Breaks the over-wide line <c>[s, e)</c> at its widest structure; false when it has none.</summary>
        private bool BreakLine(int s, int e, List<Chain> chains)
        {
            var changed = false;
            // A one-line body opens: `{` ends the line and `}` starts one.
            var p = Kind(s) == TokenKind.CloseBrace && Kind(s + 1) == TokenKind.ElseKeyword ? s + 1 : s;
            if (Kind(p) is TokenKind.IfKeyword or TokenKind.WhileKeyword or TokenKind.UnlessKeyword or TokenKind.ForKeyword
                or TokenKind.ElseKeyword)
            {
                for (int k = p + 1, depth = 0; k < e; k++)
                {
                    if (IsCloser(Kind(k))) depth--;
                    if (depth == 0 && Kind(k) == TokenKind.OpenBrace)
                    {
                        var c = _match[k];
                        if (c > k + 1 && c < e && Editable(k + 1, c))
                        {
                            _lineStart[k + 1] = _lineStart[c] = true;
                            return true;
                        }
                        break;
                    }
                    if (IsOpener(Kind(k))) depth++;
                }
            }
            // A wrapped condition breaks before each `&&`, `||`, `and` and `or` outside brackets, as does its continuation line.
            if (Kind(p) == TokenKind.ElseKeyword) p++;
            if (p < e && Kind(p) is TokenKind.IfKeyword or TokenKind.WhileKeyword or TokenKind.UnlessKeyword
                or TokenKind.AmpAmp or TokenKind.BarBar or TokenKind.AndKeyword or TokenKind.OrKeyword)
            {
                var depth = 0;
                for (var k = p + 1; k < e; k++)
                {
                    if (IsCloser(Kind(k))) depth--;
                    if (depth == 0 && Kind(k) == TokenKind.OpenBrace) break;
                    if (depth == 0 && Kind(k) is TokenKind.AmpAmp or TokenKind.BarBar or TokenKind.AndKeyword or TokenKind.OrKeyword
                        && !_lineStart[k] && Editable(k, k)
                        // `if (a) ⏎ && b` would read `(a)` as the whole condition (BYN1017).
                        && !(Kind(k - 1) == TokenKind.CloseParen && _match[k - 1] == p + 1))
                        changed = _lineStart[k] = true;
                    if (IsOpener(Kind(k))) depth++;
                }
                if (changed) return true;
            }
            // Header clauses after the `)` go one per line when the head before them fits.
            {
                var depth = 0;
                var closed = false;
                var first = -1;
                for (var k = s; k < e; k++)
                {
                    if (IsCloser(Kind(k))) depth--;
                    if (depth == 0 && Kind(k) == TokenKind.CloseParen) closed = true;
                    else if (depth == 0 && closed && k > s && IsClause(k))
                    {
                        if (first < 0)
                        {
                            if (Width(s, k) > options.Width) break;
                            first = k;
                        }
                        if (!_lineStart[k] && Editable(k, k)) changed = _lineStart[k] = true;
                    }
                    if (IsOpener(Kind(k))) depth++;
                }
                if (changed) return true;
            }
            // Otherwise the outermost chain or list on the line: a chain before a list at the same depth, then the leftmost.
            var depths = new int[e - s];
            for (int k = s, d = 0; k < e; k++)
            {
                if (IsCloser(Kind(k))) d--;
                depths[k - s] = d;
                if (IsOpener(Kind(k))) d++;
            }
            Chain? bestChain = null;
            var best = int.MaxValue;
            foreach (var chain in chains)
            {
                var b = chain.Breakable;
                if (b.Count == 0 || b[0] < s || b[^1] >= e || b.Any(d => _lineStart[d]) || !Editable(chain.Start, chain.End)) continue;
                if (depths[b[0] - s] < best)
                {
                    best = depths[b[0] - s];
                    bestChain = chain;
                }
            }
            var bestList = -1;
            for (var o = s; o < e; o++)
            {
                if (!(Kind(o) is TokenKind.OpenParen or TokenKind.OpenBracket || IsStructLiteral(o))) continue;
                var c = _match[o];
                if (c <= o + 1 || c >= e || depths[o - s] >= best || !Editable(o, c) || Kind(o) == TokenKind.OpenParen && InPattern(o))
                    continue;
                best = depths[o - s];
                bestList = o;
                bestChain = null;
            }
            if (bestChain is not null)
            {
                foreach (var d in bestChain.Breakable) _lineStart[d] = true;
                return true;
            }
            if (bestList < 0) return false;
            BreakList(bestList, _match[bestList]);
            return true;
        }

        // ── Blank lines between top-level declarations (pass 7, proposal §3.7) ───────────

        private void TopLevelBlanks()
        {
            var members = tree.Root.Members;
            for (var d = 1; d < members.Length; d++)
            {
                var (a, b) = (members[d - 1], members[d]);
                if (a is GlobalStatement || b is GlobalStatement) continue;
                var next = TokenAt(a.Span.End);
                if (next >= tokens.Length - 1 || !gaps[next].HasNewline) continue;
                var nextEnd = d + 1 < members.Length ? TokenAt(members[d + 1].Span.Start) : tokens.Length - 1;
                if (OneLine(TokenAt(a.Span.Start), next) && OneLine(next, Math.Max(next + 1, Math.Min(nextEnd, TokenAt(b.Span.End))))
                    && a.GetType() == b.GetType() && LeadingKeywords(TokenAt(a.Span.Start)) == LeadingKeywords(next))
                    continue;
                _needsBlank[next] = true;
            }
        }

        /// <summary>Whether tokens <c>[from, to)</c> lie on one line.</summary>
        private bool OneLine(int from, int to)
        {
            for (var i = from + 1; i < to; i++)
                if (_lineStart[i]) return false;
            return true;
        }

        private string LeadingKeywords(int i)
        {
            var words = new List<string>();
            for (; i < tokens.Length && Kind(i).IsKeyword(); i++) words.Add(Text(i));
            return string.Join(" ", words);
        }

        // ── The guide's attributes, blocks, generics and member groups (docs/bayan-style.md, proposal §3.2) ──

        /// <summary>The declarations of <paramref name="decls"/> and of the type bodies among them.</summary>
        private static IEnumerable<Decl> Decls(Decl[] decls)
        {
            foreach (var decl in decls)
            {
                yield return decl;
                var members = decl switch
                {
                    StructDecl s => s.Members,
                    InterfaceDecl n => n.Members,
                    ExtensionDecl x => x.Members,
                    _ => [],
                };
                foreach (var member in Decls(members)) yield return member;
            }
        }

        /// <summary>The statement blocks of a declaration: its body's, and those nested in its statements, not in expressions.</summary>
        private static IEnumerable<BlockStmt> Blocks(Decl decl) => decl switch
        {
            FunctionDecl f => Blocks(f.Body),
            ConstructorDecl c => Blocks(c.Body),
            TestDecl t => Blocks(t.Body),
            PropertyDecl p => Blocks(p.Block),
            GlobalStatement g => Blocks(g.Statement),
            _ => [],
        };

        private static IEnumerable<BlockStmt> Blocks(Stmt? stmt) => stmt switch
        {
            BlockStmt b => [b, .. b.Statements.SelectMany(Blocks)],
            IfStmt s => [.. Blocks(s.Then), .. Blocks(s.Else)],
            UnlessStmt s => Blocks(s.Body),
            GuardedStmt s => Blocks(s.Statement),
            WhileStmt s => Blocks(s.Body),
            DoWhileStmt s => Blocks(s.Body),
            WhileLetStmt s => Blocks(s.Body),
            ForStmt s => Blocks(s.Body),
            LabeledStmt s => Blocks(s.Statement),
            SwitchStmt s => s.Sections.SelectMany(x => x.Statements).SelectMany(Blocks),
            DeferStmt s => Blocks(s.Body),
            ContextStmt s => Blocks(s.Body),
            _ => [],
        };

        /// <summary>
        /// An attribute before a type or function goes on its own line above it; one before a field or parameter stays
        /// inline. A statement block written on one line takes one statement per line, <c>{</c> ending the line and
        /// <c>}</c> starting one; a <c>=&gt;</c> body and a block inside an expression (a lambda's) stay as written. The
        /// <c>&lt;</c> and <c>&gt;</c> of a generic list take no space inside.
        /// </summary>
        private void Guide()
        {
            foreach (var decl in Decls(tree.Root.Members))
            {
                if (decl.Attributes is [var first, ..] attributes && OwnLineAttributes(decl))
                {
                    var head = TokenAt(Math.Max(attributes[^1].Span.End, attributes[^1].Because?.Span.End ?? 0));
                    if (Editable(TokenAt(first.Span.Start), head))
                    {
                        foreach (var a in attributes.Skip(1)) _lineStart[TokenAt(a.Span.Start)] = true;
                        _lineStart[head] = true;
                    }
                }
                foreach (var block in Blocks(decl))
                {
                    var o = TokenAt(block.Span.Start);
                    if (block.Statements.Length == 0 || Kind(o) != TokenKind.OpenBrace || _match[o] < o || !Editable(o, _match[o])) continue;
                    foreach (var s in block.Statements) _lineStart[TokenAt(s.Span.Start)] = true;
                    _lineStart[_match[o]] = true;
                }
            }
            for (var o = 1; o < tokens.Length; o++)
                if (GenericClose(o) is var close and > 0)
                {
                    _tightAfter[o] = true;
                    _tightBefore[close] = true;
                }
        }

        /// <summary>A type or a function: the declarations whose attributes go on their own lines.</summary>
        private static bool OwnLineAttributes(Decl decl) => decl is StructDecl or InterfaceDecl or ExtensionDecl or EnumDecl
            or UnionDecl or ErrorEnumDecl or ErrorSetDecl or TypeAliasDecl or FunctionDecl or ConstructorDecl or TestDecl;

        /// <summary>
        /// The <c>&gt;</c> closing a generic list opened by the <c>&lt;</c> at <paramref name="o"/>, or −1: a <c>&lt;</c>
        /// right after a name, then on one line only tokens a type is made of, up to its <c>&gt;</c>. The parser reads no
        /// gap inside one but a <c>&gt;</c> after a <c>&gt;</c>, which <see cref="TriviaMatters"/> keeps.
        /// </summary>
        private int GenericClose(int o)
        {
            if (Kind(o) != TokenKind.Less || Trivia(o) || !(Kind(o - 1) == TokenKind.Identifier || Kind(o - 1).IsContextualKeyword())) return -1;
            for (int k = o + 1, depth = 1; k < tokens.Length && !_lineStart[k]; k++)
            {
                switch (Kind(k))
                {
                    case TokenKind.Less:
                        depth++;
                        break;
                    case TokenKind.Greater:
                        if (--depth == 0) return k;
                        break;
                    case TokenKind.Identifier or TokenKind.Comma or TokenKind.Dot or TokenKind.Question or TokenKind.Star
                        or TokenKind.OpenBracket or TokenKind.CloseBracket or TokenKind.OpenParen or TokenKind.CloseParen
                        or TokenKind.IntegerLiteral or TokenKind.Arrow:
                        break;
                    default:
                        if (!Kind(k).IsContextualKeyword()) return -1;
                        break;
                }
            }
            return -1;
        }

        /// <summary>
        /// Inside a type body, one blank line between member groups (fields, <c>states</c>, properties, static members,
        /// methods) and between two methods. A function body's statements are not members, so none goes there.
        /// </summary>
        private void MemberBlanks()
        {
            foreach (var decl in Decls(tree.Root.Members))
            {
                var (members, states) = decl switch
                {
                    StructDecl s => (s.Members, s.States),
                    InterfaceDecl n => (n.Members, []),
                    ExtensionDecl x => (x.Members, []),
                    _ => ((Decl[])[], (UnionVariant[])[]),
                };
                var items = members.Select(m => (Start: MemberStart(m), Group: Group(m), Method: m is FunctionDecl or ConstructorDecl)).ToList();
                if (states is [var state, ..] && StatesStart(TokenAt(state.Span.Start)) is var at and >= 0)
                    items.Add((at, "states", false));
                items.Sort((a, b) => a.Start.CompareTo(b.Start));
                for (var k = 1; k < items.Count; k++)
                {
                    var (prev, next) = (items[k - 1], items[k]);
                    if (prev.Group == next.Group && !(prev.Method && next.Method)) continue;
                    if (gaps[next.Start].HasNewline && Editable(next.Start, next.Start)) _needsBlank[next.Start] = true;
                }
            }
        }

        private int MemberStart(Decl decl) => TokenAt(decl.Attributes is [var a, ..] ? Math.Min(a.Span.Start, decl.Span.Start) : decl.Span.Start);

        /// <summary>The <c>states</c> word of the <c>states { … }</c> block holding the state at <paramref name="first"/>, or −1.</summary>
        private int StatesStart(int first)
        {
            var o = first - 1;
            return Kind(o) == TokenKind.OpenBrace && o > 0 && Text(o - 1) == "states" ? o - 1 : -1;
        }

        private static string Group(Decl decl) => decl switch
        {
            FieldDecl { Modifiers: var m } when m.HasFlag(Modifiers.Static) => "static",
            PropertyDecl { Modifiers: var m } when m.HasFlag(Modifiers.Static) => "static",
            FunctionDecl { Modifiers: var m } when m.HasFlag(Modifiers.Static) => "static",
            FieldDecl => "field",
            PropertyDecl or GetterDecl => "property",
            FunctionDecl or ConstructorDecl => "method",
            _ => decl.GetType().Name,
        };

        // ── Alignment runs (pass 8, proposal §3.2, §3.3, §3.7) ───────────────────────────

        /// <summary>
        /// Pass 8. Consecutive lines of one shape at one level, with no blank or comment line between them, form a run, and
        /// the run pads the gap before each of its columns so that they start at one column: the name of a field, the name
        /// and <c>=&gt;</c> of a property, the <c>=&gt;</c> of a one-line switch arm and the <c>=</c> of a one-line top-level
        /// declaration. Then consecutive lines at one level that end in a comment align the comments. A column whose padding
        /// would push a line of its run past <c>width</c> stays unaligned in that run, and a line whose column sits after a
        /// gap the parser reads (<see cref="TriviaMatters"/>) ends the run.
        /// </summary>
        private void Align()
        {
            var shapes = new Dictionary<int, (string Key, int[] Columns)>();
            Shapes(tree.Root.Members, topLevel: true, shapes);
            Arms(shapes);
            var lines = new List<int>();
            for (var i = 0; i < tokens.Length - 1; i++)
                if (_lineStart[i]) lines.Add(i);
            var run = new List<int>();
            foreach (var s in lines)
            {
                var ok = shapes.TryGetValue(s, out var shape) && Plain(s) && shape.Columns.All(k => Padded(s, k));
                if (run.Count > 0 && (!ok || shape.Key != shapes[run[0]].Key || _level[s] != _level[run[0]] || Separated(s)))
                {
                    AlignRun(run, shapes);
                    run.Clear();
                }
                if (ok) run.Add(s);
            }
            AlignRun(run, shapes);
            run.Clear();
            foreach (var s in lines)
            {
                var e = LineEnd(s);
                var ok = gaps[e].Items is [{ IsComment: true }, ..] && Plain(s);
                if (run.Count > 0 && (!ok || _level[s] != _level[run[0]] || Separated(s)))
                {
                    AlignComments(run);
                    run.Clear();
                }
                if (ok) run.Add(s);
            }
            AlignComments(run);
        }

        /// <summary>The fields, properties and one-line top-level declarations that start a line, by their line.</summary>
        private void Shapes(Decl[] decls, bool topLevel, Dictionary<int, (string Key, int[] Columns)> shapes)
        {
            foreach (var decl in decls)
            {
                var start = TokenAt(decl.Span.Start);
                var s = LineStartOf(start);
                var e = LineEnd(s);
                if ((s == start || Kind(s) == TokenKind.At) && TokenAt(decl.Span.End) == e)
                {
                    var name = decl switch { FieldDecl f => TokenAt(f.Name.Span.Start), PropertyDecl p => TokenAt(p.Name.Span.Start), _ => -1 };
                    if (topLevel && decl is not GlobalStatement && First(TokenKind.Equals, start, e) is var eq and > 0)
                        shapes[s] = (decl.GetType().Name + " " + LeadingKeywords(start), [eq]);
                    else if (!topLevel && decl is FieldDecl)
                        shapes[s] = ("field", [name]);
                    else if (!topLevel && decl is PropertyDecl { Body: not null } && First(TokenKind.FatArrow, name, e) is var arrow and > 0)
                        shapes[s] = ("property", [name, arrow]);
                }
                var members = decl switch
                {
                    StructDecl d => d.Members,
                    InterfaceDecl n => n.Members,
                    ExtensionDecl x => x.Members,
                    _ => [],
                };
                Shapes(members, topLevel: false, shapes);
            }
        }

        /// <summary>The one-line arms of each <c>switch { … }</c>: an arm that starts a line and ends it with its <c>,</c> or the <c>}</c>.</summary>
        private void Arms(Dictionary<int, (string Key, int[] Columns)> shapes)
        {
            for (var o = 1; o < tokens.Length; o++)
            {
                if (Kind(o) != TokenKind.OpenBrace || Kind(o - 1) != TokenKind.SwitchKeyword || _match[o] < o) continue;
                var c = _match[o];
                foreach (var k in Items(o, c))
                {
                    if (!_lineStart[k] || !(k == o + 1 || Kind(k - 1) == TokenKind.Comma)) continue;
                    var e = LineEnd(k);
                    if (e > c || !(e == c || Kind(e - 1) == TokenKind.Comma)) continue;
                    if (Enumerable.Range(k, e - k).Any(m => IsOpener(Kind(m)) && _match[m] >= e)) continue;
                    if (First(TokenKind.FatArrow, k, e) is var arrow and > 0) shapes[k] = ("arm", [arrow]);
                }
            }
        }

        /// <summary>The first <paramref name="kind"/> in tokens <c>[from, e)</c> outside brackets, or −1.</summary>
        private int First(TokenKind kind, int from, int e)
        {
            for (var k = from; k < e; k++)
            {
                if (Kind(k) == kind) return k;
                if (IsOpener(Kind(k)) && _match[k] > k) k = _match[k];
            }
            return -1;
        }

        /// <summary>Whether the line from <paramref name="s"/> is one line, with no frozen token and not in a hole.</summary>
        private bool Plain(int s)
        {
            var e = LineEnd(s);
            if (_inHole[s] || _inHole[e] || Width(s, e) == 0) return false;
            for (var k = s; k <= e; k++)
                if (_frozen[k]) return false;
            return true;
        }

        /// <summary>Whether column token <paramref name="k"/> follows a space on the line of <paramref name="s"/> that padding may widen.</summary>
        private bool Padded(int s, int k) =>
            k > s && k < LineEnd(s) && Space(k, tokens[k - 1].End) && !TriviaMatters(source, tokens, k);

        /// <summary>Whether a blank line, an inserted one or a comment line comes before line start <paramref name="s"/>.</summary>
        private bool Separated(int s) => gaps[s].HasBlank || _needsBlank[s] || gaps[s].Items.Skip(1).Any(x => x.IsComment);

        /// <summary>The padding the run has already put in tokens <c>(s, e)</c>.</summary>
        private int Pads(int s, int e)
        {
            var n = 0;
            for (var k = s + 1; k < e; k++) n += _pad[k];
            return n;
        }

        /// <summary>The columns of the line from <paramref name="s"/> with its padding, before any trailing comment.</summary>
        private int LineWidth(int s) => Width(s, LineEnd(s)) + Pads(s, LineEnd(s));

        private void AlignRun(List<int> run, Dictionary<int, (string Key, int[] Columns)> shapes)
        {
            if (run.Count < 2) return;
            for (var c = 0; c < shapes[run[0]].Columns.Length; c++)
            {
                var at = run.Select(s => Width(s, shapes[s].Columns[c]) + Pads(s, shapes[s].Columns[c]) + 1).ToArray();
                var target = at.Max();
                if (run.Where((s, n) => at[n] < target && LineWidth(s) + target - at[n] > options.Width).Any()) continue;
                for (var n = 0; n < run.Count; n++) _pad[shapes[run[n]].Columns[c]] = target - at[n];
            }
        }

        private void AlignComments(List<int> run)
        {
            if (run.Count < 2) return;
            var at = run.Select(s => LineWidth(s) + 1).ToArray();
            var target = at.Max();
            for (var n = 0; n < run.Count; n++)
            {
                var text = CommentText(source, gaps[LineEnd(run[n])].Items[0]);
                if (at[n] < target && target + text.Count(b => (b & 0xC0) != 0x80) > options.Width) return;
            }
            for (var n = 0; n < run.Count; n++) _commentPad[LineEnd(run[n])] = target - at[n];
        }

        // ── Writing a gap: blank lines (pass 7), comments, indentation (pass 5), spacing (pass 6) ──

        private void EmitGap(int i)
        {
            var gap = gaps[i];
            var from = i == 0 ? bom : tokens[i - 1].End;
            if (_frozen[i])
            {
                _out.AddRange(source.AsSpan(from, tokens[i].Start - from));
                return;
            }
            if (_inHole[i] && gap.HasNewline)
            {
                Hygiene(from, tokens[i].Start);
                return;
            }
            var eof = Kind(i) == TokenKind.EndOfFile;
            var items = gap.Items;
            var at = 0;
            if (i > 0 && items.Count > 0 && items[0].IsComment)
            {
                Spaces(1 + _commentPad[i]);
                Add(items[0]);
                at = 1;
            }
            // A joined gap holds no comment (Joinable); a broken one held no newline.
            if (i > 0 && !_lineStart[i])
            {
                if (eof)
                {
                    _out.Add((byte)'\n');
                    return;
                }
                if (at == 0 && Space(i, from)) Spaces(1 + _pad[i]);
                return;
            }
            if (i > 0)
            {
                _out.Add((byte)'\n');
                at++;
            }
            // Each line between the token's line and the one before: a comment, or null for a blank line.
            var lines = new List<GapItem?>();
            GapItem? comment = null;
            for (; at < items.Count; at++)
            {
                if (items[at].IsComment) comment = items[at];
                else
                {
                    if (comment is not null || lines.Count == 0 || lines[^1] is not null) lines.Add(comment);
                    comment = null;
                }
            }
            if (comment is not null) lines.Add(comment);
            if (i == 0 || Kind(i - 1) == TokenKind.OpenBrace)
                while (lines.Count > 0 && lines[0] is null) lines.RemoveAt(0);
            if (eof || Kind(i) == TokenKind.CloseBrace)
                while (lines.Count > 0 && lines[^1] is null) lines.RemoveAt(lines.Count - 1);
            if (_needsBlank[i] && !lines.Contains(null)) lines.Insert(0, null);
            var commentLevel = eof ? 0 : Kind(i) is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace ? _level[i] + 1 : _level[i];
            foreach (var line in lines)
            {
                if (line is { } c)
                {
                    Indent(commentLevel);
                    Add(c);
                }
                _out.Add((byte)'\n');
            }
            if (!eof) Indent(_level[i]);
        }

        private void Add(GapItem item) => _out.AddRange(CommentText(source, item));

        private void Indent(int level) => Spaces(level * options.Indent);

        private void Spaces(int n)
        {
            for (; n > 0; n--) _out.Add((byte)' ');
        }

        /// <summary>The bytes as written, less the blanks and carriage returns before each newline (pass 1).</summary>
        private void Hygiene(int from, int to)
        {
            var blanks = from;
            for (var at = from; at < to; at++)
            {
                var b = source[at];
                if (b is (byte)' ' or (byte)'\t' or (byte)'\r') continue;
                if (b != '\n') _out.AddRange(source.AsSpan(blanks, at - blanks));
                _out.Add(b);
                blanks = at + 1;
            }
            _out.AddRange(source.AsSpan(blanks, to - blanks));
        }

        // ── Horizontal spacing (pass 6, proposal §3.8) ────────────────────────────────────

        /// <summary>Whether one space goes between tokens <paramref name="i"/> − 1 and <paramref name="i"/> on one line.</summary>
        private bool Space(int i, int from)
        {
            var written = tokens[i].Start > from;
            // The parser reads the gap here (`>>`, `T...`, `u8*`, `30s`, `unlikely (a)`): keep it as written.
            if (TriviaMatters(source, tokens, i)) return written;
            // Generics are tight inside (`List<Sku>`).
            if (_tightAfter[i - 1] || _tightBefore[i]) return written && Merges(i);
            var after = After(i - 1);
            var ahead = Before(i);
            bool space;
            if (after == Side.None || ahead == Side.None) space = false;
            else if (after == Side.Keep || ahead == Side.Keep) space = written;
            else if (after == Side.Space || ahead == Side.Space) space = true;
            else space = written;
            return space || written && Merges(i);
        }

        /// <summary>Whether tokens <paramref name="i"/> − 1 and <paramref name="i"/> written together lex as something else (<c>- -x</c>).</summary>
        private bool Merges(int i)
        {
            // A string piece lexes as itself only inside its string; it never merges with a neighbour.
            if (Piece(Kind(i - 1)) || Piece(Kind(i))) return false;
            byte[] joined = [.. source.AsSpan(tokens[i - 1].Start, tokens[i - 1].Length), .. source.AsSpan(tokens[i].Start, tokens[i].Length)];
            var lexed = Lexer.Lex(new SourceText("layout", joined)).Tokens;
            return lexed.Length != 3 || lexed[0].Kind != tokens[i - 1].Kind || lexed[1].Kind != tokens[i].Kind;
        }

        private static bool Piece(TokenKind kind) => kind is TokenKind.InterpolatedStringStart or TokenKind.InterpolatedStringText
            or TokenKind.InterpolationStart or TokenKind.InterpolationEnd or TokenKind.InterpolatedStringEnd;

        private static bool OperandEnd(TokenKind kind) => kind is TokenKind.Identifier or TokenKind.IntegerLiteral
            or TokenKind.FloatLiteral or TokenKind.NumericSuffix or TokenKind.CharLiteral or TokenKind.InterpolatedStringEnd
            or TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.ThisKeyword or TokenKind.NullKeyword
            or TokenKind.TrueKeyword or TokenKind.FalseKeyword
            || kind.IsStringLiteral() || kind.IsContextualKeyword();

        private static bool IsBinary(TokenKind kind) => kind is TokenKind.FatArrow or TokenKind.Arrow or TokenKind.Equals
            or TokenKind.EqualsEquals or TokenKind.BangEquals or TokenKind.LessEquals or TokenKind.GreaterEquals
            or TokenKind.QuestionQuestion or TokenKind.QuestionQuestionEquals or TokenKind.AmpAmp or TokenKind.BarBar
            or TokenKind.Slash or TokenKind.Percent or TokenKind.PlusPercent or TokenKind.MinusPercent or TokenKind.StarPercent
            or TokenKind.PlusBar or TokenKind.MinusBar or TokenKind.StarBar or TokenKind.Bar or TokenKind.Caret
            or TokenKind.LessLess or TokenKind.PlusEquals or TokenKind.MinusEquals or TokenKind.StarEquals
            or TokenKind.SlashEquals or TokenKind.PercentEquals or TokenKind.AmpEquals or TokenKind.BarEquals
            or TokenKind.CaretEquals or TokenKind.LessLessEquals;

        /// <summary>Whether the <c>-</c>, <c>+</c>, <c>&amp;</c>, <c>!</c> or <c>*</c> at <paramref name="i"/> is a prefix operator.</summary>
        private bool IsUnary(int i) => _lineStart[i] || !OperandEnd(Kind(i - 1));

        /// <summary>A <c>*</c>: prefix, binary (spaced before), or as written (<c>u8*</c>, <c>u8**</c>, <c>a*b</c>).</summary>
        private Side Star(int i, Side prefix)
        {
            if (_lineStart[i]) return prefix;
            if (Kind(i - 1) == TokenKind.Star && !Trivia(i)) return Side.Keep;
            if (!OperandEnd(Kind(i - 1))) return prefix;
            return Trivia(i) ? Side.Space : Side.Keep;
        }

        /// <summary>What token <paramref name="i"/> asks of the space after it.</summary>
        private Side After(int i) => Kind(i) switch
        {
            TokenKind.InterpolatedStringStart or TokenKind.InterpolatedStringText or TokenKind.InterpolationStart
                or TokenKind.InterpolationEnd => Side.None,
            TokenKind.OpenParen or TokenKind.OpenBracket or TokenKind.Dot or TokenKind.QuestionDot or TokenKind.At
                or TokenKind.Tilde or TokenKind.DotDot or TokenKind.DotDotEquals => Side.None,
            TokenKind.Comma or TokenKind.Colon => Side.Space,
            TokenKind.OpenBrace => Kind(i + 1) == TokenKind.CloseBrace ? Side.Keep : Side.Space,
            var k when IsBinary(k) => Side.Space,
            TokenKind.Minus or TokenKind.Plus or TokenKind.Amp => IsUnary(i) ? Side.None : Side.Space,
            TokenKind.Bang => IsUnary(i) ? Side.None : Side.Keep,
            TokenKind.Star => Star(i, Side.None),
            TokenKind.Less => Kind(i - 1) == TokenKind.DotDot ? Side.None : Trivia(i) ? Side.Space : Side.Keep,
            TokenKind.Greater or TokenKind.Question => Trivia(i) ? Side.Space : Side.Keep,
            TokenKind.PlusPlus or TokenKind.MinusMinus or TokenKind.Hash or TokenKind.Semicolon => Side.Keep,
            _ => Side.Defer,
        };

        /// <summary>What token <paramref name="i"/> asks of the space before it.</summary>
        private Side Before(int i) => Kind(i) switch
        {
            TokenKind.InterpolatedStringText or TokenKind.InterpolationStart or TokenKind.InterpolationEnd
                or TokenKind.InterpolatedStringEnd => Side.None,
            TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.Comma => Side.None,
            TokenKind.Semicolon or TokenKind.NumericSuffix or TokenKind.PlusPlus or TokenKind.MinusMinus or TokenKind.Hash => Side.Keep,
            TokenKind.CloseBrace => Kind(i - 1) == TokenKind.OpenBrace ? Side.Keep : Side.Space,
            TokenKind.OpenBrace => Side.Space,
            TokenKind.Colon => SpacedColon(i) ? Side.Space : Side.None,
            TokenKind.Dot or TokenKind.QuestionDot => Kind(i - 1) is TokenKind.Identifier or TokenKind.CloseParen
                or TokenKind.CloseBracket or TokenKind.ThisKeyword or TokenKind.InterpolatedStringEnd
                || Kind(i - 1).IsStringLiteral() || Kind(i - 1).IsContextualKeyword() ? Side.None : Side.Defer,
            TokenKind.OpenParen or TokenKind.OpenBracket => CallLike(i - 1) ? Side.None : Side.Defer,
            TokenKind.DotDot or TokenKind.DotDotEquals => OperandEnd(Kind(i - 1)) ? Side.None : Side.Defer,
            var k when IsBinary(k) => Side.Space,
            TokenKind.Minus or TokenKind.Plus or TokenKind.Amp => IsUnary(i) ? Side.Defer : Side.Space,
            TokenKind.Bang => IsUnary(i) ? Side.Defer : Side.Keep,
            TokenKind.Star => Star(i, Side.Defer),
            TokenKind.Less => Kind(i - 1) == TokenKind.DotDot ? Side.None : Trivia(i) ? Side.Space : Side.Keep,
            TokenKind.Greater or TokenKind.Question => Trivia(i) ? Side.Space : Side.Keep,
            _ => Side.Defer,
        };

        /// <summary>Whether a <c>(</c> or <c>[</c> after token <paramref name="i"/> is a call or an index: no space before it.</summary>
        private bool CallLike(int i) => Kind(i) is TokenKind.CloseParen or TokenKind.CloseBracket || Kind(i).IsContextualKeyword()
            || Kind(i) == TokenKind.Identifier && Text(i) is not ("where" or "expects" or "becomes");

        /// <summary>Whether the <c>:</c> at <paramref name="i"/> is a ternary's or a conformance's (<c>struct S : I</c>, <c>where T : I</c>).</summary>
        private bool SpacedColon(int i)
        {
            var depth = 0;
            for (var k = i - 1; k >= 0; k--)
            {
                var kind = Kind(k);
                if (kind is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace or TokenKind.InterpolationEnd) depth++;
                else if (kind is TokenKind.OpenParen or TokenKind.OpenBracket or TokenKind.OpenBrace or TokenKind.InterpolationStart)
                {
                    if (depth == 0) return false;
                    depth--;
                }
                else if (depth == 0 && (kind is TokenKind.StructKeyword or TokenKind.InterfaceKeyword or TokenKind.ExtensionKeyword
                             || kind == TokenKind.Question && Trivia(k) || kind == TokenKind.Identifier && Text(k) == "where"))
                    return true;
                if (_lineStart[k] && depth == 0) return false;
            }
            return false;
        }
    }
}
