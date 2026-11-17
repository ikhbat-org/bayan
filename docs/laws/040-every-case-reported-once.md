---
id: L040
title: Every case is reported once
status: enacted
release: unscheduled
enacted: 2026-11-18
sources: spec 019 R1, R2, R3
kind: invariant
scope: src/driver/golden.byn, src/driver/test.byn
---

## Statement
For every cases directory, every case selection and every `--jobs` value, the golden runner reports exactly one result for each selected case and no result for any case outside the selection.

## Counterexample looks like
A cases directory, a selection and a `--jobs` value, with a case that is reported twice, a selected case with no result, or a result for a case that was not selected.
