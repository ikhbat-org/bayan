Write a program that answers five questions about Bayān by printing the answers. Each question has its own function; `main` calls the five in order.

**Prayers.** Declare an enum `Prayer` for the five daily prayers, in this order, each with one constant `i64` datum, its rakaat: `fajr` 2, `dhuhr` 4, `asr` 4, `maghrib` 3, `isha` 4. Go through the values the enum provides and print one line for each, then the total, in this form:

```
salah <name>: <rakaat>
salah total: <sum of the rakaat>
```

Take the name of each prayer from the enum itself, not from a string you type.

**Removals.** Bilal's gifts are the `List<i64>` 10, 20, 30, 40, 50. First remove the elements at positions 1 up to but not including 3, with the list's `remove` taking `from:` and `until:`. Print the length and the elements then at positions 0, 1 and 2. Then remove the element at position 0 with `remove` taking `from:` and `through:`, and print the length and the elements then at positions 0 and 1:

```
gifts after until: <length>, <e0>, <e1>, <e2>
gifts after through: <length>, <e0>, <e1>
```

**Slices.** The string `Ḥasan ibn Zaynab` starts with a letter `Ḥ` (U+1E24, one scalar). Take the slice of the bytes from offset 0 up to but not including 7, and the slice from offset 8 to the end of the string, using a range slice and the string's byte length. For each slice print the text, its byte length and its scalar count:

```
word head: <text>, <bytes>, <scalars>
word tail: <text>, <bytes>, <scalars>
```

**Search.** In the same string, find the byte position of the text `ibn` and of the text `bint` with the string's own search member, which gives no position when the text is absent. Print the position, or -1 when there is none:

```
word position ibn: <position>
word position bint: <position>
```

**Update.** Declare a struct `Pledge` with the fields `donor` (`string`), `amount` (`i64`) and `paid` (`bool`). Make the pledge Bilal, 40, not paid. Make a second pledge from it with the language's copy-and-update form, changing only `paid` to true. Print `paid` and `amount` of the first and then of the second:

```
pledge before: <paid>, <amount>
pledge after: <paid>, <amount>
```

The program reads no input.
