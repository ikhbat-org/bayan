#!/usr/bin/env bash
# Cleanup for the 2026-11-12 session (plan 007 Phase B, review fix 2026-11-12-2). Worktrees whose work dev holds are
# left to merged-worktree-backlog.sh; this removes what that script does not reach:
#   - branch tmp-probe-review-2026-11-12 (a probe, already in dev);
#   - worktrees .worktrees/chore-017-preflight-sh, .worktrees/chore-017-t11-refusal-tests and their branches
#     chore/017-preflight-sh, chore/017-t11-refusal-tests (merged into feat/017-selfhost-default);
#   - worktree .worktrees/worker-017-t14, branch chore/worker-017-t14 and key 017-t14 (first T14 attempt, superseded);
#   - worktree .worktrees/worker-017-t14b, branch chore/worker-017-t14b, keys 017-t14b, 017-t14b-review, 017-t14--gate-review (T14, landed);
#   - worktree .worktrees/worker-017-t17, branch chore/worker-017-t17, keys 017-t17, 017-t17-review (T17, landed);
#   - worktree .worktrees/fix-017-preflight-yml and branch fix/017-preflight-yml (merged into feat/017-selfhost-default);
#   - /tmp scratch: /tmp/w015t8.py, /tmp/pt.out, /tmp/rt_new_51494.c;
#   - on the ghosthive VM bayan-test01: /root/work-007b, /root/007b.bundle, /root/rv007b*.bundle, /root/run-*.sh.
# ~/.claude/.worktrees/dev-land belongs to the ~/.claude repo (route-replay pilot P2); clean it with that repo's tooling
# once P2 has finished.
# Dry run by default. --execute / -e acts. The VM step also needs --delete-vm-scratch (it reaches another host);
# the unmerged chore/worker-017-t14 branch also needs --drop-unmerged-t14.
set -euo pipefail

execute=0; vm=0; dropt14=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-vm-scratch) vm=1 ;;
    --drop-unmerged-t14) dropt14=1 ;;
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

# the first T14 attempt (8a7ea54e, written before T11/T13 landed), superseded by key 017-t14b; its diff is saved in
# tmp/017-t14-old-attempt.diff. Unmerged by design, so it needs -D; the worker key is retired through worker.js.
b=chore/worker-017-t14; w="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)/.worktrees/worker-017-t14"
if git show-ref --verify --quiet "refs/heads/$b" && [ "$(git rev-parse "$b")" = "$(git rev-parse 8a7ea54e)" ]; then
  run deno run -A "$HOME/.claude/tools/worker.js" retire 017-t14
  [ -d "$w" ] && run git worktree remove "$w"
  if [ "$dropt14" = 1 ]; then run git branch -D "$b"
  else printf 'skip: git branch -D %s (unmerged; needs --drop-unmerged-t14)\n' "$b"; fi
else printf 'keep: %s (missing or moved past 8a7ea54e)\n' "$b"; fi

# the second T14 attempt, landed into feat/017-selfhost-default by land.sh (7d9e7aa6); land.sh keeps the worker
# worktree and keys, so retire them here. The branch is merged, so -d.
b=chore/worker-017-t14b; w="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)/.worktrees/worker-017-t14b"
if git show-ref --verify --quiet "refs/heads/$b" && git merge-base --is-ancestor "$b" refs/heads/feat/017-selfhost-default; then
  for k in 017-t14b 017-t14b-review 017-t14--gate-review; do run deno run -A "$HOME/.claude/tools/worker.js" retire "$k"; done
  [ -d "$w" ] && run git worktree remove "$w"
  run git branch -d "$b"
else printf 'keep: %s (missing or not merged)\n' "$b"; fi

# T17, landed into feat/017-selfhost-default by land.sh (7b50c9e9), and the preflight/wave-brief .yml fix merged there
root="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
b=chore/worker-017-t17; w="$root/.worktrees/worker-017-t17"
if git show-ref --verify --quiet "refs/heads/$b" && git merge-base --is-ancestor "$b" refs/heads/feat/017-selfhost-default; then
  for k in 017-t17 017-t17-review; do run deno run -A "$HOME/.claude/tools/worker.js" retire "$k"; done
  [ -d "$w" ] && run git worktree remove "$w"
  run git branch -d "$b"
else printf 'keep: %s (missing or not merged)\n' "$b"; fi
b=fix/017-preflight-yml; w="$root/.worktrees/fix-017-preflight-yml"
if git show-ref --verify --quiet "refs/heads/$b" && git merge-base --is-ancestor "$b" refs/heads/feat/017-selfhost-default; then
  [ -d "$w" ] && run git worktree remove "$w"
  run git branch -d "$b"
else printf 'keep: %s (missing or not merged)\n' "$b"; fi

for f in /tmp/w015t8.py /tmp/pt.out /tmp/rt_new_51494.c; do
  [ -e "$f" ] && run rm -f "$f"
done

if [ "$vm" = 1 ]; then
  run ssh ghosthive 'incus exec bayan-test01 -- sh -c "rm -rf /root/work-007b /root/007b.bundle /root/rv007b*.bundle /root/run-*.sh"'
else
  printf 'skip: VM scratch on bayan-test01 (needs --delete-vm-scratch)\n'
fi
