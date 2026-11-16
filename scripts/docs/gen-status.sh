#!/usr/bin/env bash
# Regenerates the generated parts of docs/STATUS.md: the header's two lines, the keyword rows (between
# `<!-- generated: keywords -->` and `<!-- end generated: keywords -->`) from src/Bayan.Syntax/Lexing/Keywords.cs and
# TokenKind.cs, and the stdlib rows (`<!-- generated: stdlib -->` … `<!-- end generated: stdlib -->`) from
# src/Bayan.Semantics/Binding/BuiltinMembers.cs. Everything else in the file (the feature rows) is hand-kept and
# copied through. Deterministic: sorted, LF, no dates.
#   gen-status.sh            print the regenerated file
#   gen-status.sh --write    rewrite docs/STATUS.md
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/release/version.sh"
die() { echo "gen-status: $*" >&2; exit 1; }
status="$root/docs/STATUS.md"
keywords="$root/src/Bayan.Syntax/Lexing/Keywords.cs"
kinds="$root/src/Bayan.Syntax/Lexing/TokenKind.cs"
members="$root/src/Bayan.Semantics/Binding/BuiltinMembers.cs"
for f in "$status" "$keywords" "$kinds" "$members"; do [ -f "$f" ] || die "${f#"$root/"} not found"; done
v="$(bayan_version "$root")"; rev="$(bayan_latest_revision "$root")"
[ -n "$rev" ] || die "no docs/revisions/NNNN-*.md"
for m in keywords stdlib; do
  [ "$(grep -cxF "<!-- generated: $m -->" "$status")" = 1 ] && [ "$(grep -cxF "<!-- end generated: $m -->" "$status")" = 1 ] \
    || die "docs/STATUS.md needs one '<!-- generated: $m -->' and one '<!-- end generated: $m -->' line"
done
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
export LC_ALL=C

# Contextual: the kinds named in TokenKindFacts.IsContextualKeyword. Reserved: the enum members from the lower bound of
# IsReservedKeyword to KeywordLast, in declaration order.
awk '/IsContextualKeyword\(/ { on = 1 } on { while (match($0, /TokenKind\.[A-Za-z]+Keyword/)) { print substr($0, RSTART + 10, RLENGTH - 10); $0 = substr($0, RSTART + RLENGTH) } } on && /;/ { exit }' \
  "$kinds" | sed 's/^/contextual /' > "$t/kinds"
lo="$(sed -nE 's/.*IsReservedKeyword.*>= TokenKind\.([A-Za-z]+) and <= KeywordLast.*/\1/p' "$kinds")"
hi="$(sed -nE 's/.*const TokenKind KeywordLast = TokenKind\.([A-Za-z]+);.*/\1/p' "$kinds")"
[ -n "$lo" ] && [ -n "$hi" ] || die "cannot find IsReservedKeyword's range in TokenKind.cs"
awk -v lo="$lo" -v hi="$hi" '/^public enum TokenKind/ { e = 1 } e && /^}/ { exit }
  e { n = $0; gsub(/[ ,]/, "", n); if (n == lo) on = 1; if (on && n ~ /^[A-Za-z]+$/) print "reserved " n; if (n == hi) on = 0 }' "$kinds" >> "$t/kinds"

# keyword, kind, line
awk 'FNR == NR { kind[$2] = $1; next }
  /\(string Text, TokenKind Kind\)\[\] All =/ { on = 1; next } on && /^ *\];/ { exit }
  on { s = $0; while (match(s, /\("[a-z]+", TokenKind\.[A-Za-z]+\)/)) {
         p = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
         split(p, a, "\""); k = p; sub(/.*TokenKind\./, "", k); sub(/\)$/, "", k)
         print a[2] "\t" (k in kind ? kind[k] : "keyword") "\t" FNR } }' "$t/kinds" "$keywords" | sort -k1,1 > "$t/kw"
[ -s "$t/kw" ] || die "no keywords in Keywords.cs"
{ printf '| keyword | kind | evidence |\n|---|---|---|\n'
  while IFS=$'\t' read -r w k n; do printf '| `%s` | %s | `Keywords.cs:%s` |\n' "$w" "$k" "$n"; done < "$t/kw"
} > "$t/kw.md"

# receiver, member, kind, line. A receiver pattern names its type: `{ IsString: true }` is string, `X { Kind: K.Y }`
# is Y (Char is rune), `X { Element.IsString: true }` is X<string>, else X without `Symbols.` and `Type`.
awk '/ Property\(TypeSymbol type, string name\)/ { kind = "property" } / Method\(TypeSymbol type, string name\)/ { kind = "method" }
  /bool HasMethod\(/ { kind = "method"; hm = 1 }
  function recv(p) {
    sub(/ [a-z]$/, "", p)
    if (p == "{ IsString: true }") return "string"
    if (match(p, /Kind: [A-Za-z]+\.[A-Za-z0-9]+/)) { r = substr(p, RSTART, RLENGTH); sub(/.*\./, "", r); return r == "Char" ? "rune" : r }
    b = p; sub(/ .*/, "", b); sub(/^Symbols\./, "", b); sub(/Type$/, "", b); sub(/Symbol$/, "", b)
    if (p ~ /Element\.IsString: true/) b = b "<string>"
    return b
  }
  kind != "" && !hm { s = $0
    while (match(s, /\([A-Za-z.]*( ?\{[^}]*\})?( [a-z])?, "[A-Za-z0-9]+"\)/)) {
      p = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
      m = p; sub(/^.*, "/, "", m); sub(/"$/, "", m); sub(/, "[A-Za-z0-9]+"$/, "", p)
      print recv(p) "\t" m "\t" kind "\t" FNR } }
  hm && match($0, /BuiltinKind\.[A-Za-z]+ \} && name == "[A-Za-z]+"/) {
    p = substr($0, RSTART, RLENGTH); split(p, a, "\""); r = p; sub(/ .*/, "", r); sub(/.*\./, "", r)
    print r "\t" a[2] "\tmethod\t" FNR; exit }' "$members" | sort -t$'\t' -k1,1 -k2,2 -k3,3 -k4,4n | awk -F'\t' '!seen[$1 FS $2 FS $3]++' > "$t/mem"
[ -s "$t/mem" ] || die "no members in BuiltinMembers.cs"
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
