# 028 — Units, `Duration` and `Uptime`
Status: draft
Release: unscheduled (planned for 0.5.0)
Sources: owner decisions 2026-11-23 (spec 027 D1; this spec D1–D8); spec 023 row 9 and OQ6; spec 021 Decisions; `docs/bayan-spec.md` §2.3, §3.4, §16.5
Created: 2026-11-23

## Problem
Bayān's specification defines nominal units of measure (§3.4) and the `std.time` types `Duration` and `Uptime`
(§16.5), but none of them is implemented yet. Unit declarations do not parse, unit-suffixed literals are rejected,
and `BYN3203` and `BYN3205` do not exist.

Under the owner's 2026-11-23 decision (spec 027, D1), release 0.5.0 ships concurrency phase 1 together with units
(spec 023 row 9) and `Uptime`. Concurrency needs typed durations and monotonic deadlines without pulling in full
civil calendars, time zones, or formatting parsers:

- `scope(timeout: d)` takes a `Duration` without requiring the `clock` effect.
- `scope(until: t)` takes an `Uptime` without requiring the `clock` effect.
- `Fiber.sleep(for: d)` takes a `Duration` without requiring the `clock` effect.
- Reading `Uptime.now()` requires the `clock` effect.

Building only bare integers for deadlines would bake raw nanosecond or millisecond numbers into public concurrency
APIs, violating §3.4 and Appendix A. Building all of spec 021 (`Instant`, `Date`, `Time`, `DateTime`, `Period`,
`ZonedDateTime`, RFC 3339 and RFC 9557 formatting and parsing) would block release 0.5.0 on calendar and zone work
that concurrency does not need.

Spec 028 defines the slice needed for 0.5.0: base and scaled unit declarations, unit-suffixed literals, unit type
checking, implicit finer conversion, explicit rounding conversion, the `core` time units, `Duration`, and `Uptime`.
It also retires the name `Millis`, which the spec replaced with `Milliseconds` (§16.5) but which the language
surface still uses.

## Goals
- Deliver nominal base and scaled unit types with zero runtime representation overhead (§3.4, §21.3).
- Catch mismatched units, bare numeric literals (including `0`), and silent precision loss at compile time through
  `BYN3203`, `BYN3205`, and related diagnostics (§2.3, §3.4).
- Provide the six `core` time units (`Nanoseconds`, `Microseconds`, `Milliseconds`, `Seconds`, `Minutes`, `Hours`)
  and `type Duration = Nanoseconds` in `core`, with no import (§16.5).
- Provide `Uptime` in `std.time` with `Uptime.now()`, ordering, `Uptime - Uptime -> Duration`, and
  `Uptime ± Duration -> Uptime`, backed by each platform's suspend-including monotonic clock (§16.5).
- Keep unit, `Duration`, and `Uptime` value operations pure and non-allocating so concurrency APIs can accept
  timeouts and deadlines without requiring `clock` or `alloc` (§14, §16.5).
- Retire `Millis` in the spec and the code, with no alias; `Io.run(timeout:)` and `IoError.timeout` take a
  `Duration`.
- Satisfy spec 021 gate G1 (unit suffix lookup with `BYN3203` and `BYN3205`) without blocking 0.5.0 on the rest of
  spec 021.

## Non-goals
- `Instant`, `Date`, `Time`, `DateTime`, `Offset`, `TimeZone`, `ZonedDateTime`, `Period`, `Weekday`, calendar units
  (`Days`, `Weeks`, `Months`, `Years`), civil arithmetic, RFC 3339 and RFC 9557 formatting and parsing, ISO
  duration formatting, `DateLayout`, and `@timeSensitive`. These stay in spec 021.
- Compound unit algebra (`unit Speed = Meters / Seconds`, `UnitA * UnitB`, or exponent simplification). Per spec
  023 OQ6, compound unit declarations stay rejected with `BYN2022` until a unit-algebra revision settles them.
