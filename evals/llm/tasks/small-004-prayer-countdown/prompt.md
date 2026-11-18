Write a program that reads the time now and a list of prayer times from standard input, and prints how long is left to each prayer.

The first line is the time now. Every other non-blank line is a prayer: a name, one space, and its time. A time is written `HH:MM` on the 24-hour clock: two digits, a colon, two digits, the hour 00 to 23 and the minute 00 to 59. Leading and trailing spaces on a line are ignored. Blank lines are ignored.

When the first line is not a valid time, print `invalid time` and nothing else.

For each prayer, in input order, print one line:

- `<name>: in <h>h <m>m` when its time is later than now; `<h>` and `<m>` are the whole hours and the remaining minutes of the wait.
- `<name>: now` when its time is the time now.
- `<name>: passed` when its time is earlier than now.

A line that is not a name, one space and a valid time prints `skipped: <line>`, with the line's leading and trailing spaces removed, and is not a prayer.

After the last line print `next: <name>` for the prayer that is not passed and has the earliest time (the first one in the input when two share it), or `next: none` when there is no such prayer.

Example input:

```
04:50
Fajr 04:30
Dhuhr 12:05
```

Example output:

```
Fajr: passed
Dhuhr: in 7h 15m
next: Dhuhr
```
