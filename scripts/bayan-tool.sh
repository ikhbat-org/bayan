#!/usr/bin/env bash
# Runs a ported tool, tools/<name>/<name>.byn, with the pinned bayan (spec 015 R1, decision T2): never the working tree's
# compiler. The tool's arguments, stdin, stdout, stderr and exit code pass through unchanged.
# Usage: scripts/bayan-tool.sh <name> [args...]
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?usage: bayan-tool.sh <name> [args...]}"; shift
case "$name" in ""|.|..|*/*) echo "bayan-tool: bad tool name: $name" >&2; exit 2 ;; esac
# One directory per tool: `bayan run` compiles every .byn beside the file, so two tools sharing a directory would be
# one program with two entry points (BYN2013).
src="$root/tools/$name/$name.byn"
[ -f "$src" ] || { echo "bayan-tool: no tool at tools/$name/$name.byn" >&2; exit 2; }
# The pin is found without the caller's PATH entries under its working directory, where tests put stub programs (a
# parity case's `git` stub in $WORK/bin), so pinned-bayan.sh runs the real git.
path=""; IFS=: read -ra dirs <<< "$PATH"
for d in "${dirs[@]}"; do case "$d" in "$PWD"|"$PWD"/*) ;; *) path="${path:+$path:}$d" ;; esac; done
bayan="$(cd "$root" && PATH="$path" bash scripts/pinned-bayan.sh)"
exec "$bayan" run "$src" -- "$@"