- Concurrency constructs themselves (`scope(timeout:)`, `scope(until:)`, `Fiber.sleep(for:)`). Those live in
  concurrency phase 1 (spec 027); spec 028 provides the types they consume.
- `provide clock` handlers (`FakeClock`, `ManualClock`) and the `UntestedClockUse` lint. Those stay in spec 023
  item #16a and spec 021.
- Float or `dec` unit storage and float duration constructors (`Duration(seconds: f64, rounding:)`), database
  column mappings, `@derive(Row)` precision checks, `UptimeSerialized` derivation checks (waiting on `@derive`), and
  `std.c` `time_t` interop. These stay in spec 021 or later revisions.
- `requires` clauses on `unit` declarations, or custom methods and operators inside a `unit` declaration body.
  Neither is defined in §3.4.
- Unit operators beyond R10: `u / n`, `%`, and `*=` stay rejected until a later revision admits them.

## User stories
- As Aisha writing a service timeout, I write `5s` or `250ms` with no import and pass it where a `Duration` is
  expected, knowing the compiler scales it to nanoseconds and rejects a bare `0` or `500`.
- As Bilal tracking an iftar countdown display, I convert a `Duration` to whole seconds with
  `remaining.floor<Seconds>()` or to a billed minute bracket with `elapsed.ceiling<Minutes>()`, and the compiler
  stops me with `BYN3205` if I drop precision implicitly.
- As Aisha measuring request latency or setting a deadline for `scope(until:)`, I read `let start = Uptime.now()`
  in a function that declares `uses clock`, compute `let deadline = start + 2s` and
  `let elapsed = Uptime.now() - start`, and pass `deadline` into pure helpers without propagating `clock`.
- As Bilal modeling parcel weights, I declare `unit Grams(g): i64` and `unit Kilograms(kg) = 1000 g`, add
  `2kg + 500g` to get `2500g`, and rely on the compiler to reject adding `Grams` to `Seconds`.

## Requirements
- **R1 Base unit declarations (§2.4, §3.4, §5.1).** A module may declare a base unit with a literal symbol as
  `unit Name(sym): StorageType` or without a symbol as `unit Name: StorageType`. `StorageType` is an integer type,
  signed or unsigned; any other storage type is a compile error (a new diagnostic). `unit` is a contextual
  declaration keyword and remains a valid identifier everywhere else. `Name` must be `PascalCase` (`BYN2008`). A
  unit type is a copyable value with the same size and runtime representation as `StorageType` and zero runtime
  overhead (§21.3).
- **R2 Derived scaled unit declarations (§3.4, §16.5; 023 OQ6).** A module may declare a scaled unit as
  `unit Name(sym) = N sym2` or `unit Name = N sym2`, where `N` is a positive integer constant greater than 1 and
  `sym2` is the literal symbol of a unit already in the family. The new unit is `N` times coarser than `sym2`'s
  unit and stores the base unit's `StorageType`. A family's finest unit is always its base unit: no derived unit is
  finer than the base. A derived unit has a literal symbol only if it declares one. The scale of a unit is the
  product of the factors from the base to it; it must fit the base `StorageType`. A factor that is not a positive
  integer constant greater than 1, a scale that does not fit, a right-hand side naming an unknown symbol, or a
  cyclic declaration is a compile error (a new diagnostic).
- **R3 Compound unit declarations rejected (§3.4; 023 OQ6).** A unit declaration combining two units with `*` or `/`
  (such as `unit Speed = Meters / Seconds`) is a compile error with `BYN2022`.
- **R4 Unit-suffixed literals (§2.3, §3.4, §16.5).** A decimal integer literal immediately followed by a unit
  symbol (such as `5s` or `250ms`) produces a value of that unit type. The symbol must match a unit visible from
  `core`, the current module, or an explicit import; an unknown symbol is a compile error (a new diagnostic). A
  unit suffix on a hexadecimal or binary literal is a compile error with `BYN0011`. A unit suffix on a
  float literal (§2.3, such as `1.5s`) is a compile error (a new diagnostic) whose help suggests a finer unit
  (`1500ms`). Built-in suffixes (`u`, `l`, `ul`, `f`, `dec`) remain reserved (§2.3). A literal value outside the
  unit's `StorageType` range is a compile error with `BYN2203`.
