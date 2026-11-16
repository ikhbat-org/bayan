#!/usr/bin/env bash
# check.sh on a fixture repo (test-fixture.sh): passes clean, then each check fails on its own breakage:
# (a) a header version, (b) a new revision and a gap, (c) a new descriptor and a hand-edited generated row,
# (d) a mirror that disagrees with VERSION, (e) a status tag for another release, (f) a cited code with no entry,
# (g) a cited spec section with no heading.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/docs-check-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
. "$root/scripts/docs/test-fixture.sh"
docs_fixture "$t/repo"
cp -R "$t/repo" "$t/clean"
s="$t/repo/scripts/docs/check.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
reset() { rm -rf "$t/repo" && cp -R "$t/clean" "$t/repo"; }
# expect <what> <message fragment>: check.sh must fail and print the fragment.
expect() {
  local out
  out="$(bash "$s" 2>&1)" && fail "$1: check passed"
  echo "$out" | grep -qF "$2" || fail "$1: no '$2' in: $out"
  reset
}

bash "$s" || fail "clean fixture fails"

sed -i.bak 's/^Version: .*/Version: 1.2.2 (matches `bayan --version`)/' "$t/repo/docs/bayan-grammar.md"
expect "(a) header version" "docs/bayan-grammar.md: 'Version: 1.2.2 (matches \`bayan --version\`)' is not 'Version: 1.2.3-dev"

printf '# 0003 — Third\n' > "$t/repo/docs/revisions/0003-third.md"
expect "(b) new revision" "docs/bayan-spec.md: 'Revisions applied: 0001–0002' is not 'Revisions applied: 0001–0003'"
rm "$t/repo/docs/revisions/0001-first.md"
expect "(b) gap" "docs/revisions/0001-*.md is missing"
cp "$t/repo/docs/revisions/0002-second.md" "$t/repo/docs/revisions/0002-again.md"
expect "(b) repeat" "docs/revisions has 2 files numbered 0002"

sed -i.bak 's/^}$/    public static readonly DiagnosticDescriptor Eps = Error("BYN4006", "eps");\n}/' \
  "$t/repo/src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs"
grep -q BYN4006 "$t/repo/src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs" || fail "fixture edit did not apply"
expect "(c) new descriptor" "docs/DIAGNOSTICS.md is stale; run bash scripts/docs/gen-diagnostics.sh --write"
sed -i.bak 's/| units | SPEC | spec-only | none |/| units | SPEC | built | none |/' "$t/repo/docs/STATUS.md"
bash "$s" >/dev/null || fail "(c) a hand-kept STATUS row edit fails the check"
sed -i.bak 's/| string | `length` | property |/| string | `length` | method |/' "$t/repo/docs/STATUS.md"
expect "(c) edited generated row" "docs/STATUS.md is stale; run bash scripts/docs/gen-status.sh --write"

sed -i.bak 's/"1.2.3-dev"/"1.2.4-dev"/' "$t/repo/src/Bayan.Backend.C/Toolchain.cs"
expect "(d) Toolchain.cs" "src/Bayan.Backend.C/Toolchain.cs says 1.2.4-dev, VERSION says 1.2.3-dev"
sed -i.bak '6s/bayan 1.2.3-dev/bayan 1.2.2/' "$t/repo/tests/cases/out/dist.tree"
expect "(d) second dist.tree line" "tests/cases/out/dist.tree says 1.2.2, VERSION says 1.2.3-dev"
printf 'Units (partial in 1.2: no suffixes). Handles (not in 1.2).\n' >> "$t/repo/docs/bayan-spec.md"
bash "$s" >/dev/null || fail "(e) tags for the VERSION release fail the check"
printf 'Line one.\nEvents (not in 1.1).\n' >> "$t/repo/docs/bayan-grammar.md"
expect "(e) tag for another release" "docs/bayan-grammar.md:8 has the status tag '(not in 1.1', which is not for 1.2 (VERSION 1.2.3-dev)"
printf 'Units (partial in 0.2: no suffixes).\n' >> "$t/repo/docs/bayan-style.md"
expect "(e) partial tag for another release" "docs/bayan-style.md:7 has the status tag '(partial in 0.2', which is not for 1.2"
printf 'Uses BYN0001 and BYN2233.\n' >> "$t/repo/docs/bayan-style.md"
bash "$s" >/dev/null || fail "(f) codes with a descriptor or an allocated line fail the check"
printf 'A planned BYN6008.\n' >> "$t/repo/docs/bayan-spec.md"
expect "(f) cited code" "docs/bayan-spec.md cites BYN6008, which has no row in docs/DIAGNOSTICS.md"
printf 'Merged like BYN1002 into BYN0001; see BYN3004.\n' >> "$t/repo/docs/bayan-grammar.md"
bash "$s" >/dev/null || fail "(f) retired and reserved codes fail the check"
grep -qF 'BYN0001' "$t/repo/docs/DIAGNOSTICS.md" || fail "fixture has no BYN0001 text"
printf 'Only in prose: BYN7777.\n' >> "$t/repo/docs/bayan-style.md"
sed -i.bak 's/^\(| \[BYN0001\].*\)$/\1 see BYN7777/' "$t/repo/docs/DIAGNOSTICS.md"
grep -qF 'see BYN7777' "$t/repo/docs/DIAGNOSTICS.md" || fail "fixture edit did not apply"
expect "(f) code only in another row's text" "docs/bayan-style.md cites BYN7777, which has no row in docs/DIAGNOSTICS.md"

# (g) the spec gets headings; a bare §N, a historical doc and a good cite pass, a missing heading fails with file:line
printf '\n## 6. Expressions\n\n### 6.6 Interpolation\n' >> "$t/repo/docs/bayan-spec.md"
printf 'Display is in SPEC §6.6 and (spec §6). A bare §9.9 may cite the grammar.\n' >> "$t/repo/docs/bayan-style.md"
printf '// Display (spec §6.6).\n' >> "$t/repo/src/Bayan.Semantics/Binding/Fixture.cs"
printf 'Historical: spec §9.9.\n' >> "$t/repo/docs/revisions/0002-second.md"
bash "$s" >/dev/null || fail "(g) good cites, a bare cite and a historical doc fail the check"
printf 'See SPEC §6.9.\n' >> "$t/repo/docs/bayan-style.md"
expect "(g) missing heading in docs" "docs/bayan-style.md:$(wc -l < "$t/repo/docs/bayan-style.md" | tr -d ' ') cites spec §6.9, which is not a heading of docs/bayan-spec.md"
printf '## 13. Concurrency\n' >> "$t/repo/docs/bayan-spec.md"
printf '// Display (spec §13).\n// Locks (spec §13.4).\n' >> "$t/repo/src/Bayan.Semantics/Binding/Fixture.cs"
expect "(g) missing heading in a code comment" "src/Bayan.Semantics/Binding/Fixture.cs:2 cites spec §13.4, which is not a heading of docs/bayan-spec.md"
echo PASS
