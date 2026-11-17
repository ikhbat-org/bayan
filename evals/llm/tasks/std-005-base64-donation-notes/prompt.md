Write a program that reads sealed donation notes from standard input and prints a report. Decode the notes with `Base64` from the `std.encoding` module.

Each non-blank line is a note: `<donor>:<payload>`. Leading and trailing spaces on a line are ignored. Blank lines are ignored, but they still count in the line numbers, which start at 1. `<donor>` is one or more characters that are not `:`; `<payload>` is everything after the first `:`.

The payload is the Base64 encoding of UTF-8 text `<kind> <amount>`: a kind, one space, and an amount. The kind is `zakat`, `sadaqah` or `fidya`. The amount is a whole number of dirhams of 1 or more.

A note that fails is rejected and counts for nothing. Print `rejected line <n>: <reason>` at once, where `<n>` is its line number and the reason is the first of these that applies:

1. `line`: there is no `:`, or the donor is empty.
2. `base64`: the payload is not valid Base64.
3. `utf8`: the decoded bytes are not valid UTF-8.
4. `payload`: the text is not exactly two fields separated by one space.
5. `kind`: the first field is not one of the three kinds.
6. `amount`: the second field is not a whole number of 1 or more.

After the last line print the totals of the accepted notes:

```
zakat: <sum>
sadaqah: <sum>
fidya: <sum>
```

Then print one line `<donor> <sum of all their accepted amounts>` for each donor with at least one accepted note, the largest sum first. Donors with the same sum are printed in the order they first appear among the accepted notes.

Example input (the payloads are `zakat 250`, `sadaqah 40` and `sadaqah 15`):

```
Aisha:emFrYXQgMjUw
Bilal:c2FkYXFhaCA0MA==
Aisha:c2FkYXFhaCAxNQ==
```

Example output:

```
zakat: 250
sadaqah: 55
fidya: 0
Aisha 265
Bilal 40
```
