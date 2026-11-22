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
#   2. in tree/: BAYAN_EXPORT_DIR=<w>/export dotnet test csharp/tests/Bayan.Tests -v q --filter <the classes> (--full too: tests
#      of no export class, which write no case, do not run), the export mode that wrote the cases (src/tests/SelfhostExport.cs on
#      that head);
#   3. scripts/selfhost/land-export.sh lands the export into land/cases (the land-time masks the tree's cases went through);
#   4. for each chosen <kind>/<Class>, every file under tests/cases/<kind>/<Class>/ with a FREEZE.tsv row or named expected.*,
#      in the tree or in land/cases, is compared by git blob id (the attributes of the tree's path, as FREEZE.tsv records);
#      a tree case dir pairs with a re-exported one by content, not name (the export numbers a test's cases in its own
#      order): its key is its section and input.byn.ref blobs, else its input.byn.ref and args blobs, else (a class with
#      neither) its name; of equal keys, equal name and expected.* blobs pair first, then equal expected.* blobs (in name
#      order), then equal names, the rest in blob-id order, and a case left over is missing or extra; a pair's path is the
#      tree's name, followed by "(re-exported as <name>)" when the names differ. Masks, on both sides before hashing:
#      SelfhostDefaultP2Tests section and expected.*, the mktemp suffix p2-errors-XXXXXX; SelfhostDefaultT9Tests
#      expected.names, the hashes in cache/v1/programs/<sha256>/ and cache/v1/runtime/<sha256>/. One that differs, is missing
#      from the re-export or is extra (landed, not in the tree) fails with its path, unless its
#      case is on tests/cases/DIVERGENCES.tsv (the case key <kind>/<Class>/<case>, or <Class>.<Test> for <case> <Test> or
#      <Test>-<n>) or holds an `os` file that does not name this host's OS (macos, linux, windows); both are counted. A landed
#      file with no FREEZE.tsv row and not in the tree (a case the owner removed) is no L043 row: it is listed, not failed.
#      A chosen class the export wrote no case dir for and listed in its <kind>/UNEXPORTED.tsv (export mode ran its compare
#      calls and wrote nothing, as SelfhostExport.NotExported records) is not export-written: counted, not compared.
# A row a golden update changed since the freeze differs from the frozen compiler's output: it belongs on DIVERGENCES.tsv.
# The work dir is removed when the run passes and kept, and named, otherwise. Exit 0 when every compared file matches, 1 when
# one does not, the export run fails or no .NET is on PATH (nothing is checked then: never a pass), 2 on a usage error or an
# export head not in the clone. Tests only: REEXPORT_DOTNET replaces `dotnet`, REEXPORT_RUNNER the golden runner
# the replay builds from src/driver, REEXPORT_COMPARE=<work dir> runs step 4 alone on a kept work dir's sel and land/cases. bash 3.2.
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
# compare <sel> <land dir> <scratch dir> <export dir>: step 4 over the classes in <sel>, the tree's tests/cases against
# <land dir>/cases; prints the exceptions and the counts, returns 1 when a file failed; writes only under <scratch dir>.
compare() {
  local sel="$1" land="$2" s="$3" ex="$4" kc os side dir k f t nx=0
  case "$(uname -s)" in (Darwin) os=macos ;; (Linux) os=linux ;; (MINGW*|MSYS*|CYGWIN*) os=windows ;; (*) os=unknown ;; esac
  # not export-written (header): no case dir in the export and a row of its own in the export's <kind>/UNEXPORTED.tsv
  : > "$s/sel.w"
  while IFS= read -r kc; do
    if [ ! -d "$ex/$kc" ] && [ -f "$ex/${kc%%/*}/UNEXPORTED.tsv" ] && cut -f1 "$ex/${kc%%/*}/UNEXPORTED.tsv" | grep -qxF "${kc#*/}"
    then nx=$((nx + 1)); else printf '%s\n' "$kc" >> "$s/sel.w"; fi
  done < "$sel"
  [ $nx = 0 ] || echo "reexport-check: not export-written: $nx classes (no case in the export, its calls in UNEXPORTED.tsv; not compared)"
  sel="$s/sel.w"
  # files: <side t or e>\t<kind>/<Class>\t<case>\t<file>\t<path hashed>, the key files and expected.* files of each case dir
  : > "$s/files"
  while IFS= read -r kc; do
    for side in t e; do
      if [ $side = t ]; then dir="$cases"; else dir="$land/cases"; fi
      [ ! -d "$dir/$kc" ] || (cd "$dir" && find "$kc" -mindepth 2 -maxdepth 2 -type f \
        \( -name 'expected.*' -o -name section -o -name input.byn.ref -o -name args \)) |
        awk -F/ -v sd=$side -v d="$dir/" '{ print sd "\t" $1 "/" $2 "\t" $3 "\t" $4 "\t" d $0 }' >> "$s/files"
    done
  done < "$sel"
  # the masks (header): a masked file is hashed from a masked copy under <scratch>/m, on both sides
  : > "$s/masks"; mkdir -p "$s/m"
  awk -F'\t' -v m="$s/m/" -v ml="$s/masks" 'BEGIN { OFS = "\t" }
    { c = $2; sub(/^[^\/]*\//, "", c); k = ""
      if (c == "SelfhostDefaultP2Tests" && ($4 == "section" || $4 ~ /^expected\./)) k = "p2"
      else if (c == "SelfhostDefaultT9Tests" && $4 == "expected.names") k = "t9"
      if (k != "") { n++; print k "\t" $5 "\t" m n > ml; $5 = m n }
      print }' "$s/files" > "$s/files.m"
  while IFS="$tab" read -r k f t; do
    case $k in
      (p2) sed -E 's/p2-errors-[A-Za-z0-9]{6}/p2-errors-<tmp>/g' "$f" > "$t" ;;
      (t9) sed -E 's#cache/v1/(programs|runtime)/[0-9a-f]{64}/#cache/v1/\1/<sha>/#g' "$f" > "$t" ;;
    esac
  done < "$s/masks"
  : > "$s/hashed"
  [ ! -s "$s/files.m" ] || cut -f5 "$s/files.m" | git hash-object --stdin-paths | paste -d "$tab" "$s/files.m" - |
    LC_ALL=C sort -t "$tab" -k1,1 -k2,2 -k3,3 -k4,4 > "$s/hashed"
  # the pairing (header): per case dir its key and the blob ids of its expected.* files by name (its signature); of equal keys,
  # equal name and signature pair first, then equal signatures, then equal names, the rest in signature order
  awk -F'\t' 'function out() { if (id == "") return
      if (sec != "") key = "s" sec ":" ref; else if (ref != "" || arg != "") key = "a" ref ":" arg; else key = "n" cs
      print kc "\t" key "\t" sig "\t" sd "\t" cs }
    { i = $1 "\t" $2 "\t" $3; if (i != id) { out(); id = i; sd = $1; kc = $2; cs = $3; sec = ref = arg = sig = "" }
      if ($4 == "section") sec = $6; else if ($4 == "input.byn.ref") ref = $6; else if ($4 == "args") arg = $6; else sig = sig $4 "=" $6 ";" }
    END { out() }' "$s/hashed" | LC_ALL=C sort -t "$tab" -k1,1 -k2,2 -k3,3 -k5,5 |
    awk -F'\t' 'function pair(i, j) { ut[i] = 1; used[j] = 1; print g1 "\t" t[i] "\t" e[j] }
      function flush(  i, j, n, q) {
        split("", b); split("", en); split("", ut); split("", used); split("", lt); split("", le); n = q = 0
        for (j = 1; j <= ne; j++) en[e[j] SUBSEP es[j]] = j
        for (i = 1; i <= nt; i++) if ((t[i] SUBSEP ts[i]) in en) pair(i, en[t[i] SUBSEP ts[i]])
        for (j = ne; j >= 1; j--) if (!(j in used)) b[es[j]] = j " " b[es[j]]
        for (i = 1; i <= nt; i++) if (!(i in ut) && b[ts[i]] != "") { j = b[ts[i]] + 0; sub(/^[0-9]+ /, "", b[ts[i]]); pair(i, j) }
        split("", en); for (j = 1; j <= ne; j++) if (!(j in used)) en[e[j]] = j
        for (i = 1; i <= nt; i++) if (!(i in ut) && t[i] in en) pair(i, en[t[i]])
        for (i = 1; i <= nt; i++) if (!(i in ut)) lt[++q] = t[i]
        for (j = 1; j <= ne; j++) if (!(j in used)) le[++n] = e[j]
        for (i = 1; i <= (q > n ? q : n); i++) print g1 "\t" lt[i] "\t" le[i]
        nt = ne = 0 }
      { g = $1 "\t" $2; if (g != gk) { if (gk != "") flush(); gk = g; g1 = $1 }
        if ($4 == "t") { t[++nt] = $5; ts[nt] = $3 } else { e[++ne] = $5; es[ne] = $3 } }
      END { if (gk != "") flush() }' | LC_ALL=C sort > "$s/pairs"
  while IFS= read -r kc; do
    [ ! -d "$cases/$kc" ] || find "$cases/$kc" -mindepth 2 -maxdepth 2 -type f -name os
  done < "$sel" | while IFS= read -r f; do grep -qw "$os" "$f" || printf '%s\n' "${f%/os}"; done | sed 's|^tests/cases/||' > "$s/os-skip"

  awk -F'\t' -v hs="$s/hashed" -v dv="$cases/DIVERGENCES.tsv" -v oss="$s/os-skip" -v fz="$cases/FREEZE.tsv" '
    BEGIN {
      while ((getline l < fz) > 0) { split(l, a, "\t"); if (a[1] == "file") row[a[3]] = 1 }
      while ((getline l < hs) > 0) { split(l, a, "\t"); if (a[4] !~ /^expected\./) continue
        c = a[1] SUBSEP a[2] SUBSEP a[3]; h[c, a[4]] = a[6]; fl[c] = fl[c] "\t" a[4] }
      while ((getline l < dv) > 0) { split(l, a, "\t"); if (a[1] != "case") div[a[1]] = 1 }
      while ((getline l < oss) > 0) skipos[l] = 1
    }
    {
      kc = $1; tc = $2; ec = $3; name = tc != "" ? tc : ec; key = kc "/" name
      split(kc, k, "/"); base = name; sub(/-[0-9]+$/, "", base)
      as = (tc != "" && ec != "" && tc != ec) ? " (re-exported as " ec ")" : ""
      split("", seen); nf = 0
      if (tc != "") { m = split(substr(fl["t", kc, tc], 2), x, "\t"); for (i = 1; i <= m; i++) if (!(x[i] in seen)) { seen[x[i]] = 1; f[++nf] = x[i] } }
      if (ec != "") { m = split(substr(fl["e", kc, ec], 2), x, "\t"); for (i = 1; i <= m; i++) if (!(x[i] in seen)) { seen[x[i]] = 1; f[++nf] = x[i] } }
      for (i = 1; i <= nf; i++) {
        p = "tests/cases/" key "/" f[i]; it = (tc != "" && (("t", kc, tc, f[i]) in h)); ie = (ec != "" && (("e", kc, ec, f[i]) in h))
        if (key in div || (k[2] "." name) in div || (k[2] "." base) in div) { ndiv++; continue }
        if (key in skipos) { nos++; continue }
        if (ie && !it && !(p in row)) { norow[++nnr] = p; continue }
        n++
        if (!ie) { print "reexport-check: missing from the re-export: " p as; bad++ }
        else if (!it) { print "reexport-check: extra (re-exported, not in the tree): " p as; bad++ }
        else if (h["t", kc, tc, f[i]] != h["e", kc, ec, f[i]]) { print "reexport-check: differs from the frozen compiler: " p as; bad++ }
      }
    }
    END {
      if (nnr > 0) {
        printf "reexport-check: re-exported with no manifest row (no L043 row, not compared): %d files\n", nnr
        for (i = 1; i <= nnr; i++) print "  " norow[i]
      }
      printf "reexport-check: %d files compared, %d on the divergence list, %d skipped by an os file, %d failed\n", n, ndiv, nos, bad
      exit (bad > 0) }' "$s/pairs"
}
if [ -n "${REEXPORT_COMPARE:-}" ]; then
  mkdir -p tmp; s="$(mktemp -d "$root/tmp/reexport-compare.XXXXXX")"
  compare "$REEXPORT_COMPARE/sel" "$REEXPORT_COMPARE/land" "$s" "$REEXPORT_COMPARE/export"; rc=$?; rm -rf "$s"; exit $rc
