#!/usr/bin/env bash
# The versioned-docs gate, run by .github/workflows/ci.yml (docs/RELEASING.md). Prints one line per failure and exits
# 1 on any:
#   (a) the `Version:` line of each header doc (version.sh `bayan_header_docs`) is `Version: <VERSION> (matches …)`;
#   (b) docs/revisions/NNNN-*.md runs 0001..highest with no gap or repeat, and each header doc's
#       `Revisions applied:` line is `0001–<highest>`;
#   (c) docs/DIAGNOSTICS.md and docs/STATUS.md equal what scripts/docs/gen-diagnostics.sh and gen-status.sh print;
#   (d) every code and test mirror of VERSION (version.sh `bayan_mirrors`) holds VERSION;
#   (e) every `(not in A.B` / `(partial in A.B` status tag in the spec, grammar and style names the major.minor of
#       VERSION, `-dev` stripped (revision 0020);
#   (f) every BYNnnnn cited in the spec, grammar and style has a row in docs/DIAGNOSTICS.md (a descriptor, a code comment
#       or a docs/diagnostics-allocated.txt line; revision 0023);
#   (g) every `SPEC §N` / `spec §N.M` cited in docs/ and in code comments under src/, selfhost/ and lib/ names a numbered
#       heading of docs/bayan-spec.md. Not checked: historical text that cites the spec as it was (docs/revisions, plans,
#       specs, handoffs, export, bayan-handoff*, CHANGELOG, suq-round3-review-response.md, and bayan-concurrency.md, which
#       cites the removed §13.1–13.5 on purpose), and a bare `§N` (it may cite the grammar or the handoff).
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

# (e) status tags
mm="$(cut -d. -f1-2 <<< "${v%%-*}")"
for doc in docs/bayan-spec.md docs/bayan-grammar.md docs/bayan-style.md; do
  [ -f "$root/$doc" ] || continue
  while IFS=: read -r line tag; do
    [ "${tag##* in }" = "$mm" ] || fail "$doc:$line has the status tag '$tag', which is not for $mm (VERSION $v)"
  done < <(grep -noE '\((not|partial) in [0-9]+\.[0-9]+' "$root/$doc")
done

# (f) cited codes
if [ -f "$root/docs/DIAGNOSTICS.md" ]; then
  for doc in docs/bayan-spec.md docs/bayan-grammar.md docs/bayan-style.md; do
    [ -f "$root/$doc" ] || continue
    for code in $(grep -oE 'BYN[0-9]{4}' "$root/$doc" | sort -u); do
      grep -qE "^\| (\[$code\]\(|$code \|)" "$root/docs/DIAGNOSTICS.md" \
        || fail "$doc cites $code, which has no row in docs/DIAGNOSTICS.md; add it to docs/diagnostics-allocated.txt"
    done
  done
fi

# (g) cited spec sections
if [ -f "$root/docs/bayan-spec.md" ]; then
  heads="$(sed -nE 's/^#{2,3} ([0-9]+(\.[0-9]+)?)\.? .*/\1/p' "$root/docs/bayan-spec.md")"
  while IFS=: read -r file line text; do
    for c in $(grep -oiE "spec('s)? §[0-9]+(\.[0-9]+)?" <<< "$text" | grep -oE '[0-9]+(\.[0-9]+)?$'); do
      grep -qxF "$c" <<< "$heads" || fail "${file#"$root"/}:$line cites spec §$c, which is not a heading of docs/bayan-spec.md"
    done
  done < <(cd "$root" && grep -rnIiE "spec('s)? §[0-9]+" $(for d in docs src selfhost lib; do [ -d "$d" ] && echo "$d"; done) \
    --exclude-dir=revisions --exclude-dir=plans --exclude-dir=specs --exclude-dir=handoffs --exclude-dir=export \
    --exclude-dir=bin --exclude-dir=obj --exclude='bayan-handoff*' --exclude='CHANGELOG*' --exclude=bayan-concurrency.md \
    --exclude=suq-round3-review-response.md --exclude=bayan-spec.md | sed "s#^#$root/#")
fi

exit "$failed"
