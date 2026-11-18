#!/usr/bin/env bash
# Test for tools/llm-eval.byn `score`, `recheck` and `run` (spec 025 T2, T3, T7, T8, T9). Scratch is under the repo's tmp/. Builds small task sets there at run
# time; the seed under evals/llm/tasks is only read. With a law id (L048, L049, L050) it runs only that law's cases.
#   bash scripts/evals/llm-eval.test.sh [<law id>]
set -uo pipefail
cd "$(dirname "$0")/../.."
only=${1:-}
seed=evals/llm/tasks
root=$PWD/tmp/llm-eval-test${only:+-$only}
rm -rf "$root"; mkdir -p "$root/tasks" "$root/cand" "$root/out" "$root/rec"
trap 'rm -rf "$root"' EXIT
export LLM_EVAL_STAMP_DIR=$root/stamps

pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
# score <name> <task-dir> <candidate>: the record goes to $root/rec/<name>, the exit code to $code, the seconds to $secs.
score() {
  local start=$(date +%s)
  bash scripts/bayan-tool.sh llm-eval score "$2" "$3" --out "$root/out/$1" > "$root/rec/$1" 2> "$root/rec/$1.err"
  code=$?
  secs=$(($(date +%s) - start))
}
# get <name> <key>: the value of <key> in the record, as JSON text.
get() { sed -n "s/.*\"$2\": \([^,}]*\).*/\1/p" "$root/rec/$1"; }
four() { echo "$(get "$1" compiles) $(get "$1" passes) $(get "$1" lintClean) $(get "$1" formatStable)"; }

mac=false
[ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ] && mac=true
sandbox=none; $mac && sandbox=sandbox-exec/2

# A stdout task that expects exit code 3, and a tests task whose test calls `shout()`.
header() { printf '# %s\n\nTitle: test task\nCategory: %s\nTier: 1\nSplit: dev\nRevision: 0023\nChecked: none\nCheck: %s\n\n## Files\n\n## Notes\n\n## Check command\n' "$1" "$2" "$3"; }
exit3=$root/tasks/small-900-exit-code
mkdir -p "$exit3/checks"
header small-900-exit-code small stdout > "$exit3/task.md"
printf 'salam\n' > "$exit3/checks/expected.stdout"
printf '3\n' > "$exit3/checks/exitcode"
loud=$root/tasks/errors-900-loud
mkdir -p "$loud/checks"
header errors-900-loud errors tests > "$loud/task.md"
printf 'void main() {\n}\n' > "$loud/checks/entry.byn"
printf 'test "shout prints" {\n    shout()\n}\n' > "$loud/checks/checks.test.byn"

printf 'i32 main() {\n    print("salam")\n    return 3\n}\n' > "$root/cand/right.byn"
printf 'i32 main() {\n    print("salam")\n    return 0\n}\n' > "$root/cand/wrong-code.byn"
printf 'i32 main() {\n    var code = 3\n    print("salam")\n    return code\n}\n' > "$root/cand/lint.byn"
printf 'void main() {\n    print(nope)\n}\n' > "$root/cand/broken.byn"
# The loop ends by itself after 40 seconds, so a scorer that failed to stop it leaves nothing running for long.
printf 'void main() {\n    let start = Io.monotonicNanos()\n    var n: i64 = 0\n    while Io.monotonicNanos() - start < 40000000000 {\n        n += 1\n    }\n}\n' > "$root/cand/loop.byn"
printf 'i32 main(ReadOnlySpan<string> args) {\n    if args.length > 0 {\n        while true {\n        }\n    }\n    var child = List<string>()\n    child.append("child")\n    let _ = Io.run("../bin/solution", child.span) catch return 1\n    print("salam")\n    return 3\n}\n' > "$root/cand/spawn.byn"
printf '/// Prints without end.\nvoid shout() {\n    while true {\n        print("a line that repeats")\n    }\n}\n' > "$root/cand/shout.byn"
cat "$seed/errors-001-prayer-time/reference/solution.byn" > "$root/cand/with-main.byn"
printf '\nvoid main() {\n}\n' >> "$root/cand/with-main.byn"

printf 'i32 main() {\n  print("salam")\n  return 3\n}\n' > "$root/cand/unformatted.byn"

# Law cases. Their titles start with the law id; with a law id as the argument only that law's cases run.
law() { [ -z "$only" ] || [ "$only" = "$1" ]; }

