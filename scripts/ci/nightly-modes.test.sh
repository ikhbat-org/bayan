#!/usr/bin/env bash
# Tests scripts/ci/nightly-modes.sh on a copy of three `run` cases (two programs and a test case), at most 3 cases per mode: the
# copy passes in every mode; an altered .stdout of the copy fails mutate and coverage naming the case; a stand-in driver that
# drops `build --coverage` fails coverage on the missing counter file, naming the case; a stand-in driver whose `--emit-c` adds
# `byn_own` fails ownership naming the case; a stand-in driver whose `--emit-c` adds a call to an unlisted function fails libc
# naming the case; a hanging program and a hanging driver are killed at their limits, failing the case as timed out; libc with no --limit runs the corpus check, which the three cases alone fail; bound runs the golden runner
# bound block through a stand-in driver over the full tree with a 5 hour timeout and fails on a failed or pending block; an
# unknown mode is a usage error.
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/nightly-modes-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$tmp/bayan"
  (cd "$root" && cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan") \
    || fail "cannot build bootstrap/bayan.c"
fi

# a scratch repo holding the script, so its tmp/nightly-modes/ is under $tmp
mkdir -p "$tmp/repo/scripts/ci" "$tmp/repo/docs/specs/011-self-hosted-emitter" "$tmp/cases/run"
cp "$root/scripts/ci/nightly-modes.sh" "$root/scripts/ci/libc-inventory-check.sh" "$tmp/repo/scripts/ci/"
cp "$root/docs/specs/011-self-hosted-emitter/011-c-inventory.md" "$tmp/repo/docs/specs/011-self-hosted-emitter/"
cp "$root"/tests/cases/run/arithmetic.* "$root"/tests/cases/run/assert-and-right.* "$root"/tests/cases/run/assert-fails.test.* "$tmp/cases/run/"
run() { BAYAN_EXE=$1 bash "$tmp/repo/scripts/ci/nightly-modes.sh" --cases "$tmp/cases/run" --limit 3 "${@:2}" > "$tmp/out" 2>&1 && echo pass || echo fail; }

[ "$(run "$bayan")" = pass ] || fail "the unchanged cases failed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: coverage 3 ok, 0 failed, 0 skipped (os); mutate 3 ok, 0 failed, 0 skipped (os); ownership 3 ok, 0 failed, 0 skipped (os); libc 3 ok, 0 failed, 0 skipped (os), 0 left out (<dir>/main.byn: not in the C# selection)' "$tmp/out" \
  || fail "the counts line is not the expected one" "$(cat "$tmp/out")"

# an altered case copy: the mutant build's stdout no longer matches
echo changed >> "$tmp/cases/run/arithmetic.stdout"
[ "$(run "$bayan" --mode mutate)" = fail ] || fail "an altered .stdout passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL mutate run/arithmetic.byn: BAYAN_MUTANT=unset: stdout differs from run/arithmetic.stdout' "$tmp/out" \
  || fail "the altered case was not named" "$(cat "$tmp/out")"
grep -q '^nightly-modes: mutate 2 ok, 1 failed' "$tmp/out" || fail "the counts did not show the failure" "$(cat "$tmp/out")"
[ "$(run "$bayan" --mode coverage)" = fail ] || fail "an altered .stdout passed coverage" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL coverage run/arithmetic.byn: BAYAN_COVERAGE unset: stdout differs from run/arithmetic.stdout' "$tmp/out" \
  || fail "the altered case was not named under coverage" "$(cat "$tmp/out")"
grep -q '^nightly-modes: coverage 2 ok, 1 failed' "$tmp/out" || fail "the coverage counts did not show the failure" "$(cat "$tmp/out")"
cp "$root/tests/cases/run/arithmetic.stdout" "$tmp/cases/run/"

# a stand-in driver: the real one, with `build --coverage` built as a plain build, so its program writes no counter file
printf '#!/usr/bin/env bash\nif [ "${1:-}" = build ]; then a=(); for x in "$@"; do [ "$x" = --coverage ] || a+=("$x"); done; set -- "${a[@]}"; fi\nexec "%s" "$@"\n' "$bayan" > "$tmp/stand-in"
chmod +x "$tmp/stand-in"
[ "$(run "$tmp/stand-in" --mode coverage --only arithmetic)" = fail ] || fail "a coverage build with no counters passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL coverage run/arithmetic.byn: BAYAN_COVERAGE set: no counter file cov.<pid>' "$tmp/out" \
  || fail "the case with no counter file was not named" "$(cat "$tmp/out")"

# a stand-in driver: the real one, with `byn_own` added to what `build --emit-c` prints
printf '#!/usr/bin/env bash\n"%s" "$@"; s=$?\n[ "${1:-} ${2:-}" != "build --emit-c" ] || echo "void byn_own_check(void);"\nexit $s\n' "$bayan" > "$tmp/stand-in"
chmod +x "$tmp/stand-in"
[ "$(run "$tmp/stand-in" --mode ownership --only arithmetic)" = fail ] || fail "byn_own in the C passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL ownership run/arithmetic.byn: --mode safe: the C holds byn_own' "$tmp/out" \
  || fail "the case whose C holds byn_own was not named" "$(cat "$tmp/out")"

# a stand-in driver: the real one, with a call to a function 011-c-inventory.md does not list added to `build --emit-c`
printf '#!/usr/bin/env bash\n"%s" "$@"; s=$?\n[ "${1:-} ${2:-}" != "build --emit-c" ] || printf "    zzz_seeded(0);\\n"\nexit $s\n' "$bayan" > "$tmp/stand-in"
[ "$(run "$tmp/stand-in" --mode libc)" = fail ] || fail "an unlisted call in the C passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL libc run/arithmetic.byn: direct libc call in emitted C not listed in 011-c-inventory.md: zzz_seeded' "$tmp/out" \
  || fail "the case whose C calls zzz_seeded was not named" "$(cat "$tmp/out")"
grep -q '^nightly-modes: libc 1 ok, 2 failed' "$tmp/out" || fail "the counts did not show the libc failures" "$(cat "$tmp/out")"

# no --limit: the corpus check runs, and three cases do not call every listed function
BAYAN_EXE=$bayan bash "$tmp/repo/scripts/ci/nightly-modes.sh" --cases "$tmp/cases/run" --mode libc > "$tmp/out" 2>&1 \
  && fail "the corpus check passed on three cases" "$(cat "$tmp/out")"
grep -q '^nightly-modes: FAIL libc corpus: listed in 011-c-inventory.md but no emitted unit calls it: ' "$tmp/out" \
  || fail "the corpus check did not run" "$(cat "$tmp/out")"
grep -q '^nightly-modes: libc 3 ok, 0 failed' "$tmp/out" || fail "a case failed the per-case check" "$(cat "$tmp/out")"

# time limits: a built program that hangs is killed at 120 s times BAYAN_TEST_TIME_SCALE, a hanging driver at BAYAN_CC_TIMEOUT_S
cat > "$tmp/stand-in" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = build ] || exit 2
[ -z "${HANG_DRIVER:-}" ] || exec sleep 30
p=""; for x in "$@"; do [ "$p" != -o ] || o=$x; p=$x; done
printf '#!/bin/sh\nexec sleep 30\n' > "$o"; chmod +x "$o"
STUB
chmod +x "$tmp/stand-in"
[ "$(BAYAN_TEST_TIME_SCALE=0.01 run "$tmp/stand-in" --mode mutate --only arithmetic)" = fail ] || fail "a hanging program passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL mutate run/arithmetic.byn: prog timed out after 2 s' "$tmp/out" \
  || fail "the case whose program hangs was not named" "$(cat "$tmp/out")"
