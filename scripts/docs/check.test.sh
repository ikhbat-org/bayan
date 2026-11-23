#!/usr/bin/env bash
# check.sh on a fixture repo (test-fixture.sh): passes clean, then each check fails on its own breakage:
# (a) a header version, (b) a new revision and a gap, (c) a new descriptor, a hand-edited generated row and a stale
# spec index, (d) a mirror that disagrees with VERSION, (e) a status tag for another release, (f) a cited code with no
# entry, (g) a cited spec section with no heading, (h) a record header that is missing or names an unknown release, a
# law with no release key, a -dev release, a doc of no kind, a snapshot with no Snapshot line, (i) a revision the feature history does not cite and a spec
# section with no row.
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
sed -i.bak 's/^Version: .*/Version: 1.2.2 (matches `bayan --version`)/' "$t/repo/docs/laws/README.md"
expect "(a) release doc version" "docs/laws/README.md: 'Version: 1.2.2 (matches \`bayan --version\`)' is not 'Version: 1.2.3-dev"

printf '# 0003 — Third\n' > "$t/repo/docs/revisions/0003-third.md"
expect "(b) new revision" "docs/bayan-spec.md: 'Revisions applied: 0001–0002' is not 'Revisions applied: 0001–0003'"
rm "$t/repo/docs/revisions/0001-first.md"
expect "(b) gap" "docs/revisions/0001-*.md is missing"
cp "$t/repo/docs/revisions/0002-second.md" "$t/repo/docs/revisions/0002-again.md"
expect "(b) repeat" "docs/revisions has 2 files numbered 0002"

sed -i.bak -e 's/^    old$/    old\n    eps/' -e 's/^    \.old         => "BYN3005",$/&\n    .eps         => "BYN4006",/' \
  -e 's/^    \.old         => "old",$/&\n    .eps         => "eps",/' "$t/repo/src/semantics/codes.byn"
grep -q BYN4006 "$t/repo/src/semantics/codes.byn" || fail "fixture edit did not apply"
expect "(c) new descriptor" "docs/DIAGNOSTICS.md is stale; run bash scripts/docs/gen-diagnostics.sh --write"
sed -i.bak 's/| units | SPEC | spec-only | none |/| units | SPEC | built | none |/' "$t/repo/docs/STATUS.md"
bash "$s" >/dev/null || fail "(c) a hand-kept STATUS row edit fails the check"
sed -i.bak 's/| string | `length` | property |/| string | `length` | method |/' "$t/repo/docs/STATUS.md"
expect "(c) edited generated row" "docs/STATUS.md is stale; run bash scripts/docs/gen-status.sh --write"
sed -i.bak 's/^Status: done$/Status: in progress/' "$t/repo/docs/specs/001-first/001-spec.md"
expect "(c) stale spec index" "docs/specs/README.md is stale; run bash scripts/docs/gen-spec-index.sh --write"

sed -i.bak 's/"1.2.3-dev"/"1.2.4-dev"/' "$t/repo/csharp/Bayan.Backend.C/Toolchain.cs"
expect "(d) Toolchain.cs" "csharp/Bayan.Backend.C/Toolchain.cs says 1.2.4-dev, VERSION says 1.2.3-dev"
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
printf '\n### §6. Expressions\n' >> "$t/repo/docs/bayan-feature-history.md"
printf 'Display is in SPEC §6.6 and (spec §6). A bare §9.9 may cite the grammar.\n' >> "$t/repo/docs/bayan-style.md"
printf '// Display (spec §6.6).\n' >> "$t/repo/csharp/Bayan.Semantics/Binding/Fixture.cs"
printf 'Historical: spec §9.9.\n' >> "$t/repo/docs/revisions/0002-second.md"
bash "$s" >/dev/null || fail "(g) good cites, a bare cite and a historical doc fail the check"
printf 'See SPEC §6.9.\n' >> "$t/repo/docs/bayan-style.md"
expect "(g) missing heading in docs" "docs/bayan-style.md:$(wc -l < "$t/repo/docs/bayan-style.md" | tr -d ' ') cites spec §6.9, which is not a heading of docs/bayan-spec.md"
printf '## 13. Concurrency\n' >> "$t/repo/docs/bayan-spec.md"
printf '\n### §13. Concurrency\n' >> "$t/repo/docs/bayan-feature-history.md"
printf '// Display (spec §13).\n// Locks (spec §13.4).\n' >> "$t/repo/csharp/Bayan.Semantics/Binding/Fixture.cs"
expect "(g) missing heading in a code comment" "csharp/Bayan.Semantics/Binding/Fixture.cs:2 cites spec §13.4, which is not a heading of docs/bayan-spec.md"

