#!/usr/bin/env bash
# Two checks over every tracked shell script, for macOS's /bin/bash 3.2:
#   1. static, on every OS: a `case` inside `$( … )`, `<( … )` or `>( … )` writes each pattern as `(pat)`. Bash 3.2 parses a
#      substitution's body only when it runs, and a bare `pat)` there closes the substitution: `bash -n` passes, the script dies
#      when it reaches that line (package.test.sh:83 failed the macOS ci job this way, run 43645701470; shard-test.test.sh:49
#      and guard.sh had it too).
#   2. `bash -n` under /bin/bash 3.x (BAYAN_BASH32 overrides the path), for everything else 3.2 rejects; skipped elsewhere.
# The first check is tested on fixtures below before it scans the repo.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# case_in_subst FILE... -> FILE:LINE for each case arm inside a substitution whose pattern does not start with "("
case_in_subst() {
  LC_ALL=C awk '
    FNR == 1 && NR > 1 { scan(prev) }
    FNR == 1 { s = ""; prev = FILENAME }
    { s = s $0 "\n" }
    END { if (NR > 0) scan(prev) }
    function word(at, w,   b, a) {  # w starts at index at, as a whole shell word
      if (substr(s, at, length(w)) != w) return 0
      b = at > 1 ? substr(s, at - 1, 1) : " "; a = substr(s, at + length(w), 1)
      return b ~ /[ \t\n;|&(]/ && a ~ /[ \t\n;|&)]/
    }
    function lineof(at,   t) { t = substr(s, 1, at); return gsub(/\n/, "", t) + 1 }
    function skipws(i) { while (i <= n && (i in skip || substr(s, i, 1) ~ /[ \t\n]/)) i = i in skip ? skip[i] : i + 1; return i }
    function comment(i) { return substr(s, i, 1) == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t\n;]/) }
    function eol(i) { while (i <= n && substr(s, i, 1) != "\n") i++; return i }
    # lt(i): s[i] starts "<<"; a heredoc (not "<<<") records its body as a skip from the line after it to its delimiter
    # line. With no delimiter line it is not a heredoc (a shift such as $((1 << 2)) or <<=) and nothing is skipped.
    function lt(i) { if (substr(s, i + 2, 1) == "<") return i + 2; heredoc(i); return i + 1 }
    function heredoc(i,   dash, w, c, at, ln, end) {
      i += 2; if (substr(s, i, 1) == "-") { dash = 1; i++ }
      while (substr(s, i, 1) ~ /[ \t]/) i++
      w = ""
      for (; i <= n; i++) {
        c = substr(s, i, 1)
        if (c ~ /[ \t\n;|&<>()]/) break
        if (c != "\047" && c != "\"" && c != "\\") w = w c
      }
      if (w == "") return
      at = hnext > i ? hnext : eol(i) + 1
      for (end = at; end <= n; end = eol(end) + 1) {
        ln = substr(s, end, eol(end) - end); if (dash) sub(/^\t+/, "", ln)
        if (ln == w) break
      }
      if (end <= n) { skip[at] = eol(end); hnext = eol(end) + 1 }
    }
    function arms(i, f) {  # i just past "case": check every arm up to esac, return the index past esac
      while (i <= n && !word(i, "in")) i++
      i = skipws(i + 2)
      while (i <= n) {
        if (comment(i)) { i = skipws(eol(i)); continue }
        if (word(i, "esac")) return i + 4
        if (substr(s, i, 1) != "(") { print f ":" lineof(i); bad++ }
        i = armend(i, f)
      }
      return i
    }
    function armend(i, f,   c, q) {  # from the pattern of an arm: the index past its ";;", ";&" or ";;&", or the index of the closing esac
      q = ""
      for (; i <= n; i++) {
        if (i in skip) { i = skip[i]; continue }
        c = substr(s, i, 1)
        if (q == "\047") { if (c == "\047") q = ""; continue }
        if (c == "\\") { i++; continue }
        if (q == "" && c == "\047") { q = c; continue }
        if (c == "\"") { q = q == "\"" ? "" : "\""; continue }
        if (q != "") continue
        if (comment(i)) { i = eol(i); continue }
        if (c == "<" && substr(s, i + 1, 1) == "<") { i = lt(i); continue }
        if (c == ";" && substr(s, i + 1, 1) == ";") { i = skipws(i + 2); if (substr(s, i, 1) == "&") i = skipws(i + 1); return i }
        if (c == ";" && substr(s, i + 1, 1) == "&") return skipws(i + 2)
        if (word(i, "case")) { i = arms(i + 4, f) - 1; continue }
        if (word(i, "esac")) return i
      }
      return i
    }
    function scan(f,   i, c, d, q, pc) {
      n = length(s); d = 0; q[0] = ""; pc[0] = 0; hnext = 0; split("", skip)
      for (i = 1; i <= n; i++) {
        if (i in skip) { i = skip[i]; continue }
        c = substr(s, i, 1)
        if (q[d] == "\047") { if (c == "\047") q[d] = ""; continue }
        if (c == "\\") { i++; continue }
        if (q[d] == "" && c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t\n;]/)) { while (i <= n && substr(s, i, 1) != "\n") i++; continue }
        if (q[d] == "" && c == "\047") { q[d] = c; continue }
        if (q[d] == "" && c == "<" && substr(s, i + 1, 1) == "<") { i = lt(i); continue }
        if (c == "\"") { q[d] = q[d] == "\"" ? "" : (q[d] == "" ? "\"" : q[d]); continue }
        if ((c == "$" || (q[d] == "" && (c == "<" || c == ">"))) && substr(s, i + 1, 1) == "(" && substr(s, i + 2, 1) != "(") {
          d++; q[d] = ""; pc[d] = 0; i++; continue
        }
        if (q[d] != "") continue
        if (c == "(") { pc[d]++; continue }
        if (c == ")") { if (pc[d] > 0) pc[d]--; else if (d > 0) d--; continue }
        if (d > 0 && word(i, "case")) i = arms(i + 4, f) - 1
      }
    }
    END { exit bad > 0 }' "$@" | uniq
  [ "${PIPESTATUS[0]}" = 0 ]
}

