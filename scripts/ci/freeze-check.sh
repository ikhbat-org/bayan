#!/usr/bin/env bash
# Checks the freeze manifest tests/cases/FREEZE.tsv against the tree (spec 019 R13, T20; L043 reads its rows).
#   scripts/ci/freeze-check.sh <rev>    the tree, manifest, EXPORT.tsv and DIVERGENCES.tsv of <rev>; no worktree read
#   scripts/ci/freeze-check.sh          the worktree: HEAD, with the files `git diff HEAD` names and the untracked files under
#                                       tests/cases taken from the worktree (what `git add -A tests/cases` would commit)
#   scripts/ci/freeze-check.sh --write  rewrites the cases and file rows of the worktree's FREEZE.tsv from the worktree view
#                                       above, keeping its tag and export rows (a golden update runs it, R14)
# FREEZE.tsv has three tab-separated columns, the row type first and the path last (paths hold spaces):
#   tag     <tag>     <its commit, 40 hex>      the tag the freeze was exported at (a commit cannot name its own sha)
#   export  <branch>  <its head, 40 hex>        the export branch head that L043 and T59 build the C# compiler from
#   cases   <kind>    <n>                       one row per kind: the case keys of its frozen files, sorted (LC_ALL=C)
#   file    <blob>    <path>                    one row per frozen file, sorted by path (LC_ALL=C); <blob> is the git blob id
# Frozen file: an expected file as scripts/ci/golden-commit-check.sh `is_expected` defines it (copied below as an awk regex; keep
# the two in step, scripts/ci/freeze-check.test.sh compares them), plus tests/cases/emit/run-c.sha256. Case key: the directory of
# an expected.* file, else the path without its last extension; the kind is its first directory under tests/cases.
# Refused (each line names the path or row):
#   - a malformed manifest (not 1 tag and 1 export row, a bad sha or count, an unknown row type, a duplicate file row);
#   - the tag resolves to another commit than its row (a tag that does not resolve, as in a shallow clone, is a note);
#   - a file row whose file is gone or whose blob differs, a frozen file with no row, a cases row that differs from the recount;
#   - an EXPORT.tsv row whose cases differ from its case directories, a class directory under cli, sem, emit-c, parse or lex
#     with no EXPORT.tsv row (a row of kind `shell` is only checked for a numeric count: its cases are the files under
#     runtime/tests/cases that runtime/tests/run.sh replays, outside tests/cases);
#   - a DIVERGENCES.tsv row with a field `pending`, or whose case starts with a kind directory and is no frozen file's case key.
# Exit 0 clean, 1 refused (on stderr), 2 usage or git error.
set -uo pipefail
usage() { echo "usage: scripts/ci/freeze-check.sh [<rev> | --write]" >&2; exit 2; }
[ $# -le 1 ] || usage
write=0; rev=""
case "${1:-}" in
  (--write) write=1 ;;
  (-*) usage ;;
  ("") ;;
  (*) rev="$1" ;;
esac
top="$(git rev-parse --show-toplevel 2> /dev/null)" || { echo "freeze-check: not in a git repo" >&2; exit 2; }
cd "$top" || exit 2
if [ -n "$rev" ]; then
  git rev-parse -q --verify "$rev^{commit}" > /dev/null || { echo "freeze-check: unknown rev '$rev'" >&2; exit 2; }
  base="$rev"
else
  base=HEAD
fi
manifest=tests/cases/FREEZE.tsv
tab="$(printf '\t')"
work="$(mktemp -d "${TMPDIR:-/tmp}/freeze-check.XXXXXX")" || exit 2
trap 'rm -rf "$work"' EXIT

# view: every file under tests/cases at <base>, `<mode> blob <sha>\t<path>`; one ls-tree pass
git -c core.quotepath=off ls-tree -r "$base" -- tests/cases > "$work/view" || { echo "freeze-check: git ls-tree $base failed" >&2; exit 2; }

# overlay (worktree mode): <path>\t<blob>, an empty blob for a deleted file; only these worktree paths are read
: > "$work/overlay"
if [ -z "$rev" ]; then
  { git -c core.quotepath=off diff --no-renames --name-only HEAD -- tests/cases &&
    git -c core.quotepath=off ls-files --others --exclude-standard -- tests/cases; } > "$work/changed" ||
    { echo "freeze-check: git diff HEAD failed" >&2; exit 2; }
  : > "$work/present"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -f "$p" ]; then printf '%s\n' "$p" >> "$work/present"; else printf '%s\t\n' "$p" >> "$work/overlay"; fi
  done < "$work/changed"
  if [ -s "$work/present" ]; then
    # the blob `git add` would store (filters applied, so CRLF under eol=lf hashes as committed)
    git hash-object --stdin-paths < "$work/present" > "$work/hashes" || { echo "freeze-check: git hash-object failed" >&2; exit 2; }
    paste -d "$tab" "$work/present" "$work/hashes" >> "$work/overlay"
  fi
