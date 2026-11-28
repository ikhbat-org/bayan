# 0027 — `Untrusted<T>` on every outside-data source

Status: decided (owner 2026-11-28: all A, with the amendments to D1, D3 and D6 below; not yet built; number provisional: 0025 is spec 026, 0026 is held by spec 028)
Release: unscheduled
Sources: SPEC §15.1, §7.9; owner answer on `Untrusted` chunk reads, 2026-11-27 (`docs/specs/027-concurrency/027-plan.md` "Needs decision" 2); owner decision 2026-11-28 (`docs/audits/2026-11-28-decisions-0.4.md` §2.2 and §6 item 2: option (c) dropped, `i64 Io.stdin.read(to:)` stays, process output has the same shape, `Untrusted` on chunked reads waits for one revision covering every §15.1 source)

## Problem

1. SPEC §15.1 says sources "return `Untrusted<T>` in their signatures", then says "Sources are not yet wrapped" and "For now `readAll` returns a plain `string`". No built source returns `Untrusted<T>` (table under Decision).
2. The `Untrusted` operations §15.1 describes are mostly not built either. Built: `Untrusted(x)`, `x.trustUnchecked() because "…"`, the facts `length` and `isEmpty` (`src/semantics/express2.byn:1279`), comparisons as facts (`express3.byn:410`), and the BYN2786 process-argument sink (`express.byn:249`). Not built: "operations on an `Untrusted` value return `Untrusted`", taint removal by constructing a type with `requires`, and escaped formatting ("Terminal output and logs escape control characters"; today `{u}` is BYN2225, `tests/cases/diag/untrusted-no-implicit.diag`). Wrapping the sources without these would force a `trustUnchecked` at almost every use.
3. The audit's option (c) (`read(to:)` returning `Untrusted<ReadOnlySpan<u8>>`) is dropped. The `i64` count stays, so the mark on a chunked read has to go somewhere other than the return value.
4. `docs/STATUS.md:30` marks `Untrusted<T>` `built`, though §15.1 says sources are not wrapped.

## Decision

Settled by the owner (2026-11-28), and only this:

- `i64 Io.stdin.read(to:)` keeps its name, particle, `i64` return and behaviour. Option (c) is dropped.
- A chunked read of process output (spec 027) takes the same shape as `Io.stdin.read(to:)`.
- How a chunked read is marked `Untrusted` is decided in this revision, once, for every §15.1 source together, not one source at a time.

Decided by the owner (2026-11-28): option A in every item under Decisions, with three amendments (D1, D3, D6). The "Decided" column below follows them.

### Sources

Counts are grep matches in `.byn` and `.diag` files on 2026-11-28, in the order `src/` / `lib/` / `tools/` / `examples/` / `tests/cases/`. They count call sites only. Process output counts `.stdout`/`.stderr` member uses not on `Io.` (an upper bound: it includes golden-expectation fields such as `expected.stdout`).

