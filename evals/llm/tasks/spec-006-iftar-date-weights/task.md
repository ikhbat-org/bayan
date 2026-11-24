# spec-006-iftar-date-weights

Title: Float to integer conversion truncates and saturates
Category: spec
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The case is settled by section 6.2 of the spec: `I(x)` from a float truncates toward zero, saturates to the bounds of `I` (`0` for a negative value and an unsigned type) and maps `nan` to `0`; it is the one narrowing conversion that does not trap. The prompt names the conversion, not its spelling or its rule, so the model must know that `u8(x)` and `i8(x)` neither round nor trap nor wrap. A program that rounds, floors (`i8` -3.7 is -3, not -4) or wraps (`u8` 256 is 255, not 0) fails, and one that expects a trap and clamps by hand passes only if it clamps the same way. The expected output is the pinned compiler's.

The input covers: a fraction just under the next whole number (3.99), a negative fraction above -1 (-0.5), a negative with a fraction (-3.7, which `u8` makes 0 and `i8` makes -3), just above `i8`'s top (127.9, 128), just below its bottom (-128.9, -129), just above `u8`'s top (255.9, 256), far above it (1000.25), 0, -0, an exponent far out of both ranges each way (1e300, -1e300) and a tiny exponent (0.000001). `nan` cannot be read from the input and is not tested.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-006-iftar-date-weights
```
