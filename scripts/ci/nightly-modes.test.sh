#!/usr/bin/env bash
# Tests scripts/ci/nightly-modes.sh on a copy of three `run` cases (two programs and a test case), at most 3 cases per mode: the
# copy passes in every mode; an altered .stdout of the copy fails mutate naming the case; a stand-in driver whose `--emit-c` adds
# `byn_own` fails ownership naming the case; a stand-in driver whose `--emit-c` adds a call to an unlisted function fails libc
# naming the case; libc with no --limit runs the corpus check, which the three cases alone fail; an unknown mode is a usage error.
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
grep -qx 'nightly-modes: coverage 1 ok, 0 failed, 0 skipped (os), 2 left out (programs: no bayan build --coverage); mutate 3 ok, 0 failed, 0 skipped (os); ownership 3 ok, 0 failed, 0 skipped (os); libc 3 ok, 0 failed, 0 skipped (os), 0 left out (<dir>/main.byn: not in the C# selection)' "$tmp/out" \
  || fail "the counts line is not the expected one" "$(cat "$tmp/out")"

# an altered case copy: the mutant build's stdout no longer matches
echo changed >> "$tmp/cases/run/arithmetic.stdout"
[ "$(run "$bayan" --mode mutate)" = fail ] || fail "an altered .stdout passed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: FAIL mutate run/arithmetic.byn: BAYAN_MUTANT=unset: stdout differs from run/arithmetic.stdout' "$tmp/out" \
  || fail "the altered case was not named" "$(cat "$tmp/out")"
grep -q '^nightly-modes: mutate 2 ok, 1 failed' "$tmp/out" || fail "the counts did not show the failure" "$(cat "$tmp/out")"
cp "$root/tests/cases/run/arithmetic.stdout" "$tmp/cases/run/"

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

[ "$(run "$bayan" --mode bad)" = fail ] && grep -q "unknown mode 'bad'" "$tmp/out" || fail "an unknown mode was not a usage error" "$(cat "$tmp/out")"
echo "nightly-modes.test: ok"
