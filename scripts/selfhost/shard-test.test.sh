#!/bin/bash
# shard-test.sh sub-commands on fixtures under tmp/, no host touched: TRX parsing into per-class sums, the median weight for a class
# missing from the TSV, packing by host speed, filter chunking, the merge of fake slice results (totals, failing names, exit code),
# and --dry-run (which must not call ssh: a fake ssh on PATH records any call).
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/shard-test-test"; S="$root/scripts/selfhost/shard-test.sh"
rm -rf "$t" && mkdir -p "$t/bin" && cd "$t"
fail=0; ok() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected [$3] got [$2]"; fail=1; fi; }

cat > a.trx <<'X'
<?xml version="1.0"?>
<TestRun><Results>
<UnitTestResult testId="t1" duration="00:00:01.5000000" outcome="Passed" />
<UnitTestResult testId="t2" duration="00:01:00.2500000" outcome="Passed" />
<UnitTestResult testId="t3" duration="00:00:02.0000000" outcome="Failed" />
</Results><TestDefinitions>
<UnitTest name="A" storage="x" id="t1"><Execution id="e1" /><TestMethod codeBase="x" className="N.AlphaTests" name="A" /></UnitTest>
<UnitTest name="B" storage="x" id="t2"><Execution id="e2" /><TestMethod codeBase="x" className="N.AlphaTests" name="B" /></UnitTest>
<UnitTest name="C" storage="x" id="t3"><Execution id="e3" /><TestMethod codeBase="x" className="N.BetaTests" name="C" /></UnitTest>
</TestDefinitions></TestRun>
X
ok "trx per-class sums" "$(bash "$S" times a.trx out.tsv >/dev/null; cat out.tsv | tr '\t\n' ' =')" "N.AlphaTests 61.750=N.BetaTests 2.000="

# median fallback: weights 10, 20, 90 -> median 20 for the missing class; odd/even
printf 'C1\t10\nC2\t20\nC3\t90\n' > w.tsv; printf 'C1\nC2\nC3\nNew\n' > cls.txt
ok "median weight for a missing class" "$(bash "$S" pack cls.txt w.tsv h=1 | awk -F'\t' '$3 == "New" { print $2 }')" "20.000"
printf 'C1\t10\nC2\t20\nC3\t30\nC4\t40\n' > w4.tsv; printf 'C1\nNew\n' > cls1.txt
ok "median of an even count" "$(bash "$S" pack cls1.txt w4.tsv h=1 | awk -F'\t' '$3 == "New" { print $2 }')" "25.000"
printf 'A\nB\n' > cls2.txt; : > empty.tsv
ok "no recorded times: weight 1" "$(bash "$S" pack cls2.txt empty.tsv h=1 | cut -f2 | tr '\n' ' ')" "1.000 1.000 "

# packing by speed: ten equal classes of 10s on vm=2 wp1=1 -> vm 7 (finish 35), wp1 3 (30)... greedy by finish time
for i in 1 2 3 4 5 6 7 8 9 10; do printf 'K%s\t10\n' $i; done > eq.tsv; cut -f1 eq.tsv > eq.txt
p=$(bash "$S" pack eq.txt eq.tsv vm=2,wp1=1)
ok "faster host gets about twice the load" "$(echo "$p" | cut -f1 | sort | uniq -c | awk '{ printf "%s=%s ", $2, $1 }')" "vm=7 wp1=3 "
# longest first: 50,30,20 on equal hosts -> 50 alone, 30+20 together
printf 'L\t50\nM\t30\nN\t20\n' > lf.tsv; cut -f1 lf.tsv > lf.txt
ok "longest-first packing" "$(bash "$S" pack lf.txt lf.tsv a=1,b=1 | awk -F'\t' '{ printf "%s:%s ", $1, $3 }')" "a:L b:M b:N "

