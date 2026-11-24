# port-001-python-guest-table

Title: Port a Python table printer
Category: port
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.py`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3. The input covers: names of different lengths, a two-digit number, a blank line, extra spaces.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-001-python-guest-table
```
