#!/usr/bin/env bash
# Test for tools/llm-eval.byn `score`, `recheck` and `run` (spec 025 T2, T3, T7, T8). Scratch is under the repo's tmp/. Builds small task sets there at run
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
    --out "$root/out/run-$n" "$@" > "$root/rec/$n" 2> "$root/rec/$n.err"
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
bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" --model true --samples 0 > /dev/null 2>&1
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
bash scripts/bayan-tool.sh llm-eval run "$seed" --model "cat $root/cand/broken.byn" --only "$seedTask" --out "$root/out/seed-run" \
  > "$root/rec/seed-run" 2>&1
check "run: git status shows nothing written under the tasks directory" \
  "$? $(git status --porcelain --ignored --untracked-files=all -- "$seed" | wc -l | tr -d ' ') $(grep -c '"outcome": "no-compile"' "$root/out/seed-run/1/records.jsonl")" "0 0 1"

# The whole run, the tool and the stub, inside the launcher's network denial (R34). Writes go only under $root. The pin is
# found outside: pinned-bayan.sh touches the shared cache, which the sandbox denies. On macOS the scorer's own launches
# fail there (sandbox-exec cannot apply a second, different profile), so this checks that the run completes, not the score.
mkdir -p "$root/net-tmp" "$root/net-cache"
pinned=$(bash scripts/pinned-bayan.sh)
TMPDIR=$root/net-tmp BAYAN_CACHE=$root/net-cache bash scripts/evals/llm-sandbox.sh --write "$root" --stdout "$root/rec/net" \
  --status "$root/rec/net.status" -- env "PINNED_BAYAN=$pinned" bash scripts/bayan-tool.sh llm-eval run "$root/sets/run" \
  --model "sh $root/model.sh $root/reply-two $root/rec/net.prompt 7" --out "$root/out/run-net" 2> "$root/rec/net.err"
status() { sed -n "s/^$1: //p" "$root/rec/net.status"; }
check "run: completes inside the network denial" "$(status exit) $(status sandbox) $(get net tokens) $(cmp -s "$root/rec/net.prompt" "$root/want-plain" && echo same)" "0 $sandbox 7 same"

echo "llm-eval.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
