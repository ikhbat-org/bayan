# Dropoff: what Extrode Tidy (`tidy`, codename fihris) needs from Bayan

From: `extrode.com/tidy` (local file organizer, CLI in Bayan; concept in
`/Users/sy/Developer/extrode.com/tidy/docs/architecture/001-concept.md`).
Written here, not in `bayan/docs/handoffs/`, because the bayan checkout was on
`feat/011-self-hosted-emitter` with untracked files on 2026-11-22. Move it into the repo when
picked up.

fihris will be a real app pushing Bayan forward, the way Sūq is. Each item below names the planned module
(`docs/bayan-library-tiers.md`) it belongs in, so this is a priority order over existing plans,
not new design. C interop (`extern c`) is expected soon; items marked **(c)** can ship as thin
wrappers over libc / Win32 / a vendored C library once it lands.

## Checked on 2026-11-22 against bayan `feat/011-self-hosted-emitter`

Exists and used in `tests/cases/run`: `Io.listDir`, `Io.readFile`, `Io.readText`, `Io.writeFile`,
`Io.run` (argv, captures stdout/stderr, exit code), `Io.runBatch`, `Io.monotonicNanos`.
Nothing else filesystem-, time-, hash-, HTTP- or SQLite-related has a run test. `extern c` is in
the spec (`bayan-spec.md:2034`) with no run test.

## P0: first milestone (`scan`, `dupes`, `plan`/`apply`/`undo`, no model)

| need | module | acceptance (as fihris uses it) |
|---|---|---|
| stat: size, mtime, kind (file/dir/symlink), without following symlinks | `std.fs` (c) | stat 100k entries in < 2 s on an SSD |
| rename/move; same volume atomic, cross-volume copy+verify+remove | `std.fs` (c) | never overwrites: fails with a distinct error if the target exists |
| mkdir -p, remove file, remove empty dir, copy file | `std.fs` (c) | errors distinguish notFound / exists / permission / notEmpty |
| recursive walk with skip (e.g. `.git`, `node_modules`) | `std.fs` | streaming, not a full list in memory; doesn't follow symlink loops |
| streaming read in chunks | `std.fs` (c) | hash a 4 GB ISO in constant memory (`Io.readFile` loads all of it) |
| SHA-256 (and a fast non-crypto hash for pre-filtering, optional) | `std.crypto` (c) | ≥ 500 MB/s on M1 |
| wall-clock time, file mtime to UTC `YYYY-MM-DD`, local offset | `std.time` (c) | names like `2026-03-14-acme-bank-statement.pdf` and journal timestamps |
| home / user dirs (Downloads, Documents), env vars | `std.fs` user dirs, `std.env` | macOS and Windows |
| Unicode: NFC normalize, lowercase, script test (Arabic block) | `std` text | slugify keeps Arabic in NFC; macOS and Windows names compare equal after NFC |
| Windows: UTF-16 paths, long paths (`\\?\`), reserved names (`CON`, `NUL`) | `std.fs` | same tests pass on Windows (wp1, wlt1) |
| move to OS trash (macOS `NSFileManager trashItem`, Windows `IFileOperation`) | `std.fs` or app-level (c) | stopgap: fihris quarantine folder |

## P1: search index and model

| need | module | acceptance |
|---|---|---|
| SQLite with FTS5, prepared statements, transactions, blobs | DB driver over `std.db` (c, vendored amalgamation) | 100k rows insert in one transaction < 5 s; FTS5 `unicode61 remove_diacritics 2` |
| HTTP/1.1 client to `127.0.0.1` (POST JSON, timeouts) | `kit.http` (a minimal localhost client would unblock it) | talk to llama.cpp `llama-server` `/v1/chat/completions` and `/v1/embeddings` |
| JSON encode/decode | `std.json` | parse llama-server responses; decoded output `Untrusted` is fine |
| long-lived child process: spawn without waiting, pid, kill, wait | `std.process` | start `llama-server` once, reuse it for many files, stop it on exit and on Ctrl-C |
| f32 vector math over spans (dot product) | `std` | cosine over 100k × 1024-dim vectors in < 1 s |
| parallel work (hash/extract on N cores) | `std.fiber` / `.par()` | or `Io.runBatch` for external tools |

## P2: later

File watching (FSEvents, `ReadDirectoryChangesW`) for background indexing; zip writing for
`archive` (stopgap: spawn `tar -a -cf x.zip`, which ships with macOS and Windows 10+);
`kit.compress` for reading archives to index them.

## Why not spawn tools for P0

`Io.run` works today, so `mv`, `stat`, `shasum`, `sqlite3` and `curl` could stand in. That costs
one process start per file per operation (milliseconds on macOS, more on Windows), which is
minutes at 10k+ files. The tools also differ between macOS and Windows. It is fine for prototyping
`dupes` on one folder, not for shipping.

## Contact

Requests from fihris are tracked in `extrode.com/tidy/work/todo.md`; friction found while
building fihris will be logged in this format.

## Addendum 2026-11-22 (late): gaps hit building fihris T1

The tidy.py port is built on `Io.run` stopgaps (macOS only). Full list with file:line:
`/Users/sy/Developer/extrode.com/tidy/work/todo.md` "## Bayan gaps" (25 lines). The ones that cost most:

- `Io.run` fails `invalidUtf8` on binary stdout (forced `od` hex for magic bytes); no cwd argument.
- No stat / rename / mkdir / delete / hash / wall clock in `Io`: one process per operation kind per run.
- `Io.stdin` has no line read: an interactive prompt needs Ctrl-D.
- `List<string>.contains` and `ReadOnlySpan<u8>.startsWith` missing though the spec lists the first (BYN2003).
- `move`, `from`, `unique`, `out` as keywords collide with natural domain names (`Op.move(from, to)`).
- `List.sort` takes no key; a struct with a `List` field cannot be read out of a list by `let`.
- No NFC/NFKD at runtime (hand-rolled Arabic composition table); no `Path.join`/`parent`.
