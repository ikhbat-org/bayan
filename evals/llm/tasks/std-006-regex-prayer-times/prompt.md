Write a program that lists the prayer times written in masjid announcements read on standard input. Find them with `Regex` from the `std.regex` module.

A time is two ASCII digits, `:`, and two ASCII digits (`29:99` counts). The character just before it and the character just after it, when there is one, must not be an ASCII letter, an ASCII digit or `_`. Times in a line do not overlap: a time that starts inside an earlier time of the same line is not a time.

Lines are numbered from 1, and blank lines count. For each time, line by line and left to right in a line, print `<line>:<offset> <time>`, where `<offset>` is the byte offset of the time's first digit in the line's UTF-8 bytes, counted from 0. After the last line print `times: <number of times found>`.

Example input:

```
Fajr 05:10
Eid prayer 07:30, then ʿAṣr 15:20
```

Example output:

```
1:5 05:10
2:11 07:30
2:31 15:20
times: 3
```
