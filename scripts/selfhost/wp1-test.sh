#!/bin/bash
# wp1-test.sh — run a branch's tests on the Windows host wp1 and record what ran (preflight.sh reads the record).
#   bash scripts/selfhost/wp1-test.sh chore/worker-012-t17 golden
# Bundles <branch> into tmp/wp1/<short sha>.bundle, copies it to wp1:/C:/home/code/extrode.com/bayan/tmp/ (scp), and over ssh
# clones it there into tmp/<short sha> (replacing the one an earlier run made) and runs, under Git Bash (WIN_BASH, default C:\home\apps\Git\bin\bash.exe),
# `bash scripts/bootstrap-build.sh` then `bash scripts/test.sh --only <part>` with BAYAN_EXE set to the stage-1 binary bootstrap-build printed.
# <part> is a scripts/test.sh part: golden, bayan, parity, scripts or runtime (anything else exits 2).
# The remote checks the clone's HEAD is the sha resolved here, else exit 4 (the branch moved before the bundle was made).
# Writes tmp/wp1/<sha>.out: branch, sha, part (on the `filter:` line preflight.sh reads) and the remote command, then the run's output, then `exit <code>`.
# A pass is cached in tmp/wp1/cache/<tree hash>-<part hash>.out (the commit's tree, so an identical tree on another commit hits too): a later
# run of the same tree and part copies it to tmp/wp1/<sha>.out under a `cached:` line, prints which cached result it used, and does not touch wp1.
# Exits with the run's code, or 1 when the output lacks scripts/test.sh's `test: all passed` line.
# WIN_HOST (default wp1) is the Windows host: the ssh/scp target, and tmp/<host>/ for the bundle, the record and the cache, so two hosts
# run at once without sharing a file (preflight.sh reads tmp/wp1). On wlt1 the remote command first puts zig on PATH.
# WIN_THREADS=N adds `--jobs N` to scripts/test.sh. BAYAN_TEST_TIME_SCALE (default 3) is passed through.
# WIN_TRX is dropped: scripts/test.sh writes no trx.
# WIN_CC sets CC for the remote run (e.g. 'zig cc'); unset, the remote run unsets CC, since wp1's user environment points CC at a
# removed tdm-gcc (2026-11-18), and bootstrap-build.sh then picks cc or zig.
set -u
[ $# = 2 ] || { echo "usage: wp1-test.sh <branch> <part>"; exit 2; }
BR=$1; FILT=$2; H=${WIN_HOST:-wp1}; WB=${WIN_BASH:-'C:\home\apps\Git\bin\bash.exe'}
case $H in ''|*[!A-Za-z0-9_-]*) echo "wp1-test: bad WIN_HOST $H"; exit 2;; esac
case ${WIN_THREADS-1} in ''|*[!0-9]*|0) echo "wp1-test: bad WIN_THREADS ${WIN_THREADS-} (a positive integer)"; exit 2;; esac
case $FILT in golden|bayan|parity|scripts|runtime) :;; *) echo "wp1-test: bad part $FILT (golden, bayan, parity, scripts, runtime)"; exit 2;; esac
SHA=$(git rev-parse --verify -q "$BR^{commit}") || { echo "wp1-test: no branch $BR"; exit 2; }
S=${SHA:0:8}; R=C:/home/code/extrode.com/bayan/tmp; OUT=tmp/$H/$SHA.out
mkdir -p "tmp/$H/cache"
TREE=$(git rev-parse "$SHA^{tree}"); CACHE=tmp/$H/cache/$TREE-$(printf '%s' "$FILT" | shasum | cut -c1-16).out
if [ -f "$CACHE" ]; then
  { echo "cached: $CACHE"; cat "$CACHE"; } > "$OUT"
  echo "wp1-test: tree $TREE with this part already passed; reusing the cached result $CACHE (run for $(sed -n 's/^sha: //p' "$CACHE" | head -1)), $H not run"
  tail -2 "$CACHE"; exit 0
fi
git bundle create "tmp/$H/$S.bundle" "$BR" > /dev/null 2>&1 || { echo "wp1-test: git bundle create failed for $BR"; exit 1; }
# wp1's ssh shell is PowerShell (scripts/cleanup/021-ci-q747-scratch.sh); written for 5.1 too (no &&). A re-run for the same sha
# replaces tmp/<short sha> only when tmp/<short sha>.wp1-test, written before the clone, says this script made it; else exit 3
PRE=""; [ "$H" != wlt1 ] || PRE="\$env:PATH = 'C:\\home\\lang\\zig\\zig-x86_64-windows-0.17.0;' + \$env:PATH; "
CCX="unset CC; "
if [ -n "${WIN_CC:-}" ]; then
  case $WIN_CC in *[!A-Za-z0-9\ ._:/-]*) echo "wp1-test: bad WIN_CC $WIN_CC"; exit 2;; esac
  CCX="export CC=''$WIN_CC''; "
fi
XTRA=""; [ -z "${WIN_THREADS:-}" ] || XTRA=" --jobs $WIN_THREADS"
CMD="$PRE""Set-Location '$R'; if (Test-Path '$S') { if (-not (Test-Path '$S.wp1-test')) { Write-Output 'wp1-test: $R/$S exists and wp1-test.sh did not create it'; exit 3 }; Remove-Item -Recurse -Force '$S' }; \
New-Item -ItemType File -Force '$S.wp1-test' | Out-Null; git clone -q -b $BR $S.bundle $S; if (\$LASTEXITCODE) { exit \$LASTEXITCODE }; \
Set-Location '$S'; if ((git rev-parse HEAD) -ne '$SHA') { Write-Output 'wp1-test: $BR moved after $SHA was resolved; the clone is not $SHA'; exit 4 }; \$env:BAYAN_TEST_TIME_SCALE = '${BAYAN_TEST_TIME_SCALE:-3}'; & '$WB' -c '${CCX}exe=\$(bash scripts/bootstrap-build.sh) || exit 1; BAYAN_EXE=\$exe bash scripts/test.sh --only $FILT$XTRA'; exit \$LASTEXITCODE"
printf 'branch: %s\nsha: %s\nfilter: %s\ncommand: ssh %s "%s"\n' "$BR" "$SHA" "$FILT" "$H" "$CMD" > "$OUT"
scp -q "tmp/$H/$S.bundle" "$H:/$R/" >> "$OUT" 2>&1; rc=$?
[ $rc = 0 ] && { ssh "$H" "$CMD" >> "$OUT" 2>&1; rc=$?; }
echo "exit $rc" >> "$OUT"
tail -4 "$OUT"
[ $rc = 0 ] || exit $rc
grep -qx 'test: all passed' "$OUT" || { echo "wp1-test: the run did not report 'test: all passed' ($OUT)"; exit 1; }
cp "$OUT" "$CACHE"
