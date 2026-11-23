#!/usr/bin/env bash
# Tests scripts/release/memory-gate.sh: it runs every command of docs/memory-leaks.md's *Release gate* block, reports
# each failure and exits 1 on any, and release.yml cannot draft a release without it passing.
set -euo pipefail
# The stub logs the caller's BAYAN_TEST_TIMEOUT_MS, and ci.yml sets it for the whole Test step; start without it.
unset BAYAN_TEST_TIMEOUT_MS

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gate="$root/scripts/release/memory-gate.sh"
doc="$root/docs/memory-leaks.md"
wf="$root/.github/workflows/release.yml"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/memory-gate-test.XXXXXX")"; mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# The doc's gate block, comments dropped, is the list the script must run.
awk '/^## /{if(s)exit} /^## Release gate$/{s=1} s&&/^```sh/{b=1;next} b&&/^```/{exit} b' "$doc" | sed -E 's/(^|[[:space:]]+)#.*$//; s/[[:space:]]+$//' \
  | sed '/^$/d' > "$tmp/doc-cmds"
[ -s "$tmp/doc-cmds" ] || fail "no command block under '## Release gate' in docs/memory-leaks.md"
while IFS= read -r c; do
  grep -qxF "run $c" "$gate" || fail "memory-gate.sh does not run the documented gate command: $c"
done < "$tmp/doc-cmds"
[ "$(grep -c '^run ' "$gate")" = "$(wc -l < "$tmp/doc-cmds" | tr -d ' ')" ] || fail "memory-gate.sh runs commands the doc's gate block does not list"
grep -q 'scripts/release/memory-gate.sh' "$doc" || fail "docs/memory-leaks.md does not name scripts/release/memory-gate.sh"

# Stub dotnet and a scratch copy of the script tree: all pass, then one fails.
cat > "$tmp/bin/dotnet" <<'STUB'
#!/bin/bash
echo "dotnet $*" >> "$LOG"
case "$*" in *"$FAIL_ON"*) [ -n "$FAIL_ON" ] && exit 1 ;; esac
exit 0
STUB
chmod +x "$tmp/bin/dotnet"
w="$tmp/w"; mkdir -p "$w/scripts/release"; cp "$gate" "$w/scripts/release/"
printf '#!/bin/bash\necho pinned >> "$LOG"\n[ "$FAIL_ON" = pinned ] && exit 1\nexit 0\n' > "$w/scripts/pinned-bayan.test.sh"
# A stub driver: logs its timeout, its BAYAN_GOLDEN_BOUND_SHARD when not empty and its arguments, fails on FAIL_ON, reports
# the block pending when PENDING is set and a failed block when RANFAIL is set.
cat > "$tmp/bin/bayan" <<'STUB'
#!/bin/bash
echo "bayan timeout=$BAYAN_TEST_TIMEOUT_MS${BAYAN_GOLDEN_BOUND_SHARD:+ shard=$BAYAN_GOLDEN_BOUND_SHARD} $*" >> "$LOG"
case "$*" in *"$FAIL_ON"*) [ -n "$FAIL_ON" ] && exit 1 ;; esac
[ "$1" = build ] && { cp "$0" "${@: -2:1}"; exit 0; }
[ "$1" = test ] && echo "$BAYAN_EXE" > "$LOG.exe"
if [ -n "$PENDING" ]; then echo "  ◆ driver: $6 (pending)"; echo "◆ 0 passed · 1 pending · 1s"
elif [ -n "$NOMATCH" ]; then echo "◆ 0 passed · 1s"
elif [ -n "$RANFAIL" ]; then echo "◆ 0 passed · ✗ 1 failed · 0 pending · 1s"; exit 1
else case "$*" in (*TheInputsHash*) echo "◆ 2 passed · 1s" ;; (*) echo "◆ 1 passed · 1s" ;; esac; fi
STUB
chmod +x "$tmp/bin/bayan"
printf '#!/bin/bash\necho "pinned ref=$PINNED_BAYAN_REF" >> "$LOG"\necho "$BIN/bayan"\n' > "$w/scripts/pinned-bayan.sh"
title='a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory'
grep -qxF "test \"$title\" {" "$root/src/driver/golden.byn" || fail "src/driver/golden.byn has no test block titled: $title"
export LOG="$tmp/log" BIN="$tmp/bin" BAYAN_EXE="$tmp/bin/bayan" PATH="$tmp/bin:$PATH" PENDING= NOMATCH= RANFAIL=

