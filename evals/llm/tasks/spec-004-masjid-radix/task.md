# spec-004-masjid-radix

Title: Number text in a radix, and the order of a map
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
Section 3.2 of the spec says `string(n, as: .hex)` gives lowercase hexadecimal with no prefix and no leading zeros (`0` gives `0`), and that a negative value prints its two's-complement bits at the type's width, so `i8` -2 is `fe`, not `-2` and not `fffe`; `.binary` is the other radix used. Section 3.5 says a `Map` preserves insertion order, so the loop prints the four masjids in the order they were added. The prompt names no member. The expected output is the pinned compiler's. A map-order guess (sorted by key) fails on the second part.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-004-masjid-radix
```
