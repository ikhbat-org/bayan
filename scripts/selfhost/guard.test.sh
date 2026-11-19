#!/bin/bash
# guard.sh on a tiny fixture with stub `scripts/test.sh`, `scripts/bootstrap-build.sh` and `bayan` (the stage-1 binary, BAYAN_EXE), plus a stub `dotnet`
# that fails the test when called (spec 019 T48c): --mutate records once under BAYAN_SNAPSHOT as `bayan test tests/cases --only <selector>`
# on BAYAN_EXE (the --mutate files, the --filter selector words, a part word dropped), then runs
# `bayan mutate --binary` with replay.py per build of the manifest and prints its summary. A survivor fails with its site,
# all killed passes (marked sites included), each build of a two-build manifest replays with its own --binary, a mutant-0 mismatch fails, a bayan error
# with only an earlier run's report beside the binary fails, a score below tests/quality-baseline.json fails, a
# null baseline passes, a failed recording, a missing CLI or manifest fails with a message, a malformed manifest or baseline
# fails naming it, and no --mutate records nothing and leaves no report.
# Coverage (T26): with a.byn changed the tests run under BAYAN_COVERAGE with it. a.byn's base function f is untouched and the
# branch adds g: g fully covered passes with f uncovered (f an info line); each missed or unknown line and branch of g fails by
# file:line, none of f's; a deleted line in f makes f gated, and a file new since --base is gated throughout; no coverage
# baseline check runs and no quality-coverage.json is left (F2); no report fails, a malformed report fails naming it, and a
# red test run is not checked for coverage.
# Tests (T48a): --filter words run one by one, a part word as `scripts/test.sh --only <part>` and any other as
# `bayan test tests/cases --only <word>`; a failing part, a failing selector, a selector matching no case, a skipped part and a
# failing bootstrap-build.sh each fail naming the word; no --task fails the content checks; the guard never calls dotnet.
# A changed file the coverage report has no entry for (b.byn's run reports only b.byn) fails naming it (Q820).
# lib/std (spec 016 T3): a changed lib/std/<m>/x.byn is in BAYAN_COVERAGE_FILES and adds the `bayan` part to the filter;
# misformatted it fails the format check naming it, formatted it passes; covered it passes, a missed line of it fails by file:line.
# A branch that does not touch lib/std gets no format item, even with a misformatted lib/std file or a failing pinned bayan.
# A changed file whose name has a space is reported by its full name.
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
r="$root/tmp/guard-test"; aux="$root/tmp/guard-test-aux"  # stubs and logs live outside the fixture repo
rm -rf "$r" "$aux" && mkdir -p "$r/src/semantics" "$r/docs" "$r/tests" "$r/scripts" "$aux/bin" "$aux/bin2" && cd "$r"
git init -q -b fixture && git config user.email t@t && git config user.name t
printf 'fn f(a: int) -> int {\n    if a == 1 { return 1 }\n    return a + 1\n}\n' > src/semantics/a.byn
printf '# Handoff\n' > docs/bayan-progress-log.md
printf 'bin/\n' > .gitignore
printf '{ "version": 1, "files": { "src/semantics/a.byn": { "mutation": 1.0, "coverage": null } } }\n' > tests/quality-baseline.json
# stub scripts/test.sh and scripts/bootstrap-build.sh (committed, so the scope check sees them as base files); both read $AUX
cat > scripts/test.sh <<'STUB'
#!/bin/bash
echo "test.sh $*" >> $AUX/runs.txt; bash $AUX/cover.sh
[ -f $AUX/skip ] && { echo "test: bayan    skip    0s  no reason"; exit 0; }
[ -f $AUX/testfail ] && { echo "test: bayan    FAIL    1s  oracle differs"; exit 1; }
echo "test: bayan    pass    1s  ok"
STUB
cat > scripts/bootstrap-build.sh <<'STUB'
#!/bin/bash
[ -f $AUX/buildfail ] && { echo "bootstrap-build.sh: stage 1 failed" >&2; exit 1; }
echo "$PINNED_BAYAN"
STUB
git add -A && git commit -qm "test: base" && git branch -q base
printf '# Handoff\n- **T99** landed.\n' > docs/bayan-progress-log.md
# stub dotnet: any call is logged in $AUX/dotnet-calls.txt and fails (T48c: the guard calls no dotnet)
cat > $aux/dotnet <<'STUB'
#!/bin/bash
echo "$*" >> $AUX/dotnet-calls.txt; exit 1
STUB
# the coverage report a test run writes: both test stubs run this
cat > $aux/cover.sh <<'STUB'
if [ -n "${BAYAN_COVERAGE:-}" ]; then
  echo "$BAYAN_COVERAGE_FILES" > $AUX/cover.txt
  [ -f $AUX/nocov ] || { mkdir -p "$BAYAN_COVERAGE"; cp $AUX/cov.json "$BAYAN_COVERAGE/bayan-quality.json"; cp $AUX/fns.json "$BAYAN_COVERAGE/functions.json"; }
