# shellcheck shell=bash
# Sourced by scripts/release and scripts/docs: the one place that reads the version and knows where it is copied.
# VERSION (repo root, one line) is the source; docs/RELEASING.md describes the mirrors.

# bayan_version <root>: the version in <root>/VERSION, e.g. 1.2.0 or 1.3.0-dev.
bayan_version() {
  local f="$1/VERSION" v
  [ -f "$f" ] || { echo "version: $f not found" >&2; return 1; }
  v="$(head -n 1 "$f")"
  bayan_valid_version "$v" || { echo "version: VERSION holds '$v', not X.Y.Z or X.Y.Z-dev" >&2; return 1; }
  printf '%s\n' "$v"
}

# bayan_valid_version <v>: X.Y.Z with an optional -suffix.
bayan_valid_version() { printf '%s\n' "$1" | grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?'; }

# bayan_latest_revision <root>: NNNN of the highest docs/revisions/NNNN-*.md.
bayan_latest_revision() {
  (cd "$1/docs/revisions" && ls) | sed -nE 's/^([0-9]{4})-.*\.md$/\1/p' | LC_ALL=C sort | tail -n 1
}

# The docs whose first lines carry `Version: <v> (matches `bayan --version`)` and `Revisions applied: 0001–NNNN`.
bayan_header_docs="docs/bayan-spec.md docs/bayan-grammar.md docs/bayan-style.md docs/DIAGNOSTICS.md docs/STATUS.md"

# Every release doc (docs/decisions/2026-11-14-003-versioned-docs-and-provenance.md): the header docs and the other
# maintained docs, each with the `Version:` line in its first ten lines. set-version.sh bumps them all.
bayan_release_docs="$bayan_header_docs docs/RELEASING.md docs/bayan-contributing.md docs/bayan-milestones.md
  docs/bayan-roadmap.md docs/bayan-not-planned.md docs/bayan-nice-to-have.md docs/bayan-questions.md
  docs/bayan-library-tiers.md docs/bayan-concurrency.md docs/bayan-views.md docs/bayan-self-hosting.md
  docs/memory-leaks.md docs/bayan-terminal-style.md docs/typed-dump.md docs/security/2026-11-06-runtime-audit.md
  docs/security/crypto-api-checklist.md docs/revisions/README.md docs/laws/README.md
  docs/specs/README.md docs/bayan-feature-history.md"

# The code and test mirrors of VERSION, one per line: file, then the sed -E text before and after the version
# (tab-separated). bootstrap/bayan.c is not one: scripts/selfhost/land.sh regenerates it from selfhost/.
bayan_mirrors() {
  printf '%s\t%s\t%s\n' \
    src/Bayan.Backend.C/Toolchain.cs '(const string CompilerVersion = ")' '(";)' \
    selfhost/driver/main.byn '^(const version: string = ")' '(")' \
    tests/cases/out/dist.tree '("compiler": "bayan )' '(")' \
    README.md '(scripts/dist\.sh .*dist/[a-z0-9-]+/)' '(/bayan)'
}
