Write a program that reads the guest lists of iftar tables from standard input and prints how many seats each table has left.

Each non-blank line is `<table> <seats> <guests>`: three fields separated by one space. `<table>` is a name and `<seats>` and `<guests>` are whole numbers of 0 or more. Leading and trailing spaces on a line are ignored. Blank lines are ignored. Any other line is a bad line.

For a good line print `<table>: <n> seats left`, where `<n>` is the seats minus the guests. For a bad line print `bad line: <line>`, with the line's leading and trailing spaces removed.

The program has a function `seatsLeft` that gives the seats left at a table. A table with more guests than seats is a bug in the lists, not a bad line, and the program must not go on after it. Write that rule as a precondition of `seatsLeft`, with `expects`. The run then ends by that abort, with exit code 134, and nothing is printed after the line before it.

Example input:

```
Aisha 8 5
Bilal 6 x
Zaynab 4 4
Omar 2 3
Hamza 9 1
```

Example output, ending with exit code 134:

```
Aisha: 3 seats left
bad line: Bilal 6 x
Zaynab: 0 seats left
```