fi
STUB
# stub bayan: logs its arguments; with $AUX/mismatch it fails as on mutant 0, with $AUX/usage as on bad arguments, else prints $AUX/out.txt and writes $AUX/report.json;
# `test` under BAYAN_SNAPSHOT (mutation-step.sh's recording) logs the files and selectors and writes a one-build manifest (two builds with
# $AUX/two, none with $AUX/nomanifest, a malformed one with $AUX/badmanifest; a failed case's result lines with $AUX/recordfail)
mkdir -p csharp/Bayan.Cli/bin/Debug/net10.0
cat > csharp/Bayan.Cli/bin/Debug/net10.0/bayan <<'STUB'
#!/bin/bash
# `run` is scripts/bayan-tool.sh running manifest-builds: one `binary<TAB>sites` line per build, a malformed manifest fails;
# the quality-baseline, report-paths, coverage-missing, coverage-gate and guard-checks tools run on the real pinned bayan ($REAL_BAYAN)
[ "$1" = run ] && [ -f $AUX/missfail ] && case $2 in */coverage-missing.byn) echo "bayan: pinned build failed" >&2; exit 1;; esac
[ "$1" = run ] && case $2 in */quality-baseline.byn|*/report-paths.byn|*/coverage-missing.byn|*/coverage-gate.byn|*/guard-checks.byn) exec "$REAL_BAYAN" "$@";; esac
[ "$1" = run ] && { m=${@: -1}; grep -q ']}$' "$m" || { echo "manifest-builds: $m: malformed" >&2; exit 1; }
  tr '{' '\n' < "$m" | sed -n 's/^"binary": "\([^"]*\)", "sites": "\([^"]*\)".*/\1 \2/p' | tr ' ' '\t'; exit 0; }
[ "$1" = test ] && [ -n "${BAYAN_SNAPSHOT:-}" ] && { echo "$BAYAN_SNAPSHOT_FILES ${*:3}" > $AUX/record.txt
  [ -f $AUX/recordfail ] && { printf 'failed run/T99\n    recording broke\n'; exit 1; }
  b=$(printf '{"binary": "%s", "sites": "%s"}' $AUX/bin/prog $AUX/bin/prog.sites.json)
  [ -f $AUX/two ] && b="$b, $(printf '{"binary": "%s", "sites": "%s"}' $AUX/bin2/prog2 $AUX/bin2/prog2.sites.json)"
  [ -f $AUX/nomanifest ] || { mkdir -p "$BAYAN_SNAPSHOT"; echo "{\"version\": 1, \"builds\": [$b]}" > "$BAYAN_SNAPSHOT/manifest.json"; }
  [ -f $AUX/badmanifest ] && echo '{"version": 1, "builds": [' > "$BAYAN_SNAPSHOT/manifest.json"
  exit 0; }
[ "$1" = test ] && { echo "bayan $*" >> $AUX/runs.txt; bash $AUX/cover.sh
  [ -f $AUX/nomatch ] && { echo "bayan: no case name contains \`${@: -1}\`" >&2; exit 2; }
  [ -f $AUX/selfail ] && { echo "run/x: failed: expected differs"; exit 1; }
  exit 0; }