- **R5 Symbol collisions and suffix spelling rules (§16.5, §21.5).** Two visible units declaring the same literal
  symbol are a compile error (a new diagnostic). The `core` time-unit symbols (`ns`, `us`, `ms`, `s`, `min`, `h`)
  are always visible, so a user unit that declares one of them (such as `unit Spins(s): i64`) is the same compile
  error, reported at the declaration. The suffix `µs` (both U+00B5 and U+03BC) is accepted as an input form for
  `us` (§16.5, §21.5). A literal with suffix `m` (such as `5m`) when no visible unit has symbol `m` is a compile
  error whose help states that minutes use `min` (a new diagnostic). A literal with suffix `d` (such as `1d`) when
  no visible unit has symbol `d` reports `RetiredDoubleSuffix` (§16.5); calendar `Days` stays in spec 021.
- **R6 Bare literals rejected for unit types (§2.3, §3.4, §16.5).** A bare numeric literal (including `0`) never
  initializes, assigns to, returns as, combines with, or passes as a unit type. Doing so is a compile error with
  `BYN3203` ("`{0}` has no unit; `{1}` needs a unit literal") and a fix-it adding the unit's symbol when it has one
  (such as `0s` or `0g`), or wrapping with `Name(0)` when the unit has no symbol.
- **R7 Implicit finer conversion and rejected coarser or unrelated conversion (§3.4, §16.5, §17).** A value of a
  coarser unit converts implicitly to any finer unit in the same family by multiplying by the exact positive
  integer scale factor between them. Converting implicitly to a coarser unit in the same family is a compile error
  with `BYN3205` ("`{0}` to `{1}` loses precision") whose help suggests `.floor<U>()`, `.ceiling<U>()`, and
  `.rounded<U>()`. Converting or combining values from unrelated unit families is a compile error (`BYN2202` or
  `BYN2208`). When an implicit finer conversion overflows the storage type, a constant expression is a compile error
  (`BYN2204`) and a runtime expression traps in every build mode (§0, §17).
- **R8 Explicit coarser conversion with rounding (§3.4, §5.2, §16.2, §16.5).** Every unit value `t` supports three
  pure, non-allocating methods to convert to a coarser unit `U` in the same family: `t.floor<U>()` (rounds toward
  negative infinity), `t.ceiling<U>()` (rounds toward positive infinity), and `t.rounded<U>()` (rounds to nearest,
  ties away from zero, §16.2). The type argument names the rounding target and is always written. Passing a type
  `U` outside `t`'s unit family is a compile error (a new diagnostic).
- **R9 Explicit wrap and unwrap conversions (§3.4, §6.2).** For a unit `U` with storage type `S`, `U(raw)` wraps an
  expression of type `S` into `U`, and `S(u)` unwraps a value of type `U` into `S`. Both are pure and never
  allocate. Explicit conversions between a unit and any unrelated type, including a unit of another family, are
  rejected with `BYN2206`.
- **R10 Unit arithmetic and comparison (§3.4, §6.7, §17; 023 OQ6).** Two values in the same unit family support
  `+`, `-`, `==`, `!=`, `<`, `<=`, `>`, and `>=`; when their scales differ, the coarser operand converts implicitly
  to the finer operand's unit, and `+` and `-` return that finer unit type (`2s + 500ms` yields `Milliseconds`
  2500). Unary `-` negates a unit value whose storage type is signed; on an unsigned unit it is a compile error
  (`BYN2208`). An integer scalar that converts implicitly to the storage type (§6.2) may multiply a unit value on
  either side (`n * u`, `u * n`) and yields that unit. Dividing two values of the same family, after converting the
  coarser operand to the finer unit, yields a plain integer of the storage type (`1s / 250ms` is `4`). `+=` and `-=`
  accept a right-hand side of the same or a coarser unit; a finer right-hand side is `BYN3205`. Multiplying two
  unit values, `u / n`, `%` on units, and `*=` on units are compile errors (`BYN2208`). All unit arithmetic is pure,
  never allocates, and traps on overflow or division by zero in every build mode (§0, §17).
