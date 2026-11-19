Write a program that hides a name in Eid greeting cards read on standard input. Find the name with `Regex` from the `std.regex` module.

The first line of the input is the name. It is never empty, and every character of it, spaces and punctuation included, stands only for itself. Every other line is a line of a card.

Print each card line, in order, with every occurrence of the name replaced by `[hidden]` and nothing else changed. Occurrences are found left to right and do not overlap, and case matters. A blank card line prints a blank line. After the last card line print `hidden: <number of occurrences replaced>`.

Example input:

```
Zaynab
Eid Mubarak, Zaynab!
From Bilal
```

Example output:

```
Eid Mubarak, [hidden]!
From Bilal
hidden: 1
```
