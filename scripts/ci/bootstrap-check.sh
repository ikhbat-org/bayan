#!/usr/bin/env bash
# Bootstrap freshness and chain (spec 019 R26, R36), with no .NET: bootstrap/bayan-rt.h and bayan-rt.c are runtime/'s, and
# bootstrap/bayan.c is the C that src/driver emits (`build --emit-c --mode safe --package src src/driver`) when built by
# the previous commit's bootstrap. Stage 0 is scripts/pinned-bayan.sh at that commit (cc on its bootstrap/bayan.c);
# stage 0 builds stage 1 with `build --package src -o <exe> src/driver`, the route land.sh regenerates bootstrap/ by.
# Usage: bootstrap-check.sh [<prev>]   (default HEAD^; on a root commit, HEAD; a shallow clone needs depth 2)
# Merge commit (HEAD^2 exists, no <prev> given): the first parent (dev) may hold a bootstrap too old for the merged branch's
# src/driver, so HEAD^2 (the merged branch, which its own CI already proved) is tried first and HEAD^ second; either parent's
# bootstrap building it passes, and the OK line names which parent. CI checks out depth 2, which may lack HEAD^2: the script
# then runs `git fetch --depth=1 origin <HEAD^2>`, and if that fails it says so and falls back to HEAD^ alone.
# Exit 1 names each stale file; stage 1 and its C are kept in tmp/bootstrap-check/.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$(git rev-parse --show-toplevel)"
cands=()
if [ $# -gt 0 ]; then cands=("$1")
elif git rev-parse -q --verify 'HEAD^1^{commit}' > /dev/null; then
  cands=(HEAD^)
  if git rev-parse -q --verify 'HEAD^2' > /dev/null; then   # a merge commit: the merged branch first, then the first parent
    p2=$(git rev-parse HEAD^2)
    git cat-file -e "$p2^{commit}" 2> /dev/null || git fetch -q --depth=1 origin "$p2" 2> /dev/null || true
    if git cat-file -e "$p2^{commit}" 2> /dev/null; then cands=(HEAD^2 HEAD^)
    else echo "bootstrap-check: HEAD^2 ($p2) is not in this clone and could not be fetched; using HEAD^ only"; fi
  fi
elif [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "bootstrap-check: FAIL HEAD has no parent in this shallow clone; fetch with depth 2 (R36 needs the previous commit)"; exit 1
else cands=(HEAD); fi
for prev in "${cands[@]}"; do git rev-parse -q --verify "$prev^{commit}" > /dev/null || { echo "bootstrap-check: no commit for '$prev'" >&2; exit 2; }; done
fail=0
for f in bayan-rt.h bayan-rt.c; do
  cmp -s "runtime/$f" "bootstrap/$f" || { echo "bootstrap-check: FAIL bootstrap/$f differs from runtime/$f (R26); copy it"; fail=1; }
done
out=tmp/bootstrap-check; rm -rf "$out"; mkdir -p "$out"
exe=bayan; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) exe=bayan.exe ;; esac
# stage 0 from the bootstrap of $1 builds stage 1, which emits src/driver; sets prev and sha, returns 1 with the reason printed
chain() {
  prev=$1; sha=$(git rev-parse "$prev^{commit}")
  s0=$(PINNED_BAYAN_REF=$sha bash "$here/pinned-bayan.sh") \
    || { echo "bootstrap-check: FAIL the bootstrap of $prev ($sha) does not build with cc (R36)"; return 1; }
  if ! "$s0" build --package src -o "$out/$exe" src/driver > "$out/stage1.log" 2>&1; then
    tail -20 "$out/stage1.log"
    echo "bootstrap-check: FAIL the bootstrap of $prev ($sha) does not build src/driver (R36); log: $out/stage1.log"; return 1
  fi
  if ! "$out/$exe" build --emit-c --mode safe --package src src/driver > "$out/bayan.c" 2> "$out/emit.log"; then
    tail -20 "$out/emit.log"
    echo "bootstrap-check: FAIL stage 1 (src/driver built by the bootstrap of $prev) does not emit src/driver (R36); log: $out/emit.log"; return 1
  fi
}
ok=0
for c in "${cands[@]}"; do
  if chain "$c"; then ok=1; break; fi
  [ "$c" = "${cands[${#cands[@]}-1]}" ] || echo "bootstrap-check: trying the next parent"
done
[ $ok = 1 ] || exit 1
if ! cmp -s "$out/bayan.c" bootstrap/bayan.c; then
  # the first differing line and the `#line` above it in the emitted C, which names the src/ file behind it
  line=$(cmp "$out/bayan.c" bootstrap/bayan.c 2>&1 | sed -nE 's/.* line ([0-9]+).*/\1/p' || true)
  [ -n "$line" ] || line=$(( $(wc -l < bootstrap/bayan.c) + 1 ))
  from=$(awk -v n="$line" 'NR > n { exit } /^#line [0-9]+ "/ { m = $0 } END { print m }' "$out/bayan.c" | sed -E 's/^#line ([0-9]+) "(.*)"$/src\/\2:\1/')
  echo "bootstrap-check: FAIL bootstrap/bayan.c is not the C that src/driver emits when built by the bootstrap of $prev (R26, R36);"
  echo "  first difference at line $line${from:+, from $from}; regenerate bootstrap/ (scripts/selfhost/land.sh does)"
  echo "  emitted: $(sed -n "${line}p" "$out/bayan.c" | cut -c1-200)"
  echo "  bootstrap/bayan.c: $(sed -n "${line}p" bootstrap/bayan.c | cut -c1-200)"
  fail=1
fi
[ $fail = 0 ] || exit 1
echo "bootstrap-check: OK (bootstrap/ matches src/ and runtime/, and the bootstrap of $prev builds it)"
