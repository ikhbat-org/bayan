#!/usr/bin/env bash
# Spec 019 T30d: the API index scans of SelfhostSemanticsApiTests, SelfhostDriverApiTests and SelfhostEmitterApiTests,
# without .NET. Each `- T<n> <file>.byn: <signature>  ← <where> <what>` line of an index is declared verbatim in its file:
#   010-api.md against src/semantics/<file>, 011-api.md and 012-api.md against src/<file>;
#   a declaration line, with a leading `public ` dropped, starts with the signature and then ends or goes on with ` =>`,
#   ` {` or ` uses `; for 010 and 011 (not 012) a parameter list `bayan format` wrapped (a line ending in `(`, the parameters,
#   a line starting with `)`) is joined into one line, and a `uses` clause on the next line is joined to it.
# 011-api.md also holds `LoweredNodes.cs:118` and `CEmitter.cs:1937`, `1942-1945`, `1961`, and src/emitter/ltree/ltree.byn
# has a `// Q1: round 4 redoes this` line followed (after blank lines) by one starting `public LocalId env`.
# Exit 1 prints one line per violation: a missing declaration, a malformed or absent index line, a missing file or marker.
#   bash scripts/ci/api-index-check.sh [root]   (root defaults to the repo)
set -uo pipefail
root="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
export LC_ALL=C
bad=0

# index, directory of the owner files (relative to root), join wrapped lists (1) or not (0)
check_index() {
  local index="$1" dir="$2" join="$3" out
  if [ ! -f "$root/$index" ]; then echo "api-index-check: no $index"; bad=1; return; fi
  out="$(awk -v index_name="$index" -v dir="$root/$dir" -v rel="$dir" -v join="$join" '
    function ltrim(s) { sub(/^[ \t\r\n\f\v]+/, "", s); return s }
    function trim(s) { sub(/[ \t\r\n\f\v]+$/, "", s); return ltrim(s) }
    # the declarations of file f, wrapped parameter lists and uses clauses joined as in SelfhostSemanticsApiTests.Declarations
    function load(f,    path, n, l, i, close_at, line, j, params) {
      path = dir "/" f; n = 0
      while ((getline l < path) > 0) { sub(/\r$/, "", l); raw[++n] = l }
      if (n == 0 && (getline l < path) < 0) { loaded[f] = -1; return }
      close(path)
      nd[f] = 0
      for (i = 1; i <= n; i++) {
        line = raw[i]
        if (join && line ~ /\($/) {
          close_at = i + 1
          while (close_at <= n && substr(ltrim(raw[close_at]), 1, 1) != ")") close_at++
          if (close_at <= n) {
            params = ""
            for (j = i + 1; j < close_at; j++) { p = trim(raw[j]); sub(/,+$/, "", p); params = params (j > i + 1 ? ", " : "") p }
            line = line params ltrim(raw[close_at]); i = close_at
          }
        }
        if (join && i + 1 <= n && substr(ltrim(raw[i + 1]), 1, 5) == "uses ") { i++; line = line " " ltrim(raw[i]) }
        decl[f, ++nd[f]] = line
      }
      loaded[f] = 1
    }
    function declared(f, sig,    k, l, rest) {
      for (k = 1; k <= nd[f]; k++) {
        l = decl[f, k]
        if (substr(l, 1, 7) == "public ") l = substr(l, 8)
        if (substr(l, 1, length(sig)) != sig) continue
        rest = substr(l, length(sig) + 1)
        if (rest == "" || substr(rest, 1, 3) == " =>" || substr(rest, 1, 2) == " {" || substr(rest, 1, 6) == " uses ") return 1
      }
      return 0
    }
    substr($0, 1, 3) != "- T" { next }
    {
      sub(/\r$/, "")
      entries++
      at = index($0, "  ← ")
      head = at ? substr($0, 1, at - 1) : ""; tail = at ? substr($0, at + length("  ← ")) : ""
      if (!at || head !~ /^- T[0-9]+ [^ \t]+\.byn: ./ || tail !~ /^[^ \t]+ ./) { print "api-index-check: " index_name ": malformed index line: " $0; next }
      split(head, w, " "); task = substr(w[2], 1); file = w[3]; sub(/:$/, "", file)
      sig = substr(head, length("- " task " " file ": ") + 1)
      if (!(file in loaded)) load(file)
      if (loaded[file] < 0) { print "api-index-check: " index_name ": " task " " file ": no file " rel "/" file; next }
      if (!declared(file, sig)) print "api-index-check: " index_name ": " task " " file ": " sig ": not declared verbatim in " rel "/" file
    }
    END { if (entries == 0) print "api-index-check: " index_name ": no `- T` index lines" }
  ' "$root/$index")"
  [ -z "$out" ] || { printf '%s\n' "$out"; bad=1; }
}

check_index docs/specs/010-self-hosted-semantics/010-api.md src/semantics 1
check_index docs/specs/012-self-hosted-bootstrap/012-api.md src 0
check_index docs/specs/011-self-hosted-emitter/011-api.md src 1

# SelfhostEmitterApiTests.IndexCarriesTheRoundFourTableAndTheMarker
api011="$root/docs/specs/011-self-hosted-emitter/011-api.md"
if [ -f "$api011" ]; then
  for s in '`LoweredNodes.cs:118`' '`CEmitter.cs:1937`, `1942-1945`, `1961`'; do
    grep -qF -- "$s" "$api011" || { echo "api-index-check: 011-api.md does not hold $s"; bad=1; }
  done
fi
ltree="$root/src/emitter/ltree/ltree.byn"
if [ ! -f "$ltree" ] || ! awk '
    want && /^[ \t\r\n\f\v]*$/ { next }
    want { if ($0 ~ /^[ \t\r\n\f\v]*public LocalId env/) { found = 1; exit } want = 0 }
    index($0, "// Q1: round 4 redoes this") { want = 1 }
    END { exit !found }
  ' "$ltree"; then
  echo "api-index-check: src/emitter/ltree/ltree.byn has no '// Q1: round 4 redoes this' line before 'public LocalId env'"; bad=1
fi

[ "$bad" = 0 ] && echo "api-index-check: ok"
exit "$bad"
