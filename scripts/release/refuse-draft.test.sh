#!/usr/bin/env bash
# Tests scripts/release/refuse-draft.sh: a -rc tag and a dispatch run are refused, a pushed plain tag is not, and the
# release job of release.yml runs the check in a step.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
s="$root/scripts/release/refuse-draft.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

bash "$s" v1.2.3 push 2>/dev/null || fail "a pushed plain tag was refused"
out="$(bash "$s" v1.2.3-rc.1 push 2>&1)" && fail "an -rc tag was accepted"
echo "$out" | grep -q "release candidate" || fail "no -rc message: $out"
out="$(bash "$s" v1.2.3 workflow_dispatch 2>&1)" && fail "a dispatch run was accepted"
echo "$out" | grep -q "workflow_dispatch run" || fail "no dispatch message: $out"
bash "$s" v1.2.3-rc.1 workflow_dispatch 2>/dev/null && fail "an -rc dispatch was accepted"
bash "$s" 2>/dev/null && fail "no arguments accepted"

# Wiring: the release job runs the check as a step, before it creates the release.
wf="$root/.github/workflows/release.yml"
awk '/^  release:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" > "${TMPDIR:-/tmp}/refuse-draft-job.$$"
trap 'rm -f "${TMPDIR:-/tmp}/refuse-draft-job.$$"' EXIT
job="${TMPDIR:-/tmp}/refuse-draft-job.$$"
grep -qE 'bash scripts/release/refuse-draft.sh ' "$job" || fail "release.yml's release job does not run refuse-draft.sh"
[ "$(grep -n 'refuse-draft.sh' "$job" | head -1 | cut -d: -f1)" -lt "$(grep -n 'gh release create' "$job" | head -1 | cut -d: -f1)" ] \
  || fail "refuse-draft.sh runs after gh release create"
echo PASS
