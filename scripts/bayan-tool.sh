#!/usr/bin/env bash
# Runs a ported tool, tools/<name>.byn, with the pinned bayan (spec 015 R1, decision T2): never the working tree's
# compiler. The tool's arguments, stdin, stdout, stderr and exit code pass through unchanged.
# Usage: scripts/bayan-tool.sh <name> [args...]
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?usage: bayan-tool.sh <name> [args...]}"; shift
case "$name" in ""|.|..|*/*) echo "bayan-tool: bad tool name: $name" >&2; exit 2 ;; esac
src="$root/tools/$name.byn"
[ -f "$src" ] || { echo "bayan-tool: no tool at tools/$name.byn" >&2; exit 2; }
bayan="$(cd "$root" && bash scripts/pinned-bayan.sh)"
exec "$bayan" run "$src" -- "$@"
