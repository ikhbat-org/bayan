Write a file that declares three error sets, one made from the other two, and three functions for opening the masjid door. Do not write a `main` function or any top-level statements.

Declare the error set `KeyError` with two cases:

- `noKey`: the key text is empty.
- `wrongKey`: the key is not the door's key.

Declare the error set `HourError` with one case:

- `closed`, carrying the hour the masjid opens as an `i64` named `opens`.

Declare the error set `DoorError` as the composition of `KeyError` and `HourError`: its cases are the cases of both, and a `KeyError` or an `HourError` converts to a `DoorError` wherever a `DoorError` is expected. Do not repeat the cases in it.

Declare:

```
void checkKey(string key) fails KeyError
void checkHour(i64 hour) fails HourError
string openDoor(string key, at i64 hour) fails DoorError
```

`checkKey` succeeds only for the key `bab-salam`, compared as written (letters, spaces and case all count). An empty key fails `noKey`; any other key fails `wrongKey`.

`checkHour` takes an hour from 0 to 23. The masjid opens at 4: an hour below 4 fails `closed` with `opens` set to 4. Any other hour succeeds.

`openDoor` checks the hour first, then the key, and passes either error on unchanged. When both pass, it returns `open at <hour>`.

Example: `openDoor("bab-salam", at: 5)` is `open at 5`.
