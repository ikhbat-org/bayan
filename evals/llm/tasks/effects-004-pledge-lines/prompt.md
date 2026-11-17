Write a file for reporting pledges to a fund. Do not write a `main` function or any top-level statements.

Declare, as `public`, a struct with two fields, `donor` (a `string`) and `amount` (an `i64`):

```
struct Pledge
```

Callers build one with `Pledge { donor: "Aisha", amount: 30 }`.

Declare, as `public`:

```
string describePledge(Pledge pledge)
void announcePledge(Pledge pledge)
i64 pledgedTotal(List<Pledge> pledges)
List<string> describeAll(List<Pledge> pledges)
void announceAll(List<Pledge> pledges)
```

- `describePledge` returns the donor's name, then ` pledged `, then the amount. For Aisha and 30 it is `Aisha pledged 30`.
- `announcePledge` prints the line `describePledge` gives, on standard output.
- `pledgedTotal` returns the sum of the amounts. No pledges give 0.
- `describeAll` returns the `describePledge` line of each pledge, in order. No pledges give an empty list.
- `announceAll` prints the `describePledge` line of each pledge in order, then one line that holds the total.

Give each function the `uses` clause its body needs, and no effect beyond it. Callers may run `describePledge` under `provide allocator:` with an arena of their own.
