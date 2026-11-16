# repair-001-missing-particle

Title: Repair BYN5005
Category: repair
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/expected.stdout`: hidden. The output the program must print; it reads no input.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN5005 twice. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
Run from the repository root. It prints `PASS repair-001-missing-particle` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/repair-001-missing-particle; d=tmp/llm-eval/repair-001-missing-particle
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < /dev/null > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  "$B" check --diagnostics json "$t/starter/solution.byn" 2>&1 | grep -q '"code":"BYN5005"' &&
  echo "PASS repair-001-missing-particle"
```