fi

# show <path> <out>: the file as the view holds it (worktree if the overlay names it, else <base>); 1 when it is absent
show() {
  if grep -q -F -x -e "$1$tab" "$work/overlay"; then return 1; fi
  if awk -F'\t' -v p="$1" '$1 == p && $2 != "" { f = 1 } END { exit !f }' "$work/overlay"; then cat "$1" > "$2"; return 0; fi
  git show "$base:$1" > "$2" 2> /dev/null
}

if [ $write = 1 ]; then
  show "$manifest" "$work/old" || { echo "freeze-check: no $manifest: write its tag and export rows first" >&2; exit 2; }
  grep -E "^(tag|export)$tab" "$work/old" > "$work/head"
  [ "$(grep -c "^tag$tab" "$work/head")" = 1 ] && [ "$(grep -c "^export$tab" "$work/head")" = 1 ] ||
    { echo "freeze-check: $manifest needs one tag and one export row before --write" >&2; exit 2; }
fi
if [ $write = 0 ]; then
  show "$manifest" "$work/manifest" || { echo "freeze-check: no $manifest at ${rev:-the worktree}" >&2; exit 1; }
  show tests/cases/EXPORT.tsv "$work/export" || : > "$work/export"
  show tests/cases/DIVERGENCES.tsv "$work/div" || : > "$work/div"
fi

awk -F'\t' -v write=$write -v view="$work/view" -v overlay="$work/overlay" -v mf="$work/manifest" -v ex="$work/export" \
  -v dv="$work/div" -v out="$work/rows" '
  # the frozen-file predicate: golden-commit-check.sh is_expected plus run-c.sha256 (p is under tests/cases/, as ls-tree gives it)
  function isexp(p) {
    if (p == "tests/cases/out/results-fail.json" || p == "tests/cases/emit/run-c.sha256") return 1
    if (index(substr(p, 12), "/expected.") > 1) return 1
    return match(p, /\.[^.\/]*$/) && (substr(p, RSTART + 1) in exts)
  }
  function casekey(rel,   b) {
    match(rel, /[^\/]*$/); b = substr(rel, RSTART)
    if (substr(b, 1, 9) == "expected.") return substr(rel, 1, RSTART - 2)
    if (match(b, /\.[^.]*$/)) return substr(rel, 1, length(rel) - length(b) + RSTART - 1)
    return rel
  }
  function kindof(key,   i) { i = index(key, "/"); return i ? substr(key, 1, i - 1) : "." }
  function bad(m) { print "freeze-check: " m; nbad++ }
  BEGIN {
    split("tokens ast diag jsonl types stdout stderr exitcode tree color plain ascii", a, " "); for (i in a) exts[a[i]] = 1
    while ((getline l < view) > 0) if (substr(l, 8, 5) == "blob ") blob[substr(l, 54)] = substr(l, 13, 40)
    while ((getline l < overlay) > 0) {
      i = index(l, "\t"); p = substr(l, 1, i - 1); b = substr(l, i + 1); ov[p] = 1
      if (b == "") delete blob[p]; else blob[p] = b
    }
    for (p in blob) {
      rel = substr(p, 13); n = split(rel, a, "/")
      if (n >= 2) kinds[a[1]] = 1
      if (n >= 3 && (a[1] == "cli" || a[1] == "sem" || a[1] == "emit-c" || a[1] == "parse" || a[1] == "lex")) cls[a[1] "\t" a[2]] = 1
      if (n >= 4 && !((a[1] "/" a[2] "/" a[3]) in cdir)) { cdir[a[1] "/" a[2] "/" a[3]] = 1; ncdir[a[1] "\t" a[2]]++ }
      if (!isexp(p)) continue
      frozen[p] = 1; k = casekey(rel)
      if (!(k in keys)) { keys[k] = 1; tcount[kindof(k)]++ }
    }
    if (write) {
      for (k in tcount) print "cases\t" k "\t" tcount[k] > out
      for (p in frozen) print "file\t" blob[p] "\t" p > out
      exit 0
    }
    # the manifest
    ln = 0; ntag = 0; nexp = 0
    while ((getline l < mf) > 0) {
      ln++; n = split(l, a, "\t")
      if (n != 3) { bad("FREEZE.tsv line " ln ": " n " columns, not 3"); continue }
      if (a[1] == "tag" || a[1] == "export") {
        if (a[3] !~ /^[0-9a-f]+$/ || length(a[3]) != 40) bad("FREEZE.tsv line " ln ": " a[1] " " a[2] " has no 40-hex commit")
        if (a[1] == "tag") { ntag++; print "TAG\t" a[2] "\t" a[3] } else nexp++
      } else if (a[1] == "cases") {
        if (a[3] !~ /^[0-9]+$/) bad("FREEZE.tsv line " ln ": cases " a[2] " has no count")
        else if (a[2] in mcount) bad("FREEZE.tsv line " ln ": duplicate cases row for kind " a[2])
        else mcount[a[2]] = a[3] + 0
      } else if (a[1] == "file") {
        if (a[2] !~ /^[0-9a-f]+$/ || length(a[2]) != 40) bad("FREEZE.tsv line " ln ": file " a[3] " has no 40-hex blob id")
        else if (a[3] in row) bad("FREEZE.tsv line " ln ": duplicate file row: " a[3])
        else row[a[3]] = a[2]
      } else bad("FREEZE.tsv line " ln ": unknown row type " a[1])
    }
    if (ntag != 1) bad("FREEZE.tsv has " ntag " tag rows, not 1")
    if (nexp != 1) bad("FREEZE.tsv has " nexp " export rows, not 1")
    for (p in row) {
      u = (p in ov) ? " (uncommitted)" : ""
      if (!(p in blob)) bad("frozen file removed" u ": " p)
      else if (blob[p] != row[p]) bad("frozen file differs from its digest" u ": " p)
      else if (!(p in frozen)) bad("file row names a file that is not an expected file: " p)
    }
    for (p in frozen) if (!(p in row)) bad("expected file has no manifest row: " p)
    for (k in tcount) if (!(k in mcount)) bad("kind " k ": " tcount[k] " cases, no manifest cases row")
    for (k in mcount) if (mcount[k] != tcount[k] + 0) bad("kind " k ": " tcount[k] + 0 " cases, manifest " mcount[k])
    # EXPORT.tsv: class, kind, tests, cases, reason
    ln = 0
    while ((getline l < ex) > 0) {
      ln++; split(l, a, "\t"); if (ln == 1 && a[1] == "class") continue
      key = a[2] "\t" a[1]
      if (key in exrow) { bad("EXPORT.tsv line " ln ": duplicate row " a[1] " " a[2]); continue }
      exrow[key] = 1
      if (a[2] == "shell") { if (a[4] !~ /^[0-9]+$/) bad("EXPORT.tsv row " a[1] " shell: cases " a[4] " is not a count"); continue }
      if (a[4] + 0 != ncdir[key] + 0 || a[4] !~ /^[0-9]+$/)
        bad("EXPORT.tsv row " a[1] " " a[2] ": cases " a[4] ", " ncdir[key] + 0 " case directories under tests/cases/" a[2] "/" a[1])
    }
    for (key in cls) if (!(key in exrow)) { split(key, a, "\t"); bad("EXPORT.tsv has no row for class " a[2] " (tests/cases/" a[1] "/" a[2] ")") }
    # DIVERGENCES.tsv: case, question, right, reason; a package case is named by its directory (run/x for run/x/main.stdout), as replay-csharp.sh names it
    ln = 0
    while ((getline l < dv) > 0) {
      ln++; n = split(l, a, "\t"); if (ln == 1 && a[1] == "case") continue
      for (i = 1; i <= n; i++) if (a[i] == "pending") { bad("DIVERGENCES.tsv line " ln ": " a[1] " is pending (column " i ")"); break }
      if ((kindof(a[1]) in kinds) && !(a[1] in keys) && !((a[1] "/main") in keys)) bad("DIVERGENCES.tsv line " ln ": " a[1] " is no case of a manifest row")
    }
    exit (nbad > 0)
  }' > "$work/report"
