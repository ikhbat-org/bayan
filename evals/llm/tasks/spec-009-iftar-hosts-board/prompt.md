Write a program that answers a question about Bayān's text formatting by printing the answer.

Zaynab lists the hosts of an iftar and the guests each one feeds. Standard input holds one host per line: a name (one field of letters, which may carry marks, such as `Ḥ` or `ā`), one space, and the number of guests, a whole number of 0 or more. There are no blank lines.

For each host, in input order, print `<name field>|<guests field>`. After the last host, print `<title field>|<total field>`.

- The name field is the name in at least 10 columns, aligned to the start, padded with `.`.
- The guests field is the number of guests in at least 4 columns, aligned to the end, padded with `0`.
- The title field is the word `total` in at least 10 columns, centred, padded with `*`. When the padding does not split evenly, the extra `*` goes after the word.
- The total field is the sum of all the guests, laid out as a guests field.

Columns are counted in Unicode scalars (letters as a reader counts them), not in bytes. A value wider than its field is printed whole, never cut. Lay out the fields with the format options the language provides inside an interpolation hole, not by hand.

Example: the input line `Hafsa 15` prints:

```
Hafsa.....|0015
**total***|0015
```
