#!/bin/bash
# preflight.sh on a fixture repo under tmp/, run by /bin/bash (3.2 on macOS), with a fake dotnet on PATH and a fake pinned bayan: a clean branch is
# all `ok` but wp1 until tmp/wp1/<sha>.out holds a passing run of every class, then exits 0; each check fails on its own fixture:
# cites (past the end, a quoted symbol not on a single cited line or the 2 after it, nor in a cited range, a missing file; a bare name resolves), files (a brace list is one name each; a listed .github/ workflow passes; prints the addition),
# questions (a number twice, one already on the base, one outside the range, a task with no range; a range from the task line or
# BAYAN_QRANGES), tests (a class from the file's declaration, not its name; a class that matches no test, a failed test, a build
# error, plan-strings-check), wp1 (missing, not `exit 0`, no tests, a filter without a class, uncommitted changes); on a checkout of
# the branch it checks the working tree. It exits early on a spec with no specs.tsv row, an unknown branch or base, a worktree it
# cannot make, or a branch with no merge base; a pinned bayan that cannot be found fails the tests check.
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
r="$root/tmp/preflight-test"; aux="$root/tmp/preflight-test-aux"
rm -rf "$r" "$aux" && mkdir -p "$r/docs/specs/012-self-hosted-bootstrap" "$r/src" "$r/tests/Bayan.Tests" "$aux/bin" && cd "$r"
git init -q -b base && git config user.email t@t && git config user.name t
printf 'tmp/\n' > .gitignore
cat > docs/specs/012-self-hosted-bootstrap/012-tasks.md <<'EOF'
- [ ] T99 fixture — files: `src/a.c`, `.github/workflows/r.yml`, `src/{d,e}.c`, `bootstrap/r.c`, `scripts/r.sh`, `tests/Bayan.Tests/FooInventoryTests.cs` (declares `FooT8Tests`, not `x.cs`) — covers: R1 — done when: x
- [ ] T98 fixture — files: `src/a.c` — covers: R1 — Questions Q300–Q304
- [ ] T97 fixture — files: `src/a.c` — covers: R1
EOF
: > docs/specs/012-self-hosted-bootstrap/012-plan.md
printf '100. old\n101. older\n' > docs/bayan-questions.md
mkdir -p docs/decisions; printf '203. answered\n' > docs/decisions/2026-11-14-004-answered-questions.md
printf 'int alpha;\nint beta;\nint gamma;\n' > src/a.c
printf 'namespace Bayan.Tests;\npublic sealed class FooT8Tests { }\n' > tests/Bayan.Tests/FooInventoryTests.cs
git add -A && git commit -qm "test: base"
printf 'spec\ttask\tfirst\tlast\n012\tT99\t200\t204\n' > "$aux/q.tsv"
cat > "$aux/bin/dotnet" <<'EOF'
#!/bin/bash
case "$1" in
  build) [ -f "$AUX/build-fail" ] && { echo "a.cs(1,1): error CS1002: ; expected"; exit 1; }; exit 0;;
  test) echo "$*" > "$AUX/test-args"; cat "$AUX/test-out"; exit "$(cat "$AUX/test-rc")";;
