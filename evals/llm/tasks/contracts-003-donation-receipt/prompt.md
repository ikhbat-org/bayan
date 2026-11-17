Write a file that declares a struct whose fields have rules, and two functions. Do not write a `main` function or any top-level statements.

Declare the struct `Donation` with two fields:

- `donor`, a `string`, of 1 through 30 characters,
- `amount`, an `i64`, of 1 or more.

Write each rule as a `requires` rule on its field, so that an invalid `Donation` cannot exist.

Declare:

```
Donation donation(string donor, for i64 amount) fails ValidationError<Donation>
string receipt(Donation d)
```

`donation` builds a `Donation` and fails when a rule is broken. `receipt` returns `<donor> gave <amount>`.

Examples: `receipt(donation("Aisha", for: 50))` is `Aisha gave 50`. `donation("", for: 50)` fails.
