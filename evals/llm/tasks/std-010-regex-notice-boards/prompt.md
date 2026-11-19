Write a program that sorts masjid notices onto boards by rules. Compile and run the rules with `Regex` from the `std.regex` module.

Standard input has two parts, separated by the first line that is `---`. The line `---` is always there. Leading and trailing spaces on every line are ignored, and blank lines are ignored in both parts.

Each line of the first part is a rule, `<board> <pattern>`: `<board>` is the text before the first space, and `<pattern>` is everything after that space, in the syntax `Regex.parse` reads. Rules are numbered from 1, counting only non-blank rule lines. A board is never named `unsorted`. A rule that fails prints at once, as it is read:

- `rule <n>: malformed` when the line has no space.
- `rule <n>: syntax at <offset>`, `rule <n>: unsupported at <offset>` or `rule <n>: too large at <offset>` when `Regex.parse` refuses the pattern with its `syntax`, `unsupported` or `tooLarge` error, where `<offset>` is the byte offset that error carries.

A rule that fails is dropped. Each line of the second part is a notice. A notice goes to the board of the first rule, in rule order, whose pattern matches some part of the notice; print `<board>: <notice>`. A notice that no rule matches prints `unsorted: <notice>`.

After the last notice print `<board> <number of notices sent to it>` for each board that has at least one rule that did not fail, in the order of each board's first such rule, then `unsorted <number of unsorted notices>`.

Example input:

```
iftar iftar|suhoor
zakat zakat(
---
iftar tonight
zakat reminder
```

Example output:

```
rule 2: syntax at 5
iftar: iftar tonight
unsorted: zakat reminder
iftar 1
unsorted 1
```
