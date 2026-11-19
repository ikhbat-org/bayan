Write a program that answers a question about Bayān's unions by printing a report.

Bilal keeps the log of a camp at Mina during Hajj. Standard input holds one entry per line. Leading and trailing spaces on a line are ignored and blank lines are skipped. Fields are separated by one space. A count is a whole number of 0 or more, written in digits.

- `tent <beds> <pilgrims>`: a tent, its beds and the pilgrims in it.
- `bus <seats>`: a bus and its seats.
- `rest`: a rest stop.
- Any other line is unknown. That includes one of these words with the wrong number of fields or with a field that is not a count. Words are compared byte for byte, so `Rest` is unknown.

Declare one `union` with a case for each of the four kinds of entry, each case carrying its data; an unknown entry carries its line with the surrounding spaces removed. Read every line into a value of that union and keep them all in one `List`. Only after the input ends, go through the list and print the report, with a `switch` over the union.

The report has one line per entry, in input order:

- a tent: `tent: <pilgrims> pilgrims in <beds> beds, <state>`, where `<state>` is `full` when the two are equal, `<n> free` when there are `<n>` fewer pilgrims than beds, and `<n> short` when there are `<n>` more;
- a bus: `bus: <seats> seats`;
- a rest stop: `rest`;
- an unknown entry: `unknown: <line>`.

Then four lines:

```
tents: <number of tents>, beds: <sum of beds>, pilgrims: <sum of pilgrims>
buses: <number of buses>, seats: <sum of seats>
rests: <number of rest stops>, unknown: <number of unknown entries>
every pilgrim seated: <yes when the pilgrims are at most the seats, otherwise no>
```

Example input:

```
tent 6 4
bus 3
```

Example output:

```
tent: 4 pilgrims in 6 beds, 2 free
bus: 3 seats
tents: 1, beds: 6, pilgrims: 4
buses: 1, seats: 3
rests: 0, unknown: 0
every pilgrim seated: no
```
