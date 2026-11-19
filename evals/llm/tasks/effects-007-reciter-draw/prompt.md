Write a file that declares one public function for choosing who recites the Quran at the masjid tonight. Do not write a `main` function or any top-level statements.

Declare, as `public`:

```
i64 drawReciter(i64 count)
```

There are `count` reciters on a list, at places 0 to `count - 1`. `drawReciter` returns the place of one of them, chosen at random, so that any reciter on the list can come up. `count` is always 1 or more.

Get the randomness from `Io.randomU64()`, which returns a `u64`. `u64(x)` and `i64(x)` convert between the two integer types.

Give the function the `uses` clause its body needs, and no effect beyond it. It does not print.

Example: `drawReciter(4)` returns 0, 1, 2 or 3.
