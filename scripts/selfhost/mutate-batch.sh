#!/bin/bash
# mutate-batch.sh — the batch mutation run (spec 013 T28, R14): guard.sh's mutation step (mutation-step.sh) over every
# src/**/*.byn with its test filter, then the scores into tests/quality-baseline.json. Run from the repo root after `dotnet build`.
#   bash scripts/selfhost/mutate-batch.sh [--list] [--files a.byn,b.byn] [--shard k/n] [--tasks <tasks.md>]...
# A file's filter is derived from the --tasks files (repeatable; default docs/specs/010-self-hosted-semantics/010-tasks.md and
# docs/specs/017-selfhost-default/017-tasks.md, where the driver's task lines live): every task line whose
# `files:` list names the file contributes the *Tests.cs classes of that same list, as FullyQualifiedName~<Class> joined by `|`;
# a glob class name such as SelfhostSemanticsT*Tests.cs is skipped (no FQN substring), and only classes of the file's own family are kept
# (src/semantics: SelfhostSemantics*, parser: SelfhostParser*, lexer: SelfhostLexer*, emitter and its subdirectories cprint/, ltree/: SelfhostEmitter*,
# driver: SelfhostDriver* and SelfhostDefault*, whose tests build src/driver through SelfhostDriverHarness: another build does not contain the file);
# a file with none left uses SelfhostSemantics, SelfhostParser, SelfhostLexer, SelfhostEmitter or SelfhostDriver; another directory fails. One group per family and shard (Q910):
# its filter is the union of its files' filters, so the tests are recorded once per (shard, family); src/emitter/ and its subdirectories are one family.
# --list prints file -> group filter and runs nothing; --shard k/n gives file i of each family to shard (i mod n)+1; --files narrows
# which files are mutated (BAYAN_SNAPSHOT_FILES) but each group keeps the union filter of all its (shard's) files, the one a full run
# raised the baseline with.
# Per group: reports and logs in tmp/mutate-batch/<group>/ (quality-<n>-<binary>.json), bayan mutate's summary printed. A group
# whose CLI, recording or mutant 0 fails is named and fails the run. Then quality-baseline check over the reports: a score
# below the baseline names the file with old and new score and exits 1 with the baseline untouched; else `update` raises it.
# MUTATE_BASELINE names another baseline file to check and raise instead (mutate-nightly.sh's scratch copy).
# Each copied report's `path`s are rewritten relative to the repo root (a path outside it fails the group, naming the report);
# a relative path that is no file under the root is an imported module's, relative to the harness builds' packageRoot src/
# (Compilation.DisplayRoot; SelfhostLexerCaseTests imports `lexer`), and is resolved there; a path that is no file there either fails the group;
# one run at a time: tmp/mutate-batch.lock (a directory holding the holder's pid) is taken for the run, a lock whose pid is gone is taken over;
# exit codes: 0 done and the baseline raised; 1 a score fell below the baseline (nothing raised); 2 usage or plan error;
# 3 setup-class failure that says nothing about the file (the lock is held, no pinned bayan, the recording failed with no failed test,
# quality-baseline check/update crashed or could not read the baseline); 4 a group failed for its files (tests failed in the recording, mutant 0 does not replay,
# no or unreadable manifest, no report, a report path that is no file): rerunning the same file fails the same way;
# a lock without a pid file is held for 60 s (its holder may be between mkdir and the pid write), then stale;
# CI shards (.github/workflows/mutation.yml) upload only the reports, and a final job runs one `update` over all of them.
set -u
export MSBUILDDISABLENODEREUSE=1 DOTNET_CLI_USE_MSBUILD_SERVER=0  # no MSBuild worker or build server outlives the run
TASKS=(); LIST=0; FILES=""; SHARD=""
while [ $# -gt 0 ]; do case "$1" in
  --list) LIST=1; shift;; --files) FILES=$2; shift 2;; --shard) SHARD=$2; shift 2;; --tasks) TASKS+=("$2"); shift 2;;
  *) echo "unknown arg $1"; exit 2;; esac; done
