Write a program that reads sadaqah gifts from standard input and prints a summary.

Each non-blank line is one gift: a whole number of dirhams, 0 or more. Leading and trailing spaces on a line are ignored. Blank lines are ignored. Any other line is a bad line: it is not a gift and is counted apart.

After the last line print four lines:

```
gifts: <number of gifts>
total: <sum of the gifts>
largest: <the largest gift, 0 when there are no gifts>
bad: <number of bad lines>
```

Example input:

```
20
 5 
oops
```

Example output:

```
gifts: 2
total: 25
largest: 20
bad: 1
```