- **R11 Unit formatting (§3.4, §6.6).** Formatting a unit value with `string(u)` or `$"{u}"` produces its numeric
  value, one ASCII space, and its literal symbol when it has one (for example `524288 B`, `512 KiB`), or its
  numeric value alone when it has no symbol. This is also the default display of `Duration` (`1500000000 ns`); ISO
  duration formatting is an explicit formatter in spec 021.
- **R12 Built-in time units in `core` (§16.5).** The six time units are defined in `core` and available in every
  module without `import`: `unit Nanoseconds(ns): i64`, `unit Microseconds(us) = 1000 ns`,
  `unit Milliseconds(ms) = 1000 us`, `unit Seconds(s) = 1000 ms`, `unit Minutes(min) = 60 s`, and
  `unit Hours(h) = 60 min`. No time unit uses the symbol `d`.
- **R13 `Duration` type (§16.5).** `core` provides `type Duration = Nanoseconds`, available without `import`: a
  signed 64-bit copyable value (8 bytes, range ±292 years) whose conversions and operations are pure and never
  allocate. Because `Duration` is `Nanoseconds`, every coarser `core` time unit converts implicitly to `Duration`,
  and `Duration` converts explicitly to coarser time units via `.floor<U>()`, `.ceiling<U>()`, and `.rounded<U>()`.
- **R14 `Uptime` type and `Uptime.now()` (§14, §16.5).** `std.time` provides `Uptime`, an opaque copyable value
  (8 bytes, signed 64-bit nanoseconds) representing a monotonic reading that includes system suspend time.
  `Uptime.now()` returns the current `Uptime`, requires the `clock` effect (so a public caller without `uses clock`
  is rejected with `BYN6002`), and never allocates. Within a single process run, a later `Uptime.now()` reading is
  never less than an earlier reading. `Uptime` has no `Display`: `string(t)` and `$"{t}"` are compile errors (a new
  diagnostic, or the existing missing-`Display` error if one applies); it has debug output only.
- **R15 `Uptime` arithmetic, comparison, and type isolation (§14, §16.5, §17; owner decisions 2026-11-23).**
  Subtracting two `Uptime` values (`end - start`) returns a signed `Duration`. `Uptime + d` and `Uptime - d`, where
  `d` is a `Duration` or any coarser time unit (via implicit finer conversion, such as `start + 5s`), return an
  `Uptime`. `Uptime` supports `==`, `!=`, `<`, `<=`, `>`, and `>=`. All of these are pure (requiring neither `clock`
  nor `alloc`) and trap on signed 64-bit overflow in every build mode. `Uptime` does not convert implicitly to or
  from integers or `Duration`. `Duration + Uptime`, adding two `Uptime` values, and combining `Uptime` with non-time
  units are compile errors (`BYN2208`); combining `Uptime` with a bare literal (`start + 1`) is `BYN3203`.
- **R16 Platform monotonic clocks (§16.5; 021 Decisions).** `Uptime.now()` reads `CLOCK_BOOTTIME` on Linux,
  `mach_continuous_time` on macOS, and `QueryInterruptTimePrecise` on Windows, each scaled to nanoseconds
  exactly: Linux reads nanoseconds directly, Windows multiplies its 100 ns units by 100, and macOS scales ticks by
  the timebase ratio without overflowing the intermediate product. Windows does not use QueryPerformanceCounter,
  whose behavior across sleep is not documented; interrupt time includes sleep (its unbiased variants are the ones
  that exclude it). Compiling a program that calls `Uptime.now()` for a target without a suspend-including monotonic clock is a compile error (a
  new diagnostic), never a silent fallback to another clock.
