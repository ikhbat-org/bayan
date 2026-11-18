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
For every task, no line of a file under `checks/` or `reference/` appears in the preamble or in `prompt.md` of the prompt the runner sends to a model (a context file given with `--context` is not part of this), with one exception: a line that is also a line of `prompt.md` is allowed only when it comes from the text of a starter file (`starter/`) or a source program (`source.*`) that the prompt quotes. Lines are compared after trimming leading and trailing whitespace; blank lines are not compared.

## Counterexample looks like
A task id, the file under `checks/` or `reference/`, and the line that appears in the preamble or in `prompt.md`, for example `small-002-fizz/checks/expected.stdout: "Salam, Aisha"` found in the preamble.