: > "$LOG"
FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err" || fail "an all-pass gate exited non-zero: $(cat "$tmp/err")"
grep -qx "memory-gate: PASS" "$tmp/out" || fail "an all-pass gate printed no PASS"
[ "$(wc -l < "$LOG" | tr -d ' ')" = 5 ] || fail "the gate did not run all 5 commands: $(cat "$LOG")"
grep -qxF "bayan timeout= test tests/cases --only cli/SelfhostDefaultT12Tests/TheInputsHashDoesNotFollowLinks" "$LOG" || fail "the gate did not run the T12 inputs-hash cases: $(cat "$LOG")"
grep -qxF "bayan timeout=1800000 shard=1/12 test --package src src/driver --only $title" "$LOG" || fail "the golden runner bound did not run on shard 1/12 with a 30 minute timeout: $(cat "$LOG")"
grep -qE "^bayan timeout=[0-9]* test --package src src/driver --only bound: $" "$LOG" || fail "the gate did not run the bound: blocks: $(cat "$LOG")"
! grep -q 'dotnet' <(grep -v '^#' "$gate") || fail "memory-gate.sh still runs dotnet"
grep -qxF "bayan timeout= test --package editors/language-server/src editors/language-server/src/bounds" "$LOG" || fail "the gate did not run the bayan-lsp bounds: $(cat "$LOG")"
! grep -qE 'CliMemoryBounds|SelfhostDefaultBounds' "$gate" || fail "memory-gate.sh still runs the .NET bound tests"
grep -q '^test "bound: ' "$root/src/driver/bounds.byn" || fail "src/driver/bounds.byn has no test block titled bound: ..."

: > "$LOG"
if FAIL_ON="bound: " bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err"; then fail "a failing bound: run passed the gate"; fi
grep -q "FAILED: $BAYAN_EXE test --package src src/driver --only bound: " "$tmp/err" || fail "the failing command was not named: $(cat "$tmp/err")"
[ "$(wc -l < "$LOG" | tr -d ' ')" = 5 ] || fail "a failure stopped the remaining gate commands: $(cat "$LOG")"
! grep -q PASS "$tmp/out" || fail "a failing gate printed PASS"

: > "$LOG"
if FAIL_ON=pinned bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failing pinned-bayan test passed the gate"; fi
grep -q "FAILED: bash scripts/pinned-bayan.test.sh" "$tmp/err" || fail "the pinned-bayan failure was not named"

: > "$LOG"
if FAIL_ON="--only" bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failing golden runner bound passed the gate"; fi
grep -q "FAILED: env BAYAN_GOLDEN_BOUND_SHARD=1/12 BAYAN_TEST_TIMEOUT_MS=1800000 $BAYAN_EXE test --package src src/driver --only $title" "$tmp/err" || fail "the golden runner bound failure was not named: $(cat "$tmp/err")"

# --full: the full tree (no shard) with the caller's timeout; refused without one.
: > "$LOG"
BAYAN_TEST_TIMEOUT_MS=18000000 FAIL_ON= bash "$w/scripts/release/memory-gate.sh" --full > /dev/null 2> "$tmp/err" || fail "a --full gate exited non-zero: $(cat "$tmp/err")"
grep -qxF "bayan timeout=18000000 test --package src src/driver --only $title" "$LOG" || fail "--full did not run the bound over the full tree with the caller's timeout: $(cat "$LOG")"
if FAIL_ON= bash "$w/scripts/release/memory-gate.sh" --full > /dev/null 2> "$tmp/err"; then fail "--full with no BAYAN_TEST_TIMEOUT_MS passed"; fi
grep -q "full needs BAYAN_TEST_TIMEOUT_MS" "$tmp/err" || fail "--full with no timeout was not refused: $(cat "$tmp/err")"

