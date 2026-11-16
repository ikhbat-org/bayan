Write a program that reads one JSON document from standard input and prints the iftar guest list it describes. Parse the document with the `std.json` module.

The document is an object. Its `host` member is text. Its `guests` member is a list of objects, each with a `name` (text) and `dishes` (a whole number).

Print, in this order:

1. `host: <host>`; when `host` is missing or is not text, `host: unknown`.
2. For each guest, in document order, `<name> brings <dishes>`. A missing or non-text `name` is `unknown`; a missing or non-number `dishes` is `0`.
3. `dishes: <sum of the dishes printed>`.

When the input is not valid JSON, print `invalid json` and nothing else.

Example input:

```
{"host": "Aisha", "guests": [{"name": "Bilal", "dishes": 2}]}
```

Example output:

```
host: Aisha
Bilal brings 2
dishes: 2
```