[ "$(HANG_DRIVER=1 BAYAN_CC_TIMEOUT_S=2 run "$tmp/stand-in" --mode coverage --only arithmetic)" = fail ] || fail "a hanging driver passed" "$(cat "$tmp/out")"
grep -qx "nightly-modes: FAIL coverage run/arithmetic.byn: the driver's \`build\` timed out after 2 s" "$tmp/out" \
  || fail "the case whose driver hangs was not named" "$(cat "$tmp/out")"

# bound: a stand-in driver logs its environment and arguments and reports what BOUND_SAYS says
cat > "$tmp/stand-in" <<'STUB'
#!/usr/bin/env bash
echo "timeout=${BAYAN_TEST_TIMEOUT_MS:-} shard=${BAYAN_GOLDEN_BOUND_SHARD-unset} test-shard=${BAYAN_TEST_SHARD-unset} $*" > "$BOUND_LOG"
case $BOUND_SAYS in
  (pass) echo "  full tree: runner 9000 KB, largest worker 9100 KB"; echo "◆ 1 passed · 1s" ;;
  (fail) echo "  ✗ driver: the bound"; echo "◆ 0 passed · ✗ 1 failed · 0 pending · 1s"; exit 3 ;;
  (pending) echo "  ◆ driver: the bound (pending)"; echo "◆ 0 passed · 1 pending · 1s" ;;
esac
STUB
chmod +x "$tmp/stand-in"
bound() { BOUND_SAYS=$1 BOUND_LOG="$tmp/bound-args" BAYAN_GOLDEN_BOUND_SHARD=1/12 BAYAN_TEST_SHARD=2/3 BAYAN_EXE="$tmp/stand-in" \
  bash "$tmp/repo/scripts/ci/nightly-modes.sh" --cases "$tmp/cases/run" --mode bound > "$tmp/out" 2>&1 && echo pass || echo fail; }
[ "$(bound pass)" = pass ] || fail "a passing bound failed" "$(cat "$tmp/out")"
grep -qx 'timeout=18000000 shard=unset test-shard=unset test --package src src/driver --only a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory' "$tmp/bound-args" \
  || fail "bound did not run the block over the full tree with a 5 hour timeout" "$(cat "$tmp/bound-args")"
grep -qx 'nightly-modes: bound passed' "$tmp/out" || fail "the bound counts line is not the expected one" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: bound: full tree: runner 9000 KB, largest worker 9100 KB' "$tmp/out" || fail "the bound figures were not printed" "$(cat "$tmp/out")"
[ "$(bound fail)" = fail ] || fail "a failed bound passed" "$(cat "$tmp/out")"
grep -q '^nightly-modes: FAIL bound: exit 3: ' "$tmp/out" && grep -qx 'nightly-modes: bound failed' "$tmp/out" || fail "the failed bound was not named" "$(cat "$tmp/out")"
[ "$(bound pending)" = fail ] || fail "a pending bound passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL bound: the block reported pending' "$tmp/out" || fail "the pending bound was not named" "$(cat "$tmp/out")"

[ "$(run "$bayan" --mode bad)" = fail ] && grep -q "unknown mode 'bad'" "$tmp/out" || fail "an unknown mode was not a usage error" "$(cat "$tmp/out")"
echo "nightly-modes.test: ok"
