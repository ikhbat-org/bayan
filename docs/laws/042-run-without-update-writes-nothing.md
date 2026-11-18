---
id: L042
title: A run without update writes nothing
status: enacted
release: unscheduled
enacted: 2026-11-18
sources: spec 019 R5
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'a run without BAYAN_UPDATE leaves the cases directory'
kind: guard
scope: src/driver/golden.byn
---

## Statement
For every golden run without `BAYAN_UPDATE` set, the cases directory is byte for byte the same afterwards: no file is created, changed or removed under it.

## Counterexample looks like
A cases directory and a run without `BAYAN_UPDATE`, with a path under the directory whose bytes, presence or absence differ after the run.

## Proof notes
2026-11-18, test block "a run without BAYAN_UPDATE leaves the cases directory…" in src/driver/golden.byn. Mutation: `goldenUpdate()` made always true (golden.byn:193), stage 1 rebuilt from it: the test failed at golden.byn:2293. Restored with `git checkout --`.