# the check on fixtures: the four that failed or would fail under 3.2, and the forms it must leave alone
t="$root/tmp/bash32-parse-test"; rm -rf "$t"; mkdir -p "$t"
printf '%s\n' 'want="$(for f in $a; do case "$f" in */) ;; *) echo "$f" ;; esac; done | sort)"' > "$t/loop.sh"
printf '%s\n' 'x=$(case $w in *a*) echo y;; *) echo n;; esac)' > "$t/first.sh"
printf '%s\n' 'C=$(while read -r f; do case "$f" in (a/*.byn|b/*.byn) echo "$f";;' '  c) echo;; esac; done)' > "$t/second-arm.sh"
printf '%s\n' 'diff <(case $1 in x) echo;; esac) /dev/null' > "$t/procsub.sh"
printf '%s\n' 'case "$b" in HEAD|dev) continue ;; esac  # not in a substitution' \
  'x=$(case $w in (*a*) echo "y)";; (*) echo n;; esac)' "y='\$(case a in b) c;; esac)'" 'z=$((1 + (2)))' \
  '# $(case a in b) c;; esac)' 'v="$(echo "(")"; case $v in a) ;; esac' > "$t/fine.sh"
printf '%s\n' "x=\$(cat <<'E'" "don't" 'E' ')' 'y=$(case a in b) c;; esac)' > "$t/heredoc.sh"
printf '%s\n' 'x=$(case a in (b) case q in r) s;; esac;; esac)' > "$t/nested.sh"
printf '%s\n' 'echo $((1 << 2)); ((x <<= 1))' 'y=$(case a in b) c;; esac)' > "$t/shift.sh"
printf '%s\n' 'x=$(case a in (b) cat <<E ;;' "don't" 'E' '  c) d;; esac)' > "$t/arm-heredoc.sh"
printf '%s\n' 'x=$(case a in (b) echo esacs;; (c) d;; esac)' 'x=$(case a in' '  # an arm comment' '  (b) c;; esac)' \
  'y=$(cat <<-EOF' "	it's" '	EOF' ')' 'z=$(tr a b <<< "q")' \
  'x=$(case a in (b) cat <<E ;;' "it's" 'E' '  (c) d;; esac)' > "$t/fine2.sh"
got="$(cd "$t" && case_in_subst loop.sh first.sh second-arm.sh procsub.sh fine.sh heredoc.sh nested.sh shift.sh arm-heredoc.sh fine2.sh || true)"
want="$(printf '%s\n' loop.sh:1 first.sh:1 second-arm.sh:2 procsub.sh:1 heredoc.sh:5 nested.sh:1 shift.sh:2 arm-heredoc.sh:4)"
[ "$got" = "$want" ] || { printf 'FAIL: the case-in-substitution check on its fixtures\nwant:\n%s\ngot:\n%s\n' "$want" "$got"; exit 1; }

bad=0
files=()
while IFS= read -r f; do files+=("$f"); done < <(git -C "$root" ls-files '*.sh')
if ! hits="$(cd "$root" && case_in_subst "${files[@]}")"; then
  printf 'FAIL: a case arm inside $( … ) needs "(pat)" for bash 3.2:\n%s\n' "$hits"; bad=1
fi

b="${BAYAN_BASH32:-/bin/bash}"
case "$("$b" -c 'echo ${BASH_VERSINFO[0]}' 2>/dev/null || true)" in
  (3)
    for f in "${files[@]}"; do
      "$b" -n "$root/$f" 2>/dev/null || { echo "FAIL: $f does not parse under bash 3.2:"; "$b" -n "$root/$f" 2>&1 | head -2 || true; bad=1; }
    done ;;
  (*) echo "SKIP bash -n: $b is not bash 3" ;;
esac
[ $bad = 0 ] && echo PASS || exit 1
