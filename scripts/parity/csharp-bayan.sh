#!/usr/bin/env bash
# The C# `bayan` (csharp/Bayan.Cli), the original the tests/parity/cli-* cases were recorded from (spec 019 T25):
#   bash scripts/parity/csharp-bayan.sh <bayan arguments>
# Builds csharp/Bayan.Cli once into <root>/tmp/parity-csharp-bayan/ (removed by hand to rebuild) and runs it with `dotnet`.
# Recording only (`scripts/parity/run.sh cli-<tool> --record`); the suite runs the cases with the driver (scripts/test.sh).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$root/tmp/parity-csharp-bayan"
if [ ! -f "$out/bayan.dll" ]; then
  dotnet build "$root/csharp/Bayan.Cli" -c Release -o "$out" > "$root/tmp/parity-csharp-bayan.log" 2>&1 \
    || { echo "csharp-bayan: build failed; log: $root/tmp/parity-csharp-bayan.log" >&2; exit 125; }
fi
exec dotnet "$out/bayan.dll" "$@"
