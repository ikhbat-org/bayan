#!/usr/bin/env bash
# Ported from DiagnosticCodesTests (spec 019 T27), one check per [Fact]. The code table is the registered table of docs/DIAGNOSTICS.md,
# which scripts/docs/gen-diagnostics.sh makes from the self-hosted message tables (scripts/docs/check.sh fails when it is stale); the
# round-4 reserved numbers are the `round4` rows of scripts/docs/data/csharp-facts.tsv. A doc example is compiled as
# `bayan check --diagnostics json tmp/diagnostic-codes/run/<name>/<code>.byn`, its own directory, as the C# compiled it alone.
#   codes-are-unique-and-well-formed, every-code-has-an-embedded-explanation (`bayan explain`), every-doc-belongs-to-a-code,
#   every-code-appears-in-a-golden-case, no-live-code-reuses-a-reserved-number, skip-list-names-existing-docs-and-still-needs-it,
#   allowed-extras-name-live-docs-and-still-need-them, every-doc-example-reports-its-own-code, complete-fix-blocks-compile-clean,
#   precondition-docs-name-requires-and-expects-and-example-612-agrees-with-its-fix, no-doc-bayan-block-ends-a-line-with-a-semicolon.
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
export LC_ALL=C
fail() { echo "FAIL $1"; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$root/tmp/diagnostic-codes-bayan"
  cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan" || fail "cannot build bootstrap/bayan.c"
fi
docs=docs/diagnostics
work="$root/tmp/diagnostic-codes"; rm -rf "$work"; mkdir -p "$work"

# The C# skip lists (DiagnosticCodesTests.cs UncompilableExamples, StructuralExamples, AllowedExtras, CompleteFixBlocks); the reasons
# are in the C# file.
uncompilable="BYN0001 BYN0005 BYN0015 BYN0016 BYN1030 BYN1032 BYN1049 BYN2005 BYN2006 BYN2010 BYN2011 BYN1072 BYN1073 BYN1074 BYN1075
  BYN1076 BYN1077 BYN1078 BYN1079 BYN1080 BYN2015 BYN2026 BYN2033 BYN2113 BYN2116 BYN2224 BYN2307 BYN2322 BYN2707 BYN2762 BYN2787 BYN3100
  BYN3101 BYN3102 BYN3103 BYN3104 BYN3201 BYN3213 BYN3215 BYN3217 BYN4001 BYN4002 BYN6004"
structural="BYN0001 BYN0005 BYN0015 BYN0016 BYN1072 BYN1073 BYN1074 BYN1075 BYN1076 BYN1077 BYN1078 BYN1079 BYN1080 BYN2005 BYN2010
  BYN2015 BYN2033 BYN3100 BYN3101 BYN3102 BYN3103 BYN3104 BYN3213 BYN3215 BYN3217 BYN4001 BYN4002 BYN6004"
extras="BYN1066/BYN1016 BYN5004/BYN5006 BYN5006/BYN5004"
# Bayan only (BYN2745, Decision 2026-11-19): its doc example `G<i64> {}` also leaves the field `g` unset (BYN2109).
extras="$extras BYN2745/BYN2109"
no_entry=BYN2014
complete_fix="BYN2027 BYN2235 BYN2236 BYN2320 BYN2321 BYN2612"
in_list() { case " $(echo $2) " in (*" $1 "*) return 0 ;; (*) return 1 ;; esac; }

# blocks <file> <heading> <prefix>: the fenced blocks of the paragraph starting with <heading>, up to the next `**` line, as
# <prefix>1, <prefix>2, ...; prints the count
blocks() {
  awk -v h="$2" -v p="$3" '
    !at { if (index($0, h) == 1) at = 1; next }
    !open && /^\*\*/ { exit }
    /^```/ { if (open) { open = 0; close(f) } else { open = 1; n++; f = p n; printf "" > f } next }
    open { print > f }
    END { print n + 0 }' "$1"
}
# codes <file.byn>: `code severity` per diagnostic of `bayan check --diagnostics json`
codes() {
  "$bayan" check --diagnostics json "$1" 2>&1 | sed -nE 's/^\{"code":"([^"]*)","severity":"([^"]*)".*/\1 \2/p' || true
}
# compile <code> <source file> <name>: copies the source to its own directory as <code>.byn and prints its codes
compile() {
  local d="$work/run/$3"; mkdir -p "$d"; cp "$2" "$d/$1.byn"; codes "$d/$1.byn"
}

registered="$(awk '/^## Registered/ { f = 1; next } /^## / { f = 0 } f && /^\| \[?BYN/' docs/DIAGNOSTICS.md \
  | sed -E 's/^\| \[?(BYN[0-9]{4})[]| ].*/\1/')"
[ -n "$registered" ] || fail "no registered codes in docs/DIAGNOSTICS.md"

# codes-are-unique-and-well-formed
bad="$(grep -vE '^BYN[0-9]{4}$' <<<"$registered" || true)"; [ -z "$bad" ] || fail "codes-are-unique-and-well-formed: malformed $bad"
dup="$(sort <<<"$registered" | uniq -d)"; [ -z "$dup" ] || fail "codes-are-unique-and-well-formed: twice $dup"

# every-code-has-an-embedded-explanation
for c in $registered; do
  first="$("$bayan" explain "$c" 2>/dev/null | head -n 1 || true)"
  case "$first" in ("# $c:"*) ;; (*) fail "every-code-has-an-embedded-explanation: $c has no docs/diagnostics/$c.md in \`bayan explain\`" ;; esac
done

# every-doc-belongs-to-a-code
for f in "$docs"/*.md; do
  c="$(basename "$f" .md)"; grep -qxF "$c" <<<"$registered" || fail "every-doc-belongs-to-a-code: $f names no registered code"
done

# every-code-appears-in-a-golden-case: a retired code ("No longer reported") or a reserved one ("Not reported yet") cannot
expected="$work/expected.txt"
find tests/cases -type f ! -name '*.byn' ! -name '*.md' -exec cat {} + > "$expected"
missing=""
for c in $registered; do
  grep -qE 'No longer reported|Not reported yet' "$docs/$c.md" && continue
  grep -qF " $c:" "$expected" || missing="$missing $c"
done
[ -z "$missing" ] || fail "every-code-appears-in-a-golden-case: no golden case for$missing"

# no-live-code-reuses-a-reserved-number
facts="${BAYAN_FACTS:-scripts/docs/data/csharp-facts.tsv}"
reserved="$(awk -F'\t' '$1 == "round4" { print $2 }' "$facts")"
[ -n "$reserved" ] || fail "no-live-code-reuses-a-reserved-number: no round4 rows in $facts"
[ -z "$(sort <<<"$reserved" | uniq -d)" ] || fail "no-live-code-reuses-a-reserved-number: a reserved number twice"
reuse="$(comm -12 <(sort -u <<<"$reserved") <(sort -u <<<"$registered"))"
[ -z "$reuse" ] || fail "no-live-code-reuses-a-reserved-number: $reuse"

failures=""
# skip-list-names-existing-docs-and-still-needs-it
for c in $uncompilable $structural; do [ -f "$docs/$c.md" ] || failures="$failures
$c: skip entry names no doc"; done
for c in $structural; do in_list "$c" "$uncompilable" || failures="$failures
$c: structural entry is not in the skip list"; done
for c in $uncompilable; do
  in_list "$c" "$structural" && continue; [ -f "$docs/$c.md" ] || continue
  n="$(blocks "$docs/$c.md" "**Example" "$work/skip-$c-")"
  if [ "$n" = 0 ]; then failures="$failures
$c: the doc has no Bayan example block; add it to StructuralExamples"
  elif compile "$c" "$work/skip-$c-1" "skip-$c" | grep -q "^$c "; then failures="$failures
$c: the example now reports its own code; remove the skip entry"; fi
done
[ -z "$failures" ] || fail "skip-list-names-existing-docs-and-still-needs-it:$failures"

# allowed-extras-name-live-docs-and-still-need-them
for key in $extras; do
  c="${key%/*}"; x="${key#*/}"
  [ -f "$docs/$c.md" ] || { failures="$failures
$key: names no doc; remove the entry"; continue; }
  in_list "$c" "$uncompilable" && { failures="$failures
$key: the doc is in the skip list; remove the entry"; continue; }
  n="$(blocks "$docs/$c.md" "**Example" "$work/extra-$c-")"
  { [ "$n" != 0 ] && compile "$c" "$work/extra-$c-1" "extra-$c" | grep -q "^$x "; } || failures="$failures
$key: the example no longer reports $x; remove the entry"
done
[ -z "$failures" ] || fail "allowed-extras-name-live-docs-and-still-need-them:$failures"

# every-doc-example-reports-its-own-code
total="$(ls "$docs"/*.md | wc -l | tr -d ' ')"; skips="$(echo $uncompilable | wc -w | tr -d ' ')"
[ $((skips * 4)) -lt "$total" ] || fail "every-doc-example-reports-its-own-code: the skip list is over 25% of the docs"
for f in "$docs"/*.md; do
  c="$(basename "$f" .md)"; in_list "$c" "$uncompilable" && continue
  n="$(blocks "$f" "**Example" "$work/ex-$c-")"
  [ "$n" != 0 ] || { failures="$failures
$c: no example block"; continue; }
  b=1
  while [ "$b" -le "$n" ]; do
    at="$c"; [ "$n" = 1 ] || at="$c block $b"
    got="$(compile "$c" "$work/ex-$c-$b" "ex-$c-$b")"
    reported="$(cut -d' ' -f1 <<<"$got" | grep -v '^$' | awk '!s[$0]++' | tr '\n' ' ')"
    extra=""
    for e in $(awk '$2 == "error" { print $1 }' <<<"$got" | awk '!s[$0]++'); do
      [ "$e" = "$c" ] || [ "$e" = "$no_entry" ] || in_list "$c/$e" "$extras" || extra="$extra $e"
    done
    if ! grep -q "^$c " <<<"$got"; then failures="$failures
$at: reported [$reported]"
    elif [ -n "$extra" ]; then failures="$failures
$at: also reports [${extra# }]"; fi
    b=$((b + 1))
  done
done
[ -z "$failures" ] || fail "every-doc-example-reports-its-own-code:$failures"

# complete-fix-blocks-compile-clean
for c in $complete_fix; do
  n="$(blocks "$docs/$c.md" "**Fix" "$work/fix-$c-")"
  [ "$n" != 0 ] || { failures="$failures
$c: no fix block"; continue; }
  b=1
  while [ "$b" -le "$n" ]; do
    errs="$(compile "$c" "$work/fix-$c-$b" "fix-$c-$b" | awk -v ne="$no_entry" '$2 == "error" && $1 != ne { print $1 }' | awk '!s[$0]++' | tr '\n' ' ')"
    [ -z "$errs" ] || failures="$failures
$c: fix block $b reports [${errs% }]"
    b=$((b + 1))
  done
done
[ -z "$failures" ] || fail "complete-fix-blocks-compile-clean:$failures"

# precondition-docs-name-requires-and-expects-and-example-612-agrees-with-its-fix
for c in BYN2320 BYN2321; do
  grep -q requires "$docs/$c.md" && grep -q expects "$docs/$c.md" || fail "precondition-docs-name-requires-and-expects: $c"
done
blocks "$docs/BYN2612.md" "**Example" "$work/p612-ex-" >/dev/null; blocks "$docs/BYN2612.md" "**Fix" "$work/p612-fix-" >/dev/null
grep -qF "db.name" "$work/p612-fix-1" && grep -qF "string name" "$work/p612-ex-1" || fail "example-612-agrees-with-its-fix"

# no-doc-bayan-block-ends-a-line-with-a-semicolon: BYN1040 shows `;` on purpose in its first Example block; its fix blocks are checked
found="$(for f in "$docs"/*.md; do
  awk -v code="$(basename "$f" .md)" '
    !inb && /^\*\*Example/ { seen = 1 }
    /^```/ {
      inb = !inb; fence = $0; sub(/[ \t]+$/, "", fence)
      bayan = inb && (fence == "```" || fence == "```bayan" || fence == "```byn")
      if (inb) skipping = (code == "BYN1040" && seen); else if (skipping) { skipping = 0; seen = 0 }
      next }
    inb && bayan && !skipping && /;[ \t]*(\}|$)/ { print code ":" NR }' "$f"
done)"
[ -z "$found" ] || fail "no-doc-bayan-block-ends-a-line-with-a-semicolon: \`;\` ends a statement in a Bayan block: $(tr '\n' ' ' <<<"$found")"

echo "diagnostic-codes: ok ($(wc -w <<<"$registered" | tr -d ' ') codes, $total docs)"