| §15.1 source | Today (path:symbol) | Decided | Counts |
|---|---|---|---|
| Request query | not built (`std.http`) | `Untrusted<string>? Request.query(string name)` (as Sūq `catalog.byn:38` writes it) | 0 / 0 / 0 / 0 / 0 |
| Request body | not built | `Untrusted<ReadOnlySpan<u8>> Request.body` (Sūq `accounts.byn:59`) | 0 / 0 / 0 / 0 / 0 |
| Request headers | not built | `Untrusted<string>? Request.header(string name)` (Sūq `checkout.byn:202`) | 0 / 0 / 0 / 0 / 0 |
| Cookies | not built | `Untrusted<string>? Request.cookie(string name)` (new name; Sūq has no cookie use) | 0 / 0 / 0 / 0 / 0 |
| Route parameters | not built | `Untrusted<string> Request.route(string name)` (Sūq `checkout.byn:157`) | 0 / 0 / 0 / 0 / 0 |
| Uploaded files | not built | `Untrusted<ReadOnlySpan<u8>>` content and `Untrusted<string>` file name on each upload (new names; Sūq has no upload) | 0 / 0 / 0 / 0 / 0 |
| Third-party API responses | not built | response body `Untrusted<ReadOnlySpan<u8>>`, header values `Untrusted<string>?`, status code clean (non-text scalar) | 0 / 0 / 0 / 0 / 0 |
| Files from user-chosen paths | `src/semantics/builtins.byn:214` `List<u8> Io.readFile(string path)`, `:223` `string Io.readText(string path)`, `:268` `List<string> Io.listDir(string path)`, `:579` `string Fs.realPath(string path)`, all `fails IoError` | an overload of each taking `Untrusted<string> path` and returning `Untrusted<…>` of the same result; a `string` path keeps the plain result (D4) | `readText` 192 / 1 / 26 / 0 / 15; `readFile` 65 / 0 / 8 / 0 / 13; `listDir` 77 / 2 / 8 / 0 / 5; `realPath` 9 / 3 / 7 / 0 / 6 |
| stdin, whole | `builtins.byn:1397` `Result<string, IoError> Io.stdin.readAll()`; `:353` `List<u8> Io.stdin.readAllBytes() fails IoError` | `Result<Untrusted<string>, IoError> Io.stdin.readAll()`; `Untrusted<List<u8>> Io.stdin.readAllBytes() fails IoError` | `readAll` 2 / 0 / 0 / 0 / 5; `readAllBytes` 6 / 0 / 0 / 0 / 6 |
| stdin, chunked | `builtins.byn:364` `i64 Io.stdin.read(to: Span<u8> buffer) fails IoError` | `i64 Io.stdin.read(to: Untrusted<Span<u8>> buffer) fails IoError` (D1 option A; a plain `Span<u8>` is BYN2202) | `read(to:` 3 / 0 / 0 / 0 / 2 |
| Command-line arguments | `src/semantics/compile.byn:990` `main(ReadOnlySpan<string> args)` (BYN2771) | `main(ReadOnlySpan<Untrusted<string>> args)` (D5) | 11 / 0 / 16 / 0 / 26 |
| Child process output, whole (owner, 2026-11-27) | `builtins.byn:1009-1013` `ProcessResult.stdout`, `.stderr`: `string`; `:60` `IoError.signaled(i32, string stdout, string stderr)`, `.timeout(Millis, string stdout, string stderr)` | `ProcessResult.stdout`, `.stderr`: `Untrusted<string>`; `exitCode` stays `i32`; `signaled(i32 signal, Untrusted<string> stdout, Untrusted<string> stderr)`, `timeout(Millis after, Untrusted<string> stdout, Untrusted<string> stderr)` (D8) | `.stdout`/`.stderr` 520 / 1 / 38 / 0 / 33; `.signaled(` 13 / 0 / 0 / 0 / 5; `.timeout(` 16 / 0 / 1 / 0 / 24 (`Io.run(` 76 / 6 / 21 / 0 / 62, `Io.runBatch(` 2 / 0 / 0 / 0 / 11) |
| Child process output, chunked | not built (spec 027 `ChildReader`) | `i64 ChildReader.read(to: Untrusted<Span<u8>> buffer)`, the same shape as stdin (owner); `readLine(max:)` keeps 027's `Untrusted<string>?` | 0 / 0 / 0 / 0 / 0 |
| Text from C | not built (`extern` is not in 0.4, §18) | an `extern` function's `string`, `ReadOnlySpan<u8>` or pointer-to-text result is `Untrusted<…>` of that type when §18 is built | 0 / 0 / 0 / 0 / 0 |
| Startup environment (trusted, §15.1) | `Env.get(string name)`: `string?` | unchanged | 50 / 0 / 14 / 0 / 14 (no change needed) |

`Fs.fileExists`, `Fs.fileSize` and `Fs.modified` accept an `Untrusted<string>` path and keep clean results (`bool`, `i64`, `Time` are facts).

### Freeze

The proposal changes builtin signatures and binding rules only. It adds no keyword, operator, clause or grammar form, so revision 0023's syntax freeze allows it.

## Decisions

### D1. How a chunked read into a caller buffer is marked

`i64` cannot carry the mark (owner), so it goes on the buffer, on documentation, or on the variable.

- **Option A: the buffer parameter is `Untrusted<Span<u8>>`.**
  ```bayan
  var input = Untrusted(List<u8>(capacity: 65536))
  let n = try Io.stdin.read(to: input.mutableSpan())   // n: i64, clean
  let text = try Utf8.decode(input[0..n])              // Untrusted<string>
  ```
  Pros: the mark is in the type, so every byte read from the buffer is `Untrusted` with no new rule; one signature shape for stdin and `ChildReader`; the count stays clean (at most the length the caller chose). Cons: the caller has to declare the buffer `Untrusted(…)` up front; it needs D2's lifting so `mutableSpan()` and slicing work on it; a plain `Span<u8>` argument becomes an error.