- **R17 `Millis` retired (§16.5).** The name `Millis` no longer exists in the language surface, the standard
  library, the compiler, or the spec; no alias remains. `Io.run(timeout:)` takes a `Duration`, and
  `IoError.timeout` carries `Duration after`. A program that names `Millis` gets the ordinary unknown-type error.
  The spec's `Millis` sites change in the same change as the code: §3.4 (`:271` becomes
  `unit Milliseconds(ms) = 1000 us`, `:281` names `Milliseconds`), `:381`, `:484`, `:1417`, `:1989`, `:1994`,
  `:1996`, and spec 023 `:72` and `:158`. (`:273`, `:2256`, `:2285` and `:2339` landed with this spec.)

## Acceptance criteria
- **R1:** Given `unit Grams(g): i64`, `unit Cents: i64`, `unit Packets(pk): u32`, and a local `let unit = 1`, when
  compiled, then all three unit types compile as copyable values of their storage size and `let unit = 1` compiles;
  `unit grams(g): i64` fails with `BYN2008`; `unit Weight(wt): f64` fails with a new diagnostic.
- **R2:** Given `unit Grams(g): i64` and `unit Kilograms(kg) = 1000 g`, when compiled, then `Kilograms` belongs to
  the `Grams` family with scale 1000 and storage `i64`; given `unit Bad(b) = 0 g`, `unit Same(sm) = 1 g`,
  `unit Huge(hg) = 9_223_372_036_854_775_807 kg`, `unit Lost(l2) = 10 zz` with no `zz` unit, or a cycle
  `unit A(a) = 2 b` with `unit B(b) = 2 a`, then compilation fails with a new diagnostic.
- **R3:** Given `unit Speed = Meters / Seconds` or `unit Area = Meters * Meters`, when compiled, then compilation
  fails with `BYN2022`.
- **R4:** Given `let d = 250ms` in a file with no imports, when compiled, then `d` has type `Milliseconds` and value
  250; given `0xFFs`, compilation fails with `BYN0011`; given `1.5s`, compilation fails with a new diagnostic whose
  help suggests `1500ms`; given `5widgets` with no `widgets` unit in scope, compilation fails with a new diagnostic;
  given `9223372036854775808ns`, compilation fails with `BYN2203`.
- **R5:** Given two imported units both declaring symbol `pt`, when compiled, then compilation fails with a new
  diagnostic; given `unit Spins(s): i64`, compilation fails with the same diagnostic at the declaration; given
  `50µs` (U+00B5 or U+03BC), it is accepted as the input form for `50us`; given `5m` with no `m` unit in scope,
  compilation fails with a new diagnostic whose help mentions `min`; given `1d` with no `d` unit in scope,
  compilation fails with `RetiredDoubleSuffix`.
- **R6:** Given `let w: Grams = 0` or `let d: Duration = 500`, when compiled, then compilation fails with `BYN3203`
  and suggests `0g` or `500ns`; given `let c: Cents = 0`, compilation fails with `BYN3203` and suggests `Cents(0)`.
- **R7:** Given `let total: Milliseconds = 2s + 500ms`, when compiled and run, then `total` equals `2500ms`; given
  `let wait: Seconds = 500ms`, compilation fails with `BYN3205`; given `2s + 5g`, compilation fails with `BYN2208`;
  given `public Nanoseconds widen(Seconds s) => s` called at runtime with `Seconds(9_223_372_037)`, execution traps
  on arithmetic overflow; given `const big: Nanoseconds = 9_223_372_037s`, compilation fails with `BYN2204`.
- **R8:** When evaluated, `1500ms.floor<Seconds>()` is `1s`, `1500ms.ceiling<Seconds>()` is `2s`,
  `1500ms.rounded<Seconds>()` is `2s`, `(-1500ms).floor<Seconds>()` is `-2s`, `(-1500ms).ceiling<Seconds>()` is
  `-1s`, `(-1500ms).rounded<Seconds>()` is `-2s`, and `61s.ceiling<Minutes>()` is `2min`; `1500ms.floor<Grams>()`
  fails to compile with a new diagnostic.
