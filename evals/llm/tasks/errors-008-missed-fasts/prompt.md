Write a file that keeps the fasts of Ramadan someone missed, with optional values and one error set. Do not write a `main` function or any top-level statements.

Declare the error set `FastError` with one case:

- `repeated`, carrying a day as an `i64` named `day`.

Declare the struct `Fast` with an `i64` field `day` and a field `reason` that holds a `string` or no value at all.

Declare:

```
i64? dayOf(string text)
i64 missedCount(List<string> lines) fails FastError
string reasonOf(Fast fast)
i64? latestDay(List<Fast> fasts)
```

`dayOf` reads a day of Ramadan: a whole number from 1 to 30 written with digits only; leading zeros are allowed. For any other text (empty, a word, a sign, a space, a decimal point, a number outside 1 to 30) it returns no value.

`missedCount` reads `lines` in order and returns how many days they list. A line that `dayOf` gives no value for is skipped. When a line names a day that an earlier line already named, it fails `repeated` with that day, at the first such line. `03` and `3` are the same day.

`reasonOf` returns the reason of `fast`, or `no reason given` when it has none. An empty reason is a reason and is returned as it is.

`latestDay` returns the highest `day` in `fasts`, or no value when the list is empty.

Example: for the lines `5`, `rest`, `12`, `missedCount` returns 2.
