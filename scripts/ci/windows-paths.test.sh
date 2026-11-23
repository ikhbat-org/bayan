#!/usr/bin/env bash
# Every tracked path is one Windows can check out (spec 019 T17e: `git clone` on Windows stopped at "invalid path" on case directories
# whose names ended in a dot or a space). A path component Windows refuses: one ending in a dot or a space; one holding < > : " | ? *, a
# backslash or a control character; or a reserved device name, CON, PRN, AUX, NUL, COM1-9 or LPT1-9, with or without an extension, in any
# case. Checks the checker on a fixture list first, then the paths `git ls-files` lists; a refused path fails the test naming it. bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }

# refused: the lines of stdin (paths, one per line) that name a path Windows refuses
refused() {
  LC_ALL=C awk '{ n = split($0, c, "/")
      for (i = 1; i <= n; i++) {
        if (c[i] ~ /[. ]$/ || c[i] ~ /[<>:"|?*\\]/ || c[i] ~ /[[:cntrl:]]/ ||
            toupper(c[i]) ~ /^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$/) { print; next }
      }
    }'
}

bad="a/b./c
a/b /c
a/end.
a/x:y
a/q?
a/con.txt
a/Lpt3
a/tab$(printf '\t')here"
good='a/b.c/d
a/.hidden
a/b c/d
a/console.txt
a/com10'
[ "$(refused <<< "$bad")" = "$bad" ] || fail "a refused fixture path passed: $(refused <<< "$bad" | diff <(printf '%s\n' "$bad") - || true)"
[ -z "$(refused <<< "$good")" ] || fail "an allowed fixture path was refused: $(refused <<< "$good")"

out="$(cd "$root" && git ls-files -z | tr '\0' '\n' | refused)"
[ -z "$out" ] || fail "tracked paths Windows refuses:
$out"
echo "windows-paths.test: ok"
