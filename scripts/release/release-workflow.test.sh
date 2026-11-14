#!/usr/bin/env bash
# Static checks of .github/workflows/release.yml and laws-nightly.yml (a workflow cannot be run here): the dry_run input,
# the full tier of the laws as a required job of a release, and laws-nightly.yml still callable and scheduled.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="$root/.github/workflows/release.yml"; ln="$root/.github/workflows/laws-nightly.yml"
fail() { echo "FAIL: $1" >&2; exit 1; }

grep -qE '^      dry_run: \{.*type: boolean, default: true' "$wf" || fail "release.yml has no boolean dry_run input defaulting to true"
grep -q '^  laws:' "$wf" || fail "release.yml has no laws job"
awk '/^  laws:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" | grep -qx '    uses: ./.github/workflows/laws-nightly.yml' || fail "release.yml's laws job does not call laws-nightly.yml"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -E 'needs:.*\bbuild\b' | grep -q 'memory-gate' || fail "release job lost build or memory-gate"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -qw 'laws' || fail "release.yml's release job does not need laws"
grep -qx '  workflow_call:' "$ln" || fail "laws-nightly.yml is not callable"
grep -q "cron: '0 4 \* \* \*'" "$ln" || fail "laws-nightly.yml lost its schedule"
grep -q 'timeout-minutes: 180' "$ln" || fail "laws-nightly.yml's job no longer allows 180 min"
grep -qF '$(bash scripts/release/package.sh release-flags "$v")' "$wf" || fail "release.yml's gh release create lost release-flags (0.x prerelease)"
echo PASS
