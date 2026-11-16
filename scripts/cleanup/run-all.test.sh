#!/bin/bash
# Test for run-all.sh (2026-11-16): fake cleanup dir (CLEANUP_DIR) and a fake dev checkout in a temp dir.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
runner="$here/run-all.sh"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
fails=0
ok() { printf 'ok:   %s\n' "$1"; }
bad() { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (want [$3], got [$2])"; fi; }

repo="$t/repo"; mkdir -p "$repo"
git -C "$repo" init -q -b dev
d="$t/cleanup"; mkdir -p "$d"; log="$t/argv"

# fake scripts record argv; parser shapes copied from the real ones
mk() { # name flags-case-lines exit-code extra-output
  cat >"$d/$1" <<EOF
#!/bin/bash
printf '%s %s\n' "$1" "\$*" >>"$log"
for a in "\$@"; do
  case "\$a" in
    --execute|-e) ;;
$2
    *) printf 'unknown flag: %s\n' "\$a"; exit 2 ;;
  esac
done
$4
exit $3
EOF
}
mk 001-a.sh '    --delete-scratch) ;;' 0 ''
mk 002-b.sh '    --delete-worktree-scratch) ;;
    --delete-remote-branches) ;;' 0 ''
mk 2026-11-15-c.sh '    --delete-branches) ;;' 1 'printf "refuse: not on dev\n"'
mk named.sh '' 0 ''
mk e-only.sh '' 0 ''
sed -i.bak 's/--execute|-e) ;;/-e) ;;/' "$d/e-only.sh"; rm -f "$d/e-only.sh.bak"
printf 'x\n' >"$d/001-a.test.sh"; printf 'x\n' >"$d/run-all.sh"; printf 'x\n' >"$d/022-w.ps1"

run() { : >"$log"; (cd "$repo" && CLEANUP_DIR="$d" /bin/bash "$runner" "$@" 2>&1); }

out="$(run)"; rc=$?
check "dry run exits 0 despite a failing script" "$rc" 0
check "order and skips" "$(cut -d' ' -f1 "$log" | tr '\n' ' ')" "001-a.sh 002-b.sh 2026-11-15-c.sh e-only.sh named.sh "
check "dry run passes no act flag" "$(grep -c -e '-e\|--execute' "$log")" 0
case "$out" in *"--- named.sh: exit 0"*"non-zero: 1"*) ok "runs after a failure; summary count" ;; *) bad "summary: $out" ;; esac
case "$out" in *"refuse: not on dev"*) ok "refuse line in summary" ;; *) bad "refuse line" ;; esac
case "$out" in *"pwsh -NoProfile scripts/cleanup/022-w.ps1"*) ok ".ps1 listed" ;; *) bad ".ps1 listed" ;; esac
case "$out" in *"022-w.ps1 -Execute"*) bad "-Execute shown on a dry run" ;; *) ok "no -Execute on dry run" ;; esac
[ -z "$(grep 022-w "$log")" ] && ok ".ps1 not run" || bad ".ps1 run"

out="$(run -e)"; rc=$?
check "execute exits 1 on a failure" "$rc" 1
check "each script gets its own act spelling" "$(grep -c -e '^e-only.sh -e$' "$log")$(grep -c -e '^001-a.sh --execute$' "$log")" 11
case "$out" in *"022-w.ps1 -Execute"*) ok "-Execute shown" ;; *) bad "-Execute shown" ;; esac

run --delete-scratch --delete-remote-branches >/dev/null
check "grouped flag reaches only accepting scripts" "$(tr '\n' '|' <"$log")" "001-a.sh --delete-scratch|002-b.sh --delete-worktree-scratch --delete-remote-branches|2026-11-15-c.sh |e-only.sh |named.sh |"
run --delete-scratch --delete-branches >/dev/null
check "member flags of different groups" "$(grep -c -e '--delete-branches' "$log")$(grep -c -e '--delete-worktree-scratch' "$log")" 11

out="$(run --bogus)"; rc=$?
check "unknown flag exits 2" "$rc" 2
check "unknown flag runs nothing" "$(wc -l <"$log" | tr -d ' ')" 0

run --only '00*' --only 'named*' >/dev/null
check "--only" "$(cut -d' ' -f1 "$log" | tr '\n' ' ')" "001-a.sh 002-b.sh named.sh "
out="$(run -e --delete-scratch --list)"; rc=$?
check "--list runs nothing" "$(wc -l <"$log" | tr -d ' ')" 0
case "$out" in *"001-a.sh --execute --delete-scratch"*"022-w.ps1 (not run"*) ok "--list shows flags and .ps1" ;; *) bad "--list: $out" ;; esac

# no checkout on dev
git -C "$repo" symbolic-ref HEAD refs/heads/other
out="$(run)"; rc=$?; check "no dev: dry run exits 0" "$rc" 0
case "$out" in *"no checkout has dev"*) ok "no dev message" ;; *) bad "no dev message" ;; esac
out="$(run -e)"; rc=$?; check "no dev: execute exits 1" "$rc" 1

[ $fails -eq 0 ] && { echo "all passed"; exit 0; }
echo "$fails failed"; exit 1
