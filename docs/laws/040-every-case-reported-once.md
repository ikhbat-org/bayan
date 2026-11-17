---
id: L040
title: Every case is reported once
status: enacted
release: unscheduled
enacted: 2026-11-18
sources: spec 019 R1, R2, R3
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only '--jobs 1 and --jobs 4 print the same report'
kind: invariant
scope: src/driver/golden.byn, src/driver/test.byn
---

## Statement
For every cases directory, every case selection and every `--jobs` value, the golden runner reports exactly one result for each selected case and no result for any case outside the selection.

## Counterexample looks like
A cases directory, a selection and a `--jobs` value, with a case that is reported twice, a selected case with no result, or a result for a case that was not selected.

## Proof notes
2026-11-18, test block "--jobs 1 and --jobs 4 print the same report…" in src/driver/golden.byn. Mutation: `for i in 0..mine.length` → `1..mine.length` in the jobs result loop (golden.byn:725), stage 1 rebuilt from it: the test failed at golden.byn:2108, report "3 passed · 1 failed · 4 golden cases" against 5. Restored with `git checkout --`.
