#!/usr/bin/env bash
# Spec 019 R11: checks tests/inventory-019.tsv against the tree. Exit 1 names each offender:
#   (a) a test class (a class with a [Fact] or [Theory] member under csharp/tests or src/tests) with no row;
#   (b) a row with disposition dropped and an empty reason;
#   (c) a row of an exported case kind (disposition sem, emit-c, lex, parse, run, cli or diag, with a target of that one word)
#       whose case count, the directories under tests/cases/<target>/<Class>/, is below the row's test count;
#   (d) a row in family csharp-internals with disposition frozen* (proven only by the frozen compiler, not allowed there).
# (c) counts only when tests/cases/EXPORT.tsv (class, kind, tests, cases, reason) exists, else it prints
# 'skip case counts: no tests/cases/EXPORT.tsv'. A class with a reason in EXPORT.tsv is not exported and is not counted.
# Golden-folder rows (disposition golden) keep the flat folder layout and are not counted per class.
#   bash scripts/ci/inventory-check.sh [root]   (root defaults to the repo; the inventory is <root>/tests/inventory-019.tsv)
set -uo pipefail
root="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
inv="$root/tests/inventory-019.tsv"
[ -f "$inv" ] || { echo "inventory-check: no $inv" >&2; exit 2; }
bad=0
offend() { echo "inventory-check: $1"; bad=1; }

# (a) classes with a test member, one per line; only top-level classes (column 0), nested helpers hold no tests
classes="$(for d in csharp/tests src/tests; do [ -d "$root/$d" ] && find "$root/$d" -name '*.cs' -type f; done | sort | while read -r f; do
  awk '
    match($0, /^((public|internal|private|protected|sealed|static|abstract|partial)[ \t]+)*class[ \t]+[A-Za-z_][A-Za-z0-9_]*/) {
      s = substr($0, RSTART, RLENGTH); sub(/.*class[ \t]+/, "", s); cur = s }
    /\[(Fact|Theory)[]( ,]/ { if (cur != "") print cur }
  ' "$f"
done | sort -u)"
rows="$(awk -F'\t' 'NR > 1 { print $1 }' "$inv" | sort -u)"
for c in $(comm -23 <(printf '%s\n' "$classes") <(printf '%s\n' "$rows")); do
  offend "class $c has no row in tests/inventory-019.tsv"
done

# (b), (d), and the rows for (c)
export_tsv="$root/tests/cases/EXPORT.tsv"
if [ -f "$export_tsv" ]; then counting=1; else counting=0; echo "skip case counts: no tests/cases/EXPORT.tsv"; fi
# tabs become \001 so that read keeps empty fields (a tab IFS would merge them)
while IFS="$(printf '\001')" read -r class file family tests disp target reason; do
  [ "$class" = class ] && continue
  if [ "$disp" = dropped ] && [ -z "$reason" ]; then offend "row $class is dropped with no reason"; fi
  case "$disp" in (frozen*) [ "$family" = csharp-internals ] && offend "row $class is csharp-internals and proven only by the frozen compiler ($disp)" ;; esac
  [ "$counting" = 1 ] || continue
  case "$disp" in (sem|emit-c|lex|parse|run|cli|diag) ;; (*) continue ;; esac
  [ "$target" = "$disp" ] || continue
  # a class named in EXPORT.tsv with a reason is not exported
  if awk -F'\t' -v c="$class" '$1 == c && $5 != "" { f = 1 } END { exit !f }' "$export_tsv"; then continue; fi
  n=0
  if [ -d "$root/tests/cases/$target/$class" ]; then n="$(find "$root/tests/cases/$target/$class" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"; fi
  [ "$n" -ge "$tests" ] || offend "row $class has $n cases under tests/cases/$target/$class, below its $tests tests"
done < <(tr '\t' '\001' < "$inv")

[ "$bad" = 0 ] && echo "inventory-check: ok"
exit "$bad"
