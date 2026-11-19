#!/usr/bin/env bash
# Tests scripts/ci/nightly-modes.sh on a copy of three `run` cases (two programs and a test case), at most 3 cases per mode: the
# copy passes in every mode; an altered .stdout of the copy fails mutate naming the case; a stand-in driver whose `--emit-c` adds
# `byn_own` fails ownership naming the case; an unknown mode is a usage error.
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
mkdir -p "$tmp/repo/scripts/ci" "$tmp/cases/run"; cp "$root/scripts/ci/nightly-modes.sh" "$tmp/repo/scripts/ci/"
cp "$root"/tests/cases/run/arithmetic.* "$root"/tests/cases/run/assert-and-right.* "$root"/tests/cases/run/assert-fails.test.* "$tmp/cases/run/"
run() { BAYAN_EXE=$1 bash "$tmp/repo/scripts/ci/nightly-modes.sh" --cases "$tmp/cases/run" --limit 3 "${@:2}" > "$tmp/out" 2>&1 && echo pass || echo fail; }

[ "$(run "$bayan")" = pass ] || fail "the unchanged cases failed" "$(cat "$tmp/out")"
grep -qx 'nightly-modes: coverage 1 ok, 0 failed, 0 skipped (os), 2 left out (programs: no bayan build --coverage); mutate 3 ok, 0 failed, 0 skipped (os); ownership 3 ok, 0 failed, 0 skipped (os)' "$tmp/out" \
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

[ "$(run "$bayan" --mode bad)" = fail ] && grep -q "unknown mode 'bad'" "$tmp/out" || fail "an unknown mode was not a usage error" "$(cat "$tmp/out")"
echo "nightly-modes.test: ok"
