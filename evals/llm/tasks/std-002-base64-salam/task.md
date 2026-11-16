# std-002-base64-salam

Title: Base64 commands with std.encoding
Category: std
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: encode, decode, text that is not Base64, an empty `encode`, Base64 of bytes that are not UTF-8 (`//79`), an unknown command. The Base64 values in `expected.stdout` were compared with Python's `base64` module.

## Check command
Run from the repository root. It prints `PASS std-002-base64-salam` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/std-002-base64-salam; d=tmp/llm-eval/std-002-base64-salam
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < "$t/checks/stdin" > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  echo "PASS std-002-base64-salam"
```
