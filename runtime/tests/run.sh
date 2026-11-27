#!/bin/bash
# Builds and runs each C driver under runtime/tests/ against bayan-rt.c, with no .NET. The build lines and pass
# conditions follow the C# tests at tag csharp-final (RuntimeNativeTests, StdPathTests, L005RunBatchTests). It is the check: of
# laws L005 and L026.
# Compiler: $CC, else cc, else zig cc. Exits non-zero when any file fails.
# BAYAN_RT_CASES overrides the fixture directory (tests/cases).
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
pathcwd=$(mktemp -d "${TMPDIR:-/tmp}/rt-path.XXXXXX") || exit 2
trap 'chmod -R u+rwx "$work" 2>/dev/null; rm -rf "$work" "$pathcwd"' EXIT

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

# Frozen oracle fixtures (T24b): tests/cases/<os>/<name>.in is fed on stdin to <name>-cases.c and its stdout must equal
# <name>.expected byte for byte. Each `.in` field is hex; `@CWD@` at the start of a field stands for the hex of the directory
# the driver runs in ($work, the directory this script switches to). A missing fixture for this OS is a failure, not a skip.
cases="${BAYAN_RT_CASES:-$here/cases}"
case "$(uname -s)" in
    Darwin) os=macos ;;
    Linux) os=linux ;;
    MINGW*|MSYS*|CYGWIN*) os=windows ;;
    *) os=$(uname -s) ;;
esac
cd "$work" || exit 2
if [ $windows = 1 ]; then cwdhex=$(hex "$(pwd -W)"); else cwdhex=$(hex "$(pwd -P)"); fi
for name in batch-cmdline path-relative; do
    fx="$cases/$os/$name"
    if ! build "$name-cases"; then bad "$name-cases.c" "build failed: $(cat "$work/$name-cases.build")"
    elif [ ! -f "$fx.in" ] || [ ! -f "$fx.expected" ]; then bad "$name-cases.c" "no fixture $fx.{in,expected}"
    else
        sed "s/@CWD@/$cwdhex/g" "$fx.in" | "$work/$name-cases.exe" 2>&1 | tr -d '\r' >"$work/$name.out"
        rc=${PIPESTATUS[1]}
        if [ $rc -eq 0 ] && cmp -s "$work/$name.out" "$fx.expected"; then ok "$name-cases.c"
        else bad "$name-cases.c" "exit $rc, output differs from $fx.expected"; fi
    fi
done