# L048: each seed reference gets four true (R8, R11). A failure names the task, the first result that is not true and the
# output of that step.
step() { case "$1" in (compiles) echo build.stdout ;; (passes) echo run.stdout test.json ;; (lintClean) echo check.stdout ;; (*) echo format.stdout ;; esac; }
if law L048; then
  for t in "$seed"/*/; do
    t=${t%/}; name=$(basename "$t")
    score "seed-$name" "$t" "$t/reference/solution.byn"
    check "L048: $name: reference scores four true" "$code $(four "seed-$name") $(get "seed-$name" outcome)" '0 true true true true "pass"'
    for k in compiles passes lintClean formatStable; do
      [ "$(get "seed-$name" $k)" = true ] && continue
      echo "  $name: $k $(get "seed-$name" $k) reference/solution.byn"
      for f in $(step $k); do [ -f "$root/out/seed-$name/work/$name/1/$f" ] && head -20 "$root/out/seed-$name/work/$name/1/$f" | sed 's/^/    /'; done
      sed 's/^/    /' "$root/rec/seed-$name.err"
      break
    done
  done
fi

# L049: every seed reference and one candidate of each failing kind, scored twice, each time in a new --out directory, give
# the same record (R9). The two scorings run at the same time, so the case fits the gate's time limit.
twice() {
  local s
  for s in a b; do
    { score "l049-$1-$s" "$2" "$3"; echo "$code" > "$root/rec/l049-$1-$s.code"; } &
  done
  wait
  check "L049: $1: $(basename "$3") scored twice in two --out directories, same record" \
    "$(cat "$root/rec/l049-$1-a.code") $(cat "$root/rec/l049-$1-b.code") $([ -s "$root/rec/l049-$1-a" ] && echo record) $(cat "$root/rec/l049-$1-b")" \
    "0 0 record $(cat "$root/rec/l049-$1-a")"
}
if law L049; then
  for t in "$seed"/*/; do
    t=${t%/}; twice "$(basename "$t")" "$t" "$t/reference/solution.byn"
  done
  for c in broken wrong-code lint unformatted loop; do twice "$c" "$exit3" "$root/cand/$c.byn"; done
fi

# L050: for every `dev` seed task, the prompt the runner sends holds no line of checks/ or reference/, except a line of
# prompt.md that is also a line of the task's starter/ or source.* (R3). Lines are trimmed; blank lines are not compared.
# A stub model records each prompt; the n-th record of records.jsonl is the task of the n-th prompt.
# Run only when named: 11 seed tasks fail it (spec 025 T38, PLAN-CHANGE), so it stays out of the whole run until they are fixed.
if [ "$only" = L050 ]; then
  mkdir -p "$root/l050"
  cat > "$root/l050.sh" <<'EOF'
