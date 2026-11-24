---
id: L041
title: Job count does not change the result
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 019 R4
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L041:'
kind: property
scope: src/driver/golden.byn, src/driver/test.byn
---

## Statement
For every cases directory and every pair of job counts N and M, the golden runner's report with `--jobs N` equals its report with `--jobs M`, with elapsed times masked, for runs in which no case reaches its time limit.

## Counterexample looks like
A cases directory, N and M, and the first line where the two masked reports differ: a different verdict, a different order, or a diff body that differs.

## Proof notes
2026-11-18, test block "L041: --jobs N and --jobs M print the same masked report…" at the end of src/driver/golden.byn (30 seeded lex/parse directories mixing passing, changed-line and missing-expected cases; pairs 1/4, 2/16, 1/2, 3/8; 15.3 s). Mutation: `detail: text[at + 1..text.length]` → `text[at..text.length]` in the `goldenJobs` result loop (golden.byn:816), stage 1 rebuilt from it: the test failed at golden.byn:2851 with "L041 counterexample: seed 0 (…/tmp/golden-l041-0), --jobs 1 vs --jobs 4, line 5: failed parse/catch-switch |     ". Restored by reverting that edit.
