#!/usr/bin/env bash
# prose-check.sh on fixture files: a clean page passes, each rule fails on its own breakage, and code, exempt pages and
# off/on regions are skipped.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
s="$root/scripts/docs/prose-check.sh"
t="$root/tmp/prose-check-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
export PROSE_VERSION=0.4.1
fail() { echo "FAIL: $1" >&2; exit 1; }
# expect <what> <rule> <text>: the check fails on a page holding <text> and names <rule>.
expect() {
  printf '%s\n' "$3" > "$t/page.md"
  local out
  out="$(bash "$s" "$t/page.md" 2>&1)" && fail "$1: check passed"
  echo "$out" | grep -qF ": $2: " || fail "$1: no '$2' finding in: $out"
}
pass() {
  printf '%s\n' "$2" > "$t/${3:-page.md}"
  local out
  out="$(bash "$s" "$t/${3:-page.md}" 2>&1)" || fail "$1: check failed: $out"
}

pass "clean" "Download bayan-<version>-<os>-<arch>.tar.gz for bayan 0.4.1, see v0.4."

expect "archives in a list" archives "$(printf -- '- bayan-0.4.1-macos-arm64.tar.gz\n- bayan-0.4.1-linux-x64.tar.gz\n- bayan-0.4.1-windows-arm64.zip')"
expect "archives on one line" archives "bayan-0.4.1-macos-arm64.tar.gz, bayan-0.4.1-macos-x64.tar.gz or bayan-0.4.1-linux-x64.tar.gz"
pass "two archives" "bayan-0.4.1-macos-arm64.tar.gz or bayan-0.4.1-linux-x64.tar.gz"
pass "archives in separate paragraphs" "$(printf 'bayan-0.4.1-macos-arm64.tar.gz\n\nbayan-0.4.1-linux-x64.tar.gz\n\nbayan-0.4.1-linux-arm64.tar.gz')"

expect "C#" csharp "Unlike C#, errors are values."
expect ".NET" csharp "It needs no .NET runtime."
expect "dotnet" csharp "Run dotnet test first."
expect "csharp/" csharp "The old code is in csharp/src."
pass "Bayān .net capability" "A function that uses .net declares it."

expect "old version" version "Since bayan 0.3.1 the build is faster."
expect "old v tag" version "Added in v0.3."
expect "dev version" version "Build bayan-0.4.1-dev from source."
pass "current v tag" "Added in v0.4.1."

expect "filler word" filler "You can simply run it."
expect "filler phrase" filler "Note that the file must exist."
pass "filler inside a word" "The justification is in the spec."

pass "fenced code" "$(printf '```\nsimply run C# here: bayan 0.1.0\n```')"
pass "pre block" "$(printf '<pre>\nC# and dotnet\n</pre>')"
pass "inline code" 'Run `dotnet test` or <code>simply</code>.'
pass "off region" "$(printf '<!-- prose-check: off -->\nThe ddc job builds the C# compiler.\n<!-- prose-check: on -->')"
expect "on again" csharp "$(printf '<!-- prose-check: off -->\nok\n<!-- prose-check: on -->\nThe C# compiler.')"
pass "from- guide" "Coming from C#? Simply read on." from-csharp.page
pass "whats-new" "New in bayan 0.3.1." whats-new.page

echo "prose-check: PASS"