rc=$?
if [ $write = 1 ]; then
  [ $rc = 0 ] || { cat "$work/report" >&2; exit 2; }
  { cat "$work/head"
    grep "^cases$tab" "$work/rows" | LC_ALL=C sort -t "$tab" -k2,2
    grep "^file$tab" "$work/rows" | LC_ALL=C sort -t "$tab" -k3; } > "$work/new"
  cmp -s "$work/new" "$manifest" 2> /dev/null && { echo "freeze-check: $manifest unchanged"; exit 0; }
  cp "$work/new" "$manifest"
  echo "freeze-check: wrote $manifest ($(grep -c "^file$tab" "$work/new") file rows)"
  exit 0
fi
bad=0
grep -v "^TAG$tab" "$work/report" >&2 && bad=1
[ $rc -le 1 ] || { echo "freeze-check: awk failed ($rc)" >&2; exit 2; }
[ $rc = 0 ] || bad=1
while IFS="$tab" read -r _ t sha; do
  if have="$(git rev-parse -q --verify "refs/tags/$t^{commit}")"; then
    [ "$have" = "$sha" ] || { echo "freeze-check: tag $t is $have, the manifest records $sha" >&2; bad=1; }
  else
    echo "freeze-check: note: tag $t does not resolve here, not compared"
  fi
done < <(grep "^TAG$tab" "$work/report")
[ $bad = 0 ] || { echo "freeze-check: refused at ${rev:-the worktree}" >&2; exit 1; }
echo "freeze-check: ok ($(grep -c "^file$tab" "$work/manifest") frozen files at ${rev:-the worktree})"
