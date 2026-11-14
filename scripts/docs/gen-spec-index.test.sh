#!/usr/bin/env bash
# gen-spec-index.sh on a fixture repo (test-fixture.sh): one section per Status group, the file links, `|` escaped,
# refusal of an unknown Status and of a missing key, and --write followed by a byte-equal print.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/docs-gen-spec-index-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
. "$root/scripts/docs/test-fixture.sh"
docs_fixture "$t/repo"
s="$t/repo/scripts/docs/gen-spec-index.sh"; d="$t/repo/docs/specs/README.md"; sp="$t/repo/docs/specs"
fail() { echo "FAIL: $1" >&2; exit 1; }
has() { grep -qxF "$1" "$d" || fail "README.md lacks: $1"; }
lacks() { ! grep -qxF "$1" "$d" || fail "README.md has: $1"; }
# spec <NNN> <slug> <Status> <Release> <Sources> [files...]
spec() {
  local n="$1" slug="$2" f
  mkdir -p "$sp/$n-$slug"
  printf '# %s — Title of %s\n\nStatus: %s\nRelease: %s\nSources: %s\n\nBody.\n' "$n" "$n" "$3" "$4" "$5" > "$sp/$n-$slug/$n-spec.md"
  shift 5
  for f in "$@"; do printf '# %s\n' "$f" > "$sp/$n-$slug/$n-$f.md"; done
}
rm -rf "$d" "$sp"/001-first
spec 001 alpha 'done (2026-01-01)' 1.2.2 'Q1' plan tasks api
spec 002 beta 'in progress (T1 open)' unscheduled 'none recorded' tasks
spec 003 gamma 'approved (not started)' 1.2.3 'Q2 | Q3'
spec 004 delta 'deferred; parked' unscheduled 'none recorded'
spec 005 eps 'rejected; see Q9' unscheduled 'Q9'
spec 006 zeta 'superseded by 007' unscheduled 'Q9' plan
spec 007 eta 'open' unscheduled 'Q9'
spec 008 theta 'draft' unscheduled 'Q9'
bash "$s" --write
head=$'| Spec | Title | Status | Release | Sources | Files |\n|---|---|---|---|---|---|'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } /^## / { on = 0 } on && /^\| \[/ { print }' "$d"; }
has '# Feature specs'
has 'Version: 1.2.3-dev (matches `bayan --version`)'
grep -q 'bash scripts/docs/gen-spec-index.sh --write' "$d" || fail "no generated-file note"
[ "$(grep -c '^## ' "$d")" = 4 ] || fail "want four sections"
grep -n '^## ' "$d" | cut -d: -f2 | paste -sd, - | grep -qx '## Built,## In progress,## To be built,## Rejected or superseded' || fail "sections out of order"
sec Built | grep -q '^| \[001\]' || fail "done not under Built"
sec 'In progress' | grep -q '^| \[002\]' || fail "in progress not under In progress"
[ "$(sec 'To be built' | cut -c1-8 | paste -sd, -)" = '| [003](,| [004](,| [007](,| [008](' ] || fail "To be built rows: $(sec 'To be built')"
[ "$(sec 'Rejected or superseded' | cut -c1-8 | paste -sd, -)" = '| [005](,| [006](' ] || fail "Rejected rows"
has '| [001](001-alpha/001-spec.md) | Title of 001 | done (2026-01-01) | 1.2.2 | Q1 | [plan](001-alpha/001-plan.md), [tasks](001-alpha/001-tasks.md), [api](001-alpha/001-api.md) |'
has '| [002](002-beta/002-spec.md) | Title of 002 | in progress (T1 open) | unscheduled | none recorded | [tasks](002-beta/002-tasks.md) |'
has '| [003](003-gamma/003-spec.md) | Title of 003 | approved (not started) | 1.2.3 | Q2 \| Q3 |  |'
has '| [006](006-zeta/006-spec.md) | Title of 006 | superseded by 007 | unscheduled | Q9 | [plan](006-zeta/006-plan.md) |'
has 'Features rejected without a spec are in [bayan-not-planned.md](../bayan-not-planned.md).'
[ "$(bash "$s")" = "$(cat "$d")" ] || fail "print differs from --write"
cmp -s <(bash "$s") "$d" || fail "print is not byte-equal to the written file"

# a group with no rows is omitted
rm -rf "$sp"/00[5-6]-*
bash "$s" | grep -q '^## Rejected' && fail "empty section kept"

spec 009 iota 'maybe' unscheduled 'Q9'
out="$(bash "$s" 2>&1)" && fail "unknown Status accepted"
echo "$out" | grep -qF "gen-spec-index: docs/specs/009-iota/009-spec.md: unknown Status 'maybe'" || fail "no Status message: $out"
rm -rf "$sp/009-iota"
spec 009 iota 'done' unscheduled 'Q9'
sed -i.bak '/^Release: /d' "$sp/009-iota/009-spec.md"
out="$(bash "$s" 2>&1)" && fail "missing key accepted"
echo "$out" | grep -qF "009-spec.md: no Release: line" || fail "no key message: $out"
echo PASS
