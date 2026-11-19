Write a program that describes the shape of hajj registration forms sent as JSON, one document per line of standard input. Read each document token by token with `JsonReader` from the `std.json` module; do not build a tree.

Lines are numbered from 1. A line with only spaces, or nothing, is skipped but still counted. For every other line print `<n>: depth <d>, keys <k>, scalars <s>`, where:

- `<d>` is the deepest nesting of lists and objects. A document that is a single text, number, `true`, `false` or `null` has depth 0; a list or object has depth 1, and each list or object inside another is one deeper than it.
- `<k>` is the number of object keys. A key repeated in one object counts each time.
- `<s>` is the number of texts, numbers, `true`, `false` and `null` values. Keys are not counted here.

When the line is not one valid JSON value and nothing more (spaces around it are allowed), or its lists and objects nest more than 128 deep, print `<n>: invalid` instead.

Example input:

```
{"pilgrim": "Aisha", "days": [8, 9]}
true false
```

Example output:

```
1: depth 2, keys 2, scalars 3
2: invalid
```