n=$(( $(cat "$1/l050/count" 2> /dev/null || echo 0) + 1 ))
echo "$n" > "$1/l050/count"
cat > "$1/l050/prompt.$n"
cat "$1/cand/broken.byn"
EOF
  bash scripts/bayan-tool.sh llm-eval run "$seed" --model "sh $root/l050.sh $root" --machine m --out "$root/out/l050" \
    > "$root/rec/l050" 2> "$root/rec/l050.err"
  check "L050: the runner sends a prompt for every seed task" "$? $(wc -l < "$root/out/l050/1/records.jsonl" | tr -d ' ')" "0 $(ls -d "$seed"/*/ | wc -l | tr -d ' ')"
  n=0 dev=0 seen=0
  for name in $(sed -n 's/^{"task": "\([^"]*\)".*/\1/p' "$root/out/l050/1/records.jsonl"); do
    n=$((n + 1)); t=$seed/$name
    grep -q '^Split: dev$' "$t/task.md" || continue
    seen=$((seen + 1))
    quoted=$(find "$t/starter" "$t"/source.* -type f 2> /dev/null)
    hidden=$(find "$t/checks" "$t/reference" -type f | sort)
    leaks=$(awk 'function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
      { l = trim($0); if (l == "") next }
      mode == "q" { q[l] = 1; next }
      mode == "m" { m[l] = 1; next }
      mode == "p" { p[l] = 1; next }
      mode == "h" { if (!(l in h)) h[l] = FILENAME; next }
      (l in h) && !((l in m) && (l in q) && !(l in p)) { print h[l] ": \"" l "\"" }' \
      mode=q $quoted mode=m "$t/prompt.md" mode=p evals/llm/preamble.md mode=h $hidden mode=s "$root/l050/prompt.$n")
    check "L050: $name: no line of checks/ or reference/ in the prompt sent" "$leaks" ""
  done
  for t in "$seed"/*/; do grep -q '^Split: dev$' "$t/task.md" && dev=$((dev + 1)); done
  check "L050: every dev task checked" "$seen" "$dev"
fi

if [ -n "$only" ]; then
  echo "llm-eval.test $only: $pass passed, $fail failed"
  [ "$fail" = 0 ]; exit
fi

# A tests task passes under the sandbox from an empty cache/ (R15): the sample directory is new, so its cache/ starts empty.
r=seed-errors-001-prayer-time
check "tests task: sandbox named" "$(get $r sandbox)" "\"$sandbox\""
check "tests task: the sample's cache/ was used" "$([ -n "$(ls -A "$root/out/$r/work/errors-001-prayer-time/1/cache")" ] && echo used)" "used"

# A stdout task: the exit code is compared (R4).
score right "$exit3" "$root/cand/right.byn"; secsRight=$secs
check "exit code 3 as expected passes" "$code $(four right) $(get right outcome) $(get right passed)" '0 true true true true "pass" true'
# The program is primed before its timed run (R14): the prime's status file is there, dated before run.stdout.
mtime() { stat -f %Fm "$1" 2> /dev/null || stat -c %.9Y "$1" 2> /dev/null || echo none; }
s=$root/out/right/work/small-900-exit-code/1
check "the run is primed first" "$(head -1 "$s/prime.stdout.status" 2> /dev/null) $(awk -v a="$(mtime "$s/prime.stdout.status")" \
  -v b="$(mtime "$s/run.stdout")" 'BEGIN { print (a != "none" && b != "none" && a + 0 < b + 0) ? "before" : "not before" }')" \
  "exit: 0 before"
score wrong-code "$exit3" "$root/cand/wrong-code.byn"
check "wrong exit code fails" "$code $(four wrong-code) $(get wrong-code outcome) $(get wrong-code passed)" '0 true false true true "fail" false'

# A candidate that does not compile: compiles false, the other three not reached (R11).
score broken "$exit3" "$root/cand/broken.byn"
check "no compile" "$code $(four broken) $(get broken outcome)" '0 false "not reached" "not reached" "not reached" "no-compile"'

# A tests candidate with a main does not compile (R5, R10).
score with-main "$seed/errors-001-prayer-time" "$root/cand/with-main.byn"
check "tests candidate with a main" "$code $(get with-main compiles) $(get with-main passed) $(get with-main outcome)" '0 false false "no-compile"'

# A candidate that loops reaches the run limit, not the build limit (R14).
score loop "$exit3" "$root/cand/loop.byn"
check "loop gives limit" "$code $(get loop compiles) $(get loop passes) $(get loop outcome)" '0 true false "limit"'
check "loop is stopped at the run limit" "$([ $((secs - secsRight)) -ge 8 ] && [ $((secs - secsRight)) -le 30 ] && echo yes)" "yes"
# The time limit reaches the launcher as TERM; its sweep kills the candidate, which runs in a process group of its own (M3).
# Each later launch on the sample sweeps it too, so llm-sandbox.test.sh tests the TERM sweep alone.
if $mac; then
  check "loop leaves no process" "$(lsof -a -d txt -u "$(id -u)" -Fn 2> /dev/null | grep -c "^n$root/out/loop/")" "0"
fi

# A stdout candidate that starts a child (which would run without end) cannot fork on macOS, so it fails, and nothing of it
# is left running (M3).
if $mac; then
  score spawn "$exit3" "$root/cand/spawn.byn"
  check "a candidate that starts a child fails and leaves no process" \
    "$code $(get spawn outcome) $(lsof -a -d txt -u "$(id -u)" -Fn 2> /dev/null | grep -c "^n$root/out/spawn/")" '0 "fail" 0'
fi

# A launcher whose probe does not run the program (exit 65, as sandbox-exec gives for a profile it refuses): the scoring
# fails and writes no record (M1). The stub sits in a copy of the files the tool needs.
fake=$root/fake-repo
mkdir -p "$fake/scripts/evals" "$fake/tools" "$fake/evals/llm"
cp scripts/bayan-tool.sh scripts/pinned-bayan.sh "$fake/scripts/"
cp tools/llm-eval.byn "$fake/tools/"
cp evals/llm/preamble.md "$fake/evals/llm/"
cat > "$fake/scripts/evals/llm-sandbox.sh" <<'EOF'
while [ $# -gt 0 ]; do case "$1" in (--status) status=$2; shift 2 ;; (--stdout) : > "$2"; shift 2 ;; (--) break ;; (*) shift ;; esac; done
printf 'exit: 65\nlimit: false\nsandbox: stub\n' > "$status"
EOF
PINNED_BAYAN=$(bash scripts/pinned-bayan.sh) bash "$fake/scripts/bayan-tool.sh" llm-eval score "$exit3" "$root/cand/right.byn" \
  --out "$root/out/probe" > "$root/rec/probe" 2> "$root/rec/probe.err"
check "a probe that exits non-zero fails the scoring, no record" "$([ $? != 0 ] && echo failed) $(wc -c < "$root/rec/probe" | tr -d ' ')" "failed 0"

# A test that prints without end reaches the per-test run limit (R14).
score shout "$loud" "$root/cand/shout.byn"
check "endless printing test gives limit" "$code $(get shout compiles) $(get shout passes) $(get shout outcome)" '0 true false "limit"'

# The same candidate scored twice gives the same record (R9); a lint warning in solution.byn is not lint-clean (R11, R12).
score lint1 "$exit3" "$root/cand/lint.byn"
score lint2 "$exit3" "$root/cand/lint.byn"
check "lint warning: passed, not lint-clean" "$(four lint1) $(get lint1 passed)" 'true true false true true'
check "scored twice, same record" "$(cat "$root/rec/lint2")" "$(cat "$root/rec/lint1")"

# An existing sample directory is refused; bad usage exits 2.
score lint1 "$exit3" "$root/cand/lint.byn"
check "existing sample directory refused" "$code $(grep -c 'exists' "$root/rec/lint1.err")" "1 1"
bash scripts/bayan-tool.sh llm-eval score "$exit3" > /dev/null 2>&1
check "usage" "$?" "2"

# recheck (T3). Each case is its own task set under $root/sets/<case>, made from one good stdout task (the exit-code task
# above with a full header) and one good repair task; a case changes one thing.
# recheck <case> [args...]: the output goes to $root/rec/rc-<case>, the exit code to $code.
recheck() {
  local c=$1; shift
  bash scripts/bayan-tool.sh llm-eval recheck "$root/sets/$c" --out "$root/out/rc-$c" "$@" > "$root/rec/rc-$c" 2>&1
  code=$?
}
full() { printf '# %s\n\nTitle: %s\nCategory: %s\nTier: 1\nSplit: dev\nRevision: 0023\nChecked: bayan 0.3.3-dev (commit 5810cf25b398)\nCheck: stdout\n\n## Files\n\n## Notes\n\n## Check command\n' "$1" "$2" "$3"; }
# good <case> <dir-name> <category>: a passing task of <category> in set <case>.
good() {
  local t=$root/sets/$1/$2
  mkdir -p "$t/checks" "$t/reference"
  cp "$exit3/checks/expected.stdout" "$exit3/checks/exitcode" "$t/checks/"
  cp "$root/cand/right.byn" "$t/reference/solution.byn"
  printf 'Write a program that prints a greeting and exits with code 3.\n' > "$t/prompt.md"
  if [ "$3" = repair ]; then
    full "$2" "Repair BYN5005" repair > "$t/task.md"
    mkdir -p "$t/starter"
    printf 'i64 sum(i64 a, by i64 b) => a + b\n\ni32 main() {\n    print("salam")\n    return i32(sum(1, 2))\n}\n' > "$t/starter/solution.byn"
  else
    full "$2" "Greeting" "$3" > "$t/task.md"
  fi
}
for c in ok lint unformatted header name twice compiles other-code leak; do
  good $c small-900-salam small
  good $c repair-900-greeting repair
done
s=$root/sets
cp "$root/cand/lint.byn" "$s/lint/small-900-salam/reference/solution.byn"
printf 'i32 main() {\n  print("salam")\n  return 3\n}\n' > "$s/unformatted/small-900-salam/reference/solution.byn"
grep -v '^Revision:' "$s/header/small-900-salam/task.md" > "$s/header/x" && mv "$s/header/x" "$s/header/small-900-salam/task.md"
mv "$s/name/small-900-salam" "$s/name/small-90-salam"
good twice small-900-again small
cp "$root/cand/right.byn" "$s/compiles/repair-900-greeting/starter/solution.byn"
cp "$root/cand/broken.byn" "$s/other-code/repair-900-greeting/starter/solution.byn"
printf 'Print this:\n\nsalam\n' > "$s/leak/small-900-salam/prompt.md"

recheck ok
check "recheck: good set passes" "$code $(grep -c '^PASS' "$root/rec/rc-ok") $(grep -c '^slowest run: [0-9]* ms (' "$root/rec/rc-ok")" "0 2 1"
# fails <case> <task> <reason>: recheck of <case> exits 1 with FAIL <task> naming <reason>, and the other task passes.
fails() {
  recheck "$1"
  local line; line=$(grep "^FAIL $2: " "$root/rec/rc-$1")
  check "recheck: $1 fails" "$code $(grep -c '^FAIL' "$root/rec/rc-$1") $(grep -c '^PASS' "$root/rec/rc-$1")" "1 1 1"
  check "recheck: $1 names its reason" "$(case "$line" in (*"$3"*) echo named ;; (*) echo "$line" ;; esac)" "named"
}
fails lint small-900-salam "lint-clean false"
fails unformatted small-900-salam "format-stable false"
fails header small-900-salam 'no `Revision:` line'
fails name small-90-salam "not <category>-<NNN>-<slug>"
fails compiles repair-900-greeting "starter/solution.byn compiles"
fails other-code repair-900-greeting "not only BYN5005"
fails leak small-900-salam "whole of checks/expected.stdout"
recheck twice
check "recheck: a number used twice fails both" "$code $(grep -c '^FAIL small-900-.*: number small-900 is also used by' "$root/rec/rc-twice")" "1 2"

# --only checks one task: the failing one is left out.
recheck leak --only repair-900-greeting
check "recheck --only" "$code $(grep -c '^PASS\|^FAIL' "$root/rec/rc-leak") $(grep -c '^PASS repair-900-greeting$' "$root/rec/rc-leak")" "0 1 1"
recheck leak --only small-999-none
check "recheck --only an unknown task" "$code" "1"

# run (T7). A stub model command records the prompt on its standard input, prints a canned reply, and prints
# `tokens: <n>` on standard error when given <n>.
#   sh model.sh <reply-file> <prompt-file> [<n>]
good run small-900-salam small
t=$root/sets/run/small-900-salam
cat > "$root/model.sh" <<'EOF'
cat > "$2"
cat "$1"
if [ -n "${3:-}" ]; then echo "tokens: $3" >&2; fi
EOF
printf 'Some words about Bayan.\n' > "$root/context.md"
fence='```'
{ printf 'First try:\n\n%sbayan\n' "$fence"; cat "$root/cand/wrong-code.byn"; printf '%s\n\nBetter:\n\n%sbayan\n' "$fence" "$fence"
  cat "$root/cand/right.byn"; printf '%s\n' "$fence"; } > "$root/reply-two"
cp "$root/cand/right.byn" "$root/reply-none"
# run <name> <reply> [<n>] [run args...]: the stub's prompt goes to $root/rec/<name>.prompt, the record to $root/rec/<name>.
run() {
  local n=$1 reply=$2 tokens=$3; shift 3
  bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model "sh $root/model.sh $root/$reply $root/rec/$n.prompt $tokens" \
    --out "$root/out/run-$n" --machine "test machine" "$@" > "$root/rec/$n" 2> "$root/rec/$n.err"
  code=$?
}
run two reply-two 42 --context "$root/context.md"
{ cat evals/llm/preamble.md; echo; cat "$root/context.md"; echo; cat "$t/prompt.md"; } > "$root/want-context"
check "run: prompt is preamble, context, prompt.md" "$code $(cmp -s "$root/rec/two.prompt" "$root/want-context" && echo same)" "0 same"
cat "$t"/checks/* "$t"/reference/* | grep -v '^[[:space:]]*$' > "$root/hidden-lines"
check "run: no line of checks/ or reference/ in the prompt" "$(grep -cFxf "$root/hidden-lines" "$root/rec/two.prompt")" "0"
check "run: two code blocks, the last is scored" "$(get two outcome) $(get two passed)" '"pass" true'
check "run: tokens read from standard error" "$(get two tokens)" "42"
check "run: wall time and reply recorded" "$([ -n "$(get two wallMs)" ] && grep -c '"reply": "First try:' "$root/rec/two")" "1"

run none reply-none ""
{ cat evals/llm/preamble.md; echo; cat "$t/prompt.md"; } > "$root/want-plain"
check "run: prompt without context is preamble, prompt.md" "$code $(cmp -s "$root/rec/none.prompt" "$root/want-plain" && echo same)" "0 same"
check "run: no code block, the whole reply is scored" "$(get none outcome) $(get none passed)" '"pass" true'
check "run: no tokens line, no tokens field" "$(grep -c '"tokens"' "$root/rec/none")" "0"
bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" > /dev/null 2>&1
check "run: no --model is usage" "$?" "2"
bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model true --machine m --remote p > /dev/null 2>&1
check "run: --machine with --remote is usage" "$?" "2"
bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model true --machine m --samples 0 > /dev/null 2>&1
check "run: --samples 0 is usage" "$?" "2"

# Samples, records and summary (T8). Four stdout tasks, each prompt tagged; a stub model command answers sample <n> of
# task <tag> with $root/plan/<tag>.<n> and prints `tokens: <t>` on standard error when given <t>.
#   sh stats.sh <root> [<t>]
# Candidates: right passes with all four; wrong-code compiles, fails, lint-clean, format-stable; broken does not compile;
# lint passes, compiles, not lint-clean, format-stable.
#   task              category tier revision  sample 1    sample 2    sample 3
#   small-901-a       small    1    0023      right       broken      broken
#   small-902-b       small    2    0023      wrong-code  wrong-code  right
#   errors-901-c      errors   1    0023      broken      wrong-code  wrong-code
#   errors-902-d      errors   2    0024      lint        broken      broken
# Hand counts (tasks, pass@1, pass@3, compile, lint-clean, format-stable; rates are count / tasks):
#   overall  4  2 3 3 2 3   (pass@1 a d; pass@3 a b d; compile a b d; lint-clean a b; format-stable a b d)
#   small    2  1 2 2 2 2
#   errors   2  1 1 1 0 1
#   tier 1   2  1 1 1 1 1   (a c)
#   tier 2   2  1 2 2 1 2   (b d)
#   0023     3  1 2 2 2 2   (a b c)
#   0024     1  1 1 1 0 1   (d)
st=$root/sets/stats
mkdir -p "$root/plan" "$root/count"
for spec in small-901-a:small:1:0023 small-902-b:small:2:0023 errors-901-c:errors:1:0023 errors-902-d:errors:2:0024; do
  IFS=: read -r name cat tier rev <<< "$spec"
  good stats "$name" "$cat"
  sed -i.bak -e "s/^Tier: 1$/Tier: $tier/" -e "s/^Revision: 0023$/Revision: $rev/" "$st/$name/task.md"; rm "$st/$name/task.md.bak"
  printf 'Write a program that prints a greeting and exits with code 3.\n\nTag: %s\n' "${name##*-}" > "$st/$name/prompt.md"
done
plan() { local tag=$1; shift; local n=1; for c in "$@"; do cp "$root/cand/$c.byn" "$root/plan/$tag.$n"; n=$((n + 1)); done; }
plan a right broken broken broken
plan b wrong-code wrong-code right
plan c broken wrong-code wrong-code
plan d lint broken broken
cat > "$root/stats.sh" <<'EOF'
tag=$(sed -n 's/^Tag: //p')
n=$(( $(cat "$1/count/$tag" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$1/count/$tag"
cat "$1/plan/$tag.$n"
if [ -n "${2:-}" ]; then echo "tokens: $2" >&2; fi
EOF
find "$st" -type f | sort | xargs shasum > "$root/stats-before"
bash scripts/bayan-tool.sh llm-eval run "$st" --model "sh $root/stats.sh $root" --samples 3 --context "$root/context.md" \
  --settings "temperature 0.2" --label stub --machine "Mac test, M1, 64 GB, macOS, stub, none" \
  --out "$root/out/stats" > "$root/rec/stats" 2> "$root/rec/stats.err"
code=$?
out=$root/out/stats/1
recs() { grep -c "\"task\": \"$1\"" "$out/records.jsonl"; }
check "run --samples 3: three records per task" \
  "$code $(wc -l < "$out/records.jsonl" | tr -d ' ') $(recs small-901-a) $(recs small-902-b) $(recs errors-901-c) $(recs errors-902-d) $(grep -c '"sample": 3,' "$out/records.jsonl") $(wc -l < "$root/rec/stats" | tr -d ' ')" \
  "0 12 3 3 3 3 4 12"
flat=$(tr -d ' \n' < "$out/summary.json")
# blk <tasks> <pass@1> <pass@k> <compile> <lint-clean> <format-stable>: the metrics object of the summary.
blk() {
  local n=$1 s="{\"tasks\":$1" k; shift
  for k in pass@1 pass@k compile lintClean formatStable; do
    s="$s,\"$k\":{\"count\":$1,\"rate\":$(awk "BEGIN { printf \"%.4f\", $1 / $n }")}"; shift
  done
  echo "$s}"
}
holds() { case "$flat" in *"$1"*) echo holds ;; *) echo "missing $1" ;; esac; }
check "summary: overall hand counts" "$(holds "\"overall\":$(blk 4 2 3 3 2 3)")" holds
check "summary: per category hand counts" "$(holds "\"small\":$(blk 2 1 2 2 2 2)") $(holds "\"errors\":$(blk 2 1 1 1 0 1)")" "holds holds"
check "summary: per tier hand counts" "$(holds "\"1\":$(blk 2 1 1 1 1 1)") $(holds "\"2\":$(blk 2 1 2 2 1 2)")" "holds holds"
check "summary: per revision hand counts" "$(holds "\"0023\":$(blk 3 1 2 2 2 2)") $(holds "\"0024\":$(blk 1 1 1 1 0 1)")" "holds holds"
commit=$(git rev-parse HEAD)
compiler=$("$(bash scripts/pinned-bayan.sh)" --version)
ccommit=$(echo "$compiler" | sed -n 's/.*(commit \([0-9a-f]*\)).*/\1/p')
# A self-hosted compiler names no commit; the tool then takes the commit the pin's ref resolves to.
ccommit=${ccommit:-$(git rev-parse -q --verify "${PINNED_BAYAN_REF:-dev}^{commit}")}
check "summary: names commits, revisions, context, k, settings, limits, sandbox, machine" \
  "$(holds "\"taskSetCommit\":\"$commit\"") $(holds "\"compiler\":\"$(echo "$compiler" | tr -d ' ')\"") $(holds "\"compilerCommit\":\"$ccommit\"") $(holds '"revisions":["0023","0024"]') $(holds "\"context\":\"$(echo "$root/context.md" | tr -d ' ')\"") $(holds '"k":3,') $(holds '"settings":"temperature0.2"') $(holds '"limits":{"buildSeconds":120,"runSeconds":10,"outputBytes":1048576}') $(holds "\"sandbox\":\"$sandbox\"") $(holds '"machine":"Mactest,M1,64GB,macOS,stub,none"') $(holds '"split":"dev"')" \
  "holds holds holds holds holds holds holds holds holds holds holds"
