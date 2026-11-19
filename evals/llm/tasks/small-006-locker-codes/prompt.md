Write a program that reads names from standard input and prints the shoe-locker code of each, for the masjid's locker board.

Each non-blank line is one name. Leading and trailing spaces on a line are ignored; spaces inside a name are kept. Blank lines are ignored. A name may be written in any script.

The code of a name is a 32-bit unsigned number `h`, computed from the bytes of the name's UTF-8 text. Start with `h = 5381`. For each byte `b`, in order, multiply `h` by `33` and keep only the low 32 bits of the product, then set `h` to `h` xor `b`.

For each name, in input order, print `<name>: <code>`, where `<code>` is `h` written as 8 lowercase hexadecimal digits, padded on the left with zeros when shorter. A name that appears twice is printed twice.

Example input:

```
Ibrahim
 Hafsa
```

Example output:

```
Ibrahim: 80ac35b1
Hafsa: 0d485938
```
