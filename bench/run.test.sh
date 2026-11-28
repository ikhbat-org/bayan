#!/usr/bin/env bash
# Tests for bench/run.sh: usage and failure paths, and the result file format (with a bayan stub that cannot build).
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected '$3', got '$2'"; fail=1; fi; }

bash bench/run.sh --bogus >/dev/null 2>&1; check "unknown argument exits 2" "$?" 2
bash bench/run.sh --help >/dev/null 2>&1; check "--help exits 0" "$?" 0
BENCH_RUNS=0 bash bench/run.sh >/dev/null 2>&1; check "BENCH_RUNS=0 exits 2" "$?" 2

d="tmp/bench-test-run-$$"
mkdir -p "$d"
printf '#!/bin/sh\nexit 1\n' > "$d/bayan"
chmod +x "$d/bayan"
out=$(BENCH_RUNS=1 BAYAN_BIN="$d/bayan" BENCH_TMP="$d/t" BENCH_RESULTS="$d/results" bash bench/run.sh 2>&1)
check "run with a failing bayan exits 0" "$?" 0
commit=$(git rev-parse --short HEAD)
f="$d/results/$commit.txt"
check "result file is <commit>.txt" "$([ -s "$f" ] && echo yes || echo no)" yes
check "result file equals the printed table" "$(cat "$f")" "$out"
check "header names the commit" "$(sed -n 1p "$f" | grep -c "^bayan bench $commit ")" 1
check "column line" "$(sed -n 2p "$f" | tr -s ' ')" "benchmark bayan c rust zig go checksum"
for b in hash parse lexer; do check "row $b" "$(grep -c "^$b " "$f")" 1; done
check "bayan cell reports the failure" "$(grep -c "^hash .*n/a (build failed)" "$f")" 1
if command -v cc >/dev/null 2>&1; then
    check "hash row has a ratio to C" "$(grep "^hash " "$f" | grep -c '1\.00x')" 1
    check "hash checksum printed" "$(grep "^hash " "$f" | grep -c '12143377579992967301$')" 1
else
    echo "skip: no cc"
fi
if command -v go >/dev/null 2>&1; then
    check "go cell has a ratio to C" "$(grep "^hash " "$f" | grep -c 'ms (.*x) *[0-9]\{8,\}$')" 1
    check "go checksum agrees with C on parse" "$(grep "^parse " "$f" | grep -c '14091657157103084200$')" 1
else
    echo "skip: no go"
