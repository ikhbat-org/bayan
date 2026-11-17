---
id: L049
title: Eval scoring is a function
status: proposed
release: unscheduled
sources: spec 025 R9
kind: property
scope: tools/llm-eval.byn
---

## Statement
For every task and every candidate, two scoring runs, each in its own new `--out` directory, give the same four results. Scoring reads no clock, no network and no state outside the task and the candidate.

## Counterexample looks like
A task id, a candidate file and the two result records that differ, for example a candidate that times out on one run and passes on the other, or a result that holds a wall time.
