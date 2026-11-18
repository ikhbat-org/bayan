#!/usr/bin/env bash
# Spec 019 T17a: lands a C# export (BAYAN_EXPORT_DIR) as golden cases.
#   bash scripts/selfhost/land-export.sh <export dir> <export worktree root> <dest tests/cases>
# Copies every case directory <export>/<kind>/<Class>/<case>/ to <dest>/<kind>/<Class>/<case>/ byte for byte, except:
#   (1) input/ becomes input.tsv, one line per entry sorted by name, `<name>\tfile:<sha256>`, `<name>\tfile+x:<sha256>` (user
#       executable bit) or `<name>\ttree:<sha256>`; files are stored once at <dest>/inputs/files/<sha256>, directories at
#       <dest>/inputs/trees/<sha256>.tsv (same format; a tree's hash is the sha256 of its .tsv text);
#   (1b) the top-level input.byn is stored by content too: it becomes input.byn.ref, the one line `file:<sha256>` into
#       <dest>/inputs/files (T17a2, D5);
#   (2) in every non-input text file, each occurrence of the export worktree root becomes `<repo>`; in input text (input/ files,
#       input.byn, before hashing) too; other top-level input and input.* files are copied unmasked;
#   (2b) land-time masks: in the expected.stdout of a cli case one of whose args lines is `doctor`, the value of an ok row (marker,
#       plain or coloured) labelled host, C compiler, zig or git becomes `<host>`, the cache row too when the case env sets no
#       BAYAN_CACHE (`not found` rows, failure rows and seeded-cache rows stay), and the value of the ok row labelled bayan becomes
#       `<version>`; in SelfhostDefaultT12Tests expected.stdout/expected.stderr everything after a line `C compiler failed (exit N):`
#       becomes the one line `<cc output>`; in SelfhostDefaultT5Tests expected.stdout/expected.stderr `(commit …)` becomes
#       `(commit <c>)` and the rest of `isn't writable: ` up to an escape or the line end becomes `<message>` (the T5 `Mask`);
#       in a cli case's expected.stdout and expected.stderr, a version line the C# `Mask` left as `bayan <version> (masked)` names
#       `<version>` (T19: the tree's version moves on); in every expected.* file, the std module list `import one of `std.json``
#       becomes `import one of <std modules>` (T19: the export shipped std.json alone, the tree ships more);
#   (2c) a non-text file under input/ that still names the export machine (HOME, /Users/, /opt/homebrew) after (2) is left out,
#       and its case and name printed; cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14 lands with no input.tsv (T17c);
#   (2d) a case that fails only because (2c) left out its input (the list `removed` below) is not landed: it is printed and
#       counted in its class's EXPORT.tsv reason as "<n> removed: <case> (<why>)" (T17c ruling 2);
#   (3) cli/SelfhostExport/ is dropped;
#   (4) <dest>/EXPORT.tsv (class, kind, tests, cases, reason) is written: one row per class and kind with cases or with rows in
#       <kind>/UNEXPORTED.tsv, tests from <dest>/../inventory-019.tsv, cases the case directories, reason the class's
#       UNEXPORTED.tsv rows (root masked) and its (2d) removals, empty when it has none.
# A file is written only when its content differs, so a rerun over the same export writes nothing. A symlink or other special
# file, or a name holding a tab, newline or backslash, under input/ stops the run. After landing, any file under <dest> holding
# this machine's HOME, /Users/ or /opt/homebrew stops the run (exit 1). Prints the counts; exit 2 on bad arguments.
set -euo pipefail
[ $# = 3 ] || { echo "usage: land-export.sh <export dir> <export worktree root> <dest tests/cases>" >&2; exit 2; }
src="${1%/}"; repo="${2%/}"; dest="${3%/}"
[ -d "$src" ] || { echo "land-export: no export dir $src" >&2; exit 2; }
[ -n "$repo" ] || { echo "land-export: empty export worktree root" >&2; exit 2; }
mkdir -p "$dest"
inv="$(cd "$dest/.." && pwd)/inventory-019.tsv"
[ -f "$inv" ] || { echo "land-export: no $inv" >&2; exit 2; }
if command -v sha256sum > /dev/null 2>&1; then sum="sha256sum"; else sum="shasum -a 256"; fi
work="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/land-export.XXXXXX")" && pwd)"   # absolute: the hashing runs from inside input/
trap 'rm -rf "$work"' EXIT
mkdir -p "$dest/inputs/files" "$dest/inputs/trees"
esc="$(printf '%s' "$repo" | sed 's/[][\.*^$/]/\\&/g')"
tab="$(printf '\t')"; nl='
'
cases=0; blobs=0; trees=0; written=0
pats=(-e /Users/ -e /opt/homebrew); [ "${#HOME}" -le 1 ] || pats+=(-e "$HOME")   # what names the export machine