# filter chunking
f1=$(printf 'A.X\nB.Y\n' | bash "$S" filters 1000)
ok "one filter" "$f1" "FullyQualifiedName~A.X.|FullyQualifiedName~B.Y."
n=$(printf 'A.X\nB.Y\nC.Z\n' | bash "$S" filters 45 | wc -l | tr -d ' ')
ok "chunked when over the max" "$n" "3"
ok "chunks within the max" "$(printf 'A.X\nB.Y\nC.Z\nD.W\n' | bash "$S" filters 45 | awk 'length > 45' | wc -l | tr -d ' ')" "0"
ok "all classes kept" "$(seq 1 500 | sed 's/^/Ns.Class/' | bash "$S" filters 2000 | tr '|' '\n' | wc -l | tr -d ' ')" "500"

# merge
mkdir -p m && cd m
printf 'Passed!  - Failed:     0, Passed:    10, Skipped:     0, Total:    10\n' > vm.log
printf '== chunk 1\nFailed!  - Failed:     1, Passed:     4, Skipped:     0, Total:     5\n  Failed N.BetaTests.C [5 ms]\nFailed!  - Failed:     0, Passed:     3, Skipped:     0, Total:     3\n' > wp1.log
mk() { printf 'host=%s\nwall=%s\nrc=%s\ndone=%s\nlog=%s\n' "$1" "$2" "$3" "$4" "$PWD/$1.log" > "$1.result"; }
mk vm 100 0 1; mk wp1 150 1 1; echo 160 > overall.wall
set +e; out=$(bash "$S" merge .); rc=$?; set -e
ok "merge fails on a failed slice" "$rc" "1"
ok "merge totals" "$(echo "$out" | grep '^total')" "total: passed 17, failed 1, overall wall 160s (2.7 min)"
ok "merge failing names per host" "$(echo "$out" | grep "^  FAIL")" "  FAIL [wp1] N.BetaTests.C"
ok "merge per-slice wall" "$(echo "$out" | grep -c 'wall 100s\|wall 150s')" "2"
printf 'Failed!  - Failed:     0, Passed:     4, Skipped:     0, Total:     4\n' > wp1.log; mk wp1 150 0 1
set +e; bash "$S" merge . > /dev/null; rc=$?; set -e; ok "merge ok when all pass" "$rc" "0"
mk wp1 150 0 0; set +e; out=$(bash "$S" merge .); rc=$?; set -e
ok "merge fails on an unfinished slice" "$rc.$(echo "$out" | grep -c 'DID NOT FINISH')" "1.1"
rm -f overall.wall; mk wp1 150 0 1
ok "overall wall defaults to the slowest slice" "$(bash "$S" merge . | grep '^total' | grep -o 'wall [0-9]*s')" "wall 150s"
printf 'vm\nwp1\n' > hosts; rm -f vm.result
set +e; out=$(bash "$S" merge .); rc=$?; set -e
ok "merge fails when a host left no result" "$rc.$(echo "$out" | grep -c '^vm: no result')" "1.1"
rm -f hosts
cd ..

# dry run: no host is touched
printf '#!/bin/bash\necho "$0 $*" >> "%s/ssh-calls"\n' "$t" > bin/ssh; cp bin/ssh bin/scp; chmod +x bin/ssh bin/scp
git init -q -b base . && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m "test: base"
d=$(PATH="$t/bin:$PATH" bash "$S" run --dry-run --classes cls.txt --times w.tsv --host vm=1.45 --host wp1=1.0 2>&1)
ok "dry run touches no host" "$([ -e ssh-calls ] && echo called || echo none)" "none"
ok "dry run lists both slices" "$(echo "$d" | grep -c '^-- ')" "2"
ok "speed 0 rejected" "$(bash "$S" run --dry-run --classes cls.txt --host vm=0 2>&1 | head -1)" "shard-test: bad speed in vm=0 (must be above 0)"
ok "speed . rejected" "$(bash "$S" run --dry-run --classes cls.txt --host vm=. 2>&1 | head -1)" "shard-test: bad speed in vm=. (must be above 0)"
ok "dry run rejects wlt1" "$(bash "$S" run --dry-run --classes cls.txt --host wlt1=1 2>&1 | head -1)" "shard-test: unsupported host wlt1 (vm, wp1)"

cd "$root"; rm -rf "$t"
[ $fail = 0 ] && echo "shard-test.test: all passed" || { echo "shard-test.test: FAILED"; exit 1; }