fi
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
  case "$kind" in
    (emit) sed -n 's/^[^ ]*  /emit /p' "$cases/emit/modes/expected.debug.sha256" "$cases/emit/exit/expected.diag.exitcode" 2> /dev/null |
      LC_ALL=C sort -u > "$w/flat/emit"; continue ;;
    (run|style|new|out)
      awk -F'\t' -v k="$kind" '$1 == "file" { p = substr($3, 13); if (index(p, k "/") != 1 || p !~ /\.(stdout|stderr|exitcode|color|plain|ascii|tree|json)$/) next
        sub(/\.[a-z]+$/, "", p); sub(/\/main$/, "", p); print "golden " p }' "$cases/FREEZE.tsv" | LC_ALL=C sort -u > "$w/flat/$kind"; continue ;;
    (parse) e=ast ;; (typed) e=types ;; (diag) e=diag ;; (*) e="" ;;
  esac
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

dotnet="${REEXPORT_DOTNET:-}"
# A shell whose PATH came from an older login (a Claude Code shell snapshot, a launchd job) can lack the SDK dir that
# ~/.zshenv or /etc/paths.d adds: past PATH, try $DOTNET_ROOT, the installer's root, then ~/.dotnet (dotnet-install.sh).
if [ -z "$dotnet" ]; then
  for d in dotnet ${DOTNET_ROOT:+"$DOTNET_ROOT/dotnet"} /usr/local/share/dotnet/dotnet "$HOME/.dotnet/dotnet"; do
    command -v "$d" > /dev/null 2>&1 || continue
    dotnet=$d
    [ "$d" = dotnet ] || { export PATH="${d%/dotnet}:$PATH"; export DOTNET_ROOT="${DOTNET_ROOT:-${d%/dotnet}}"; }
    break
  done
  [ -n "$dotnet" ] || dotnet=dotnet
