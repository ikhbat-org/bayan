#!/usr/bin/env bash
# Spec 019 T17f: every tracked file under tests/cases/inputs/files is named by the sha256 of its bytes (land-export.sh store).
# Hashes the git blobs (the index, what a commit stores), not the worktree files, in one `git cat-file --batch` and one perl;
# exit 1 names each path whose blob does not hash to its name.
#   bash scripts/ci/input-blobs.test.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
dir=tests/cases/inputs/files
git ls-files -s -- "$dir" | awk -F'\t' '{ split($1, a, " "); print a[2] " " $2 }' |
  git cat-file --batch='%(objectsize) %(rest)' |
  perl -MDigest::SHA=sha256_hex -e '
    binmode STDIN; my ($n, $bad) = (0, 0);
    while (defined(my $h = <STDIN>)) {
      chomp $h; my ($size, $path) = split / /, $h, 2;
      my $d = ""; $size == 0 || read(STDIN, $d, $size) == $size or die "input-blobs: short read for $path\n";
      read(STDIN, my $nl, 1); $n++;
      (my $name = $path) =~ s{.*/}{};
      if (sha256_hex($d) ne $name) { print "input-blobs: $path does not hash to its name\n"; $bad++ }
    }
    $n > 0 or die "input-blobs: no tracked files under '"$dir"'\n";
    if ($bad) { print "input-blobs: $bad of $n blobs do not hash to their names\n"; exit 1 }
    print "input-blobs: $n blobs ok\n";'
