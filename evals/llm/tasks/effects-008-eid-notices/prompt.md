Write a file for posting Eid prayer notices. Do not write a `main` function or any top-level statements.

Declare, as `public`, an effect alias named `notice` that stands for the two effects posting a notice has: allocating and printing to standard output.

Declare, as `public`:

```
string noticeLine(string family, at i64 hour)
i64 noticeCount(List<string> families)
void postNotice(string family, at i64 hour)
void postAll(List<string> families, at i64 hour)
```

- `noticeLine` returns `Eid prayer for the `, then the family name, then ` family at `, then the hour, then `:00`. For Hamza and 9 it is `Eid prayer for the Hamza family at 9:00`.
- `noticeCount` returns how many families there are.
- `postNotice` prints the `noticeLine` line on standard output.
- `postAll` prints the `noticeLine` line of each family in order, then one line that says how many notices were posted. No families print only that last line.

`postNotice` and `postAll` declare their effects with `uses notice`. Give `noticeLine` and `noticeCount` the `uses` clause their bodies need, and no effect beyond it.
