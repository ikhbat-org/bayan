#!/usr/bin/env bash
# Spec 019 T30d: the source scans of SelfhostDriverT8Tests (spec 012 R12, K4 and K2) without .NET.
#   bash scripts/ci/libc-inventory-check.sh [root]
#     runtime/libc-uses.txt is the library functions runtime/bayan-rt.{c,h} call, sorted (C locale) and holding memcpy;
#     every `| ` table line of docs/specs/011-self-hosted-emitter/011-c-inventory.md (but `| Site `) is a row.
#   bash scripts/ci/libc-inventory-check.sh --emitted <dir> [root]
#     the C units <dir>/*.c have only extension tokens that are rows of 011-c-inventory.md, and their direct library calls
#     are the `- `name`` lines of that file, no more and no fewer. A direct call is a called name that is not the runtime's
#     (byn_, BYN_, bynt_, bayan_, __builtin_), not a keyword, type or *_C macro, and not defined at column 0 of its unit.
#     Nothing here emits the C: the C# test emitted every tests/cases/run input in debug, safe and fast mode (019 T30d).
# A called name is an identifier not after `.`, `->` or a word character, then white space and `(`, in the text with
# comments, string and character literals blanked. Exit 1 prints one line per violation; 2 on a usage or file error.
set -uo pipefail
emitted=""
if [ "${1:-}" = --emitted ]; then
  emitted="${2:-}"; [ -d "$emitted" ] || { echo "libc-inventory-check: --emitted needs a directory of .c files" >&2; exit 2; }
  shift 2
fi
root="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
export LC_ALL=C
inventory="$root/docs/specs/011-self-hosted-emitter/011-c-inventory.md"
[ -f "$inventory" ] || { echo "libc-inventory-check: no $inventory" >&2; exit 2; }
bad=0
say() { [ -z "$1" ] || { printf '%s\n' "$1" | sed 's/^/libc-inventory-check: /'; bad=1; }; }

# Words before `(` that are not functions (SelfhostDriverT8Tests.NotFunctions).
not_functions='defined if for while switch return sizeof else void double bool int32_t int64_t uint8_t uint32_t uint64_t UINT64_C
_Alignas _WIN32 __attribute__ WEXITSTATUS WIFSIGNALED WTERMSIG S_ISDIR hook eq less flush N X _i _u'

