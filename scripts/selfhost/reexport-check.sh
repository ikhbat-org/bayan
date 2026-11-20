#!/usr/bin/env bash
# Spec 019 T59, the L043 check: re-exports golden cases with the frozen C# compiler and compares them with the tree.
#   bash scripts/selfhost/reexport-check.sh [--seed S | --class <kind>/<Class> ... | --full]
# The classes: the EXPORT.tsv rows with cases (kind `shell` aside) that export mode writes at the export head (derived from
# that head's sources, below); the others are printed as left out and never count as checked. Default: one class per kind, picked by the seed (S, else the
# ISO week `date -u +%G%V`): of a kind's classes of at most 2,000 EXPORT.tsv cases sorted (LC_ALL=C), number 1 + (cksum of
# "S kind") mod n; larger classes are printed as left to --full, and a kind with none prints so. --class names classes
# instead; --full takes them all. The chosen classes are printed first.
# Steps, in <root>/tmp/reexport.XXXXXX (no worktree: the checkout's git state is left alone):
#   1. `git archive` of the export head tests/cases/FREEZE.tsv names (its `export` row) into tree/;
#   2. in tree/: BAYAN_EXPORT_DIR=<w>/export dotnet test csharp/tests/Bayan.Tests -v q --filter <the classes> (no filter with
#      --full), the export mode that wrote the cases (src/tests/SelfhostExport.cs on that head);
#   3. scripts/selfhost/land-export.sh lands the export into land/cases (the land-time masks the tree's cases went through);
#   4. for each chosen <kind>/<Class>, every file under tests/cases/<kind>/<Class>/ with a FREEZE.tsv row or named expected.*,
#      in the tree or in land/cases, is compared by git blob id (the attributes of the tree's path, as FREEZE.tsv records);
#      one that differs, is missing from the re-export or is extra (landed, not in the tree) fails with its path, unless its
#      case is on tests/cases/DIVERGENCES.tsv (the case key <kind>/<Class>/<case>, or <Class>.<Test> for <case> <Test> or
#      <Test>-<n>) or holds an `os` file that does not name this host's OS (macos, linux, windows); both are counted. A landed
#      file with no FREEZE.tsv row and not in the tree (a case the owner removed) is no L043 row: it is listed, not failed.
# A row a golden update changed since the freeze differs from the frozen compiler's output: it belongs on DIVERGENCES.tsv.
# The work dir is removed when the run passes and kept, and named, otherwise. Exit 0 when every compared file matches, 1 when
# one does not, the export run fails or no .NET is on PATH (nothing is checked then: never a pass), 2 on a usage error or an
# export head not in the clone. Tests only: REEXPORT_DOTNET replaces `dotnet`. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2