fi
# The frozen tree's projects stay as frozen: a NuGet advisory published after the freeze (NU1903 on
# Microsoft.DotNet.ILCompiler 10.0.12, GHSA-p3jp-9v83-76w9, 2026-11-21) would fail their build under warnings-as-errors.
export NuGetAudit=false
command -v "$dotnet" > /dev/null 2>&1 ||
  { echo "reexport-check: no dotnet on PATH, in \$DOTNET_ROOT, /usr/local/share/dotnet or ~/.dotnet: L043 is not checked here (the R27 job, .github/workflows/ddc.yml, runs it)" >&2; rm -rf "$w"; exit 1; }
die() { echo "reexport-check: $1 (work dir kept: $w)" >&2; exit 1; }
start=$(date +%s)

mkdir -p "$w/tree" "$w/export" "$w/land/cases"
git archive --format=tar "$sha" | tar -xf - -C "$w/tree" || die "cannot extract $sha into $w/tree"
trc=0; crc=0; prc=0
if [ -s "$w/sel" ]; then
filter=""
for c in $(cut -d/ -f2 "$w/sel" | LC_ALL=C sort -u); do filter="${filter:+$filter|}FullyQualifiedName~.$c."; done
# The tree is no git work tree (GIT_CEILING_DIRECTORIES): git finds no repo around it, as in ddc.sh.
(cd "$w/tree" && BAYAN_EXPORT_DIR="$w/export" BAYAN_CACHE="$w/tree/tmp/cache" GIT_CEILING_DIRECTORIES="$root/tmp" \
  "$dotnet" test csharp/tests/Bayan.Tests -v q ${filter:+--filter "$filter"}) > "$w/test.out" 2>&1
