# shellcheck shell=bash
# Sourced by the scripts/docs and scripts/release tests: docs_fixture <dir> builds a small repo at <dir> holding the
# real release and docs scripts and miniature sources for them (version 1.2.3-dev, revisions 0001–0002, every release doc), with the
# generated docs written. Needs $root (the real repo).

docs_fixture() {
  local r="$1" d
  mkdir -p "$r/scripts/release" "$r/scripts/docs" "$r/docs/revisions" "$r/docs/diagnostics" "$r/csharp/Bayan.Backend.C" \
    "$r/csharp/Bayan.Syntax/Diagnostics" "$r/csharp/Bayan.Syntax/Lexing" "$r/csharp/Bayan.Semantics/Binding" "$r/src/driver" \
    "$r/tests/cases/out"
  cp "$root"/scripts/release/{version,set-version,package}.sh "$r/scripts/release/"
  for f in cut next-dev; do [ ! -f "$root/scripts/release/$f.sh" ] || cp "$root/scripts/release/$f.sh" "$r/scripts/release/"; done
  cp "$root"/scripts/docs/{gen-diagnostics,gen-status,gen-spec-index,check,check-history}.sh "$r/scripts/docs/"
  printf '1.2.3-dev\n' > "$r/VERSION"
  printf 'public static class Toolchain\n{\n    public const string CompilerVersion = "1.2.3-dev";\n}\n' > "$r/csharp/Bayan.Backend.C/Toolchain.cs"
  printf '// driver\nconst version: string = "1.2.3-dev"\n' > "$r/src/driver/main.byn"
  printf '{\n  "compiler": "bayan 1.2.3-dev",\n  "x": 1\n}\n{\n  "compiler": "bayan 1.2.3-dev"\n}\n' > "$r/tests/cases/out/dist.tree"
  printf '# Bayan\n\n```sh\nscripts/dist.sh                                # this host: dist/macos-arm64/1.2.3-dev/bayan\n```\n' > "$r/README.md"
  mkdir -p "$r/tests/parity/cli-cli/version-prints-version/expected" "$r/tests/parity/cli-environment/doctor-reports-a-healthy-toolchain/expected"
  printf '$ bayan --version\nbayan 1.2.3-dev (<build>)\n' > "$r/tests/parity/cli-cli/version-prints-version/expected/stdout"
  printf '\n\n◆ bayan       1.2.3-dev (commit <c>)\n' > "$r/tests/parity/cli-environment/doctor-reports-a-healthy-toolchain/expected/stdout"
  printf '# 0001 — First\n\nStatus: done\nRelease: 1.2.2\nSources: none recorded\n' > "$r/docs/revisions/0001-first.md"
  printf '# 0002 — Second\n\nStatus: done\nRelease: 1.2.2\nSources: none recorded\n' > "$r/docs/revisions/0002-second.md"
  for d in spec grammar style; do
    printf '# Bayan %s\n\nVersion: 1.2.3-dev (matches `bayan --version`)\nRevisions applied: 0001–0002\n\nBody of %s.\n' "$d" "$d" > "$r/docs/bayan-$d.md"
  done
  # The other release docs (version.sh `bayan_release_docs`): a title and the Version line.
  . "$r/scripts/release/version.sh"
  for d in $bayan_release_docs; do
    case "$d" in docs/DIAGNOSTICS.md|docs/STATUS.md|docs/specs/README.md) continue ;; esac
    [ -f "$r/$d" ] && continue
    mkdir -p "$r/$(dirname "$d")"
    printf '# %s\n\nVersion: 1.2.3-dev (matches `bayan --version`)\n' "$d" > "$r/$d"
  done
  # The feature history cites every fixture revision and has a `### §N. ` row per `## N.` heading of the fixture spec.
  printf '# Feature history\n\nVersion: 1.2.3-dev (matches `bayan --version`)\n\n0001-first.md, 0002-second.md\n' > "$r/docs/bayan-feature-history.md"
  mkdir -p "$r/docs/specs/001-first"
  printf '# 001 — First\n\nStatus: done\nRelease: 1.2.2\nSources: none recorded\n' > "$r/docs/specs/001-first/001-spec.md"
  printf '# Changelog\n\n## [Unreleased]\n\n### Added\n- a new thing\n\n## [1.2.2] - 2026-01-01\n\n- old\n' > "$r/CHANGELOG.md"
  mkdir -p "$r/src/lexer" "$r/src/parser" "$r/src/semantics" "$r/scripts/docs/data"
  : > "$r/src/lexer/diagnostics.byn"; : > "$r/src/parser/codes.byn"
  cat > "$r/src/semantics/codes.byn" <<'EOF'
