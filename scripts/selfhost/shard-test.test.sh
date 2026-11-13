#!/bin/bash
# shard-test.sh sub-commands on fixtures under tmp/, no host touched: TRX parsing into per-class sums (and the merge of two TRX files),
# the median weight for a class missing from the TSV, host spec parsing, packing by host speed, serial classes and threads, the serial
# class list from a fixture .cs tree, filter chunking, the merge of fake slice results (totals, failing names, exit code), poll verdicts,
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

cat > b.trx <<'X'
<?xml version="1.0"?>
<TestRun><Results>
<UnitTestResult testId="u1" duration="00:00:10.0000000" outcome="Passed" />
<UnitTestResult testId="u2" duration="00:00:07.0000000" outcome="Passed" />
<UnitTestResult testId="u3" duration="00:00:05.0000000" outcome="Passed" />
</Results><TestDefinitions>
<UnitTest name="A" storage="x" id="u1"><Execution id="e1" /><TestMethod codeBase="x" className="N.AlphaTests" name="A" /></UnitTest>
<UnitTest name="C" storage="x" id="u2"><Execution id="e2" /><TestMethod codeBase="x" className="N.BetaTests" name="C" /></UnitTest>
<UnitTest name="G" storage="x" id="u3"><Execution id="e3" /><TestMethod codeBase="x" className="N.GammaTests" name="G" /></UnitTest>
</TestDefinitions></TestRun>
X
ok "times merges two trx files, the larger per class" "$(bash "$S" times a.trx b.trx out2.tsv >/dev/null; cat out2.tsv | tr '\t\n' ' =')" \
  "N.AlphaTests 61.750=N.BetaTests 7.000=N.GammaTests 5.000="

# host spec NAME=SPEED[:SLICES[:THREADS]]: defaults 1 slice, 4 threads; each bad part named, exit 2
ok "host spec defaults" "$(bash "$S" host-spec vm=0.91) $(bash "$S" host-spec wlt1=0.45:1) $(bash "$S" host-spec mb1=.71)" "vm=0.91:1:4 wlt1=0.45:1:4 mb1=.71:1:4"
ok "host spec slices and threads" "$(bash "$S" host-spec vm=0.91:2:8)" "vm=0.91:2:8"
while IFS='|' read -r spec msg; do
  set +e; got=$(bash "$S" host-spec "$spec" 2>&1); rc=$?; set -e
  ok "host spec $spec refused" "$rc $got" "2 shard-test: $msg"
done <<'X'
xyz=1|unsupported host xyz in xyz=1 (vm, wp1, wlt1, mb1)
vm|bad host vm (NAME=SPEED[:SLICES[:THREADS]])
vm=1:2:3:4|bad host vm=1:2:3:4 (NAME=SPEED[:SLICES[:THREADS]])
vm=abc|bad speed in vm=abc
vm=0:2|bad speed in vm=0:2 (must be above 0)
vm=1:0|bad slices in vm=1:0 (a positive integer)
vm=1:x|bad slices in vm=1:x (a positive integer)
vm=1:|bad slices in vm=1: (a positive integer)
wp1=1:2|bad slices in wp1=1:2 (only vm runs more than one slice)
vm=1:1:0|bad threads in vm=1:1:0 (a positive integer)
vm=1:2:x|bad threads in vm=1:2:x (a positive integer)
mb1=1:1:|bad threads in mb1=1:1: (a positive integer)
X

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

