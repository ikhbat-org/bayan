#!/usr/bin/env bash
# L027 (bootstrap fixpoint), the stage 1/stage 2 half, with no .NET (spec 019 T31): for src/driver in each of `safe` and
# `debug`, the C stage 1 emits and the C stage 2 emits are byte-identical, and hold no absolute path and no timestamp.
#   bash scripts/ci/fixpoint-check.sh                          (after scripts/ci/bootstrap-check.sh)
#   bash scripts/ci/fixpoint-check.sh --compare MODE A.c B.c   (the compare and the scan alone, for tests)
# Stage 1 is tmp/bootstrap-check/bayan, the one bootstrap-check.sh leaves. Stage 1 builds stage 2
# (`build --package src -o <exe> src/driver`); each emits `build --emit-c --mode MODE --package src src/driver`, and stage 1
# emits twice (BootstrapTests' C1IsReproducibleAndHasNoAbsolutePath). A difference prints the mode, the first differing
# line and that line from each side. The scan, ported from BootstrapTests: the repo root (with `/`, `\` and `\\`), $HOME and
# $TMPDIR (skipped when unset or `/tmp`: the driver names "/tmp/" as a fallback) as text, and a `#line` naming a rooted file;
# for a timestamp, __DATE__, __TIME__, __TIMESTAMP__, and today's date (local and UTC) as `YYYY-MM-DD` and as __DATE__ writes
# it. Everything goes under tmp/fixpoint-check/ (BAYAN_CACHE too). The frozen-tree half of L027 runs in the ddc job
# (scripts/ci/ddc.sh, scripts/ci/ddc-laws.txt). Exit 0 when it holds, 1 with the counterexample, 2 on a usage error. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2

# the first differing line of $2 and $3 in mode $1; returns 1 after printing it
compare() {
  cmp -s "$2" "$3" && return 0
  line=$(awk 'NR == FNR { a[FNR] = $0; n = FNR; next }
    { if (FNR > n || a[FNR] != $0) { print FNR; found = 1; exit } m = FNR }
    END { if (!found) print (m < n ? m + 1 : m) }' "$2" "$3")
  echo "fixpoint-check: FAIL $1: $2 and $3 differ at line $line"
  echo "  $2: $(sed -n "${line}p" "$2" | cut -c1-200)"
  echo "  $3: $(sed -n "${line}p" "$3" | cut -c1-200)"
  return 1
}

# an absolute path or a timestamp in $1; returns 1 after naming the file, line and match
scan() {
  needles=()
  r=${root%/}; [ -z "$r" ] || needles+=("$r" "$(printf '%s' "$r" | tr / '\\')" "$(printf '%s' "$r" | sed 's#/#\\\\#g')")
  h=${HOME:-}; h=${h%/}; [ -z "$h" ] || needles+=("$h")
  t=${TMPDIR:-}; t=${t%/}; [ -z "$t" ] || [ "$t" = /tmp ] || needles+=("$t")
  needles+=(__DATE__ __TIME__ __TIMESTAMP__ "$(date +%Y-%m-%d)" "$(date -u +%Y-%m-%d)" "$(date '+%b %e %Y')" "$(date -u '+%b %e %Y')")
  for n in "${needles[@]}"; do
    hit=$(grep -nF -m1 -- "$n" "$1" || true)
    [ -z "$hit" ] || { echo "fixpoint-check: FAIL $1:${hit%%:*}: holds '$n' (an absolute path or a timestamp)"; return 1; }
  done
  hit=$(grep -nE -m1 '^#line [0-9]+ "([A-Za-z]:|[/\\])' "$1" || true)
  [ -z "$hit" ] || { echo "fixpoint-check: FAIL $1:${hit%%:*}: a #line names a rooted file: $(printf '%s' "${hit#*:}" | cut -c1-200)"; return 1; }
  return 0
}

if [ "${1:-}" = --compare ]; then
  [ $# = 4 ] || { echo "usage: fixpoint-check.sh [--compare MODE A.c B.c]" >&2; exit 2; }
  ok=0; compare "$2" "$3" "$4" || ok=1; scan "$3" || ok=1; scan "$4" || ok=1
  exit $ok
fi
[ $# = 0 ] || { echo "usage: fixpoint-check.sh [--compare MODE A.c B.c]" >&2; exit 2; }

exe=bayan; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) exe=bayan.exe ;; esac
s1="tmp/bootstrap-check/$exe"
[ -x "$s1" ] || { echo "fixpoint-check: FAIL no stage 1 at $s1; run scripts/ci/bootstrap-check.sh first"; exit 1; }
out=tmp/fixpoint-check; rm -rf "$out"; mkdir -p "$out/stage2"
export BAYAN_CACHE="$root/$out/cache"
start=$(date +%s)
s2="$out/stage2/$exe"
if ! nice "$s1" build --package src -o "$s2" src/driver > "$out/stage2.log" 2>&1; then
  tail -20 "$out/stage2.log"; echo "fixpoint-check: FAIL stage 1 does not build src/driver; log: $out/stage2.log"; exit 1
fi
fail=0
for mode in safe debug; do
  for s in 1 1again 2; do
    case $s in 2) e=$s2 ;; *) e=$s1 ;; esac
    if ! nice "$e" build --emit-c --mode "$mode" --package src src/driver > "$out/stage$s.$mode.c" 2> "$out/emit.log"; then
      tail -20 "$out/emit.log"; echo "fixpoint-check: FAIL stage $s does not emit src/driver in $mode; log: $out/emit.log"; exit 1
    fi
  done
  compare "$mode" "$out/stage1.$mode.c" "$out/stage1again.$mode.c" || fail=1
  compare "$mode" "$out/stage1.$mode.c" "$out/stage2.$mode.c" || fail=1
  scan "$out/stage1.$mode.c" || fail=1
  scan "$out/stage2.$mode.c" || fail=1
done
[ $fail = 0 ] || exit 1
echo "fixpoint-check: OK (stage 1 and stage 2 emit the same C for src/driver in safe and debug, with no absolute path or timestamp; $(( $(date +%s) - start ))s)"
