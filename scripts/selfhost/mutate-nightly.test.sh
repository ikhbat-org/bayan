#!/bin/bash
# mutate-nightly.sh with a stub mutate-batch.sh (MUTATE_BATCH) in a scratch repo: a first night runs the queue once in path
# order and leaves the cursor on the last file, a failing file is logged and the next one runs; the next night wraps to the first
# file and stops before the next one once the slowest file time no longer fits before the deadline, keeping the cursor; the night
# after resumes after it; reports land in <state>/reports/<slug>/; the repo's files outside the ignored tmp/ stay unchanged (the
# stub writes the baseline it is given; the stand-in for an empty `git status --porcelain`, with no git repo to set up);
# a bad --deadline and a run outside a repo root are setup errors (exit 2).
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
[ -f "$AUX/slow" ] && echo 86400 > "$AUX/state/slowest"
[ "$f" = selfhost/a/y.byn ] && exit 1
exit 0
STUB
export AUX="$t/aux" MUTATE_BATCH="$t/aux/batch.sh"
ln -s "$state" "$t/aux/state"
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

: > "$t/aux/ran.txt"; touch "$t/aux/slow"
night || fail "night 2 exited $?: $(cat "$t/out.txt")"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/x.byn ] || fail "night 2 (wrap, then deadline stop) ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(cat "$state/cursor")" = selfhost/a/x.byn ] || fail "night 2 cursor $(cat "$state/cursor")"
log | grep -q 'stop: [0-9]*s left before .*, slowest file 86400s' || fail "night 2 log lacks the deadline stop: $(log)"

: > "$t/aux/ran.txt"; rm "$t/aux/slow"; echo 1 > "$state/slowest"
night || fail "night 3 exited $?: $(cat "$t/out.txt")"
[ "$(paste -sd, "$t/aux/ran.txt")" = selfhost/a/y.byn,selfhost/b/z.byn,selfhost/a/x.byn ] || fail "night 3 (resume after the cursor) ran $(paste -sd, "$t/aux/ran.txt")"
[ "$(tree)" = "$clean" ] || fail "the repo is not clean after night 3: $(diff <(echo "$clean") <(tree))"

: > "$t/aux/ran.txt"; rm "$state/slowest"
deadline=$(python3 -I -c 'import datetime; print((datetime.datetime.now() + datetime.timedelta(minutes=10)).strftime("%H:%M"))')
night || fail "night 4 exited $?: $(cat "$t/out.txt")"
[ ! -s "$t/aux/ran.txt" ] || fail "night 4 (10 min left, no file timed yet) ran $(paste -sd, "$t/aux/ran.txt")"
log | grep -q 'stop: [0-9]*s left before .*, slowest file 900s' || fail "night 4 log lacks the 15 min default stop: $(log)"

set +e
bash "$root/scripts/selfhost/mutate-nightly.sh" --deadline 25:00 --state "$state" > "$t/out.txt" 2>&1; [ $? = 2 ] || fail "a bad --deadline did not exit 2"
(cd "$t" && bash "$root/scripts/selfhost/mutate-nightly.sh" --deadline "$deadline" --state "$state" > "$t/out.txt" 2>&1); [ $? = 2 ] || fail "a run outside a repo root did not exit 2"
echo PASS
