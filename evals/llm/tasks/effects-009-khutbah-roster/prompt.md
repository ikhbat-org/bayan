Write a file for the roster of imams who give the Friday khutbah at a masjid. Do not write a `main` function or any top-level statements.

Declare, as `public`, a struct `KhutbahRoster` that keeps the imams' names in the order they take turns. Callers make one with `KhutbahRoster(name)`, which starts the roster with that one imam. It has, all `public`:

- a read-only property `i64 count`: how many imams are on the roster;
- a read-only property `string names`: the names in order, separated by `, ` (a comma and a space). A roster of Aisha's two sons, Musa then Isa, gives `Musa, Isa`;
- a method `void add(ref this, string imam)` that puts an imam at the end of the turns;
- a method `string nameFor(i64 week)` that gives the imam whose turn falls in `week`. Week 0 is the first imam's, week 1 the second's, and after the last imam the turns start again from the first. `week` is never negative.

`count` and `nameFor` allocate nothing.

Declare, as `public`:

```
KhutbahRoster rosterOf(string first)
i64 rosterSize(KhutbahRoster roster)
string rosterLine(KhutbahRoster roster)
void announceRoster(KhutbahRoster roster)
```

- `rosterOf` returns a new roster with `first` as its only imam.
- `rosterSize` returns the roster's `count`.
- `rosterLine` returns the roster's `names`.
- `announceRoster` prints the roster's `names` on standard output.

Give every member and function the effects its body needs, declared the way the language allows for that kind of declaration, and no effect beyond them. Callers may run any of them under `provide allocator:` with an arena of their own.
