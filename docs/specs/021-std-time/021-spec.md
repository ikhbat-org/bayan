# 021 — std.time: calendar and clock types
Status: approved design (user, 2026-11-08), parked. Phase 1a (the SPEC text) landed 2026-11-10 as `docs/bayan-spec.md` §16.5; Phase 1b and Phases 2–5 are open and wait on the gates below. Owner: Sy.
Created: 2026-11-09

`std.time` gives Bayān value types, units, arithmetic, clocks, zones, formatting and parsing for points on the timeline and civil calendar dates. `docs/bayan-spec.md` §16.5 is the normative text; this spec holds the full decision record, the gates and the phases. Where the two disagree, fix the spec.

Rules for anyone working from this spec:
- Parked. Start only when Sy schedules it or all gates pass. It is not part of the revision-0021 work, round-4 §10 or spec 013 T19, and must not block or rebase in-flight work or edit files in-flight branches touch.
- No diagnostic numbers here. Allocate at merge in the ranges in the Diagnostics table; grep `docs/diagnostics/` and the descriptor files first, as round 3 did.
- Spec first: Phase 1 is doc-only. Code phases need their gates.
- Hijri is out of scope (Decisions, T13). Implement none of it.

## Gates

State re-checked on this branch (dev at 0.3.0 preparation, 2026-11-14).

| Gate | Needed by | Check | State |
| --- | --- | --- | --- |
| G1 Unit suffix lookup lands (lexer suffix-to-unit; BYN3203 and BYN3205 raised) | Phase 2 | `5s` binds as `Seconds`; a bare literal is rejected | not met: neither code exists in `src/` or `docs/diagnostics/` |
| G2 Particle checks land (5.3e) | Phase 2 | BYN5006-family active | met: BYN5006 `ParameterNeedsParticle` in `DiagnosticCodes.cs` |
| G3 `union error` binds (5.3b) | Phase 3 | `catch switch` with whole-value arms works | met on the evidence of `catch switch` and `union error` in `tests/cases/run/` (for example `self-hosting-lambdas.byn`); confirm whole-value arms (`.case name => …`) before Phase 3 |
| G4 `uses` and `provide` land | Phase 2 | `provide clock: …` compiles | met: `tests/cases/run/lambda-uses-provide.byn` |
| G5 `std` tier scaffolding exists | Phase 2 | the library-tiers rows are live modules | not met: `lib/std/` holds `json` and a README |
| G6 `kit` packaging exists | Phase 4 | a `kit.*` module can ship data files | not met: no `kit` directory |

## Audit: corrections already applied to the earlier drafts

| # | Draft | Rule it broke | Fix |
| --- | --- | --- | --- |
| 1 | `Zoned` | type names are nouns; past participles name events and states (`Order.paid`) | `ZonedDateTime` |
| 2 | `ZoneGap` as an error name | error types are named `…Error` (`DecodeError`, `Utf8Error`) | `LocalTimeError { skipped, ambiguous }`; parsing fails with `TimeParseError` |
| 3 | `tryAdded(…)` described as "fails" | `try` forms return `T?` (`tryGet`, `tryFrom`); failing uses `fails` on the plain name | `tryAdded` returns `T?`; a typed DST failure takes the civil route: `ZonedDateTime(z.dateTime + 1d, at: z.zone)` fails `LocalTimeError` |
| 4 | `.ambiguous(two) => …` in `catch switch` | A3 whole-value binding is `.case name => …` | `.ambiguous a => a.earlier` |
| 5 | `{month:2}` pattern language | revision 0003: format specs are named arguments in the hole (`{n, as: .hex}`); `{n:hex}` is an input form | drop the pattern language; format with interpolation, `{d.month, as: .digits(2)}`; parse custom layouts with a `const DateLayout(…)`; with no format letters the `YYYY` bug cannot happen |
| 6 | `t.sinceMidnight`, `Time(sinceMidnight:)` | A4: conversions are `T(x)` and `T.tryFrom(x)` | `Duration(t)`; `Time(d)` traps out of range; `Time.tryFrom(d)` gives `Time?` |
| 7 | `resolve:`, `onConflict:` | optional parameters are nouns; no `on` prefix | `resolution: .earlier | .later | .compatible`; `offsetConflict: .keepZone | .keepOffset` (absent means fail) |
| 8 | `leapSecond: .clamp` | cases read as states | `leapSecond: .clamped` |
| 9 | "parse takes `Untrusted<string>`" | §15.1: operations preserve taint | parse accepts either; `Untrusted` in gives `Untrusted<Date>` out |
| 10 | `Millis` in spec examples such as `timeout(Millis after)` | no abbreviations in names | `Milliseconds`, in a separate doc sweep (Phase 1b) |
| 11 | unit base | round 3 keeps `unit Seconds(s): i64` storage | `Nanoseconds` is the base by relation only; every unit stores its own count, so values and storage do not change |
| 12 | where time units live | spec examples use `30s` with no import | time units live in `core`, so no import is needed; calendar units need `import std.time` |
| 13 | `Time.midnight`, `TimeZone.utc` | `T.x` with camelCase `x` reads as a state type | tentative: keep `Time.midnight`, `Time.noon` and `TimeZone.utc`; Phase 1a confirms them against the round-4 dot-shorthand static-member rule, with `Time(hour: 0)` as the fallback |
| 14 | `Month` enum | C35 fixed `Date(year:month:day:)` with integers | months are `i32` 1–12 everywhere; only `Weekday` is an enum |
| 15 | `ZonedDateTime` with structural `==` but `<` by instant | breaks ordering laws | structural `==` and hash; no `<`; order through `.instant` |

