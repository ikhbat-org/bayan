#!/usr/bin/env bash
# The versioned-docs gate, run by .github/workflows/ci.yml (docs/RELEASING.md). Prints one line per failure and exits
# 1 on any:
#   (a) the `Version:` line of each release doc (version.sh `bayan_release_docs`) is `Version: <VERSION> (matches …)`;
#   (b) docs/revisions/NNNN-*.md runs 0001..highest with no gap or repeat, and each header doc's
#       `Revisions applied:` line is `0001–<highest>`;
#   (c) docs/DIAGNOSTICS.md, docs/STATUS.md and docs/specs/README.md equal what scripts/docs/gen-diagnostics.sh,
#       gen-status.sh and gen-spec-index.sh print;
#   (d) every code and test mirror of VERSION (version.sh `bayan_mirrors`) holds VERSION;
#   (e) every `(not in A.B` / `(partial in A.B` status tag in the spec, grammar and style names the major.minor of
#       VERSION, `-dev` stripped (revision 0020);
#   (f) every BYNnnnn cited in the spec, grammar and style has a row in docs/DIAGNOSTICS.md (a descriptor, a code comment
#       or a docs/diagnostics-allocated.txt line; revision 0023);
#   (g) every `SPEC §N` / `spec §N.M` cited in docs/ and in code comments under csharp/, src/ and lib/ names a numbered
#       heading of docs/bayan-spec.md. Not checked: historical text that cites the spec as it was (docs/revisions, plans,
#       specs, handoffs, export, bayan-progress-log.md, the answered questions (docs/decisions/*-answered-questions.md),
#       CHANGELOG, suq-round3-review-response.md, and bayan-concurrency.md, which cites the removed §13.1–13.5 on purpose),
#       and a bare `§N` (it may cite the grammar or another doc);
#   (h) every record doc (specs, plans, decisions, revisions, audits, the progress log, the proposals and the laws
#       design) has `Status:`, `Release:` and `Sources:` lines in its first ten lines (docs/laws: the `status:`,
#       `release:` and `sources:` frontmatter keys, also in the first ten lines), and its release is a `## [X.Y.Z]` version in CHANGELOG.md, the
#       VERSION target (`-dev` stripped) or `unscheduled`; every snapshot doc (export, misc, the design rounds, the Sūq
#       reports and the other dated notes) has a `Snapshot:` line in its first ten lines. Release docs are neither;
#   (i) every docs/revisions/NNNN-*.md is cited in docs/bayan-feature-history.md and every numbered section of the spec
#       has a row there (scripts/docs/check-history.sh prints one line per problem).
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

# (a) the Version line, in the first ten lines of each release doc
for doc in $bayan_release_docs; do
  [ -f "$root/$doc" ] || { fail "$doc not found"; continue; }
  line="$(head -n 10 "$root/$doc" | grep -m 1 '^Version: ' || true)"
  want="Version: $v (matches \`bayan --version\`)"
  [ "$line" = "$want" ] || fail "$doc: '${line:-no Version: line}' is not '$want'"
done

# (b) the Revisions applied line, in the first ten lines of each header doc
for doc in $bayan_header_docs; do
  [ -f "$root/$doc" ] || continue
  line="$(head -n 10 "$root/$doc" | grep -m 1 '^Revisions applied: ' || true)"
  [ -z "$rev" ] || [ "$line" = "Revisions applied: 0001–$rev" ] \
    || fail "$doc: '${line:-no Revisions applied: line}' is not 'Revisions applied: 0001–$rev'"
done

# (c) the generated files
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
for g in diagnostics:docs/DIAGNOSTICS.md status:docs/STATUS.md spec-index:docs/specs/README.md; do
  gen="scripts/docs/gen-${g%%:*}.sh"; doc="${g#*:}"
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
  done < <(cd "$root" && grep -rnIiE "spec('s)? §[0-9]+" $(for d in docs csharp src lib; do [ -d "$d" ] && echo "$d"; done) \
    --exclude-dir=revisions --exclude-dir=plans --exclude-dir=specs --exclude-dir=handoffs --exclude-dir=export \
    --exclude-dir=bin --exclude-dir=obj --exclude=bayan-progress-log.md --exclude='*-answered-questions.md' --exclude='CHANGELOG*' --exclude=bayan-concurrency.md \
    --exclude=suq-round3-review-response.md --exclude=bayan-spec.md | sed "s#^#$root/#")
fi

# (h) record and snapshot headers
released="$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "$root/CHANGELOG.md" 2>/dev/null)"
while IFS= read -r doc; do
  case " $(echo $bayan_release_docs) " in *" $doc "*) continue ;; esac
  case "$doc" in
    docs/specs/*|docs/plans/*|docs/decisions/*|docs/revisions/*|docs/audits/*|docs/laws/*|docs/handoffs/*|docs/bayan-progress-log.md \
    |docs/bayan-style-proposal.md|docs/bayan-shorthands-proposal.md|docs/design/laws-contracts-and-parallel-iterators.md)
      top="$(head -n 10 "$root/$doc")"
      [ "$(head -n 1 "$root/$doc")" != "---" ] \
        || top="$(sed -E 's/^status: /Status: /; s/^release: /Release: /; s/^sources: /Sources: /' <<< "$top")"
      for key in Status Release Sources; do
        grep -q "^$key: " <<< "$top" || fail "$doc: no $key: line in the first ten lines (record doc)"
      done
      rel="$(grep -m 1 '^Release: ' <<< "$top" | sed -E 's/^Release: ([^ ;,(]+).*/\1/')"
      [ -z "$rel" ] || [ "$rel" = unscheduled ] || [ "$rel" = "${v%%-*}" ] \
        || grep -qxF "$rel" <<< "$released" \
        || fail "$doc: Release: $rel is not a released version (CHANGELOG.md), ${v%%-*} or unscheduled" ;;
    docs/export/*|docs/misc/*|docs/bayan-design-round-*|docs/suq-*|docs/bayan-reference-app-*|docs/bayan-status-for-suq.md \
    |docs/bayan-brand-brief.md|docs/bayan-additional-concepts.md|docs/bayan-going-public.md|docs/laws-and-decisions.md|docs/design/lessons-from-other-languages.md)
      head -n 10 "$root/$doc" | grep -q '^Snapshot: ' || fail "$doc: no Snapshot: line in the first ten lines (snapshot doc)" ;;
    docs/assets/*) ;;   # brand kit and images: assets, not docs
    docs/diagnostics/*) ;;   # embedded in `bayan explain` and bootstrap/bayan.c; no header until decided (plan 016)
    *) fail "$doc is not a release, record or snapshot doc; add it to bayan_release_docs (scripts/release/version.sh) or to a kind in check.sh (h)" ;;
  esac
done < <(cd "$root" && find docs -name '*.md' -type f | LC_ALL=C sort)

# (i) the feature history
while IFS= read -r line; do fail "$line"; done < <(bash "$root/scripts/docs/check-history.sh" 2>&1 || true)

exit "$failed"
