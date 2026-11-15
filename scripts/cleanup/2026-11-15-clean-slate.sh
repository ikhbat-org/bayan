#!/usr/bin/env bash
# Written 2026-11-15 by the session that built plan 017 (refactor/layout-csharp-src: src/ → csharp/, selfhost/ → src/), for
# the user's "land everything you can merge back to dev and then start with a clean slate".
# Run scripts/cleanup/session-2026-11-15.sh first: it removes the 016 writer worktrees, .worktrees/main-release and that
# session's branches. This one then:
#   1. removes the worktrees .worktrees/base-dev (plan 017's dev baseline), .worktrees/dev (where plan 017 merged) and the
#      0.3.1 prep's fix-m1-relpath, fix-bash32-subst-lint, fix-review-2026-11-15-3, release-0.3.1, cleanup-slate and
#      fix-review-4, refusing one (detached or not) whose HEAD has commits not on dev, and one holding ignored files
#      other than build output (bin/, obj/, TestResults/, .cache/, .DS_Store), which `git worktree remove` deletes with
#      it, unless --delete-worktree-scratch;
#   2. puts the main checkout on dev, then lists (with --delete-old-build-output, removes) the old layout's ignored build
#      output left inside the new src/ and tests/;
#   3. with --delete-branches, deletes every local branch merged into dev (`git branch -d`, which refuses anything else);
#   4. lists the unmerged branches whose every commit is already on dev by patch (`git cherry`), for the user: a cleanup
#      script never force-deletes;
#   5. lists (with --delete-vm-ci, removes) bayan-test01:/home/bt/ci, the local-CI clones (one per commit, reached through
#      ssh ghosthive incus), refused while a ci-* unit is still active there.
# Every target is checked at run time. Dry run by default; --execute / -e acts; --delete-branches adds step 3;
# --delete-old-build-output adds the removal in step 2; --delete-vm-ci adds the removal in step 5;
# --delete-worktree-scratch lets step 1 remove a worktree with ignored scratch (tmp/, .idea/, *.user) in it.
set -euo pipefail

execute=0; branches=0; buildout=0; vmci=0; wtscratch=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-branches) branches=1 ;;
    --delete-old-build-output) buildout=1 ;;
    --delete-vm-ci) vmci=1 ;;
    --delete-worktree-scratch) wtscratch=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
failed=0
# The first ignored path under <dir> (or <dir>/<sub>) that is not build output, if any.
scratch() { git -C "$1" status --porcelain --ignored=matching --untracked-files=all -- "${2:-.}" | sed -n 's/^!! //p' \
  | grep -vE '(^|/)(bin|obj|TestResults|\.cache)/|(^|/)\.DS_Store$' | head -1 || true; }
run() { if [ $execute = 1 ]; then printf 'run:   %s\n' "$*"; "$@" || { printf '  failed\n'; failed=1; }; else printf 'would: %s\n' "$*"; fi; }

