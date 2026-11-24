Write a file that declares one public function for seating guests at an iftar. Do not write a `main` function or any top-level statements.

Declare, as `public`:

```
List<i64> tableSizes(i64 guests, by i64 seats)
```

The guests fill tables of `seats` places one table at a time, in order. `tableSizes` returns how many guests sit at each table, first table first. Every table is full except possibly the last. No guests give an empty list. `seats` is always 1 or more and `guests` is never negative.

Give the function the `uses` clause its body needs, and no effect beyond it. It does not print. Callers may run it under `provide allocator:` with an arena of their own.

Examples: `tableSizes(10, by: 4)` is `[4, 4, 2]`. `tableSizes(6, by: 3)` is `[3, 3]`. `tableSizes(0, by: 5)` is empty.