- **R9:** Given `let s = Seconds(42)` and `let n = i64(s)`, when evaluated, then `s == 42s` and `n == 42`; given
  `Grams(s)` where `s` is `Seconds`, compilation fails with `BYN2206`.
- **R10:** Given `2s + 500ms`, `3 * 250ms`, `250ms * 3`, `-5s`, `1000ms / 250ms`, `1s / 250ms`, and `2s > 1500ms`,
  when evaluated, then they yield `2500ms`, `750ms`, `750ms`, `-5s`, `i64` 4, `i64` 4, and `true`; given
  `var t = 500ms` then `t += 1s`, `t` is `1500ms`, while `var u = 1s` then `u += 500ms` fails with `BYN3205`; given
  `2s * 3s`, `10s / 2`, `10s % 3s`, `t *= 2`, or `-Packets(1)` on a `u32` unit, compilation fails with `BYN2208`;
  given `10s / 0s`, execution traps on division by zero.
- **R11:** Given `unit Bytes(B): i64`, `unit KiB(KiB) = 1024 B`, and `unit Cents: i64`, when formatting
  `$"{Bytes(524288)}"`, `$"{Bytes(524288).rounded<KiB>()}"`, `$"{Cents(50)}"`, and `$"{1500ms}"` as a `Duration`,
  then the results are `"524288 B"`, `"512 KiB"`, `"50"`, and `"1500000000 ns"`.
- **R12:** Given a module with no imports using `1ns`, `1us`, `1ms`, `1s`, `1min`, and `1h`, when compiled and run,
  then `1h == 60min`, `1min == 60s`, `1s == 1000ms`, `1ms == 1000us`, and `1us == 1000ns` all evaluate to `true`.
- **R13:** Given a module with no imports and a pure function `public Duration pad(Seconds s) => s + 250ms`, when
  compiled and run with `pad(2s)`, then it compiles with no `uses` clause and returns `2_250_000_000ns`.
- **R14:** Given a public function calling `Uptime.now()` without `uses clock`, when compiled, then it fails with
  `BYN6002`; given a public function with `uses clock` reading `let a = Uptime.now()` followed by
  `let b = Uptime.now()`, when run, then `b - a >= 0ns`; given `$"{a}"`, compilation fails.
- **R15:** Given pure functions `public Uptime deadline(Uptime start, Seconds after) => start + after` and
  `public Duration elapsed(Uptime end, from Uptime start) => end - start`, and a test function with `uses clock`
  that reads `let start = Uptime.now()`, when run, then `elapsed(deadline(start, after: 5s), from: start) == 5s`,
  `deadline(start, after: 5s) - 5s == start`, `start < deadline(start, after: 5s)`, and `start == start` are all
  `true`; `start + start` and `5s + start` fail to compile with `BYN2208`; `start + 1` fails with `BYN3203`.
- **R16:** Given a program calling `Uptime.now()`, when built and run on Linux, macOS, and Windows, then it reads
  `CLOCK_BOOTTIME`, `mach_continuous_time`, and `QueryInterruptTimePrecise` respectively; when compiled for a target
  with no suspend-including monotonic clock (such as `wasm32`), compilation fails with a new diagnostic.
- **R17:** Given the repository after the change, a search for the word `Millis` in the compiler, standard library,
  tests, and `docs/bayan-spec.md` finds no match outside history and changelog entries; given
  `Io.run(…, timeout: 5s)`, it compiles and a process that outlives it ends with `IoError.timeout` whose `after` is
  `5_000_000_000ns`; given a program declaring `let t: Millis = 5ms`, compilation fails with the unknown-type error.

## Law candidates
- **Unit erasure:** For every program using unit types that passes `bayan check`, unit types always have the same
  size, alignment, and runtime arithmetic values as their storage types with explicit scale factors.
