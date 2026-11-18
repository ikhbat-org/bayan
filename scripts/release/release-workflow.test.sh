#!/usr/bin/env bash
# Static checks of .github/workflows/release.yml and laws-nightly.yml (a workflow cannot be run here): the dry_run input,
# the full tier of the laws and the diverse double-compiling job (ddc.yml, 019 R27) as required jobs of a release, and
# laws-nightly.yml and ddc.yml still callable and scheduled.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wf="$root/.github/workflows/release.yml"; ln="$root/.github/workflows/laws-nightly.yml"; ddc="$root/.github/workflows/ddc.yml"
fail() { echo "FAIL: $1" >&2; exit 1; }

grep -qE '^      dry_run: \{.*type: boolean, default: true' "$wf" || fail "release.yml has no boolean dry_run input defaulting to true"
grep -q '^  laws:' "$wf" || fail "release.yml has no laws job"
awk '/^  laws:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" | grep -qx '    uses: ./.github/workflows/laws-nightly.yml' || fail "release.yml's laws job does not call laws-nightly.yml"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -E 'needs:.*\bbuild\b' | grep -q 'memory-gate' || fail "release job lost build or memory-gate"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -qw 'laws' || fail "release.yml's release job does not need laws"
grep -q '^  ddc:' "$wf" || fail "release.yml has no ddc job"
awk '/^  ddc:/{j=1;next} j&&/^  [^ #]/{exit} j' "$wf" | grep -qx '    uses: ./.github/workflows/ddc.yml' || fail "release.yml's ddc job does not call ddc.yml"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -qw 'ddc' || fail "release.yml's release job does not need ddc"
grep -qx '  workflow_call:' "$ddc" || fail "ddc.yml is not callable"
grep -qE "^    - cron: '[0-9]+ [0-9]+ \* \* [0-6]'" "$ddc" || fail "ddc.yml lost its weekly schedule"
grep -q 'bash scripts/ci/install-dotnet.sh' "$ddc" && grep -q 'bash scripts/ci/ddc.sh' "$ddc" || fail "ddc.yml does not install .NET with install-dotnet.sh and run ddc.sh"
ddcref=$(sed -n "s/.*DDC_REF: \${{ inputs.ref || '\([^']*\)' }}.*/\1/p" "$ddc")
# a CI checkout fetches with --no-tags: the check needs a clone that has tags
if [ -n "$(git -C "$root" tag -l | head -n 1)" ]; then
  git -C "$root" rev-parse -q --verify "refs/tags/$ddcref^{commit}" >/dev/null || fail "ddc.yml defaults to ref '$ddcref', which is not a tag here"
fi
grep -qx '  workflow_call:' "$ln" || fail "laws-nightly.yml is not callable"
grep -q "cron: '0 4 \* \* \*'" "$ln" || fail "laws-nightly.yml lost its schedule"
grep -q 'timeout-minutes: 180' "$ln" || fail "laws-nightly.yml's job no longer allows 180 min"
grep -qF '$(bash scripts/release/package.sh release-flags "$v")' "$wf" || fail "release.yml's gh release create lost release-flags (0.x prerelease)"
# 019 R37: each archive holds bayan-lsp, built by the shipped (stage 2) bayan after its smoke test and before Package;
# the C# server (editors/language-server/*.csproj) is never built or shipped.
[ "$(grep -cE '^          - \{ os: [^,]+, rid: (linux|osx)-[a-z0-9]+, exe: bayan, lsp: bayan-lsp \}$|^          - \{ os: [^,]+, rid: win-[a-z0-9]+, exe: bayan\.exe, lsp: bayan-lsp\.exe \}$' "$wf")" = 6 ] \
  || fail "release.yml's six build rows do not each name lsp: bayan-lsp (.exe on Windows)"
lsp='        run: ./publish/${{ matrix.exe }} build --package editors/language-server/src -o publish/${{ matrix.lsp }} editors/language-server/src/app'
l_lsp=$(grep -nxF -- "$lsp" "$wf" | cut -d: -f1 | head -n 1 || true)
l_sm=$(grep -nF -- 'run: ./publish/${{ matrix.exe }} --version' "$wf" | cut -d: -f1 | head -n 1 || true)
l_pkg=$(grep -nxF -- '        run: bash scripts/release/package.sh pack ${{ matrix.rid }} publish dist' "$wf" | cut -d: -f1 | head -n 1 || true)
[ -n "$l_lsp" ] || fail "release.yml does not build bayan-lsp with the shipped bayan into publish/"
[ -n "$l_sm" ] && [ -n "$l_pkg" ] && [ "$l_sm" -lt "$l_lsp" ] && [ "$l_lsp" -lt "$l_pkg" ] || fail "release.yml builds bayan-lsp outside the smoke test .. Package span"
! grep -qE 'LanguageServer|\.csproj' "$wf" || fail "release.yml builds the C# language server"
echo PASS
