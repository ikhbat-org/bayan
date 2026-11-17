#!/usr/bin/env bash
# The two recorder tests exit 0 with a `skipped:` line naming the reason under a fake uname printing Linux, and under a
# PATH holding only a fake arm64 macOS uname (no otool), so the Linux ci job and a host without the tools pass them.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/sabk-record-skip-test"
rm -rf "$t" && mkdir -p "$t/linux" "$t/bare"
trap 'rm -rf "$t"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
printf '#!/bin/sh\necho Linux\n' > "$t/linux/uname"
printf '#!/bin/sh\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n' > "$t/bare/uname"
chmod +x "$t/linux/uname" "$t/bare/uname"

for name in record-encodings record-macho; do
  test="$root/scripts/sabk/$name.test.sh"
  rc=0; out="$(PATH="$t/linux:$PATH" "$BASH" "$test" 2>&1)" || rc=$?
  [ $rc = 0 ] || fail "$name.test under Linux exited $rc: $out"
  [ "$out" = "$name.test: skipped: not macOS (Linux)" ] || fail "$name.test under Linux printed: $out"
  rc=0; out="$(PATH="$t/bare" "$BASH" "$test" 2>&1)" || rc=$?
  [ $rc = 0 ] || fail "$name.test without otool exited $rc: $out"
  [ "$out" = "$name.test: skipped: otool not on PATH" ] || fail "$name.test without otool printed: $out"
done
echo "record-skip.test: all passed"
