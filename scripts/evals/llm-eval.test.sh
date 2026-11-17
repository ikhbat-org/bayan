#!/usr/bin/env bash
# Test for tools/llm-eval.byn `score` and `recheck` (spec 025 T2, T3). Scratch is under the repo's tmp/. Builds small task sets there at run
# time; the seed under evals/llm/tasks is only read.
#   bash scripts/evals/llm-eval.test.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
seed=evals/llm/tasks
root=$PWD/tmp/llm-eval-test
rm -rf "$root"; mkdir -p "$root/tasks" "$root/cand" "$root/out" "$root/rec"
trap 'rm -rf "$root"' EXIT

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
sandbox=none; $mac && sandbox=sandbox-exec

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
printf 'void main() {\n    var n: i64 = 0\n    while true {\n        n += 1\n    }\n}\n' > "$root/cand/loop.byn"
printf '/// Prints without end.\nvoid shout() {\n    while true {\n        print("a line that repeats")\n    }\n}\n' > "$root/cand/shout.byn"
cat "$seed/errors-001-prayer-time/reference/solution.byn" > "$root/cand/with-main.byn"
printf '\nvoid main() {\n}\n' >> "$root/cand/with-main.byn"

# Each seed reference gets four true (R8, R11).
for t in "$seed"/*/; do
  t=${t%/}; name=$(basename "$t")
  score "seed-$name" "$t" "$t/reference/solution.byn"
  check "$name: reference scores four true" "$code $(four "seed-$name") $(get "seed-$name" outcome)" '0 true true true true "pass"'
done

# A tests task passes under the sandbox from an empty cache/ (R15): the sample directory is new, so its cache/ starts empty.
r=seed-errors-001-prayer-time
check "tests task: sandbox named" "$(get $r sandbox)" "\"$sandbox\""
check "tests task: the sample's cache/ was used" "$([ -n "$(ls -A "$root/out/$r/work/errors-001-prayer-time/1/cache")" ] && echo used)" "used"

# A stdout task: the exit code is compared (R4).
score right "$exit3" "$root/cand/right.byn"; secsRight=$secs
check "exit code 3 as expected passes" "$code $(four right) $(get right outcome) $(get right passed)" '0 true true true true "pass" true'
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
  check "recheck: $1 names its reason" "$(case "$line" in *"$3"*) echo named ;; *) echo "$line" ;; esac)" "named"
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

echo "llm-eval.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
