#!/usr/bin/env bash
# Spec 019 T17f: every tracked file under tests/cases/inputs/files is named by the sha256 of its bytes (land-export.sh store),
# except the paths listed in tests/cases/inputs/unrestored.txt (`#` lines are comments; sorted). Hashes the git blobs (the index,
# what a commit stores), not the worktree files, in one `git cat-file --batch` and one perl. Exit 1 names each path that does not
# hash to its name and is not listed, and each listed path that hashes to its name or is not tracked (the list may only shrink).
# First a self-check on a fixture repository under tmp/: a listed mismatch passes, an unlisted one and a listed match fail.
#   bash scripts/ci/input-blobs.test.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
if command -v sha256sum > /dev/null 2>&1; then h() { sha256sum | cut -c1-64; }; else h() { shasum -a 256 | cut -c1-64; }; fi

# check <work dir>: in the repository holding the current directory, compares the mismatching paths with <work dir>/list
check() {
  local w="$1" dir=tests/cases/inputs/files
  git ls-files -s -- "$dir" | awk -F'\t' '{ split($1, a, " "); print a[2] " " $2 }' |
    git cat-file --batch='%(objectsize) %(rest)' |
    perl -MDigest::SHA=sha256_hex -e '
      binmode STDIN; my $n = 0;
      while (defined(my $h = <STDIN>)) {
        chomp $h; my ($size, $path) = split / /, $h, 2;
        my $d = ""; $size == 0 || read(STDIN, $d, $size) == $size or die "input-blobs: short read for $path\n";
        read(STDIN, my $nl, 1); $n++;
        (my $name = $path) =~ s{.*/}{};
        print "$path\n" if sha256_hex($d) ne $name;
      }
      $n > 0 or die "input-blobs: no tracked files under '"$dir"'\n";' | LC_ALL=C sort > "$w/bad" || return 1
  grep -v '^#' "$w/list" | grep -v '^$' > "$w/listed" || true
  LC_ALL=C sort -c "$w/listed" 2> /dev/null || { echo "input-blobs: the unrestored list is not sorted"; return 1; }
  LC_ALL=C comm -23 "$w/bad" "$w/listed" | sed 's/^/input-blobs: does not hash to its name and is not listed: /' > "$w/out"
  LC_ALL=C comm -13 "$w/bad" "$w/listed" | sed 's/^/input-blobs: listed but hashes to its name or is not tracked: /' >> "$w/out"
  [ ! -s "$w/out" ] || { cat "$w/out"; return 1; }
  echo "input-blobs: ok, $(wc -l < "$w/bad" | tr -d ' ') listed mismatches"
}

# self-check on a fixture repository (its own .git; nothing is committed)
t="$root/tmp/input-blobs-test"; rm -rf "$t"; mkdir -p "$t/w" "$t/repo/tests/cases/inputs/files"
fail() { echo "FAIL $1"; exit 1; }
(
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
  cd "$t/repo"; git init -q .
  printf 'tests/cases/inputs/files/** -text\n' > .gitattributes
  f=tests/cases/inputs/files
  good="$(printf 'a\r\nb\r\n' | h)"; printf 'a\r\nb\r\n' > "$f/$good"
  lost="$(printf 'c\r\nd\n' | h)"; printf 'c\nd\n' > "$f/$lost"                    # a listed file whose CRs were lost
  git add -A
  printf '# header\n%s\n' "$f/$lost" > "$t/w/list"
  out="$(check "$t/w")" || fail "a listed mismatch failed: $out"
  wrong="$(printf 'e\r\n' | h)"; printf 'e\n' > "$f/$wrong"; git add -A              # an unlisted mismatch
  rc=0; out="$(check "$t/w")" || rc=$?
  [ $rc = 1 ] && grep -q "is not listed: $f/$wrong\$" <<<"$out" || fail "an unlisted mismatch passed ($rc): $out"
  git rm -q --cached "$f/$wrong"
  printf '# header\n%s\n%s\n' "$f/$good" "$f/$lost" | LC_ALL=C sort > "$t/w/list"   # a listed path that hashes to its name
  rc=0; out="$(check "$t/w")" || rc=$?
  [ $rc = 1 ] && grep -q "listed but hashes to its name or is not tracked: $f/$good\$" <<<"$out" || fail "a listed match passed ($rc): $out"
) || exit 1
rm -rf "$t"

# the tree
w="$(mktemp -d "${TMPDIR:-/tmp}/input-blobs.XXXXXX")"; trap 'rm -rf "$w"' EXIT
cp "$root/tests/cases/inputs/unrestored.txt" "$w/list"
cd "$root"
check "$w"
