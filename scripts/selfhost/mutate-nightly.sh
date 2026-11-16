#!/bin/bash
# mutate-nightly.sh — the batch mutation run spread over nights, one selfhost .byn file at a time. Run from the repo root after `dotnet build`.
#   bash scripts/selfhost/mutate-nightly.sh --deadline HH:MM [--state <dir>] [--tasks <tasks.md>]...
# The queue is every file of `mutate-batch.sh --list` (--tasks passed through), in path order; <state> (default
# $HOME/mutate-nightly) keeps `cursor` (the last file run) and `secs/<file-slug>` (the last run time of each file; the slowest
# is the largest of them, 900 before the first, so an outlier is replaced when its file runs again) and holds `lock` (a directory
# with its pid, taken over when the pid is gone; a second nightly on the state exits 2). Each file runs as `mutate-batch.sh --files <file>` against a scratch copy of tests/quality-baseline.json
# (MUTATE_BASELINE=<state>/baseline.json), so the repo is never edited; the runner never commits or pushes.
# Before each file it stops when less than `slowest` remains before the deadline (the next HH:MM after the start), and it
# stops after one pass over the queue; the next night resumes after the cursor and wraps to the first file after the last.
# Per night <state>/<YYYY-MM-DD>.log gets one line per file (file, rc, seconds, every build's score line) and the stop reason; the group's
# reports and per-site logs are copied to <state>/reports/<file-slug>/. A file that fails its score (rc 1) or whose group fails
# for it (rc 4: mutant 0 does not replay, no manifest ...) is logged and the next one runs; a setup-class rc (mutate-batch.sh: 2 or 3,
# e.g. no pinned bayan, a build failure, its lock held, a baseline crash) stops the night with the cursor unmoved and the reason
# logged, exit 2. A file whose recording failed with failed tests (rc 4, `mutation: recording under BAYAN_SNAPSHOT: N test(s)
# failed`) records no time, and the rest of its family (selfhost/<dir>, the batch's recording group) is logged `rc=skip` and
# passed that night: each would re-record the same failing tests (30–95 min a file on 2026-11-09). The night's skipped families are
# kept in <state>/skip (the deadline epoch on its first line; a restart of the same night loads it, another night replaces it).
# The failed file and the files passed as `rc=skip` go to <state>/retry (one path per line): each night runs them first, in path
# order (files gone from the queue dropped, none twice a night, each counting toward the one pass), then continues after the
# cursor, which a retry run does not move; a retry file leaves `retry` once it ran with any result but a failed recording.
# Exit 0 after a deadline stop or a full pass, 2 on a setup error. MUTATE_BATCH overrides the mutate-batch.sh path (tests).
set -u
DEADLINE=""; STATE=$HOME/mutate-nightly; TASKS=()
while [ $# -gt 0 ]; do case "$1" in
  --deadline) DEADLINE=$2; shift 2;; --state) STATE=$2; shift 2;; --tasks) TASKS+=(--tasks "$2"); shift 2;;
  *) echo "mutate-nightly: unknown arg $1"; exit 2;; esac; done
