#!/usr/bin/env bash
# Builds the self-hosted compiler from the bootstrap with no .NET (spec 019 R24, T40).
#   bash scripts/bootstrap-build.sh [--out DIR]
# Stage 0: bootstrap/bayan.c + bootstrap/bayan-rt.c with a C compiler ($CC, else cc, else zig cc), the flags of README.md
#          (the `safe` ones of src/driver/cc.byn); -lshell32 instead of -lm on Windows, as runtime/tests/run.sh.
# Stage 1: stage 0 builds src/driver: `<stage0> build --mode safe --package src -o <stage1> src/driver`, as scripts/test.sh.
# DIR (default <root>/tmp/bootstrap-build) gets bayan-stage0 and bayan-stage1 (.exe on Windows) and the stage logs. Prints
# the stage-1 path on success; exit 1 names the failed stage, 2 is a usage error or no C compiler. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

out="$root/tmp/bootstrap-build"
while [ $# -gt 0 ]; do
  case "$1" in
    (--out) [ $# -ge 2 ] && [ -n "$2" ] || { echo "bootstrap-build.sh: --out expects a directory" >&2; exit 2; }; out=$2; shift 2 ;;
    (*) echo "bootstrap-build.sh: unexpected argument '$1' (--out DIR)" >&2; exit 2 ;;
  esac
done

exe=""; lib=-lm
case "$(uname -s)" in (MINGW*|MSYS*|CYGWIN*) exe=.exe; lib=-lshell32 ;; esac

if [ -n "${CC:-}" ]; then cc=($CC)
elif [ -z "$exe" ] && command -v cc >/dev/null 2>&1; then cc=(cc)
elif command -v zig >/dev/null 2>&1; then cc=(zig cc)
elif command -v cc >/dev/null 2>&1; then cc=(cc)
else echo "bootstrap-build.sh: no C compiler: set CC, or install cc or zig" >&2; exit 2
fi

mkdir -p "$out" || exit 2
s0="$out/bayan-stage0$exe"; s1="$out/bayan-stage1$exe"
rm -f "$s0" "$s1"

if ! "${cc[@]}" -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c "$lib" -o "$s0" >"$out/stage0.log" 2>&1; then
  echo "bootstrap-build.sh: stage 0 failed (C compile of bootstrap/bayan.c); log: $out/stage0.log" >&2; exit 1
fi
if ! "$s0" build --mode safe --package src -o "$s1" src/driver >"$out/stage1.log" 2>&1; then
  echo "bootstrap-build.sh: stage 1 failed (stage 0 building src/driver); log: $out/stage1.log" >&2; exit 1
fi
echo "$s1"
