# 025 — proposed L050 amendment (Fable, 2026-11-19; awaits the owner)
Status: proposed (2026-11-19, awaits the owner)
Release: unscheduled
Sources: ./025-spec.md; `docs/laws/050-eval-hidden-stays-hidden.md`; the 40 seed tasks measured 2026-11-19

**Ruling: (B), amend the law. (A) cannot satisfy L050 as written, and the 11 failures are not leaks.**

I measured the 40 seed tasks in this worktree: 18 hidden files in 11 tasks share a line with `prompt.md`, and the one-line preamble shares none.

- **(A) is impossible for three kinds of line.**
  - Lines the task contract fixes: the `take` signature the reference must implement, `unknown command`, and the command word `report`.
  - Fixed vocabulary: `subhanallah` and `alhamdulillah` are 2 of the 4 distinct lines of small-002's stdin.
  - Structural lines: `}` in `checks.test.byn` and `entry.byn`.
  
  Avoiding these would mean prompts that never show a command or a fixed message on its own line. That makes the tasks worse to satisfy a matcher.
- **The rest is example reuse, which is not disclosure.** Every overlap is 1 to 3 lines, and no hidden file is wholly in its prompt. The model sees the example because the author wrote it in `prompt.md`, not because the runner showed `checks/`. Rewriting nine tasks' checks would buy nothing and force L048 rechecks.
- **The enacted statement uses line equality as a proxy for "shown to a model", and the proxy is wrong.** R3 itself is fine and needs no change.

**Amended Statement for the owner (the law changes only on their word):**

> For every task, the prompt the runner sends to a model is the preamble, then the context file when one is given with `--context`, then the task's `prompt.md`, each unchanged and nothing else, and it is the same prompt when the task's `checks/` and `reference/` are absent. No line of a file under `checks/` or `reference/` appears in the preamble. No file under `checks/` or `reference/` has all of its lines in `prompt.md`; a line that is also a line of a starter file (`starter/`) or a source program (`source.*`) the prompt quotes is not counted as being in `prompt.md`. Lines are compared after trimming leading and trailing whitespace; blank lines and lines with no letter or digit are not compared, and a file with no compared line is skipped.

**Amended "Counterexample looks like":**

> A task id and one of: a difference between the prompt sent and the preamble, context and `prompt.md`; a difference in the prompt sent when `checks/` and `reference/` are removed; a file under `checks/` or `reference/` and its line found in the preamble; or a file under `checks/` or `reference/` whose every line is in `prompt.md`.

What the amendment does:
- **Clause 1** is what R3 actually demands of the runner, and it is mechanical: send the prompt from a copy of the task without `checks/` and `reference/` and compare.
- **Clause 2** keeps T38's mutation test: a reference line added to the preamble fails.
- **Clause 3** catches a pasted reference and a hidden check that is nothing but the public example.
- **What it gives up:** a partial paste into `prompt.md` (a reference with one line changed) is no longer caught mechanically; that is left to review. I rejected a fraction or line-count threshold because any number would be tuned to these 40 tasks, and small-002's vocabulary already sits at half.

Effects:
- **Tasks:** none change, so L048 stamps stand and L049 is untouched.
- **Heldout:** the proof runs on dev tasks only (T38's done-when). The law says "every task", so the owner can run the same check on heldout themselves; no agent touches those tasks.
- **Until the owner amends:** T38 stays open. The writer holds the proof and neither commits a failing one nor weakens it to pass.

**Not verified:** I have not seen the writer's diff or run its proof. My count used my own reading of the starter and source exemption, and I did not test the "same prompt without `checks/` and `reference/`" clause against the runner.

**What would change my mind:** if the owner wants examples and hidden data disjoint as a task-quality rule, that is a separate task-authoring rule for stdin and expected-output values only. It still cannot cover contract-fixed lines, vocabulary or `}`, so the amendment is needed either way.

