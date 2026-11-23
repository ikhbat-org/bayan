Write a file that declares a struct whose rules are checked when it is built, and one function. Do not write a `main` function or any top-level statements.

Declare the struct `Hall`, the prayer hall of a masjid on the morning of Eid, with three `i32` fields: `capacity`, `men` and `women`. Its rules, written as `requires` rules so that an invalid `Hall` cannot exist:

- `capacity` is above 0,
- `men` is 0 or more,
- `women` is 0 or more,
- `men` and `women` together are at most `capacity`.

When a `Hall` is built, every broken rule is reported as a violation that names a field. Each of the first three rules names its own field. The last rule must name `capacity`, not `men` or `women`.

Declare:

```
i32 placesLeft(Hall h)
```

`placesLeft` returns the places still free in the hall.

Example: building a `Hall` with `capacity` 50, `men` 30 and `women` 25 fails with one violation, and its field is `capacity`.