- **No bare literals for units:** A bare numeric literal (including `0`) never converts implicitly to a unit type.
- **Finer-then-coarser round-trip:** For every unit value `u` of a coarser unit `C` and every finer unit `F` in the
  same family where converting `u` to `F` does not overflow, implicitly converting `u` to `F` and calling
  `.floor<C>()`, `.ceiling<C>()`, or `.rounded<C>()` always equals `u`.
- **Rounding bracket:** For every unit value `x` and every coarser target unit `U` in the same family,
  `x.floor<U>() <= x.rounded<U>() <= x.ceiling<U>()` always holds, and `x.ceiling<U>() - x.floor<U>()` always
  equals `U(0)` or `U(1)`.
- **Monotonicity of `Uptime`:** For every pair of `Uptime.now()` calls `t1` followed by `t2` in the same process
  run, `t1 <= t2` always holds.
- **`Uptime` addition and subtraction inverse:** For every `Uptime` `t` and every `Duration` `d` where `t + d` does
  not overflow, `(t + d) - t` always equals `d` and `(t + d) - d` always equals `t`.
- **Effect boundary for `Uptime` and `Duration`:** Calling `Uptime.now()` always requires the `clock` effect, while
  unit, `Duration`, and `Uptime` conversions, comparisons, and arithmetic never require `clock` or `alloc`.
- **No silent clock fallback:** A compilation target without a suspend-including monotonic clock always fails to
  compile a call to `Uptime.now()` and never silently substitutes a different clock.

## Decisions (owner, 2026-11-23)
- D1 `Millis` is renamed to `Milliseconds` in the spec and the code, with no alias; `Io.run(timeout:)` and
  `IoError.timeout` take a `Duration` (R17).
- D2 Time units and `type Duration = Nanoseconds` live in `core`; `Uptime` stays in `std.time` (R12, R13, R14).
- D3 Derived units use only the `N sym` form; a family's finest unit is its base (R2).
- D4 `Duration` displays in unit form by default; ISO formatting is an explicit formatter in spec 021 (R11).
- D5 Unit storage is an integer type, signed or unsigned, inherited from the base; unary minus needs a signed
  storage type (R1, R2, R10).
- D6 `Uptime` adds ordering and `Uptime - Duration`; no `Duration + Uptime`; no `Display`, debug output only (R14,
  R15).
- D7 Unit operators also accept `u * n`, `+=` and `-=` with a same-or-coarser right-hand side, and mixed-scale
  `u / u`; `u / n`, `%`, and `*=` stay rejected (R10).
- D8 `1d` without a visible `d` unit reports `RetiredDoubleSuffix` (R5).

## Open questions
None open.

Answered in the plan (`./028-plan.md`, Decisions):
- **OQ1 (Units and `Uptime` as `Map` keys and in `const` declarations).** `docs/bayan-spec.md:298` lists integer
  types, `rune`, `bool`, `string`, plain enums, `Symbol`, tuples, and structs as `Map` keys without explicitly
  naming units. Confirm whether unit types and `Uptime` are valid `Map` keys and valid module-level `const` values
  in 028. Answered in D-OQ1: unit types (including `Duration`) are `Map` keys and scalar `const` values; `Uptime`
  is neither; `const` unit arrays stay BYN2229.
- **OQ2 (Diagnostic code allocation, existing `Time` and `Io.monotonicNanos`, and fake clock naming).** New
  diagnostics in R1, R2, R4, R5, R8, R14 and R16 need `BYN####` codes in `docs/DIAGNOSTICS.md` (next free number in
  each area), and `RetiredDoubleSuffix` needs one if it has none. Confirm that `Io.monotonicNanos()` and the
  existing `Time` stay unchanged during 028. (`docs/specs/021-std-time/021-spec.md:170,272` names the fake
  clock `FixedClock` while `docs/bayan-spec.md:2257` and
  `docs/specs/023-spec-catch-up/023-spec.md:80,166` settle `FakeClock`; that
  stays out of scope for 028.) Answered in D-OQ2a–d: BYN2237–BYN2244 and BYN4003, R14 reuses BYN2225;
  `Io.monotonicNanos()` and `Time` stay unchanged; fake clock naming stays out of scope.
