Write a program that turns pledges to read the Qur'an for a khatm into a JSON report. Build the report as a `JsonValue` and write it with `Json.encode` from the `std.json` module, with an indent of 2.

Each line of standard input is a pledge, `<name> <juz>`. Leading and trailing spaces on a line are ignored. Blank lines are ignored, but they still count in the line numbers, which start at 1. A pledge is valid when it has two fields and no more, separated by one space, and `<juz>` is a whole number from 1 to 30.

The report is one JSON object with these members, in this order:

1. `total`: the sum of the juz of the valid pledges.
2. `complete`: `true` when the total is 30 or more, else `false`.
3. `readers`: one object per valid pledge, in input order, with the members `name` (text) and `juz` (a number).
4. `skipped`: the line numbers of the non-blank lines that are not valid pledges, in order.

Print the text `Json.encode` gives and nothing else. As it writes them, a `"` or `\` in a name is escaped with `\`, a character outside ASCII is `\u` and four lowercase hexadecimal digits, and an empty list is `[]`.

Example input:

```
Hafsa 7
Khalid four
Sumayya 8
```

Example output:

```
{
  "total": 15,
  "complete": false,
  "readers": [
    {
      "name": "Hafsa",
      "juz": 7
    },
    {
      "name": "Sumayya",
      "juz": 8
    }
  ],
  "skipped": [
    2
  ]
}
```
