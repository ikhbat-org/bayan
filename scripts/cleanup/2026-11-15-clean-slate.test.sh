#!/usr/bin/env bash
# Tests step 2b of 2026-11-15-clean-slate.sh in a fixture repo whose main checkout is on dev: ignored old-layout build output is
# listed, removed only with --execute --delete-old-build-output, and a directory with a file git does not ignore is refused.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/clean-slate-test"; rm -rf "$t"; mkdir -p "$t"; cd "$t"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
git init -q -b dev && git config core.hooksPath /dev/null
mkdir -p src/driver src/Bayan.Cli/obj src/Bayan.Testing && echo x > src/driver/a.byn
printf 'obj/\n' > .gitignore && git add . && git -c user.email=t@t -c user.name=t commit -qm base
echo o > src/Bayan.Cli/obj/a.dll; echo s > src/Bayan.Testing/stray.cs
fail() { echo "FAIL $1"; exit 1; }
s="$root/scripts/cleanup/2026-11-15-clean-slate.sh"
out="$(bash "$s" 2>&1 || true)"
grep -q '^stale:  src/Bayan.Cli ' <<<"$out" || fail "dry run lists the ignored build output: $out"
grep -q '^refuse: src/Bayan.Testing holds files git does not ignore' <<<"$out" || fail "dry run refuses an unignored file: $out"
bash "$s" -e > /dev/null 2>&1 || true
[ -f src/Bayan.Cli/obj/a.dll ] || fail "--execute alone removed build output"
bash "$s" -e --delete-old-build-output > /dev/null 2>&1 || true
[ ! -e src/Bayan.Cli ] || fail "--delete-old-build-output left src/Bayan.Cli"
[ -f src/Bayan.Testing/stray.cs ] || fail "an unignored file was removed"
[ -f src/driver/a.byn ] || fail "a tracked file was removed"
echo ok