check "summary: no tokens line, no tokens per second" "$(grep -c '"tokens' "$out/summary.json") $(holds '"speed":{"samples":12,"wallMs":')" "0 holds"
check "run: nothing written under the tasks directory" "$(find "$st" -type f | sort | xargs shasum | cmp -s - "$root/stats-before" && echo same)" "same"

# --remote names the provider; a `tokens:` line on every sample gives tokens per second.
bash scripts/bayan-tool.sh llm-eval run "$st" --model "sh $root/stats.sh $root 50" --only small-901-a --remote example-provider \
  --out "$root/out/stats-remote" > "$root/rec/stats-remote" 2>&1
code=$?
flat=$(tr -d ' \n' < "$root/out/stats-remote/1/summary.json")
check "summary: remote with provider, tokens per second when printed" \
  "$code $(holds '"machine":"remote","provider":"example-provider"') $(holds '"k":1,') $(holds '"tokens":50,"tokensPerSecond":') $(holds '"context":"none"') $(holds '"settings":"none"')" \
  "0 holds holds holds holds holds"

# A run over the seed leaves git status of the tasks directory clean (R37).
seedTask=$(basename "$(ls -d "$seed"/*/ | head -1)")
bash scripts/bayan-tool.sh llm-eval run "$seed" --model "cat $root/cand/broken.byn" --only "$seedTask" --machine m --out "$root/out/seed-run" \
  > "$root/rec/seed-run" 2>&1
check "run: git status shows nothing written under the tasks directory" \
  "$? $(git status --porcelain --ignored --untracked-files=all -- "$seed" | wc -l | tr -d ' ') $(grep -c '"outcome": "no-compile"' "$root/out/seed-run/1/records.jsonl")" "0 0 1"

# The whole run, the tool and the stub, inside a network denial (R34). Writes go only under $root. The pin is found
# outside: pinned-bayan.sh touches the shared cache, which the sandbox denies.
mkdir -p "$root/net-tmp" "$root/net-cache"
pinned=$(bash scripts/pinned-bayan.sh)
if $mac; then
  # The launcher's own profile cannot hold the tool (it denies reads of the repo and exec of anything but its program), so
  # the denial here is a profile of network and writes only. The scorer's launches cannot apply their profile inside it
  # (sandbox-exec cannot apply a second one), so the probe fails and the run stops there, after the model command ran.
  real=$(cd "$root" && pwd -P)
  env -i "HOME=$root/net-tmp" "PATH=$PATH" "TMPDIR=$root/net-tmp" "BAYAN_CACHE=$root/net-cache" "DOTNET_ROOT=${DOTNET_ROOT:-}" \
    "PINNED_BAYAN=$pinned" /usr/bin/sandbox-exec -p "(version 1) (allow default) (deny network*) (deny file-write*)
      (allow file-write* (literal \"/dev/null\") (literal \"/dev/dtracehelper\") (subpath \"$real\"))" \
    bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model "sh $root/model.sh $root/reply-two $root/rec/net.prompt 7" \
    --machine m --out "$root/out/run-net" > "$root/rec/net" 2> "$root/rec/net.err"
  check "run: inside the network denial the model command runs, then the probe stops the scoring" \
    "$([ $? != 0 ] && echo stopped) $(grep -c "the launcher's probe exited" "$root/rec/net.err") $(cmp -s "$root/rec/net.prompt" "$root/want-plain" && echo same)" "stopped 1 same"
else
  TMPDIR=$root/net-tmp BAYAN_CACHE=$root/net-cache bash scripts/evals/llm-sandbox.sh --write "$root" --stdout "$root/rec/net" \
    --status "$root/rec/net.status" -- env "PINNED_BAYAN=$pinned" bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" \
    --model "sh $root/model.sh $root/reply-two $root/rec/net.prompt 7" --machine m --out "$root/out/run-net" 2> "$root/rec/net.err"
  status() { sed -n "s/^$1: //p" "$root/rec/net.status"; }
  check "run: completes inside the network denial" "$(status exit) $(status sandbox) $(get net tokens) $(cmp -s "$root/rec/net.prompt" "$root/want-plain" && echo same)" "0 $sandbox 7 same"
  [ "$(status exit)" = 0 ] || { echo "  net.status:"; sed 's/^/    /' "$root/rec/net.status"; echo "  net.err (last 40 lines):"; tail -40 "$root/rec/net.err" | sed 's/^/    /'; }
fi

# Stamp and heldout guard (T9). A git repository holding a set with one `dev` and one `Split: heldout` task, both
# synthetic. The stamp goes to $LLM_EVAL_STAMP_DIR, under $root.
good held small-900-salam small
good held small-901-kept small
hs=$root/sets/held
sed -i.bak 's/^Split: dev$/Split: heldout/' "$hs/small-901-kept/task.md"; rm "$hs/small-901-kept/task.md.bak"
g() { git -C "$hs" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
g init -q && g add -A && g commit -qm tasks
hcommit=$(g rev-parse HEAD)
stamp=$LLM_EVAL_STAMP_DIR/$hcommit-$ccommit
# hrun <name> [run args...]: run over the set with a stub that answers right; output in $root/rec/<name>, summary in $flat.
hrun() {
  local n=$1; shift
  bash scripts/bayan-tool.sh llm-eval run "$hs" --model "cat $root/cand/right.byn" --out "$root/out/$n" "$@" > "$root/rec/$n" 2>&1
  code=$?
  flat=$({ tr -d ' \n' < "$root/out/$n/1/summary.json"; } 2> /dev/null)
}

# Uncommitted changes: recheck passes, writes no stamp.
printf '\n' >> "$hs/small-900-salam/prompt.md"
recheck held
check "recheck: uncommitted changes, no stamp" "$code $(grep -c '^PASS' "$root/rec/rc-held") $(grep -c '^no stamp: the tasks directory has uncommitted changes' "$root/rec/rc-held") $([ -e "$stamp" ] && echo stamp || echo none)" "0 2 1 none"
g checkout -q -- .

# No stamp: verified false, no headline; both splits give two blocks, never one number over both.
hrun held-none --remote example-provider
check "run: heldout without a stamp is not verified and has no headline" "$code $(holds '"verified":false') $(grep -c '"headline"' "$root/out/held-none/1/summary.json")" "0 holds 0"
check "run: both splits give two blocks" \
  "$(holds '"splits":[{"split":"') $(holds '"split":"dev","overall":{"tasks":1,') $(holds '"split":"heldout","overall":{"tasks":1,') $(grep -c '"tasks": 2' "$root/out/held-none/1/summary.json")" \
  "holds holds holds 0"

# A committed set: a passing recheck writes the stamp named by both commits; run then writes the headline.
recheck held
check "recheck: committed set writes the stamp named by both commits" \
  "$code $(grep -c "^stamp: $stamp\$" "$root/rec/rc-held") $(sed -n 's/^taskSetCommit: //p' "$stamp" 2> /dev/null)" "0 1 $hcommit"
recheck held --only small-900-salam
check "recheck --only writes no stamp" "$code $(grep -c '^no stamp: --only' "$root/rec/rc-held")" "0 1"
hrun held-stamped --remote example-provider
check "run: heldout with the stamp is verified and has the headline" \
  "$code $(holds '"verified":true') $(holds '"headline":{"split":"heldout","tasks":1,"pass@1":{"count":1,"rate":1.0000}}')" "0 holds holds"
# --only scores part of the set: no headline, even when verified (R21).
hrun held-only --remote example-provider --only small-901-kept
check "run: --only writes no headline" "$code $(holds '"verified":true') $(grep -c '"headline"' "$root/out/held-only/1/summary.json")" "0 holds 0"
# The stamp does not verify the same commit once a file is changed.
printf '\n' >> "$hs/small-900-salam/prompt.md"
hrun held-dirty --remote example-provider
check "run: uncommitted changes are not verified" "$code $(holds '"verified":false') $(grep -c '"headline"' "$root/out/held-dirty/1/summary.json")" "0 holds 0"
g checkout -q -- .

# A compiler whose version line names no commit (a self-hosted one): the commit comes from the pin's ref, in its own stamp
# field; with no commit from either, no stamp. The fake answers --version and hands everything else to the real compiler,
# which runs the tool. The set it rechecks is committed and holds no task, so no scored step runs: the sandbox lets a step
# exec the program alone, so the fake could not hand a step on.
real=$(bash scripts/pinned-bayan.sh)
printf '#!/bin/sh\nif [ "$1" = --version ]; then echo "bayan 0.3.3-dev (selfhost)"; exit 0; fi\nexec "%s" "$@"\n' "$real" > "$root/fake-bayan"
chmod +x "$root/fake-bayan"
mkdir -p "$root/sets/empty"
printf 'No tasks.\n' > "$root/sets/empty/README.md"
ge() { git -C "$root/sets/empty" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
ge init -q && ge add -A && ge commit -qm empty
ecommit=$(ge rev-parse HEAD)
pincommit=$(git rev-parse HEAD)
pstamp=$LLM_EVAL_STAMP_DIR/$ecommit-$pincommit
PINNED_BAYAN=$root/fake-bayan PINNED_BAYAN_REF=HEAD recheck empty
check "recheck: version line without a commit, the stamp takes the pin's commit" \
  "$code $(grep -c "^stamp: $pstamp\$" "$root/rec/rc-empty") $(sed -n 's/^compilerCommit: //p' "$pstamp" 2> /dev/null) $(grep -c '^compiler: bayan 0.3.3-dev (selfhost)$' "$pstamp" 2> /dev/null)" "0 1 $pincommit 1"
PINNED_BAYAN=$root/fake-bayan PINNED_BAYAN_REF=no-such-ref recheck empty
check "recheck: no commit from the version line or the pin, no stamp" \
  "$code $(grep -c '^no stamp: neither' "$root/rec/rc-empty") $(ls "$LLM_EVAL_STAMP_DIR" | wc -l | tr -d ' ')" "0 1 2"

# --remote is required for a heldout run without --machine (and --machine or --remote for any run, R32).
hrun held-anon
check "run: heldout without --machine or --remote is refused" \
  "$code $(grep -c 'needs --machine <text> or --remote <provider>' "$root/rec/held-anon") $([ -e "$root/out/held-anon" ] && echo out || echo none)" "2 1 none"
hrun held-machine --machine "test machine"
check "run: heldout with --machine runs" "$code $(holds '"machine":"testmachine"')" "0 holds"
bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model true > /dev/null 2>&1
check "run: dev without --machine or --remote is refused" "$?" "2"

# records.jsonl is appended to per sample (R37): the stub model counts the lines already there when it is called, so a
# full rewrite at the end shows 0 0 0, not 0 1 2.
cat > "$root/appended.sh" <<'EOF'
cat > /dev/null
if [ -f "$1/out/appended/1/records.jsonl" ]; then wc -l < "$1/out/appended/1/records.jsonl" | tr -d ' ' >> "$1/appended.log"; else echo 0 >> "$1/appended.log"; fi
cat "$1/cand/right.byn"
EOF
bash scripts/bayan-tool.sh llm-eval run "$st" --model "sh $root/appended.sh $root" --only small-901-a --samples 3 --machine m \
  --out "$root/out/appended" > "$root/rec/appended" 2>&1
check "run: records.jsonl grows by one line per sample, not rewritten at the end" "$? $(tr '\n' ' ' < "$root/appended.log")" "0 0 1 2 "

# Marker check (T10b, R24). A synthetic marker made now; no marker string is kept in the repository. Set `mk` holds a
# `dev` task without the marker and two `heldout` tasks, one marked in every file that is not exempt, one not.
marker=TESTMARK-$RANDOM-$(date +%s)-$RANDOM
good mk small-900-dev small
good mk small-901-marked small
good mk small-902-bare small
mk=$root/sets/mk
for t in small-901-marked small-902-bare; do
  sed 's/^Split: dev$/Split: heldout/' "$mk/$t/task.md" > "$root/m.tmp"; mv "$root/m.tmp" "$mk/$t/task.md"
done
# markit <task>: the marker in every file that is not exempt (a comment line first in the `.byn` file).
markit() {
  local t=$mk/$1 f
  for f in task.md prompt.md; do printf '\n%s\n' "$marker" >> "$t/$f"; done
  { printf '// %s\n' "$marker"; cat "$t/reference/solution.byn"; } > "$root/m.tmp"; mv "$root/m.tmp" "$t/reference/solution.byn"
}
markit small-901-marked
recheck mk
check "recheck: no MARKER file, the marker check is skipped" "$code $(grep -c '^PASS' "$root/rec/rc-mk")" "0 3"
printf '%s\n' "$marker" > "$mk/MARKER"
recheck mk
check "recheck: MARKER present, a heldout file without the string fails" \
  "$code $(grep -c '^FAIL small-902-bare: no marker in ' "$root/rec/rc-mk") $(grep '^FAIL small-902-bare' "$root/rec/rc-mk" | grep -o 'task.md\|prompt.md\|reference/solution.byn' | wc -l | tr -d ' ')" "1 1 3"
check "recheck: MARKER present, every non-exempt file marked passes; exempt files and dev tasks need none" \
  "$(grep -c '^PASS small-901-marked' "$root/rec/rc-mk") $(grep -c '^PASS small-900-dev' "$root/rec/rc-mk") $(grep -c "$marker" "$mk/small-901-marked/checks/expected.stdout")" "1 1 0"
markit small-902-bare
recheck mk
check "recheck: MARKER present, every heldout task marked passes" "$code $(grep -c '^PASS' "$root/rec/rc-mk")" "0 3"

echo "llm-eval.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
