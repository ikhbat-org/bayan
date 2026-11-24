# port-004-python-pledge-totals

Title: Port a Python totals-by-name program
Category: port
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.py`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The input covers: a name that repeats (the order is the first appearance), a blank line, extra spaces, a line with a letter in the number, a line with three fields, and the largest total.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-004-python-pledge-totals
```
