# shellcheck shell=bash
# Sourced by the scripts/docs and scripts/release tests: docs_fixture <dir> builds a small repo at <dir> holding the
# real release and docs scripts and miniature sources for them (version 1.2.3-dev, revisions 0001–0002), with the
# generated docs written. Needs $root (the real repo).

docs_fixture() {
  local r="$1" d
  mkdir -p "$r/scripts/release" "$r/scripts/docs" "$r/docs/revisions" "$r/docs/diagnostics" "$r/src/Bayan.Backend.C" \
    "$r/src/Bayan.Syntax/Diagnostics" "$r/src/Bayan.Syntax/Lexing" "$r/src/Bayan.Semantics/Binding" "$r/selfhost/driver" \
    "$r/tests/cases/out"
  cp "$root"/scripts/release/{version,set-version,package}.sh "$r/scripts/release/"
  for f in cut next-dev; do [ ! -f "$root/scripts/release/$f.sh" ] || cp "$root/scripts/release/$f.sh" "$r/scripts/release/"; done
  cp "$root"/scripts/docs/{gen-diagnostics,gen-status,check}.sh "$r/scripts/docs/"
  printf '1.2.3-dev\n' > "$r/VERSION"
  printf 'public static class Toolchain\n{\n    public const string CompilerVersion = "1.2.3-dev";\n}\n' > "$r/src/Bayan.Backend.C/Toolchain.cs"
  printf '// driver\nconst version: string = "1.2.3-dev"\n' > "$r/selfhost/driver/main.byn"
  printf '{\n  "compiler": "bayan 1.2.3-dev",\n  "x": 1\n}\n{\n  "compiler": "bayan 1.2.3-dev"\n}\n' > "$r/tests/cases/out/dist.tree"
  printf '# Bayan\n\n```sh\nscripts/dist.sh                                # this host: dist/macos-arm64/1.2.3-dev/bayan\n```\n' > "$r/README.md"
  printf '# 0001 — First\n\nStatus: accepted\n' > "$r/docs/revisions/0001-first.md"
  printf '# 0002 — Second\n\nStatus: accepted\n' > "$r/docs/revisions/0002-second.md"
  printf '# Revisions\n' > "$r/docs/revisions/README.md"
  for d in spec grammar style; do
    printf '# Bayan %s\n\nVersion: 1.2.3-dev (matches `bayan --version`)\nRevisions applied: 0001–0002\n\nBody of %s.\n' "$d" "$d" > "$r/docs/bayan-$d.md"
  done
  printf '# Changelog\n\n## [Unreleased]\n\n### Added\n- a new thing\n\n## [1.2.2] - 2026-01-01\n\n- old\n' > "$r/CHANGELOG.md"
  cat > "$r/src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs" <<'EOF'
public static class DiagnosticCodes
{
    public static readonly DiagnosticDescriptor Alpha = Error("BYN0001", "alpha `{0}`");
    // BYN1002 is retired: merged into BYN0001. Never reuse it.
    public static readonly DiagnosticDescriptor RetiredBeta = Error("BYN1002", "retired: beta");
    public static readonly DiagnosticDescriptor Gamma = Warning("BYN2003", "a | b needs \"quotes\"");
    // BYN3004 is reserved: no fibers yet.
    public static readonly DiagnosticDescriptor Delta = Error("BYN3004", "delta");
    public static readonly DiagnosticDescriptor Old = Error("BYN3005", "old");
    public static readonly DiagnosticDescriptor SecondForm = new("BYN0001", Severity.Error, "second form");
    // Reserved: round 4.
    // BYN1070 NegatedIsInput: `!(x is .s)`. // target: 19xx input form
    // End reserved: round 4.
}
EOF
  printf '# BYN0001: alpha\n' > "$r/docs/diagnostics/BYN0001.md"
  cat > "$r/docs/diagnostics-allocated.txt" <<'EOF'
# hand-kept
plan BYN2233 UnlikelyOnErrorReturn Warning: redundant.
reserved BYN8004 - a layer-2 sink
retired BYN3005 Old retired in its page only
EOF
  cat > "$r/src/Bayan.Syntax/Lexing/Keywords.cs" <<'EOF'
public static class Keywords
{
    private static readonly (string Text, TokenKind Kind)[] All =
    [
        ("struct", TokenKind.StructKeyword), ("error", TokenKind.ErrorKeyword),
        ("actor", TokenKind.ActorKeyword),
    ];
}
EOF
  cat > "$r/src/Bayan.Syntax/Lexing/TokenKind.cs" <<'EOF'
public enum TokenKind : ushort
{
    StructKeyword,
    ErrorKeyword,
    // Reserved: no meaning yet.
    ActorKeyword,
}

public static class TokenKindFacts
{
    public const TokenKind KeywordLast = TokenKind.ActorKeyword;

    public static bool IsReservedKeyword(this TokenKind kind) => kind is >= TokenKind.ActorKeyword and <= KeywordLast;

    public static bool IsContextualKeyword(this TokenKind kind) => kind is
        TokenKind.ErrorKeyword;
}
EOF
  cat > "$r/src/Bayan.Semantics/Binding/BuiltinMembers.cs" <<'EOF'
internal static class BuiltinMembers
{
    public static (BuiltinMember Member, TypeSymbol Type)? Property(TypeSymbol type, string name) => (type, name) switch
    {
        ({ IsString: true }, "length") => (BuiltinMember.StringLength, PrimitiveType.I64),
        ({ IsString: true }, "utf16") => (BuiltinMember.StringUtf16, TextViewType.Utf16),
        _ => null,
    };

    public static BuiltinMethod? Method(TypeSymbol type, string name) => (type, name) switch
    {
        (TextViewType { Kind: TextViewKind.Utf16 }, "copy") => new(BuiltinMember.Utf16Copy, [], new ListType(PrimitiveType.U16)),
        (SpanType { Element.IsString: true }, "joined") or (ListType { Element.IsString: true }, "joined") =>
            new(BuiltinMember.StringJoined, [("by", PrimitiveType.String)], PrimitiveType.String),
        (ListType l, "append") => new(BuiltinMember.ListAdd, [("item", l.Element)], PrimitiveType.Void, Mutating: true),
        (PrimitiveType { Kind: PrimitiveKind.Char }, "copy") => null,
        _ => null,
    };

    public static bool HasMethod(TypeSymbol type, string name) =>
        Method(type, name) is not null || (type is BuiltinType { Kind: BuiltinKind.IoInput } && name == "readAllBytes");

    private static readonly string[] Candidates = ["length", "copy"];
}
EOF
  cat > "$r/docs/STATUS.md" <<'EOF'
# Bayan status

Version: 1.2.3-dev (matches `bayan --version`)
Revisions applied: 0001–0002

Hand-kept intro.

## Features

| name | decided in | status | evidence |
|---|---|---|---|
| `then` | round 4 | proposed | none |
| units | SPEC | spec-only | none |

## Keywords (generated)

<!-- generated: keywords -->
<!-- end generated: keywords -->

## Stdlib members (generated)

<!-- generated: stdlib -->
<!-- end generated: stdlib -->

Hand-kept tail.
EOF
  bash "$r/scripts/docs/gen-diagnostics.sh" --write
  bash "$r/scripts/docs/gen-status.sh" --write
}
