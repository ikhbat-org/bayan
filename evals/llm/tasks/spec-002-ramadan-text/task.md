# spec-002-ramadan-text

Title: Byte length and scalar count of a string
Category: spec
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/expected.stdout`: hidden. The output the program must print. There is no `checks/stdin`; the program reads no input.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The case is settled by section 3.2 of the spec: `s.length` is the byte length and `s.runeCount` counts scalars. The prompt names neither member, so the model must know both, and must not count by hand. The expected output is the pinned compiler's: `Ramaḍān` is 10 bytes (`ḍ` is 3, `ā` is 2) and 7 scalars, written as precomposed letters. A program that prints the same number twice fails.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-002-ramadan-text
```
