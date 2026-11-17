#!/bin/bash
# Builds and runs each C driver under runtime/tests/ against bayan-rt.c, with no .NET. The build lines and pass
# conditions follow csharp/tests/Bayan.Tests (RuntimeNativeTests, StdPathTests, L005RunBatchTests).
# Compiler: $CC, else cc, else zig cc. Exits non-zero when any file fails.
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
rt="$root/runtime"

if [ -n "$CC" ]; then cc=($CC)
elif command -v cc >/dev/null 2>&1; then cc=(cc)
elif command -v zig >/dev/null 2>&1; then cc=(zig cc)
else echo "no C compiler: set CC, or install cc or zig" >&2; exit 2
fi

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) windows=1; lib=-lshell32 ;;
    *) windows=0; lib=-lm ;;
esac

mkdir -p "$root/tmp"
work=$(mktemp -d "$root/tmp/rt-tests.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT

pass=0; fail=0; skipped=0

ok() { echo "ok $1"; pass=$((pass + 1)); }
bad() { echo "FAIL $1${2:+: $2}"; fail=$((fail + 1)); }
skip() { echo "skip $1: $2"; skipped=$((skipped + 1)); }

hex() { printf '%s' "$1" | od -An -tx1 | tr -d ' \n'; }

# build <name> [runtime.c]: compiles tests/<name>.c with the runtime into $work/<name>.exe.
build() {
    "${cc[@]}" -std=c11 -fwrapv -ffp-contract=off -w -O0 -g -DBYN_DEBUG -I "$rt" \
        "$here/$1.c" "${2:-$rt/bayan-rt.c}" -o "$work/$1.exe" $lib >"$work/$1.build" 2>&1
}

# check <name> <expected-stdout>: the driver exits 0 and prints exactly the expected text.
check() {
    local name=$1.c
    build "$1" || { bad "$name" "build failed: $(cat "$work/$1.build")"; return; }
    "$work/$1.exe" >"$work/$1.out" 2>"$work/$1.err" || { bad "$name" "exit $?"; return; }
    tr -d '\r' <"$work/$1.out" >"$work/$1.lf"
    printf '%s' "$2" >"$work/$1.want"
    cmp -s "$work/$1.lf" "$work/$1.want" && ok "$name" || bad "$name" "unexpected output: $(cat "$work/$1.lf")"
}

# batch-cmdline.c: Windows cmd.exe command lines (and refusals), printed on every OS.
want='cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "a b""
cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" """
refused
refused
cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "^&|<>()!""
cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "a\""
refused
refused
refused
cmd.exe /d /e:ON /v:OFF /s /c ""C:\dir\X.CMD" "a""
cmd.exe /d /e:ON /v:OFF /s /c ""./run.Bat" "a""
refused
refused
refused
cmd.exe /d /e:ON /v:OFF /s /c "".\x.bat" "a""
cmd.exe /d /e:ON /v:OFF /s /c ""C:\x\y.cmd" "a""
cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd" "x" "y z""
cmd.exe /d /e:ON /v:OFF /s /c "".\echo.cmd""
refused
'
check batch-cmdline "$want"

# batch-cmdline-cases.c reads hex cases from stdin (`-` is an empty argument). Cases are the L005RunBatchTests.cs rows that pair
# a path and arguments with the exact command line (ModelReadsKnownCommandLines, lines 113-119), the same on every OS; the
# generated corpus is T24b.
if build batch-cmdline-cases; then
    P='cmd.exe /d /e:ON /v:OFF /s /c '
    in="$(hex '.\echo.cmd') $(hex 'a b')
$(hex '.\echo.cmd') -
$(hex '.\echo.cmd') $(hex '^&|<>()!')
$(hex '.\echo.cmd') $(hex 'a\')
$(hex '.\echo.cmd') $(hex x) $(hex 'y z')
$(hex '.\echo.cmd')
$(hex 'C:\dir\X.CMD') $(hex a)
"
    want="$(hex "$P"'"".\echo.cmd" "a b""')"'
'"$(hex "$P"'"".\echo.cmd" """')"'
'"$(hex "$P"'"".\echo.cmd" "^&|<>()!""')"'
'"$(hex "$P"'"".\echo.cmd" "a\""')"'
'"$(hex "$P"'"".\echo.cmd" "x" "y z""')"'
'"$(hex "$P"'"".\echo.cmd""')"'
'"$(hex "$P"'""C:\dir\X.CMD" "a""')"'
'
    printf '%s' "$in" | "$work/batch-cmdline-cases.exe" 2>&1 | tr -d '\r' >"$work/bcc.out"
    rc=${PIPESTATUS[1]}
    printf '%s' "$want" >"$work/bcc.want"
    if [ $rc -eq 0 ] && cmp -s "$work/bcc.out" "$work/bcc.want"; then ok batch-cmdline-cases.c
    else bad batch-cmdline-cases.c "exit $rc: $(cat "$work/bcc.out")"; fi
else bad batch-cmdline-cases.c "build failed: $(cat "$work/batch-cmdline-cases.build")"; fi

# path-relative-cases.c reads hex cases from stdin. StdPathTests.cs holds no expected result for any pair (the expected text
# comes from Path.GetRelativePath at run time), so the pairs of StdPathTests.cs:60-61 are fed and only the exit code and one
# output line per case are checked; the compared results are T24b.
if build path-relative-cases; then
    in="$(hex /a/b) $(hex /a/b/c)
$(hex /a/b) $(hex /a/B/c)
$(hex /A/b) $(hex /a/b)
$(hex /a/b) $(hex /a/c)
$(hex /a/b) $(hex /x)
$(hex /a/b/) $(hex /a/b)
$(hex /a) $(hex /a/./b/../c)
$(hex /) $(hex /a)
"
    printf '%s' "$in" | "$work/path-relative-cases.exe" 2>&1 | tr -d '\r' >"$work/prc.out"
    rc=${PIPESTATUS[1]}
    lines=$(wc -l <"$work/prc.out" | tr -d ' ')
    if [ $rc -eq 0 ] && [ "$lines" = 8 ]; then ok path-relative-cases.c
    else bad path-relative-cases.c "exit $rc, $lines output lines for 8 cases"; fi
else bad path-relative-cases.c "build failed: $(cat "$work/path-relative-cases.build")"; fi

# io-run-posix.c
if [ $windows = 1 ]; then skip io-run-posix.c "POSIX only"
else
    check io-run-posix "left group: 11 in time 1
left group with helper: 11 in time 1 child gone 1
longest timeout: 0 code 0
deleted directory: 0 code 0
deleted directory, empty PATH entry: 0 code 0
"
fi

# wait-status.c: a real SIGKILL status exists on POSIX only.
want="failed raw 0: 5 code -1 detail -1
query failed raw 259: 5 code -1 detail -1
failed raw 259: 5 code -1 detail -1
timed out: 11 code -1 detail -1
"
[ $windows = 1 ] || want="${want}signaled: 10 code -1 detail 9
"
check wait-status "${want}exit 3: 0 code 3 detail -1
"

check zero-resize "hex 0, zero-byte requests 0
"
check strbuf-grow "cap 128, taken text unchanged 1, old blocks handed back 0
"

# io-read-release.c: the heap is measured on macOS and glibc only, elsewhere the driver prints "unsupported".
mkdir -p "$work/io"
if build io-read-release; then
    "$work/io-read-release.exe" "$work/io/invalid.bin" "$work/io" >"$work/irr.out" 2>"$work/irr.err"
    rc=$?
    tr -d '\r' <"$work/irr.out" >"$work/irr.lf"
    out=$(cat "$work/irr.lf")
    musl=0
    ls /lib/ld-musl-* >/dev/null 2>&1 && musl=1
    if [ $rc -ne 0 ]; then bad io-read-release.c "exit $rc"
    elif [ "$out" = "file 3 leaked 0, stdin 3 leaked 0, dir failed 1 leaked 0, dir stdin failed 1 leaked 0" ]; then ok io-read-release.c
    elif [ "$out" = unsupported ] && { [ $windows = 1 ] || { [ "$(uname -s)" != Darwin ] && [ "$(uname -s)" != Linux ]; } || [ $musl = 1 ]; }; then
        skip io-read-release.c "no heap introspection on this platform"
    else bad io-read-release.c "unexpected output: $out"; fi
else bad io-read-release.c "build failed: $(cat "$work/io-read-release.build")"; fi

# cov-flush.c: a panic aborts the program (non-zero exit) after the coverage flush printed its line.
if build cov-flush; then
    bash -c '"$0"; exit $?' "$work/cov-flush.exe" >"$work/cov.out" 2>/dev/null
    rc=$?
    tr -d '\r' <"$work/cov.out" >"$work/cov.lf"
    printf 'flushed\n' >"$work/cov.want"
    if [ $rc -ne 0 ] && cmp -s "$work/cov.lf" "$work/cov.want"; then ok cov-flush.c
    else bad cov-flush.c "exit $rc: $(cat "$work/cov.lf")"; fi
else bad cov-flush.c "build failed: $(cat "$work/cov-flush.build")"; fi

check runtime-properties "ok
"

# run-terminate-fails.c: Windows only, against a runtime whose TerminateJobObject call always fails.
if [ $windows = 0 ]; then skip run-terminate-fails.c "Windows only"
else
    terminate='if (!TerminateJobObject(job, 1) ||'
    if [ "$(grep -cF "$terminate" "$rt/bayan-rt.c")" != 1 ]; then bad run-terminate-fails.c "no single TerminateJobObject call to replace"
    else
        mkdir "$work/rtf"
        cp "$rt/bayan-rt.h" "$work/rtf/"
        awk -v t="$terminate" '{ i = index($0, t); if (i) $0 = substr($0, 1, i - 1) "if (true ||" substr($0, i + length(t)); print }' "$rt/bayan-rt.c" >"$work/rtf/bayan-rt.c"
        if build run-terminate-fails "$work/rtf/bayan-rt.c"; then
            "$work/run-terminate-fails.exe" >"$work/rtf.out" 2>/dev/null
            rc=$?
            tr -d '\r' <"$work/rtf.out" >"$work/rtf.lf"
            printf 'result 5 in time 1\n' >"$work/rtf.want"
            if [ $rc -eq 0 ] && cmp -s "$work/rtf.lf" "$work/rtf.want"; then ok run-terminate-fails.c
            else bad run-terminate-fails.c "exit $rc: $(cat "$work/rtf.lf")"; fi
        else bad run-terminate-fails.c "build failed: $(cat "$work/run-terminate-fails.build")"; fi
    fi
fi

echo "$pass ok, $fail failed, $skipped skipped"
[ $fail -eq 0 ]
