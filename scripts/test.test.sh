#!/usr/bin/env bash
# Tests scripts/test.sh with each part replaced by a stub (TEST_SH_*): all passing exits 0 with one pass line per part;
# one failing exits 1 naming it, after the parts behind it ran; --jobs reaches the golden part; --only runs one part;
# --skip golden runs the others; --shard i/n reaches only the golden part as BAYAN_TEST_SHARD; a bad --jobs, --only, --skip
# or --shard exits 2; the default zig cache's o/ is trimmed to 2000 entries, a caller-set one is not.
# No driver is built: every part is stubbed.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
s="$root/scripts/test.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/test-sh-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# stub <name> <exit>: records its arguments in $tmp/<name>.args and exits <exit>.
stub() { printf '#!/bin/sh\necho "$@" > "%s/%s.args"\nexit %s\n' "$tmp" "$1" "$2" > "$tmp/$1"; chmod +x "$tmp/$1"; }
for p in golden bayan parity scripts runtime; do stub "$p" 0; done
export TEST_SH_GOLDEN="$tmp/golden" TEST_SH_BAYAN="$tmp/bayan" TEST_SH_PARITY="$tmp/parity" TEST_SH_SCRIPTS="$tmp/scripts" TEST_SH_RUNTIME="$tmp/runtime"
unset BAYAN_EXE

rc=0; out="$("$BASH" "$s" --jobs 3 2>&1)" || rc=$?
[ $rc = 0 ] || fail "all parts passing exited $rc: $out"
for p in golden bayan parity scripts runtime; do
  [ "$(grep -c "^test: $p  *pass " <<<"$out")" = 1 ] || fail "no one pass line for $p: $out"
done
[ "$(cat "$tmp/golden.args")" = "--jobs 3" ] || fail "--jobs 3 did not reach the golden part: $(cat "$tmp/golden.args")"

