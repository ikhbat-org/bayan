#!/usr/bin/env bash
# Spec 019 T59, the L043 check: re-exports golden cases with the frozen C# compiler and compares them with the tree.
#   bash scripts/selfhost/reexport-check.sh [--seed S | --class <kind>/<Class> ... | --full]
# The classes: the EXPORT.tsv rows with cases (kind `shell` aside). Default: one class per kind, picked by the seed (S, else the
# ISO week `date -u +%G%V`): of a kind's classes sorted (LC_ALL=C), number 1 + (cksum of "S kind") mod n. --class names classes
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
#      <Test>-<n>) or holds an `os` file that does not name this host's OS (macos, linux, windows); both are counted.
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
awk -F'\t' 'NR > 1 && $2 != "shell" && $4 + 0 > 0 { print $2 "/" $1 }' "$cases/EXPORT.tsv" | LC_ALL=C sort -u > "$w/all"
if [ $full = 1 ]; then
  cp "$w/all" "$w/sel"; what="all classes"
elif [ -n "$picked" ]; then
  : > "$w/sel"
  for c in $picked; do
    grep -qxF "$c" "$w/all" || { echo "reexport-check: $c is no EXPORT.tsv class with cases" >&2; rm -rf "$w"; exit 2; }
    echo "$c" >> "$w/sel"
  done
  what="named classes"
else
  seed="${seed:-$(date -u +%G%V)}"; : > "$w/sel"
  for kind in $(cut -d/ -f1 "$w/all" | uniq); do
    k=$(grep -c "^$kind/" "$w/all"); h=$(printf '%s %s' "$seed" "$kind" | cksum | cut -d' ' -f1)
    grep "^$kind/" "$w/all" | sed -n "$((h % k + 1))p" >> "$w/sel"
  done
  what="seed $seed"
fi
echo "== reexport-check: export $ref ($(echo "$sha" | cut -c1-12)), $what: $(wc -l < "$w/sel" | tr -d ' ') classes"
[ $full = 1 ] || sed 's/^/  /' "$w/sel"

dotnet="${REEXPORT_DOTNET:-dotnet}"
command -v "$dotnet" > /dev/null 2>&1 ||
  { echo "reexport-check: no dotnet on PATH: L043 is not checked here (the R27 job, .github/workflows/ddc.yml, runs it)" >&2; rm -rf "$w"; exit 1; }
die() { echo "reexport-check: $1 (work dir kept: $w)" >&2; exit 1; }
start=$(date +%s)

mkdir -p "$w/tree" "$w/export" "$w/land/cases"
git archive --format=tar "$sha" | tar -xf - -C "$w/tree" || die "cannot extract $sha into $w/tree"
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

awk -F'\t' -v tb="$w/tb" -v eb="$w/eb" -v dv="$cases/DIVERGENCES.tsv" -v oss="$w/os-skip" '
  BEGIN {
    while ((getline l < tb) > 0) { i = index(l, "\t"); t[substr(l, 1, i - 1)] = substr(l, i + 1) }
    while ((getline l < eb) > 0) { i = index(l, "\t"); e[substr(l, 1, i - 1)] = substr(l, i + 1) }
    while ((getline l < dv) > 0) { split(l, a, "\t"); if (a[1] != "case") div[a[1]] = 1 }
    while ((getline l < oss) > 0) skipos[l] = 1
  }
  {
    p = $0; key = substr(p, 13); sub(/\/[^\/]*$/, "", key); split(key, k, "/"); name = k[3]; base = name; sub(/-[0-9]+$/, "", base)
    if (key in div || (k[2] "." name) in div || (k[2] "." base) in div) { ndiv++; next }
    if (key in skipos) { nos++; next }
    n++
    if (!(p in e)) { print "reexport-check: missing from the re-export: " p; bad++ }
    else if (!(p in t)) { print "reexport-check: extra (re-exported, not in the tree): " p; bad++ }
    else if (t[p] != e[p]) { print "reexport-check: differs from the frozen compiler: " p; bad++ }
  }
  END { printf "reexport-check: %d files compared, %d on the divergence list, %d skipped by an os file, %d failed\n", n, ndiv, nos, bad
    exit (bad > 0) }' "$w/paths"
crc=$?
[ $crc = 0 ] && [ $trc = 0 ] || die "L043 does not hold for the classes above"
rm -rf "$w"
echo "reexport-check: ok in $(( $(date +%s) - start ))s"
