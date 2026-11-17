Write a file that reads gifts written as lines of text, with two error sets. Do not write a `main` function or any top-level statements.

Declare the error set `AmountError` with three cases:

- `empty`: the text is empty.
- `notNumber`: the text is not a whole number.
- `notPositive`: the number is 0 or below.

Declare the error set `GiftError` with three cases:

- `badLine`: the line is not two fields.
- `unknownDonor`, carrying the name as a `string` named `name`.
- `overLimit`, carrying the donor's limit as an `i64` named `limit`.

Declare two structs:

- `Donor`, with a `string` field `name` and an `i64` field `limit`, the most the donor may give in one gift.
- `Summary`, with `i64` fields `accepted`, `refused` and `total`.

Declare:

```
i64 readAmount(string text) fails AmountError
i64 giftFrom(List<Donor> donors, for string line) fails AmountError, GiftError
string receipt(List<Donor> donors, for string line)
Summary tally(List<Donor> donors, for List<string> lines)
```

`readAmount` reads a whole number of dirhams. Empty text fails `empty`. Text that is not a whole number (a word, a decimal point, spaces inside) fails `notNumber`. A number of 0 or below, such as `-5`, fails `notPositive`.

`giftFrom` reads one line of the form `<name> <amount>`: two fields separated by one space. It returns the amount. The checks run in this order, and the first one that applies decides the failure:

1. The line is not exactly two fields: fail `badLine`.
2. The name is not the name of a donor in `donors`: fail `unknownDonor` with the name.
3. The amount is not valid: fail with the error `readAmount` gives.
4. The amount is above the donor's `limit`: fail `overLimit` with the limit. An amount equal to the limit is allowed.

`receipt` calls `giftFrom` and never fails. It returns:

- `thank you <name>: <amount>` when the gift is accepted,
- `bad line` for `badLine`,
- `unknown donor <name>` for `unknownDonor`,
- `over the limit of <limit>` for `overLimit`,
- `bad amount` for any `AmountError`.

`tally` reads every line in order. `accepted` counts the lines `giftFrom` accepts, `refused` counts the lines it fails on, and `total` is the sum of the accepted amounts.

Examples, with the donors Aisha (limit 100) and Bilal (limit 50): `giftFrom(donors, for: "Aisha 40")` is 40. `receipt(donors, for: "Bilal 80")` is `over the limit of 50`.
