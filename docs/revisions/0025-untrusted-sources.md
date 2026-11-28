# 0025 — `Untrusted<T>` on every outside-data source

Status: draft (proposed 2026-11-28; awaiting owner; three questions at the end)
Release: unscheduled
Sources: SPEC §15.1, §7.9; owner answer on `Untrusted` chunk reads, 2026-11-27 (`docs/specs/027-concurrency/027-plan.md` "Needs decision" 2); owner decision 2026-11-28 (`docs/audits/2026-11-28-decisions-0.4.md` §2.2 and §6 item 2: option (c) dropped, `i64 Io.stdin.read(to:)` stays, process output has the same shape, `Untrusted` on chunked reads waits for one revision covering every §15.1 source)

## Problem

1. SPEC §15.1 says sources "return `Untrusted<T>` in their signatures", then says "Sources are not yet wrapped" and "For now `readAll` returns a plain `string`". No built source returns `Untrusted<T>`:

   | Source (§15.1 class) | Built signature today | Where |
   |---|---|---|
   | stdin | `Result<string, IoError> Io.stdin.readAll()` | `src/semantics/builtins.byn:1397` |
   | stdin | `List<u8> Io.stdin.readAllBytes() fails IoError` | `builtins.byn:353` |
   | stdin | `i64 Io.stdin.read(to: Span<u8> buffer) fails IoError` | `builtins.byn:364` |
   | command-line arguments | `main(ReadOnlySpan<string> args)` | `src/semantics/compile.byn:990` (BYN2771) |
   | files from user-chosen paths | `List<u8> Io.readFile(string path)`, `string Io.readText(string path)`, `List<string> Io.listDir(string path)`, `string Fs.realPath(string path)`, all `fails IoError` | `builtins.byn:214`, `:223`, `:268`, `:579` |
   | child process output (owner, 2026-11-27) | `ProcessResult.stdout`, `.stderr`: `string`; `IoError.signaled(i32, string stdout, string stderr)`, `.timeout(Millis, string stdout, string stderr)` | `builtins.byn:1009-1013`, `:60` |
   | text from C | none: `extern` is not in 0.4 (§18) | |
   | request query, body, headers, cookies, route parameters, uploads, third-party API responses | none: `std.http` is not built | |

2. The `Untrusted` operations §15.1 describes are mostly not built either. Built: `Untrusted(x)`, `x.trustUnchecked() because "…"`, the facts `length` and `isEmpty` (`src/semantics/express2.byn:1279`), comparisons as facts (`express3.byn:410`), and the BYN2786 process-argument sink (`express.byn:249`). Not built: "operations on an `Untrusted` value return `Untrusted`", taint removal by constructing a type with `requires`, and escaped formatting ("Terminal output and logs escape control characters"; today `{u}` is BYN2225, `tests/cases/diag/untrusted-no-implicit.diag`). Wrapping the sources without these would force a `trustUnchecked` at almost every use.
3. The audit's option (c) (`read(to:)` returning `Untrusted<ReadOnlySpan<u8>>`) is dropped. The `i64` count stays, so the mark has to go somewhere other than the return value.
4. `docs/STATUS.md:30` marks `Untrusted<T>` `built`, though §15.1 says sources are not wrapped.

## Decision

All of the following lands in one step: one compiler change, with every caller in the repository updated in the same commit.

### 1. Source signatures