rm -f "$tmp"/*.args; stub bayan 1
rc=0; out="$("$BASH" "$s" --jobs 2 2>&1)" || rc=$?
logs="$(sed -n 's#.*log: \(.*\)/bayan\.log).*#\1#p' <<<"$out")"; case "$logs" in "$root"/tmp/test.*) rm -rf "$logs" ;; esac
[ $rc = 1 ] || fail "a failing part exited $rc, not 1: $out"
grep -q '^test: bayan  *FAIL ' <<<"$out" || fail "the failing part has no FAIL line: $out"
grep -qx 'test: FAILED bayan' <<<"$out" || fail "the failing part is not named at the end: $out"
[ -f "$tmp/parity.args" ] && [ -f "$tmp/scripts.args" ] && [ -f "$tmp/runtime.args" ] || fail "the parts after a failing one did not run: $out"

rm -f "$tmp"/*.args; stub bayan 0
printf '#!/bin/sh\necho "failed run/early-case"\necho "  ✗ a test block"\nseq 1 30\nexit 3\n' > "$tmp/golden"; chmod +x "$tmp/golden"
rc=0; out="$("$BASH" "$s" --only golden 2>&1)" || rc=$?
logs="$(sed -n 's#.*log: \(.*\)/golden\.log).*#\1#p' <<<"$out")"; case "$logs" in "$root"/tmp/test.*) rm -rf "$logs" ;; esac
grep -qx '    failed run/early-case' <<<"$out" || fail "a failed case above the log's last 20 lines is not printed: $out"
grep -qx '      ✗ a test block' <<<"$out" || fail "a failed test block above the log's last 20 lines is not printed: $out"
stub golden 0

rm -f "$tmp"/*.args
rc=0; out="$("$BASH" "$s" --only runtime --jobs 5 2>&1)" || rc=$?
[ $rc = 0 ] || fail "--only runtime exited $rc: $out"
[ -f "$tmp/runtime.args" ] && [ ! -f "$tmp/golden.args" ] && [ ! -f "$tmp/bayan.args" ] && [ ! -f "$tmp/parity.args" ] && [ ! -f "$tmp/scripts.args" ] \
  || fail "--only runtime ran another part: $out"

# --skip golden runs the other four parts; --shard i/n reaches the golden part as BAYAN_TEST_SHARD and no other part, a caller's
# value included (the bayan part's test blocks start the runner).
rm -f "$tmp"/*.args
rc=0; out="$("$BASH" "$s" --skip golden 2>&1)" || rc=$?
[ $rc = 0 ] && [ ! -f "$tmp/golden.args" ] && ! grep -q '^test: golden ' <<<"$out" || fail "--skip golden ran the golden part (exit $rc): $out"
for p in bayan parity scripts runtime; do
  [ -f "$tmp/$p.args" ] || fail "--skip golden did not run $p: $out"
done
for p in golden bayan parity scripts runtime; do
  printf '#!/bin/sh\necho "${BAYAN_TEST_SHARD-unset}" > "%s/%s.shard"\n' "$tmp" "$p" > "$tmp/$p"; chmod +x "$tmp/$p"
done
rc=0; out="$(BAYAN_TEST_SHARD=9/9 "$BASH" "$s" --shard 2/5 2>&1)" || rc=$?
[ $rc = 0 ] || fail "--shard 2/5 exited $rc: $out"
[ "$(cat "$tmp/golden.shard")" = 2/5 ] || fail "the golden part saw BAYAN_TEST_SHARD=$(cat "$tmp/golden.shard"), not 2/5"
for p in bayan parity scripts runtime; do
  [ "$(cat "$tmp/$p.shard")" = unset ] || fail "the $p part saw BAYAN_TEST_SHARD=$(cat "$tmp/$p.shard")"
done
grep -q '^test: golden  *pass .*shard 2/5' <<<"$out" || fail "the golden summary line does not name the shard: $out"
for v in 0/4 5/4 a/b 3 /4 4/ 1/65 1/3/3 ""; do
  rc=0; out="$("$BASH" "$s" --shard "$v" --only golden 2>&1)" || rc=$?
  if [ -z "$v" ]; then
    [ $rc = 0 ] || fail "an empty --shard exited $rc: $out"
  else
    [ $rc = 2 ] && grep -q "^test.sh: --shard expects i/n" <<<"$out" || fail "--shard '$v' exited $rc: $out"
  fi
done
rc=0; "$BASH" "$s" --skip nope >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "--skip nope exited $rc, not 2"
for p in golden bayan parity scripts runtime; do stub "$p" 0; done


printf '#!/bin/sh\necho "$ZIG_GLOBAL_CACHE_DIR" > "%s/zig.dir"\n' "$tmp" > "$tmp/runtime"; chmod +x "$tmp/runtime"
rc=0; (unset ZIG_GLOBAL_CACHE_DIR; "$BASH" "$s" --only runtime >/dev/null 2>&1) || rc=$?
[ $rc = 0 ] && [ "$(cat "$tmp/zig.dir")" = "$root/tmp/zig-global" ] || fail "an unset ZIG_GLOBAL_CACHE_DIR is not tmp/zig-global: $(cat "$tmp/zig.dir")"
rc=0; ZIG_GLOBAL_CACHE_DIR="$tmp/own-zig" "$BASH" "$s" --only runtime >/dev/null 2>&1 || rc=$?
[ $rc = 0 ] && [ "$(cat "$tmp/zig.dir")" = "$tmp/own-zig" ] || fail "a set ZIG_GLOBAL_CACHE_DIR was replaced: $(cat "$tmp/zig.dir")"
stub runtime 0

# the default zig cache's o/ is trimmed to the newest 2000 entries, keeping one written in the last 10 minutes; a copy of
# test.sh under $tmp/fake makes $tmp/fake/tmp/zig-global the default, so the checkout's own cache is not touched. Entries hold
# a main.o; rt, the oldest, holds zig's libcompiler_rt.a and is kept (laws-nightly 44901747519).
mkdir -p "$tmp/fake/scripts" "$tmp/fake/tmp/zig-global/o" "$tmp/own-zig/o"; cp "$s" "$tmp/fake/scripts/test.sh"
(cd "$tmp/fake/tmp/zig-global/o" && seq 1 2001 | xargs mkdir && seq 1 2001 | sed 's#$#/main.o#' | xargs touch \
  && mkdir rt && touch rt/libcompiler_rt.a && touch -t 202001010000 * && touch -t 201901010000 rt && mkdir new)
(cd "$tmp/own-zig/o" && seq 1 2001 | xargs mkdir && touch -t 202001010000 *)
# h/ manifests name inputs, not o/ entries: one naming main.c must go with the trim (else a hit fails FileNotFound), one
# naming only zig's own sources stays.
mkdir -p "$tmp/fake/tmp/zig-global/h"
printf '0 1 2 abc /w/tmp/x/main.c\n' > "$tmp/fake/tmp/zig-global/h/prog.txt"
printf '0 1 2 abc /zig/lib/compiler_rt.zig\n' > "$tmp/fake/tmp/zig-global/h/rt.txt"
rc=0; (unset ZIG_GLOBAL_CACHE_DIR; "$BASH" "$tmp/fake/scripts/test.sh" --only runtime >/dev/null 2>&1) || rc=$?
[ ! -e "$tmp/fake/tmp/zig-global/h/prog.txt" ] || fail "a zig manifest naming main.c outlived the o/ trim"
[ -f "$tmp/fake/tmp/zig-global/h/rt.txt" ] || fail "a zig manifest naming only zig's sources was removed"
[ $rc = 0 ] || fail "test.sh with an old zig cache exited $rc"
[ "$(ls -A "$tmp/fake/tmp/zig-global/o" | wc -l | tr -d ' ')" = 2001 ] || fail "the default zig cache's o/ has $(ls -A "$tmp/fake/tmp/zig-global/o" | wc -l) entries, not 2001"
[ -d "$tmp/fake/tmp/zig-global/o/new" ] || fail "an o/ entry written in the last 10 minutes was trimmed"
[ -f "$tmp/fake/tmp/zig-global/o/rt/libcompiler_rt.a" ] || fail "the o/ entry holding zig's libcompiler_rt.a was trimmed"
rc=0; ZIG_GLOBAL_CACHE_DIR="$tmp/own-zig" "$BASH" "$s" --only runtime >/dev/null 2>&1 || rc=$?
[ $rc = 0 ] && [ "$(ls -A "$tmp/own-zig/o" | wc -l | tr -d ' ')" = 2001 ] || fail "a caller-set ZIG_GLOBAL_CACHE_DIR was trimmed (exit $rc)"
rc=0; "$BASH" "$s" --jobs 0 >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "--jobs 0 exited $rc, not 2"
rc=0; "$BASH" "$s" --only nope >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "--only nope exited $rc, not 2"
echo "test.test: all passed"
