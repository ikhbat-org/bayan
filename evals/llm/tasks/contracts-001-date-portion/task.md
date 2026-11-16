# contracts-001-date-portion

Title: A struct that cannot be invalid
Category: contracts
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests build valid and invalid portions and assert `fails ValidationError<Portion>`; a solution that checks the rules by hand in `portion` instead of with `requires` cannot produce that error set.

## Check command
Run from the repository root. It prints `PASS contracts-001-date-portion` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/contracts-001-date-portion; d=tmp/llm-eval/contracts-001-date-portion
mkdir -p "$d" && cp "$t/reference/solution.byn" "$t"/checks/*.byn "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" test "$d" &&
  echo "PASS contracts-001-date-portion"
```
