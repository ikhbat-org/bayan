#!/usr/bin/env bash
# bayan-tool.sh passes arguments, stderr and the exit code through, runs from the caller's directory, ignores stub
# programs on PATH under the caller's directory, runs two tools side by side in tools/, and refuses a missing,
# path-like or non-script tool.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
t="$root/tools/bayan-tool-probe.byn"; b="$root/tools/bayan-tool-probe-b.byn"; n="$root/tools/bayan-tool-probe-n.byn"
w="$root/tmp/bayan-tool-test"
trap 'rm -f "$t" "$b" "$n"; rm -rf "$w"' EXIT
mkdir -p "$w"
printf '#!/usr/bin/env bayan\ni32 main(ReadOnlySpan<string> args) {\n    for a in args { print($"[{a}]") }\n    let here = Fs.fileExists("marker")\n    print($"{here}")\n    print("err", to: .stderr)\n    return 3\n}\n' > "$t"
# A second tool beside the probe: each tool is its own program.
printf '#!/usr/bin/env bayan\nvoid main() {\n    print("b")\n}\n' > "$b"
touch "$w/marker"
set +e; out=$(cd "$w" && bash "$root/scripts/bayan-tool.sh" bayan-tool-probe "a b" -- c 2> "$w/err"); rc=$?; set -e
[ "$rc" = 3 ] || fail "exit code $rc, expected 3: $(head -3 "$w/err")"
[ "$out" = "$(printf '[a b]\n[--]\n[c]\ntrue')" ] || fail "stdout: $out"
[ "$(cat "$w/err")" = err ] || fail "stderr: $(cat "$w/err")"
[ "$(bash "$root/scripts/bayan-tool.sh" bayan-tool-probe-b)" = b ] || fail "the second tool did not run alone"
mkdir -p "$w/bin"; printf '#!/usr/bin/env bash\nexit 1\n' > "$w/bin/git"; chmod +x "$w/bin/git"
set +e; out=$(cd "$w" && PATH="$w/bin:$PATH" bash "$root/scripts/bayan-tool.sh" bayan-tool-probe 2> /dev/null); rc=$?; set -e
[ "$rc" = 3 ] || fail "a git stub in the caller's bin/ broke the launcher: exit $rc"
if bash "$root/scripts/bayan-tool.sh" no-such-tool 2> /dev/null; then fail "a missing tool ran"; fi
if bash "$root/scripts/bayan-tool.sh" ../x 2> /dev/null; then fail "a path-like name ran"; fi
rm -f "$b"; printf 'void main() {\n}\n' > "$n"
set +e; err=$(bash "$root/scripts/bayan-tool.sh" bayan-tool-probe-n 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && [[ "$err" == *"does not start with #!"* ]] || fail "a tool without #! ran (exit $rc): $err"
echo PASS