trc=$?
[ $trc = 0 ] || { tail -20 "$w/test.out" >&2; echo "reexport-check: the export run exited $trc (log: $w/test.out)" >&2; }

cp tests/inventory-019.tsv "$w/land/"
GIT_CEILING_DIRECTORIES="$root/tmp" bash scripts/selfhost/land-export.sh "$w/export" "$w/tree" "$w/land/cases" > "$w/land.out" 2>&1 ||
  { cat "$w/land.out" >&2; die "land-export.sh refused the re-export"; }

compare "$w/sel" "$w/land" "$w" "$w/export"
crc=$?
fi
if [ -s "$w/runits" ]; then
  # the C# CLI from the same tree (dotnet test built its projects already when there was an export run)
  (cd "$w/tree" && GIT_CEILING_DIRECTORIES="$root/tmp" "$dotnet" build csharp/Bayan.Cli -v q -o "$w/cs") > "$w/build.out" 2>&1 ||
    { tail -20 "$w/build.out" >&2; die "the C# CLI build failed (log: $w/build.out)"; }
  # the golden runner for the run, style, new and out cases: src/driver of this checkout, built with the pinned bayan
  runner=""
  if grep -q '^golden ' "$w/runits"; then
    runner="${REEXPORT_RUNNER:-$w/drv/bayan}"
    if [ -z "${REEXPORT_RUNNER:-}" ]; then
      pinned="$(bash scripts/pinned-bayan.sh 2> "$w/drv.out")" && mkdir -p "$w/drv" &&
        "$pinned" build --mode safe --package src -o "$runner" src/driver >> "$w/drv.out" 2>&1 ||
        { tail -20 "$w/drv.out" >&2; die "the golden runner build failed (log: $w/drv.out)"; }
    fi
  fi
  mkdir -p "$w/replay"
  bash scripts/selfhost/replay-csharp.sh "$w/cs/bayan" "$w/runits" "$w/replay" ${runner:+"$runner"}
  prc=$?
fi
[ $crc = 0 ] && [ $trc = 0 ] && [ $prc = 0 ] || die "L043 does not hold for the classes above"
rm -rf "$w"
echo "reexport-check: ok in $(( $(date +%s) - start ))s"
