#!/usr/bin/env bash
# Cleanup for plan 008 (docs/plans/2026-11-12-008-release-prep-and-process.md) and the review fixes of 2026-11-12.
# Each branch below is removed only once dev contains it; the matching worktree goes first:
#   - feat/008-release-prep-and-process and its worktree .worktrees/feat-030-release-prep;
#   - feat/030-release-prep (the worktree's first name, superseded by feat/008);
#   - chore/worker-008-{w1,w2,w3,w4,w5,w6,c} (landed into feat/008; land removed their worktrees and keys);
#   - fix/review-2026-11-12-{1..5} and worktrees .worktrees/fix-review-2026-11-12-{1..5}
#     (-2 holds chore/cleanup-2026-11-12-vm, removed only when that branch is in dev too);
#   - /tmp scratch: /tmp/w1-flood-*.txt (W1 writer);
#   - extrode-fleet01 (ghosthive) host /root: feat008.bundle, full-008.sh, w6-check.sh, rerun-fail-9af7.sh, rerun2-9af7.sh,
#     run-full-9af7.sh, dev-9af76107.bundle;
#   - VM bayan-test01: /root/work-full, /root/dev-9af76107.bundle, /root/run-full-9af7.sh, /root/full-9af7.*, /root/rerun*-9af7.*,
#     /home/bt/{r-9af7,w6,f008-*,feat008.bundle,w6-check.sh,full-008.sh,run.sh,w6*.log,w6.out,full-008.*}. User bt stays: shard-test.sh uses it.
# Dry run by default. --execute / -e acts. The host and VM steps also need --delete-remote-scratch (they reach another host).
set -euo pipefail

execute=0; remote=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-remote-scratch) remote=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
root="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
cd "$root"
run() { if [ "$execute" = 1 ]; then printf 'run:  %s\n' "$*"; "$@"; else printf 'would: %s\n' "$*"; fi; }
# `git branch -d` judges "merged" against HEAD; report a refusal and go on.
del() { if [ "$execute" = 1 ]; then printf 'run:  git branch -d %s\n' "$1"; git branch -d "$1" || printf 'keep: %s (git branch -d refused; rerun from the dev checkout)\n' "$1"
  else printf 'would: git branch -d %s\n' "$1"; fi; }
in_dev() { git show-ref --verify --quiet "refs/heads/$1" && git merge-base --is-ancestor "$1" refs/heads/dev; }
# the worktree path that has branch $1 checked out, if any
wt_of() { git worktree list --porcelain | awk -v b="refs/heads/$1" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}'; }
drop() {
  if in_dev "$1"; then
    w=$(wt_of "$1")
    if [ -n "$w" ]; then run git worktree remove "$w" || { printf 'keep: %s (worktree %s not removed)\n' "$1" "$w"; return 0; }; fi
    del "$1"
  else printf 'keep: %s (missing or not in dev)\n' "$1"; fi
}

for b in chore/worker-008-w1 chore/worker-008-w2 chore/worker-008-w3 chore/worker-008-w4 chore/worker-008-w5 chore/worker-008-w6 chore/worker-008-c \
         feat/008-release-prep-and-process feat/030-release-prep chore/cleanup-2026-11-12-vm \
         fix/review-2026-11-12-1 fix/review-2026-11-12-2 fix/review-2026-11-12-3 fix/review-2026-11-12-4 fix/review-2026-11-12-5; do
  drop "$b"
done

for f in /tmp/w1-flood-*.txt; do
  [ -e "$f" ] && run rm -f "$f"
done

# Fails closed: an unreachable host, an unknown VM state or a failed unit listing skips the remote steps.
state=""; units=""
if [ "$remote" = 1 ]; then
  state=$(ssh ghosthive 'incus list bayan-test01 -c s -f csv' 2>/dev/null) || state=unreachable
  if [ "$state" = RUNNING ]; then
    units=$(ssh ghosthive 'incus exec bayan-test01 -- sh -c "systemctl list-units --state=active,activating --no-legend --plain; if pgrep -u bt -x dotnet >/dev/null; then echo full-008-dotnet; fi"' 2>/dev/null) || state=unreachable
  fi
fi
if [ "$remote" = 1 ] && [ "$state" != RUNNING ] && [ "$state" != STOPPED ]; then
  printf 'skip: bayan-test01 state is "%s" (ghosthive unreachable or VM unknown); rerun later\n' "$state"
elif [ "$remote" = 1 ] && grep -qE '^ *(full-008|shard-|w6-check|cap-check)' <<< "$units"; then
  printf 'skip: a test job is running on bayan-test01; rerun when it has finished\n'
elif [ "$remote" = 1 ]; then
  run ssh ghosthive 'cd /root && rm -f feat008.bundle full-008.sh w6-check.sh cap-check.sh cap-fix.sh rerun-fail-9af7.sh rerun2-9af7.sh run-full-9af7.sh dev-9af76107.bundle'
  # A VM that was running is left running (another job may start on it); one this step starts is stopped again.
  if [ "$state" = STOPPED ]; then run ssh ghosthive 'incus start bayan-test01'; fi
  run ssh ghosthive 'incus exec bayan-test01 -- sh -c "rm -rf /root/work-full /root/dev-9af76107.bundle /root/run-full-9af7.sh /root/full-9af7.* /root/rerun*-9af7.* /home/bt/r-9af7 /home/bt/w6 /home/bt/rc /home/bt/feat008.bundle /home/bt/w6-check.sh /home/bt/cap-check.sh /home/bt/cap-fix.sh /home/bt/full-008.sh /home/bt/run.sh /home/bt/w6*.log /home/bt/w6.out /home/bt/cap-*.out /home/bt/cap-*.log /home/bt/*.bin /home/bt/*.err /home/bt/full-008.* /home/bt/f008-*"'
  if [ "$state" = STOPPED ]; then run ssh ghosthive 'incus stop bayan-test01'; fi
else
  printf 'skip: extrode-fleet01 and bayan-test01 scratch (needs --delete-remote-scratch)\n'
fi
