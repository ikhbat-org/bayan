# effects-006-fitra-log

Title: Logging is not an effect
Category: effects
Tier: 1
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
Logging is ambient (spec section 14): `log` is allowed in a function with no `uses` clause and never allocates, even with an interpolated message, so `fitraOwed` declares no effect. A candidate that treats the log as console output and declares `uses console` (or `alloc` for the message) fails the tests build twice: a hidden public function with no `uses` clause calls it (BYN6002), and the last test stores it in a local of type `(List<i64>, i64) -> i64` (BYN6005). `uses log` is not an effect name (BYN6003). A candidate that uses `print` instead of `log` needs `console` and fails the same way. The hidden input covers several households, households of 0 people among others, all households empty, and no households. The text of the log message is not checked.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-006-fitra-log
```
