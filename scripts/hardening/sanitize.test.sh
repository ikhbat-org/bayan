#!/usr/bin/env bash
# Tests scripts/hardening/sanitize.sh against a fake bayan driver, a fake runtime/tests/run.sh and a fake setarch in a temporary
# directory under tmp/, with HARDEN_DIR there too. SANITIZE_SH overrides the script under test.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
san="${SANITIZE_SH:-$root/scripts/hardening/sanitize.sh}"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/sanitize-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/out"
export HARDEN_DIR="$tmp/out" HARDEN_RUNSH="$tmp/run.sh" HARDEN_CC=true
unset HARDEN_FSIZE HARDEN_SETARCH

# setarch: records its arguments, marks the environment and runs the command after <arch> -R.
cat >"$tmp/bin/setarch" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$tmp/setarch.args"
shift 2
SETARCH_SEEN=1 exec "\$@"
STUB
# The driver and run.sh record the file-size limit and whether they started under setarch.
cat >"$tmp/bayan" <<STUB
#!/bin/sh
echo "golden \$(ulimit -f) \${SETARCH_SEEN:-0}" >>"$tmp/seen"
echo "passed run/a"
STUB
cat >"$tmp/run.sh" <<STUB
echo "runtime \$(ulimit -f) \${SETARCH_SEEN:-0}" >>"$tmp/seen"
echo "ok a.c"
echo "FAIL b.c: differs"
STUB
chmod +x "$tmp/bin/setarch" "$tmp/bayan"
export BAYAN_EXE="$tmp/bayan"

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }
has() { printf '%s\n' "$1" | grep -qxF -- "$2"; }

out=$(HARDEN_SETARCH="$tmp/bin/setarch" HARDEN_FSIZE=12345 bash "$san" --asan 2>&1); rc=$?
[ $rc = 0 ]; check "--asan exits 0" $?
has "$out" "asan: golden 1 passed, 0 failed; runtime 1 ok, 1 failed; findings 0"; check "counts per cell" $?
has "$out" "  runtime failed b.c"; check "names the failing runtime test" $?
has "$(cat "$tmp/seen")" "golden 12345 1"; check "the golden runner starts under setarch -R with the file-size cap" $?
has "$(cat "$tmp/seen")" "runtime 12345 1"; check "run.sh starts under setarch -R with the file-size cap (ASan DEADLYSIGNAL loop, 2026-11-27)" $?
grep -qx -- "$(uname -m) -R env.*" "$tmp/setarch.args"; check "setarch gets <arch> -R before the runner" $?

rm -f "$tmp/seen"
out=$(HARDEN_SETARCH="$tmp/no-such-setarch" bash "$san" --asan 2>&1); rc=$?
[ $rc = 0 ]; check "runs without setarch" $?
has "$(cat "$tmp/seen")" "golden 2000000 0"; check "no setarch: the golden runner runs plainly, default cap 2000000" $?
has "$(cat "$tmp/seen")" "runtime 2000000 0"; check "no setarch: run.sh runs plainly, default cap 2000000" $?

echo "$pass passed, $failed failed"
[ $failed = 0 ]
