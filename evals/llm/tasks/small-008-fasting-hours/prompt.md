Write a program that reads Aisha's Ramadan fasting log from standard input and prints the hours of each fast and a summary.

Each non-blank line is a fast: a day, one space, and the hours fasted. The day is one field of any text without spaces. The hours are written as one or more digits, optionally followed by a point and one or more digits, and are from 0 to 24. Leading and trailing spaces on a line are ignored. Blank lines are ignored.

Every number this program prints is rounded to two decimal places and always printed with two digits after the point.

For each fast, in input order, print `<day>: <hours>`.

A line that is not a day, one space and valid hours prints `skipped: <line>`, with the line's leading and trailing spaces removed, and is not a fast.

After the last line print three lines:

```
days: <number of fasts>
average: <mean hours of the fasts>
longest: <day> <hours>
```

`longest` names the fast with the most hours, the first one in the input when two share it. When there are no fasts, print `average: none` and `longest: none` instead.

Example input:

```
Mon 15.25
Tue 14.75
Wed 14.8x
```

Example output:

```
Mon: 15.25
Tue: 14.75
skipped: Wed 14.8x
days: 2
average: 15.00
longest: Mon 15.25
```
