Write a file that declares a struct whose fields have rules, and two functions that change one field. Do not write a `main` function or any top-level statements.

Declare the struct `ZakatPayment`, one zakat payment with a note for the treasurer. It has three fields:

- `payer`, a `string`, of 1 through 24 characters,
- `amount`, an `i64`, above 0,
- `memo`, a `string`, with no rule.

Write each rule as a `requires` rule on its field, so that an invalid `ZakatPayment` cannot exist.

Declare these two functions with these signatures, unchanged:

```
ZakatPayment withMemo(ZakatPayment p, to string memo)
ZakatPayment withAmount(ZakatPayment p, to i64 amount) fails ValidationError<ZakatPayment>
```

Each returns `p` with one field replaced and the other fields kept. `withMemo` replaces the note and cannot fail. `withAmount` replaces the amount and fails when the new amount breaks its rule.

Example: for a payment by Hamza of 300 with the note `cash`, `withMemo(p, to: "bank")` has the note `bank`, and `withAmount(p, to: 0)` fails.
