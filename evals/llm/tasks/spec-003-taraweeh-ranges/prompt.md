Write a program that answers questions about Bayān's ranges and indexes by printing the answers.

Zaynab prays taraweeh on `nights` = 6 nights, numbered from 0. Her gifts, in the order she gave them, are 10, 20 and 35 dirhams, kept in a `List<i64>`.

1. What is the sum of the night numbers in the inclusive range that starts at 0 and ends at `nights - 1`? Write the end of the range as the expression `nights - 1`, with no parentheses.
2. How many values does the inclusive range from 0 to `nights` hold? Count them in a loop.
3. Is night 3 in the inclusive range from 1 to `nights - 1`? Is night `nights` in it? Use the language's own test for a value in a range, and no parentheses around `nights - 1`.
4. What are the last gift and the second to last gift? Index from the end of the list, never with the length.

Print the answers, one per line, in this form:

```
taraweeh sum: <number>
taraweeh steps: <number>
taraweeh inside: <true or false>
taraweeh edge: <true or false>
taraweeh last: <number>
taraweeh second last: <number>
```

The program reads no input.