# Prints `C <file> <name>` per called name and `D <file> <name>` per name defined at column 0 of the files' code
# (comments, "..." and '...' literals each replaced by one space, as SelfhostDriverT8Tests.Code).
calls() {
  awk '
    function emit_line(l, f,    rest, pre, name, after, pos, start) {
      # a name left open at the end of an earlier line is a call (or a definition) when the next code starts with (
      if (pending != "" && l !~ /^[ \t\r\f\v]*$/) {
        if (l ~ /^[ \t\r\f\v]*\(/) { print "C " pfile " " pending; if (pdef) print "D " pfile " " pending }
        pending = ""; pdef = 0
      }
      if (l ~ /^[A-Za-z_][A-Za-z0-9_ \t*]*[ \t*][A-Za-z_][A-Za-z0-9_]*[ \t\r\f\v]*(\(|$)/) {
        pre = l; sub(/[ \t\r\f\v]*\(.*$/, "", pre); sub(/[ \t\r\f\v]+$/, "", pre)
        name = pre; sub(/^.*[^A-Za-z0-9_]/, "", name)
        if (l ~ /\(/) print "D " f " " name; else def_open = name
      }
      rest = l; pos = 0
      while (match(rest, /[A-Za-z0-9_]+/)) {
        start = pos + RSTART; name = substr(rest, RSTART, RLENGTH)
        pos += RSTART + RLENGTH - 1; rest = substr(rest, RSTART + RLENGTH)
        if (name ~ /^[0-9]/) continue
        if (start > 1 && substr(l, start - 1, 1) ~ /[.>]/) continue
        if (rest ~ /^[ \t\r\f\v]*\(/) print "C " f " " name
        else if (rest ~ /^[ \t\r\f\v]*$/) { pending = name; pfile = f; pdef = (def_open == name) }
      }
      def_open = ""
    }
    FNR == 1 { if (NR > 1 && out != "") emit_line(out, prev); state = 0; out = "" }
    {
      prev = FILENAME; l = $0; n = length(l)
      for (i = 1; i <= n; i++) {
        ch = substr(l, i, 1)
        if (state == 0) {
          two = substr(l, i, 2)
          if (two == "/*") { state = 1; i++ }
          else if (two == "//") { out = out " "; i = n }
          else if (ch == "\"") state = 2
          else if (ch == "'\''" && substr(l, i + 1, 1) != "'\''") state = 3
          else out = out ch
        } else if (state == 1) { if (substr(l, i, 2) == "*/") { state = 0; out = out " "; i++ } }
        else if (ch == "\\") i++
        else if ((state == 2 && ch == "\"") || (state == 3 && ch == "'\''")) { state = 0; out = out " " }
      }
      if (state == 0) { emit_line(out, FILENAME); out = "" }
    }
    END { if (out != "") emit_line(out, prev) }
  ' "$@"
}

# The token of every inventory row; a `| ` line (but `| Site `) that is not a row is printed as `BAD <line>`.
rows() {
  awk '
    substr($0, 1, 2) != "| " || substr($0, 1, 7) == "| Site " { next }
    !/^\| [^ |`]+ `[^`]+` \| `[^`]+` \| .+ \|$/ { print "BAD " $0; next }
    { split($0, p, "`"); print "ROW " p[4] }
  ' "$inventory"
}
row_out="$(rows)"
say "$(printf '%s\n' "$row_out" | sed -n 's/^BAD /011-c-inventory.md: table line is not a row: /p')"
filter() { NF_WORDS="$not_functions" awk 'BEGIN { n = split(ENVIRON["NF_WORDS"], w, /[ \n]+/); for (i = 1; i <= n; i++) skip[w[i]] = 1 }
  !($0 in skip) && $0 !~ /^(byn_|BYN_|bynt_|bayan_|__builtin_)/'; }

if [ -z "$emitted" ]; then
  # LibcListIsTheRuntimesLibcCalls
  list="$root/runtime/libc-uses.txt"
  for f in "$list" "$root/runtime/bayan-rt.c" "$root/runtime/bayan-rt.h"; do
    [ -f "$f" ] || { echo "libc-inventory-check: no $f" >&2; exit 2; }
  done
  actual="$(calls "$root/runtime/bayan-rt.c" "$root/runtime/bayan-rt.h" | awk '$1 == "C" { print $3 }' | filter | sort -u)"
  listed="$(tr -d '\r' < "$list" | grep -v '^$')"
  say "$(comm -23 <(printf '%s\n' "$actual") <(printf '%s\n' "$listed" | sort -u) | grep -v '^$' | sed 's|^|called by the runtime but not in runtime/libc-uses.txt: |')"
  say "$(comm -13 <(printf '%s\n' "$actual") <(printf '%s\n' "$listed" | sort -u) | grep -v '^$' | sed 's|^|in runtime/libc-uses.txt but not called by the runtime: |')"
  [ "$(printf '%s\n' "$listed" | sort)" = "$listed" ] || say "runtime/libc-uses.txt is not sorted"
  grep -qx memcpy <<<"$listed" || say "runtime/libc-uses.txt does not list memcpy"
else
  units=("$emitted"/*.c)
  [ -f "${units[0]}" ] || { echo "libc-inventory-check: no .c file in $emitted" >&2; exit 2; }
  # EmittedCHasOnlyInventoryExtensionTokens: the CInventoryTests token regex over each unit as written
  tokens="$(printf '%s\n' "$row_out" | sed -n 's/^ROW //p')"
  say "$(for u in "${units[@]}"; do
    awk -v unit="${u##*/}" '
      function word(c) { return c ~ /[A-Za-z0-9_]/ }
      { text = text $0 "\n" }
      END {
        s = text
        while (match(s, /__builtin_[A-Za-z0-9_]+|__attribute__[ \t\r\n\f\v]*\(\(([^()]|\([^()]*\))*\)\)|__declspec|alloca|__typeof__|typeof|__auto_type|__thread|__int128|__extension__|__restrict[A-Za-z0-9_]*|#pragma [A-Za-z0-9_]+|_Pragma|__asm__|asm|__has_builtin|__PRETTY_FUNCTION__|__COUNTER__|\(\{/)) {
          m = substr(s, RSTART, RLENGTH); before = RSTART > 1 ? substr(s, RSTART - 1, 1) : ""; after = substr(s, RSTART + RLENGTH, 1)
          if (((m == "alloca" || m == "typeof" || m == "asm") && (word(before) || word(after))) || (m == "__thread" && word(after))) {
            s = substr(s, RSTART + 1); continue
          }
          s = substr(s, RSTART + RLENGTH)
          if (m !~ /^__attribute__/) { print m "\t" unit; continue }
          list = m; sub(/^[^(]*\(\(/, "", list); list = substr(list, 1, length(list) - 2)
          depth = 0; start = 1
          for (i = 1; i <= length(list) + 1; i++) {
            c = substr(list, i, 1)
            if (i <= length(list) && c == "(") depth++
            else if (i <= length(list) && c == ")") depth--
            else if (i > length(list) || (c == "," && depth == 0)) {
              item = substr(list, start, i - start); gsub(/^[ \t\r\n\f\v]+|[ \t\r\n\f\v]+$/, "", item)
              print "__attribute__((" item "))\t" unit; start = i + 1
            }
          }
        }
      }
    ' "$u"
  done | ROWS="$tokens" awk -F'\t' 'BEGIN { n = split(ENVIRON["ROWS"], r, /\n/); for (i = 1; i <= n; i++) ok[r[i]] = 1 }
    !($1 in ok) && !($1 in seen) { seen[$1] = 1; print "extension token without a row in 011-c-inventory.md: " $1 " (first in " $2 ")" }')"
  # EmittedCDirectLibcCallsAreListed
  found="$(for u in "${units[@]}"; do
    calls "$u" | awk '$1 == "D" { def[$3] = 1 } $1 == "C" { c[$3] = 1 } END { for (n in c) if (!(n in def) && n !~ /_C$/) print n }' | filter
  done | sort -u)"
  listed="$(awk '/^- `[A-Za-z0-9_]+`/ { s = $0; sub(/^- `/, "", s); sub(/`.*/, "", s); print s }' "$inventory" | sort -u)"
  say "$(comm -23 <(printf '%s\n' "$found") <(printf '%s\n' "$listed") | grep -v '^$' | sed 's|^|direct libc call in emitted C not listed in 011-c-inventory.md: |')"
  say "$(comm -13 <(printf '%s\n' "$found") <(printf '%s\n' "$listed") | grep -v '^$' | sed 's|^|listed in 011-c-inventory.md but no emitted unit calls it: |')"
fi

[ "$bad" = 0 ] && echo "libc-inventory-check: ok"
exit "$bad"
