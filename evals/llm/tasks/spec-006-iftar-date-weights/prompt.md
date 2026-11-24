Write a program that answers a question about Bayān's number conversions by printing the answers.

Bilal weighs the dates for iftar boxes on a scale that gives a decimal reading. For each reading he wants a whole number held in a `u8` and one held in an `i8`, each made from the `f64` reading with the conversion the language provides from `f64` to that type.

Standard input holds one reading per line, in the form `f64` text parsing accepts: an optional `-`, digits, an optional point followed by digits, and an optional exponent such as `e5`. There are no blank lines and no spaces.

For each line, print one line in this form, where `<reading>` is the line as it was read:

```
<reading>: u8 <value>, i8 <value>
```

Example: the input line `42.5` prints `42.5: u8 42, i8 42`.
