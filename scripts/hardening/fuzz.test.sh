#!/usr/bin/env bash
# Tests scripts/hardening/fuzz.sh against fake afl-fuzz, afl-clang-fast, valgrind, bayan driver and run.sh scripts in a temporary
# directory under tmp/ (first on PATH), with FUZZ_DIR there too. A missing tool is named through FUZZ_AFL, FUZZ_CC and
# FUZZ_VALGRIND, as the real tools may be installed. FUZZ_SH overrides the script under test.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fuzz="${FUZZ_SH:-$root/scripts/hardening/fuzz.sh}"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/fuzz-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/fuzz" "$tmp/corpus" "$tmp/big"
export PATH="$tmp/bin:$PATH" FUZZ_DIR="$tmp/fuzz" FUZZ_CORPUS="$tmp/corpus"
unset FUZZ_AFL FUZZ_CC FUZZ_VALGRIND FUZZ_RUNSH HARDEN_CC BAYAN_EXE

cat >"$tmp/fuzzer_stats" <<'STATS'
start_time        : 1700000000
last_update       : 1700000120
fuzzer_pid        : 4242
execs_done        : 123456
execs_per_sec     : 1028.80
corpus_count      : 78
saved_crashes     : 3
saved_hangs       : 1
command_line      : afl-fuzz -V 120 -- x check y:z
STATS

