# effects-005-gift-sinks

Title: Effect bounds on an interface and its conformers
Category: effects
Tier: 3
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
The interface method declares `uses alloc` as an upper bound, and `GiftBook.take` allocates, so it must declare `uses alloc` (BYN6002 without it). `GiftTally.take` must declare no effect: a hidden public function with no `uses` clause calls it, so a `take` that declares `alloc` fails the tests build with BYN6002 on that function. A hidden struct that conforms to the interface and allocates in `take` is passed to `giveAll`, so `giveAll` must be generic over the interface and declare `uses alloc`. The print functions need `console`; `announceTally` also needs `alloc` because it calls `describeTally`. The last test stores three functions in locals of function types that bound their effects, so an extra effect fails the tests build with BYN6005. The text of the printed lines is not checked.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-005-gift-sinks
```
