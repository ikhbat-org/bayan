#!/usr/bin/env bash
# Tests scripts/selfhost/pre-push-laws.sh on a scratch copy under tmp/ with a fake dotnet: a dotnet `check:` runs the xunit
# filter, a shell `check:` runs as written with the full tier, an enacted law with no `check:` fails, proposed laws are skipped.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/pre-push-laws-test"; rm -rf "$t"; mkdir -p "$t/scripts/selfhost" "$t/docs/laws" "$t/bin"
cp "$root/scripts/selfhost/pre-push-laws.sh" "$t/scripts/selfhost/"
printf '#!/bin/sh\necho "dotnet $* tier=$BAYAN_LAW_TIER" >> "%s/calls"\n' "$t" > "$t/bin/dotnet"; chmod +x "$t/bin/dotnet"
law() { printf -- '---\nid: %s\nstatus: %s\n%s---\n' "$2" "$3" "${4:+check: $4
}" > "$t/docs/laws/$1"; }
law 001-a.md L001 enacted 'dotnet test --filter "Law=L001"'
law 002-b.md L002 enacted "echo shell tier=\$BAYAN_LAW_TIER >> $t/calls"
law 003-c.md L003 proposed ''
run() { rc=0; out="$(PATH="$t/bin:$PATH" bash "$t/scripts/selfhost/pre-push-laws.sh" 2>&1)" || rc=$?; }
run
[ "$rc" = 0 ] || fail "all proven: exit $rc: $out"
grep -qx 'dotnet test -v q --filter Law=L001 tier=full' "$t/calls" || fail "dotnet check: $(cat "$t/calls")"
grep -qx 'shell tier=full' "$t/calls" || fail "shell check: $(cat "$t/calls")"
[ "$(wc -l < "$t/calls" | tr -d ' ')" = 2 ] || fail "proposed law ran: $(cat "$t/calls")"
law 004-d.md L004 enacted ''
run
[ "$rc" = 1 ] || fail "no check: exit $rc: $out"
grep -q 'LAWS FAILED (full tier): L004' <<<"$out" || fail "no check reason: $out"
law 004-d.md L004 enacted 'false'
run
[ "$rc" = 1 ] || fail "failing shell check: exit $rc: $out"
echo "pre-push-laws.test: ok"
