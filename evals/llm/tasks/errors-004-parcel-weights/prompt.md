Write a file that declares an error set and three functions that pass an error on or handle it. Do not write a `main` function or any top-level statements.

Declare the error set `ParcelError` with two cases:

- `badWeight`: the text is not a weight.
- `tooMuch`: the weight is over 50 kilos.

Declare:

```
i64 kilos(string text) fails ParcelError
i64 totalKilos(string first, to string second) fails ParcelError
i64 kilosOrZero(string text)
```

`kilos` reads the weight of a food parcel in kilos. A weight is a whole number written with digits, 1 or more. Anything else is `badWeight`: empty text, letters, a decimal point, a minus sign, 0. A weight over 50 fails `tooMuch`; 50 is allowed.

`totalKilos` returns the sum of the two weights. It reads `first` before `second`, and an error from either text is passed on unchanged.

`kilosOrZero` returns the weight of `text`, or 0 when `kilos` fails. It never fails.

Examples: `kilos("12")` is 12. `totalKilos("12", to: "30")` is 42. `kilosOrZero("heavy")` is 0.