# serial-aware packing: serial S1, S2 (30s each) and a parallel P1 (60s) on two equal units at 4 threads. Counted by raw seconds
# P1 goes alone and S1+S2 share a unit (60s one at a time); counted as serial + parallel/4 the serial classes are split (max 45s).
printf 'S1\t30\nS2\t30\nP1\t60\n' > ser.tsv; cut -f1 ser.tsv > ser.txt; printf 'S1\nS2\n' > serial.txt
cost() { awk -F'\t' 'FILENAME == ARGV[1] { s[$1] = 1; next } { if ($3 in s) S[$1] += $2; else P[$1] += $2; u[$1] = 1 }
  END { for (k in u) { c = S[k] + P[k] / 4; if (c > m) m = c } print m }' serial.txt -; }
old=$(bash "$S" pack ser.txt ser.tsv a=1,b=1); new=$(bash "$S" pack ser.txt ser.tsv a=1,b=1 serial.txt)
ok "without the serial list both serial classes share a unit" "$(echo "$old" | awk -F'\t' '{ printf "%s:%s ", $1, $3 }').$(echo "$old" | cost)" "a:P1 b:S1 b:S2 .60"
ok "serial-aware: the serial classes are split" "$(echo "$new" | awk -F'\t' '{ printf "%s:%s ", $1, $3 }').$(echo "$new" | cost)" "a:S1 a:P1 b:S2 .45"
# threads: eight parallel classes of 10s; equal threads split evenly, 1 against 8 threads puts most on the 8-thread unit
for i in 1 2 3 4 5 6 7 8; do printf 'Q%s\t10\n' $i; done > q.tsv; cut -f1 q.tsv > q.txt
cnt() { cut -f1 | sort | uniq -c | awk '{ printf "%s=%s ", $2, $1 }'; }
ok "equal threads: even split" "$(bash "$S" pack q.txt q.tsv a=1:1:4,b=1:1:4 serial.txt | cnt)" "a=4 b=4 "
ok "threads change the split" "$(bash "$S" pack q.txt q.tsv a=1:1:1,b=1:1:8 serial.txt | cnt)" "a=1 b=7 "
ok "two vm slices are units vm1 and vm2" "$(bash "$S" pack q.txt q.tsv vm=1:2,wp1=1 serial.txt | cnt)" "vm1=3 vm2=3 wp1=2 "

# the serial class list from [CollectionDefinition(..., DisableParallelization = true)] and [Collection(...)] in a .cs tree
mkdir -p cs
cat > cs/A.cs <<'X'
namespace Ns.A;

[CollectionDefinition(nameof(Ser), DisableParallelization = true)]
public sealed class Ser;
[CollectionDefinition(nameof(Par))]
public sealed class Par;

[Collection(nameof(Ser))]
public sealed class OneTests
{
}

[Collection(nameof(Par))]
public sealed class TwoTests
{
}
X
cat > cs/B.cs <<'X'
namespace Ns.B
{
    [Collection("Ser")]  // the string form
    public sealed partial class ThreeTests(ITestOutputHelper output) : IDisposable
    {
    }

    [Collection(nameof(Ser))]
    /// <summary>the class's own directory</summary>
    [Trait("a", "b")]
    internal class FourTests
    {
    }

    public class FiveTests
    {
    }
}
X
ok "serial classes from the .cs tree" "$(bash "$S" serial cs | tr '\n' ' ')" "Ns.A.OneTests Ns.B.FourTests Ns.B.ThreeTests "
ok "no .cs files: no serial classes" "$(bash "$S" serial nowhere | wc -l | tr -d ' ')" "0"

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

# poll verdicts
ps() { printf "$1" | bash "$S" poll-state; }
ok "poll: no answer is a miss" "$(ps '')" "miss"
ok "poll: host answers, VM does not, is a miss" "$(ps 'MemAvailable: 20000000 kB\n')" "miss"
ok "poll: rc written" "$(ps 'MemAvailable: 20000000 kB\n---\n0\n---\ninactive\n')" "done 0"
ok "poll: host memory under 10 GiB" "$(ps 'MemAvailable: 9000000 kB\n---\n---\nactive\n')" "lowmem 9000000"
ok "poll: unit ended without rc" "$(ps 'MemAvailable: 20000000 kB\n---\n---\nfailed\n')" "ended"
ok "poll: host memory under 10 GiB while the VM does not answer" "$(ps 'MemAvailable: 3000000 kB\n')" "lowmem 3000000"
ok "poll: running" "$(ps 'MemAvailable: 20000000 kB\n---\n---\nactive\n')" "running"
p2='MemAvailable: 20000000 kB\n=== vm1\n---\n0\n---\ninactive\n=== vm2\n---\n---\nactive\n'
ok "poll of two units: each its own verdict" "$(printf "$p2" | bash "$S" poll-state vm1) $(printf "$p2" | bash "$S" poll-state vm2) $(printf "$p2" | bash "$S" poll-state vm3)" "done 0 running miss"

# dry run: no host is touched
printf '#!/bin/bash\necho "$0 $*" >> "%s/ssh-calls"\n' "$t" > bin/ssh; cp bin/ssh bin/scp; chmod +x bin/ssh bin/scp
git init -q -b base . && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m "test: base"
d=$(PATH="$t/bin:$PATH" bash "$S" run --dry-run --classes cls.txt --times w.tsv --host vm=1.45 --host wp1=1.0 2>&1)
ok "dry run touches no host" "$([ -e ssh-calls ] && echo called || echo none)" "none"
ok "dry run lists both slices" "$(echo "$d" | grep -c '^-- ')" "2"
ok "speed 0 rejected" "$(bash "$S" run --dry-run --classes cls.txt --host vm=0 2>&1 | head -1)" "shard-test: bad speed in vm=0 (must be above 0)"
ok "speed . rejected" "$(bash "$S" run --dry-run --classes cls.txt --host vm=. 2>&1 | head -1)" "shard-test: bad speed in vm=. (must be above 0)"
ok "dry run rejects an unknown host" "$(bash "$S" run --dry-run --classes cls.txt --host wlt2=1 2>&1 | head -1)" "shard-test: unsupported host wlt2 in wlt2=1 (vm, wp1, wlt1, mb1)"
set +e; bash "$S" run --dry-run --classes cls.txt --host vm=1:2:0 > /dev/null 2>&1; rc=$?; set -e; ok "a bad host spec exits 2" "$rc" "2"
ok "default hosts are vm and wp1" "$(PATH="$t/bin:$PATH" bash "$S" run --dry-run --classes cls.txt --times w.tsv 2>&1 | sed -n 's/^-- \(.*\) classes:$/\1/p' | tr '\n' ' ')" "vm wp1 "
s8=$(git rev-parse HEAD | cut -c1-8)
d=$(PATH="$t/bin:$PATH" bash "$S" run --dry-run --classes q.txt --times q.tsv --host vm=1:2:6 --host wp1=1 --host wlt1=1:1:3 --host mb1=1 2>&1)
ok "dry run with four hosts touches no host" "$([ -e ssh-calls ] && echo called || echo none)" "none"
ok "dry run names the units" "$(echo "$d" | sed -n 's/^-- \(.*\) classes:$/\1/p' | tr '\n' ' ')" "vm1 vm2 wp1 wlt1 mb1 "
ok "dry run: vm1 and vm2 in their own unit and directory" "$(echo "$d" | grep -c "systemd-run --unit=shard-$s8-1 in /home/bt/shard/$s8-1).*MaxParallelThreads=6")$(echo "$d" | grep -c "systemd-run --unit=shard-$s8-2 in /home/bt/shard/$s8-2).*MaxParallelThreads=6")" "11"
ok "dry run: wlt1 through wp1-test.sh" "$(echo "$d" | grep -c "^  WIN_HOST=wlt1 WIN_THREADS=3 bash scripts/selfhost/wp1-test.sh base ")" "1"
ok "dry run: mb1 local, in its own clone" "$(echo "$d" | grep -c "^  (in tmp/shard/$s8/mb1/repo, DOTNET_ROOT=\$HOME/.dotnet) nice dotnet test .*MaxParallelThreads=4$")" "1"

cd "$root"; rm -rf "$t"
[ $fail = 0 ] && echo "shard-test.test: all passed" || { echo "shard-test.test: FAILED"; exit 1; }