BATCH=${MUTATE_BATCH:-$(dirname "$0")/mutate-batch.sh}
[[ $DEADLINE =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || { echo "mutate-nightly: --deadline HH:MM is required (got '$DEADLINE')"; exit 2; }
[ -f tests/quality-baseline.json ] || { echo "mutate-nightly: no tests/quality-baseline.json: run from the repo root"; exit 2; }
mkdir -p "$STATE/reports" "$STATE/secs" || { echo "mutate-nightly: cannot create $STATE"; exit 2; }
# one nightly per state, and none while a mutate-batch.sh run holds tmp/mutate-batch (the per-file clean-up below would delete its files)
# a lock without a pid file is held for 60 s (its holder may be between mkdir and the pid write), then stale
holder() { local pid; pid=$(cat "$1/pid" 2>/dev/null); [ -d "$1" ] || return 0
  if [ -n "$pid" ]; then kill -0 "$pid" 2>/dev/null && echo "$pid"; else [ -z "$(find "$1" -maxdepth 0 -mmin +1 2>/dev/null)" ] && echo unknown; fi; return 0; }
if ! mkdir "$STATE/lock" 2>/dev/null; then
  pid=$(holder "$STATE/lock")
  [ -z "$pid" ] || { echo "mutate-nightly: $STATE is in use by another nightly (pid $pid)"; exit 2; }
  rm -r "$STATE/lock"; mkdir "$STATE/lock" 2>/dev/null || { echo "mutate-nightly: $STATE is in use by another nightly"; exit 2; }
fi
echo $$ > "$STATE/lock/pid"; trap 'rm -r "$STATE/lock"' EXIT
END=$(python3 -I -c '
import datetime, sys
h, m = map(int, sys.argv[1].split(":"))
now = datetime.datetime.now()
end = now.replace(hour=h, minute=m, second=0, microsecond=0)
print(int((end + datetime.timedelta(days=1) if end <= now else end).timestamp()))' "$DEADLINE") || { echo "mutate-nightly: cannot compute the deadline"; exit 2; }
LOG=$STATE/$(date +%F).log
QUEUE=$(bash "$BATCH" --list ${TASKS[@]+"${TASKS[@]}"} 2>&1) || { echo "mutate-nightly: mutate-batch.sh --list failed: $QUEUE"; exit 2; }
QUEUE=$(sed -n 's/ -> .*//p' <<< "$QUEUE" | LC_ALL=C sort)
[ -n "$QUEUE" ] || { echo "mutate-nightly: mutate-batch.sh --list gave no file"; exit 2; }
total=$(wc -l <<< "$QUEUE" | tr -d ' ')
echo "== $(date '+%F %T') start: deadline $DEADLINE, $total files, cursor $(cat "$STATE/cursor" 2>/dev/null || echo none)" >> "$LOG"
done_n=0; SKIP=""; RAN=""  # SKIP: families (selfhost/<dir>) whose recording failed tonight: their tests fail the same way for every file; RAN: files handled tonight
if [ "$(head -1 "$STATE/skip" 2>/dev/null)" = "$END" ]; then SKIP=$(tail -n +2 "$STATE/skip"); else echo "$END" > "$STATE/skip"; fi
# retry files no longer in the queue are dropped
[ -f "$STATE/retry" ] && { grep -xFf <(printf '%s\n' "$QUEUE") "$STATE/retry" | LC_ALL=C sort -u > "$STATE/retry.new"; mv "$STATE/retry.new" "$STATE/retry"; }
retry_add() { grep -qxF "$1" "$STATE/retry" 2>/dev/null || echo "$1" >> "$STATE/retry"; }
while [ "$done_n" -lt "$total" ]; do
  slowest=$(cat "$STATE"/secs/* 2>/dev/null | sort -n | tail -1); slowest=${slowest:-900}
  left=$(( END - $(date +%s) ))
  if [ "$left" -lt "$slowest" ]; then
    echo "== $(date '+%F %T') stop: ${left}s left before $DEADLINE, slowest file ${slowest}s" >> "$LOG"; exit 0; fi
  cursor=$(cat "$STATE/cursor" 2>/dev/null || true)
  # a retry file not yet handled tonight, else the first file after the cursor in path order, the first file when none is (wrap): a file added or removed since keeps the order
  isr=0; f=$(LC_ALL=C sort -u "$STATE/retry" 2>/dev/null | grep -vxFf <(printf '%s\n' "$RAN") | head -1)
  if [ -n "$f" ]; then isr=1; else
    f=$(awk -v c="$cursor" '$0 > c { print; exit }' <<< "$QUEUE"); [ -n "$f" ] || f=$(head -1 <<< "$QUEUE")
    # a retry file that already ran tonight is not run again
    if grep -qxF "$f" <<< "$RAN"; then echo "$f" > "$STATE/cursor"; continue; fi; fi
  slug=$(sed 's|/|-|g; s|\.byn$||' <<< "$f")
  fam=$(cut -d/ -f1-2 <<< "$f")
  if grep -qxF "$fam" <<< "$SKIP"; then
    echo "$f rc=skip secs=0 no score: the recording of $fam failed earlier tonight" >> "$LOG"
    [ $isr = 1 ] || echo "$f" > "$STATE/cursor"; retry_add "$f"; RAN=$(printf '%s\n%s' "$RAN" "$f"); done_n=$((done_n + 1)); continue; fi
  pid=$(holder tmp/mutate-batch.lock)
  if [ -n "$pid" ]; then echo "== $(date '+%F %T') stop: mutate-batch.sh (pid $pid) holds tmp/mutate-batch, cursor not moved" >> "$LOG"; exit 2; fi
  cp tests/quality-baseline.json "$STATE/baseline.json"
  rm -rf tmp/mutate-batch
  start=$(date +%s)
  out=$(MUTATE_BASELINE=$STATE/baseline.json bash "$BATCH" --files "$f" ${TASKS[@]+"${TASKS[@]}"} 2>&1); rc=$?
  secs=$(( $(date +%s) - start ))
  score=$(grep '^mutation: [0-9]' <<< "$out" | awk 'NR > 1 { printf " | " } { printf "%s", $0 } END { print "" }')
  [ -n "$score" ] || score="no score: $(tail -1 <<< "$out")"
  echo "$f rc=$rc secs=$secs $score" >> "$LOG"
  rm -rf "$STATE/reports/$slug"; mkdir -p "$STATE/reports/$slug"
  printf '%s\n' "$out" > "$STATE/reports/$slug/batch.txt"
  for g in tmp/mutate-batch/*/; do
    [ -d "$g" ] || continue
    cp "$g"quality-*.json "$g"mutate-*.txt "$STATE/reports/$slug/" 2>/dev/null
    [ -d "$g"rejected ] && cp -R "$g"rejected "$STATE/reports/$slug/"
  done
  # a failed recording runs no mutant: its time would only push the deadline stop earlier
  recfail=0
  if [ $rc = 4 ] && grep -q 'mutation: recording under BAYAN_SNAPSHOT: ' <<< "$out"; then
    recfail=1; SKIP=$(printf '%s\n%s' "$SKIP" "$fam"); echo "$fam" >> "$STATE/skip"; retry_add "$f"
    echo "== $(date '+%F %T') skip: the tests of $fam fail under BAYAN_SNAPSHOT, its other files wait for the next pass: $(grep -m1 -o 'recording under BAYAN_SNAPSHOT: .*' <<< "$out" | cut -c1-600)" >> "$LOG"
  else
    echo "$secs" > "$STATE/secs/$slug"
  fi
  case $rc in 0|1|4) ;; *)  # 1: score below the baseline, 4: this file's group failed; anything else: the night is wasted, not the file
    echo "== $(date '+%F %T') stop: setup failure (rc=$rc) on $f, cursor not moved: $(tail -1 <<< "$out")" >> "$LOG"; exit 2;; esac
  if [ $isr = 1 ]; then [ $recfail = 1 ] || { grep -vxF "$f" "$STATE/retry" > "$STATE/retry.new"; mv "$STATE/retry.new" "$STATE/retry"; }
  else echo "$f" > "$STATE/cursor"; fi
  RAN=$(printf '%s\n%s' "$RAN" "$f")
  done_n=$((done_n + 1))
done
echo "== $(date '+%F %T') stop: the queue of $total files ran once" >> "$LOG"
exit 0
