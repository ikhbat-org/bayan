# port-005-python-fund-ledger

Title: Port a Python fund ledger with a class and an exception
Category: port
Tier: 3
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
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The input covers every command and every error message: a blank line, extra spaces, a duplicate fund, an unknown fund, a bad amount (a word, 0), a withdrawal above the balance, a move to an unknown fund, a known command with too few words, an unknown command, and `show` with an extra word. The order of the checks inside a command matters: an unknown fund is reported before a bad amount, and a bad amount before a duplicate name.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-005-python-fund-ledger
```
