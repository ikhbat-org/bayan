#!/usr/bin/env bash
# Tests scripts/hardening/cc-wrap.sh against a fake real compiler that prints its arguments one per line (and a version line for
# --version) and exits $FAKE_RC. CC_WRAP overrides the wrapper under test.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wrap="${CC_WRAP:-$root/scripts/hardening/cc-wrap.sh}"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/cc-wrap-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/fakecc" <<'STUB'
#!/bin/sh
for a in "$@"; do
    [ "$a" = --version ] && echo "fakecc 1.0"
    echo "arg:$a"
done
exit "${FAKE_RC:-0}"
STUB
chmod +x "$tmp/fakecc"
export HARDEN_CC="$tmp/fakecc"
unset HARDEN_CFLAGS HARDEN_COMPILE_ONLY HARDEN_STRIP FAKE_RC

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }
has() { printf '%s\n' "$1" | grep -qxF -- "$2"; }

out=$(HARDEN_STRIP="-w -fwrapv" sh "$wrap" -w -Wall -fno-wrapv -fwrapv x.c)
has "$out" "arg:-w"; [ $? != 0 ]; check "strip -w drops the exact -w" $?
has "$out" "arg:-Wall"; check "strip -w keeps -Wall" $?
has "$out" "arg:-fno-wrapv"; check "strip -w keeps -fno-wrapv, which contains it" $?
has "$out" "arg:-fwrapv"; [ $? != 0 ]; check "strip drops every listed argument" $?
[ "$(printf '%s\n' "$out" | tr '\n' ' ')" = "arg:-Wall arg:-fno-wrapv arg:x.c " ]; check "kept arguments stay in order" $?

out=$(HARDEN_CFLAGS=-fsanitize=undefined HARDEN_COMPILE_ONLY=-DONLY_C sh "$wrap" -c x.c -o x.o)
has "$out" "arg:-DONLY_C"; check "compile-only flags appear with -c" $?
has "$out" "arg:-fsanitize=undefined"; check "extra flags appear with -c" $?
out=$(HARDEN_CFLAGS=-fsanitize=undefined HARDEN_COMPILE_ONLY=-DONLY_C sh "$wrap" x.c x.o -o x)
has "$out" "arg:-DONLY_C"; [ $? != 0 ]; check "compile-only flags do not appear without -c" $?
has "$out" "arg:-fsanitize=undefined"; check "extra flags appear on the link" $?

out=$(HARDEN_CFLAGS=-fsanitize=address HARDEN_STRIP=-w sh "$wrap" --version)
has "$out" "fakecc 1.0"; check "--version prints the real compiler's version" $?
has "$out" "cc-wrap: extra=-fsanitize=address compile-only= strip=-w"; check "--version carries the cc-wrap line" $?

FAKE_RC=7 sh "$wrap" x.c >/dev/null; [ $? = 7 ]; check "exit status passes through" $?
FAKE_RC=5 sh "$wrap" --version >/dev/null; [ $? = 5 ]; check "--version exit status passes through" $?

echo "$pass passed, $failed failed"
[ $failed = 0 ]
