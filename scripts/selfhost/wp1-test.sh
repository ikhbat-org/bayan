#!/bin/bash
# wp1-test.sh — run a branch's tests on the Windows host wp1 and record what ran (preflight.sh reads the record).
#   bash scripts/selfhost/wp1-test.sh chore/worker-012-t17 'FullyQualifiedName~StdFsTests|FullyQualifiedName~CInventoryTests'
# Bundles <branch> into tmp/wp1/<short sha>.bundle, copies it to wp1:/C:/home/code/extrode.com/bayan/tmp/ (scp), and over ssh
# clones it there into tmp/<short sha> (replacing the one an earlier run made) and runs `dotnet test tests/Bayan.Tests -c Release -p:NuGetAudit=false -v q --logger 'console;verbosity=minimal' --filter <filter>`. The minimal console logger keeps each failed test's message and stack in the record (-v q alone printed only `[FAIL]` lines).
# The remote checks the clone's HEAD is the sha resolved here, else exit 4 (the branch moved before the bundle was made).
# Writes tmp/wp1/<sha>.out: branch, sha, filter and the remote command, then the run's output, then `exit <code>`.
# A pass is cached in tmp/wp1/cache/<tree hash>-<filter hash>.out (the commit's tree, so an identical tree on another commit hits too): a later
# run of the same tree and filter copies it to tmp/wp1/<sha>.out under a `cached:` line, prints which cached result it used, and does not touch wp1.
# Exits with the run's code, or 1 when the run matched no tests.
set -u
[ $# = 2 ] || { echo "usage: wp1-test.sh <branch> <filter>"; exit 2; }
BR=$1; FILT=$2
[[ $FILT != *\'* ]] || { echo "wp1-test: the filter holds a single quote"; exit 2; }
SHA=$(git rev-parse --verify -q "$BR^{commit}") || { echo "wp1-test: no branch $BR"; exit 2; }
S=${SHA:0:8}; R=C:/home/code/extrode.com/bayan/tmp; OUT=tmp/wp1/$SHA.out
mkdir -p tmp/wp1/cache
TREE=$(git rev-parse "$SHA^{tree}"); CACHE=tmp/wp1/cache/$TREE-$(printf '%s' "$FILT" | shasum | cut -c1-16).out
if [ -f "$CACHE" ]; then
  { echo "cached: $CACHE"; cat "$CACHE"; } > "$OUT"
  echo "wp1-test: tree $TREE with this filter already passed; reusing the cached result $CACHE (run for $(sed -n 's/^sha: //p' "$CACHE" | head -1)), wp1 not run"
  tail -2 "$CACHE"; exit 0
fi
git bundle create "tmp/wp1/$S.bundle" "$BR" > /dev/null 2>&1 || { echo "wp1-test: git bundle create failed for $BR"; exit 1; }
# wp1's ssh shell is PowerShell (scripts/cleanup/021-ci-q747-scratch.sh); written for 5.1 too (no &&). A re-run for the same sha
# replaces tmp/<short sha> only when tmp/<short sha>.wp1-test, written before the clone, says this script made it; else exit 3
CMD="Set-Location '$R'; if (Test-Path '$S') { if (-not (Test-Path '$S.wp1-test')) { Write-Output 'wp1-test: $R/$S exists and wp1-test.sh did not create it'; exit 3 }; Remove-Item -Recurse -Force '$S' }; \
New-Item -ItemType File -Force '$S.wp1-test' | Out-Null; git clone -q -b $BR $S.bundle $S; if (\$LASTEXITCODE) { exit \$LASTEXITCODE }; \
Set-Location '$S'; if ((git rev-parse HEAD) -ne '$SHA') { Write-Output 'wp1-test: $BR moved after $SHA was resolved; the clone is not $SHA'; exit 4 }; \$env:BAYAN_TEST_TIME_SCALE = '${BAYAN_TEST_TIME_SCALE:-3}'; dotnet test tests/Bayan.Tests -c Release -p:NuGetAudit=false -v q --logger 'console;verbosity=minimal' --filter '$FILT'; exit \$LASTEXITCODE"
printf 'branch: %s\nsha: %s\nfilter: %s\ncommand: ssh wp1 "%s"\n' "$BR" "$SHA" "$FILT" "$CMD" > "$OUT"
scp -q "tmp/wp1/$S.bundle" "wp1:/$R/" >> "$OUT" 2>&1; rc=$?
[ $rc = 0 ] && { ssh wp1 "$CMD" >> "$OUT" 2>&1; rc=$?; }
echo "exit $rc" >> "$OUT"
tail -4 "$OUT"
[ $rc = 0 ] || exit $rc
grep -qE 'Total: *[1-9]' "$OUT" || { echo "wp1-test: the run matched no tests ($OUT)"; exit 1; }
cp "$OUT" "$CACHE"
