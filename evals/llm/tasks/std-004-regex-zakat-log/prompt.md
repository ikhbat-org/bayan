Write a program that totals zakat payments by month from a log read on standard input. Match each line with `Regex` from the `std.regex` module.

A valid line is `<name> paid <amount> on <date>` and nothing else: `<name>` is one or more ASCII letters, `<amount>` is one or more digits, and `<date>` is `YYYY-MM-DD` with only digits. Words and spaces are as shown, one space between fields. Leading and trailing spaces on a line are ignored. Blank lines are ignored.

A line that is not valid prints `skipped: <line>` at once, with the line's leading and trailing spaces removed.

After the last line print one line per month that has at least one valid line, in the order the months first appear: `<YYYY-MM>: <sum of the amounts paid in that month>`. Print nothing more.

Example input:

```
Aisha paid 200 on 2026-03-14
Bilal paid 50 on 2026-03-20
Maryam paid 75 on 2026-02-01
```

Example output:

```
2026-03: 250
2026-02: 75
```
