Write a file that declares an error set with payloads and two functions for splitting sadaqah evenly. Do not write a `main` function or any top-level statements.

Declare the error set `ShareError` with three cases:

- `noPeople`: nobody to give to.
- `negative`, carrying the amount as an `i64` named `amount`.
- `uneven`, carrying what is left over as an `i64` named `left`.

Declare:

```
i64 share(i64 total, for i64 people) fails ShareError
string describe(i64 total, for i64 people)
```

`share` returns what each person receives. The checks run in this order:

1. `people` is 0 or less: fail `noPeople`.
2. `total` is below 0: fail `negative` with the total.
3. `total` does not divide evenly by `people`: fail `uneven` with the remainder.

`describe` calls `share` and never fails. It returns:

- `each gets <n>` when `share` succeeds,
- `no people`,
- `negative amount: <amount>`,
- `left over: <left>`.

Examples: `share(120, for: 4)` is 30. `describe(100, for: 3)` is `left over: 1`.
