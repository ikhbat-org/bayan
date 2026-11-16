#!/bin/bash
# Runs every scripts/cleanup/*.sh (not *.test.sh, not itself) in LC_ALL=C ls order, each as `bash <script> [flags]`,
# from the root of the checkout that has `dev` checked out (found with `git worktree list --porcelain`; the scripts
# are the ones in that checkout, not this file's directory). Written 2026-11-16. Never run by an agent.
#
#   scripts/cleanup/run-all.sh                       dry run: every script bare, changes nothing
#   scripts/cleanup/run-all.sh -e [grouped flags]    --execute / -e: every script is passed the spelling it accepts
#   scripts/cleanup/run-all.sh --only '<glob>' ...   only scripts whose file name matches (repeatable)
#   scripts/cleanup/run-all.sh --list                print the scripts and the flags each would receive, run nothing
#
# A runner flag is passed to a script only as the script flags that script's own argument parser accepts (the script
# is read for them), so no script sees a flag it does not know. Grouped flags are passed on a dry run too, so the dry
# run shows what the execute run would do. One script failing does not stop the rest. .ps1 scripts are not run: the
# summary prints the pwsh command for wp1. Exit: 1 only with --execute and a script exited non-zero, or --execute
# with no checkout on dev; 2 for a bad runner flag; a dry run is 0.
#
# Runner flag                     -> script flag (scripts that accept it)
#   --delete-scratch              local scratch and ignored build output inside worktrees
#                                    --delete-scratch (001-017, 023, leak-audit, q31-followups, unattended-late)
#                                    --delete-worktree-scratch (018, 2026-11-15-clean-slate, merged-worktree-backlog)
#                                    --delete-build-output (022-style-guide)
#                                    --delete-ignored (2026-11-14-worktree-backlog)
#                                    --delete-old-build-output (2026-11-15-clean-slate)
#                                    --remove-ignored-build-output (022-self-hosted-emitter)
#                                    --delete-replay-scratch (route-replay-p2-scratch)
#   --delete-remote-scratch       scratch on other hosts over ssh (wp1, wlt1, the VM bayan-test01)
#                                    --delete-remote (016-spec-013-and-011-draft)
#                                    --delete-remote-scratch (2026-11-12-008-release-prep)
#                                    --delete-vm-scratch (2026-11-12-session-scratch, q31-followups)
#                                    --delete-vm-ci (2026-11-15-clean-slate)
#                                    --remove-remote (q31-arena-plans, q31-plan-014, session-2026-11-13/14/15)
#                                    --remove-docker-image (016-spec-013-and-011-draft)
#   --discard-dirty               loses uncommitted edits in worktrees
#                                    --discard-worktree-changes (018-superseded-branches)
#                                    --discard-dirty (2026-11-14-worktree-backlog)
#   --delete-branches             deletes local branches beyond what `git branch -d` allows
#                                    --delete-branches (2026-11-15-clean-slate)
#                                    --drop-unmerged-t14 (2026-11-12-session-scratch; uses `git branch -D`)
#   --delete-remote-branches      OUTWARD-FACING: deletes branches on origin (`git push origin --delete`)
#                                    --delete-remote-branches (019-merged-branches)
#   --remove-dead-mutation-exempt `git rm` (staged, not committed) of the dead mutation-exempt files
#                                    --remove-dead-mutation-exempt (022-self-hosted-emitter)
# The script flags are the ones in the scripts' parsers on 2026-11-16; the runner reads each script, so a new
# script that spells one of them is picked up, but a new spelling needs a line in members() below.
set -uo pipefail

usage() {
  printf 'usage: run-all.sh [-e|--execute] [--delete-scratch] [--delete-remote-scratch] [--discard-dirty]\n'
  printf '                  [--delete-branches] [--delete-remote-branches] [--remove-dead-mutation-exempt]\n'
  printf '                  [--only <glob>]... [--list]\n'
}