# Spec 019 T26 fixtures (StdEnvTests, StdFsTests, StdPathTests rows exported at 3e54b7e91 on macOS and at 08b3f29b0 on Windows, wp1):
# tests/cases/<os>/<case>.in is replayed through the runtime by the family's driver and its stdout must equal <case>.expected; the
# path drivers' `--unmask` first turns the working-directory markers of the expected file into this directory's hex. An expected
# `panic <hex>` (.NET threw) wants a non-zero exit, no stdout and `panic: <message>` as the first stderr line. std-fs-cases.c builds its
# tree under $work/<case>.root with umask 022 and the fixture's modes, so the modes it prints are set, not the host's. The
# short-names row replays through path-relative-cases.c, as StdPathTests does. Windows-only rows are skipped elsewhere and the invalid
# UTF-8 row (raw bytes set through /bin/sh) on Windows. On Windows the drivers run without the `_` that bash exports (the export's
# process had none), and std-fs-cases.c exits 3 with a `skip: ` line when the fixture's links need a symlink privilege this account
# lacks, which is a skip. Linux has no export yet, so there a missing fixture is a skip; on macOS and Windows it is a failure.
# std-path-cases.c unmasks and replays in $pathcwd, a temporary directory outside the checkout: its rows from rooted names (`\a`)
# hold the export's working directory only where that directory's first component is none of them, and a checkout can start with
# one (hosted Windows checks out at D:\a\...). On Windows it is entered by its long name, as a short one (RUNNER~1) in the working
# directory would expand in .NET's results but not in the markers.
[ $windows = 0 ] || pathcwd=$(cygpath -ml "$pathcwd")
: >"$work/none.c"
for name in std-env-get-matches-dotnet std-env-invalid-utf8-value-matches-dotnet std-fs-file-exists-matches-dotnet \
    std-fs-io-remove-matches-dotnet std-fs-io-create-directory-matches-dotnet std-fs-io-remove-directory-matches-dotnet \
    std-fs-io-create-directory-extended-path-matches-dotnet std-fs-rename-matches-dotnet std-fs-copy-matches-dotnet \
    std-path-each-function-matches-dotnet std-path-case-tables-match-dotnet std-path-full-path-panics-where-dotnet-throws-space \
    std-path-short-names-expand-as-dotnet; do
    fx="$cases/$os/$name"
    case $name in
        std-env-*) drv=std-env-cases ;;
        std-fs-*) drv=std-fs-cases ;;
        std-path-case-tables-*) drv=std-path-case-tables-cases ;;
        std-path-short-names-*) drv=path-relative-cases ;;
        *) drv=std-path-cases ;;
    esac
    # The Windows fixtures hold what wp1 saw: each-function's drive results are literal C: (run with $work on C:; on another drive
    # std-path-cases.c trades that drive's letter with C in its arguments and results, so the rows read as on C:), short-names
    # needs C:\Program Files as PROGRA~1 (8.3 names on) and no NOPE~1, and case-tables matches the runtime's `_WIN32` tables as
    # .NET 10.0.404 generated them.
    case $name in
        *-extended-path-*|std-path-short-names-*) [ $os = windows ] || { skip "$drv.c $name" "Windows only"; continue; } ;;
        std-env-invalid-utf8-*) [ $os != windows ] || { skip "$drv.c $name" "POSIX only"; continue; } ;;
    esac
    if [ ! -f "$fx.in" ] || [ ! -f "$fx.expected" ]; then
        if [ $os = macos ] || [ $os = windows ]; then bad "$drv.c $name" "no fixture $fx.{in,expected}"; else skip "$drv.c $name" "no $os export"; fi
        continue
    fi
    if [ ! -f "$work/$drv.exe" ]; then
        if [ $drv = std-path-case-tables-cases ]; then build $drv "$work/none.c"; else build $drv; fi ||
            { bad "$drv.c $name" "build failed: $(cat "$work/$drv.build")"; continue; }
    fi
    if [ $drv = std-path-cases ]; then cd "$pathcwd" || exit 2; "$work/$drv.exe" --unmask <"$fx.expected" | tr -d '\r' >"$work/$name.want"
    else cp "$fx.expected" "$work/$name.want"; fi
    run=()
    [ $os != windows ] || run=(env -u _)
    "${run[@]}" "$work/$drv.exe" "$(pwd -P)/$name.root" <"$fx.in" 2>"$work/$name.err" | tr -d '\r' >"$work/$name.out"
    rc=${PIPESTATUS[0]}
    cd "$work" || exit 2
    if [ $os = windows ] && [ $rc -eq 3 ] && grep -q '^skip: ' "$work/$name.err"; then
        skip "$drv.c $name" "$(sed -n 's/^skip: //p' "$work/$name.err" | head -n 1 | tr -d '\r')"
        continue
    fi
    panic=$(sed -n 's/^panic \([0-9a-f]*\)$/\1/p' "$work/$name.want")
    if [ -n "$panic" ]; then
        got=$(head -n 1 "$work/$name.err" | tr -d '\r')
        if [ $rc -ne 0 ] && [ ! -s "$work/$name.out" ] && [ "$(hex "$got")" = "$(hex 'panic: ')$panic" ]; then ok "$drv.c $name"
        else bad "$drv.c $name" "exit $rc, want the panic of $fx.expected, got stderr: $(echo "$got" | cut -c1-80)"; fi
    elif [ $rc -eq 0 ] && cmp -s "$work/$name.out" "$work/$name.want"; then ok "$drv.c $name"
    elif [ $rc -ne 0 ] && [ -s "$work/$name.err" ]; then bad "$drv.c $name" "exit $rc: $(head -n 1 "$work/$name.err" | tr -d '\r' | cut -c1-200)"
    else
        line=$(cmp "$work/$name.out" "$work/$name.want" 2>&1 | sed -n 's/.*line \([0-9]*\).*/\1/p')
        if [ -n "$line" ]; then
            bad "$drv.c $name" "exit $rc, $name.expected line $line: want $(sed -n "${line}p" "$work/$name.want" | cut -c1-80), got $(sed -n "${line}p" "$work/$name.out" | cut -c1-80)"
        else bad "$drv.c $name" "exit $rc, output differs from $fx.expected in length: $(head -c 200 "$work/$name.err")"; fi
    fi
done

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
check sort-wide "size 104, sorted 1, stable 1, payload intact 1
"

check io-read-some 'stdout: "reply/#"
short: err 0 got 3 "hel"
rest: err 0 got 2 "lo"
more: err 0 got 3 "xyz"
end: err 0 got 0 ""
closed: failed 1 got -1
'

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

# io-read-presize.c: a 1.5 MiB file is read into one buffer of its size (spec 019 T44a, golden-bound on macOS).
if build io-read-presize; then
    "$work/io-read-presize.exe" "$work/io/presize.bin" >"$work/irp.out" 2>"$work/irp.err"
    rc=$?
    out=$(tr -d '\r' <"$work/irp.out")
    if [ $rc -ne 0 ]; then bad io-read-presize.c "exit $rc"
    elif [ "$out" = "file 0 resizes 1 same 1" ]; then ok io-read-presize.c
    else bad io-read-presize.c "unexpected output: $out"; fi
else bad io-read-presize.c "build failed: $(cat "$work/io-read-presize.build")"; fi

# fs-size.c: the size of a 12345-byte file, and notFound (code 1) for a missing path.
if build fs-size; then
    "$work/fs-size.exe" "$work/io/size.bin" >"$work/fsz.out" 2>"$work/fsz.err"
    rc=$?
    out=$(tr -d '\r' <"$work/fsz.out")
    want='file 0 size 12345
missing 1 size -1'
    if [ $rc -ne 0 ]; then bad fs-size.c "exit $rc"
    elif [ "$out" = "$want" ]; then ok fs-size.c
    else bad fs-size.c "unexpected output: $out"; fi
else bad fs-size.c "build failed: $(cat "$work/fs-size.build")"; fi

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
