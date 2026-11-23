#!/usr/bin/env bash
# Law L047 (spec 024 R7) with no dotnet, ported from SabkAllocationLawTests.AllocationIsSound (src/tests/SabkLawTests.cs):
# `$BAYAN_EXE test --package src src/sabk --only L047:` runs the two Bayān tests "L047:" in src/sabk/check/sound.test.byn and
# passes exactly 2.
# BAYAN_EXE: the self-hosted driver; unset, src/driver is built with the pinned bayan (scripts/pinned-bayan.sh) into tmp/, as
# scripts/test.sh does. Off arm64 macOS it prints why and exits 0. bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then echo "l047: skipped: sabk tests need arm64 macOS (024 R9)"; exit 0; fi
fail() { echo "FAIL L047: $1"; exit 1; }

bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  mkdir -p tmp
  bayan="$root/tmp/sabk-law047-bayan"
  pin="$(bash scripts/pinned-bayan.sh 2>"$bayan.log")" && "$pin" build --mode safe --package src -o "$bayan" src/driver >>"$bayan.log" 2>&1 \
    || fail "building src/driver with the pinned bayan failed; log: $bayan.log"
fi
export BAYAN_EXE="$bayan"

rc=0; out="$("$bayan" test --package src src/sabk --only 'L047:' 2>&1)" || rc=$?
case "$out" in (*"◆ 2 passed"*) [ $rc = 0 ] ;; (*) false ;; esac || fail "L047: failed (exit $rc):
$out"
echo "l047: 2 passed"
