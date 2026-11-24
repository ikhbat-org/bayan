Write a program that reads names from standard input and prints the badge for each student of the masjid's Quran circle.

Each non-blank line is one name. Leading and trailing spaces on a line are ignored; spaces inside a name are kept and count as characters. Blank lines are ignored. Names may be written in any script. In this task a character is one Unicode code point.

A badge holds at most 6 characters. A name of 6 characters or fewer is its own badge. A longer name's badge is its first 5 characters followed by `~`.

For each name, in input order, print `<badge> (<n>)`, where `<n>` is the number of characters in the whole name.

Example input:

```
Bilal
Abdulaziz
خديجة
```

Example output:

```
Bilal (5)
Abdul~ (9)
خديجة (5)
```
