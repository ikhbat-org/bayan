Write a file with a distinct type, two structs and seven functions for booking shares of a qurbani cow. Every rule is checked when a value is built. Do not write a `main` function or any top-level statements.

Declare `Shares` as a distinct type over `i32` that only holds 1 through 7. The rule is a `requires` rule on the type.

Declare the struct `Booking`, one family's part of a cow, paid at 900 a share. It has three fields and one more rule:

- `family`, a `string`, of 1 through 16 characters,
- `shares`, a `Shares`,
- `paid`, an `i64`, of 0 or more,
- `paid` is at least 900 times the number of shares.

Declare the struct `Cow` with one field, `taken`, an `i32` of 0 through 7: the shares already booked.

Write every rule as a `requires` rule, so that an invalid `Shares`, `Booking` or `Cow` cannot exist.

Declare these functions with these signatures, unchanged:

```
Booking booking(string family, for i32 shares, by i64 paid) fails ValidationError<Shares>, ValidationError<Booking>
i64 change(Booking b)
string verdict(string family, for i32 shares, by i64 paid)
Cow emptyCow()
Cow added(Cow cow, by Booking b) fails ValidationError<Cow>
Cow addedAll(Cow cow, from List<Booking> bookings) fails ValidationError<Cow>
i32 sharesLeft(Cow cow)
```

- `booking` makes the `Shares` first, then the `Booking`, and fails with the first error.
- `change` returns what was paid beyond 900 a share.
- `verdict` calls `booking`. On success it returns `booked <family>: <n> shares, change <c>`. When the shares fail it returns `refused <family>: shares`, and when the booking fails, `refused <family>: booking`.
- `emptyCow` returns a cow with no share taken. It cannot fail.
- `added` returns the cow with the booking's shares taken, and fails when that breaks a rule. `addedAll` adds each booking in order and stops at the first failure.
- `sharesLeft` returns how many of the seven shares are free.

Example: `verdict("Bilal", for: 2, by: 1900)` is `booked Bilal: 2 shares, change 100`.
