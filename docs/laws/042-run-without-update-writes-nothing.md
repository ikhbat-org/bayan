---
id: L042
title: A run without update writes nothing
status: enacted
release: unscheduled
enacted: 2026-11-18
sources: spec 019 R5
kind: guard
scope: src/driver/golden.byn
---

## Statement
For every golden run without `BAYAN_UPDATE` set, the cases directory is byte for byte the same afterwards: no file is created, changed or removed under it.

## Counterexample looks like
A cases directory and a run without `BAYAN_UPDATE`, with a path under the directory whose bytes, presence or absence differ after the run.