Gaps the design also covers:
- **Normalized `Period` equality.** Storing months and days means `1y == 12mo` and `1w == 7d`. Noda's structural equality makes `PT1H != PT60M`.
- **Year 0 and negative years.** The proleptic calendar has year 0. Years outside 0000–9999 cannot be RFC 3339, so `.rfc3339` fails and `.iso` uses the expanded `±YYYYYY` form.
- **Parse limits.** At most 9 fraction digits and a maximum input length; rejecting is cheaper than reading unbounded hostile input.
- **Zone ID path traversal.** An `Untrusted` ID such as `../../etc/passwd` never becomes a file path. IDs resolve only through the database index.
- **Serialization.** A `TimeZone` serializes as its ID, never as the u32 handle.
- **Platform clocks.** `Uptime` is Linux `CLOCK_BOOTTIME`, macOS `mach_continuous_time`, Windows QPC. A target with no such clock is a compile error, not a silent fallback. (`AwakeTime`, the clock that excludes suspend, was dropped on 2026-11-08: `Uptime` only.)
- **Performance.** Neri–Schneider calendar algorithms for date conversion; per-zone transition binary search with a cached current period; 128-bit multiply for QPC tick scaling.
- **The `m` slip.** `5m` written without a meters import gets the help line "minutes are `min`".

## Decisions

### T1. Types

Every type is a `Copy` value. Accessors and arithmetic are pure and never allocate.

| Type | Meaning | Layout | Range |
| --- | --- | --- | --- |
| `Instant` | point on the UTC timeline | i64 s + i32 ns (16) | years −9999 to 9999 |
| `Duration` | `type Duration = Nanoseconds`, signed | i64 (8) | ±292 years |
| `Date` | civil date, proleptic Gregorian, has year 0 | i16, u8, u8 (4) | −9999 to 9999 |
| `Time` | time of day | i64 ns since midnight (8) | 00:00 to 23:59:59.999999999 |
| `DateTime` | `Date` + `Time` | 16 | |
| `Offset` | fixed UTC offset, east positive | i32 s (4) | ±25:59:59 |
| `TimeZone` | interned handle into immutable rule data | u32 (4) | |
| `ZonedDateTime` | `Instant` + zone + cached offset | 24 | |
| `Period` | calendar amount, normalized | `Months` + `Days` (8) | |
| `Uptime` | monotonic reading that includes suspend | i64 ns (8) | |
| `Weekday` | `enum`, `.monday` … `.sunday`; `isoNumber` is 1–7 | | |

### T2. Time units

Time units live in `core`; no import is needed.

```bayan
unit Nanoseconds(ns): i64
unit Microseconds(us) = 1000 ns
unit Milliseconds(ms) = 1000 us
unit Seconds(s)       = 1000 ms
unit Minutes(min)     = 60 s
unit Hours(h)         = 60 min
```

