#!/usr/bin/env bash
# Runs a ported tool, tools/<name>.byn, with the pinned bayan (spec 015 R1, decision T2): never the working tree's
# compiler. The tool's arguments, stdin, stdout, stderr and exit code pass through unchanged.
# Usage: scripts/bayan-tool.sh <name> [args...]
# BAYAN_REPO_ROOT is exported for the tool: the repo root, so a tool finds repo files whatever its working directory.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?usage: bayan-tool.sh <name> [args...]}"; shift
case "$name" in ""|.|..|*/*) echo "bayan-tool: bad tool name: $name" >&2; exit 2 ;; esac
src="$root/tools/$name.byn"
[ -f "$src" ] || { echo "bayan-tool: no tool at tools/$name.byn" >&2; exit 2; }
# Each tool starts with `#!/usr/bin/env bayan`, so `bayan run` compiles it alone as a script; without that line it would
# compile every .byn in tools/ as one program (BYN2013, two entry points).
head -c 2 "$src" | grep -q "^#!" || { echo "bayan-tool: tools/$name.byn does not start with #! (a script)" >&2; exit 2; }
# The pin is found without the caller's PATH entries under its working directory, where tests put stub programs (a
# parity case's `git` stub in $WORK/bin), so pinned-bayan.sh runs the real git.
path=""; IFS=: read -ra dirs <<< "$PATH"
for d in "${dirs[@]}"; do case "$d" in "$PWD"|"$PWD"/*) ;; *) path="${path:+$path:}$d" ;; esac; done
bayan="$(cd "$root" && PATH="$path" bash scripts/pinned-bayan.sh)"
export BAYAN_REPO_ROOT="$root"
exec "$bayan" run "$src" -- "$@"
