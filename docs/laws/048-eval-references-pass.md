---
id: L048
title: Eval references pass
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 025 R8, R29
kind: property
scope: evals/llm/tasks/**
proof: scripts/evals/llm-eval.test.sh
check: bash scripts/evals/llm-eval.test.sh L048
---

## Statement
For every task under `evals/llm/tasks/`, scoring the task's reference solution with the pinned compiler gives all four results of R11: it compiles with no diagnostic, passes its checks, is lint-clean, and is unchanged by `bayan format`.

## Counterexample looks like
A task id and the first of the four results its reference does not get, with the compiler's output for that step, for example `std-003-zakat-table: format changed reference/solution.byn`.

## Proof notes
Mutation: indented one line of evals/llm/tasks/small-001-zakat-due/reference/solution.byn by two more spaces; L048 failed 39 passed, 1 failed: `FAIL L048: small-001-zakat-due: reference scores four true (got '0 true true true false "pass"')`, then `small-001-zakat-due: formatStable false reference/solution.byn` and `would format .../solution.byn`.
