# spec-003-taraweeh-ranges

Title: Range precedence, range tests and indexes from the end
Category: spec
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/expected.stdout`: hidden. The output the program must print. There is no `checks/stdin`; the program reads no input.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The cases are settled by section 6.1 of the spec: `a..=b` binds looser than every arithmetic operator, so `0..=nights - 1` is `0..=(nights - 1)`, and `x in a..=b` is a boolean test; and by section 3.5, where `xs[^1]` indexes from the end. The prompt names no operator. A candidate that reads the range as C# would, or that uses `xs.length - 1` against the instruction, is not caught by the output alone, so the prompt states the expressions it wants and the expected output is what the pinned compiler prints for them.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-003-taraweeh-ranges
```