| Source | New signature |
|---|---|
| `Io.stdin.readAll()` | `Result<Untrusted<string>, IoError>` |
| `Io.stdin.readAllBytes()` | `Untrusted<List<u8>> … fails IoError` |
| `Io.stdin.read(to:)` | `i64 Io.stdin.read(to: Untrusted<Span<u8>> buffer) fails IoError`. The name, particle, `i64` return and behaviour stay the same. Only the buffer's type changes, so the bytes the call writes carry the mark. The count is a fact (at most the buffer's length, which the caller chose), so it is clean. |
| `main` | `main(ReadOnlySpan<Untrusted<string>> args)`. `main(ReadOnlySpan<string> args)` becomes BYN2771, with a fix-it to the new type. |
| `Io.readFile`, `Io.readText`, `Io.listDir`, `Fs.realPath` | Each gets an overload taking `Untrusted<string> path` that returns `Untrusted<…>` of the same result (`Untrusted<List<u8>>`, `Untrusted<string>`, `Untrusted<List<string>>`, `Untrusted<string>`). A `string` path keeps the plain result, since a fixed path is config (§15.1). |
| `Fs.fileExists`, `Fs.fileSize`, `Fs.modified` | Unchanged; they accept an `Untrusted<string>` path. Their results (`bool`, `i64`, `Time`) are facts and stay clean. |
| `Io.run`, `Io.runBatch` result | `ProcessResult.stdout` and `.stderr` become `Untrusted<string>`. `exitCode` stays `i32`, since it is a non-text scalar (§15.1 `fromJson` rule). |
| `IoError` payloads | `signaled(i32 signal, Untrusted<string> stdout, Untrusted<string> stderr)` and `timeout(Millis after, Untrusted<string> stdout, Untrusted<string> stderr)`. |
| Process chunk reads (spec 027, not built) | Same shape as stdin: `i64 read(to: Untrusted<Span<u8>> buffer)` on `ChildReader`. This replaces 027 Decision 3's allocating `Untrusted<List<u8>>? read(max:)`. `readLine(max:)` keeps 027's `Untrusted<string>?`. |
| `Env.get` | Unchanged (`string?`): startup environment is trusted (§15.1). |
| Text from C, `std.http` sources | Unchanged text: §15.1 already gives them `Untrusted<T>`, and they take it when §18 and `std.http` are built. |

A chunked reader declares its buffer untrusted once:

```bayan
var input = Untrusted(List<u8>(capacity: 65536))
let n = try Io.stdin.read(to: input.mutableSpan())   // n: i64, clean
let text = try Utf8.decode(input[0..n])              // Untrusted<string>
```

### 2. Operations lift (builds the existing §15.1 bullet)

- A builtin member, operator, index, slice, `for` element or pure builtin function (string, span, list, `Utf8`, `Hex`, `Path`, `T.parse`) applied to an `Untrusted<T>` binds as it does on `T`, and its result is wrapped in `Untrusted`. An untrusted argument to a builtin taints the result the same way.
- Facts are clean: `bool` results (comparisons, `isEmpty`, `contains`, `startsWith`, `is` patterns), plus `length` and `runeCount`. Parsed numbers are not facts: `try i32.parse(u)` is `Untrusted<i32>`, because a number from input is a size or loop-bound sink (§15.1 table).
- No lifting into effectful builtins: `writeFile`, `remove`, `createDirectory`, `removeDirectory`, `Fs.rename`, `Fs.copy`, `Fs.setModified` and `Io.stdout`/`Io.stderr` `write` given an `Untrusted` argument are BYN2202, as now. `Io.run`/`Io.runBatch` arguments stay BYN2786.
- User-written and `lib/std` functions do not lift. A `T` parameter still rejects `Untrusted<T>` (BYN2202), so a function that takes outside data says so in its signature.

### 3. Removing the mark

- `try T(u)`, where `T` is a distinct type with `requires` and `u` is `Untrusted<V>` for `T`'s underlying `V`, returns a trusted `T` (§15.1 "only construction of a type with `requires` removes it").
- Struct literals keep BYN2202 for an `Untrusted` field value. `T.fromJson` keeps §15.1's field rule.
- `x.trustUnchecked() because "…"` is unchanged and stays the only other way out. `bayan audit` already lists each use.

### 4. Formatting

`{u}`, where `u` is `Untrusted<T>` and `T` is formattable, formats `T` with control characters escaped, as `log` does (§14). This builds the existing bullet "Terminal output and logs escape control characters in untrusted values." BYN2225 no longer fires for `Untrusted<T>`, or for optionals and collections of it. `{u, as: .debug}` is unchanged.

### Freeze

This revision changes builtin signatures and binding rules only. It adds no keyword, operator, clause or grammar form, so revision 0023's syntax freeze allows it.

## Sections

- SPEC header: `Revisions applied: 0001–0025`.
- SPEC §15.1, the "Sources" bullet: the signature table from Decision 1, child process output added to the source list, and `Env.get` named as trusted.
- SPEC §15.1, the "Operations" bullet: Decision 2's lifting, fact and no-lift rules.
- SPEC §15.1, the "Filtering" bullet: Decision 3's `try T(u)`.
- SPEC §15.1, the "Processes" bullet: `ProcessResult.stdout`/`.stderr` and the `signaled`/`timeout` payloads are `Untrusted<string>`.
- SPEC §15.1, the "Standard streams" bullet: the new types of `readAll`, `readAllBytes` and `read(to:)`. Drop "For now `readAll` returns a plain `string`, not `Untrusted<string>`."
- SPEC §15.1, the "Terminal output" bullet: Decision 4.
- SPEC §15.1, the "Implemented so far" bullet: drop "Sources are not yet wrapped."
- SPEC §7.9: no change. `fromJson(Untrusted<string> body)` now takes `try Io.stdin.readAll()` directly.
- `docs/STATUS.md:30`: `Untrusted<T>` becomes `partial` until this is built, with evidence updated to `src/semantics/`. The IoInput and ProcessResult stdlib rows take the new types.
- `docs/specs/027-concurrency/027-plan.md`: "Needs decision" 2 is answered by Decision 1's process chunk-read row.
- `docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md`, `docs/bayan-feature-history.md`: header bump, plus a 0025 entry in the feature history.

