# port-007-python-notice-columns

Title: Port a Python program that finds a character and counts characters
Category: port
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.py`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The task tests that a Bayān string's `length` and `position` count bytes, where Python's `len` and `find` count code points: the port counts with `runeCount`. The input covers: an ASCII line, an Arabic name and message, accented Latin letters after the colon, an Arabic line with no colon, an ASCII line with no colon, a line that starts with the colon, a line that ends with it, a line with three colons (the first one counts), a line with spaces before the name and around the colon, and a blank line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-007-python-notice-columns
```
