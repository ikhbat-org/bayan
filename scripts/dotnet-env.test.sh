#!/usr/bin/env bash
# Only the R27 job runs .NET (spec 019 R28, T48e). Fails when a file under scripts/ (outside scripts/cleanup/, *.md not
# run) has `dotnet` in command position, or a file under .github names install-dotnet.sh on a non-comment line, unless the
# file is on the allow list or the pending list. Command position: line start, after ; & | ( { or $(, after if/then/do/
# else/elif/while/until/exec/command/time/!, past env assignments; `dotnet`, "$dotnet" and <path>/dotnet count. Comment
# lines and stubs that write a fake dotnet (`cat > $d/dotnet`) are not hits. A pending entry with no hit fails, so the
# list only shrinks. A self-test on a fixture tree under tmp/ runs first. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

allow="scripts/ci/install-dotnet.sh scripts/ci/install-dotnet.test.sh scripts/ci/sdk-patch-check.sh
scripts/ci/sdk-patch-check.test.sh scripts/ci/ddc.sh scripts/ci/ddc.test.sh .github/workflows/ddc.yml"
# One per line: <file> <task that removes its .NET call>.
pending=""

cmd_re='(^|[;&|({]|\$\(|(^|[[:space:]])(if|then|do|else|elif|while|until|exec|command|time|!)[[:space:]])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*"?\$?([^[:space:]";&|()]*/)?dotnet"?([[:space:]]|$)'

# hits ROOT: the files with a hit, relative to ROOT.
hits() {
  local f
  (cd "$1" && find scripts -type f ! -path 'scripts/cleanup/*' ! -name '*.md' | sort) | while IFS= read -r f; do
    grep -vE '^[[:space:]]*#' "$1/$f" | grep -qE "$cmd_re" && echo "$f"
  done
  [ -d "$1/.github" ] || return 0
  (cd "$1" && find .github -type f | sort) | while IFS= read -r f; do
    grep -vE '^[[:space:]]*#' "$1/$f" | grep -q 'install-dotnet\.sh' && echo "$f"
  done
}

# check ROOT ALLOW PENDING: one FAIL line per verdict; exit 1 on any.
check() {
  local h f bad=0
  h="$(hits "$1")"
  for f in $h; do
    case " $(echo $2) " in (*" $f "*) continue ;; esac
    echo "$3" | grep -q "^$f " && continue
    echo "FAIL: $f runs .NET and is not on the allow list (spec 019 R28)"; bad=1
  done
  while read -r f t; do
    [ -n "$f" ] || continue
    echo "$h" | grep -qxF "$f" || { echo "FAIL: pending $f ($t) has no hit; remove it from the pending list"; bad=1; }
  done <<EOF
$3
EOF
  return $bad
}

fail=0
ok() { [ "$2" = "$3" ] || { echo "FAIL self-test: $1: got '$2', want '$3'" >&2; fail=1; }; }
fx="$root/tmp/dotnet-env-test"
rm -rf "$fx"; mkdir -p "$fx/scripts/a" "$fx/scripts/ci" "$fx/scripts/cleanup" "$fx/.github/workflows"
printf '#!/usr/bin/env bash\nset -e\n%s build x\n' dotnet > "$fx/scripts/a/caller.sh"
printf '#!/usr/bin/env bash\nif ! X=1 %s test y; then exit 1; fi\n' dotnet > "$fx/scripts/a/iftest.sh"
printf '#!/usr/bin/env bash\n# %s build x\n  # %s test y\n' dotnet dotnet > "$fx/scripts/a/comment.sh"
printf '#!/usr/bin/env bash\ncat > "$d/dotnet" <<S\necho "%s called" >&2; exit 1\nS\n' dotnet > "$fx/scripts/a/stub.test.sh"
printf '#!/usr/bin/env bash\n"$%s" publish x\n' dotnet > "$fx/scripts/ci/ddc.sh"
printf '#!/usr/bin/env bash\n%s test\n' dotnet > "$fx/scripts/cleanup/old.sh"
printf 'steps:\n  - run: bash scripts/ci/%s.sh "$T"\n' install-dotnet > "$fx/.github/workflows/ddc.yml"
printf 'steps:\n  - run: bash scripts/ci/%s.sh "$T"\n' install-dotnet > "$fx/.github/workflows/other.yml"
printf '# the bump edits scripts/ci/%s.sh\non: push\n' install-dotnet > "$fx/.github/workflows/note.yml"

out="$(check "$fx" "$allow" "")"; rc=$?
ok "verdicts exit" "$rc" "1"
ok "unlisted caller" "$(echo "$out" | grep -c '^FAIL: scripts/a/caller.sh ')" "1"
ok "caller after if !" "$(echo "$out" | grep -c '^FAIL: scripts/a/iftest.sh ')" "1"
ok "comment is no hit" "$(echo "$out" | grep -c 'comment.sh')" "0"
ok "failing stub is no hit" "$(echo "$out" | grep -c 'stub.test.sh')" "0"
ok "allow-listed ddc.sh" "$(echo "$out" | grep -c 'ddc.sh')" "0"
ok "scripts/cleanup excluded" "$(echo "$out" | grep -c 'cleanup')" "0"
ok "allow-listed ddc.yml" "$(echo "$out" | grep -c 'ddc.yml')" "0"
ok "unlisted workflow step" "$(echo "$out" | grep -c '^FAIL: .github/workflows/other.yml ')" "1"
ok "workflow comment is no hit" "$(echo "$out" | grep -c 'note.yml')" "0"
ok "three verdicts" "$(echo "$out" | grep -c '^FAIL')" "3"
p="scripts/a/caller.sh T1
scripts/a/iftest.sh T2
.github/workflows/other.yml T3"
out="$(check "$fx" "$allow" "$p")"; rc=$?
ok "pending covers its hits" "$rc $out" "0 "
out="$(check "$fx" "$allow" "$p
scripts/a/comment.sh T9")"; rc=$?
ok "stale pending fails" "$rc $out" "1 FAIL: pending scripts/a/comment.sh (T9) has no hit; remove it from the pending list"
rm -rf "$fx"
[ "$fail" = 0 ] || { echo "dotnet-env.test: self-test FAILED" >&2; exit 1; }

check "$root" "$allow" "$pending" >&2 || exit 1
echo PASS
