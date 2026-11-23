# errors-010-library-loans

Title: Errors kept as values and explained later
Category: errors
Tier: 3
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
The hidden tests build a library of four books (one already lent) and three members (one at the limit), explain error values they build directly, lend books, and fail on an unknown member, an unknown book, a book on loan and a member at the limit, including requests where two checks apply and names or codes that differ only in case. They read each payload through a `catch switch` with one whole-set arm per error set, check that a refused request leaves every `holder` and `holding` as it was, and run `lendAll` over a mix of eight requests (comparing the count, both lists of error values in order and the library afterwards) and over no requests.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-010-library-loans
```