- **Option B: keep `Span<u8>`, untrusted by documentation only** (027 option (a)).
  ```bayan
  var input = List<u8>(capacity: 65536)
  let n = try Io.stdin.read(to: input.mutableSpan())
  let text = try Utf8.decode(input[0..n])              // string: nothing marks it
  ```
  Pros: no change to callers; nothing for the compiler to build. Cons: one §15.1 source stays untyped, so its bytes reach sinks with no check; it contradicts "sources return `Untrusted<T>`".
- **Option C: the compiler marks the argument's variable after the call** (flow-sensitive taint on the buffer).
  ```bayan
  var input = List<u8>(capacity: 65536)
  let n = try Io.stdin.read(to: input.mutableSpan())   // from here `input` is treated as Untrusted
  ```
  Pros: no declaration at the call site. Cons: the type of `input` changes without a visible annotation; it needs a flow analysis the compiler does not have; aliases of the buffer (another span over the same list) escape the mark.

Decided: A. Amendment (owner): `read(to:)` rejects a plain `Span<u8>` (BYN2202, per D9), and `readAll` and `readAllBytes` return `Untrusted` in this same revision, not a later one. Every whole-stream read in the spec and `lib/std` is covered: `Io.stdin.readAll` and `Io.stdin.readAllBytes`. `ChildReader` (spec 027) has chunked reads only (`read`, `readLine`) and no whole-stream read; whole child output comes through `ProcessResult` (D8).

| Read | Before | After | Counts (`src/` / `lib/` / `tools/` / `examples/` / `tests/cases/`) |
|---|---|---|---|
| `Io.stdin.read(to:)` | `Span<u8>` buffer | `Untrusted<Span<u8>>` buffer; plain `Span<u8>` is BYN2202 | 3 / 0 / 0 / 0 / 2 |
| `Io.stdin.readAll()` | `Result<string, IoError>` | `Result<Untrusted<string>, IoError>` | 2 / 0 / 0 / 0 / 5 |
| `Io.stdin.readAllBytes()` | `List<u8> … fails IoError` | `Untrusted<List<u8>> … fails IoError` | 6 / 0 / 0 / 0 / 6 |

### D2. Which operations carry the mark to their result

- **Option A: builtins lift, user code does not.** A builtin member, operator, index, slice, `for` element or pure builtin function (string, span, list, `Utf8`, `Hex`, `Path`, `T.parse`) applied to `Untrusted<T>` binds as on `T` and returns `Untrusted<…>`. Facts stay clean: `bool` results (comparisons, `isEmpty`, `contains`, `startsWith`, `is` patterns), `length`, `runeCount`. Parsed numbers are not facts (`try i32.parse(u)` is `Untrusted<i32>`, a size or loop-bound sink in the §15.1 table). User-written and `lib/std` functions do not lift: a `T` parameter rejects `Untrusted<T>` (BYN2202).
  ```bayan
  let line = u.trimmed()          // Untrusted<string>
  if u.startsWith("--") { … }     // bool: clean
  let k = try i32.parse(u)        // Untrusted<i32>
  ```
  Pros: builds the existing §15.1 bullet; a function that takes outside data says so in its signature. Cons: the compiler needs a lifted binding path for every builtin; `lib/std` helpers need `Untrusted` overloads to accept outside data.
- **Option B: nothing lifts.** Every use needs `trustUnchecked` first. Pros: nothing to build. Cons: at the counts above (several hundred sites), `trustUnchecked` stops meaning anything and `bayan audit` lists noise.
- **Option C: every call lifts, user functions included.** Pros: least migration. Cons: a function can no longer state that it takes only trusted input, so sinks written in Bayān lose their check.

Decided: A.

### D3. Untrusted data into effectful builtins

- **Option A: BYN2202 as now.** `writeFile`, `remove`, `createDirectory`, `removeDirectory`, `Fs.rename`, `Fs.copy`, `Fs.setModified` and `Io.stdout`/`Io.stderr` `write` given an `Untrusted` argument are BYN2202; `Io.run`/`Io.runBatch` arguments stay BYN2786.
  ```bayan
  try Io.writeFile("out.bin", bytes)   // bytes: Untrusted<List<u8>> → BYN2202
  ```
  Pros: no new rule; every write of outside data is visible as a `trustUnchecked`. Cons: writing downloaded bytes or echoing input needs a `trustUnchecked` per write.
