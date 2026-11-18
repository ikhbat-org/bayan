# spec-001-sadaqah-counters

Title: Wrapping and saturating arithmetic on narrow integers
Category: spec
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 0530e92ea69c)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/expected.stdout`: hidden. The output the program must print. There is no `checks/stdin`; the program reads no input.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The case is settled by the spec's overflow rule: `+% -% *%` wrap and `+| -| *|` saturate, on integers only. The prompt names the operations, not their symbols or results, so the model must know both the spelling and the rule. The expected output is the pinned compiler's: `u8` 250 wrapping-plus 10 is 4, saturating-plus 10 is 255, and `i8` -120 wrapping-minus 10 is 126. A program that uses plain `+` or `-` overflows and traps, so it fails on its exit code as well as its output.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-001-sadaqah-counters
```
