Write a program that reads dhikr phrases from standard input, one per line, and prints how often each was said.

Leading and trailing spaces on a line are ignored. Blank lines are ignored. Two lines are the same phrase when their text is equal after that.

Print one line per distinct phrase as `<count> <phrase>`, the phrase said most often first. Phrases with the same count are printed in the order they first appear in the input.

After them print `distinct: <number of distinct phrases>`.

Example input:

```
subhanallah
alhamdulillah
alhamdulillah
```

Example output:

```
2 alhamdulillah
1 subhanallah
distinct: 2
```
