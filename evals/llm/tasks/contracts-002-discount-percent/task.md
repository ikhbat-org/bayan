# contracts-002-discount-percent

Title: A checked distinct type
Category: contracts
Tier: 1
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
The hidden tests call `discounted` with constant percentages and `priceAfter` with values inside and outside the range.

## Check command
Run from the repository root. It prints `PASS contracts-002-discount-percent` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/contracts-002-discount-percent; d=tmp/llm-eval/contracts-002-discount-percent
mkdir -p "$d" && cp "$t/reference/solution.byn" "$t"/checks/*.byn "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" test "$d" &&
  echo "PASS contracts-002-discount-percent"
```
