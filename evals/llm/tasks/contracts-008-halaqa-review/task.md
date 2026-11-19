# contracts-008-halaqa-review

Title: Reading the violations of a failed build
Category: contracts
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests review valid students, students at the edges of every rule, names too short, too long, empty, with a space at either end and a single space (both name rules broken, so `name` is listed twice), ages and juz counts on both sides of their ranges, and students with every rule broken. Two name rules joined with `&&` in one `requires` report one violation and fail the single-space cases.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-008-halaqa-review
```
