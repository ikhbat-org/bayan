Write a program that tells which file paths fit a pattern. Match with `Glob` from the `std.path` module.

The first line of standard input is the pattern. Every other non-blank line is a path, with leading and trailing spaces ignored. The pattern uses these forms and no others:

- `*` matches any run of characters, including none, inside one path segment; it never matches a `/`.
- `?` matches exactly one character that is not `/`.
- `{a,b}` matches `a` or `b`.
- Any other character matches itself.

The whole path must match the pattern.

For each path, in input order, print `<path>: match` or `<path>: no match`. After the last path print `matched: <number of paths that match>`.

Example input:

```
iftar/*.txt
iftar/dates.txt
iftar/soup/lentil.txt
```

Example output:

```
iftar/dates.txt: match
iftar/soup/lentil.txt: no match
matched: 1
```
