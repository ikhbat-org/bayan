Write a file that declares a struct whose rules are checked when it is built, and three functions. Do not write a `main` function or any top-level statements.

Declare the struct `Portion`, the dates laid out for an iftar table, with two `i32` fields, `dates` and `guests`. Its rules, written as `requires` rules so that an invalid `Portion` cannot exist:

- `dates` is above 0,
- `guests` is above 0,
- there is at least one date for every guest.

Declare:

```
Portion portion(i32 dates, for i32 guests) fails ValidationError<Portion>
Portion joined(Portion p, by i32 extra) fails ValidationError<Portion>
i32 perGuest(Portion p)
```

`portion` builds a `Portion` and fails when a rule is broken. `joined` returns `p` with `extra` more guests and the same dates, and fails when the result breaks a rule. `perGuest` returns the whole number of dates each guest gets.

Examples: `perGuest(portion(21, for: 7))` is 3. `portion(3, for: 4)` fails.
