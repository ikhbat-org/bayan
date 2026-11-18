---
id: L049
title: Eval scoring is a function
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 025 R9
kind: property
scope: tools/llm-eval.byn
proof: scripts/evals/llm-eval.test.sh
check: bash scripts/evals/llm-eval.test.sh L049
---

## Statement
For every task and every candidate whose output does not vary and which finishes within the limits, two scoring runs, each in its own new `--out` directory, give the same four results. No result depends on time except through the `limit` outcome, and scoring reads no network and no state outside the task and the candidate.

## Counterexample looks like
A task id, a candidate file and the two result records that differ, for example a candidate within the limits whose result differs between the runs, or a result that holds a wall time.

## Proof notes
Mutation: added `m.append(JsonMember { key: "runMs", value: number(runNanos / 1000000) })` after the `limits` member of the score record in tools/llm-eval.byn; L049 failed 1 passed, 44 failed (all but the no-compile candidate, which never runs), e.g. `FAIL L049: contracts-001-date-portion: solution.byn scored twice in two --out directories, same record` with records differing only in `"runMs": 4358` against `"runMs": 4302`.
