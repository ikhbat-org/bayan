Write a file that boards groups of pilgrims onto a bus to umrah, where a group boards together or not at all. Do not write a `main` function or any top-level statements.

Declare the error set `BoardError` with three cases:

- `noName`: a name in the group is empty.
- `twice`, carrying the name as a `string` named `name`.
- `full`, carrying the number of seats as an `i64` named `seats`.

Declare the struct `Bus` with a `List<string>` field `riders`, the names on the bus in the order they boarded, and an `i64` field `seats`.

Declare:

```
void board(ref Bus bus, from string group) fails BoardError
i64 boardAll(ref Bus bus, from List<string> groups)
```

`group` is names separated by commas, with no spaces around them. `board` takes the names in order and, for each one, checks in this order:

1. The name is empty: fail `noName`.
2. The name is already in `riders`, from before the call or from earlier in this group: fail `twice` with the name. Names are compared as written, so case counts.
3. `riders` already holds `seats` names: fail `full` with `seats`.

Otherwise the name is appended to `riders`. When `board` fails, `riders` must be as it was before the call: the names of the group that were already appended are taken off again.

`boardAll` calls `board` for each group in order. A group that fails stays off the bus and the next group is tried. It returns how many groups boarded, and never fails.

Example: on a bus with 4 seats and `Hafsa` aboard, `board(ref bus, from: "Umar,Hafsa")` fails `twice` with `Hafsa`, and `riders` is still `Hafsa`.
