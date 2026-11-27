#!/usr/bin/env bash
# The writing rules of docs/bayan-contributing.md (*Writing docs*) that a script can check, over the docs a user or
# contributor reads to learn the language and the tools: the READMEs, site/content/*.page, RELEASING, contributing and
# the language docs below. Not checked: docs whose subject is versions (roadmap, milestones, questions, feature history),
# generated docs (DIAGNOSTICS.md) and records.
# Given file arguments, checks those instead. Prints one `prose: <file>:<line>: <rule>: <text>` line per finding and
# exits 1 on any:
#   archives  three or more release archive names in one paragraph or list (rule 1: say the pattern);
#   csharp    C#, .NET, dotnet or csharp/ (rule 4: Bayān on its own terms);
#   version   a Bayān version other than VERSION, as `bayan 0.3.1`, `bayan-0.3.1` or `v0.3` (rule 3);
#   filler    a word or phrase from scripts/docs/prose-words.txt (rule 6).
# Code is not prose: fenced blocks, <pre>…</pre>, `inline code` and <code>…</code> are skipped. Exempt: the comparison
# guides site/content/from-*.page, site/content/whats-new.page (it names versions), docs/bayan-self-hosting.md (the
# frozen C# oracle), and any lines between `<!-- prose-check: off -->` and `<!-- prose-check: on -->`.
# PROSE_VERSION overrides VERSION (tests).
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
words="$root/scripts/docs/prose-words.txt"
version="${PROSE_VERSION:-$(tr -d '[:space:]' < "$root/VERSION")}"

if [ $# -gt 0 ]; then
  files=("$@")
else
  files=()
  for f in README.md bootstrap/README.md editors/README.md docs/RELEASING.md docs/bayan-contributing.md \
    docs/bayan-spec.md docs/bayan-grammar.md docs/bayan-style.md docs/bayan-concurrency.md docs/bayan-views.md \
    docs/bayan-library-tiers.md docs/bayan-terminal-style.md docs/bayan-not-planned.md docs/bayan-nice-to-have.md \
    docs/typed-dump.md; do files+=("$root/$f"); done
  for f in "$root"/site/content/*.page; do files+=("$f"); done
fi

found=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in from-*.page|whats-new.page|bayan-self-hosting.md) continue ;; esac
  rel="${f#"$root"/}"
  out="$(awk -v file="$rel" -v version="$version" -v wordsfile="$words" '
    BEGIN {
      nw = 0
      while ((getline w < wordsfile) > 0) { if (w != "") words[++nw] = tolower(w) }
      code = 0; pre = 0; off = 0; para = 0; first = 0
    }
    function report(line, rule, text) { printf "prose: %s:%d: %s: %s\n", file, line, rule, substr(text, 1, 100) }
    function flush() { if (para >= 3) report(first, "archives", para " archive names; write bayan-<version>-<os>-<arch>.tar.gz"); para = 0 }
    {
      raw = $0
      if (raw ~ /<!-- prose-check: off -->/) { off = 1; next }
      if (raw ~ /<!-- prose-check: on -->/) { off = 0; next }
      if (raw ~ /^[ \t]*```/) { code = !code; next }
      if (code || off) next
      if (pre || raw ~ /<pre[ >]/) { pre = (raw !~ /<\/pre>/); next }
      line = raw
      gsub(/`[^`]*`/, "", line)
      gsub(/<code>[^<]*<\/code>/, "", line)
      if (line ~ /^[ \t]*$/) { flush(); next }
      s = raw; n = 0
      while (match(s, /bayan-[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?-(macos|linux|windows)-[a-z0-9]+/)) { n++; s = substr(s, RSTART + RLENGTH) }
      if (n > 0) { if (para == 0) first = NR; para += n }
      if (line ~ /C#|\.NET|(^|[^A-Za-z])dotnet([^A-Za-z]|$)|csharp\//) report(NR, "csharp", raw)
      s = line
      while (match(s, /(bayan[- ][0-9]+\.[0-9]+\.[0-9]+(-dev)?|(^|[^A-Za-z0-9])v[0-9]+\.[0-9]+(\.[0-9]+)?)/)) {
        m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        sub(/^[^0-9]*/, "", m)
        if (m != version && index(version, m) != 1) { report(NR, "version", raw); break }
      }
      low = " " tolower(line) " "
      gsub(/[^a-z]+/, " ", low)
      for (i = 1; i <= nw; i++) if (index(low, " " words[i] " ")) { report(NR, "filler", "\"" words[i] "\": " raw); break }
    }
    END { flush() }
  ' "$f")"
  if [ -n "$out" ]; then echo "$out"; found=1; fi
done
exit "$found"
