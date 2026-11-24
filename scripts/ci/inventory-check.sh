#!/usr/bin/env bash
# Spec 019 R11: checks tests/inventory-019.tsv (class, file, family, tests, disposition, target, reason, memberdata) against
# the tree; the 8th column, the T16e [MemberData] audit, is read and not checked. Exit 1 names each offender:
#   (a) a test class (a class with a [Fact] or [Theory] member under csharp/tests or src/tests) with no row;
#   (b) a row with disposition dropped and an empty reason;
#   (c) a row of an exported case kind (disposition sem, emit-c, lex, parse, run, cli or diag, with a target of that one word)
#       whose case count, the directories under tests/cases/<target>/<Class>/, is below the row's test count; or of such a
#       disposition with a target <kind>/<stem>,<stem>... (flat cases) naming a stem with no tests/cases/<kind>/<stem>.* file
#       and no tests/cases/<kind>/<stem>/ folder (an empty list names the empty stem and fails);
#   (d) a row in family csharp-internals with disposition frozen* (proven only by the frozen compiler, not allowed there).
#   (e) a row with disposition nightly (a nightly script runs its tests) whose target's first word is no file under root, or
#       a file .github/workflows/laws-nightly.yml does not name.
# (c) counts only when tests/cases/EXPORT.tsv (class, kind, tests, cases, reason) exists, else it prints
# 'skip case counts: no tests/cases/EXPORT.tsv'. The tests a class's EXPORT.tsv reasons name, the leading count of each reason
# ('N not exported: Name (cover); ...'), are added to its cases: a row passes when cases plus named tests reach its test count.
# A golden row (disposition golden, target tests/cases/<dir>) counts the cases in that flat folder, one per distinct file stem
# or subdirectory (not a <Class>/ subdirectory of a class EXPORT.tsv names with kind <dir>, which holds that class's cases),
# against the summed tests of all golden rows sharing the folder; with a tests/cases/<dir>/<Class>/ folder,
# it counts the directories under tests/cases/<dir>/<Class>/ against the row alone. A row with target tests/cases itself counts
# the cases of every kind folder under tests/cases (stems as above; in a <kind>/<Class>/<test> layout, one per test, a directory
# with main.byn or without subdirectories being one case) against the row alone.
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
# tabs become \037 so that read keeps empty fields (a tab IFS would merge them)
while IFS="$(printf '\037')" read -r class file family tests disp target reason memberdata; do
  [ "$class" = class ] && continue
  if [ "$disp" = dropped ] && [ -z "$reason" ]; then offend "row $class is dropped with no reason"; fi
  case "$disp" in (frozen*) [ "$family" = csharp-internals ] && offend "row $class is csharp-internals and proven only by the frozen compiler ($disp)" ;; esac
  if [ "$disp" = nightly ]; then
    s="${target%% *}"
    if [ -z "$s" ] || [ ! -f "$root/$s" ]; then offend "row $class names nightly script '$s', not found"
    elif ! grep -qF -- "$s" "$root/.github/workflows/laws-nightly.yml" 2>/dev/null; then
      offend "row $class names nightly script $s, not run by .github/workflows/laws-nightly.yml"
    fi
    continue
  fi
  [ "$counting" = 1 ] || continue
  # tests named by the class's EXPORT.tsv reasons (the leading count of each reason) count as accounted for
  named="$(awk -F'\t' -v c="$class" '$1 == c && match($5, /^[0-9]+ /) { s += substr($5, 1, RLENGTH - 1) } END { print s + 0 }' "$export_tsv")"
  if [ "$disp" = golden ]; then
    dir="${target#tests/cases}"; dir="${dir#/}"
    if [ -z "$dir" ]; then
      # target tests/cases itself: every case under every kind folder, one per distinct file stem or subdirectory
      n=0
      for k in "$root"/tests/cases/*/; do
        [ -d "$k" ] || continue
        c="$(for e in "$k"*; do
          if [ -d "$e" ] && [ ! -f "$e/main.byn" ] && [ -n "$(find "$e" -mindepth 1 -maxdepth 1 -type d)" ]; then
            find "$e" -mindepth 1 -maxdepth 1 | sed "s|.*/\\(.*\\)|$(basename "$e")/\\1|; s|\\..*||"   # <kind>/<Class>/<test>: one case per test
          else basename "$e" | sed 's|\..*||'; fi
        done | sort -u | wc -l | tr -d ' ')"; n=$((n + c))
      done
      [ $((n + named)) -ge "$tests" ] || offend "row $class has $n cases across the kind folders of tests/cases and $named tests named by reasons, below its $tests tests"
      continue
    fi
    if [ ! -d "$root/tests/cases/$dir/$class" ]; then
      if [ ! -d "$root/tests/cases/$dir" ]; then
        [ "$named" -ge "$tests" ] || offend "row $class has 0 cases, no $target folder, and $named tests named by reasons, for its $tests tests"
        continue
      fi
      # a <Class>/ subfolder of an exported class (EXPORT.tsv class of kind <dir>) holds that class's cases, not this folder's
      exported="$(awk -F'\t' -v k="$dir" '$2 == k { print $1 }' "$export_tsv")"
      n="$(find "$root/tests/cases/$dir" -mindepth 1 -maxdepth 1 | while read -r e; do
        if [ -d "$e" ] && grep -qxF -- "${e##*/}" <<<"$exported"; then continue; fi
        printf '%s\n' "${e##*/}"
      done | sed 's|\..*||' | sort -u | wc -l | tr -d ' ')"
      want="$(awk -F'\t' -v t="$target" '$5 == "golden" && $6 == t { s += $4 } END { print s }' "$inv")"
      [ $((n + named)) -ge "$want" ] || offend "row $class has $n cases in $target and $named tests named by reasons, below the $want tests of its golden rows"
      continue
    fi
    target="$dir"
  else
    case "$disp" in (sem|emit-c|lex|parse|run|cli|diag) ;; (*) continue ;; esac
    if [ "${target%%/*}" = "$disp" ] && [ "$target" != "$disp" ]; then
      # target <kind>/<stem>,<stem>...: flat cases, each a <stem>.* file or <stem>/ folder under tests/cases/<kind>/
      while read -r s; do
        if [ -z "$s" ] || { [ ! -d "$root/tests/cases/$disp/$s" ] && ! compgen -G "$root/tests/cases/$disp/$s.*" >/dev/null; }; then
          offend "row $class names case $disp/$s, not found under tests/cases/$disp"
        fi
      done <<<"$(printf '%s' "${target#*/}" | tr ',' '\n')"
      continue
    fi
    [ "$target" = "$disp" ] || continue
  fi
  n=0
  if [ -d "$root/tests/cases/$target/$class" ]; then n="$(find "$root/tests/cases/$target/$class" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"; fi
  [ $((n + named)) -ge "$tests" ] || offend "row $class has $n cases under tests/cases/$target/$class and $named tests named by reasons, below its $tests tests"
done < <(tr '\t' '\037' < "$inv")

[ "$bad" = 0 ] && echo "inventory-check: ok"
exit "$bad"