- Conversion: finer is implicit; coarser goes through `rounded<U>()`, `floor<U>()` or `ceiling<U>()`. Bare literals are rejected, including `0`.
- `µs` is an input form for `us`; accept both U+00B5 and U+03BC.
- `Millis` becomes `Milliseconds` in a doc sweep (Phase 1b).
- No time unit uses `d`.

### T3. Calendar units

These come only with `import std.time`.

```bayan
unit Days(d): i32
unit Weeks(w) = 7 d
unit Months(mo): i32
unit Years(y) = 12 mo
```

- Days and months never convert into each other or into time units.
- `Period(months:days:)` combines them. Equality is normalized, so `1y == 12mo`.

### T4. Time of day

- Construction: `Time(hour:minute:)`, with optional `second:` and `nanosecond:`. There is no `24:00`.
- Conversions: `Duration(t)`, `Time(d)` (traps), `Time.tryFrom(d)` (gives `Time?`).
- Arithmetic: `t ± time unit` wraps around midnight; `t.tryAdded(d)` gives `nil` instead of wrapping. `b - a` gives a signed `Duration`.

### T5. Arithmetic

| Left | Right | Result | Rule |
| --- | --- | --- | --- |
| `Instant` | ± time unit | `Instant` | exact |
| `Instant` | − `Instant` | `Duration` | may be negative; traps past ±292 y |
| `Instant` | ± calendar unit | error | |
| `Date` | ± calendar unit or `Period` | `Date` | clamps at month end |
| `Date` | − `Date` | `Days` | |
| `Date` | ± time unit | error | |
| `Time` | ± time unit | `Time` | wraps |
| `Time` | − `Time` | `Duration` | |
| `DateTime` | ± calendar unit | `DateTime` | clamps |
| `DateTime` | ± time unit | `DateTime` | carries into days |
| `DateTime` | − `DateTime` | `Duration` | civil, no DST |
| `ZonedDateTime` | ± time unit | `ZonedDateTime` | exact |
| `ZonedDateTime` | ± calendar unit | `ZonedDateTime` | civil step, then `.compatible` resolution |
| `ZonedDateTime` | − `ZonedDateTime` | `Duration` | |

Clamping is the rule for month steps. Jan 31 + `1mo` is Feb 28 (Feb 29 in a leap year), and Feb 29 + `1y` is Feb 28. It is not reversible, and two steps can differ from one; document both. Strict forms: `tryAdded` and `trySubtracted` give `T?`, returning `nil` instead of clamping or wrapping; a typed DST failure takes the civil route, `ZonedDateTime(z.dateTime + 1d, at: z.zone)`.

### T6. Method forms

| Form | Use |
| --- | --- |
| `a + 1d`, `a - 1d` | plain operator form |
| `a.added(1mo)`, `a.subtracted(1w)` | `-ed` copies, for chains |
| `a.tryAdded(1mo)` | gives `T?` |
| `x += 1w`, `x.add(1w)` | mutate a `var` |

A mutating verb on a `let` reuses the existing mutation diagnostic, with help "write `a + 1w`".

### T7. Differences, ranges, queries

- Differences: `Days(from:until:)`, `Months(from:until:)`, `Period(from:until:)`, `Seconds(from:until:)`. They count from the start and truncate toward zero.
- Recurrence: `start.series(by: 1mo, until: end)` yields `start + n·step`. It never chains steps, so month-end dates do not drift.
- Ranges: half-open uses `from: … until:`; inclusive uses `through:`.
- Queries: `weekday`, `dayOfYear`, `daysInMonth`, `isLeapYear`, `startOfMonth`, `endOfMonth`, `startOfIsoWeek`.
- Next and previous weekday: `next(…)` and `previous(…)` are strictly after or before; `inclusive: true` makes today count. This reuses the named-`bool` form instead of a second `nextOrSame` method. ``following` and `preceding` were considered and are adjectives too, so they fix nothing. `next` and `previous` are adjectives, but BYN5001 does not flag them (neither ends in `-ed`), and iteration uses `moveNext`/`current`, so `next` is free.

  ```bayan
  let friday = today.next(.friday)                    // never today
  let due    = today.next(.friday, inclusive: true)   // today if it's Friday
  let last   = today.previous(.monday)
  ```

- Start of day: `d.startOfDay(at: zone)` gives a `ZonedDateTime` and fails `LocalTimeError.skipped`.

### T8. Clocks

- Readings use the `clock` effect: `Instant.now()`, `Uptime.now()`, `ZonedDateTime.now(at:)`, `Date.today(at:)`.
- No ambient zone. `Date.now()` is an error with help.
- Elapsed time is `Uptime.now() - start`, a `Duration`. `Uptime` does not mix with `Instant`, and deriving a serializer for it is an error.
- Platform clocks are as in the audit. A target with no such clock is a compile error.
- Fakes: `provide clock: FixedClock(at: t) { }` and `ManualClock` with `advance(by:)` (SPEC §16.5 names the fake `FakeClock`; settle the name in Phase 1a follow-up).
- Smearing: `Instant.now()` may be smeared or stepped; the docs say so.
- Sleep (coordinate with `std.fiber`): `sleep(for:)` uses `Uptime`; `sleep(until: Instant)` is a wall-clock deadline that re-checks after clock steps.

### T9. Zones

```bayan
union error LocalTimeError {
    skipped(ZonedDateTime before, ZonedDateTime after)
    ambiguous(ZonedDateTime earlier, ZonedDateTime later)
}

