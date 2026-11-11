#!/usr/bin/env bash
# Cleanup for the 2026-11-12 session (plan 007 Phase B, review fix 2026-11-12-2). Worktrees whose work dev holds are
# left to merged-worktree-backlog.sh; this removes what that script does not reach:
#   - branch tmp-probe-review-2026-11-12 (a probe, already in dev);
#   - worktrees .worktrees/chore-017-preflight-sh, .worktrees/chore-017-t11-refusal-tests and their branches
#     chore/017-preflight-sh, chore/017-t11-refusal-tests (merged into feat/017-selfhost-default);
#   - /tmp scratch: /tmp/w015t8.py, /tmp/pt.out, /tmp/rt_new_51494.c;
#   - on the ghosthive VM bayan-test01: /root/work-007b, /root/007b.bundle, /root/rv007b*.bundle, /root/run-*.sh.
# ~/.claude/.worktrees/dev-land belongs to the ~/.claude repo (route-replay pilot P2); clean it with that repo's tooling
# once P2 has finished.
# Dry run by default. --execute / -e acts. The VM step also needs --delete-vm-scratch (it reaches another host).
set -euo pipefail

execute=0; vm=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-vm-scratch) vm=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
cd "$(git rev-parse --show-toplevel)"
run() { if [ "$execute" = 1 ]; then printf 'run:  %s\n' "$*"; "$@"; else printf 'would: %s\n' "$*"; fi; }

b=tmp-probe-review-2026-11-12
if git show-ref --verify --quiet "refs/heads/$b"; then
  if git merge-base --is-ancestor "$b" refs/heads/dev; then run git branch -d "$b"
  else printf 'keep: %s (not in dev)\n' "$b"; fi
fi

for n in 017-preflight-sh 017-t11-refusal-tests; do
  b=chore/$n; w="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)/.worktrees/chore-$n"
  if git show-ref --verify --quiet "refs/heads/$b" && git merge-base --is-ancestor "$b" refs/heads/feat/017-selfhost-default; then
    [ -d "$w" ] && run git worktree remove "$w"
    run git branch -d "$b"
  else printf 'keep: %s (missing or not merged)\n' "$b"; fi
done

for f in /tmp/w015t8.py /tmp/pt.out /tmp/rt_new_51494.c; do
  [ -e "$f" ] && run rm -f "$f"
done

if [ "$vm" = 1 ]; then
  run ssh ghosthive 'incus exec bayan-test01 -- sh -c "rm -rf /root/work-007b /root/007b.bundle /root/rv007b*.bundle /root/run-*.sh"'
else
  printf 'skip: VM scratch on bayan-test01 (needs --delete-vm-scratch)\n'
fi
