#!/usr/bin/env bash
# cut.sh and next-dev.sh on a fixture git repo (scripts/docs/test-fixture.sh, tagged v1.0.0 and v1.2.2): the version
# and headers set, the CHANGELOG section with the revisions added and the status rows changed since v1.2.2, check.sh
# passing after each, no commit or tag made, refusals.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/release-cut-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
. "$root/scripts/docs/test-fixture.sh"
docs_fixture "$t/repo"
r="$t/repo"; cut="$r/scripts/release/cut.sh"; nd="$r/scripts/release/next-dev.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
g() { git -C "$r" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false -c tag.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
commit() { g add -A && g commit -qm "$1"; }
check() { bash "$r/scripts/docs/check.sh" || fail "check.sh fails after $1"; }

g init -q -b fixture
mv "$r/docs/revisions/0002-second.md" "$t/0002-second.md"   # added between v1.0.0 and v1.2.2: a cut must not list it
commit one && g tag v1.0.0
mv "$t/0002-second.md" "$r/docs/revisions/0002-second.md"
bash "$r/scripts/release/set-version.sh" 1.2.2 >/dev/null
commit "release 1.2.2"
# Like main's merge commits: v1.2.2 sits on a child of the release point that the working branch never descends from.
g checkout -q --detach && g commit -q --allow-empty -m "Merge branch 'fixture'" && g tag v1.2.2 && g checkout -q fixture
! g merge-base --is-ancestor v1.2.2 HEAD || fail "fixture: v1.2.2 is an ancestor of HEAD"

out="$(bash "$nd" 1.2.3)"
echo "$out" | grep -qx "changed VERSION" || fail "next-dev output: $out"
[ "$(cat "$r/VERSION")" = 1.2.3-dev ] || fail "next-dev VERSION: $(cat "$r/VERSION")"
grep -qx 'Version: 1.2.3-dev (matches `bayan --version`)' "$r/docs/STATUS.md" || fail "next-dev STATUS header"
check next-dev
commit "1.2.3-dev"

printf '# 0003 — Third\n' > "$r/docs/revisions/0003-third.md"
printf 'edited\n' >> "$r/docs/revisions/0001-first.md"
sed -i.bak 's/| units | SPEC | spec-only | none |/| units | SPEC | built | `a.cs:1` |\n| `x` | SPEC | proposed | none |/' "$r/docs/STATUS.md"
rm "$r/docs/STATUS.md.bak"
commit "work"
head="$(g rev-parse HEAD)"

# A tracked file that still says the previous -dev version stops the cut, naming the file; the bump is undone here.
printf 'version 1.2.3-dev\n' > "$r/stray.txt"; g add stray.txt
out="$(bash "$cut" 1.2.3 2>&1)" && fail "cut accepted a leftover 1.2.3-dev"
echo "$out" | grep -q "still contain 1.2.3-dev" || fail "no leftover message: $out"
echo "$out" | grep -qx "stray.txt" || fail "leftover file not named: $out"
grep -q '^## \[1.2.3\]' "$r/CHANGELOG.md" && fail "a refused cut wrote the CHANGELOG section"
g rm -qf stray.txt; g checkout -q HEAD -- . ; g clean -qfd -- . 2>/dev/null || true
[ "$(cat "$r/VERSION")" = 1.2.3-dev ] || fail "fixture not restored after the refused cut: $(cat "$r/VERSION")"

out="$(bash "$cut" 1.2.3)"
for f in VERSION src/Bayan.Backend.C/Toolchain.cs docs/bayan-spec.md CHANGELOG.md; do
  echo "$out" | grep -qx "changed $f" || fail "no 'changed $f' in: $out"
done
[ "$(cat "$r/VERSION")" = 1.2.3 ] || fail "cut VERSION: $(cat "$r/VERSION")"
for d in bayan-spec bayan-grammar bayan-style DIAGNOSTICS STATUS; do
  grep -qx 'Version: 1.2.3 (matches `bayan --version`)' "$r/docs/$d.md" || fail "$d Version line"
  grep -qx 'Revisions applied: 0001–0003' "$r/docs/$d.md" || fail "$d Revisions line"
done
check cut
want="$(printf '%s\n' '# Changelog' '' '## [Unreleased]' '' "## [1.2.3] - $(date +%Y-%m-%d)" '' '### Added' '- a new thing' '' \
  '### Revisions' '- 0003 — Third (`docs/revisions/0003-third.md`)' '' '### Status changes' \
  '- `x` (Features): new, proposed' '- units (Features): spec-only → built' '' '## [1.2.2] - 2026-01-01' '' '- old')"
[ "$(cat "$r/CHANGELOG.md")" = "$want" ] || fail "CHANGELOG.md:
$(cat "$r/CHANGELOG.md")"
echo "$out" | grep -qx -- '- units (Features): spec-only → built' || fail "cut does not print the section: $out"
[ "$(bash "$r/scripts/release/package.sh" notes 1.2.3 | grep -c '^### ')" = 3 ] || fail "package.sh notes of the cut section"
[ "$(g rev-parse HEAD)" = "$head" ] || fail "cut committed"
[ "$(g tag --list | tr '\n' ' ')" = "v1.0.0 v1.2.2 " ] || fail "cut tagged: $(g tag --list)"

out="$(bash "$cut" 1.2.3 2>&1)" && fail "second cut accepted"
echo "$out" | grep -q "already has a ## \[1.2.3\] section" || fail "no repeat message: $out"
out="$(bash "$cut" 1.2 2>&1)" && fail "bad version accepted"
echo "$out" | grep -q "'1.2' is not X.Y.Z" || fail "no bad-version message: $out"
out="$(bash "$cut" 2.0.0 2>&1)" && fail "cut of another version accepted"
echo "$out" | grep -q "VERSION is 1.2.3, not 2.0.0" || fail "no version-mismatch message: $out"
out="$(bash "$nd" 1.2.4-dev 2>&1)" && fail "next-dev of a suffixed version accepted"

commit "release 1.2.3"
cp "$r/CHANGELOG.md" "$t/cl"
bash "$nd" 1.2.4 >/dev/null
[ "$(cat "$r/VERSION")" = 1.2.4-dev ] || fail "next-dev 1.2.4 VERSION: $(cat "$r/VERSION")"
cmp -s "$t/cl" "$r/CHANGELOG.md" || fail "next-dev changed CHANGELOG.md"
check "next-dev 1.2.4"

# No previous tag: every revision is listed and the status note says so. An enclosing repo holding a lower v* tag
# must not be consulted (git finds it once $r/.git is gone).
rm -rf "$r/.git"
(cd "$t" && git init -q -b outer \
  && git -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m outer \
  && git -c user.name=test -c user.email=test@example.invalid -c tag.gpgsign=false tag v1.0.0)
bash "$r/scripts/release/set-version.sh" 1.2.4-dev >/dev/null
sed -i.bak 's/^## \[1.2.3\]/## [1.2.3x]/' "$r/CHANGELOG.md"
out="$(bash "$cut" 1.2.4)"
echo "$out" | grep -qx -- '- 0001 — First (`docs/revisions/0001-first.md`)' || fail "untagged cut lacks 0001: $out"
echo "$out" | grep -qx -- '- no previous v\* tag; nothing to compare' || fail "untagged cut status note: $out"
echo PASS
