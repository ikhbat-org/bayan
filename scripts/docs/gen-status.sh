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

# keyword, kind, line and receiver, member, kind, line: the `kw` and `mem` rows
facts() { awk -F'\t' -v OFS='\t' -v k="$1" '$1 == k { $1 = ""; sub(/^\t/, ""); print }' "$facts_tsv"; }
facts kw > "$t/kw"
[ -s "$t/kw" ] || die "no kw rows in csharp-facts.tsv"
{ printf '| keyword | kind | evidence |\n|---|---|---|\n'
  while IFS=$'\t' read -r w k n; do printf '| `%s` | %s | `Keywords.cs:%s` |\n' "$w" "$k" "$n"; done < "$t/kw"
} > "$t/kw.md"

facts mem > "$t/mem"
[ -s "$t/mem" ] || die "no mem rows in csharp-facts.tsv"
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
