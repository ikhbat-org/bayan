Write a program that reads Hajj savings plans from standard input and prints how many months each saver still needs.

Each non-blank line is `<name> <saved> <goal> <monthly>`: four fields separated by one space. `<name>` is a name, and `<saved>`, `<goal>` and `<monthly>` are whole numbers of 0 or more. Leading and trailing spaces on a line are ignored. Blank lines are ignored. Any other line is a bad line: print `bad line: <line>`, with the line's leading and trailing spaces removed.

The program has a function that gives the months left: the whole number of months of `<monthly>` needed to raise `<goal>` minus `<saved>`, rounded up. It has two rules:

- A plan whose `<monthly>` is 0 is a business outcome: the function fails with an error you declare, and the program prints `<name>: no monthly saving` and goes on. This holds even when nothing is left to save.
- A plan whose `<saved>` is above its `<goal>` is a bug in the lists. Write that rule as a precondition of the function, with `expects`. The run then ends by that abort, with exit code 134, and nothing is printed for that line or after it.

For any other plan print `<name>: <n> months`.

Example input:

```
Aisha 300 1000 200
Bilal 50 x 10
Sumayya 10 10 0
Omar 900 100 5
Hamza 0 10 1
```

Example output, ending with exit code 134:

```
Aisha: 4 months
bad line: Bilal 50 x 10
Sumayya: no monthly saving
```