# afl-fuzz: records its arguments and ASAN_OPTIONS, writes the fixture stats and one crash and one hang under -o.
cat >"$tmp/bin/afl-fuzz" <<STUB
#!/bin/sh
printf '%s\n' "\$@" >"$tmp/afl.args"
echo "\$ASAN_OPTIONS" >"$tmp/afl.asan"
echo "\$AFL_DEBUG_CHILD" >"$tmp/afl.debugchild"
while [ \$# -gt 0 ]; do [ "\$1" = -o ] && out=\$2; shift; done
mkdir -p "\$out/default/crashes" "\$out/default/hangs"
cp "$tmp/fuzzer_stats" "\$out/default/fuzzer_stats"
echo crash >"\$out/default/crashes/id:000000,sig:06"
echo hang >"\$out/default/hangs/id:000000"
STUB
printf '#!/bin/sh\nexit 0\n' >"$tmp/bin/afl-clang-fast"
# valgrind: skips its options and runs the program; exits 99 (an error) when the program's name is $FAKE_VG_ERR.
cat >"$tmp/bin/valgrind" <<'STUB'
#!/bin/sh
while [ $# -gt 0 ]; do case "$1" in -*) shift ;; *) break ;; esac; done
"$@"
rc=$?
case "${1##*/}" in "$FAKE_VG_ERR".exe.real) exit 99 ;; esac
exit $rc
STUB
# fakecc: writes an executable that exits 0 at its -o path.
cat >"$tmp/bin/fakecc" <<'STUB'
#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
printf '#!/bin/sh\nexit 0\n' >"$out"; chmod +x "$out"
STUB
# run.sh: builds two drivers through $CC and runs each, as runtime/tests/run.sh does.
cat >"$tmp/run.sh" <<STUB
#!/bin/bash
cc=(\$CC)
for n in alpha beta; do "\${cc[@]}" -O0 "$tmp/\$n.c" -o "$tmp/\$n.exe" || exit 2; "$tmp/\$n.exe" arg && echo "ok \$n.c" || echo "FAIL \$n.c"; done
echo "x ok, y failed, 0 skipped"
STUB
# bayan: `build` records its arguments and BAYAN_CC/HARDEN_* and writes its -o file; `check` panics on input holding CRASH.
cat >"$tmp/bin/fakebayan" <<STUB
#!/bin/sh
if [ "\$1" = build ]; then
    printf '%s\n' "\$@" "BAYAN_CC=\$BAYAN_CC" "HARDEN_CC=\$HARDEN_CC" "HARDEN_CFLAGS=\$HARDEN_CFLAGS" >"$tmp/build.args"
    while [ \$# -gt 0 ]; do [ "\$1" = -o ] && out=\$2; shift; done
    printf '#!/bin/sh\n' >"\$out"; chmod +x "\$out"; exit 0
fi
if grep -q CRASH "\$2"; then echo "panic: boom" >&2; exit 134; fi
echo "main.byn:1:1: error: nope" >&2; exit 1
STUB
chmod +x "$tmp"/bin/* "$tmp/run.sh"
printf 'main() {}\n' >"$tmp/corpus/a.byn"
head -c 5000 /dev/zero | tr '\0' x >"$tmp/big/big.byn"

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }
has() { printf '%s\n' "$1" | grep -qxF -- "$2"; }

err=$(FUZZ_AFL=no-afl-fuzz-here bash "$fuzz" --afl 2>&1); rc=$?
[ $rc = 1 ]; check "--afl without afl-fuzz exits 1" $?
printf '%s' "$err" | grep -q 'no no-afl-fuzz-here on PATH'; check "--afl names the missing afl-fuzz" $?
err=$(BAYAN_EXE="$tmp/bin/fakebayan" FUZZ_CC=no-afl-clang-here bash "$fuzz" --build 2>&1); rc=$?
[ $rc = 1 ]; check "--build without afl-clang-fast exits 1" $?
printf '%s' "$err" | grep -q 'no no-afl-clang-here on PATH'; check "--build names the missing compiler" $?
err=$(FUZZ_VALGRIND=no-valgrind-here bash "$fuzz" --valgrind 2>&1); rc=$?
[ $rc = 1 ]; check "--valgrind without valgrind exits 1" $?
printf '%s' "$err" | grep -q 'no no-valgrind-here on PATH'; check "--valgrind names the missing valgrind" $?

bash "$fuzz" >/dev/null 2>&1; [ $? = 2 ]; check "no mode is a usage error" $?
bash "$fuzz" --bogus >/dev/null 2>&1; [ $? = 2 ]; check "an unknown option is a usage error" $?
bash "$fuzz" --afl --valgrind >/dev/null 2>&1; [ $? = 2 ]; check "two modes are a usage error" $?
bash "$fuzz" --afl --minutes >/dev/null 2>&1; [ $? = 2 ]; check "--minutes without a value is a usage error" $?
bash "$fuzz" --afl --minutes x >/dev/null 2>&1; [ $? = 2 ]; check "a non-numeric --minutes is a usage error" $?
bash "$fuzz" --afl --minutes 0 >/dev/null 2>&1; [ $? = 2 ]; check "--minutes 0 is a usage error" $?
bash "$fuzz" --build >/dev/null 2>&1; [ $? = 2 ]; check "--build without BAYAN_EXE is a usage error" $?

out=$(BAYAN_EXE="$tmp/bin/fakebayan" bash "$fuzz" --build 2>&1); rc=$?
[ $rc = 0 ] && [ -x "$tmp/fuzz/bayan-afl" ]; check "--build writes bayan-afl" $?
args=$(cat "$tmp/build.args" 2>/dev/null)
[ "$(printf '%s\n' "$args" | head -n 6 | tr '\n' ' ')" = "build --package src -o $tmp/fuzz/bayan-afl src/driver " ]
check "--build runs build --package src -o bayan-afl src/driver" $?
has "$args" "BAYAN_CC=$root/scripts/hardening/cc-wrap.sh"; check "--build routes the compiler through cc-wrap.sh" $?
has "$args" "HARDEN_CC=afl-clang-fast"; check "--build compiles with afl-clang-fast" $?
has "$args" "HARDEN_CFLAGS=-fsanitize=address"; check "--build adds -fsanitize=address" $?

out=$(FUZZ_CORPUS="$tmp/big" bash "$fuzz" --afl 2>&1); rc=$?
[ $rc = 1 ]; check "a corpus file over 4096 bytes exits 1" $?
printf '%s' "$out" | grep -q "big.byn is 5000 bytes, over 4096"; check "the corpus check names the big file" $?
[ ! -f "$tmp/afl.args" ]; check "afl-fuzz does not run on a refused corpus" $?

out=$(bash "$fuzz" --afl --minutes 2 2>&1); rc=$?
[ $rc = 0 ]; check "--afl exits 0 with crashes" $?
has "$out" "afl: execs 123456, paths 78, crashes 3, hangs 1"; check "the stats line holds the fixture's counts" $?
has "$out" "  $tmp/fuzz/out/default/crashes/id:000000,sig:06"; check "--afl lists the crash file" $?
has "$out" "  $tmp/fuzz/out/default/hangs/id:000000"; check "--afl lists the hang file" $?
args=$(cat "$tmp/afl.args" 2>/dev/null)
[ "$(printf '%s\n' "$args" | head -n 2 | tr '\n' ' ')" = "-V 120 " ]; check "--minutes 2 runs afl-fuzz for 120 seconds" $?
has "$args" "none"; check "afl-fuzz runs with -m none" $?
[ "$(printf '%s\n' "$args" | tail -n 4 | tr '\n' ' ')" = "-- $tmp/fuzz/bayan-afl check $tmp/fuzz/in/main.byn " ]
check "afl-fuzz runs bayan-afl check in/main.byn" $?
[ "$(ls "$tmp/fuzz/seeds")" = a.byn ]; check "afl-fuzz is seeded with the corpus .byn files" $?
grep -q 'abort_on_error=1:symbolize=0:detect_leaks=0' "$tmp/afl.asan"; check "ASAN_OPTIONS aborts, does not symbolize or check leaks" $?
[ "$(cat "$tmp/afl.debugchild")" = 1 ]; check "afl-fuzz runs with AFL_DEBUG_CHILD=1 (fork server crash on WSL otherwise)" $?

echo CRASH >"$tmp/fuzz/out/default/crashes/id:000001"
out=$(BAYAN_EXE="$tmp/bin/fakebayan" bash "$fuzz" --triage 2>&1); rc=$?
[ $rc = 0 ]; check "--triage exits 0" $?
has "$out" "$(printf '%s\t1\t-' "$tmp/fuzz/out/default/crashes/id:000000,sig:06")"; check "--triage prints a diagnostics-only exit 1" $?
has "$out" "$(printf '%s\t134\tpanic: boom' "$tmp/fuzz/out/default/crashes/id:000001")"; check "--triage prints the panic line" $?
has "$out" "triage: crashes 2, findings 1"; check "a diagnostics-only exit 1 is not a finding" $?

out=$(FUZZ_RUNSH="$tmp/run.sh" HARDEN_CC=fakecc FAKE_VG_ERR=beta bash "$fuzz" --valgrind 2>&1); rc=$?
[ $rc = 0 ]; check "--valgrind exits 0 with errors" $?
has "$out" "valgrind: tests 2, clean 1, errors 1 (run.sh: x ok, y failed, 0 skipped)"; check "valgrind exit 99 is counted as an error" $?
has "$out" "  error beta.exe arg"; check "--valgrind names the erroring test" $?
[ -x "$tmp/alpha.exe.real" ]; check "--vg-cc builds the driver to <exe>.real" $?

echo "$pass passed, $failed failed"
[ $failed = 0 ]