# 1. worktrees
for wt in base-dev dev fix-m1-relpath fix-bash32-subst-lint fix-review-2026-11-15-3 release-0.3.1 cleanup-slate fix-review-4; do
  d="$main/.worktrees/$wt"
  if ! git -C "$main" worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  if [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" != dev ] \
     && [ -n "$(git -C "$main" rev-list -1 "dev..$(git -C "$d" rev-parse HEAD)")" ]; then
    printf 'refuse: %s holds commits not on dev. Left alone.\n' "$wt"; failed=1; continue
  fi
  other="$(scratch "$d")"
  if [ -n "$other" ] && [ $wtscratch = 0 ]; then
    printf 'refuse: %s holds ignored files that are not build output (%s; --delete-worktree-scratch removes them with it). Left alone.\n' "$wt" "$other"; failed=1; continue
  fi
  run git -C "$main" worktree remove "$d"
done
run git -C "$main" worktree prune

# 2. the main checkout on dev
cur="$(git -C "$main" branch --show-current)"
if [ "$cur" = dev ]; then printf 'skip:  main checkout already on dev\n'
elif [ -n "$(git -C "$main" status --porcelain --untracked-files=no)" ]; then printf 'refuse: the main checkout (%s) has uncommitted changes. Left on %s.\n' "$main" "$cur"; failed=1
elif git -C "$main" worktree list --porcelain | grep -qxF 'branch refs/heads/dev'; then
  if [ $execute = 1 ]; then printf 'refuse: dev is still checked out in another worktree. Left on %s.\n' "$cur"; failed=1
  else printf 'would: git -C %s switch dev (once step 1 has freed dev)\n' "$main"; fi
else run git -C "$main" switch dev; fi

# 2b. the old layout's ignored build output: git moves tracked files only, so bin/, obj/ and .DS_Store of src/Bayan.*,
#     tests/Bayan.Tests and selfhost/ stay where they were, inside the new src/. Removed only with --delete-old-build-output, and
#     only a directory dev does not track and whose every file is ignored build output (bin/, obj/, TestResults/,
#     .cache/, .DS_Store; tmp/, .idea/, *.user and other ignored scratch refuse the directory).
for p in src/Bayan.Backend.C src/Bayan.Cli src/Bayan.Lowering src/Bayan.Semantics src/Bayan.Syntax src/Bayan.Testing \
         tests/Bayan.Tests tests/native selfhost; do
  d="$main/$p"
  [ -e "$d" ] || continue
  if [ "$(git -C "$main" branch --show-current)" != dev ]; then printf 'later: %s (checked once the main checkout is on dev)\n' "$p"; continue; fi
  if [ -n "$(git -C "$main" ls-files -- "$p" | head -1)" ]; then printf 'refuse: %s is tracked on dev. Left alone.\n' "$p"; failed=1; continue; fi
  if [ -n "$(git -C "$main" status --porcelain --untracked-files=all -- "$p" | head -1)" ]; then
    printf 'refuse: %s holds files git does not ignore. Left alone.\n' "$p"; failed=1; continue
  fi
  other="$(scratch "$main" "$p")"
  if [ -n "$other" ]; then printf 'refuse: %s holds ignored files that are not build output (%s). Left alone.\n' "$p" "$other"; failed=1; continue; fi
  if [ $buildout = 1 ]; then run rm -rf "$d"; else printf 'stale:  %s (ignored build output; --delete-old-build-output removes it)\n' "$p"; fi
done

# 3. branches merged into dev
if [ $branches = 1 ]; then
  for b in $(git -C "$main" branch --merged dev --format='%(refname:short)'); do
    case "$b" in (dev|main) continue ;; esac
    if git -C "$main" worktree list --porcelain | grep -qxF "branch refs/heads/$b"; then printf 'skip:  %s is checked out in a worktree\n' "$b"; continue; fi
    run git -C "$main" branch -d "$b"
  done
else
  printf 'note:  %s branches merged into dev; --delete-branches deletes them\n' "$(git -C "$main" branch --merged dev --format='%(refname:short)' | grep -cvxE 'dev|main' || true)"
fi

# 4. unmerged, but every commit on dev by patch: for the user to decide (git branch -D is not run here)
for b in $(git -C "$main" branch --no-merged dev --format='%(refname:short)'); do
  case "$b" in (main) continue ;; esac
  if [ -z "$(git -C "$main" cherry dev "$b" | grep '^+' || true)" ]; then printf 'patch-equivalent (not deleted): %s\n' "$b"; fi
done

# 5. bayan-test01's local-CI clones
if [ $vmci = 1 ]; then
  run ssh ghosthive "incus exec bayan-test01 -- sh -c 'if systemctl list-units --no-legend --state=active,activating \"ci-*\" | grep -q .; then echo a ci-* unit is still active; exit 3; fi; rm -rf /home/bt/ci'"
else
  printf 'stale:  bayan-test01:/home/bt/ci (local-CI clones; --delete-vm-ci removes it)\n'
fi

printf '\nremaining worktrees:\n'; git -C "$main" worktree list
printf 'main checkout: %s\n' "$(git -C "$main" branch --show-current)"
[ $execute = 1 ] || printf '\ndry run: nothing changed. --execute to act, --delete-branches to delete merged branches too,
--delete-old-build-output to remove the old layout build output, --delete-vm-ci to remove bayan-test01:/home/bt/ci,
--delete-worktree-scratch to remove worktrees that hold ignored scratch.\n'
exit $failed
