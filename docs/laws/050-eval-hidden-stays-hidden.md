---
id: L050
title: Eval hidden stays hidden
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 025 R3
kind: guard
scope: tools/llm-eval.byn, evals/llm/tasks/**
---

## Statement
For every task, the prompt the runner sends to a model is the preamble, then the context file when one is given with `--context`, then the task's `prompt.md`, each unchanged and nothing else, and it is the same prompt when the task's `checks/` and `reference/` are absent. No line of a file under `checks/` or `reference/` appears in the preamble. No file under `checks/` or `reference/` has all of its lines in `prompt.md`; a line that is also a line of a starter file (`starter/`) or a source program (`source.*`) the prompt quotes is not counted as being in `prompt.md`. Lines are compared after trimming leading and trailing whitespace; blank lines and lines with no letter or digit are not compared, and a file with no compared line is skipped.

## Counterexample looks like
A task id and one of: a difference between the prompt sent and the preamble, context and `prompt.md`; a difference in the prompt sent when `checks/` and `reference/` are removed; a file under `checks/` or `reference/` and its line found in the preamble; or a file under `checks/` or `reference/` whose every line is in `prompt.md`.

## Amendment
Amended by the owner 2026-11-19 ("amend L050 as proposed"), taking Fable's proposal in `docs/specs/025-llm-eval-set/025-l050-amendment.md`. The enacted text forbade any shared line between a hidden file and `prompt.md`; 18 hidden files in 11 seed tasks share contract-fixed lines (`unknown command`), taught vocabulary (`subhanallah`) or `}` with their prompts, which no prompt can avoid. A partial paste of a reference into `prompt.md` is no longer caught by the check and is left to review.
