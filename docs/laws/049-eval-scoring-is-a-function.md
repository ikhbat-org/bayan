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
Tiers (Fable 2026-11-19, spec 011 D11): with BAYAN_LAW_TIER unset the check scores a fixed subset, the references of errors-001-prayer-time (a tests task), small-001-zakat-due (stdout with stdin) and spec-001-sadaqah-counters (stdout without stdin), one of each check shape, named in the test (no time or random source), plus the five failing candidates (broken, wrong-code, lint, unformatted, loop); BAYAN_LAW_TIER=full scores all 40 references and the five. The two scorings of a candidate run one after the other.
Timings, 2026-11-19: quick tier 8 passed, 0 failed in 166 s at load 6.9-15.7 (the `-001` task of all 8 categories took 256 s at load about 10, so it was cut to one per check shape); full tier 45 passed, 0 failed in 950 s at load 12-19. Before the tiers the whole set took 680 s at load 44-54, past the gate's 600 s.
Quick-tier mutation: the same `runMs` member after `limits` in the score record; L049 failed 1 passed, 7 failed (all but broken), e.g. errors-001-prayer-time with `"runMs": 4717` against `"runMs": 4445`.