[ "$1" = format ] && { if grep -q BAD "${@: -1}"/*/*.byn; then echo "${@: -1}/m/x.byn"; exit 1; fi; exit 0; }
[ "$1" = parse ] && { grep -q '^fn ' "${@: -1}" && echo "Function f"; echo "Program"; exit 0; }
echo "$@" > $AUX/mutate-args.txt; echo "$@" >> $AUX/mutate-args-all.txt
[ -f $AUX/mismatch ] && { echo "bayan: (any text: the guard keys on the exit code)" >&2; exit 1; }
[ -f $AUX/usage ] && { echo "bayan: usage" >&2; exit 2; }
cat $AUX/out.txt; cp $AUX/report.json "$(dirname "$3")/bayan-quality.json"
grep -q ': survived$' $AUX/out.txt && exit 3 || exit 0
STUB
chmod +x $aux/dotnet csharp/Bayan.Cli/bin/Debug/net10.0/bayan; export REAL_BAYAN=$(cd "$root" && env -u PINNED_BAYAN bash scripts/pinned-bayan.sh)
export AUX=$aux PINNED_BAYAN=$PWD/csharp/Bayan.Cli/bin/Debug/net10.0/bayan; export BAYAN_EXE=$PINNED_BAYAN
a=$r/src/semantics/a.byn
# result <killed> <survived> <marked>: stub per-site lines, summary and report
result() {
  { for ((i = 0; i < $1; i++)); do echo "$a:2:10 relational \`==\` -> \`!=\`: killed"; done
    for ((i = 0; i < $2; i++)); do echo "$a:3:14 arithmetic \`+\` -> \`-\`: survived"; done
    for ((i = 0; i < $3; i++)); do echo "$a:3:5 statement \`return a + 1\` -> \`\`: marked"; done
    echo "mutation: $1 killed, $2 survived, 0 timeout, $3 marked, 0 not reached, 0 not emitted"; echo "timing: total 1 s"; } > $aux/out.txt
  local ms="" st i
  for st in killed:$1 survived:$2 marked:$3; do
    for ((i = 0; i < ${st#*:}; i++)); do ms="$ms${ms:+, }{\"site\": {\"file\": \"$a\"}, \"status\": \"${st%%:*}\"}"; done; done
  printf '{"version": 1, "kind": "mutation", "files": [{"path": "%s", "mutants": [%s]}]}\n' "$a" "$ms" > $aux/report.json; }
g() { PATH="$aux:$PATH" bash "$root/scripts/selfhost/guard.sh" --base base --allow "src/semantics/a.byn,tmp/*${ALLOWX:-}" \
  --filter "${FILT:-run/ bayan}" --task T99 "$@" 2>&1 || true; }
result 2 0 1; pass=$(g --mutate src/semantics/a.byn); rec=$(cat $aux/record.txt); args=$(cat $aux/mutate-args.txt)
[ -f tmp/guard-run/quality-1-prog.json ] && report=1 || report=0
result 1 1 0; survived=$(g --mutate src/semantics/a.byn)
result 2 0 1; rm -f $aux/mutate-args-all.txt; touch $aux/two; two=$(g --mutate src/semantics/a.byn); rm $aux/two; twoargs=$(cat $aux/mutate-args-all.txt)
result 1 1 0; touch $aux/mismatch; mismatch=$(g --mutate src/semantics/a.byn); rm $aux/mismatch
touch $aux/usage; usage=$(g --mutate src/semantics/a.byn); rm $aux/usage
printf '{ "version": 1, "files": { "src/semantics/a.byn": { "mutation": null, "coverage": null } } }\n' > tests/quality-baseline.json
nullbase=$(ALLOWX=,tests/quality-baseline.json g --mutate src/semantics/a.byn); git show HEAD:tests/quality-baseline.json > tests/quality-baseline.json
touch $aux/nomanifest; nomanifest=$(g --mutate src/semantics/a.byn); rm $aux/nomanifest
touch $aux/badmanifest; badmanifest=$(g --mutate src/semantics/a.byn); rm $aux/badmanifest
result 2 0 1; printf '{ "version": 1, "files": ' > tests/quality-baseline.json
badbase=$(ALLOWX=,tests/quality-baseline.json g --mutate src/semantics/a.byn); git show HEAD:tests/quality-baseline.json > tests/quality-baseline.json
touch $aux/recordfail; recordfail=$(g --mutate src/semantics/a.byn); rm $aux/recordfail
rm $aux/record.txt; plain=$(g); [ -f $aux/record.txt ] && plainrec=1 || plainrec=0; ls tmp/guard-run/quality-*.json > /dev/null 2>&1 && plainrep=1 || plainrep=0
printf x > "stray file.txt"; space=$(g); rm "stray file.txt"
mv csharp/Bayan.Cli/bin/Debug/net10.0/bayan $aux/bayan; nocli=$(g --mutate src/semantics/a.byn); mv $aux/bayan csharp/Bayan.Cli/bin/Debug/net10.0/bayan
# T48a: the words run one by one; each failure names its word
rm -f $aux/runs.txt; runs_plain=$(g); runs=$(cat $aux/runs.txt)
touch $aux/testfail; partfail=$(g); rm $aux/testfail
touch $aux/selfail; selfail=$(g); rm $aux/selfail
touch $aux/nomatch; nomatch=$(g); rm $aux/nomatch
touch $aux/skip; skip=$(g); rm $aux/skip
touch $aux/buildfail; buildfail=$(BAYAN_EXE= g); rm $aux/buildfail
notask=$(PATH="$aux:$PATH" bash "$root/scripts/selfhost/guard.sh" --base base --allow "src/semantics/a.byn,tmp/*" --filter bayan 2>&1 || true)
[ -f $aux/dotnet-calls.txt ] && dotnetcalls=$(cat $aux/dotnet-calls.txt) || dotnetcalls=""
# cov <covered> <total> <missed lines> <unknown lines> <line,column,outcome,status>...: the coverage report of a.byn, one branch per argument
cov() { local lines="\"covered\": $1, \"total\": $2, \"missed\": $3, \"unknown\": $4" b l c o st e hit=0 n=0 missed="" unknown=""; shift 4
  for b in "$@"; do IFS=, read -r l c o st <<< "$b"; e="{\"line\": $l, \"column\": $c, \"outcome\": $o}"; n=$((n + 1))
    case $st in hit) hit=$((hit + 1)) ;; missed) missed="$missed${missed:+, }$e" ;; unknown) unknown="$unknown${unknown:+, }$e" ;; esac; done
  printf '{"version": 1, "kind": "coverage", "files": [{"path": "%s", "lines": {%s}, "branches": {"covered": %s, "total": %s, "missed": [%s], "unknown": [%s]}, "errorPaths": []}]}\n' \
    "$a" "$lines" $hit $n "$missed" "$unknown" > $aux/cov.json; }
# fns <f's [covered, total] lines> <f's branches> <g's lines> <g's branches>: functions.json for a.byn (f 1-4, a blank line, g 6-9)
fns() { printf '{"version": 1, "files": {"%s": [{"span": [1, 4], "lines": %s, "branches": %s}, {"span": [6, 9], "lines": %s, "branches": %s}]}}\n' "$a" "$@" > $aux/fns.json; }
printf '\nfn g(a: int) -> int {\n    if a > 2 { return 2 }\n    return a\n}\n' >> src/semantics/a.byn
# f uncovered (line 3, branch 2:10 never true), g covered; the blank line opens the hunk adding g
cov 3 4 '[3]' '[]' 2,10,true,missed 2,10,false,hit 7,10,true,hit 7,10,false,hit; fns '[1, 2]' '[1, 2]' '[2, 2]' '[2, 2]'
covpass=$(g); covfiles=$(cat $aux/cover.txt); [ -f tmp/guard-run/quality-coverage.json ] && covrep=1 || covrep=0
touch $aux/missfail; covmissfail=$(g); rm $aux/missfail
# f and g both short: only g's are items
cov 1 4 '[3, 8]' '[7]' 2,10,true,missed 7,10,true,missed 7,10,false,hit 8,5,false,unknown; fns '[1, 2]' '[0, 1]' '[0, 2]' '[1, 3]'
covmiss=$(g)
touch $aux/testfail; covred=$(g); rm $aux/testfail
# a coverage baseline above the run's is not checked
printf '{ "version": 1, "files": { "src/semantics/a.byn": { "mutation": null, "coverage": 1.0, "branches": 1.0 } } }\n' > tests/quality-baseline.json
cov 3 4 '[3]' '[]' 2,10,true,missed 2,10,false,hit 7,10,true,hit 7,10,false,hit; fns '[1, 2]' '[1, 2]' '[2, 2]' '[2, 2]'
covbase=$(ALLOWX=,tests/quality-baseline.json g); git show HEAD:tests/quality-baseline.json > tests/quality-baseline.json
touch $aux/nocov; covnone=$(g); rm $aux/nocov
printf '{"version": 1, "files": [' > $aux/cov.json; covbad=$(g)
# deleting f's line 2 makes f (then 1-3) gated: a deletion touches the lines on either side of it
sed -i.bak 2d src/semantics/a.byn; rm src/semantics/a.byn.bak
cov 2 3 '[2]' '[]' 6,10,true,hit 6,10,false,hit
printf '{"version": 1, "files": {"%s": [{"span": [1, 3], "lines": [0, 1], "branches": [0, 0]}, {"span": [5, 8], "lines": [2, 2], "branches": [2, 2]}]}}\n' "$a" > $aux/fns.json
covtouch=$(g)
# a file new since base is touched throughout
printf 'fn h() -> int {\n    return 1\n}\n' > src/semantics/b.byn
a=$r/src/semantics/b.byn cov 0 1 '[2]' '[]'
printf '{"version": 1, "files": {"%s": [{"span": [1, 3], "lines": [0, 1], "branches": [0, 0]}]}}\n' "$r/src/semantics/b.byn" > $aux/fns.json
covnew=$(ALLOWX=,src/semantics/b.byn g)
# a changed file with only constants, absent from the report, has nothing to cover (info line, no FAIL item)
printf 'const k: string = "x"\n' > src/semantics/c.byn
covconst=$(ALLOWX=,src/semantics/b.byn,src/semantics/c.byn g)
# lib/std: a misformatted file fails the format check naming it, the formatted one passes, and a changed one is covered
mkdir -p lib/std/m; printf 'fn k() -> int {\n  return 1 /*BAD*/\n}\n' > lib/std/m/x.byn
stdbad=$(ALLOWX=,lib/std/m/x.byn g); stdcover=$(cat $aux/cover.txt)
printf 'fn k() -> int {\n    return 1\n}\n' > lib/std/m/x.byn
stdgood=$(ALLOWX=,lib/std/m/x.byn g)
rm -f $aux/runs.txt; FILT=run/ ALLOWX=,lib/std/m/x.byn g > /dev/null; stdfilter=$(cat $aux/runs.txt)
rm -f $aux/runs.txt; FILT='run/ bayan' ALLOWX=,lib/std/m/x.byn g > /dev/null; stdkeep=$(cat $aux/runs.txt)
# lib/std coverage alone: k covered passes, k's line 2 missed fails by file:line
git show base:src/semantics/a.byn > src/semantics/a.byn; rm src/semantics/b.byn src/semantics/c.byn
x=$r/lib/std/m/x.byn; a=$x cov 1 1 '[]' '[]'
printf '{"version": 1, "files": {"%s": [{"span": [1, 3], "lines": [1, 1], "branches": [0, 0]}]}}\n' "$x" > $aux/fns.json
stdcovpass=$(ALLOWX=,lib/std/m/x.byn g)
a=$x cov 0 1 '[2]' '[]'
printf '{"version": 1, "files": {"%s": [{"span": [1, 3], "lines": [0, 1], "branches": [0, 0]}]}}\n' "$x" > $aux/fns.json
stdcovmiss=$(ALLOWX=,lib/std/m/x.byn g)
# a branch that does not touch lib/std runs no format check, whatever lib/std holds and whether or not the pinned bayan works
printf 'fn k() -> int {\n  return 1 /*BAD*/\n}\n' > lib/std/m/x.byn; git add lib/std/m/x.byn; git commit -qm "test: std in base"; git branch -qf base
stduntouched=$(g); stduntouchedfail=$(PINNED_BAYAN=$aux/missing g)
cd "$root"; rm -rf "$r" "$aux"
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
echo "$pass" | grep -q '^GUARD PASS$' || fail "all killed (one marked) did not pass" "$pass"
echo "$pass" | grep -q '^mutation: 2 killed, 0 survived, 0 timeout, 1 marked' || fail "the bayan mutate summary was not printed" "$pass"
[ "$rec" = "src/semantics/a.byn --only run/" ] || fail "recorded with the wrong files or filter" "$rec"
[ "$args" = "mutate --binary $aux/bin/prog --sites $aux/bin/prog.sites.json -- python3 -I $root/scripts/selfhost/replay.py --binary $aux/bin/prog $r/tmp/guard-run/snap" ] || fail "bayan mutate ran with the wrong arguments" "$args"
S="$r/tmp/guard-run/snap"; R="python3 -I $root/scripts/selfhost/replay.py"
[ "$twoargs" = "mutate --binary $aux/bin/prog --sites $aux/bin/prog.sites.json -- $R --binary $aux/bin/prog $S
mutate --binary $aux/bin2/prog2 --sites $aux/bin2/prog2.sites.json -- $R --binary $aux/bin2/prog2 $S" ] && echo "$two" | grep -q '^GUARD PASS$' || fail "the two builds did not each replay with their own --binary" "$twoargs
$two"
[ $report = 1 ] || fail "the report was not copied to tmp/guard-run/quality-1-prog.json" "$pass"
echo "$survived" | grep -q '^- mutation survived: src/semantics/a.byn:3:14 arithmetic `+` -> `-` — ' || fail "a survivor was not a FAIL item with its site" "$survived"
echo "$survived" | grep -q '^- baseline: mutation score of src/semantics/a.byn fell from 1.0 to 0.5 (tests/quality-baseline.json)$' || fail "a baseline drop was not a FAIL item" "$survived"
echo "$mismatch" | grep -q '^- mutation: the recording does not replay on the unmutated build' || fail "a mutant-0 mismatch did not fail" "$mismatch"
echo "$usage" | grep -q "^- mutation: bayan mutate exited 2 on $aux/bin/prog without a report" || fail "an earlier run's report was used after a bayan error" "$usage"
echo "$nullbase" | grep -q 'fell from' && fail "a null baseline failed" "$nullbase"
echo "$nullbase" | grep -q '^- mutation survived' || fail "the null-baseline run did not run mutation" "$nullbase"
echo "$nomanifest" | grep -q '^- mutation: the recording wrote no tmp/guard-run/snap/manifest.json' || fail "a missing manifest did not fail with a message" "$nomanifest"
echo "$badmanifest" | grep -q '^GUARD FAIL' && echo "$badmanifest" | grep -q '^- mutation: tmp/guard-run/snap/manifest.json is unreadable — ' || fail "a malformed manifest did not fail naming it" "$badmanifest"
echo "$badbase" | grep -q '^GUARD FAIL' && echo "$badbase" | grep -q '^- baseline: quality-baseline check failed on tests/quality-baseline.json and tmp/guard-run/quality-\*.json — ' || fail "a malformed baseline did not fail naming it" "$badbase"
echo "$recordfail" | grep -q '^- mutation: recording under BAYAN_SNAPSHOT: 1 test(s) failed (tmp/guard-run/record.txt): run/T99 — first: recording broke$' || fail "a failed recording did not fail with its message" "$recordfail"
# guard-checks runs on the pinned bayan too (spec 015 T15), so the missing CLI fails the content checks before mutation
echo "$nocli" | grep -q '^- checks: guard-checks failed: pinned-bayan: PINNED_BAYAN=.*/csharp/Bayan.Cli/bin/Debug/net10.0/bayan is not an executable' || fail "a missing CLI did not fail with a message" "$nocli"
echo "$plain" | grep -q '^GUARD PASS$' && [ $plainrec = 0 ] && [ $plainrep = 0 ] || fail "a guard without --mutate recorded or left a report" "$plain"
L='(listing: tmp/guard-run/coverage/src/semantics/a.byn.cov.txt)'
echo "$covpass" | grep -q '^GUARD PASS$' || fail "an uncovered untouched function failed the guard" "$covpass"
echo "$covpass" | grep -qF "coverage: src/semantics/a.byn: touched functions: lines 2/2, branches 2/2 $L" \
  && echo "$covpass" | grep -qF "coverage: src/semantics/a.byn: other functions, not gated (no line of theirs changed): lines 1/2, branches 1/2 $L" \
  || fail "the touched and other functions' summary lines are missing" "$covpass"
[ "$covfiles" = src/semantics/a.byn ] || fail "the tests ran under BAYAN_COVERAGE_FILES='$covfiles', not the changed a.byn" "$covpass"
[ $covrep = 0 ] || fail "the coverage report was copied to tmp/guard-run/quality-coverage.json (land.sh would record it)" "$covpass"
echo "$covmiss" | grep -q '^- coverage: missed line src/semantics/a.byn:8; no test under --filter runs it' || fail "a missed line of a touched function was not a FAIL item with file:line" "$covmiss"
echo "$covmiss" | grep -q '^- coverage: unknown line src/semantics/a.byn:7; a counter file was unreadable' || fail "an unknown line was not a FAIL item" "$covmiss"
echo "$covmiss" | grep -q '^- coverage: missed branch src/semantics/a.byn:7:10 never true; ' || fail "a missed branch was not a FAIL item with file:line" "$covmiss"
echo "$covmiss" | grep -q '^- coverage: unknown branch src/semantics/a.byn:8:5 never false; ' || fail "an unknown branch was not a FAIL item" "$covmiss"
echo "$covmiss" | grep -qE '^- coverage: .* src/semantics/a.byn:(3|2:10)' && fail "an untouched function's miss was a FAIL item" "$covmiss"
echo "$covred" | grep -q '^- tests: FAIL' && ! echo "$covred" | grep -q '^- coverage:' || fail "a red test run was checked for coverage" "$covred"
echo "$covbase" | grep -q '^GUARD PASS$' || fail "the guard checked coverage against the baseline" "$covbase"
echo "$space" | grep -qxF -- "- scope: stray file.txt is outside --allow (src/semantics/a.byn,tmp/*); revert it or record the need as a Question" || fail "a changed file with a space in its name was not reported by its full name" "$space"
echo "$covbad" | grep -q '^GUARD FAIL' && echo "$covbad" | grep -q "^- coverage: coverage-gate.py: $r/tmp/guard-run/coverage/bayan-quality.json is unreadable: " || fail "a malformed coverage report did not fail naming it" "$covbad"
echo "$covtouch" | grep -q '^- coverage: missed line src/semantics/a.byn:2; ' || fail "a deleted line in f did not make f gated" "$covtouch"
echo "$covnew" | grep -q '^- coverage: missed line src/semantics/b.byn:2; ' || fail "a function of a file new since --base was not gated" "$covnew"
echo "$covnew" | grep -qxF -- "- coverage: src/semantics/a.byn is in no build under --filter 'run/ bayan' (no entry in tmp/guard-run/coverage/bayan-quality.json), so its touched functions are unchecked" \
  && ! echo "$covnew" | grep -q '^- coverage: src/semantics/b.byn is in no build' || fail "a changed file absent from the coverage report was not a FAIL item naming it" "$covnew"
echo "$covconst" | grep -qxF -- "coverage: src/semantics/c.byn declares no function; nothing to cover" && ! echo "$covconst" | grep -q '^- coverage: src/semantics/c.byn' || fail "a const-only file absent from the report was not an info line" "$covconst"
[ "$runs" = "bayan test tests/cases --only run/
test.sh --only bayan" ] && echo "$runs_plain" | grep -q '^GUARD PASS$' || fail "the filter words did not run one by one as a selector then a part" "$runs
$runs_plain"
echo "$partfail" | grep -q "^- tests: FAIL 'bayan' (exit 1) — first failure: test: bayan    FAIL" && ! echo "$partfail" | grep -q "'run/'" || fail "a failing part did not fail naming it" "$partfail"
echo "$selfail" | grep -q "^- tests: FAIL 'run/' (exit 1) — first failure: run/x: failed" && ! echo "$selfail" | grep -q "'bayan'" || fail "a failing selector did not fail naming it" "$selfail"
echo "$nomatch" | grep -qxF -- "- tests: 'run/' matched no tests" || fail "a selector matching no case did not fail" "$nomatch"
echo "$skip" | grep -qxF -- "- tests: skipped tests present ('bayan')" || fail "a skipped part did not fail" "$skip"
echo "$buildfail" | grep -qxF -- "- build: bootstrap-build.sh failed — bootstrap-build.sh: stage 1 failed" || fail "a failing bootstrap-build.sh did not fail the build" "$buildfail"
echo "$notask" | grep -qxF -- "- checks: no --task, so the content checks cannot run (pass --task T<n>)" || fail "no --task did not fail the content checks" "$notask"
[ -z "$dotnetcalls" ] || fail "the guard called dotnet" "$dotnetcalls"
echo "$covpass" | grep -q 'is in no build' && fail "a changed file in the coverage report was reported absent" "$covpass"
echo "$covmissfail" | grep -q '^GUARD FAIL' && echo "$covmissfail" | grep -qxF -- "- coverage: coverage-missing failed: bayan: pinned build failed" \
  || fail "a failed coverage-missing run was not a FAIL item" "$covmissfail"
echo "$covnone" | grep -q "^- coverage: the tests wrote no tmp/guard-run/coverage/bayan-quality.json: no test under --filter 'run/ bayan' builds a selfhost program with src/semantics/a.byn$" \
  || fail "a coverage run without a report (an earlier run's left in place) did not fail" "$covnone"
echo "$stdbad" | grep -q '^- format: bayan format --check lib/std failed: .*lib/std/m/x.byn' || fail "a misformatted lib/std file did not fail the format check naming it" "$stdbad"
echo "$stdgood" | grep -q '^- format:' && fail "a formatted lib/std file failed the format check" "$stdgood"
[ "$stdfilter" = "bayan test tests/cases --only run/
test.sh --only bayan" ] || fail "a lib/std change did not add the bayan part to a filter without it" "$stdfilter"
[ "$stdkeep" = "bayan test tests/cases --only run/
test.sh --only bayan" ] || fail "a lib/std change with the bayan part in the filter ran it other than once" "$stdkeep"
echo "$stdcovpass" | grep -q '^GUARD PASS$' && echo "$stdcovpass" | grep -qF "coverage: lib/std/m/x.byn: touched functions: lines 1/1" || fail "a covered lib/std change did not pass with its coverage line" "$stdcovpass"
echo "$stdcovmiss" | grep -q '^- coverage: missed line lib/std/m/x.byn:2; ' || fail "an uncovered lib/std function was not a FAIL item with file:line" "$stdcovmiss"
echo "$stduntouched$stduntouchedfail" | grep -q '^- format:' && fail "a branch not touching lib/std ran the lib/std format check" "$stduntouched$stduntouchedfail"
case ",$stdcover," in *,lib/std/m/x.byn,*) ;; *) fail "a changed lib/std file was not in BAYAN_COVERAGE_FILES ($stdcover)" "$stdbad";; esac
echo PASS