usage() { echo "usage: reexport-check.sh [--seed S | --class <kind>/<Class> ... | --full]" >&2; exit 2; }
full=0; seed=""; picked=""
while [ $# -gt 0 ]; do
  case "$1" in
    (--full) full=1 ;;
    (--seed) [ $# -ge 2 ] && [ -n "$2" ] || usage; seed="$2"; shift ;;
    (--class) [ $# -ge 2 ] && [ -n "$2" ] || usage; picked="$picked $2"; shift ;;
    (*) usage ;;
  esac
  shift
done
n=0; [ $full = 0 ] || n=$((n + 1)); [ -z "$seed" ] || n=$((n + 1)); [ -z "$picked" ] || n=$((n + 1))
[ $n -le 1 ] || usage

cases=tests/cases; tab="$(printf '\t')"
[ -f "$cases/FREEZE.tsv" ] && [ -f "$cases/EXPORT.tsv" ] || { echo "reexport-check: no $cases/FREEZE.tsv or EXPORT.tsv" >&2; exit 2; }
IFS="$tab" read -r ref sha <<EOF
$(awk -F'\t' '$1 == "export" { print $2 "\t" $3; exit }' "$cases/FREEZE.tsv")
EOF
[ -n "${sha:-}" ] || { echo "reexport-check: FREEZE.tsv has no export row" >&2; exit 2; }
git cat-file -e "$sha^{commit}" 2> /dev/null || { echo "reexport-check: the export head $sha ($ref) is not in this clone; fetch it" >&2; exit 2; }

mkdir -p tmp; w="$(mktemp -d "$root/tmp/reexport.XXXXXX")"
awk -F'\t' 'NR > 1 && $2 != "shell" && $4 + 0 > 0 { print $2 "/" $1 }' "$cases/EXPORT.tsv" | LC_ALL=C sort -u > "$w/rows"
# Export mode at the head: a class writes cases when a file declaring it names SelfhostExport, or a Selfhost* type declared in a
# file that does (the harnesses, or another class's tests it runs). The other classes (recorded through the C# CLI, T59b) are
# left out of the sample and of --full, and printed.
src="csharp/tests src/tests"
git grep -l -w SelfhostExport "$sha" -- $src | sed "s|^$sha:||" > "$w/hooked"
: > "$w/helpers"; : > "$w/xfiles"
[ ! -s "$w/hooked" ] || git grep -h -o -E "(class|record) Selfhost[A-Za-z0-9_]*" "$sha" -- $(cat "$w/hooked") |
  awk '{ print $2 }' | LC_ALL=C sort -u > "$w/helpers"
[ ! -s "$w/helpers" ] || git grep -l -w -F -f "$w/helpers" "$sha" -- $src | sed "s|^$sha:||" > "$w/xfiles"
git grep -o -w -E "(class|record) [A-Za-z0-9_]+" "$sha" -- $src | sed "s|^$sha:||" |
  awk -v xf="$w/xfiles" -v rows="$w/rows" -v left="$w/left" '
    BEGIN { while ((getline l < xf) > 0) x[l] = 1 }
    { i = index($0, ":"); split(substr($0, i + 1), a, " "); if (substr($0, 1, i - 1) in x) ok[a[2]] = 1 }
    END { while ((getline l < rows) > 0) { c = l; sub(/^[^\/]*\//, "", c); if (c in ok) print l; else print l > left } }' > "$w/all"
[ -f "$w/left" ] || : > "$w/left"
# The replay (T59 part 2, scripts/selfhost/replay-csharp.sh): of the left-out classes and the flat kinds, ryes are the units it runs
# through the C# CLI, rno (`<unit>\t<reason>`) the ones it does not. A flat kind's inputs (flat/<kind>) are its FREEZE.tsv rows
# `tests/cases/<kind>/<path>.<ending>` outside the EXPORT.tsv classes, read as `<kind>/<path>.byn`.
bash scripts/selfhost/replay-csharp.sh --list > "$w/routes"
awk -F'\t' -v left="$w/left" -v yes="$w/ryes" -v no="$w/rno" '
  BEGIN { while ((getline l < left) > 0) { L[l] = 1; order[++m] = l } }
  { r[$1] = $2; why[$1] = $3; if ($1 !~ /\//) flat[++f] = $1 }
  END {
    for (i = 1; i <= m; i++) { c = order[i]; if ((c in r) && r[c] != "-") print c > yes; else print c "\t" ((c in r) ? why[c] : "no replay route") > no }
    for (i = 1; i <= f; i++) { c = flat[i]; if (r[c] != "-") print c > yes; else print c "\t" why[c] > no }
  }' "$w/routes"
[ -f "$w/ryes" ] || : > "$w/ryes"; [ -f "$w/rno" ] || : > "$w/rno"
mkdir -p "$w/flat"
for kind in $(grep -v / "$w/ryes"); do
  case "$kind" in (parse) e=ast ;; (typed) e=types ;; (*) e="" ;; esac
  awk -F'\t' -v k="$kind" -v e="$e" -v rows="$w/rows" '
    BEGIN { while ((getline l < rows) > 0) cls[l] = 1 }
    $1 == "file" { p = substr($3, 13); n = split(p, a, "/"); if (a[1] != k || (k "/" a[2]) in cls || n < 2) next
      if (substr(p, length(p) - length(e)) != "." e) next; print k " " substr(p, 1, length(p) - length(e)) "byn" }' "$cases/FREEZE.tsv" |
    LC_ALL=C sort > "$w/flat/$kind"
done
: > "$w/rsel"
if [ $full = 1 ]; then
  cp "$w/all" "$w/sel"; what="all classes"
  cp "$w/ryes" "$w/rsel"
elif [ -n "$picked" ]; then
  : > "$w/sel"
  for c in $picked; do
    if grep -qxF "$c" "$w/ryes"; then echo "$c" >> "$w/rsel"; continue; fi
    r="$(awk -F'\t' -v c="$c" '$1 == c { print $2 }' "$w/rno")"
    [ -z "$r" ] || { echo "reexport-check: export mode writes no case for $c at $ref and the C# CLI replay does not run it ($r); it is not checked here" >&2; rm -rf "$w"; exit 2; }
    grep -qxF "$c" "$w/all" || { echo "reexport-check: $c is no EXPORT.tsv class with cases" >&2; rm -rf "$w"; exit 2; }
    echo "$c" >> "$w/sel"
  done
  what="named classes"
else
  seed="${seed:-$(date -u +%G%V)}"; : > "$w/sel"
  # the weekly pick: classes of at most 2,000 EXPORT.tsv cases (the R27 job's 60 minutes); larger ones are left to --full
  awk -F'\t' 'NR > 1 && $4 + 0 > 2000 { print $2 "/" $1 }' "$cases/EXPORT.tsv" | LC_ALL=C sort -u > "$w/bigrows"
  grep -vxF -f "$w/bigrows" "$w/all" > "$w/small"; grep -xF -f "$w/bigrows" "$w/all" > "$w/big"
  for kind in $(cut -d/ -f1 "$w/all" | uniq); do
    k=$(grep -c "^$kind/" "$w/small"); h=$(printf '%s %s' "$seed" "$kind" | cksum | cut -d' ' -f1)
    [ "$k" -gt 0 ] || { echo "reexport-check: $kind has no weekly class (each is over 2,000 cases; --full or --class checks it)" >> "$w/nokind"; continue; }
    grep "^$kind/" "$w/small" | sed -n "$((h % k + 1))p" >> "$w/sel"
  done
  # the weekly replay: per kind one replayed class, number 1 + (cksum of "S replay kind") mod n; per flat kind a slice of $slice inputs
  # from number 1 + (that cksum) mod n of its sorted inputs, wrapping
  slice=20
  for kind in $(sed 's|/.*||' "$w/ryes" | uniq); do
    h=$(printf '%s replay %s' "$seed" "$kind" | cksum | cut -d' ' -f1)
    if grep -qxF "$kind" "$w/ryes"; then
      k=$(wc -l < "$w/flat/$kind" | tr -d ' '); [ "$k" -gt 0 ] || continue
      awk -v s=$((h % k)) -v z=$slice -v k="$k" '{ l[NR - 1] = $0 } END { for (i = 0; i < z && i < k; i++) print l[(s + i) % k] }' \
        "$w/flat/$kind" > "$w/slice.$kind"
      echo "flat/$kind" >> "$w/rsel"
    else
      k=$(grep -c "^$kind/" "$w/ryes"); grep "^$kind/" "$w/ryes" | sed -n "$((h % k + 1))p" >> "$w/rsel"
    fi
  done
  what="seed $seed"
fi
# the replay's units: a class as is, a flat kind as its inputs (the weekly slice when one was drawn)
: > "$w/runits"
while IFS= read -r u; do
  case "$u" in
    (flat/*) cat "$w/slice.${u#flat/}" >> "$w/runits" ;;
    (*/*) echo "$u" >> "$w/runits" ;;
    (*) cat "$w/flat/$u" >> "$w/runits" ;;
  esac
done < "$w/rsel"
echo "== reexport-check: export $ref ($(echo "$sha" | cut -c1-12)), $what: $(wc -l < "$w/sel" | tr -d ' ') classes"
[ $full = 1 ] || sed 's/^/  /' "$w/sel"
[ ! -f "$w/nokind" ] || cat "$w/nokind"
if [ -s "$w/big" ]; then
  echo "reexport-check: left to --full (over 2,000 cases): $(wc -l < "$w/big" | tr -d ' ') classes"
  sed 's/^/  /' "$w/big"
fi
if [ -s "$w/rsel" ]; then
  echo "reexport-check: replayed through the C# CLI (export mode writes no case for them at this head): $(wc -l < "$w/rsel" | tr -d ' ') units, $(wc -l < "$w/runits" | tr -d ' ') lines"
  sed 's/^/  /' "$w/rsel"
fi
if [ -s "$w/rno" ]; then
  echo "reexport-check: left out, not checked (no export case and no C# CLI replay): $(wc -l < "$w/rno" | tr -d ' ') classes and flat kinds"
  sed "s/^/  /; s/$tab/: /" "$w/rno"
fi

dotnet="${REEXPORT_DOTNET:-dotnet}"
command -v "$dotnet" > /dev/null 2>&1 ||
  { echo "reexport-check: no dotnet on PATH: L043 is not checked here (the R27 job, .github/workflows/ddc.yml, runs it)" >&2; rm -rf "$w"; exit 1; }
die() { echo "reexport-check: $1 (work dir kept: $w)" >&2; exit 1; }
start=$(date +%s)

mkdir -p "$w/tree" "$w/export" "$w/land/cases"
git archive --format=tar "$sha" | tar -xf - -C "$w/tree" || die "cannot extract $sha into $w/tree"
trc=0; crc=0; prc=0
if [ -s "$w/sel" ]; then
filter=""
if [ $full = 0 ]; then
  for c in $(cut -d/ -f2 "$w/sel" | LC_ALL=C sort -u); do filter="${filter:+$filter|}FullyQualifiedName~.$c."; done
fi
# The tree is no git work tree (GIT_CEILING_DIRECTORIES): git finds no repo around it, as in ddc.sh.
(cd "$w/tree" && BAYAN_EXPORT_DIR="$w/export" BAYAN_CACHE="$w/tree/tmp/cache" GIT_CEILING_DIRECTORIES="$root/tmp" \
  "$dotnet" test csharp/tests/Bayan.Tests -v q ${filter:+--filter "$filter"}) > "$w/test.out" 2>&1
trc=$?
[ $trc = 0 ] || { tail -20 "$w/test.out" >&2; echo "reexport-check: the export run exited $trc (log: $w/test.out)" >&2; }

cp tests/inventory-019.tsv "$w/land/"
GIT_CEILING_DIRECTORIES="$root/tmp" bash scripts/selfhost/land-export.sh "$w/export" "$w/tree" "$w/land/cases" > "$w/land.out" 2>&1 ||
  { cat "$w/land.out" >&2; die "land-export.sh refused the re-export"; }

case "$(uname -s)" in (Darwin) os=macos ;; (Linux) os=linux ;; (MINGW*|MSYS*|CYGWIN*) os=windows ;; (*) os=unknown ;; esac
# rows: <path>\t<tree blob or empty>\t<re-export blob or empty>\t<skip: div, os or empty>, one per compared path
: > "$w/tpaths"; : > "$w/epaths"
while IFS= read -r kc; do
  [ ! -d "$cases/$kc" ] || find "$cases/$kc" -type f -name 'expected.*' >> "$w/tpaths"
  [ ! -d "$w/land/cases/$kc" ] || (cd "$w/land" && find "cases/$kc" -type f -name 'expected.*') | sed 's|^|tests/|' >> "$w/epaths"
done < "$w/sel"
awk -F'\t' -v sel="$w/sel" 'BEGIN { while ((getline l < sel) > 0) want["tests/cases/" l "/"] = 1 }
  $1 == "file" { p = $3; split(p, a, "/"); if ((a[1] "/" a[2] "/" a[3] "/" a[4] "/") in want) print p }' "$cases/FREEZE.tsv" >> "$w/tpaths"
LC_ALL=C sort -u "$w/tpaths" "$w/epaths" > "$w/paths"
: > "$w/thash"; : > "$w/ehash"
while IFS= read -r p; do
  [ ! -f "$p" ] || printf '%s\n' "$p" >> "$w/thash"
  [ ! -f "$w/land/${p#tests/}" ] || printf '%s\n' "$w/land/${p#tests/}" >> "$w/ehash"
done < "$w/paths"
hashes() { [ -s "$1" ] || return 0; git hash-object --stdin-paths < "$1" | paste -d "$tab" "$1" -; }
hashes "$w/thash" > "$w/tb"; hashes "$w/ehash" | sed "s|^$w/land/|tests/|" > "$w/eb"
while IFS= read -r kc; do
  [ ! -d "$cases/$kc" ] || find "$cases/$kc" -mindepth 2 -maxdepth 2 -type f -name os
done < "$w/sel" | while IFS= read -r f; do grep -qw "$os" "$f" || printf '%s\n' "${f%/os}"; done | sed 's|^tests/cases/||' > "$w/os-skip"

awk -F'\t' -v tb="$w/tb" -v eb="$w/eb" -v dv="$cases/DIVERGENCES.tsv" -v oss="$w/os-skip" -v fz="$cases/FREEZE.tsv" '
  BEGIN {
    while ((getline l < fz) > 0) { split(l, a, "\t"); if (a[1] == "file") row[a[3]] = 1 }
    while ((getline l < tb) > 0) { i = index(l, "\t"); t[substr(l, 1, i - 1)] = substr(l, i + 1) }
    while ((getline l < eb) > 0) { i = index(l, "\t"); e[substr(l, 1, i - 1)] = substr(l, i + 1) }
    while ((getline l < dv) > 0) { split(l, a, "\t"); if (a[1] != "case") div[a[1]] = 1 }
    while ((getline l < oss) > 0) skipos[l] = 1
  }
  {
    p = $0; key = substr(p, 13); sub(/\/[^\/]*$/, "", key); split(key, k, "/"); name = k[3]; base = name; sub(/-[0-9]+$/, "", base)
    if (key in div || (k[2] "." name) in div || (k[2] "." base) in div) { ndiv++; next }
    if (key in skipos) { nos++; next }
    if ((p in e) && !(p in t) && !(p in row)) { norow[++nnr] = p; next }
    n++
    if (!(p in e)) { print "reexport-check: missing from the re-export: " p; bad++ }
    else if (!(p in t)) { print "reexport-check: extra (re-exported, not in the tree): " p; bad++ }
    else if (t[p] != e[p]) { print "reexport-check: differs from the frozen compiler: " p; bad++ }
  }
  END {
    if (nnr > 0) {
      printf "reexport-check: re-exported with no manifest row (no L043 row, not compared): %d files\n", nnr
      for (i = 1; i <= nnr; i++) print "  " norow[i]
    }
    printf "reexport-check: %d files compared, %d on the divergence list, %d skipped by an os file, %d failed\n", n, ndiv, nos, bad
    exit (bad > 0) }' "$w/paths"
crc=$?
fi
if [ -s "$w/runits" ]; then
  # the C# CLI from the same tree (dotnet test built its projects already when there was an export run)
  (cd "$w/tree" && GIT_CEILING_DIRECTORIES="$root/tmp" "$dotnet" build csharp/Bayan.Cli -v q -o "$w/cs") > "$w/build.out" 2>&1 ||
    { tail -20 "$w/build.out" >&2; die "the C# CLI build failed (log: $w/build.out)"; }
  mkdir -p "$w/replay"
  bash scripts/selfhost/replay-csharp.sh "$w/cs/bayan" "$w/runits" "$w/replay"
  prc=$?
fi
[ $crc = 0 ] && [ $trc = 0 ] && [ $prc = 0 ] || die "L043 does not hold for the classes above"
rm -rf "$w"
echo "reexport-check: ok in $(( $(date +%s) - start ))s"