# (i) the feature history: a revision it does not cite and a numbered section with no row
printf '# 0003 — Third\n\nStatus: done\nRelease: 1.2.2\nSources: none recorded\n' > "$t/repo/docs/revisions/0003-third.md"
sed -i.bak 's/^Revisions applied: .*/Revisions applied: 0001–0003/' "$t/repo"/docs/{bayan-spec,bayan-grammar,bayan-style,DIAGNOSTICS,STATUS}.md
bash "$s" >/dev/null 2>&1 && fail "(i) setup: an uncited revision passes"
printf ', 0003-third.md\n' >> "$t/repo/docs/bayan-feature-history.md"
bash "$s" >/dev/null || fail "(i) a cited revision fails the check"
reset
printf '# 0003 — Third\n\nStatus: done\nRelease: 1.2.2\nSources: none recorded\n' > "$t/repo/docs/revisions/0003-third.md"
sed -i.bak 's/^Revisions applied: .*/Revisions applied: 0001–0003/' "$t/repo"/docs/{bayan-spec,bayan-grammar,bayan-style,DIAGNOSTICS,STATUS}.md
expect "(i) uncited revision" "docs/revisions/0003-third.md is not cited in docs/bayan-feature-history.md"
printf '\n## 7. Statements\n' >> "$t/repo/docs/bayan-spec.md"
expect "(i) section with no row" "SPEC section 7 has no row in docs/bayan-feature-history.md"

# (h) record and snapshot headers; a release doc under a record directory (docs/revisions/README.md) is not a record
mkdir -p "$t/repo/docs/plans" "$t/repo/docs/laws" "$t/repo/docs/export"
for rel in 1.2.2 1.2.3 unscheduled; do
  printf '# P\n\nStatus: open\nRelease: %s\nSources: Q1\n' "$rel" > "$t/repo/docs/plans/p-$rel.md"
done
printf -- '---\nid: L001\nstatus: enacted\nrelease: 1.2.2\nsources: none recorded\n---\n\n# L001\n' > "$t/repo/docs/laws/001-x.md"
printf '# X\n\nSnapshot: 2026-01-01; not maintained. Current text: none\n' > "$t/repo/docs/export/X.md"
bash "$s" >/dev/null || fail "(h) good record, law and snapshot headers fail the check"
cp -R "$t/repo" "$t/clean-h"; reset() { rm -rf "$t/repo" && cp -R "$t/clean-h" "$t/repo"; }
printf '# Q\n\nStatus: open\nSources: Q1\n' > "$t/repo/docs/plans/q.md"
expect "(h) record with no Release" "docs/plans/q.md: no Release: line in the first ten lines (record doc)"
sed -i.bak 's/^Release: 1.2.2$/Release: 1.2.1 (never cut)/' "$t/repo/docs/plans/p-1.2.2.md"
expect "(h) unknown release" "docs/plans/p-1.2.2.md: Release: 1.2.1 is not a released version (CHANGELOG.md), 1.2.3 or unscheduled"
printf '# D\n\nStatus: open\nRelease: 1.2.3-dev\nSources: Q1\n' > "$t/repo/docs/plans/d.md"
expect "(h) -dev release" "docs/plans/d.md: Release: 1.2.3-dev is not a released version"
printf '# U\n\nno header\n' > "$t/repo/docs/u.md"
expect "(h) doc of no kind" "docs/u.md is not a release, record or snapshot doc"
sed -i.bak '/^release: /d' "$t/repo/docs/laws/001-x.md"
expect "(h) law with no release key" "docs/laws/001-x.md: no Release: line in the first ten lines (record doc)"
sed -i.bak 's/^id: L001$/id: L001\na: 1\nb: 2\nc: 3\nd: 4\ne: 5\nf: 6/' "$t/repo/docs/laws/001-x.md"
grep -qx 'f: 6' "$t/repo/docs/laws/001-x.md" || fail "fixture edit did not apply"
expect "(h) law key past line ten" "docs/laws/001-x.md: no Sources: line in the first ten lines (record doc)"
sed -i.bak '/^Snapshot: /d' "$t/repo/docs/export/X.md"
expect "(h) snapshot with no Snapshot line" "docs/export/X.md: no Snapshot: line in the first ten lines (snapshot doc)"
echo PASS
