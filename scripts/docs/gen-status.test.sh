#!/usr/bin/env bash
# gen-status.sh on a fixture repo (test-fixture.sh): keyword kinds, stdlib receivers, the hand-kept text kept, the
# header rewritten, determinism, refusal of a missing marker.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/docs-gen-status-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
. "$root/scripts/docs/test-fixture.sh"
docs_fixture "$t/repo"
s="$t/repo/scripts/docs/gen-status.sh"; d="$t/repo/docs/STATUS.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
has() { grep -qxF "$1" "$d" || fail "STATUS.md lacks: $1"; }

has '| `struct` | keyword | `Keywords.cs:5` |'
has '| `error` | contextual | `Keywords.cs:5` |'
has '| `actor` | reserved | `Keywords.cs:6` |'
has '| string | `length` | property | `BuiltinMembers.cs:5` |'
has '| string | `utf16` | property | `BuiltinMembers.cs:6` |'
has '| Utf16 | `copy` | method | `BuiltinMembers.cs:12` |'
has '| Span<string> | `joined` | method | `BuiltinMembers.cs:13` |'
has '| List<string> | `joined` | method | `BuiltinMembers.cs:13` |'
has '| List | `append` | method | `BuiltinMembers.cs:15` |'
has '| rune | `copy` | method | `BuiltinMembers.cs:16` |'
has '| IoInput | `readAllBytes` | method | `BuiltinMembers.cs:21` |'
for line in 'Hand-kept intro.' '| `then` | round 4 | proposed | none |' '| units | SPEC | spec-only | none |' 'Hand-kept tail.'; do has "$line"; done
[ "$(bash "$s")" = "$(cat "$d")" ] || fail "regenerating changed the output"

printf '# 0003 — Third\n' > "$t/repo/docs/revisions/0003-third.md"
sed -i.bak 's/^Version: .*/Version: 9.9.9 (matches `bayan --version`)/' "$d"
bash "$s" --write
has 'Version: 1.2.3-dev (matches `bayan --version`)'
has 'Revisions applied: 0001–0003'

grep -v '^<!-- end generated: stdlib -->$' "$d" > "$t/s" && cat "$t/s" > "$d"
out="$(bash "$s" 2>&1)" && fail "missing marker accepted"
echo "$out" | grep -q "needs one '<!-- generated: stdlib -->'" || fail "no marker message: $out"
echo PASS
