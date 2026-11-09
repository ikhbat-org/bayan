#!/bin/bash
# mutate-nightly.sh with a stub mutate-batch.sh (MUTATE_BATCH) in a scratch repo: a first night runs the queue once in path
# order and leaves the cursor on the last file, a failing file is logged and the next one runs; the next night wraps to the first
# file and stops before the next one once the slowest file time no longer fits before the deadline, keeping the cursor; the night
# after resumes after it; reports land in <state>/reports/<slug>/; the repo's files outside the ignored tmp/ stay unchanged (the
# stub writes the baseline it is given; the stand-in for an empty `git status --porcelain`, with no git repo to set up);
# a bad --deadline and a run outside a repo root are setup errors (exit 2); every build's score line is logged; the slowest time is
# the largest per-file last time (an outlier is replaced when its file runs again); a setup-class rc (not 0 or 1) stops the night
# without moving the cursor; a live lock on the state or on tmp/mutate-batch stops it (exit 2), a stale lock is taken over.
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/mutate-nightly-test"; repo="$t/repo"; state="$t/state"
rm -rf "$t" && mkdir -p "$repo/tests" "$t/aux" && cd "$repo"
printf '{ "version": 1, "files": {} }\n' > tests/quality-baseline.json; printf 'tmp/\n' > .gitignore
tree() { find . -path ./tmp -prune -o -type f -print | LC_ALL=C sort | xargs shasum; }
clean=$(tree)
cat > "$t/aux/batch.sh" <<'STUB'
#!/bin/bash
if [ "$1" = --list ]; then printf 'selfhost/b/z.byn -> G\nselfhost/a/x.byn -> F\nselfhost/a/y.byn -> F\n'; exit 0; fi
f=$2; echo "$f" >> "$AUX/ran.txt"
echo '{}' >> "${MUTATE_BASELINE:-tests/quality-baseline.json}"
mkdir -p tmp/mutate-batch/g; echo "{\"file\": \"$f\"}" > tmp/mutate-batch/g/quality-1-prog.json
echo "mutation: 3 of 4 killed"
[ -f "$AUX/two" ] && echo "mutation: 1 of 2 killed"
[ -f "$AUX/setup" ] && exit 3
[ -f "$AUX/group" ] && exit 4
[ "$f" = selfhost/a/y.byn ] && exit 1
exit 0
STUB
export AUX="$t/aux" MUTATE_BATCH="$t/aux/batch.sh"
deadline=$(python3 -I -c 'import datetime; print((datetime.datetime.now() - datetime.timedelta(minutes=1)).strftime("%H:%M"))')  # ~24h ahead
night() { bash "$root/scripts/selfhost/mutate-nightly.sh" --deadline "$deadline" --state "$state" > "$t/out.txt" 2>&1; }
fail() { echo "FAIL $1"; exit 1; }
log() { cat "$state"/*.log; }

night || fail "night 1 exited $?: $(cat "$t/out.txt")"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/x.byn,selfhost/a/y.byn,selfhost/b/z.byn ] || fail "night 1 ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(cat "$state/cursor")" = selfhost/b/z.byn ] || fail "night 1 cursor $(cat "$state/cursor")"
log | grep -q '^selfhost/a/y.byn rc=1 secs=[0-9]* mutation: 3 of 4 killed$' || fail "night 1 log lacks the failing file: $(log)"
log | grep -q '^selfhost/b/z.byn rc=0 secs=[0-9]* mutation: 3 of 4 killed$' || fail "night 1 log lacks the file after the failing one: $(log)"
log | grep -q 'stop: the queue of 3 files ran once' || fail "night 1 log lacks the full-pass stop: $(log)"
grep -q selfhost/a/x.byn "$state/reports/selfhost-a-x/quality-1-prog.json" || fail "no report in reports/selfhost-a-x/"
[ "$(tree)" = "$clean" ] || fail "the repo is not clean: $(diff <(echo "$clean") <(tree))"

# night 2: the slowest per-file time (86400s, 24h) does not fit: nothing runs, the cursor stays
: > "$t/aux/ran.txt"; echo 86400 > "$state/secs/selfhost-b-z"
night || fail "night 2 exited $?: $(cat "$t/out.txt")"
[ ! -s "$t/aux/ran.txt" ] || fail "night 2 (slowest 86400s) ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(cat "$state/cursor")" = selfhost/b/z.byn ] || fail "night 2 cursor $(cat "$state/cursor")"
log | grep -q 'stop: [0-9]*s left before .*, slowest file 86400s' || fail "night 2 log lacks the deadline stop: $(log)"

# night 3: an outlier (80000s of 86340s left fits) is replaced when its file runs again, and every build's score is logged
: > "$t/aux/ran.txt"; echo 80000 > "$state/secs/selfhost-a-x"; echo 1 > "$state/secs/selfhost-b-z"; touch "$t/aux/two"
night || fail "night 3 exited $?: $(cat "$t/out.txt")"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/x.byn,selfhost/a/y.byn,selfhost/b/z.byn ] || fail "night 3 (wrap after the cursor) ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(cat "$state/secs/selfhost-a-x")" -lt 80000 ] || fail "night 3: the outlier time of x was kept ($(cat "$state/secs/selfhost-a-x"))"
log | grep -q '^selfhost/a/x.byn rc=0 secs=[0-9]* mutation: 3 of 4 killed | mutation: 1 of 2 killed$' || fail "night 3 log lacks both builds' scores: $(log)"
rm "$t/aux/two"
[ "$(tree)" = "$clean" ] || fail "the repo is not clean after night 3: $(diff <(echo "$clean") <(tree))"

# night 4: no time recorded: 900s default
: > "$t/aux/ran.txt"; rm "$state"/secs/*
deadline=$(python3 -I -c 'import datetime; print((datetime.datetime.now() + datetime.timedelta(minutes=10)).strftime("%H:%M"))')
night || fail "night 4 exited $?: $(cat "$t/out.txt")"
[ ! -s "$t/aux/ran.txt" ] || fail "night 4 (10 min left, no file timed yet) ran $(paste -sd, "$t/aux/ran.txt")"
log | grep -q 'stop: [0-9]*s left before .*, slowest file 900s' || fail "night 4 log lacks the 15 min default stop: $(log)"

# night 5: a setup-class rc stops the night, the cursor stays on z
: > "$t/aux/ran.txt"; touch "$t/aux/setup"
deadline=$(python3 -I -c 'import datetime; print((datetime.datetime.now() - datetime.timedelta(minutes=1)).strftime("%H:%M"))')
rc=0; night || rc=$?
[ $rc = 2 ] || fail "night 5 (setup rc 3) exited $rc, not 2"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/x.byn ] || fail "night 5 ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(cat "$state/cursor")" = selfhost/b/z.byn ] || fail "night 5 moved the cursor to $(cat "$state/cursor")"
log | grep -q 'stop: setup failure (rc=3) on selfhost/a/x.byn, cursor not moved' || fail "night 5 log lacks the setup failure: $(log)"
rm "$t/aux/setup"

# night 6: rc 4 (the file's own group failed) is logged and the cursor passes the file, every night
: > "$t/aux/ran.txt"; touch "$t/aux/group"; echo selfhost/b/z.byn > "$state/cursor"
night || fail "night 6 (group failures) exited $?: $(cat "$t/out.txt")"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/x.byn,selfhost/a/y.byn,selfhost/b/z.byn ] || fail "night 6 stopped on a failing group: ran $(paste -sd, "$t/aux/ran.txt")"
log | grep -q '^selfhost/a/x.byn rc=4 ' || fail "night 6 log lacks the rc=4 line: $(log)"
[ "$(cat "$state/cursor")" = selfhost/b/z.byn ] || fail "night 6 cursor $(cat "$state/cursor")"
rm "$t/aux/group"

# a live lock on the state, a live mutate-batch.sh lock on tmp/mutate-batch, a stale lock taken over
: > "$t/aux/ran.txt"; sleep 60 & holder=$!
mkdir "$state/lock"; echo $holder > "$state/lock/pid"
rc=0; night || rc=$?
[ $rc = 2 ] && grep -q 'in use by another nightly' "$t/out.txt" || fail "a live state lock did not stop the nightly with exit 2 (rc=$rc): $(cat "$t/out.txt")"
[ ! -s "$t/aux/ran.txt" ] || fail "a live state lock still ran $(paste -sd, "$t/aux/ran.txt")"
rm -r "$state/lock"; mkdir -p tmp/mutate-batch.lock; echo $holder > tmp/mutate-batch.lock/pid
rc=0; night || rc=$?
[ $rc = 2 ] && [ ! -s "$t/aux/ran.txt" ] && log | grep -q 'stop: mutate-batch.sh (pid [0-9]*) holds tmp/mutate-batch' || fail "a live batch lock did not stop the nightly (rc=$rc): $(log)"
kill $holder; wait $holder 2>/dev/null || true
mkdir "$state/lock"; echo $holder > "$state/lock/pid"; rm -r tmp/mutate-batch.lock
night || fail "a stale state lock stopped the nightly: $(cat "$t/out.txt")"
[ -s "$t/aux/ran.txt" ] && [ ! -e "$state/lock" ] || fail "a stale lock was not taken over, or the lock outlived the run"
# a lock without a pid file: held while young, stale once older than 60 s
: > "$t/aux/ran.txt"; mkdir "$state/lock"
rc=0; night || rc=$?
[ $rc = 2 ] && [ ! -s "$t/aux/ran.txt" ] || fail "a young pid-less lock did not stop the nightly (rc=$rc)"
touch -t 200001010000 "$state/lock"
night || fail "an old pid-less lock stopped the nightly: $(cat "$t/out.txt")"
[ -s "$t/aux/ran.txt" ] || fail "an old pid-less lock was not taken over"

set +e
bash "$root/scripts/selfhost/mutate-nightly.sh" --deadline 25:00 --state "$state" > "$t/out.txt" 2>&1; [ $? = 2 ] || fail "a bad --deadline did not exit 2"
(cd "$t" && bash "$root/scripts/selfhost/mutate-nightly.sh" --deadline "$deadline" --state "$state" > "$t/out.txt" 2>&1); [ $? = 2 ] || fail "a run outside a repo root did not exit 2"
echo PASS
