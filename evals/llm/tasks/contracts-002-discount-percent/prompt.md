Write a file that declares a distinct type with a rule and two functions that use it. Do not write a `main` function or any top-level statements.

Declare `Percent` as a distinct type over `i32` that only holds 0 through 100. The rule is a `requires` rule on the type.

Declare:

```
i64 discounted(i64 price, by Percent percent)
i64 priceAfter(i64 price, by i32 rawPercent) fails ValidationError<Percent>
```

`discounted` returns `price` (in fils) with `percent` taken off: the price minus `price * percent / 100`, the division rounded down. It cannot fail, because a `Percent` is always valid.

`priceAfter` does the same for a percentage that has not been checked yet, and fails when it is outside 0 through 100.

Examples: `discounted(2000, by: Percent(25))` is 1500. `priceAfter(2000, by: 101)` fails.
