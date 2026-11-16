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
Run from the repository root. It prints `PASS std-001-json-iftar-guests` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/std-001-json-iftar-guests; d=tmp/llm-eval/std-001-json-iftar-guests
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < "$t/checks/stdin" > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  echo "PASS std-001-json-iftar-guests"
```
