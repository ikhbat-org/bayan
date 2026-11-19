# port-009-python-hifz-scores

Title: Port a Python program that keeps `None` beside numbers
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
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The task tests Bayān's optionals as the port of `None`: the map holds `i64?`, a comparison needs the optional narrowed or unwrapped, and a null optional interpolates as `null`, so the port must print `None` itself. The input covers: a name first seen without a score and later with one, a name first seen with a score of 0 and later without one (the 0 stays), a name never given a score, a later lower score that does not replace the best, a later higher one that does, two students tied for the top score, extra spaces and a blank line. Some students have a score, so `top:` is a number; the case where every student lacks a score (`top: None`) is not in the hidden input, because a task has one input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-009-python-hifz-scores
```