let meeting = ZonedDateTime(local, at: kl) catch switch {
    .skipped s => s.after
    .ambiguous a => a.earlier
}
```

- Construction: `ZonedDateTime(local, at: zone)` fails `LocalTimeError`. Passing `resolution:` makes it infallible.
- Comparison: `==` and hashing are structural (instant plus the zone's identity). There is no `<`; order through `.instant`.
- No DST flag. Expose `offset` and `standardOffset`; their difference may be negative.
- `std.time` has `TimeZone.utc` and fixed offsets only.
- `TimeZone.parse(id)` fails and `TimeZone.tryParse(id)` gives `TimeZone?`. Both reject `Etc/GMT±n`, POSIX TZ strings and abbreviations, with help pointing to `+08:00` or an IANA ID.
- IDs are kept as written, compared by normalized ID, resolved only through the database index (never as file paths), and serialized as text.

### T10. Format and parse

- `Display` and `.iso` follow RFC 3339 and 9557. `.rfc3339` is strict and fails for years outside 0000–9999; `.iso` uses the expanded `±YYYYYY` form for those.
- Durations use ISO with exact units only (`PT1H30M`, `-PT5S`); a `Period` uses `P1Y2M3D`.
- Custom output uses interpolation specs, `$"{d.year}-{d.month, as: .digits(2)}"`, written into the caller's buffer.
- Custom input: layouts are a `const DateLayout(.day(digits: 2), "/", .month(digits: 2), "/", .year)`, checked at compile time. `Date.tryParse(text, as: layout)` reads them. A two-digit year needs `pivot:`.
- Parsing: `T.parse` fails `TimeParseError`; `T.tryParse` gives `T?` (confirm that `parse … fails` pairs with `tryParse` in SPEC A4). Parsing is strict, with at most 9 fraction digits and a maximum length. Taint is preserved.
- Instants need an offset: `Instant.parse("2026-01-01")` fails.
- `:60` fails by default; `leapSecond: .clamped` accepts it.
- A stored offset that disagrees with the zone's current rules fails `.offsetMismatch` unless `offsetConflict:` picks a side.
- Weeks: ISO only in `std`; locale weeks in `kit.intl` with `for:`. Localized output is display-only and cannot be parsed back.

### T11. Interop

- Epochs are named: `Instant(unixSeconds:)`, `Instant(unixMilliseconds:)`; no bare epoch numbers.
- No float constructors except `Duration(seconds: f64, rounding:)`.
- Codecs and `@derive(Row)` declare their precision. A silent truncation is a compile error; truncation must be written as `rounded<…>()`.
- Database mapping:

| Bayān | Postgres |
| --- | --- |
| `Instant` | `timestamptz` |
| `DateTime` | `timestamp` |
| `ZonedDateTime` | `timestamptz` + zone ID column, or RFC 9557 text |
| `Date` | `date` |
| `Time` | `time` (never `timetz`) |
| `Duration` | `bigint` ns |
| `Period` | months and days columns |

- `std.c` maps `time_t` with a width check.

### T12. Testing

- `@timeSensitive` reruns the test under `provide clock` across a fixed corpus: ISO week-year flips (Dec 28 – Jan 4); Feb 28 and 29 in leap and non-leap years; Dec 31 of a leap year; DST gap and overlap in several zones; Samoa's skipped 2011-12-30; Brazil's missing midnight; a backwards clock step.
- Lint: a test that reads the real `clock` without `@timeSensitive` or a `provide`.

### T13. Hijri: parked

Out of scope. Agreed direction: it lives in `kit.calendar` and requires an authority (`by:`). Open questions: the authority list and IDs, the confirmed-data source and format, prediction tables, the day boundary, how stored data notices a moved prediction, and arithmetic over predicted months.

### T14. Placement

| Module | Contents |
| --- | --- |
| `std.time` | T1–T12 except IANA data |
| `kit.tz` | IANA data, system or bundled, behind the same API; runtime reload into new immutable tables (old handles stay valid); Windows ID mapping; system-zone lookup (`uses env, fs`); `TimeZone.database.version` |
| `kit.intl` | localized names, culture formats, locale weeks |
| `kit.calendar` | non-ISO calendars, converting through `Date` (a library-tiers row) |

The earlier open questions were all answered on 2026-11-08.

## Diagnostics

Names only; numbers are allocated at merge.

| Name | Range | Fires on |
| --- | --- | --- |
| `CalendarUnitOnInstant` | types/units | `instant + 1d` |
| `TimeUnitOnDate` | types/units | `date + 3h` |
| `TimeIsNotDuration` | types | `Time` used where a `Duration` is expected, or the reverse |
| `MinutesNotMeters` | spelling (19xx) | `5m` with no meters unit imported |
| `RetiredDoubleSuffix` | spelling (19xx) | C# `1d` meant as a double |
| `DuplicateUnitSymbol` | imports | two imported units with one symbol |
| `AbbreviatedUnitName` | naming (51xx) | `Millis` |
| `DateHasNoNow` | spelling | `Date.now()` |
| `ReassembledDate` | patterns (50xx) | `Date(year: d.year + 1, …)` |
| `WallClockMeasurement` | patterns (50xx) | timing with `Instant.now()` |
| `UptimeSerialized` | derivation | serializing `Uptime` |
| `ImplicitTruncation` | derivation | precision lost in a codec or row |
| `LegacyZoneName` | patterns | `Etc/GMT±n` or POSIX TZ in a literal |
| `InvalidDateLayout` | types | a bad `const DateLayout` |
| `UntestedClockUse` | tests | a test reading the real clock |

## Phases

- [x] **1a Spec** (no gate). New SPEC section for `std.time` from the Decisions section; library-tiers rows for `std.time`, `kit.tz`, `kit.calendar`; GRAMMAR examples. Done 2026-11-10 (`docs/bayan-spec.md` §16.5, `docs/bayan-library-tiers.md`; review fixes 2026-11-11; Questions 1159–1161 and 1240–1243 in `docs/decisions/2026-11-14-004-answered-questions.md`, Q1159 resolved).
  - [ ] Confirm `Time.midnight`, `Time.noon` and `TimeZone.utc` against the round-4 static-member rule (audit row 13); fall back to `Time(hour: 0)`.
  - [ ] Settle the fake clock's name (`FakeClock` in SPEC §16.5 against `FixedClock` and `ManualClock` in T8).
- [ ] **1b Rename sweep** (no gate). `Millis` becomes `Milliseconds` across docs, with the spec diff only. Done when `grep -rn Millis docs` is empty. Open on this branch: `docs/bayan-spec.md` lines 264, 274, 374, 477 and 1254 still say `Millis`.
- [ ] **2 v0.1 core** (G1, G2, G4, G5). Time units, `Instant`, `Duration`, `Uptime`, `clock` fakes, ISO format and parse for `Instant` (needed by spec 014). Done when 014 timestamps use it and the T12 corpus runs on these types.
- [ ] **3 Civil** (G3). `Date`, `Time`, `DateTime`, `Offset`, `Period`, T3 units, T5–T7, `DateLayout`, diagnostics. Done when the T5 table is fully covered by tests.
- [ ] **4 Zones** (G6). `kit.tz`, `TimeZone`, `ZonedDateTime`, T9, the offset-conflict policy. Done when the DST corpus passes in five or more zones.
- [ ] **5 Interop** (`std.db` codecs exist). T11 mappings, `@derive(Row)` precision checks. Done when round trips are lossless or rejected at compile time.
