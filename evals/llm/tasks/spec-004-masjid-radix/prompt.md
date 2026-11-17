Write a program that answers questions about Bayān's number text and maps by printing the answers.

Part one. Four whole numbers are held in typed values:

- `debt` is an `i8` that holds -2.
- `capacity` is a `u16` that holds 4095.
- `empty` is a `u8` that holds 0.
- `rows` is a `u8` that holds 10.

Give the text of `debt`, `capacity` and `empty` in lowercase hexadecimal, and the text of `rows` in binary, with the conversion the language provides for a number in a given radix. Print them in this form:

```
debt hex: <text>
capacity hex: <text>
empty hex: <text>
rows binary: <text>
```

Part two. Bilal keeps the seats of four masjids in a `Map<string, i64>`. He adds them in this order: Quba 120, Nabawi 900, Aqsa 400, Haram 1500. Then he goes through the map once with a `for` loop, printing one line per entry, in this form:

```
masjid <name>: <seats>
```

The same loop adds the seats up, and after it the program prints one more line:

```
masjid total: <sum of the seats>
```

Print the part-one lines first, then the part-two lines, in the order a `for` loop over the map visits them. The program reads no input.