enum SemaCode {
    alpha
    secondForm
    retiredBeta
    gamma
    delta
    old
}

string codeText(SemaCode code) => code switch {
    .alpha       => "BYN0001",
    .secondForm  => "BYN0001",
    .retiredBeta => "BYN1002",
    .gamma       => "BYN2003",
    .delta       => "BYN3004",
    .old         => "BYN3005",
}

string messageFormat(SemaCode code) => code switch {
    .alpha       => "alpha `{0}`",
    .secondForm  => "second form",
    .retiredBeta => "retired: beta",
    .gamma       => "a | b needs \"quotes\"",
    .delta       => "delta",
    .old         => "old",
}

bool isWarning(SemaCode code) => code switch {
    .gamma => true,
    _ => false,
}
EOF
  printf '# BYN0001: alpha\n' > "$r/docs/diagnostics/BYN0001.md"
  cat > "$r/docs/diagnostics-allocated.txt" <<'EOF'
# hand-kept
plan BYN2233 UnlikelyOnErrorReturn Warning: redundant.
reserved BYN8004 - a layer-2 sink
retired BYN3005 Old retired in its page only
EOF
  cat > "$r/src/lexer/tokens.byn" <<'EOF'
public enum TokenKind {
    identifier
    structKeyword
    errorKeyword
    // Reserved: no meaning yet.
    actorKeyword
}

bool isReservedKeyword(TokenKind kind) =>
    kind.ordinal >= TokenKind.actorKeyword.ordinal && kind.ordinal <= TokenKind.actorKeyword.ordinal
EOF
  cat > "$r/src/parser/recover.byn" <<'EOF'
public bool isContextualKeyword(TokenKind kind) => kind switch {
    .errorKeyword => true,
    _ => false,
}
EOF
  cat > "$r/src/semantics/builtins.byn" <<'EOF'
PropertyResult? builtinProperty(ref Ctx c, for Type type, by string name) {
    switch name {
        case "length": return t9Property(.stringLength, as: prim(.i64))
        case "utf16": return t9Property(.stringUtf16, as: textViewType(.utf16))
    }
    return null
}

BuiltinMethod? method(ref Ctx c, for Type type, by string name) {
    switch name {
        case "copy": return null
        case "joined": return null
        case "append": return null
    }
    return null
}

bool hasMethod(ref Ctx c, for Type type, by string name) =>
    method(ref c, for: type, by: name) is not null || (type == builtinType(.ioInput) && name == "readAllBytes")

List<string> names(ref Ctx c, for Type t) {
    return List<string>()
}
EOF
  { printf 'kind\tf1\tf2\tf3\n'
    printf 'retired\tBYN1002\tmerged into BYN0001. Never reuse it.\n'
    printf 'reserved\tBYN3004\tno fibers yet.\n'
    printf 'round4\tBYN1070\tNegatedIsInput\t`!(x is .s)`. // target: 19xx input form\n'
    printf 'kw\tactor\t6\nkw\terror\t5\nkw\tstruct\t5\n'
    printf 'mem\tIoInput\treadAllBytes\t21\nmem\tList\tappend\t15\nmem\tList<string>\tjoined\t13\nmem\tSpan<string>\tjoined\t13\n'
    printf 'mem\tUtf16\tcopy\t12\nmem\trune\tcopy\t16\nmem\tstring\tlength\t5\nmem\tstring\tutf16\t6\n'
  } > "$r/scripts/docs/data/csharp-facts.tsv"
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
  bash "$r/scripts/docs/gen-spec-index.sh" --write
}