esac
EOF
printf '#!/bin/bash\n[ -f "$AUX/tool-fail" ] && { echo "BYN1001 message missing"; exit 1; }; echo ok\n' > "$aux/bayan"
chmod +x "$aux/bin/dotnet" "$aux/bayan"
export AUX=$aux PINNED_BAYAN=$aux/bayan  # scripts/bayan-tool.sh runs it for plan-strings-check
passing() { printf '  Passed Bayan.Tests.%s.A [1 ms]\n' FooT8Tests CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests > "$aux/test-out"; echo 0 > "$aux/test-rc"; }
passing
# br <name> <file> <line>…: a branch off base appending each line to its file
br() { git switch -q -c "$1" base; shift; while [ $# -gt 0 ]; do mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" >> "$1"; shift 2; done
  git add -A; git commit -qm "test: branch"; git switch -q base; }
pf() { PATH="$aux/bin:$PATH" BAYAN_BASE=base BAYAN_QRANGES=$aux/q.tsv /bin/bash "$root/scripts/selfhost/preflight.sh" 012 "$1" "$2" 2>&1 && echo "rc=0" || echo "rc=$?"; }
REV=docs/specs/012-self-hosted-bootstrap/reviews/T99.md
br good src/a.c 'int delta;' docs/bayan-questions.md '200. **T99.** `src/a.c:2` `beta` and `a.c:1-2` (bare name) hold it; `src/a.c:3`, then `gamma` elsewhere; `src/a.c:1` `gamma` is 2 lines on.' \
  $REV '| 1 | LOW | `src/a.c:4` `delta` | open |'
br stale src/a.c 'int delta;' docs/bayan-questions.md '201. `src/a.c:9` is past the end; `src/a.c:1` `delta` is 3 lines on; `src/a.c:1-2` `gamma` ends short; `nope.c:1` does not exist; `src/a.c:3` `gamma` holds.'
br outside .github/workflows/r.yml 'on: push' .github/workflows/s.yml 'on: push' src/b.c 'int b;' scripts/r.sh 'true' scripts/s.sh 'true' bootstrap/r.c "int r;" src/d.c 'int d;' src/e.c 'int e;' tests/Bayan.Tests/BarTests.cs 'class BarTests {}' work/todo.md '- x'
br driver selfhost/driver/main.byn 'x'
br qdup docs/bayan-questions.md '101. again'
br qans docs/bayan-questions.md '203. reuses an answered number'
br qout docs/bayan-questions.md '205. out of range'
br qbase docs/bayan-questions.md '202. mine'
br qline docs/bayan-questions.md '300. in the task line range'
br norange docs/bayan-questions.md '400. no range'
printf '202. another task\n' >> docs/bayan-questions.md; git commit -qam "test: base takes 202"
good=$(pf T99 good); gsha=$(git rev-parse good); targs=$(cat "$aux/test-args")
mkdir -p tmp/wp1; W=tmp/wp1/$gsha.out
F='FullyQualifiedName~FooT8Tests|FullyQualifiedName~CInventoryTests|FullyQualifiedName~SelfhostDriverT8Tests|FullyQualifiedName~SelfhostDriverRuntimeTests'
printf 'branch: good\nsha: %s\nfilter: %s\nPassed!  - Failed:     0, Passed:     4, Skipped:     0, Total:     4\nexit 0\n' "$gsha" "$F" > $W; wok=$(pf T99 good)
printf 'filter: %s\nFailed!  - Failed:     1, Passed:     3, Skipped:     0, Total:     4\nexit 1\n' "$F" > $W; wexit=$(pf T99 good)
printf 'filter: %s\nexit 0\n' "$F" > $W; wnone=$(pf T99 good)
printf 'filter: FullyQualifiedName~FooT8Tests\nPassed!  - Failed:     0, Passed:     1, Skipped:     0, Total:     1\nexit 0\n' > $W; wfilt=$(pf T99 good)
printf '  Passed Bayan.Tests.%s.A [1 ms]\n' FooT8Tests CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests SelfhostDriverT2Tests SelfhostDefaultT4Tests SelfhostDriverT5Tests > "$aux/test-out"; mapped=$(pf T99 driver); mapargs=$(cat "$aux/test-args"); passing
stale=$(pf T99 stale); outside=$(pf T99 outside)
qdup=$(pf T99 qdup); qans=$(pf T99 qans); qout=$(pf T99 qout); qbase=$(pf T99 qbase); qline=$(pf T98 qline); norange=$(pf T97 norange); notask=$(pf T96 good)
printf '  Passed Bayan.Tests.%s.A [1 ms]\n' CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests > "$aux/test-out"; zero=$(pf T99 good)
passing; printf '  Failed Bayan.Tests.CInventoryTests.B [1 ms]\n' >> "$aux/test-out"; echo 1 > "$aux/test-rc"; failed=$(pf T99 good)
passing; touch "$aux/build-fail"; build=$(pf T99 good); rm "$aux/build-fail"
touch "$aux/tool-fail"; tool=$(pf T99 good); rm "$aux/tool-fail"
git switch -q good; printf 'int c;\n' > src/c.c; writer=$(pf T99 good); rm src/c.c; git switch -q base
# the exits before any check: no specs.tsv row, an unknown branch or base, a worktree that cannot be made, no merge base
nospec=$(PATH="$aux/bin:$PATH" /bin/bash "$root/scripts/selfhost/preflight.sh" 999 T99 good 2>&1 && echo "rc=0" || echo "rc=$?")
nobr=$(pf T99 nope); nobase=$(BAYAN_BASE=nobase PATH="$aux/bin:$PATH" BAYAN_QRANGES=$aux/q.tsv /bin/bash "$root/scripts/selfhost/preflight.sh" 012 T99 good 2>&1 && echo "rc=0" || echo "rc=$?")
mkdir -p tmp/preflight; chmod a-w tmp; nowt=$(pf T99 good); chmod u+w tmp
git branch lone "$(git commit-tree "$(git mktree < /dev/null)" -m "test: lone")"; nomb=$(pf T99 lone)
# no pinned bayan
nobayan=$(PINNED_BAYAN=$aux/none pf T99 good)
cd "$root"; rm -rf "$r" "$aux"
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
has() { grep -qxF -- "$2" <<< "$1"; }
for l in "ok cites (5 checked)" "ok files (3 changed)" "ok questions (1 added, range Q200–Q204)" "ok plan-strings" "rc=1"; do has "$good" "$l" || fail "the clean branch lacks '$l'" "$good"; done
has "$good" "ok tests (4 passed: FooT8Tests CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests)" || fail "the tests line is not the file's declared class and the cross-cutting set" "$good"
has "$mapped" "ok tests (7 passed: FooT8Tests CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests SelfhostDriverT2Tests SelfhostDefaultT4Tests SelfhostDriverT5Tests)" || fail "a change to selfhost/driver/main.byn did not add the test-map classes" "$mapped"
grep -q -- "--filter $F|FullyQualifiedName~SelfhostDriverT2Tests|FullyQualifiedName~SelfhostDefaultT4Tests|FullyQualifiedName~SelfhostDriverT5Tests " <<< "$mapargs" || fail "the filter for a driver change is '$mapargs'" "$mapped"
grep -q -- "--filter $F " <<< "$targs" || fail "dotnet test ran '$targs'" "$good"
grep -q "^FAIL wp1: no tmp/wp1/$gsha.out for good's HEAD; run: bash scripts/selfhost/wp1-test.sh good '$F'$" <<< "$good" || fail "a missing wp1 run is not reported with its command" "$good"
[ "$(grep -c '^FAIL' <<< "$good")" = 1 ] || fail "the clean branch has a FAIL besides wp1" "$good"
has "$wok" "ok wp1 (Passed:     4)" && has "$wok" "rc=0" && ! grep -q '^FAIL' <<< "$wok" || fail "a clean branch with its wp1 run does not pass" "$wok"
has "$wexit" "FAIL wp1: tmp/wp1/$gsha.out ends in 'exit 1', not 'exit 0'" || fail "a failed wp1 run passed" "$wexit"
has "$wnone" "FAIL wp1: tmp/wp1/$gsha.out ran no tests" || fail "a wp1 run of no tests passed" "$wnone"
grep -q "^FAIL wp1: tmp/wp1/$gsha.out ran 'FullyQualifiedName~FooT8Tests', without CInventoryTests SelfhostDriverT8Tests SelfhostDriverRuntimeTests; run: " <<< "$wfilt" || fail "a wp1 run without the cross-cutting classes passed" "$wfilt"
has "$stale" 'FAIL cites: docs/bayan-questions.md Q201 `src/a.c:9`: src/a.c has 4 lines' || fail "a citation past the end passed" "$stale"
has "$stale" 'FAIL cites: docs/bayan-questions.md Q201 `src/a.c:1`: `delta` is not on src/a.c:1 or the 2 lines after it' || fail "a quoted symbol 3 lines after its line passed" "$stale"
has "$stale" 'FAIL cites: docs/bayan-questions.md Q201 `nope.c:1`: no such file' || fail "a citation of a missing file passed" "$stale"
has "$stale" 'FAIL cites: docs/bayan-questions.md Q201 `src/a.c:1-2`: `gamma` is not on src/a.c:1-2' || fail "a range ending short of its quoted symbol passed" "$stale"
[ "$(grep -c '^FAIL cites' <<< "$stale")" = 4 ] || fail "a citation that holds was reported" "$stale"
has "$outside" 'FAIL files: 4 changed outside T99'"'"'s files list; append to its files: in docs/specs/012-self-hosted-bootstrap/012-tasks.md: `.github/workflows/s.yml`, `scripts/s.sh`, `src/b.c`, `tests/Bayan.Tests/BarTests.cs`' || fail "files outside the list are not reported with the addition" "$outside"
has "$qdup" "FAIL questions: Q101 is in the questions docs 2 times" || fail "a duplicate Question number passed" "$qdup"
has "$qans" "FAIL questions: Q203 is in the questions docs 2 times" || fail "a number taken by an answered Question passed" "$qans"
has "$qout" "FAIL questions: Q205 is outside T99's range Q200–Q204" || fail "a Question outside the range passed" "$qout"
has "$qbase" "FAIL questions: Q202 is already on base (another task took it)" || fail "a Question the base took meanwhile passed" "$qbase"
has "$qline" "ok questions (1 added, range Q300–Q304)" || fail "the task line's range is not used" "$qline"
grep -q "^FAIL questions: Q400 added, but T97 has no Question range" <<< "$norange" || fail "a task with no range passed" "$norange"
has "$notask" "FAIL task: no T96 in docs/specs/012-self-hosted-bootstrap/012-tasks.md on base" || fail "an unknown task did not fail" "$notask"
has "$zero" "FAIL tests: FullyQualifiedName~FooT8Tests matched no tests" || fail "a class matching no test passed" "$zero"
has "$failed" "FAIL tests: Bayan.Tests.CInventoryTests.B failed" && has "$failed" "FAIL tests: dotnet test exited 1 (tmp/preflight/t99/test.txt)" || fail "a failed test passed" "$failed"
grep -q '^FAIL tests: build failed — a.cs(1,1): error CS1002' <<< "$build" || fail "a build error passed" "$build"
grep -q '^FAIL tests: plan-strings-check --base base failed — BYN1001 message missing$' <<< "$tool" || fail "a plan-strings failure passed" "$tool"
has "$writer" 'FAIL files: 1 changed outside T99'"'"'s files list; append to its files: in docs/specs/012-self-hosted-bootstrap/012-tasks.md: `src/c.c`' || fail "on the branch's checkout an untracked file is not checked" "$writer"
grep -q '^FAIL wp1: the working tree has uncommitted changes' <<< "$writer" || fail "uncommitted changes did not make wp1 fail" "$writer"
has "$nospec" "FAIL spec: no row for spec 999 in scripts/selfhost/specs.tsv" && has "$nospec" "rc=1" || fail "a spec without a specs.tsv row did not fail" "$nospec"
has "$nobr" "FAIL branch: no branch nope" && has "$nobr" "rc=1" || fail "an unknown branch did not fail" "$nobr"
has "$nobase" "FAIL branch: no base branch nobase" && has "$nobase" "rc=1" || fail "an unknown base did not fail" "$nobase"
has "$nowt" "FAIL branch: cannot check out good in $r/tmp/preflight-t99" && has "$nowt" "rc=1" || fail "a worktree that cannot be made did not fail" "$nowt"
has "$nomb" "FAIL branch: lone has no merge base with base" && has "$nomb" "rc=1" || fail "a branch with no merge base did not fail" "$nomb"
has "$nobayan" "FAIL tests: plan-strings-check --base base failed — pinned-bayan: PINNED_BAYAN=$aux/none is not an executable" && has "$nobayan" "rc=1" || fail "a missing pinned bayan did not fail" "$nobayan"
echo PASS
