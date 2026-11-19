Write a program that keeps track of a Ramadan khatm circle at the masjid, where readers share the 30 juz of the Quran. It reads commands from standard input, one per line, and prints what each command reports.

The juz are numbered 1 to 30. At the start every juz is open. A juz is open, claimed by a reader, or finished by a reader.

Leading and trailing spaces on a line are ignored. Blank lines are ignored. Fields are separated by one space. A name is one field. A juz number is a whole number from 1 to 30.

Commands:

- `claim <name> <juz>`: when the juz is open, it becomes claimed by `<name>`; print `<name> claims juz <juz>`.
- `done <name> <juz>`: when the juz is claimed by `<name>`, it becomes finished by `<name>`; print `<name> finished juz <juz>`.
- `release <name> <juz>`: when the juz is claimed by `<name>`, it becomes open; print `juz <juz> is open again`.
- `status`: print `finished: <f> claimed: <c> open: <runs>`, where `<f>` and `<c>` count the finished and the claimed juz, and `<runs>` lists the open juz from lowest to highest, joined by `, `. A run of two or more consecutive open juz is written `<first>-<last>`, a single one as its number, and no open juz as `none`.

When `claim`, `done` or `release` cannot act, it changes nothing and prints, by the juz's state:

- open: `juz <juz> is not claimed`
- claimed by someone (any name, the same one included, for `claim`; another name for `done` and `release`): `juz <juz> is taken by <that name>`
- finished: `juz <juz> was finished by <that name>`

Any other line, including a command with the wrong number of fields or a bad juz number, prints `bad command: <line>`, with the line's leading and trailing spaces removed.

Example input:

```
claim Aisha 4
claim Bilal 4
done Aisha 4
status
```

Example output:

```
Aisha claims juz 4
juz 4 is taken by Aisha
Aisha finished juz 4
finished: 1 claimed: 0 open: 1-3, 5-30
```