## Codes

| Code | Change |
|---|---|
| BYN2771 | Message becomes "`main` must return `void` or `i32` and take nothing or `ReadOnlySpan<Untrusted<string>> args`". New fix-it from `ReadOnlySpan<string>`. Page updated. |
| BYN2225 | The `Untrusted<T>` cases retire (Decision 4). The `Box` case (no `formatInto`) stays. |
| BYN2202 | No change in meaning. It is the error for an `Untrusted` argument to a non-lifting function, including `read(to:)` given a plain `Span<u8>`. Its help names `Untrusted(…)` for the buffer. |
| BYN2786, BYN8004, BYN8006 | Unchanged. |

None added.

## Sūq files

None affected. Sūq has no `main`, stdin, file or process code (`suq/storefront` uses `Untrusted` only for spec-only HTTP input). No Sūq use is added. A CLI sketch under `suq/` would be the natural one, if the owner wants it.

## Effect on work already done

`.byn` call sites to update (grep counts, 2026-11-28):

| Site | `src/` | `tools/` | `editors/` | `lib/` | `tests/cases/` |
|---|---|---|---|---|---|
| `main(ReadOnlySpan<string> args)` | 9 | 16 | 0 | 0 | 24 |
| `Io.run(` (uses of `.stdout`/`.stderr`) | 76 | 21 | 9 | 6 | 54 |
| `Io.stdin.readAll(` / `readAllBytes(` / `read(to:` | 2 / 6 / 3 | 0 | 0 / 0 / 1 | 0 | 5 / 6 / 2 |
| `Io.readText(` / `readFile(` / `listDir(` / `Fs.realPath(` | 192 / 65 / 77 / 8 | 26 / 8 / 8 / 7 | 0 / 2 / 4 / 5 | 1 / 0 / 2 / 3 | 13 / 12 / 5 / 4 |

- File reads change only where the path is `Untrusted`. A tool that unwraps its arguments once in `main` (`args[i].trustUnchecked() because "the user names files on their own command line"`) keeps plain file reads. That is one site per `main`, not per read.
- Process output: comparisons against expected text (goldens) are facts and need no change. Code that passes child output on (`bayan run` streaming, parsing `git` output) needs lifting or one `trustUnchecked` per call.
- `editors/language-server/src/transport/transport.byn:54` declares its `input` buffer `Untrusted(…)`. The JSON-RPC parse then takes `Untrusted` bytes.
- Goldens: `diag/untrusted-no-implicit.diag` and `diag/not-formattable-untrusted-part.diag` lose their BYN2225 `Untrusted` lines. `run/main-args.byn` moves to the new `main` type. New goldens: each Decision 1 row, a lifted member, a fact, a parsed number staying `Untrusted`, `try Email(u)`, a non-lifting write (BYN2202) and escaped `{u}` output.
- Runtime: no change. `Untrusted<T>` has `T`'s C representation (§15.1), so `byn_io_read_stdin_some` and `ProcessResult` stay as they are.
- `bootstrap/` is regenerated after the self-hosted compiler builds the change.

## Diff

The changes apply to §15.1 as listed under Sections, with the text taken from Decisions 1–4. No other SPEC section changes.

## Questions for the owner

1. Decision 1 keeps `i64 read(to:)` but changes the buffer to `Untrusted<Span<u8>>`. The other option keeps `Span<u8>`, with the bytes untrusted by documentation only (027 option (a)). That leaves one §15.1 source untyped.
2. Decision 2 has no lifting into effectful builtins, so writing downloaded bytes to a file needs a `trustUnchecked`. The alternative lifts the data arguments and keeps path arguments as sinks, which means a new BYN2786 sink list.
3. A file read with an `Untrusted` path is allowed and returns `Untrusted`. Path traversal checks stay with BYN8004 (`PathSegment`, spec-only). The alternative makes the path parameter a BYN2786 sink now.
