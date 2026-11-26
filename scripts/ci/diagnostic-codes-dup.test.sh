#!/usr/bin/env bash
# The duplicate-reserved-number check of scripts/ci/diagnostic-codes.test.sh must fail on a facts file that lists a round4 number twice.
# BAYAN_EXE as there; unset, that script builds bootstrap/bayan.c.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
mkdir -p tmp
facts="$root/tmp/diagnostic-codes-dup.tsv"
{ cat scripts/docs/data/csharp-facts.tsv; awk -F'\t' '$1 == "round4" { print; exit }' scripts/docs/data/csharp-facts.tsv; } > "$facts"
rc=0; out="$(BYAN_FACTS="$facts" bash scripts/ci/diagnostic-codes.test.sh 2>&1)" || rc=$?
[ "$rc" != 0 ] && grep -q 'a reserved number twice' <<<"$out" || { echo "FAIL duplicate reserved number not caught: $out"; exit 1; }
echo "diagnostic-codes-dup.test: ok"
