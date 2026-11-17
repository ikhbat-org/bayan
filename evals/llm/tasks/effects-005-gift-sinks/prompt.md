Write a file for recording gifts at an iftar. Do not write a `main` function or any top-level statements.

Declare, as `public`, an interface for anything that takes in a gift:

```
interface IGiftSink {
    void take(ref this, string donor, for i64 amount) uses alloc
}
```

Declare, as `public`, two structs that conform to it. Callers make each with `GiftBook()` and `GiftTally()`.

- `GiftBook` keeps one line of text for each gift: the donor's name, then ` gave `, then the amount, as in `Aisha gave 5`. It has a read-only property `i64 count` (the number of gifts), a read-only property `bool isEmpty`, and a method `string lineAt(i64 index)` that gives the line of the gift at `index`, counting from 0 in the order the gifts were taken. `take` adds a line.
- `GiftTally` keeps only numbers. It has public fields `count`, `total` and `largest`, each an `i64` starting at 0: the number of gifts, the sum of their amounts, and the greatest single amount. `take` updates them. `take` of `GiftTally` allocates nothing and declares no effect.

Declare, as `public`:

```
void giveAll<S>(ref S sink, from List<string> donors, for i64 amount) where S : IGiftSink
void announceBook(GiftBook book)
string describeTally(GiftTally tally)
void announceTally(GiftTally tally)
```

- `giveAll` gives `amount` from each donor, in order, by calling `take` on the sink. It works with any struct that conforms to `IGiftSink`, including ones the caller writes.
- `announceBook` prints each line of the book on standard output, in order.
- `describeTally` returns the count, then ` gifts, `, then the total, then ` dirhams`. A tally of 3 gifts that add up to 12 gives `3 gifts, 12 dirhams`.
- `announceTally` prints the line `describeTally` gives.

Give each function the `uses` clause its body needs, and no effect beyond it. Keep the interface exactly as shown.
