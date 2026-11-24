# repair-004-missing-prayer

Title: Repair BYN2410
Category: repair
Tier: 2
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
`starter/solution.byn` fails `bayan check` with BYN2410: a `switch` over an enum leaves out `maghrib`. The prompt gives the rak'ahs of `maghrib`. The input covers: every prayer, a blank line, spaces around a word, a word that is not a prayer, a capitalised prayer name, a repeated prayer. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-004-missing-prayer
```
