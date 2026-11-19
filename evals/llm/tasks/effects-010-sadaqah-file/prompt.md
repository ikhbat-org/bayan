Write a file for keeping the gifts of a masjid's sadaqah box and saving them to a file. Do not write a `main` function or any top-level statements.

Declare, as `public`, a struct `Gift` with two public fields, `donor` (a `string`) and `amount` (an `i64`).

Declare, as `public`, a struct `SadaqahBox` that keeps gifts in the order they were given. Callers make an empty one with `SadaqahBox()`. It has, all `public`:

- a read-only property `i64 count`: how many gifts are in the box;
- a read-only property `i64 total`: the sum of their amounts, 0 for an empty box;
- a method `void put(ref this, string donor, for i64 amount)` that adds a gift at the end;
- a method `Gift entryAt(i64 index)` that gives the gift at `index`, counting from 0.

`count`, `total` and `entryAt` allocate nothing.

Declare, as `public`:

```
void saveBox(SadaqahBox box, to string path)
i64 savedGifts(string path)
bool boxSaved(string path)
void discardBox(string path)
void announceBox(SadaqahBox box)
```

- `saveBox` writes the file at `path`, replacing any file already there. The file holds one line for each gift, in order, and each line ends with a newline. An empty box gives an empty file.
- `savedGifts` reads the file at `path` and returns how many lines it holds. When there is no file at `path` it fails with the `IoError` the read gave.
- `boxSaved` says whether a file exists at `path`.
- `discardBox` removes the file at `path`. Removing a file that is not there does nothing.
- `announceBox` prints one line for each gift on standard output, then one line with the total.

`saveBox`, `savedGifts` and `discardBox` pass on any `IoError` from the file system with `fails IoError`. Use `Io.writeFile(path, bytes)` (it takes the text's `bytes`), `Io.readText(path)`, `Fs.fileExists(path)` and `Io.remove(path)`.

Give every function and method the `uses` clause its body needs, and no effect beyond it.
