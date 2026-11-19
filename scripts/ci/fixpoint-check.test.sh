#!/usr/bin/env bash
# Tests scripts/ci/fixpoint-check.sh: `--compare` on given files (nothing is built): equal files pass; one differing byte
# fails naming the mode and the line; the repo root, $HOME or $TMPDIR in a file fails naming the file and line; a rooted
# `#line` file fails; today's date or __DATE__ fails. With no stage 1 in a scratch copy, the full run fails saying so.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check="$root/scripts/ci/fixpoint-check.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/fixpoint-check-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }
run() { HOME=/home/fixpoint-test TMPDIR=/var/fixpoint-tmp/ bash "$check" "$@" > "$tmp/out" 2>&1 && echo pass || echo fail; }

c() { printf '#line 1 "driver/main.byn"\nint a;\n%s\nint b;\n' "$1"; }
c 'int x;' > "$tmp/a.c"; cp "$tmp/a.c" "$tmp/b.c"
[ "$(run --compare safe "$tmp/a.c" "$tmp/b.c")" = pass ] || fail "equal files failed" "$(cat "$tmp/out")"

# one byte differs on line 3
c 'int y;' > "$tmp/b.c"
[ "$(run --compare debug "$tmp/a.c" "$tmp/b.c")" = fail ] || fail "a differing byte passed" "$(cat "$tmp/out")"
grep -q 'FAIL debug: .* differ at line 3$' "$tmp/out" && grep -q 'b.c: int y;' "$tmp/out" && grep -q 'a.c: int x;' "$tmp/out" \
  || fail "the difference did not name the mode, line and both sides" "$(cat "$tmp/out")"

# absolute paths: the repo root, $HOME, $TMPDIR, a rooted #line file
for p in "$root/src/driver/main.byn" /home/fixpoint-test/x /var/fixpoint-tmp/y; do
  c "char *p = \"$p\";" > "$tmp/b.c"; c "char *p = \"$p\";" > "$tmp/a.c"
  [ "$(run --compare safe "$tmp/a.c" "$tmp/b.c")" = fail ] || fail "an absolute path $p passed" "$(cat "$tmp/out")"
  grep -q "FAIL $tmp/a.c:3: holds '" "$tmp/out" || fail "the path $p was not named with file and line" "$(cat "$tmp/out")"
done
printf '#line 1 "/src/driver/main.byn"\nint a;\n' > "$tmp/a.c"; cp "$tmp/a.c" "$tmp/b.c"
[ "$(run --compare safe "$tmp/a.c" "$tmp/b.c")" = fail ] || fail "a rooted #line passed" "$(cat "$tmp/out")"
grep -q "FAIL $tmp/a.c:1: a #line names a rooted file" "$tmp/out" || fail "the rooted #line was not named" "$(cat "$tmp/out")"

# timestamps: today's date, __DATE__
for s in "$(date +%Y-%m-%d) 10:00" __DATE__; do
  c "char *t = \"$s\";" > "$tmp/a.c"; cp "$tmp/a.c" "$tmp/b.c"
  [ "$(run --compare safe "$tmp/a.c" "$tmp/b.c")" = fail ] || fail "a timestamp $s passed" "$(cat "$tmp/out")"
  grep -q "FAIL $tmp/a.c:3: holds '" "$tmp/out" || fail "the timestamp $s was not named with file and line" "$(cat "$tmp/out")"
done

# no stage 1: a scratch copy of the script, with no tmp/bootstrap-check/
mkdir -p "$tmp/repo/scripts/ci"; cp "$check" "$tmp/repo/scripts/ci/"
check="$tmp/repo/scripts/ci/fixpoint-check.sh"
[ "$(run)" = fail ] || fail "a missing stage 1 passed" "$(cat "$tmp/out")"
grep -q 'FAIL no stage 1 at tmp/bootstrap-check/bayan; run scripts/ci/bootstrap-check.sh first' "$tmp/out" \
  || fail "a missing stage 1 was not named" "$(cat "$tmp/out")"
[ ! -e "$tmp/repo/tmp/fixpoint-check" ] || fail "a missing stage 1 still wrote tmp/fixpoint-check/"
echo "fixpoint-check.test: ok"
