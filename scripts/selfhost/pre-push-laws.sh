#!/bin/bash
# pre-push-laws.sh — the full tier of every enacted law (docs/laws/*.md with `status: enacted`): runs each law's own `check:` line
# with BAYAN_LAW_TIER=full, where the quick tier (unset, what `laws-check.js --run` and the merge gate run) runs a fixed seeded subset (spec 011 D11).
# An enacted law with no `check:` line fails the gate. Run it from the repo root before pushing; the laws-nightly workflow runs it too. It never pushes.
# BAYAN_LAWS_LEFT="L043 ..." names laws another job runs (ddc.yml runs L043 on the frozen compiler, the one job with .NET):
# each is printed as left and not run, and an id there that is not an enacted law fails the gate.
#   bash scripts/selfhost/pre-push-laws.sh [laws-dir]     (default docs/laws; BAYAN_LAWS_DIR also sets it)
set -u
cd "$(dirname "$0")/../.."
dir=${1:-${BAYAN_LAWS_DIR:-docs/laws}}
export BAYAN_LAW_TIER=full
failed=()
left=" ${BAYAN_LAWS_LEFT:-} "; seen=" "
for f in "$dir"/0*.md; do
  [ -e "$f" ] || continue
  front() { awk -v k="$1" '/^---[ \t]*$/ { if (++n == 2) exit; next } n == 1 && index($0, k ":") == 1 { sub(/^[^:]*: */, ""); print; exit }' "$f"; }
  [ "$(front status)" = enacted ] || continue
  id=$(front id)
  case "$left" in *" $id "*) echo "== $id left to another job (BAYAN_LAWS_LEFT)"; seen="$seen$id "; continue ;; esac
  echo "== $id (full tier)"
  check=$(front check)
  if [ -z "$check" ]; then echo "$id: no check: line in $f"; failed+=("$id"); continue; fi
  bash -c "$check" || failed+=("$id")
done
for id in $left; do case "$seen" in *" $id "*) ;; *) echo "$id: in BAYAN_LAWS_LEFT but not an enacted law"; failed+=("$id") ;; esac; done
if [ ${#failed[@]} = 0 ]; then echo "All enacted laws hold (full tier)."; exit 0; fi
echo "LAWS FAILED (full tier): ${failed[*]}"; exit 1
