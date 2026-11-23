#!/usr/bin/env bash
# The corpus-wide theories of CoverageTests.cs, MutantSchemataTests.cs, OwnershipCheckerTests.cs and the emitted-C half of
# SelfhostDriverT8Tests over the `run` cases, through the self-hosted driver $BAYAN_EXE alone (spec 019 T30h item 2 and T30d, the
# nightly tier; laws-nightly.yml runs it, scripts/test.sh does not).
#   BAYAN_EXE=<driver> bash scripts/ci/nightly-modes.sh [--mode coverage|mutate|ownership|libc|bound]... [--only TEXT] [--limit N]
#                                                       [--jobs N] [--cases DIR]
# The cases are those of RunTests (`*.byn` at the top of DIR, default tests/cases/run, and `<dir>/main.byn`), ordinal order; --only
# keeps the names holding TEXT, --limit the first N of each mode. A flat case is built from a copy alone in a directory, as
# golden.byn does, since the driver compiles every file of a file's directory; a `*.test.byn` case is a one-module package.
#   mutate     MutantZeroIsThePlainProgram: `build --schemata-files <every file of the case>`, run with BAYAN_MUTANT unset, `0` and
#              `x1` in an empty work directory with the case's .args and .stdin, against its .stdout, .stderr and .exitcode (a case
#              whose `// os:` line names the other OS is skipped). MutantZeroIsThePlainTestBinary: each test (`--test i`) of the
#              `test --mutate --run true` binary with BAYAN_MUTANT unset, `0` and `x1` against the plain `test` binary.
#   coverage   CoverageBuildIsThePlainProgram: `build --coverage`, run with BAYAN_COVERAGE unset and set (to a prefix in the
#              case's scratch directory) as mutate runs its build, against the same expected files; the set run must leave a
#              `cov.<pid>` counter file, a panic's too. CoverageBuildIsThePlainTestBinary: each test of the `test --coverage`
#              binary with BAYAN_COVERAGE unset and set against the plain one.
#   ownership  SafeAndFastCHaveNoChecker: the C of `build --emit-c` (a test case: `out/<mode>/<host>/c/main.c` of `test`) in
#              `safe` and `fast` holds no `byn_own`.
#   libc       EmittedCHasOnlyInventoryExtensionTokens and EmittedCDirectLibcCallsAreListed: the C of `build --emit-c` in `debug`,
#              `safe` and `fast` (a test case: `out/safe/<host>/c/main.c` of `test`, the C# default mode) passes
#              `scripts/ci/libc-inventory-check.sh --emitted`, but for its "no emitted unit calls it" lines, which hold only for the
#              whole corpus: with no --only and no --limit, one more check over every unit reports them as `libc corpus`. As the
#              C# test, the top-level `*.byn` alone; the `<dir>/main.byn` cases are counted as left out.
#   bound      the golden runner bound of docs/memory-leaks.md rule 8 (src/driver/golden.byn, "a run over tests/cases keeps the
#              runner and each worker under 15 MB ...") over the full tests/cases tree: BAYAN_GOLDEN_BOUND_SHARD and
#              BAYAN_TEST_SHARD unset, BAYAN_TEST_TIMEOUT_MS 5 hours (a hosted runner took 889 s for one twelfth of the tree at
#              --jobs 3, so about 3 hours). The release memory gate samples shard 1/12 only (Decision 2026-11-20, Fable for the
#              owner). Not a default mode and not per case (--only, --limit and --cases do not apply): laws-nightly.yml runs it in
#              a job of its own. Its output goes to tmp/nightly-modes/bound.log.
# Prints one line per failing case, then the counts of each mode. Everything goes under tmp/nightly-modes/. Each run of a built
# program or test binary is killed after 120 s times BAYAN_TEST_TIME_SCALE (CoverageTests.cs:49 and MutantSchemataTests.cs:72
# `TestTime.Scale(120_000)`), each driver run after BAYAN_CC_TIMEOUT_S seconds, default 600 (Toolchain.cs:146 `CompileTimeout`);
# a killed run fails its case as `<program> timed out after N s`. The bound mode has its own BAYAN_TEST_TIMEOUT_MS.
# Exit 0 when no case failed, 1 when one did, 2 on a usage error. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2

