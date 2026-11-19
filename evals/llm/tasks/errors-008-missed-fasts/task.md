# errors-008-missed-fasts

Title: Optional values beside an error set
Category: errors
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
The hidden tests read days 1, 30, 19 and one with a leading zero, and texts that give no value: empty, 0, 31, 300, a negative number, a word, a trailing space and a decimal. They count an empty list, lists of distinct days and lists with lines to skip (including a list where every line is skipped), and read the `repeated` payload for a day named twice, a day written once with a leading zero and once without, two repeats where the first one decides, and a repeat after a skipped line. They build `Fast` values with `null` and with a reason, including an empty one, and find the latest day of three fasts, of one fast and of none.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-008-missed-fasts
```
