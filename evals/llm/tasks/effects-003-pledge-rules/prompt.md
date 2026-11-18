Write a file that declares three public functions about pledges to a fund. Do not write a `main` function or any top-level statements.

Declare, as `public`:

```
List<i64> adjustPledges(List<i64> pledges, by (i64 -> i64) rule)
i64 totalAfter(List<i64> pledges, by (i64 -> i64) rule)
i64 countAbove(List<i64> pledges, at i64 floor)
```

- `adjustPledges` returns a new list. Each pledge in it is `rule` applied to the pledge at the same place in `pledges`. No pledges give an empty list.
- `totalAfter` returns the sum of `rule` applied to each pledge. No pledges give 0.
- `countAbove` returns how many pledges are strictly greater than `floor`.

Give each function the `uses` clause its body needs, and no effect beyond it. A caller may pass a `rule` that prints, and each function must accept it.
