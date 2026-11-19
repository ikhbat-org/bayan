# errors-007-quran-pages

Title: Handling one error case and passing the rest on
Category: errors
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
The hidden tests read pages 1, 604 and one with leading zeros, empty text, 0, a negative number, a word, a decimal, a trailing space, a plus sign and pages past 604, and assert the case each failure carries. They call `resumePage` with empty text, a page and each other failure, read the `last` payload through a `catch switch` with only the `notNumber` and `pastEnd` arms, and call it through `try` in a hidden function that fails `ResumeError`. Both compile only when `resumePage` fails the narrowed set and `ResumeError` is `PageError` without `blank` rather than a new set.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-007-quran-pages
```
