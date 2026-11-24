# effects-008-eid-notices

Title: An effect alias
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
An effect alias is a declaration, `effect notice = alloc, console` (spec section 14), and expands to its effects wherever it is named. The hidden tests name `notice` in a `uses` clause and in function types, so a candidate that does not declare the alias, or spells it another way, does not build the tests (BYN6003). One test stores `postNotice` both under `uses notice` and under `uses alloc, console`, so an alias that names other effects fails with BYN6005 or, when it leaves one out, the candidate fails with BYN6002. `noticeLine` builds a string and must declare `uses alloc` alone; `noticeCount` declares nothing. A hidden public function declared `uses notice` calls both posting functions. The hidden input covers two hours of one and two digits, two families, and no families for both `noticeCount` and `postAll`. The text of the count line is not checked, and neither is `public` on the alias: the tests are in the same module, and the pinned compiler accepts a module-private alias in a public signature.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-008-eid-notices
```
