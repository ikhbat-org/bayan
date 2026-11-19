Write a program that answers a question about Bayān's maps by printing the answers.

On Eid, Aisha's family records the eidi each child is given, in a `Map<string, i64>` from the child's name to the dirhams given so far. Standard input holds one command per line:

- `give <name> <amount>`: add `<amount>`, a whole number of 0 or more, to what `<name>` has. A name not yet in the map starts at 0 and is added to it. Print nothing.
- `ask <name>`: print `<name>: <dirhams>`, what `<name>` has been given, or 0 when the name is not in the map. Asking never adds a name to the map.
- `children`: print `children: <n>`, the number of entries in the map.

A name is one field and names are compared byte for byte, so `Aisha` and `aisha` are two children. Fields are separated by one space. There are no blank lines and no other commands. Read and update the map with the members the language provides for a key that may be missing.

Example input:

```
give Hafsa 10
ask Hafsa
```

Example output:

```
Hafsa: 10
```
