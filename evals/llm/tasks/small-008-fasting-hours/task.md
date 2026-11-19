# small-008-fasting-hours

Title: Fasting hours to two decimals
Category: small
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The task tests float text both ways: `f64.tryParse`, and the `digits:` spec in an interpolation hole (a plain `{x}` prints `14` for 14.0, and a compact `{x:.2}` is BYN1068).

The input covers: a whole number of hours, a value that rounds up to the next whole hour (12.999), a value that rounds down, 0, 24 and 24.0 (a tie for longest), above 24, a negative, a point first, a point last, an exponent, two points, a missing hours field, an extra field, a word, surrounding spaces, a blank line. No value or mean is a tie at the third decimal. The empty case (`average: none`) is not in the input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-008-fasting-hours
```