# runner flag -> script flags it stands for
members() {
  case "$1" in
    --delete-scratch) echo "--delete-scratch --delete-worktree-scratch --delete-build-output --delete-ignored --delete-old-build-output --remove-ignored-build-output --delete-replay-scratch" ;;
    --delete-remote-scratch) echo "--delete-remote --delete-remote-scratch --delete-vm-scratch --delete-vm-ci --remove-remote --remove-docker-image" ;;
    --discard-dirty) echo "--discard-worktree-changes --discard-dirty" ;;
    --delete-branches) echo "--delete-branches --drop-unmerged-t14" ;;
    --delete-remote-branches) echo "--delete-remote-branches" ;;
    --remove-dead-mutation-exempt) echo "--remove-dead-mutation-exempt" ;;
  esac
}

execute=0; list=0; only=""; groups=""
while [ $# -gt 0 ]; do
  case "$1" in
    --execute|-e) execute=1 ;;
    --list) list=1 ;;
    --only) [ $# -ge 2 ] || { usage; exit 2; }; only="$only$2
"; shift ;;
    --delete-scratch|--delete-remote-scratch|--discard-dirty|--delete-branches|--delete-remote-branches|--remove-dead-mutation-exempt)
      groups="$groups $1" ;;
    *) usage; exit 2 ;;
  esac
  shift
done

# does script $1 accept flag $2 (a case pattern in its parser, alone or among |-joined alternatives)
accepts() { grep -Eq -- "^[[:space:]]*(.*\\|)?$2(\\|.*)?\\)" "$1"; }

# the flags script $1 receives
flags_for() {
  local s="$1" out="" g m
  if [ $execute -eq 1 ]; then
    if accepts "$s" --execute; then out="--execute"; elif accepts "$s" -e; then out="-e"; fi
  fi
  for g in $groups; do
    for m in $(members "$g"); do
      if accepts "$s" "$m"; then out="$out $m"; fi
    done
  done
  printf '%s\n' "${out# }"
}

selected() {
  [ -n "$only" ] || return 0
  local g
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    case "$1" in $g) return 0 ;; esac
  done <<EOF
$only
EOF
  return 1
}

# the checkout with dev checked out
devroot=""; cur=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) cur="${line#worktree }" ;;
    "branch refs/heads/dev") devroot="$cur"; break ;;
  esac
done <<EOF
$(git worktree list --porcelain 2>/dev/null)
EOF
if [ -z "$devroot" ]; then
  printf 'no checkout has dev checked out; check dev out in a worktree and run again.\n'
  [ $execute -eq 1 ] && exit 1
  exit 0
fi

dir="${CLEANUP_DIR:-$devroot/scripts/cleanup}"
sh_list=""; ps_list=""
for f in $(cd "$dir" && LC_ALL=C ls); do
  case "$f" in
    *.test.sh|*.test.ps1|run-all.sh) continue ;;
    *.sh) selected "$f" && sh_list="$sh_list $f" ;;
    *.ps1) selected "$f" && ps_list="$ps_list $f" ;;
  esac
done

if [ $list -eq 1 ]; then
  printf 'dev checkout: %s\n' "$devroot"
  for f in $sh_list; do printf '%s %s\n' "$f" "$(flags_for "$dir/$f")"; done
  for f in $ps_list; do printf '%s (not run; pwsh on wp1)\n' "$f"; done
  exit 0
fi

cd "$devroot" || exit 1
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
summary=""; bad=0
for f in $sh_list; do
  fl="$(flags_for "$dir/$f")"
  printf '=== %s %s\n' "$f" "$fl"
  bash "$dir/$f" $fl >"$tmp" 2>&1; rc=$?
  cat "$tmp"
  printf -- '--- %s: exit %s\n' "$f" "$rc"
  line="$(printf '%-48s exit %s' "$f" "$rc")"
  if [ $rc -ne 0 ]; then
    bad=$((bad + 1))
    ref="$(grep -m1 '^refuse' "$tmp")"
    [ -n "$ref" ] && line="$line  $ref"
  fi
  summary="$summary$line
"
done

printf '\n=== summary (%s)\n' "$([ $execute -eq 1 ] && echo execute || echo 'dry run')"
printf '%s' "$summary"
printf 'non-zero: %s\n' "$bad"
for f in $ps_list; do
  printf 'not run (Windows): on wp1: pwsh -NoProfile scripts/cleanup/%s%s\n' "$f" "$([ $execute -eq 1 ] && echo ' -Execute')"
done
[ $execute -eq 1 ] && [ $bad -gt 0 ] && exit 1
exit 0
