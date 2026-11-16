#!/usr/bin/env bash
# Tests the scratch steps of 2026-11-16-release-0-3-2.sh and 022-style-guide.sh in a fixture repo on dev (review 2026-11-16-5):
# -e alone deletes no scratch; --delete-scratch deletes a .cache/bayan/.build-<sha>-<pid> dir only when that pid has exited.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/release-0-3-2-cleanup-test"; rm -rf "$t"; mkdir -p "$t"; cd "$t"; trap 'cd "$root"; rm -rf "$t"' EXIT
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
git init -q -b dev && git config core.hooksPath /dev/null
printf 'tmp/\n.cache/\n' > .gitignore && git add . && git -c user.email=t@t -c user.name=t commit -qm base
mkdir -p tmp/cleanup-all-ignored tmp/manifesto-site-ignored .cache/bayan
(exit 0) & dead=$!; wait "$dead"
mkdir .cache/bayan/.build-abc-$$ .cache/bayan/.build-abc-"$dead"
fail() { echo "FAIL $1"; exit 1; }

r="$root/scripts/cleanup/2026-11-16-release-0-3-2.sh"
out="$(bash "$r" -e 2>&1)" || fail "-e exits 0: $out"
[ -d tmp/cleanup-all-ignored ] || fail "-e alone keeps tmp/cleanup-all-ignored"
[ -d .cache/bayan/.build-abc-"$dead" ] || fail "-e alone keeps a stale build dir"
out="$(bash "$r" -e --delete-scratch 2>&1)" || fail "-e --delete-scratch exits 0: $out"
[ ! -e tmp/cleanup-all-ignored ] || fail "--delete-scratch deletes tmp/cleanup-all-ignored"
[ ! -e .cache/bayan/.build-abc-"$dead" ] || fail "--delete-scratch deletes the build dir of an exited process"
[ -d .cache/bayan/.build-abc-$$ ] || fail "--delete-scratch keeps the build dir of a running process: $out"
grep -q "process $$ is running" <<<"$out" || fail "the kept dir is named: $out"

s="$root/scripts/cleanup/022-style-guide.sh"
out="$(bash "$s" -e 2>&1)" || fail "022 -e exits 0: $out"
[ -d tmp/manifesto-site-ignored ] || fail "022 -e alone keeps tmp/manifesto-site-ignored"
grep -q 'keep:  .*tmp/manifesto-site-ignored; pass --delete-scratch' <<<"$out" || fail "022 names the flag: $out"
out="$(bash "$s" --delete-scratch 2>&1)" || fail "022 dry run exits 0: $out"
grep -q 'would: rm -rf .*tmp/manifesto-site-ignored' <<<"$out" || fail "022 --delete-scratch would delete it: $out"
echo "ok: release-0-3-2 and 022 cleanup scratch steps"
