#!/usr/bin/env bash
# Regenerates the generated parts of docs/STATUS.md: the header's two lines, the keyword rows (between
# `<!-- generated: keywords -->` and `<!-- end generated: keywords -->`) and the stdlib rows (`<!-- generated: stdlib -->`
# … `<!-- end generated: stdlib -->`) from scripts/docs/data/csharp-facts.tsv (the `kw` and `mem` rows, extracted once
# from the retired C# Keywords.cs, TokenKind.cs and BuiltinMembers.cs). Everything else in the file (the feature rows) is hand-kept and
# copied through. Deterministic: sorted, LF, no dates.
#   gen-status.sh            print the regenerated file
#   gen-status.sh --write    rewrite docs/STATUS.md
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/release/version.sh"
die() { echo "gen-status: $*" >&2; exit 1; }
status="$root/docs/STATUS.md"
facts_tsv="$root/scripts/docs/data/csharp-facts.tsv"
for f in "$status" "$facts_tsv"; do [ -f "$f" ] || die "${f#"$root/"} not found"; done
v="$(bayan_version "$root")"; rev="$(bayan_latest_revision "$root")"
[ -n "$rev" ] || die "no docs/revisions/NNNN-*.md"
for m in keywords stdlib; do
  [ "$(grep -cxF "<!-- generated: $m -->" "$status")" = 1 ] && [ "$(grep -cxF "<!-- end generated: $m -->" "$status")" = 1 ] \
    || die "docs/STATUS.md needs one '<!-- generated: $m -->' and one '<!-- end generated: $m -->' line"
done
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
export LC_ALL=C

# C#-only facts from the TSV: kw (keyword, line in the retired Keywords.cs) and mem (receiver, member, line in the retired
# BuiltinMembers.cs)
facts() { awk -F'\t' -v OFS='\t' -v k="$1" '$1 == k { $1 = ""; sub(/^\t/, ""); print }' "$facts_tsv"; }

# keyword, kind, line. The keywords are the `xKeyword` kinds of src/lexer/tokens.byn (`x` is the text); reserved ones run
# from isReservedKeyword's lower bound to its upper bound, contextual ones are those src/parser/recover.byn's
# isContextualKeyword names; the line is the TSV's `kw` row (the keyword's line in the retired Keywords.cs).
facts kw > "$t/kwline"
awk '/^(public )?bool isContextualKeyword\(/ { on = 1 }
  on { s = $0; while (match(s, /\.[A-Za-z]+Keyword/)) { print substr(s, RSTART + 1, RLENGTH - 8); s = substr(s, RSTART + RLENGTH) } }
  on && /^}/ { exit }' "$root/src/parser/recover.byn" > "$t/ctx"
awk '/^(public )?bool isReservedKeyword\(/ { r = 1 }
  r && match($0, /ordinal >= TokenKind\.[A-Za-z]+/) { print "lo " substr($0, RSTART + 21, RLENGTH - 21 - 7) }
  r && match($0, /ordinal <= TokenKind\.[A-Za-z]+/) { print "hi " substr($0, RSTART + 21, RLENGTH - 21 - 7); r = 0 }
  /^(public )?enum TokenKind/ { e = 1; next } e && /^}/ { e = 0 }
  e { n = $0; gsub(/[ \t]/, "", n); if (n ~ /Keyword$/) { sub(/Keyword$/, "", n); print "kw " n } }' "$root/src/lexer/tokens.byn" > "$t/enum"
awk -v ctxf="$t/ctx" -v linef="$t/kwline" '
  BEGIN { while ((getline cw < ctxf) > 0) ctx[cw] = 1; while ((getline l < linef) > 0) { split(l, a, "\t"); line[a[1]] = a[2] } }
  $1 == "lo" { lo = $2 } $1 == "hi" { hi = $2 }
  $1 == "kw" { w[++n] = $2 }
  END { for (i = 1; i <= n; i++) { k = w[i]; if (k == lo) on = 1
          print k "\t" (on ? "reserved" : (k in ctx ? "contextual" : "keyword")) "\t" line[k]
          if (k == hi) on = 0 } }' "$t/enum" | sort -k1,1 > "$t/kw"
[ -s "$t/kw" ] || die "no keywords in src/lexer/tokens.byn"
[ "$(wc -l < "$t/kw" | tr -d ' ')" = "$(facts kw | wc -l | tr -d ' ')" ] || die "csharp-facts.tsv kw rows and src/lexer/tokens.byn keywords differ"
{ printf '| keyword | kind | evidence |\n|---|---|---|\n'
  while IFS=$'\t' read -r w k n; do printf '| `%s` | %s | `Keywords.cs:%s` |\n' "$w" "$k" "$n"; done < "$t/kw"
} > "$t/kw.md"

# receiver, member, kind, line. The kind is where src/semantics/builtins.byn handles the member name: builtinProperty
# (property) or method and the helpers after it (method); the receiver and line are the TSV's `mem` row (the retired BuiltinMembers.cs).
awk '/^PropertyResult\? builtinProperty\(/ { kind = "property" } /^BuiltinMethod\? method\(/ { kind = "method" }
  kind != "" { s = $0; while (match(s, /(case |name == )"[A-Za-z0-9]+"/)) {
    p = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH); split(p, a, "\""); print a[2] "\t" kind } }
  /^List<string> names\(/ { kind = "" }' \
  "$root/src/semantics/builtins.byn" | sort -u > "$t/kinds"
facts mem | awk -F'\t' -v OFS='\t' -v kf="$t/kinds" '
  BEGIN { while ((getline l < kf) > 0) { split(l, a, "\t"); kind[a[1]] = a[2] } }
  { if (!($2 in kind)) { print "gen-status: member " $2 " is not in src/semantics/builtins.byn" > "/dev/stderr"; bad = 1 }
    print $1, $2, kind[$2], $3 } END { exit bad }' > "$t/mem" || die "csharp-facts.tsv mem rows and src/semantics/builtins.byn differ"
[ -s "$t/mem" ] || die "no members in csharp-facts.tsv"
{ printf '| receiver | member | kind | evidence |\n|---|---|---|---|\n'
  while IFS=$'\t' read -r r m k n; do printf '| %s | `%s` | %s | `BuiltinMembers.cs:%s` |\n' "$r" "$m" "$k" "$n"; done < "$t/mem"
} > "$t/mem.md"

gen() {
  awk -v v="$v" -v rev="$rev" -v kw="$t/kw.md" -v mem="$t/mem.md" '
    function emit(f,  l) { while ((getline l < f) > 0) print l; close(f) }
    !hv && /^Version: / { print "Version: " v " (matches `bayan --version`)"; hv = 1; next }
    !hr && /^Revisions applied: / { print "Revisions applied: 0001–" rev; hr = 1; next }
    $0 == "<!-- generated: keywords -->" { print; emit(kw); skip = 1; next }
    $0 == "<!-- generated: stdlib -->" { print; emit(mem); skip = 1; next }
    /^<!-- end generated: [a-z]+ -->$/ { skip = 0 }
    !skip { print }
    END { if (!hv || !hr) { print "gen-status: docs/STATUS.md has no Version: or Revisions applied: line" > "/dev/stderr"; exit 1 } }' "$status"
}

if [ "${1:-}" = --write ]; then gen > "$t/out"; cat "$t/out" > "$status"; else gen; fi
