# port-008-python-adhan-shift

Title: Port a Python clock shift that divides negative numbers
Category: port
Tier: 2
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
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The task tests that Bayān's integer `/` truncates toward zero and its `%` takes the sign of the dividend, where Python's `//`, `%` and `divmod` round down: a port with plain `/` and `%` prints a negative minute or the wrong day for a time moved before midnight. The `:02d` holes port to `width:` and `fill:` in the interpolation hole. The input covers: a shift back within the day, a shift forward past midnight, a shift back past midnight, a zero shift, a shift back that lands on midnight of the same day, a shift back of more than a day, a shift of one whole day forward, a shift of two whole weeks back, extra spaces, a blank line, a line of two words, and a negative total for the last line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-008-python-adhan-shift
```