# put <candidate> <target>: copies when the target is missing or differs
put() {
  if ! cmp -s "$1" "$2" 2> /dev/null; then mkdir -p "$(dirname "$2")"; cp "$1" "$2"; written=$((written + 1)); fi
}

# store <file>: copies the file into inputs/files by content; sets $stored to its sha256
store() {
  stored="$($sum < "$1" | cut -c1-64)"
  if [ ! -f "$dest/inputs/files/$stored" ]; then cp "$1" "$dest/inputs/files/$stored"; chmod 644 "$dest/inputs/files/$stored"; blobs=$((blobs + 1)); fi
}

# land_input <case input dir> <target input.tsv> <case name>
land_input() {
  local in="$1" w="$work/in" p e h d n bad hit
  rm -rf "$w"; mkdir -p "$w/lv"
  bad="$(cd "$in" && find . \( ! -type f ! -type d \) -o -name "*$tab*" -o -name "*$nl*" -o -name '*\\*')"
  [ -z "$bad" ] || { echo "land-export: unsupported input entry under $in: $bad" >&2; exit 1; }
  # (c) the root in an input text file becomes <repo> before hashing (on a copy: the export is not touched)
  (cd "$in" && find . -type f -print0 | xargs -0 grep -l -I -F -e "$repo" -- 2> /dev/null) > "$w/hits" || true
  if [ -s "$w/hits" ]; then
    rm -rf "$work/inmask"; cp -Rp "$in" "$work/inmask"; in="$work/inmask"
    while IFS= read -r hit; do LC_ALL=C sed "s/$esc/<repo>/g" "$in/$hit" > "$work/cand"; cat "$work/cand" > "$in/$hit"; done < "$w/hits"
  fi
  # (d) a non-text file that still names the export machine is left out (T17c), its case and name printed
  (cd "$in" && find . -type f -print0 | xargs -0 grep -l -F "${pats[@]}" -- 2> /dev/null) > "$w/named" || true
  if [ -s "$w/named" ]; then
    (cd "$in" && tr '\n' '\0' < "$w/named" | xargs -0 grep -l -I -F "${pats[@]}" -- 2> /dev/null) > "$w/text" || true
    grep -vx -F -f "$w/text" "$w/named" > "$w/drop" || true
    if [ -s "$w/drop" ]; then
      if [ "$in" != "$work/inmask" ]; then rm -rf "$work/inmask"; cp -Rp "$in" "$work/inmask"; in="$work/inmask"; fi
      while IFS= read -r p; do rm -f "$in/$p"; echo "land-export: $3: left out ${p#./} (names the export machine)"; done < "$w/drop"
    fi
  fi
  (cd "$in" && find . -type f -print) > "$w/files"
  (cd "$in" && find . -type f -perm -100 -print) > "$w/exec"
  (cd "$in" && find . -type d -print) > "$w/dirs"
  : > "$w/known"
  if [ -s "$w/files" ]; then
    (cd "$in" && tr '\n' '\0' < "$w/files" | xargs -0 $sum) |
      awk -v ex="$w/exec" 'BEGIN { while ((getline l < ex) > 0) x[l] = 1 }
        { h = substr($0, 1, 64); p = substr($0, 67); print p "\t" (p in x ? "file+x:" : "file:") h "\t" h }' > "$w/hashed"
    while IFS="$tab" read -r p e h; do
      if [ ! -f "$dest/inputs/files/$h" ]; then cp "$in/$p" "$dest/inputs/files/$h"; chmod 644 "$dest/inputs/files/$h"; blobs=$((blobs + 1)); fi
    done < "$w/hashed"
    cut -f1,2 "$w/hashed" > "$w/known"
  fi
  local depth max
  max="$(awk -F/ 'NF - 1 > m { m = NF - 1 } END { print m + 0 }' "$w/dirs")"
  depth="$max"
  while [ "$depth" -ge 0 ]; do
    rm -f "$w/lv/"*
    # each directory at this depth gets lv/<n>.tsv of its children, sorted by name; lv/map holds <n>\t<dir>
    awk -F'\t' -v d="$depth" -v lv="$w/lv" -v dirs="$w/dirs" '
      function depth(p) { return gsub(/\//, "/", p) }
      BEGIN { while ((getline l < dirs) > 0) if (depth(l) == d) { n++; idx[l] = n; f = lv "/" n ".tsv"; printf "" > f; close(f); print n "\t" l > (lv "/map") } }
      { p = $1; par = p; sub(/\/[^\/]*$/, "", par); if (par in idx) { name = substr(p, length(par) + 2); print idx[par] "\t" name "\t" $2 } }
    ' "$w/known" | LC_ALL=C sort -t"$tab" -k1,1n -k2,2 |
      awk -F'\t' -v lv="$w/lv" '{ f = lv "/" $1 ".tsv"; if (f != last) { if (last != "") close(last); last = f }; print $2 "\t" $3 >> f }'
    (cd "$w/lv" && find . -name '*.tsv' -print | tr '\n' '\0' | xargs -0 $sum) |
      awk -v map="$w/lv/map" 'BEGIN { while ((getline l < map) > 0) { split(l, a, "\t"); dir[a[1]] = a[2] } }
        { n = substr($0, 67); sub(/^\.\//, "", n); sub(/\.tsv$/, "", n); print dir[n] "\t" n "\t" substr($0, 1, 64) }' > "$w/level"
    while IFS="$tab" read -r d n h; do
      if [ "$d" = . ]; then
        put "$w/lv/$n.tsv" "$2"
      else
        printf '%s\ttree:%s\n' "$d" "$h" >> "$w/known"
        if [ ! -f "$dest/inputs/trees/$h.tsv" ]; then cp "$w/lv/$n.tsv" "$dest/inputs/trees/$h.tsv"; trees=$((trees + 1)); fi
      fi
    done < "$w/level"
    depth=$((depth - 1))
  done
}

ESC="$(printf '\033')"

# (2d) <kind>/<class>/<case>\t<why>: cases not landed because (2c) left out the input they test
removed="cli/SelfhostDriverT5Tests/CannotWriteTheOutputAsCliApp-5${tab}its input out/safe/macos-arm64/read-only named the export machine and was left out
cli/SelfhostDriverT5Tests/CannotWriteTheOutputAsCliApp-6${tab}its input out/safe/macos-arm64/read-only named the export machine and was left out"

# (a) mask_doctor <export case dir>: in $work/cand, the value of an ok row (marker, optionally in colour) labelled host, C compiler,
# zig or git becomes <host>, the cache row too when the case env sets no BAYAN_CACHE, the bayan row <version>; `not found` rows,
# failure rows stay
mask_doctor() {
  local labels='host|C compiler|zig|git' pre="(${ESC}\\[[0-9;]*m)?(◆|\\*)(${ESC}\\[[0-9;]*m)? +"
  grep -q '^BAYAN_CACHE=' "$1/env" 2> /dev/null || labels="$labels|cache"
  LC_ALL=C sed -E -e "/^$pre($labels) +not found/b" -e "s/^($pre($labels) +)[^ ].*/\\1<host>/" \
    -e "s/^(${pre}bayan +)[^ ].*/\\1<version>/" "$work/cand" > "$work/cand2"
  mv "$work/cand2" "$work/cand"
}

# (b) mask_cc: in $work/cand, everything after a line `C compiler failed (exit N):` becomes the line `<cc output>`
mask_cc() {
  awk '{ print } /^C compiler failed \(exit [0-9]+\):$/ { print "<cc output>"; exit }' "$work/cand" > "$work/cand2"
  mv "$work/cand2" "$work/cand"
}

# (c) mask_version: in $work/cand, the version of a line `bayan <version> (masked)` (SelfhostDriverTests.cs:31 `Mask`) becomes <version>
mask_version() {
  LC_ALL=C sed -E 's/^bayan [^ ]+ \(masked\)$/bayan <version> (masked)/' "$work/cand" > "$work/cand2"
  mv "$work/cand2" "$work/cand"
}

# (d) mask_std: in $work/cand, the export's std module list after `import one of `, `std.json` alone (not followed by ", `", a longer
# list), becomes <std modules>
mask_std() {
  LC_ALL=C sed -E -e 's/import one of `std\.json`$/import one of <std modules>/' \
    -e 's/import one of `std\.json`([^,]|,$|,[^ ]|, $|, [^`])/import one of <std modules>\1/g' "$work/cand" > "$work/cand2"
  mv "$work/cand2" "$work/cand"
}

# (e) mask_commit: in $work/cand, `(commit …)` becomes `(commit <c>)` and the rest of `isn't writable: ` up to an escape or the
# line end becomes `<message>` (SelfhostDefaultT5Tests.cs `Mask`, which its export did not apply)
mask_commit() {
  LC_ALL=C sed -E -e 's/\(commit [^)]*\)/(commit <c>)/g' -e "s/isn't writable: [^${ESC}]*/isn't writable: <message>/g" "$work/cand" > "$work/cand2"
  mv "$work/cand2" "$work/cand"
}

# land_case <export case dir> <dest case dir>
land_case() {
  local c="$1" to="$2" f
  if [ "$kind/$class/${c##*/}" = cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14 ]; then
    # its input was the C# test host's bin folder and the case is a usage error: it lands with no input.tsv (T17c ruling 2)
    echo "land-export: cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14: left out input/ (the test host's bin folder)"
  elif [ -d "$c/input" ]; then
    land_input "$c/input" "$to/input.tsv" "$kind/$class/${c##*/}"
  fi
  (cd "$c" && find . -type f ! -path './input/*' -print) > "$work/rest"
  : > "$work/masked"
  [ ! -s "$work/rest" ] || (cd "$c" && tr '\n' '\0' < "$work/rest" | xargs -0 grep -l -I -F -e "$repo" --) > "$work/masked" || true
  while IFS= read -r f; do
    f="${f#./}"
    case "$f" in
      (input.byn) # stored by content; the pointer file input.byn.ref holds `file:<sha256>`
          if grep -qx -F -e "./$f" "$work/masked"; then LC_ALL=C sed "s/$esc/<repo>/g" "$c/$f" > "$work/cand"; else cp "$c/$f" "$work/cand"; fi
          store "$work/cand"; printf 'file:%s\n' "$stored" > "$work/ref"; put "$work/ref" "$to/input.byn.ref" ;;
      (input|input.*) put "$c/$f" "$to/$f" ;;
      (*) if grep -qx -F -e "./$f" "$work/masked"; then LC_ALL=C sed "s/$esc/<repo>/g" "$c/$f" > "$work/cand"
          else cp "$c/$f" "$work/cand"; fi
          # a cli doctor run (a line of args is `doctor`): mask_doctor on its stdout
          [ "$kind/$f" != cli/expected.stdout ] || ! grep -qx -F doctor "$c/args" 2> /dev/null || mask_doctor "$c"
          case "$kind/$f" in (cli/expected.stdout|cli/expected.stderr) mask_version ;; esac
          case "$f" in (expected.*) mask_std ;; esac
          case "$class" in
            (SelfhostDefaultT12Tests) case "$f" in (expected.stdout|expected.stderr) mask_cc ;; esac ;;
            (SelfhostDefaultT5Tests) case "$f" in (expected.stdout|expected.stderr) mask_commit ;; esac ;;
          esac
          put "$work/cand" "$to/$f" ;;
    esac
  done < "$work/rest"
  mkdir -p "$to"
  cases=$((cases + 1))
}

: > "$work/counts"; : > "$work/unexported"; : > "$work/removed"
for k in "$src"/*/; do
  k="${k%/}"; kind="${k##*/}"
  for cl in "$k"/*/; do
    [ -d "$cl" ] || continue
    cl="${cl%/}"; class="${cl##*/}"
    [ "$kind/$class" != cli/SelfhostExport ] || continue
    n=0
    for c in "$cl"/*/; do
      [ -d "$c" ] || continue
      c="${c%/}"
      why="$(printf '%s\n' "$removed" | awk -F'\t' -v id="$kind/$class/${c##*/}" '$1 == id { print $2 }')"
      if [ -n "$why" ]; then
        echo "land-export: $kind/$class/${c##*/}: removed ($why)"
        printf '%s\t%s\t%s (%s)\n' "$class" "$kind" "${c##*/}" "$why" >> "$work/removed"; continue
      fi
      land_case "$c" "$dest/$kind/$class/${c##*/}"
      n=$((n + 1))
    done
    [ "$n" = 0 ] || printf '%s\t%s\t%s\n' "$class" "$kind" "$n" >> "$work/counts"
  done
  if [ -f "$k/UNEXPORTED.tsv" ]; then
    LC_ALL=C sed "s/$esc/<repo>/g" "$k/UNEXPORTED.tsv" | awk -F'\t' -v k="$kind" 'k == "cli" && $1 == "SelfhostExport" { next }
      { r = $3; for (i = 4; i <= NF; i++) r = r " " $i; print $1 "\t" k "\t" $2 " (" r ")" }' >> "$work/unexported"
  fi
done

# EXPORT.tsv: reason "<n> not exported: <test> (<rest>); ...", the distinct rows sorted, then "<n> removed: <case> (<why>); ..."
LC_ALL=C sort -u "$work/unexported" > "$work/unexported.sorted"
LC_ALL=C sort -u "$work/removed" > "$work/removed.sorted"
awk -F'\t' -v inv="$inv" -v un="$work/unexported.sorted" -v rm="$work/removed.sorted" '
  BEGIN {
    while ((getline l < inv) > 0) { split(l, a, "\t"); if (a[1] != "class") tests[a[1]] = a[4] }
    while ((getline l < un) > 0) { split(l, a, "\t"); key = a[1] "\t" a[2]; keys[key] = 1
      reason[key] = (rows[key] ? reason[key] "; " : "") a[3]; rows[key]++ }
    while ((getline l < rm) > 0) { split(l, a, "\t"); key = a[1] "\t" a[2]; keys[key] = 1
      gone[key] = (nrm[key] ? gone[key] "; " : "") a[3]; nrm[key]++ }
  }
  { key = $1 "\t" $2; keys[key] = 1; cnt[key] = $3 }
  END {
    for (key in keys) { split(key, a, "\t")
      r = (key in rows ? rows[key] " not exported: " reason[key] : "")
      if (key in nrm) r = (r == "" ? "" : r "; ") nrm[key] " removed: " gone[key]
      print key "\t" (a[1] in tests ? tests[a[1]] : "") "\t" (key in cnt ? cnt[key] : 0) "\t" r }
  }
' "$work/counts" | LC_ALL=C sort -t"$tab" -k1,1 -k2,2 > "$work/body"
{ printf 'class\tkind\ttests\tcases\treason\n'; cat "$work/body"; } > "$work/EXPORT.tsv"
put "$work/EXPORT.tsv" "$dest/EXPORT.tsv"
# nothing under dest may name the export machine: its HOME, /Users/ or /opt/homebrew (pats)
leaks="$(grep -rl -F "${pats[@]}" -- "$dest" 2> /dev/null | head -20 || true)"
[ -z "$leaks" ] || { echo "land-export: the landed tree names the export machine (HOME, /Users/ or /opt/homebrew) in:" >&2; echo "$leaks" >&2; exit 1; }
echo "land-export: $cases cases, $blobs new input files, $trees new input trees, $written files written"
