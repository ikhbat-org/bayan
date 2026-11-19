# std-010-regex-notice-boards

Title: Masjid notice boards routed with std.regex
Category: std
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: a refused `(?i)` flag (`unsupported`), a rule line with surrounding spaces and `|`, a line with no space, a board with two rules, an unclosed group, a count above 1000, a backreference, a pattern too large, a non-ASCII pattern whose byte offset differs from its rune offset, a board whose every rule failed (not listed), an anchored pattern, a blank line in each part, `\b` around a word, a notice matched by two rules (the first wins), a notice that is `---` after the separator, and three notices no rule matches.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-010-regex-notice-boards
```
