---
id: L050
title: Eval hidden stays hidden
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 025 R3
kind: guard
scope: tools/llm-eval.byn, evals/llm/tasks/**
proof: scripts/evals/llm-eval.test.sh
check: bash scripts/evals/llm-eval.test.sh L050
---

## Statement
For every task, the prompt the runner sends to a model is the preamble, then the context file when one is given with `--context`, then the task's `prompt.md`, each unchanged and nothing else, and it is the same prompt when the task's `checks/` and `reference/` are absent. No line of a file under `checks/` or `reference/` appears in the preamble. No file under `checks/` or `reference/` has all of its lines in `prompt.md`; a line that is also a line of a starter file (`starter/`) or a source program (`source.*`) the prompt quotes is not counted as being in `prompt.md`. Lines are compared after trimming leading and trailing whitespace; blank lines and lines with no letter or digit are not compared, and a file with no compared line is skipped.

## Counterexample looks like
A task id and one of: a difference between the prompt sent and the preamble, context and `prompt.md`; a difference in the prompt sent when `checks/` and `reference/` are removed; a file under `checks/` or `reference/` and its line found in the preamble; or a file under `checks/` or `reference/` whose every line is in `prompt.md`.

## Amendment
Amended by the owner 2026-11-19 ("amend L050 as proposed"), taking Fable's proposal in `docs/specs/025-llm-eval-set/025-l050-amendment.md`. The enacted text forbade any shared line between a hidden file and `prompt.md`; 18 hidden files in 11 seed tasks share contract-fixed lines (`unknown command`), taught vocabulary (`subhanallah`) or `}` with their prompts, which no prompt can avoid. A partial paste of a reference into `prompt.md` is no longer caught by the check and is left to review.

## Proof notes
The case runs the runner twice over the seed with a stub model and `--context`: once over `evals/llm/tasks` and once over a copy whose `checks/` and `reference/` are emptied (the runner lists `checks/`, so the directories stay). For each `dev` task it checks (a) the prompt sent equals preamble, context, `prompt.md` byte for byte, (b) it equals the prompt from the emptied copy, (c) no compared line of a file under `checks/` or `reference/` is a line of `evals/llm/preamble.md`, (d) no such file has every compared line in `prompt.md`, lines of `starter/` and `source.*` not counting as in `prompt.md`. Lines are trimmed; blank lines and lines with no letter or digit are skipped. 162 passed, 0 failed on the seed, also under /bin/bash 3.2, about 100 s.
Mutation (i): appended the last two lines of std-001-json-iftar-guests/reference/solution.byn to evals/llm/preamble.md; L050 failed 1: `std-001-json-iftar-guests: no line of checks/ or reference/ in the preamble (evals/llm/tasks/std-001-json-iftar-guests/reference/solution.byn: "print($"dishes: {dishes}")" is a line of the preamble)`.
Mutation (ii): appended the whole of std-001-json-iftar-guests/checks/expected.stdout to that task's `prompt.md`; L050 failed 1: `std-001-json-iftar-guests: no file of checks/ or reference/ wholly in prompt.md (evals/llm/tasks/std-001-json-iftar-guests/checks/expected.stdout: every line is in prompt.md)`.
Mutation (iii): in tools/llm-eval.byn the prompt got `checks/expected.stdout` appended; L050 failed 52 (110 passed), both the prompt-sent and the without-`checks/` cases of every task with that file, e.g. `contracts-004-iftar-seats: prompt sent differs from preamble, context and prompt.md` (extra lines `Aisha: 5 seats left`) and `port-001-python-guest-table: same prompt without checks/ and reference/`.
Each mutation was restored by copying the saved original back (a worker may not run `git checkout`); the tree matches HEAD apart from the files listed in the task.