usage() { echo "nightly-modes.sh: $1 (--mode coverage|mutate|ownership|libc|bound, --only TEXT, --limit N, --jobs N, --cases DIR)" >&2; exit 2; }
modes=(); only=""; limit=0; jobs=1; cases=tests/cases/run
while [ $# -gt 0 ]; do
  case $1 in
    (--mode) [ $# -ge 2 ] || usage "--mode expects a mode"
      case $2 in (coverage|mutate|ownership|libc|bound) modes+=("$2") ;; (*) usage "unknown mode '$2'" ;; esac; shift 2 ;;
    (--only) [ $# -ge 2 ] || usage "--only expects text"; only=$2; shift 2 ;;
    (--limit|--jobs) [ $# -ge 2 ] || usage "$1 expects a number"
      case $2 in (''|*[!0-9]*) usage "$1 expects a number, not '$2'" ;; esac
      if [ "$1" = --limit ]; then limit=$2; else jobs=$2; fi; shift 2 ;;
    (--cases) [ $# -ge 2 ] && [ -d "$2" ] || usage "--cases expects a directory"; cases=$2; shift 2 ;;
    (*) usage "unexpected argument '$1'" ;;
  esac
done
[ "$jobs" -gt 0 ] || usage "--jobs expects a number above 0"
[ ${#modes[@]} -gt 0 ] || modes=(coverage mutate ownership libc)
[ -n "${BAYAN_EXE:-}" ] && [ -x "$BAYAN_EXE" ] || { echo "nightly-modes.sh: BAYAN_EXE names no driver ('${BAYAN_EXE:-}')" >&2; exit 2; }
exe=$(cd "$(dirname "$BAYAN_EXE")" && pwd)/$(basename "$BAYAN_EXE")
cases=$(cd "$cases" && pwd)
kind=$(basename "$cases")
x=""; other="// os: windows"
case "$(uname -s)" in (MINGW*|MSYS*|CYGWIN*) x=.exe; other="// os: unix" ;; esac
out="$root/tmp/nightly-modes"
rm -rf "$out"; mkdir -p "$out/result" || exit 2
# the time limits in seconds: a program run (120 s scaled, rounded up; TestTime.cs: 1 when unset or not positive), a driver run
run_s=$(awk -v f="${BAYAN_TEST_TIME_SCALE:-1}" 'BEGIN { f += 0; if (f <= 0) f = 1; s = 120 * f; c = int(s); if (c < s) c++; print c }')
case ${BAYAN_CC_TIMEOUT_S:-} in (''|*[!0-9]*|0) driver_s=600 ;; (*) driver_s=$BAYAN_CC_TIMEOUT_S ;; esac

# waits for the process $1, killed after $2 s (no GNU timeout on macOS): a watchdog polls each second and, at the limit,
# writes "$4 timed out after $2 s" to $3 and kills it; returns its status
watch() {
  local pid=$1 s=$2 mark=$3 what=$4 w code
  ( i=0
    while [ $i -lt "$s" ]; do sleep 1; kill -0 "$pid" 2>/dev/null || exit 0; i=$((i + 1)); done
    echo "$what timed out after $s s" > "$mark"; kill -KILL "$pid" ) > /dev/null 2>&1 &
  w=$!
  wait "$pid"; code=$?
  kill "$w" 2>/dev/null; wait "$w" 2>/dev/null
  return $code
}

# runs $1 in the fresh work directory $2 with BAYAN_MUTANT $3 and BAYAN_COVERAGE $4 (`-` unset), the stdin file $5 and the
# argument file $6 (each skipped when "" or absent), then the arguments after them; leaves $2.o, $2.e (CR dropped) and $2.c,
# and $2.timeout when it was killed at run_s
run() {
  local bin=$1 work=$2 mut=$3 cov=$4 stdin=$5 argf=$6 l code; shift 6
  local a=("$@")
  rm -rf "$work"; mkdir -p "$work"
  if [ -n "$argf" ] && [ -f "$argf" ]; then
    while IFS= read -r l || [ -n "$l" ]; do a+=("${l%$'\r'}"); done < "$argf"
  fi
  [ -n "$stdin" ] && [ -f "$stdin" ] || stdin=/dev/null
  ( unset BAYAN_MUTANT BAYAN_COVERAGE
    [ "$mut" = - ] || export BAYAN_MUTANT="$mut"
    [ "$cov" = - ] || export BAYAN_COVERAGE="$cov"
    cd "$work" && exec "$bin" ${a[@]+"${a[@]}"} < "$stdin" > "$work.out" 2> "$work.err" ) &
  watch $! "$run_s" "$work.timeout" "$(basename "$bin")"; code=$?
  # PanicExit.Portable: the Windows fail-fast status is the 134 of an abort
  case $code in (3221226505) code=134 ;; esac
  tr -d '\r' < "$work.out" > "$work.o"; tr -d '\r' < "$work.err" > "$work.e"; echo "$code" > "$work.c"
}

# the driver with `$@` in the directory $1, BAYAN_MUTANT and BAYAN_COVERAGE unset; stdout to $2.out, stderr to $2.err, and
# $2.timeout when it was killed at driver_s
driver() {
  local dir=$1 log=$2; shift 2
  ( unset BAYAN_MUTANT BAYAN_COVERAGE; cd "$dir" && exec "$exe" "$@" > "$log.out" 2> "$log.err" ) &
  watch $! "$driver_s" "$log.timeout" "the driver's \`$1\`"
}

# the first line of a driver log $1 (.out then .err), for a failure message
said() { cat "$1.out" "$1.err" 2>/dev/null | grep -v '^[[:space:]]*$' | head -1 | cut -c1-200; }

mode_of() { local m; m=$(head -1 "$1" | tr -d '\r'); m=${m#// mode: }; case $m in (debug|fast) echo "$m" ;; (*) echo safe ;; esac; }

# the one-module package $1 holding the test case $2, built by `test --mode $3` and the flags after it; its log is $1.log
package() {
  local p=$1 src=$2 m=$3; shift 3
  mkdir -p "$p/src/app" && cp "$src" "$p/src/app/" && printf 'Package { name: "local/nm", version: "0.1.0" }\n' > "$p/package.byn"
  driver "$p" "$p.log" test --mode "$m" "$@"
}

# the file $3 under out/$2/<host>/ of the package $1
built() { local f; for f in "$1"/out/"$2"/*/"$3"; do [ -f "$f" ] && { echo "$f"; return 0; }; done; return 1; }

# each test of the plain binary $2 against the binary $3 under each `MUT,COV` of $4..; prints the first difference
tests_differ() {
  local d=$1 plain=$2 other=$3 n=$4 v i; shift 4
  for ((i = 0; i < n; i++)); do
    run "$plain" "$d/w" - - "" "" --test "$i"
    for v in "$@"; do
      rm -f "$d/counters/cov".*
      run "$other" "$d/v" "${v%%,*}" "${v#*,}" "" "" --test "$i"
      if ! cmp -s "$d/w.o" "$d/v.o"; then echo "test $i, $(label "$v"): stdout differs from the plain test binary"; return 0; fi
      if ! cmp -s "$d/w.e" "$d/v.e"; then echo "test $i, $(label "$v"): stderr differs from the plain test binary"; return 0; fi
      if ! cmp -s "$d/w.c" "$d/v.c"; then
        echo "test $i, $(label "$v"): exit code $(cat "$d/v.c"), the plain test binary's $(cat "$d/w.c")"; return 0
      fi
    done
  done
}
label() {
  case $1 in
    (-,-) echo "BAYAN_MUTANT unset, BAYAN_COVERAGE unset" ;;
    (*,-) echo "BAYAN_MUTANT=${1%%,*}" ;;
    (*) echo "BAYAN_COVERAGE set" ;;
  esac
}

# the test binary half of mutate and coverage for the test case $2 in the scratch directory $1: the failure, or nothing
test_binary() {
  local d=$1 src=$2 mode=$3 m plain other n
  m=$(mode_of "$src")
  package "$d/plain" "$src" "$m"
  plain=$(built "$d/plain" "$m" "nm-test$x") || { echo "the plain test binary did not build: $(said "$d/plain.log")"; return; }
  n=$(sed -n '1s/^running \([0-9][0-9]*\) .*/\1/p' "$d/plain.log.out")
  [ "${n:-0}" -gt 0 ] || { echo "no tests: $(said "$d/plain.log")"; return; }
  mkdir -p "$d/counters"
  if [ "$mode" = mutate ]; then
    package "$d/mutate" "$src" "$m" --mutate --run true
    other=$(built "$d/mutate" "$m" "nm-mutate$x") || { echo "the --mutate test binary did not build: $(said "$d/mutate.log")"; return; }
    tests_differ "$d" "$plain" "$other" "$n" -,- 0,- x1,-
  else
    package "$d/coverage" "$src" "$m" --coverage
    other=$(built "$d/coverage" "$m" "nm-test$x") || { echo "the --coverage test binary did not build: $(said "$d/coverage.log")"; return; }
    tests_differ "$d" "$plain" "$other" "$n" -,- "-,$d/counters/cov"
  fi
}

# the program file the driver builds for the case $3 at $2: a `<dir>/main.byn` in place, else a copy alone in $1/src/<kind>/
program() {
  if [ "$(basename "$2")" = main.byn ] && [ "$3" != main.byn ]; then echo "$2"; return 0; fi
  mkdir -p "$1/src/$kind" && cp "$2" "$1/src/$kind/" && echo "$1/src/$kind/$(basename "$2")"
}

# the program half of mutate or coverage ($4) for the case $2 in the scratch directory $1: the failure, or nothing. mutate runs the
# `--schemata-files` build with BAYAN_MUTANT unset, `0` and `x1`; coverage the `--coverage` build with BAYAN_COVERAGE unset and
# set, which must write a counter file
program_case() {
  local d=$1 src=$2 name=$3 mode=$4 m files v base want got s at
  local flags=(--coverage) runs=(- "$d/counters/cov")
  m=$(mode_of "$src")
  src=$(program "$d" "$src" "$name") || { echo "cannot copy to $d/src"; return; }
  if [ "$mode" = mutate ]; then
    files=$(find "$(dirname "$src")" -name '*.byn' | LC_ALL=C sort | paste -sd, -)
    flags=(--schemata-files "$files"); runs=(- 0 x1)
  fi
  if ! driver "$root" "$d/build" build --mode "$m" "${flags[@]}" -o "$d/prog$x" "$src"; then
    echo "the $([ "$mode" = mutate ] && echo schemata || echo coverage) build failed: $(said "$d/build")"; return
  fi
  base="$cases/${name%.byn}"
  mkdir -p "$d/counters"
  for v in "${runs[@]}"; do
    if [ "$mode" = mutate ]; then
      at="BAYAN_MUTANT=${v/-/unset}"; run "$d/prog$x" "$d/w" "$v" - "$base.stdin" "$base.args"
    else
      at="BAYAN_COVERAGE $([ "$v" = - ] && echo unset || echo set)"; run "$d/prog$x" "$d/w" - "$v" "$base.stdin" "$base.args"
    fi
    for s in stdout:o stderr:e; do
      if [ -f "$base.${s%:*}" ]; then tr -d '\r' < "$base.${s%:*}" > "$d/want"; else : > "$d/want"; fi
      cmp -s "$d/want" "$d/w.${s#*:}" || { echo "$at: ${s%:*} differs from $kind/${name%.byn}.${s%:*}"; return; }
    done
    want=""; [ ! -f "$base.exitcode" ] || want=$(tr -d ' \t\r\n' < "$base.exitcode")
    got=$(cat "$d/w.c"); [ "$got" != 0 ] || got=""
    [ "$want" = "$got" ] || { echo "$at: exit code '${got}', $kind/${name%.byn}.exitcode says '${want}'"; return; }
  done
  # a panic writes them too (bayan-rt.c `byn_cov_flush`)
  if [ "$mode" = coverage ] && ! ls "$d/counters" | grep -q '^cov\.'; then
    echo "BAYAN_COVERAGE set: no counter file cov.<pid>"
  fi
}

# ownership for the case $2 in the scratch directory $1: the failure, or nothing
ownership() {
  local d=$1 src=$2 m c
  if [ "${src%.test.byn}" = "$src" ]; then src=$(program "$d" "$src" "$3") || { echo "cannot copy to $d/src"; return; }; fi
  for m in safe fast; do
    if [ "${src%.test.byn}" != "$src" ]; then
      package "$d/$m" "$src" "$m"
      c=$(built "$d/$m" "$m" c/main.c) || { echo "--mode $m: \`test\` left no C: $(said "$d/$m.log")"; return; }
    else
      c="$d/$m.c"
      if ! driver "$root" "$d/$m" build --emit-c --mode "$m" "$src"; then echo "--mode $m: build --emit-c failed: $(said "$d/$m")"; return; fi
      cp "$d/$m.out" "$c"
    fi
    if grep -q byn_own "$c"; then echo "--mode $m: the C holds byn_own"; return; fi
  done
}

# libc for the case $2 in the scratch directory $1: its units go to $1/c/, then the failure, or nothing
libc() {
  local d=$1 src=$2 m c r
  mkdir -p "$d/c"
  if [ "${src%.test.byn}" != "$src" ]; then
    package "$d/test" "$src" safe
    c=$(built "$d/test" safe c/main.c) || { echo "\`test\` left no C: $(said "$d/test.log")"; return; }
    cp "$c" "$d/c/test.c"
  else
    src=$(program "$d" "$src" "$3") || { echo "cannot copy to $d/src"; return; }
    for m in debug safe fast; do
      if ! driver "$root" "$d/$m" build --emit-c --mode "$m" "$src"; then echo "--mode $m: build --emit-c failed: $(said "$d/$m")"; return; fi
      cp "$d/$m.out" "$d/c/$m.c"
    done
  fi
  r=$(bash "$root/scripts/ci/libc-inventory-check.sh" --emitted "$d/c" "$root" 2>&1 | sed 's/^libc-inventory-check: //' \
    | grep -v -e '^ok$' -e '^listed in 011-c-inventory.md but no emitted unit calls it: ' | paste -sd ';' - | sed 's/;/; /g')
  [ -z "$r" ] || echo "$r"
}

# the cases: the top-level *.byn, then each <dir>/main.byn, in ordinal order
names=$( (cd "$cases" && { ls | grep '\.byn$' | while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done
  for f in */main.byn; do [ -f "$f" ] && echo "$f"; done; }) | LC_ALL=C sort)

# the units, `<mode> <name>`; cases a mode leaves out are counted in left_<mode>
: > "$out/units"
for mode in "${modes[@]}"; do
  [ "$mode" != bound ] || continue
  taken=0; left=0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    case $name in (*"$only"*) ;; (*) continue ;; esac
    case $mode/$name in (libc/*/*) left=$((left + 1)); continue ;; esac
    [ "$limit" = 0 ] || [ "$taken" -lt "$limit" ] || continue
    taken=$((taken + 1)); echo "$mode $name" >> "$out/units"
  done <<EOF
$names
EOF
  eval "left_$mode=$left"
done

# worker $1 of $jobs: the units whose index is $1 modulo $jobs; result/<index> holds `ok`, `skip` or `fail <message>`
worker() {
  local k=$1 i=0 mode name d src r t
  while IFS=' ' read -r mode name; do
    if [ $((i % jobs)) = "$k" ]; then
      src="$cases/$name"; d="$out/$mode/$(echo "${name%.byn}" | tr / _)"; mkdir -p "$d"
      if [ "$mode" = ownership ]; then r=$(ownership "$d" "$src" "$name")
      elif [ "$mode" = libc ]; then r=$(libc "$d" "$src" "$name")
      elif [ "${name%.test.byn}" != "$name" ]; then r=$(test_binary "$d" "$src" "$mode")
      elif head -2 "$src" | tr -d '\r' | grep -qxF "$other"; then r=skip
      else r=$(program_case "$d" "$src" "$name" "$mode")
      fi
      # a run killed at its time limit fails the case, whatever its output compared as
      t=$(find "$d" -name '*.timeout' -exec cat {} + 2>/dev/null | head -1); [ -z "$t" ] || r=$t
      case $r in ('') echo ok ;; (skip) echo skip ;; (*) echo "fail $r" ;; esac > "$out/result/$i"
    fi
    i=$((i + 1))
  done < "$out/units"
}
k=0; while [ $k -lt "$jobs" ]; do worker $k & k=$((k + 1)); done
wait

# bound: the block passed when the driver exited 0 and reported 1 passed and nothing pending; result/bound holds `ok` or `fail <message>`
title='a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory'
case " ${modes[*]} " in
  (*" bound "*)
    ( unset BAYAN_GOLDEN_BOUND_SHARD BAYAN_TEST_SHARD BAYAN_MUTANT BAYAN_COVERAGE
      cd "$root" && BAYAN_TEST_TIMEOUT_MS=18000000 exec "$exe" test --package src src/driver --only "$title" > "$out/bound.log" 2>&1 )
    code=$?
    if grep -qF '(pending)' "$out/bound.log"; then r="fail the block reported pending"
    elif [ "$code" != 0 ] || ! grep -qE '(^|[^0-9])1 passed' "$out/bound.log"; then
      r="fail exit $code: $(grep -v '│' "$out/bound.log" | grep -v '^[[:space:]]*$' | tail -6 | paste -sd ';' - | cut -c1-400)"
    else r=ok
    fi
    echo "$r" > "$out/result/bound"
    grep -E '^ *(full tree|shard [0-9]+/[0-9]+): runner ' "$out/bound.log" | sed 's/^ */nightly-modes: bound: /' ;;
esac

summary=""; failed=0; i=0
for mode in "${modes[@]}"; do eval "ok_$mode=0 fail_$mode=0 skip_$mode=0"; done
while IFS=' ' read -r mode name; do
  r=$(cat "$out/result/$i" 2>/dev/null || echo "fail no result")
  case $r in
    (ok) eval "ok_$mode=\$((ok_$mode + 1))" ;;
    (skip) eval "skip_$mode=\$((skip_$mode + 1))" ;;
    (*) echo "nightly-modes: FAIL $mode $kind/$name: ${r#fail }"; eval "fail_$mode=\$((fail_$mode + 1))"; failed=1 ;;
  esac
  i=$((i + 1))
done < "$out/units"
# libc corpus: the direct library calls of every unit together are the listed ones, no fewer (a full run alone)
if [ -z "$only" ] && [ "$limit" = 0 ] && grep -q '^libc ' "$out/units"; then
  mkdir -p "$out/libc-all"
  for c in "$out"/libc/*/c/*.c; do [ -f "$c" ] && cp "$c" "$out/libc-all/$(basename "$(dirname "$(dirname "$c")")")-$(basename "$c")"; done
  r=$(bash "$root/scripts/ci/libc-inventory-check.sh" --emitted "$out/libc-all" "$root" 2>&1 \
    | sed -n 's/^libc-inventory-check: \(listed in 011-c-inventory.md but no emitted unit calls it: .*\)/\1/p' | paste -sd ';' - | sed 's/;/; /g')
  [ -z "$r" ] || { echo "nightly-modes: FAIL libc corpus: $r"; failed=1; }
fi
for mode in "${modes[@]}"; do
  if [ "$mode" = bound ]; then
    r=$(cat "$out/result/bound")
    if [ "$r" = ok ]; then part="bound passed"; else echo "nightly-modes: FAIL bound: ${r#fail }"; part="bound failed"; failed=1; fi
    summary="${summary:+$summary; }$part"; continue
  fi
  eval "o=\$ok_$mode f=\$fail_$mode s=\$skip_$mode l=\$left_$mode"
  part="$mode $o ok, $f failed, $s skipped (os)"
  [ "$mode" != libc ] || part="$part, $l left out (<dir>/main.byn: not in the C# selection)"
  summary="${summary:+$summary; }$part"
done
echo "nightly-modes: $summary"
exit $failed