[ ${#TASKS[@]} -gt 0 ] || TASKS=(docs/specs/010-self-hosted-semantics/010-tasks.md docs/specs/017-selfhost-default/017-tasks.md)
HERE=$(dirname "$0"); OUT=$PWD/tmp/mutate-batch; BASELINE=${MUTATE_BASELINE:-tests/quality-baseline.json}

# group<TAB>file<TAB>filter per file, in file order, after --files and --shard
# a plan error is the tool'"'"'s `mutate-batch: ...` line (exit 2); anything else on stderr (no pinned bayan) is a setup failure (exit 3)
PERR=$(mktemp); PLAN=$(bash "$HERE/../bayan-tool.sh" mutate-plan "$FILES" "$SHARD" "${TASKS[@]}" 2> "$PERR") || {
  echo "$PLAN"; cat "$PERR" >&2; case $(head -c 14 "$PERR") in "mutate-batch: ") rm -f "$PERR"; exit 2;; esac; rm -f "$PERR"; exit 3; }
rm -f "$PERR"

if [ $LIST = 1 ]; then while IFS=$'\t' read -r g f flt; do echo "$f -> $flt"; done <<< "$PLAN"; exit 0; fi
[ -n "$PLAN" ] || { echo "mutate-batch: no file selected"; exit 2; }
mkdir -p "$(dirname "$OUT")"; LOCK=$OUT.lock
if ! mkdir "$LOCK" 2>/dev/null; then
  pid=$(cat "$LOCK/pid" 2>/dev/null)
  if [ -n "$pid" ]; then kill -0 "$pid" 2>/dev/null && held=1; else [ -z "$(find "$LOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ] && held=1; fi
  if [ "${held:-0}" = 1 ]; then echo "mutate-batch: $OUT is in use by another run (lock $LOCK, pid ${pid:-unknown})"; exit 3; fi
  rm -r "$LOCK"; mkdir "$LOCK" 2>/dev/null || { echo "mutate-batch: $OUT is in use by another run (lock $LOCK)"; exit 3; }
fi
echo $$ > "$LOCK/pid"; trap 'rm -r "$LOCK"' EXIT
FAIL=(); note() { FAIL+=("$1"); }
. "$HERE/mutation-step.sh"
BAD=0; SETUP=0; OK=()
while IFS= read -r g <&3; do
  flt=$(awk -F'\t' -v g="$g" '$1==g{print $3; exit}' <<< "$PLAN")
  mut=$(awk -F'\t' -v g="$g" '$1==g{print $2}' <<< "$PLAN" | paste -sd, -)
  LOG="$OUT/$g"; rm -rf "$LOG"; mkdir -p "$LOG"; FAIL=()
  echo "== group $g ($flt): $mut"
  mutation_step "$LOG" "$flt" "$mut" 0
  # bayan mutate writes absolute source paths: make each report's paths repo-root-relative, so any machine can read it
  if [ ${#FAIL[@]} = 0 ]; then for rp in "$LOG"/quality-*.json; do
    [ -f "$rp" ] && { bash "$HERE/../bayan-tool.sh" report-paths "$rp" "$(pwd -W 2>/dev/null || pwd)" 2> "$LOG/relpath.txt" || note "report: $(tail -1 "$LOG/relpath.txt")"
    }; done; fi
  if [ ${#FAIL[@]} = 0 ]; then
    OK+=("$g")
  else
    BAD=1
    for x in "${FAIL[@]}"; do echo "group $g: $x"
      case $x in "mutation: no pinned bayan"*|"mutation: recording the tests under BAYAN_SNAPSHOT failed"*) SETUP=1;; esac; done
    mkdir -p "$LOG/rejected"
    for rp in "$LOG"/quality-*.json; do
      [ -f "$rp" ] && mv "$rp" "$LOG/rejected/rejected-$(basename "$rp")"
    done
  fi
done 3< <(cut -f1 <<< "$PLAN" | awk '!s[$0]++')
REPORTS=(); for g in ${OK[@]+"${OK[@]}"}; do REPORTS+=("$OUT/$g"/quality-*.json); done
if [ ${#REPORTS[@]} -gt 0 ]; then
  out=$(bash "$HERE/../bayan-tool.sh" quality-baseline check "$BASELINE" . "${REPORTS[@]}" 2> "$OUT/baseline.txt"); BX=$?
  if [ $BX != 0 ]; then
    [ -n "$out" ] && echo "$out" || echo "baseline: quality-baseline check failed on $BASELINE — $(tail -1 "$OUT/baseline.txt")"
    # a refused shard uploads no accepted report: every report it would have applied moves to its group's rejected/
    for g in "${OK[@]}"; do mkdir -p "$OUT/$g/rejected"
      for rp in "$OUT/$g"/quality-*.json; do [ -f "$rp" ] && mv "$rp" "$OUT/$g/rejected/rejected-$(basename "$rp")"; done; done
    echo "mutate-batch: baseline not updated"; [ $BX = 1 ] && [ -n "$out" ] && exit 1; exit 3; fi
  bash "$HERE/../bayan-tool.sh" quality-baseline update "$BASELINE" . "${REPORTS[@]}" || { echo "mutate-batch: baseline update failed"; exit 3; }
  echo "baseline: $BASELINE updated from ${#REPORTS[@]} report(s)"
fi
[ $SETUP = 1 ] && exit 3; [ $BAD = 1 ] && exit 4; exit 0
