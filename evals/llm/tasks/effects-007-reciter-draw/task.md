# effects-007-reciter-draw

Title: A public function that draws at random
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
`Io.randomU64()` carries the `random` effect, so `drawReciter` must declare `uses random`: without it the candidate does not compile (BYN6002), and a made-up name such as `rand` or `io` is BYN6003. The conversion is given in the prompt so that the task turns on the effect alone. The hidden input covers one reciter (always 0), the range over 200 draws from 7, and every place reached in 300 draws from 3 (a fair draw misses one with a chance under 1 in 10^52). The last test stores the function in a local of type `i64 -> i64 uses random`, so a clause with an extra effect fails the tests build with BYN6005; `bayan check` alone accepts it.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-007-reciter-draw
```
