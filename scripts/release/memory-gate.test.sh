#!/usr/bin/env bash
# Tests scripts/release/memory-gate.sh: it runs every command of docs/memory-leaks.md's *Release gate* block, reports
# each failure and exits 1 on any, and release.yml cannot draft a release without it passing.
set -euo pipefail

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
# A stub driver: logs its timeout and arguments, fails on FAIL_ON, reports the block pending when PENDING is set.
cat > "$tmp/bin/bayan" <<'STUB'
#!/bin/bash
echo "bayan timeout=$BAYAN_TEST_TIMEOUT_MS $*" >> "$LOG"
case "$*" in *"$FAIL_ON"*) [ -n "$FAIL_ON" ] && exit 1 ;; esac
[ "$1" = build ] && { cp "$0" "${@: -2:1}"; exit 0; }
if [ -n "$PENDING" ]; then echo "  ◆ driver: $6 (pending)"; echo "◆ 0 passed · 1 pending · 1s"; else echo "◆ 1 passed · 1s"; fi
STUB
chmod +x "$tmp/bin/bayan"
printf '#!/bin/bash\necho "pinned ref=$PINNED_BAYAN_REF" >> "$LOG"\necho "$BIN/bayan"\n' > "$w/scripts/pinned-bayan.sh"
title='a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory'
grep -qxF "test \"$title\" {" "$root/src/driver/golden.byn" || fail "src/driver/golden.byn has no test block titled: $title"
export LOG="$tmp/log" BIN="$tmp/bin" BAYAN_EXE="$tmp/bin/bayan" PATH="$tmp/bin:$PATH"

: > "$LOG"
FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err" || fail "an all-pass gate exited non-zero: $(cat "$tmp/err")"
grep -qx "memory-gate: PASS" "$tmp/out" || fail "an all-pass gate printed no PASS"
[ "$(wc -l < "$LOG" | tr -d ' ')" = 5 ] || fail "the gate did not run all 5 commands: $(cat "$LOG")"
grep -qxF "bayan timeout=600000 test --package src src/driver --only $title" "$LOG" || fail "the golden runner bound did not run with a 10 minute timeout: $(cat "$LOG")"

: > "$LOG"
if FAIL_ON=CliMemoryBounds bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err"; then fail "a failing CliMemoryBounds run passed the gate"; fi
grep -q "FAILED: dotnet test -v q --filter FullyQualifiedName~CliMemoryBounds" "$tmp/err" || fail "the failing command was not named: $(cat "$tmp/err")"
[ "$(wc -l < "$LOG" | tr -d ' ')" = 5 ] || fail "a failure stopped the remaining gate commands: $(cat "$LOG")"
! grep -q PASS "$tmp/out" || fail "a failing gate printed PASS"

: > "$LOG"
if FAIL_ON=pinned bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failing pinned-bayan test passed the gate"; fi
grep -q "FAILED: bash scripts/pinned-bayan.test.sh" "$tmp/err" || fail "the pinned-bayan failure was not named"

: > "$LOG"
if FAIL_ON="--only" bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failing golden runner bound passed the gate"; fi
grep -q "FAILED: env BAYAN_TEST_TIMEOUT_MS=600000 $BAYAN_EXE test --package src src/driver --only $title" "$tmp/err" || fail "the golden runner bound failure was not named: $(cat "$tmp/err")"

: > "$LOG"
if PENDING=1 FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > "$tmp/out" 2> "$tmp/err"; then fail "a pending golden runner bound passed the gate"; fi
grep -q "FAILED: the golden runner bound reported pending" "$tmp/err" || fail "the pending golden runner bound was not named: $(cat "$tmp/err")"

# BAYAN_EXE unset: the gate builds src/driver with the pinned bayan at HEAD and runs the bound with that driver.
: > "$LOG"
BAYAN_EXE= FAIL_ON= bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err" || fail "a gate that built its driver exited non-zero: $(cat "$tmp/err")"
grep -qxF "pinned ref=HEAD" "$LOG" || fail "the gate did not ask for the pinned bayan at HEAD: $(cat "$LOG")"
grep -qxF "bayan timeout= build --mode safe --package src -o $w/tmp/memory-gate/bayan src/driver" "$LOG" || fail "the gate did not build src/driver: $(cat "$LOG")"
grep -qxF "bayan timeout=600000 test --package src src/driver --only $title" "$LOG" || fail "the built driver did not run the bound: $(cat "$LOG")"
: > "$LOG"
if BAYAN_EXE= FAIL_ON=build bash "$w/scripts/release/memory-gate.sh" > /dev/null 2> "$tmp/err"; then fail "a failed driver build passed the gate"; fi
grep -q "FAILED: build of src/driver for BAYAN_EXE" "$tmp/err" || fail "the failed driver build was not named: $(cat "$tmp/err")"

# Wiring: release.yml runs the gate in its own job and the draft release needs it.
grep -q '^  memory-gate:' "$wf" || fail "release.yml has no memory-gate job"
awk '/^  memory-gate:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" | grep -qE '^ +run: bash scripts/release/memory-gate.sh$' || fail "release.yml's memory-gate job does not run memory-gate.sh"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -q 'memory-gate' || fail "release.yml's release job does not need memory-gate"
echo PASS
