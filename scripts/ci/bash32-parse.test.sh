#!/usr/bin/env bash
# Every tracked shell script passes `bash -n` under macOS's /bin/bash 3.2, which rejects some bare `pat)` case arms
# inside `$( … )` (write `(pat)`) that newer bash accepts. -n misses the ones 3.2 parses only at run time
# (package.test.sh:83 was one); the macOS ci job running each script catches those. Skipped where /bin/bash is not 3.x.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
b="${BAYAN_BASH32:-/bin/bash}"
case "$("$b" -c 'echo ${BASH_VERSINFO[0]}' 2>/dev/null || true)" in
  (3) ;;
  (*) echo "SKIP: $b is not bash 3"; exit 0 ;;
esac
bad=0
while IFS= read -r f; do
  "$b" -n "$root/$f" 2>/dev/null || { echo "FAIL: $f does not parse under bash 3.2:"; "$b" -n "$root/$f" 2>&1 | head -2 || true; bad=1; }
done < <(git -C "$root" ls-files '*.sh')
[ $bad = 0 ] && echo PASS || exit 1