# A bound that ran and failed is named once, as failed, and not as unmatched.
: > "$LOG"
if RANFAIL=1 FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failed golden runner bound passed the gate"; fi
[ "$(grep -c "FAILED: .*--only $title" "$tmp/err")" = 1 ] || fail "the failed golden runner bound was not named once: $(cat "$tmp/err")"
! grep -q "the golden runner bound did not run (no test matched)" "$tmp/err" || fail "a bound that ran and failed was reported as unmatched: $(cat "$tmp/err")"

: > "$LOG"
if PENDING=1 FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err"; then fail "a pending golden runner bound passed the gate"; fi
grep -q "FAILED: bayan-lsp bound blocks reported pending" "$tmp/err" || fail "the pending bayan-lsp bounds were not named: $(cat "$tmp/err")"
grep -q "FAILED: the golden runner bound reported pending" "$tmp/err" || fail "the pending golden runner bound was not named: $(cat "$tmp/err")"

: > "$LOG"
if NOMATCH=1 FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err"; then fail "a bound title that selects no test passed the gate"; fi
grep -q "FAILED: the golden runner bound did not run (no test matched)" "$tmp/err" || fail "the unmatched golden runner bound was not named: $(cat "$tmp/err")"
grep -q "FAILED: bayan-lsp bound blocks did not run (none passed)" "$tmp/err" || fail "the unrun bayan-lsp bounds were not named: $(cat "$tmp/err")"
grep -q "FAILED: the bound: blocks did not run (none passed)" "$tmp/err" || fail "the unmatched bound: blocks were not named: $(cat "$tmp/err")"
grep -q "FAILED: the T12 inputs-hash cases did not both pass" "$tmp/err" || fail "the unrun T12 inputs-hash cases were not named: $(cat "$tmp/err")"

# BAYAN_EXE unset: the gate builds src/driver with the pinned bayan at HEAD and runs the bound with that driver.
: > "$LOG"
env -u BAYAN_EXE FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err" || fail "a gate that built its driver exited non-zero: $(cat "$tmp/err")"
grep -qxF "pinned ref=HEAD" "$LOG" || fail "the gate did not ask for the pinned bayan at HEAD: $(cat "$LOG")"
grep -qxF "bayan timeout= build --mode safe --package src -o $w/tmp/memory-gate/bayan src/driver" "$LOG" || fail "the gate did not build src/driver: $(cat "$LOG")"
grep -qxF "bayan timeout=1800000 shard=1/12 test --package src src/driver --only $title" "$LOG" || fail "the built driver did not run the bound: $(cat "$LOG")"
[ "$(cat "$LOG.exe")" = "$w/tmp/memory-gate/bayan" ] || fail "the bound did not see the built driver in BAYAN_EXE: $(cat "$LOG.exe")"
: > "$LOG"
if BAYAN_EXE= FAIL_ON=build bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failed driver build passed the gate"; fi
grep -q "FAILED: build of src/driver for BAYAN_EXE" "$tmp/err" || fail "the failed driver build was not named: $(cat "$tmp/err")"

# Wiring: release.yml runs the gate in its own job and the draft release needs it.
grep -q '^  memory-gate:' "$wf" || fail "release.yml has no memory-gate job"
awk '/^  memory-gate:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" | grep -qE '^ +run: bash scripts/release/memory-gate.sh$' || fail "release.yml's memory-gate job does not run memory-gate.sh"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -q 'memory-gate' || fail "release.yml's release job does not need memory-gate"
echo PASS
