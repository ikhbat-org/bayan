#!/bin/bash
# quality-baseline: check fails on a mutation, line coverage or branch coverage score below the baseline and passes on an equal or higher one,
# a file with no entry, and a null on either side; update creates the file, adds new files, raises a score and keeps a
# higher one; report paths (absolute, or relative to the root) become root-relative keys; an absolute or `..` path outside the
# root exits non-zero naming the report and writes no key; two shards' reports merged by one update keep both shards' raises
# (applying each shard's own updated baseline in turn loses one).
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
d="$root/tmp/quality-baseline-test"; rm -rf "$d" && mkdir -p "$d/w"
q() { bash "$root/scripts/bayan-tool.sh" quality-baseline "$@"; }
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
# mutation report: <file> <killed> <survived> [timeout] [marked]
mut() { local ms="" st i
  for st in killed:$2 survived:$3 timeout:${4:-0} marked:${5:-0}; do
    for ((i = 0; i < ${st#*:}; i++)); do ms="$ms${ms:+, }{\"site\": {\"file\": \"$1\"}, \"status\": \"${st%%:*}\"}"; done; done
  printf '{"version": 1, "kind": "mutation", "files": [{"path": "%s", "mutants": [%s]}]}\n' "$1" "$ms"; }
# entry <baseline> <file>: the file's entry as `"mutation": 1.0, "coverage": null, ...` (the indent=2 layout quality-baseline writes), empty for none
entry() { awk -v k="    \"$2\": {" '$0 == k { on = 1; next } on && /^    }/ { exit } on { sub(/^ +/, ""); printf "%s%s", s, $0; s = " " }' "$1"; }
# val <baseline> <file> <score>: one score of the file's entry
val() { entry "$1" "$2" | sed -n "s/.*\"$3\": \([^,]*\).*/\1/p"; }
cov() { printf '{"version": 1, "kind": "coverage", "files": [{"path": "%s", "lines": {"covered": %s, "total": %s, "missed": []}}]}\n' "$1" "$2" "$3"; }
# coverage report with branches: <file> <covered lines> <total lines> <covered branches> <total branches>
bcov() { printf '{"version": 1, "kind": "coverage", "files": [{"path": "%s", "lines": {"covered": %s, "total": %s, "missed": []}, "branches": {"covered": %s, "total": %s, "missed": []}}]}\n' "$@"; }
B=$d/baseline.json
printf '{ "version": 1, "files": { "a.byn": { "mutation": 0.75, "coverage": 0.5, "branches": 0.5 }, "n.byn": { "mutation": null, "coverage": null } } }\n' > $B
mut a.byn 2 1 > $d/drop.json; mut a.byn 2 1 1 > $d/equal.json; mut "$d/w/a.byn" 4 0 0 3 > $d/abs.json
mut b.byn 1 1 > $d/new.json; mut n.byn 0 5 > $d/null.json; cov a.byn 1 4 > $d/covdrop.json; bcov a.byn 2 4 1 4 > $d/brdrop.json; bcov a.byn 2 4 0 0 > $d/brnone.json; mut m.byn 0 0 0 2 > $d/marked.json
out=$(q check $B "$d/w" $d/drop.json) && fail "a mutation drop passed" "$out"
[ "$out" = "baseline: mutation score of a.byn fell from 0.75 to 0.6667 ($B)" ] || fail "drop message" "$out"
out=$(q check $B "$d/w" $d/equal.json) || fail "an equal score (timeout counts as killed) failed" "$out"
out=$(q check $B "$d/w" $d/abs.json) || fail "a higher score from an absolute path failed" "$out"
out=$(q check $B "$d/w" $d/new.json) || fail "a file with no baseline entry failed" "$out"
out=$(q check $B "$d/w" $d/null.json) || fail "a null baseline score failed" "$out"
out=$(q check $B "$d/w" $d/marked.json) || fail "a null new score (only marked mutants) failed" "$out"
out=$(q check $B "$d/w" $d/drop.json $d/abs.json) || fail "two reports on one file were not summed ((2+4)/(6+1) > 0.75)" "$out"
out=$(q check $B "$d/w" $d/covdrop.json) && fail "a coverage drop passed" "$out"
echo "$out" | grep -q 'coverage score of a.byn fell from 0.5 to 0.25' || fail "coverage drop message" "$out"
out=$(q check $B "$d/w" $d/brdrop.json) && fail "a branch coverage drop passed" "$out"
[ "$out" = "baseline: branches score of a.byn fell from 0.5 to 0.25 ($B)" ] || fail "branch drop message" "$out"
out=$(q check $B "$d/w" $d/brnone.json) || fail "a report with no branches (null branch score) failed" "$out"
q update $B "$d/w" $d/abs.json $d/new.json
got="$(entry $B a.byn) | $(entry $B b.byn) | $(entry $B n.byn)"
[ "$got" = '"mutation": 1.0, "coverage": 0.5, "branches": 0.5 | "mutation": 0.5, "coverage": null, "branches": null | "mutation": null, "coverage": null' ] || fail "update did not raise a.byn and add b.byn" "$got"
bcov a.byn 3 4 3 4 > $d/brup.json; q update $B "$d/w" $d/brup.json; q update $B "$d/w" $d/brdrop.json
got="$(val $B a.byn coverage) $(val $B a.byn branches)"
[ "$got" = "0.75 0.75" ] || fail "update did not raise the branch score, or a lower one replaced it" "$got"
q update $B "$d/w" $d/drop.json
got=$(val $B a.byn mutation)
[ "$got" = 1.0 ] || fail "a lower score replaced a higher baseline" "$got"
q update $d/fresh.json "$d/w" $d/new.json
got=$(tr -d ' \n' < $d/fresh.json)
[ "$got" = '{"version":1,"files":{"b.byn":{"mutation":0.5,"coverage":null,"branches":null}}}' ] || fail "update did not create a missing baseline" "$got"
# a path outside the root (absolute, or `..`): refused naming the report, no `../..` key written, in check and in update
mut /elsewhere/z.byn 1 0 > $d/outabs.json; mut ../z.byn 1 0 > $d/outdot.json; cp $d/fresh.json $d/fresh-before.json
for r in outabs outdot; do for c in check update; do
  out=$(q $c $d/fresh.json "$d/w" $d/$r.json 2>&1) && fail "$c accepted the path of $r.json" "$out"
  echo "$out" | grep -q "$d/$r.json" || fail "$c did not name $r.json" "$out"
done; done
cmp -s $d/fresh.json $d/fresh-before.json || fail "a refused path changed the baseline" "$(cat $d/fresh.json)"
# the two-shard loss: shard 1 raises a.byn, shard 2 raises b.byn; the baseline each uploads misses the other's raise, one update over both reports keeps both
printf '{ "version": 1, "files": { "a.byn": { "mutation": 0.5 }, "b.byn": { "mutation": 0.5 } } }\n' > $d/base.json
cp $d/base.json $d/s1.json; cp $d/base.json $d/s2.json; mut a.byn 3 1 > $d/r1.json; mut b.byn 4 0 > $d/r2.json
q update $d/s1.json "$d/w" $d/r1.json; q update $d/s2.json "$d/w" $d/r2.json
got="$(val $d/s2.json a.byn mutation) $(val $d/s2.json b.byn mutation)"
[ "$got" = "0.5 1.0" ] || fail "the last shard's own baseline was not missing the other raise (setup)" "$got"
q update $d/base.json "$d/w" $d/r1.json $d/r2.json
got="$(val $d/base.json a.byn mutation) $(val $d/base.json b.byn mutation)"
[ "$got" = "0.75 1.0" ] || fail "one update over both shards' reports lost a raise" "$got"
rm -rf "$d"
echo PASS
