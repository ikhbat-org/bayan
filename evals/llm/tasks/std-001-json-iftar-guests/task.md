# std-001-json-iftar-guests

Title: Guest list from JSON with std.json
Category: std
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: two full guests, a guest with no `dishes`, a guest with no `name`. Invalid JSON is described in the prompt and not checked by the seed input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-001-json-iftar-guests
```