- **Option B: data arguments lift, path arguments become a sink.** The bytes of `writeFile` accept `Untrusted`; its path, and every path of the other calls, reject it like BYN2786. Pros: fewer `trustUnchecked` for plain copying. Cons: a new per-parameter sink list; the line between data and path parameters has to be specified for each builtin.

Decided: A. Amendment (owner): file writes never escape. `Io.writeFile` and the other file effects given an `Untrusted` argument stay BYN2202. BYN2202's help text, when the argument is `Untrusted`, reads: "write the text to the terminal or a log, which escape control characters, or call `trustUnchecked() because "…"` if these are raw bytes you have checked". It names escaped output as the fix for text and `trustUnchecked` only for raw bytes.

Interplay with D6: an `Untrusted` string given to `Io.stdout.write` or `Io.stderr.write` is escaped, not rejected, so those two drop out of option A's BYN2202 list; the file effects keep it. `Untrusted<List<u8>>` (raw bytes) to `Io.stdout.write` has no text to escape and stays BYN2202.
```bayan
try Io.writeFile("out.txt", text)   // text: Untrusted<string> → BYN2202 (no escaping on files)
Io.stdout.write(text)               // escaped, accepted (D6)
```

### D4. File reads with an `Untrusted` path

- **Option A: allowed, the result is `Untrusted`.** Path traversal checks stay with BYN8004 (`PathSegment`, spec-only).
  ```bayan
  let text = try Io.readText(args[0])   // args[0]: Untrusted<string> → Untrusted<string>
  ```
  Pros: a CLI that reads the file its user names works with no ceremony. Cons: `../../etc/passwd` from a remote source is not stopped until BYN8004 is built.
- **Option B: the path parameter is a BYN2786 sink now.** Pros: traversal blocked today. Cons: every tool that reads a file named on its command line needs a `trustUnchecked` per read, or one per `main`.

Decided: A.

### D5. `main` arguments

- **Option A: `main(ReadOnlySpan<Untrusted<string>> args)` is the only form;** `main(ReadOnlySpan<string> args)` is BYN2771 with a fix-it to the new type.
  ```bayan
  void main(ReadOnlySpan<Untrusted<string>> args) {
      let path = args[0].trustUnchecked() because "the user names files on their own command line"
  }
  ```
  Pros: one form; matches §15.1 listing command-line arguments as a source. Cons: 53 `main` signatures change (11 / 0 / 16 / 0 / 26).
