#!/usr/bin/env bash
# Spec 019 T30d: SelfhostEmitterPrinterBoundaryTests (011 D9) without .NET. src/emitter/cprint/ is the only module with C text in
# its string literals: no other src/emitter/**/*.byn has a literal (outside a trailing // comment; `\n` read as a line break)
# holding #include, #line, #define, typedef, int64_t, uint8_t, byn_, BYN_, bynt_, (void), ->, `goto `, `static `, `;\n` or
# `{\n`. The JSON literals listed below are exempt, and each must still be a literal in its file. `*.test.byn` files are
# skipped: their literals are expected C and mutant labels, test data rather than emitter code (spec 019 T29 tests).
# Exit 1 prints one line per hit (`<file>:<line>: "<literal>" has `<word>``) and per stale JSON entry.
#   bash scripts/ci/printer-boundary-check.sh [root]   (root defaults to the repo; scans <root>/src/emitter)
set -uo pipefail
root="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
export LC_ALL=C
dir="$root/src/emitter"
[ -d "$dir" ] || { echo "printer-boundary-check: no $dir" >&2; exit 2; }
files="$(cd "$dir" && find . -name '*.byn' -type f ! -path './cprint/*' ! -name '*.test.byn' | sed 's|^\./||' | sort)"
[ -n "$files" ] || { echo "printer-boundary-check: no .byn under src/emitter outside cprint"; exit 1; }

out="$(cd "$dir" && printf '%s\n' "$files" | awk '
  BEGIN {
    nw = split("#include|#line|#define|typedef|int64_t|uint8_t|byn_|BYN_|bynt_|(void)|->|goto |static ", word, "|")
    word[++nw] = ";\n"; word[++nw] = "{\n"   # split would break these at the line break
    # JSON literals, not C (user 2026-11-08): file under src/emitter and the literal as written
    json_file[1] = "schemata.byn"; json_lit[1] = "{\\n  \\\"version\\\": 1,\\n  \\\"sites\\\": ["; nj = 1
  }
  # the string literals of line l before a trailing // comment, into lit[1..n]; returns n
  function literals(l,    n, i, ch, cur, open) {
    n = 0; open = 0
    for (i = 1; i <= length(l); i++) {
      ch = substr(l, i, 1)
      if (!open) {
        if (ch == "/" && substr(l, i + 1, 1) == "/") break
        if (ch == "\"") { open = 1; cur = "" }
      } else if (ch == "\\" && i < length(l)) { cur = cur ch substr(l, i + 1, 1); i++ }
      else if (ch == "\"") { lit[++n] = cur; open = 0 }
      else cur = cur ch
    }
    return n
  }
  function exempt(f, s,    j) { for (j = 1; j <= nj; j++) if (json_file[j] == f && json_lit[j] == s) return 1; return 0 }
  {
    f = $0; ln = 0
    while ((getline l < f) > 0) {
      ln++; sub(/\r$/, "", l)
      n = literals(l)
      for (k = 1; k <= n; k++) {
        if (exempt(f, lit[k])) continue
        u = lit[k]; gsub(/\\n/, "\n", u)
        for (w = 1; w <= nw; w++) if (index(u, word[w])) { shown = word[w]; if (shown ~ /\n$/) shown = substr(shown, 1, length(shown) - 1) "\\n"; print f ":" ln ": \"" lit[k] "\" has `" shown "`" }
      }
      for (j = 1; j <= nj; j++) if (json_file[j] == f) for (k = 1; k <= n; k++) if (lit[k] == json_lit[j]) seen[j] = 1
    }
    close(f)
  }
  END { for (j = 1; j <= nj; j++) if (!seen[j]) print "JSON entry " json_file[j] " names no literal in its file: \"" json_lit[j] "\"" }
')"
[ -z "$out" ] && { echo "printer-boundary-check: ok"; exit 0; }
printf '%s\n' "$out" | sed 's/^/printer-boundary-check: /'
exit 1
