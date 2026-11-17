# small-003-sadaqah-gifts

Title: Gifts summed and ranked
Category: small
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: surrounding spaces, blank lines, a word, a negative number, a zero gift, two numbers on one line, a last line with no newline.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-003-sadaqah-gifts
```
