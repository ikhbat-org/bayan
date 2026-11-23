Write a program that reads who is bringing which dish to the masjid's iftar potluck, from standard input, and prints who brings each dish.

Each non-blank line is a pledge: a name, one space, and a dish. A name and a dish are each one field without spaces. Two dishes are the same when their text is equal; case counts. Leading and trailing spaces on a line are ignored. Blank lines are ignored.

A line that does not have two fields separated by one space prints `skipped: <line>` at once, with the line's leading and trailing spaces removed, and is not a pledge.

After the last line, print one line per dish, in the order the dishes first appear: `<dish>: <names>`. `<names>` lists the names of that dish's pledges in input order. One name is written alone, two names as `A and B`, and three or more as `A, B and C`, with `, ` between names and ` and ` before the last one. A name is listed once per pledge.

Then print `dishes: <number of distinct dishes>`.

Example input:

```
Bilal soup
Aisha bread
Zaynab soup
```

Example output:

```
soup: Bilal and Zaynab
bread: Aisha
dishes: 2
```
