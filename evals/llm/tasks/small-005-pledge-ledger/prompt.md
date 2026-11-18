Write a program that keeps a ledger of sadaqah pledges. It reads commands from standard input, one per line, and prints what each command reports.

Leading and trailing spaces on a line are ignored. Blank lines are ignored. Fields are separated by one space. A name is one field. An amount is a whole number of dirhams of 1 or more.

Commands:

- `pledge <name> <amount>`: add `<amount>` to what `<name>` has pledged. A name seen for the first time joins the ledger. Print `<name> pledged <total pledged by name>`.
- `pay <name> <amount>`: add `<amount>` to what `<name>` has paid. Print `<name>: settled` when paid equals pledged, `<name>: <n> left` when paid is below pledged by `<n>`, and `<name>: over by <n>` when paid is above pledged by `<n>`. A name that never pledged prints `unknown: <name>` and changes nothing.
- `report`: print one line per name, in the order the names first pledged: `<name> <pledged> <paid> <status>`. The status is `unpaid` when nothing is paid, `partial` when paid is above 0 and below pledged, `settled` when equal, and `over` when above. Then print `pledged: <sum of all pledged> paid: <sum of all paid>`.

Any other line, including a command with the wrong number of fields or a bad amount, prints `bad command: <line>`, with the line's leading and trailing spaces removed.

Example input:

```
pledge Aisha 100
pay Aisha 40
report
```

Example output:

```
Aisha pledged 100
Aisha: 60 left
Aisha 100 40 partial
pledged: 100 paid: 40
```