- **Option B: both forms accepted; the `string` form is a warning with the same fix-it.** Pros: no break. Cons: two forms of `main` stay in the language; the warning form keeps argv untyped.
- **Option C: arguments stay trusted;** §15.1 drops them from the source list. Pros: no migration. Cons: option injection through argv into `Io.run` (BYN2786's own example) goes unchecked.

Decided: A; all callers in the repository are updated in the same commit.

### D6. Formatting `{u}`

- **Option A: `{u}` formats `T` with control characters escaped, as `log` does (§14).**
- **Option B: keep BYN2225.** Pros: nothing to build. Cons: every message that shows input needs `trustUnchecked`.

Decided: A, amended (owner). Interpolation does not escape. An interpolated string with any `Untrusted` part (also an optional or collection of one) is `Untrusted<string>`, and the text is kept as is. Escaping happens where text reaches a terminal or log sink: `Io.stdout` and `Io.stderr` writes, `print`, `log`. BYN2225 no longer fires for `Untrusted<T>`. `{u, as: .debug}` is unchanged.

Escape set (applied by the sink to an `Untrusted<string>`; trusted strings are written as they are). §14 says `log` "escapes control characters" and names no form, so this revision fixes it as `\u{X}`: the code point in uppercase hex, no leading zeros.

| Code points | Treatment |
|---|---|
| U+000A (`\n`), U+0009 (`\t`) | kept as is |
| other C0, U+0000–U+001F | escaped, `\u{1B}` form |
| DEL, U+007F | escaped |
| C1, U+0080–U+009F | escaped |
| bidi overrides, U+202A–U+202E, and isolates, U+2066–U+2069 | escaped |
| everything else | kept as is |

```bayan
let msg = $"got {u}"           // msg: Untrusted<string>; holds the raw text
print(msg)                     // u = "\u{1B}[2J" (ESC) prints \u{1B}[2J, not a screen clear
print($"name {u}")             // u = "a\u{202E}b" prints a\u{202E}b; the override does not reorder the line
Io.stdout.write(msg)           // escaped the same way
```
Pros: builds the existing §15.1 bullet; error messages can show input; a built string still carries the mark to a file or process sink. Cons: terminal output differs from the raw bytes, so a program that must echo input exactly writes it as bytes after `trustUnchecked`.

### D7. Removing the mark by construction

- **Option A: build `try T(u)`**, where `T` is a distinct type with `requires` and `u` is `Untrusted<V>` for `T`'s underlying `V`; it returns a trusted `T`. Struct literals keep BYN2202 for an `Untrusted` field value; `T.fromJson` keeps §15.1's field rule.
  ```bayan
  let email = try Email(u)   // Email: trusted
  ```
  Pros: builds §15.1 "only construction of a type with `requires` removes it"; gives a checked way out. Cons: one more binding rule.
- **Option B: `trustUnchecked` stays the only way out.** Pros: nothing to build. Cons: validated input still needs an unchecked escape.

Decided: A.

### D8. Process output payloads

- **Option A: `ProcessResult.stdout`/`.stderr` and the `signaled`/`timeout` payloads are all `Untrusted<string>`;** `exitCode` stays `i32` (a non-text scalar, §15.1 `fromJson` rule).
  ```bayan
  let r = try Io.run(git, args: ["rev-parse", "HEAD"])
  if r.stdout == expected { … }   // comparison: clean
  ```
  Pros: the same bytes have the same type whether the child exits or is stopped. Cons: code that matches on `.timeout(_, out, err)` changes too (16 / 0 / 1 / 0 / 24).
- **Option B: only `ProcessResult` is wrapped.** Pros: smaller change. Cons: the same child output is trusted when it comes through an error payload.

Decided: A.

### D9. A new diagnostic code

- **Option A: none.** A plain `Span<u8>` given to `read(to:)`, and an `Untrusted` argument to a non-lifting function, are BYN2202, whose help names `Untrusted(…)` for the buffer.
- **Option B: a new code in 8000–8999 for "chunked read needs an `Untrusted` buffer"** (BYN8007, free: see Codes). Pros: a page of its own for the most common migration error. Cons: one more code for a case BYN2202 already describes.

Recommendation: **A**.

## Sections

As decided (owner, 2026-11-28):

- SPEC header: `Revisions applied: 0001–0027`.
- SPEC §15.1, the "Sources" bullet: the Sources table, child process output added to the source list, and `Env.get` named as trusted.
- SPEC §15.1, the "Operations" bullet: D2's lifting, fact and no-lift rules.
- SPEC §15.1, the "Filtering" bullet: D7's `try T(u)`.
- SPEC §15.1, the "Processes" bullet: D8.
- SPEC §15.1, the "Standard streams" bullet: the new types of `readAll`, `readAllBytes` and `read(to:)`. Drop "For now `readAll` returns a plain `string`, not `Untrusted<string>`."
- SPEC §15.1, the "Terminal output" bullet: D6 (an interpolated string with an `Untrusted` part is `Untrusted<string>`; terminal and log sinks escape per the D6 table) and D3 (file writes never escape).
- SPEC §15.1, the "Implemented so far" bullet: drop "Sources are not yet wrapped."
- SPEC §7.9: no change. `fromJson(Untrusted<string> body)` now takes `try Io.stdin.readAll()` directly.
- `docs/STATUS.md:30`: `Untrusted<T>` becomes `partial` until this is built, with evidence updated to `src/semantics/`. The IoInput and ProcessResult stdlib rows take the new types.
- `docs/specs/027-concurrency/027-plan.md`: "Needs decision" 2 is answered by D1 and the chunked process-output row.
- `docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md`, `docs/bayan-feature-history.md`: header bump, plus a 0027 entry in the feature history.

## Codes

Checked in `src/semantics/codes.byn` (2026-11-28): the 8000–8999 range holds only BYN8001 (`.missingBecause`, line 560) and BYN8006 (`.expectsReadsUntrusted`, line 561). `docs/diagnostics-allocated.txt` reserves BYN8002, BYN8003, BYN8004 and BYN8005 (spec-only). BYN8007 onward is free.

| Code | Change |
|---|---|
| BYN2771 | D5 A: message becomes "`main` must return `void` or `i32` and take nothing or `ReadOnlySpan<Untrusted<string>> args`". New fix-it from `ReadOnlySpan<string>`. Page updated. |
| BYN2225 | D6 A: the `Untrusted<T>` cases retire (interpolation yields `Untrusted<string>`). The `Box` case (no `formatInto`) stays. |
| BYN2202 | No change in meaning. It is the error for an `Untrusted` argument to a non-lifting function (D2) or a file effect (D3), including `read(to:)` given a plain `Span<u8>` (D1 A). Help text: for the buffer, `Untrusted(…)`; for an `Untrusted` argument to a file effect, escaped terminal output for text and `trustUnchecked` only for raw bytes (D3). |
| BYN2786 | Unchanged; under D3 B it would gain path parameters. |
| BYN8004 | Stays reserved (spec-only). D4 A leaves untrusted file paths to it. |
| BYN8006 | Meaning unchanged. It fires on more programs: an `expects` reading `args`, stdin or process output now reads an `Untrusted` value. |
| BYN8007 | Added only under D9 B; free today. |

## Sūq files

None affected. Sūq has no `main`, stdin, file or process code (`suq/storefront` uses `Untrusted` only for spec-only HTTP input, whose shapes the Sources table follows). No Sūq use is added. A CLI sketch under `suq/` would be the natural one, if the owner wants it.

## Effect on work already done

Call-site counts are in the Sources table.

- File reads change only where the path is `Untrusted`. A tool that unwraps its arguments once in `main` keeps plain file reads: one site per `main`, not per read.
- Process output: comparisons against expected text (goldens) are facts and need no change. Code that passes child output on (`bayan run` streaming, parsing `git` output) needs lifting or one `trustUnchecked` per call.
- `editors/language-server/src/transport/transport.byn:54` declares its `input` buffer `Untrusted(…)`. The JSON-RPC parse then takes `Untrusted` bytes.
- Runtime: no change. `Untrusted<T>` has `T`'s C representation (§15.1), so `byn_io_read_stdin_some` and `ProcessResult` stay as they are.
- `bootstrap/` is regenerated after the self-hosted compiler builds the change.

Golden cases a build needs (as decided; names are new unless they exist today):

| Case | Kind | Covers |
|---|---|---|
| `diag/untrusted-no-implicit` | existing, updated | loses its BYN2225 `Untrusted` lines (D6) |
| `diag/not-formattable-untrusted-part` | existing, updated | keeps only the `Box` line (D6) |
| `diag/invalid-main-signature` | existing, updated | BYN2771 new message and fix-it for `ReadOnlySpan<string>` (D5) |
| `diag/expects-reads-untrusted` | existing, updated | BYN8006 on an `expects` reading `args` |
| `diag/untrusted-read-plain-span` | new | BYN2202 for `Io.stdin.read(to:)` given `Span<u8>` (D1) |
| `diag/untrusted-user-function-arg` | new | BYN2202 for `Untrusted<string>` into a user `string` parameter (D2) |
| `diag/untrusted-effectful-write` | new | BYN2202 for `Io.writeFile` given `Untrusted<string>` or `Untrusted<List<u8>>`, and `Io.stdout.write` given `Untrusted<List<u8>>` (D3) |
| `diag/untrusted-struct-field` | new | BYN2202 for an `Untrusted` struct-literal field (D7) |
| `diag/untrusted-process-output-sink` | new | BYN2786 for `r.stdout` passed as an `Io.run` argument (D8) |
| `run/main-args` | existing, updated | new `main` type (D5) |
| `run/io-stdin`, `run/io-stdin-bytes`, `run/io-stdin-read` | existing, updated | `Untrusted` results and buffer (D1) |
| `run/io-run-signal`, `run/io-run-timeout-output` | existing, updated | `Untrusted<string>` payloads (D8) |
| `run/untrusted-clean-facts` | existing, extended | `contains`, `startsWith`, `runeCount` clean (D2) |
| `run/untrusted-lift` | new | lifted member, slice and `Utf8.decode` results (D2) |
| `run/untrusted-parse-stays` | new | `try i32.parse(u)` is `Untrusted<i32>` (D2) |
| `run/untrusted-read-file-path` | new | `Io.readText(Untrusted path)` returns `Untrusted<string>` (D4) |
| `run/untrusted-requires-construct` | new | `try Email(u)` gives a trusted `Email` (D7) |
| `run/untrusted-format-escaped` | new | interpolation with `{u}` is `Untrusted<string>`; `print`, `log` and `Io.stdout.write` escape the D6 set (ESC, U+202E) and keep `\n`, `\t` |
| `run/untrusted-process-output` | new | `ProcessResult.stdout` compared and lifted (D8) |

## Diff

The changes apply to §15.1 as listed under Sections, with the text taken from the decided options. No other SPEC section changes.
