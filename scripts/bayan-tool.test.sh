#!/usr/bin/env bash
# bayan-tool.sh passes arguments, stderr and the exit code through, runs from the caller's directory, and refuses a
# missing or path-like tool name.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
t="$root/tools/bayan-tool-probe.byn"; w="$root/tmp/bayan-tool-test"
trap 'rm -f "$t"; rm -rf "$w"' EXIT
mkdir -p "$w"
printf '#!/usr/bin/env bayan\ni32 main(ReadOnlySpan<string> args) {\n    for a in args { print($"[{a}]") }\n    let here = Fs.fileExists("marker")\n    print($"{here}")\n    print("err", to: .stderr)\n    return 3\n}\n' > "$t"
touch "$w/marker"
set +e; out=$(cd "$w" && bash "$root/scripts/bayan-tool.sh" bayan-tool-probe "a b" -- c 2> "$w/err"); rc=$?; set -e
[ "$rc" = 3 ] || fail "exit code $rc, expected 3"
[ "$out" = "$(printf '[a b]\n[--]\n[c]\ntrue')" ] || fail "stdout: $out"
[ "$(cat "$w/err")" = err ] || fail "stderr: $(cat "$w/err")"
if bash "$root/scripts/bayan-tool.sh" no-such-tool 2> /dev/null; then fail "a missing tool ran"; fi
if bash "$root/scripts/bayan-tool.sh" ../x 2> /dev/null; then fail "a path-like name ran"; fi
echo PASS
