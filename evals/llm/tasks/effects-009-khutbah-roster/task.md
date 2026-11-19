# effects-009-khutbah-roster

Title: Effects of constructors and properties
Category: effects
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
Properties and constructors take no `uses` clause (spec section 3.10, "properties take no `uses` clause"); the pinned compiler rejects one with BYN1001 on a constructor and BYN1004 on a property. Their effects are inferred and passed to the caller: `KhutbahRoster(name)` builds a list and `names` builds a string, so `rosterOf`, `rosterLine` and `announceRoster` must declare `uses alloc` (BYN6002 without it), and `announceRoster` also `console`. The method `add` is an ordinary method and must declare `uses alloc`. `count` and `nameFor` read without allocating, and a hidden public function with no `uses` clause calls both, so a `nameFor` that declares `alloc` fails the tests build with BYN6002. The last test stores the four functions in locals of function types that bound their effects, so an extra effect fails the tests build with BYN6005. The hidden input covers a roster of one imam asked for weeks 0 and 5, a roster of three asked for weeks 0, 2, 3, 4 and 7 (the turns wrap), names of one and of three imams, and the functions under a provided arena. The text of the printed line is not checked.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-009-khutbah-roster
```
