# repair-005-missing-field

Title: Repair BYN2109
Category: repair
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN2109 three times, in three struct literals that leave out a field. The prompt says what each missing field holds. The input covers: tables that fit, a table that does not, a later table that fits after one that did not, an odd and an even number of guests, a guest count of 0, a line with a non-number, a line with three fields, a blank line. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-005-missing-field
```
