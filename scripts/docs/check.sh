#!/usr/bin/env bash
# The versioned-docs gate, run by .github/workflows/ci.yml (docs/RELEASING.md). Prints one line per failure and exits
# 1 on any:
#   (a) the `Version:` line of each header doc (version.sh `bayan_header_docs`) is `Version: <VERSION> (matches …)`;
#   (b) docs/revisions/NNNN-*.md runs 0001..highest with no gap or repeat, and each header doc's
#       `Revisions applied:` line is `0001–<highest>`;
#   (c) docs/DIAGNOSTICS.md and docs/STATUS.md equal what scripts/docs/gen-diagnostics.sh and gen-status.sh print;
#   (d) every code and test mirror of VERSION (version.sh `bayan_mirrors`) holds VERSION.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/release/version.sh"
failed=0
fail() { echo "check: $*"; failed=1; }

v="$(bayan_version "$root" 2>&1)" || { echo "check: $v"; exit 1; }
rev="$(bayan_latest_revision "$root")"

# (b) the revision sequence
if [ -z "$rev" ]; then fail "no docs/revisions/NNNN-*.md"; else
  for ((n = 1; n <= 10#$rev; n++)); do
    nnnn="$(printf '%04d' "$n")"; set -- "$root"/docs/revisions/"$nnnn"-*.md
    if [ ! -e "$1" ]; then fail "docs/revisions/$nnnn-*.md is missing (revisions run 0001–$rev)"
    elif [ $# -gt 1 ]; then fail "docs/revisions has $# files numbered $nnnn"; fi
  done
fi

# (a) and (b) the headers, in the first ten lines of each doc
for doc in $bayan_header_docs; do
  [ -f "$root/$doc" ] || { fail "$doc not found"; continue; }
  line="$(head -n 10 "$root/$doc" | grep -m 1 '^Version: ' || true)"
  want="Version: $v (matches \`bayan --version\`)"
  [ "$line" = "$want" ] || fail "$doc: '${line:-no Version: line}' is not '$want'"
  line="$(head -n 10 "$root/$doc" | grep -m 1 '^Revisions applied: ' || true)"
  [ -z "$rev" ] || [ "$line" = "Revisions applied: 0001–$rev" ] \
    || fail "$doc: '${line:-no Revisions applied: line}' is not 'Revisions applied: 0001–$rev'"
done

# (c) the generated files
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
for g in diagnostics:DIAGNOSTICS status:STATUS; do
  gen="scripts/docs/gen-${g%%:*}.sh"; doc="docs/${g#*:}.md"
  if ! bash "$root/$gen" > "$t/out" 2> "$t/err"; then fail "$gen failed: $(head -n 1 "$t/err")"
  elif [ ! -f "$root/$doc" ]; then fail "$doc not found; run bash $gen --write"
  elif ! cmp -s "$t/out" "$root/$doc"; then fail "$doc is stale; run bash $gen --write"; fi
done

# (d) the mirrors
while IFS=$'\t' read -r file pre suf; do
  [ -f "$root/$file" ] || { fail "$file not found"; continue; }
  found="$(sed -nE "s#.*$pre([^\"/ ]+)$suf.*#\\2#p" "$root/$file")"
  [ -n "$found" ] || { fail "$file: no version found"; continue; }
  for got in $found; do
    [ "$got" = "$v" ] || fail "$file says $got, VERSION says $v; run bash scripts/release/set-version.sh $v"
  done
done < <(bayan_mirrors)

exit "$failed"
