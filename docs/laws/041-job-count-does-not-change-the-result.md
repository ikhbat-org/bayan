---
id: L041
title: Job count does not change the result
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 019 R4
kind: property
scope: src/driver/golden.byn, src/driver/test.byn
---

## Statement
For every cases directory and every pair of job counts N and M, the golden runner's report with `--jobs N` equals its report with `--jobs M`, with elapsed times masked, for runs in which no case reaches its time limit.

## Counterexample looks like
A cases directory, N and M, and the first line where the two masked reports differ: a different verdict, a different order, or a diff body that differs.
