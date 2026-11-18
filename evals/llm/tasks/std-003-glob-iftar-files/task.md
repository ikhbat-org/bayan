# std-003-glob-iftar-files

Title: Path matching with std.path
Category: std
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: alternatives for a directory, `?` with one character too few and too many, `*` matching nothing and a dotted name, a wrong extension, an extra directory level, an alternative that is not listed, surrounding spaces, a blank line, a repeated path, an empty segment.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-003-glob-iftar-files
```
