Write a program that reads savings records from standard input and prints the zakat due on each.

Each non-blank line is a record: a name, one space, and the saver's savings as a whole number of dirhams. Leading and trailing spaces on a line are ignored. Blank lines are ignored.

Zakat is due only when the savings reach the nisab of 5000 dirhams. It is then one fortieth of the savings, rounded down. Below the nisab it is 0.

For each record, in input order, print `<name>: <zakat>`.

A line that does not have two fields separated by one space, or whose second field is not a whole number of 0 or more, prints `skipped: <line>`, with the line's leading and trailing spaces removed.

After the last line print `total: <sum of the zakat printed>`.

Example input:

```
Aisha 8000
Bilal 100
no amount
```

Example output:

```
Aisha: 200
Bilal: 0
skipped: no amount
total: 200
```
