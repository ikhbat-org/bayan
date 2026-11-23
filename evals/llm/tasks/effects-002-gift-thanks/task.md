# effects-002-gift-thanks

Title: A public function that prints
Category: effects
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
A public function that calls `print` must declare `uses console`: without it the candidate does not compile (BYN6002). The text of the line is not checked, because the test runner captures console output and the prompt states only that the line names the donor and the amount. The last test stores the function in a local of type `(string, i64) -> void uses console`, so a clause with an extra effect such as `alloc` fails the tests build with BYN6005; `bayan check` alone accepts it.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-002-gift-thanks
```
