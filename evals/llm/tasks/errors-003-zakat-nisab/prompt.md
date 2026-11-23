Write a file that declares an error set and one function that fails. Do not write a `main` function or any top-level statements.

Declare the error set `ZakatError` with three cases:

- `badNisab`: the nisab is 0 or less.
- `negative`: the savings are below 0.
- `belowNisab`: the savings are below the nisab, so no zakat is due.

Declare:

```
i64 zakatDue(i64 savings, at i64 nisab) fails ZakatError
```

`zakatDue` returns the zakat due on `savings`: one fortieth of them, the division rounded down. The checks run in this order, and the first one that applies decides the failure:

1. `nisab` is 0 or less: fail `badNisab`.
2. `savings` is below 0: fail `negative`.
3. `savings` is below `nisab`: fail `belowNisab`.

Savings equal to the nisab are due.

Examples: `zakatDue(1000, at: 500)` is 25. `zakatDue(50, at: 100)` fails `belowNisab`.
