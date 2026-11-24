Write a file that declares one public function for zakat al-fitr. Do not write a `main` function or any top-level statements.

Declare, as `public`:

```
i64 fitraOwed(List<i64> households, at i64 rate)
```

Each number in `households` is how many people live in one household; it is never negative and may be 0. Every person owes `rate`. `fitraOwed` returns what all the households owe together. No households give 0.

Before it returns, `fitraOwed` writes one diagnostic message with `log` that names the number of people and the total. It does not print to standard output.

Give the function the `uses` clause its body needs, and no effect beyond it.

Example: households of 3 and 5 people at a rate of 10 owe 80.
