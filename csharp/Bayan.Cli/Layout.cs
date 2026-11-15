using Bayan.Syntax.Ast;
using Bayan.Syntax.Lexing;
using Bayan.Syntax.Parsing;
using Bayan.Syntax.Text;

namespace Bayan.Cli;

/// <summary>The project's layout knobs (<c>style</c> in <c>package.byn</c>).</summary>
internal sealed record LayoutOptions(int Indent = 4, int Width = 120, bool AlignRuns = true, bool TrailingCommasMultiline = true);

/// <summary>
/// The layout pass of <c>bayan format</c> (docs/bayan-style-proposal.md §3): it rewrites only the whitespace between
/// tokens, line by line, and never moves a token to another line. Comments are the source bytes between token spans.
/// The output is kept only when it lexes to the same tokens, keeps the same comments and parses with the same
/// diagnostics; otherwise the input comes back with the reason.
/// </summary>
internal static class Layout
{
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
        if (after.Length != tokens.Length) return "the tokens changed";
        for (var i = 0; i < tokens.Length; i++)
            if (after[i].Kind != tokens[i].Kind
                || !source.AsSpan(tokens[i].Start, tokens[i].Length).SequenceEqual(output.AsSpan(after[i].Start, after[i].Length)))
                return "the tokens changed";
        var bom = output.Length >= 3 && output[0] == 0xEF && output[1] == 0xBB && output[2] == 0xBF ? 3 : 0;
        var afterGaps = Gaps(output, after, bom);
        if (afterGaps is null || !Comments(source, gaps).SequenceEqual(Comments(output, afterGaps))) return "the comments changed";
        var reparsed = SyntaxTree.Parse(new SourceText("layout", output));
        if (!tree.Diagnostics.Select(d => d.Code).SequenceEqual(reparsed.Diagnostics.Select(d => d.Code))) return "the diagnostics changed";
        return null;
    }

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
        private readonly List<byte> _out = new(source.Length + source.Length / 8);

        public byte[] Render()
        {
            for (var i = 0; i < tokens.Length; i++) _lineStart[i] = i == 0 || gaps[i].HasNewline;
            Freeze();
            Levels();
            TopLevelBlanks();
            _out.AddRange(source.AsSpan(0, bom));
            for (var i = 0; i < tokens.Length; i++)
            {
                EmitGap(i);
                _out.AddRange(source.AsSpan(tokens[i].Start, tokens[i].Length));
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

        /// <summary>The spaces and tabs that start the original line of token <paramref name="i"/>.</summary>
        private int OriginalIndent(int i)
        {
            var at = tokens[i].Start;
            var n = 0;
            while (at > bom && source[at - 1] is (byte)' ' or (byte)'\t')
            {
                at--;
                n++;
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
                else if (first is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace) level = Math.Max(0, top.Line);
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
                            frames.Add(new Frame { Opener = Kind(k), Line = line, Statement = line, StatementIndent = OriginalIndent(i) });
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
                _out.Add((byte)' ');
                Add(items[0]);
                at = 1;
            }
            if (i > 0 && !gap.HasNewline)
            {
                if (eof)
                {
                    _out.Add((byte)'\n');
                    return;
                }
                if (at == 0 && Space(i, from)) _out.Add((byte)' ');
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

        private void Indent(int level)
        {
            for (var n = level * options.Indent; n > 0; n--) _out.Add((byte)' ');
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
            var (before, kind) = (Kind(i - 1), Kind(i));
            // The parser reads these pairs by their adjacency: `>>`, `>>=`, `T...`.
            if (before == TokenKind.Greater && kind is TokenKind.Greater or TokenKind.GreaterEquals && !written) return false;
            if (before is TokenKind.DotDot && kind == TokenKind.Dot) return written;
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
                if (_lineStart[k]) return false;
            }
            return false;
        }
    }
}
