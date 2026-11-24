Write a program that reads commands from standard input, one per line, and prints one line per command. Use `Base64` from the `std.encoding` module.

- `encode <text>`: print the Base64 encoding of the UTF-8 bytes of `<text>`. `<text>` is everything after `encode ` and may be empty.
- `decode <text>`: print the text that `<text>` encodes. When `<text>` is not valid Base64, or the decoded bytes are not valid UTF-8, print `invalid`.
- Any other line: print `unknown command`.

Example input:

```
encode Salam
decode U2FsYW0=
hello
```

Example output:

```
U2FsYW0=
Salam
unknown command
```
