#!/usr/bin/env bash
# mutate.sh's default file set, in a fixture repo under tmp/: a branch that changes only csharp/tests/ has nothing to mutate
# (exit 1 before Stryker).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
d="$root/tmp/mutate-test"
trap 'rm -rf "$d"' EXIT
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
g() { git -C "$d" -c user.email=t@t -c user.name=t "$@"; }
rm -rf "$d"; mkdir -p "$d/scripts/quality" "$d/csharp/tests/Bayan.Tests" "$d/csharp/Bayan.Cli"
cp "$root/scripts/quality/mutate.sh" "$d/scripts/quality/"
echo 'class T {}' > "$d/csharp/tests/Bayan.Tests/T.cs"; echo 'class C {}' > "$d/csharp/Bayan.Cli/C.cs"
g init -q -b dev; g config core.hooksPath /dev/null; g add -A; g commit -q -m base
g checkout -q -b feat/x; echo 'class T { int x; }' > "$d/csharp/tests/Bayan.Tests/T.cs"; g commit -qam tests
out=$(bash "$d/scripts/quality/mutate.sh" 2>&1) && fail "a tests-only change did not refuse" "$out"
grep -qx 'mutate.sh: no csharp/ files to mutate' <<< "$out" || fail "a tests-only change reached Stryker" "$out"
echo ok