fi
# Absent go: every PATH directory holding go is replaced by a directory of symlinks to everything else in it.
nopath=""; i=0; IFS=: read -ra pdirs <<< "$PATH"
for p in "${pdirs[@]}"; do
    if [ -x "$p/go" ]; then
        i=$((i + 1)); mkdir -p "$d/nogo$i"
        for e in "$p"/*; do [ "$(basename "$e")" = go ] || ln -sf "$e" "$d/nogo$i/$(basename "$e")"; done
        p="$PWD/$d/nogo$i"
    fi
    nopath="$nopath:$p"
done
nopath=${nopath#:}
out=$(PATH="$nopath" BENCH_RUNS=1 BAYAN_BIN="$d/bayan" BENCH_TMP="$d/t7" BENCH_RESULTS="$d/results7" bash bench/run.sh 2>&1)
check "absent go: hash row says n/a (no go)" "$(echo "$out" | grep -c "^hash .*n/a (no go)")" 1
check "absent go: parse row says n/a (no go)" "$(echo "$out" | grep -c "^parse .*n/a (no go)")" 1
check "go build uses no flags" "$(grep -c 'go build -o "\$T/bin/go-\$b" "bench/programs/go/\$b.go"' bench/run.sh)" 1

# RID mapping (bench/rid.sh) for faked uname values.
. bench/rid.sh
check "rid Darwin arm64" "$(bench_rid Darwin arm64)" osx-arm64
check "rid Darwin x86_64" "$(bench_rid Darwin x86_64)" osx-x64
check "rid Linux x86_64" "$(bench_rid Linux x86_64)" linux-x64
check "rid Linux aarch64" "$(bench_rid Linux aarch64)" linux-arm64
check "rid MINGW64 x86_64" "$(bench_rid MINGW64_NT-10.0 x86_64)" win-x64
check "rid MSYS x86_64" "$(bench_rid MSYS_NT-10.0 x86_64)" win-x64
check "rid CYGWIN x86_64" "$(bench_rid CYGWIN_NT-10.0 x86_64)" win-x64
bench_rid Plan9 mips >/dev/null; check "rid unknown fails" "$?" 1
check "exe on Windows" "$(bench_exe MINGW64_NT-10.0)" bayan.exe
check "exe on Linux" "$(bench_exe Linux)" bayan

# Fake programs: the stub bayan builds the lexer into a script that prints "<ns> abc<FAKE_TAIL>" with ns popped
# from the FAKE_SEQ file, one value per run.
cat > "$d/fake" <<'FAKE'
#!/bin/sh
n=$(head -n1 "$FAKE_SEQ"); tail -n +2 "$FAKE_SEQ" > "$FAKE_SEQ.new"; mv "$FAKE_SEQ.new" "$FAKE_SEQ"
printf '%s abc%s\n' "$n" "$FAKE_TAIL"
FAKE
cat > "$d/fakebayan" <<'STUB'
#!/bin/sh
case "$2" in *programs*) exit 1 ;; esac
while [ $# -gt 0 ]; do if [ "$1" = "-o" ]; then cp "$FAKE_PROG" "$2"; chmod +x "$2"; fi; shift; done
exit 0
STUB
chmod +x "$d/fakebayan" "$d/fake"
# lexer <runs> <ns...>: the lexer row of a run whose fake program prints the given ns values in turn
lexer() {
    local r=$1; shift
    printf '%s\n' "$@" > "$d/seq"
    BENCH_RUNS=$r FAKE_SEQ="$d/seq" FAKE_PROG="$d/fake" BAYAN_BIN="$d/fakebayan" BENCH_TMP="$d/t3" BENCH_RESULTS="$d/results3" bash bench/run.sh 2>&1 | grep '^lexer ' | tr -s ' '
}
check "odd count takes the middle" "$(lexer 3 3000000 1000000 9000000)" "lexer 3.0 ms (n/a) n/a (no port) n/a (no port) n/a (no port) n/a (no port) abc"
check "even count takes the mean of the middle two" "$(lexer 4 3000000 1000000 10000000 2000000)" "lexer 2.5 ms (n/a) n/a (no port) n/a (no port) n/a (no port) n/a (no port) abc"
check "trailing CR is stripped from the checksum" "$(FAKE_TAIL=$'\r' lexer 1 5000000)" "lexer 5.0 ms (n/a) n/a (no port) n/a (no port) n/a (no port) n/a (no port) abc"
check "non-numeric ns" "$(lexer 1 fast | cut -c1-30)" "lexer n/a (bad output) n/a (no"
BENCH_RUNS=00 bash bench/run.sh >/dev/null 2>&1; check "BENCH_RUNS=00 exits 2" "$?" 2
check "BENCH_RUNS=08 is decimal" "$(lexer 08 1000000 1000000 1000000 1000000 1000000 1000000 1000000 1000000 | cut -c1-12)" "lexer 1.0 ms"

# A set but missing BAYAN_BIN never builds; an unset one runs BENCH_BUILD, whose failure is noted.
printf '#!/bin/sh\ntouch "%s/built"\necho "stage 1 failed" >&2\nexit 1\n' "$d" > "$d/fakebuild"
out=$(BENCH_BUILD="$d/fakebuild" BENCH_RUNS=1 BAYAN_BIN="$d/missing" BENCH_TMP="$d/t4" BENCH_RESULTS="$d/results4" bash bench/run.sh 2>&1)
check "missing BAYAN_BIN does not build" "$([ -e "$d/built" ] && echo yes || echo no)" no
check "missing BAYAN_BIN is noted" "$(echo "$out" | grep -c "^lexer .*n/a (no bayan at $d/missing)")" 1
out=$(unset BAYAN_BIN; BENCH_BUILD="$d/fakebuild" BENCH_RUNS=1 BENCH_TMP="$d/t5" BENCH_RESULTS="$d/results5" bash bench/run.sh 2>&1)
check "unset BAYAN_BIN runs the bootstrap build" "$([ -e "$d/built" ] && echo yes || echo no)" yes
check "a failed bootstrap build is noted" "$(echo "$out" | grep -c "^lexer .*n/a (no bayan: bootstrap build failed)")" 1
printf '#!/bin/sh\n[ "$1" = --out ] && echo "%s/fakebayan"\n' "$PWD/$d" > "$d/okbuild"
echo 4000000 > "$d/seq"
check "the built bayan is used" "$(unset BAYAN_BIN; BENCH_BUILD="$d/okbuild" BENCH_RUNS=1 FAKE_SEQ="$d/seq" FAKE_PROG="$d/fake" BENCH_TMP="$d/t6" BENCH_RESULTS="$d/results6" bash bench/run.sh 2>&1 | grep '^lexer ' | tr -s ' ')" "lexer 4.0 ms (n/a) n/a (no port) n/a (no port) n/a (no port) n/a (no port) abc"
check "no dotnet in bench/run.sh, baseline.sh, friction.sh" "$(cat bench/run.sh bench/baseline.sh bench/friction.sh | grep -c dotnet)" 0

# zig needs -lc on Linux.
check "zig build passes -lc" "$(grep -c 'zig build-exe -lc ' bench/run.sh)" 1
exit $fail
