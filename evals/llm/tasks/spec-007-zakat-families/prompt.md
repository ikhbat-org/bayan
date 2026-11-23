Write a program that answers a question about declaring and calling functions in Bayān.

Aisha shares zakat among poor families in whole dirhams. Declare two functions, each with two `i64` parameters, the zakat in dirhams first and the number of families second:

- `share` returns what each family gets: the zakat divided by the number of families, rounded down.
- `leftover` returns the dirhams left once every family has its share.

`main` reads standard input. Each line holds two whole numbers, each 1 or more, separated by one space: the zakat, then the number of families. There are no blank lines. For each line, `main` calls `share` and `leftover` and prints one line in this form:

```
<zakat> for <families>: <share> each, <leftover> left
```

Example: the input line `30 4` prints `30 for 4: 7 each, 2 left`.
