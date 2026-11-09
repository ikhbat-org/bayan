#!/bin/bash
# mutate-nightly.sh — the batch mutation run spread over nights, one selfhost .byn file at a time. Run from the repo root after `dotnet build`.
#   bash scripts/selfhost/mutate-nightly.sh --deadline HH:MM [--state <dir>] [--tasks <tasks.md>]...
# The queue is every file of `mutate-batch.sh --list` (--tasks passed through), in path order; <state> (default
# $HOME/mutate-nightly) keeps `cursor` (the last file run) and `slowest` (the longest file run so far, in seconds; 900 before
# the first). Each file runs as `mutate-batch.sh --files <file>` against a scratch copy of tests/quality-baseline.json
# (MUTATE_BASELINE=<state>/baseline.json), so the repo is never edited; the runner never commits or pushes.
# Before each file it stops when less than `slowest` remains before the deadline (the next HH:MM after the start), and it
# stops after one pass over the queue; the next night resumes after the cursor and wraps to the first file after the last.
# Per night <state>/<YYYY-MM-DD>.log gets one line per file (file, rc, seconds, score line) and the stop reason; the group's
# reports and per-site logs are copied to <state>/reports/<file-slug>/. A failing file is logged and the next one runs.
# Exit 0 after a deadline stop or a full pass, 2 on a setup error. MUTATE_BATCH overrides the mutate-batch.sh path (tests).
set -u
DEADLINE=""; STATE=$HOME/mutate-nightly; TASKS=()
while [ $# -gt 0 ]; do case "$1" in
  --deadline) DEADLINE=$2; shift 2;; --state) STATE=$2; shift 2;; --tasks) TASKS+=(--tasks "$2"); shift 2;;
  *) echo "mutate-nightly: unknown arg $1"; exit 2;; esac; done
BATCH=${MUTATE_BATCH:-$(dirname "$0")/mutate-batch.sh}
[[ $DEADLINE =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || { echo "mutate-nightly: --deadline HH:MM is required (got '$DEADLINE')"; exit 2; }
[ -f tests/quality-baseline.json ] || { echo "mutate-nightly: no tests/quality-baseline.json: run from the repo root"; exit 2; }
mkdir -p "$STATE/reports" || { echo "mutate-nightly: cannot create $STATE"; exit 2; }
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
done_n=0
while [ "$done_n" -lt "$total" ]; do
  slowest=$(cat "$STATE/slowest" 2>/dev/null || echo 900)
  left=$(( END - $(date +%s) ))
  if [ "$left" -lt "$slowest" ]; then
    echo "== $(date '+%F %T') stop: ${left}s left before $DEADLINE, slowest file ${slowest}s" >> "$LOG"; exit 0; fi
  cursor=$(cat "$STATE/cursor" 2>/dev/null || true)
  # the first file after the cursor in path order, the first file when none is (wrap): a file added or removed since keeps the order
  f=$(awk -v c="$cursor" '$0 > c { print; exit }' <<< "$QUEUE"); [ -n "$f" ] || f=$(head -1 <<< "$QUEUE")
  slug=$(sed 's|/|-|g; s|\.byn$||' <<< "$f")
  cp tests/quality-baseline.json "$STATE/baseline.json"
  rm -rf tmp/mutate-batch
  start=$(date +%s)
  out=$(MUTATE_BASELINE=$STATE/baseline.json bash "$BATCH" --files "$f" ${TASKS[@]+"${TASKS[@]}"} 2>&1); rc=$?
  secs=$(( $(date +%s) - start ))
  score=$(grep -m1 '^mutation: [0-9]' <<< "$out" || echo "no score: $(tail -1 <<< "$out")")
  echo "$f rc=$rc secs=$secs $score" >> "$LOG"
  rm -rf "$STATE/reports/$slug"; mkdir -p "$STATE/reports/$slug"
  printf '%s\n' "$out" > "$STATE/reports/$slug/batch.txt"
  for g in tmp/mutate-batch/*/; do
    [ -d "$g" ] || continue
    cp "$g"quality-*.json "$g"mutate-*.txt "$STATE/reports/$slug/" 2>/dev/null
    [ -d "$g"rejected ] && cp -R "$g"rejected "$STATE/reports/$slug/"
  done
  echo "$f" > "$STATE/cursor"
  [ "$secs" -gt "$slowest" ] && echo "$secs" > "$STATE/slowest"
  done_n=$((done_n + 1))
done
echo "== $(date '+%F %T') stop: the queue of $total files ran once" >> "$LOG"
exit 0
