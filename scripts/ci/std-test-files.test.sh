#!/usr/bin/env bash
# Ported from StdTestFilesTests (spec 019 T26): for each lib/std/<module>,
#   module-tests-pass            `bayan test lib/std/<module>` exits 0 and reports at least one passed test (each test runs in
#                                its own process, as the C# harness-build test ran it: module-tests-pass-in-a-harness-build)
#   importing-the-module-compiles-clean   a package with `import std.<module>` passes `bayan check` (the shipped source passes the
#                                <std> checks, which compiling the module as the entry package never runs)
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
fail() { echo "FAIL $1"; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$root/tmp/std-test-files-bayan"
  cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan" || fail "cannot build bootstrap/bayan.c"
fi
n=0
for d in lib/std/*/; do
  m="$(basename "$d")"
  rc=0; out="$("$bayan" test "lib/std/$m" 2>&1)" || rc=$?
  [ "$rc" = 0 ] || fail "module-tests-pass $m: exit $rc: $out"
  grep -Eq '[1-9][0-9]* passed' <<<"$out" || fail "module-tests-pass $m: no passed test in: $out"
  p="$root/tmp/std-import/$m"; rm -rf "$p"; mkdir -p "$p"
  printf 'import std.%s\nprint("x")\n' "$m" > "$p/main.byn"
  rc=0; out="$("$bayan" check "$p/main.byn" 2>&1)" || rc=$?
  [ "$rc" = 0 ] || fail "importing-the-module-compiles-clean $m: exit $rc: $out"
  n=$((n + 1))
done
[ "$n" -gt 0 ] || fail "no module under lib/std"
echo "std-test-files: ok ($n modules)"
