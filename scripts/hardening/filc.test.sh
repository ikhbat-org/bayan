#!/usr/bin/env bash
# Tests scripts/hardening/filc.sh with a fake driver (`test` passes; `build` writes a shell program per case) and a fake compiler:
# a case is a finding when its exit differs from its expected one and its own stderr names Fil-C.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/filc-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }

cat >"$tmp/driver" <<'F'
#!/bin/sh
if [ "$1" = test ]; then echo "passed run/fake"; exit 0; fi
# build --mode <m> -o <out> <src>
out=$5; src=$6
case "${src##*/}" in
    assert-plain.byn) body='echo "filc panic: out of bounds" >&2; exit 1' ;;
    assert-pass.byn) body='echo "filc safety error: x" >&2; exit 0' ;;
    assert-side-effect.byn) body='echo "plain failure" >&2; exit 1' ;;
    assert-and-right.byn) body='echo "filc user error: abort() called" >&2; echo "[1] filc panic: user thwarted themselves." >&2; exit 133' ;;
    assert-nested.byn) body='echo "filc safety error: cannot read pointer with ptr < lower." >&2; echo "filc user error: abort() called" >&2; exit 133' ;;
    *) body='exit 0' ;;
esac
printf '#!/bin/sh\n%s\n' "$body" >"$out"; chmod +x "$out"
F
chmod +x "$tmp/driver"
printf '#!/bin/sh\nexit 0\n' >"$tmp/cc"; chmod +x "$tmp/cc"

out=$(BAYAN_EXE="$tmp/driver" FILC_CC="$tmp/cc" bash "$root/scripts/hardening/filc.sh" --only run/assert- 2>&1); rc=$?
[ $rc = 0 ]; check "filc.sh exits 0 when it ran" $?
printf '%s\n' "$out" | grep -qx '  finding run/assert-plain'; check "a failing program with the marker on stderr is a finding" $?
printf '%s\n' "$out" | grep -q 'finding run/assert-pass'; [ $? != 0 ]; check "the marker with the expected exit is not a finding" $?
printf '%s\n' "$out" | grep -q 'finding run/assert-side-effect'; [ $? != 0 ]; check "a failing program without the marker is not a finding" $?
printf '%s\n' "$out" | grep -q 'finding run/assert-and-right'; [ $? != 0 ]; check "Fil-C's abort() (exit 133) where 134 is expected is not a finding" $?
printf '%s\n' "$out" | grep -qx '  finding run/assert-nested'; check "exit 133 after a Fil-C safety error is a finding" $?
printf '%s\n' "$out" | grep -q 'findings 2$'; check "the findings are counted" $?

echo "$pass passed, $failed failed"
[ $failed = 0 ]
