#!/usr/bin/env bash
# Written 2026-11-14 by the docs-tidy session (branch docs/tidy-2026-11-14).
# Removes the worktree backlog under .worktrees/: every registered worktree except the main checkout, dev and the
# ones named in KEEP. Branches are never deleted: the 2026-11-14 authors rewrite changed every SHA, so
# `git branch -d` would refuse each old branch as unmerged, and -D is not used. Each branch is printed with
# where its content stands, checked at run time:
#   in-dev     its tip is an ancestor of dev, or a dev commit has the same tree (the rewrite kept trees);
#   not-in-dev neither; the commits stay on the branch (reasons in docs/bayan-progress-log.md, 2026-11-14 tidy entry).
# A worktree with uncommitted changes is refused unless --discard-dirty is given; with it, the changes are first
# saved as tmp/worktree-patches/<name>.patch (tracked diff) and <name>.untracked.tar (untracked files) in the main
# checkout, then the worktree is removed with --force; if saving fails the worktree is left alone. A worktree holding
# ignored files (tmp/ evidence, build output), which `git worktree remove` deletes without asking, is refused unless
# --delete-ignored is given; those files are not saved.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; discard=0; ignored=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --discard-dirty) discard=1 ;;
    --delete-ignored) ignored=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
KEEP=("$main/.worktrees/dev" "$main/.worktrees/docs-tidy" "$main/.worktrees/fix-lexer-help")
failed=0
run() { if [ $execute = 1 ]; then printf 'run:   %s\n' "$*"; "$@" || { printf '  failed\n'; failed=1; }; else printf 'would: %s\n' "$*"; fi; }

# 1. collect worktrees (deepest path first, so nested worktrees go before the one holding them)
trees="$(mktemp)"; trap 'rm -f "$trees"' EXIT
git log --format=%T dev > "$trees"
list=()
while IFS= read -r line; do list+=("$line"); done < <(
  git worktree list --porcelain | awk '/^worktree /{w=substr($0,10)} /^branch /{print w "|" substr($0,19)} /^detached/{print w "|"}' \
  | awk -F'|' '{print length($1) "\t" $0}' | sort -rn | cut -f2-)

# 2. remove each
for entry in "${list[@]}"; do
  d="${entry%%|*}"; br="${entry#*|}"
  [ "$d" = "$main" ] && continue
  skip=0; for k in "${KEEP[@]}"; do [ "$d" = "$k" ] && skip=1; done
  case "$d" in "$main/.worktrees/worker-tidy-"*) skip=1 ;; esac  # this session's writers; worker.js land removes them
  [ $skip = 1 ] && { printf 'keep:  %s\n' "${d#$main/}"; continue; }
  if [ ! -d "$d" ]; then printf 'skip:  %s directory gone (pruned below)\n' "${d#$main/}"; continue; fi
  state=detached
  if [ -n "$br" ]; then
    if git merge-base --is-ancestor "$br" dev 2>/dev/null || grep -qx "$(git rev-parse "$br^{tree}")" "$trees"; then
      state=in-dev; else state=not-in-dev; fi
  fi
  printf 'tree:  %s [%s] %s\n' "${d#$main/}" "${br:-detached}" "$state"
  ign="$(git -C "$d" status --porcelain --ignored | grep '^!!' | head -5 || true)"
  if [ -n "$ign" ] && [ $ignored = 0 ]; then
    printf 'refuse: %s holds ignored files git worktree remove would delete (--delete-ignored removes them). Left alone:\n%s\n' "${d#$main/}" "$ign"
    failed=1; continue
  fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then
    if [ $discard = 0 ]; then
      printf 'refuse: %s has uncommitted changes (--discard-dirty saves and removes them). Left alone.\n' "${d#$main/}"
      failed=1; continue
    fi
    name="$(basename "$d")"; out="$main/tmp/worktree-patches"
    run mkdir -p "$out"
    if [ $execute = 1 ]; then
      if ! git -C "$d" diff --binary HEAD > "$out/$name.patch" \
         || ! git -C "$d" ls-files --others --exclude-standard -z | tar -C "$d" --null -T - -cf "$out/$name.untracked.tar"; then
        printf 'failed: saving %s; worktree left alone.\n' "${d#$main/}"; failed=1; continue
      fi
      printf 'saved: %s/%s.patch and %s.untracked.tar\n' "$out" "$name" "$name"
    else
      printf 'would: save %s changes to %s/%s.patch\n' "${d#$main/}" "$out" "$name"
    fi
    run git worktree remove --force "$d"
  elif [ -n "$ign" ]; then
    run git worktree remove --force "$d"
  else
    run git worktree remove "$d"
  fi
done
run git worktree prune

# 3. remaining state
printf '\nremaining worktrees:\n'; git worktree list
[ $failed = 0 ] || { printf '\nsome items were refused or failed; see above.\n'; exit 1; }
