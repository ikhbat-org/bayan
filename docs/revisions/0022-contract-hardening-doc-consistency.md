# 0022 — Contract hardening and documentation consistency

Status: accepted (user decisions D1–D6 and Q1, handed off from `tmp/dropoff-0020/drop.md` after verification against `dev` at 58950f39)

## Problem

A review of Herb Sutter's P4454R0 (the C++26 contracts failure) against the spec found six gaps: checks are described as build-mode-independent only piecemeal, contract clauses have no purity rule, `ensures` has no recorded rejection, changing a released contract has no compatibility rule, the document precedence rule is unwritten, and §6.1 says "C# precedence" while the parser binds ranges looser than arithmetic. The review also found small spec errors: the §20 `clamp` example breaks BYN5004 and BYN5006, and §10 still says modifiers precede the parameter "name".

The drop was numbered 0020. Revisions 0020 and 0021 exist, and they already cover its clause-order, lockfile and header items. This revision keeps only what is still missing.

## Decision

1. Checks never depend on the build mode (D1). Principle 9 says so for every check.
2. `expects` clauses are pure (D2). The rule is recorded now; BYN6008, the check, is a separate later task (Part C below).
3. There is no `ensures` (D3). Postconditions are `@cases` tests, `property` tests and laws.
4. Adding or narrowing an `expects` or `requires` on a released public API is a breaking change (D4).
5. SPEC changes only through numbered revisions, and the order of authority is written in `docs/revisions/README.md` (D4, D5). The source SPEC has no Appendix C; only the export snapshot does, and the snapshot files are not edited.
6. Ranges bind looser than arithmetic, as the parser does today (Q1, user decision: keep the parser, amend §6.1).
7. Clause order `where` → `expects` → `uses` → `becomes` → `fails` and the lockfile `package.lock.byn` (D6) are already recorded by revision 0020 items 24 and 26. Nothing is done here.

Edits are anchored on text and section, not line numbers. Changed SPEC rules carry `(rev 0022)`.

| # | Drop item | File, section | Change |
| --- | --- | --- | --- |
| 1 | A1 | SPEC §0 principle 9 | "**Memory safety is never a build-mode option.** Bounds checks and region checks apply in every build." → "**Checks are never a build-mode option.** Bounds, region, overflow, `if never`, `expects` and `requires` checks apply in every build. (rev 0022)" |
| 2 | A1 | SPEC §15.5, §21.3 Performance targets (Runtime paragraph) | "(§0)" follows the "every build mode" sentence in each. The sentences are otherwise unchanged |
| 3 | A2 | SPEC §7.9, `expects` bullets | Two bullets follow the "must be `bool`" bullet: the clause is pure (calls only functions whose declared or inferred effects are empty; ambient `log` and `panic` are allowed; for an effect-polymorphic call (§14) the effects of the function passed at that call site count; how often the check runs and on which side of the call is unspecified, principle 10), tagged "not in 0.2: BYN6008 is not checked yet"; and an outside-world fact is a business outcome, checked in the body with `fail .x unless …`. The same purity rule for a `requires` rule (it runs at every construction and inside decoders) is part of Part C and is not written into SPEC until that task lands |
| 4 | A3 | SPEC §19.4 Editions and stability | Appended: adding or narrowing an `expects` or `requires` on a released public function or type is a breaking change; `core` never does it, other packages only in a new major version; loosening one is not breaking |
| 5 | A4 | SPEC Appendix A | New bullet: "No `ensures`: postconditions are `@cases` tests, `property` tests and laws (§20). Re-propose only with a Sūq or selfhost case that none of them can express. (rev 0022)" |
| 6 | A5, D4, D5 | `docs/revisions/README.md` | Two bullets beside the existing "change only through a numbered revision" rule: the breaking-change rule's home is SPEC §19.4 (item 4); an unapplied revision outranks the SPEC text it changes; addenda, drafts, plans and owner decisions take effect when a revision records them; between two revisions the later wins; addenda folded before revision 0022 stay as applied. The drop put this in "Appendix C"; the source SPEC ends at Appendix B, so the README is where the rule lives. `docs/export/BAYAN-SPEC.md` Appendix C is a snapshot and is not edited |
| 7 | A7 | SPEC §20 mutation-testing example | The signature line only: `i32 clamp(i32 x, i32 lo, i32 hi)` → `i32 clamp(i32 x, from i32 lo, through i32 hi)`, matching `x.clamped(from: lo, through: hi)` in §16.2. The old line reports BYN5004 (three unlabeled parameters) and BYN5006 for `lo` and `hi` |
| 8 | A7 | SPEC §10 | "Modifiers precede the parameter name" → "Modifiers precede the parameter's type". The examples stay as revision 0021 wrote them, `ref StrBuf buffer` and `move File file`; the drop's `buf` is an abbreviation revision 0021 removed |
| 9 | Q1 | SPEC §6.1 Operators | "C# operators and precedence, plus:" now states the exception: `a..b` and `a..=b` bind looser than every arithmetic and shift operator and tighter than comparison, `is`, `in` and `??`, so `0..=n - 1` is `0..=(n - 1)` and `a + 1..b` is `(a + 1)..b` (C# reads `(0..=n) - 1`). Source: `src/Bayan.Syntax/Parsing/Parser.cs:3270-3285`, the `Prec` enum, where `Range` sits between `Relational` and `Shift` (`Coalesce` is the loosest, then `LogicalOr`, `LogicalAnd`, `BitOr`, `BitXor`, `BitAnd`, `Equality`, `Relational`, `Range`, `Shift`, `Additive`, `Multiplicative`). A range end is parsed with `ParseBinary(Prec.Shift)` (`:3349`, `:3388`); the right side of `in` with `ParseBinary(Prec.Range)` (`:3381`). Golden: `tests/cases/run/range-binds-looser-than-arithmetic.byn` (`0..=n - 1` and `0..=(n - 1)` both run four times; output from the C# compiler). SPEC §0's `0..=n - 1` paraphrase was right; §6.1 was wrong |
| 10 | B2 | `docs/STATUS.md` | New row "Build modes" (`partial`): `debug`, `safe` and `fast` are built (`src/Bayan.Backend.C/Toolchain.cs:96-99`); `small` is not built. The `ensures` row points at Appendix A |
| 11 | verify.out | `AGENTS.md:9` | Diagnostic ranges continue past 4999 with the 5xxx–8xxx areas of revision 0017 (and the 9xxx note), so a worker allocating a code in those families finds its area |
| 12 | headers | SPEC, GRAMMAR, STYLE, `docs/DIAGNOSTICS.md`, `docs/STATUS.md` | `Revisions applied: 0001–0022` (`scripts/docs/check.sh`) |
| 13 | A6/A25 | `docs/design/laws-contracts-and-parallel-iterators.md:167` | Supersedes addendum 002:167 ("`requires`/`ensures` runtime semantics now; verification marked as v1.x"): `ensures` is not adopted (revision 0019 item 19, this revision item 5). Only `requires` runtime semantics apply now; verification stays v1.x. The note at :125 already supersedes §3 for `ensures` |
| 14 | A6/D1 | `docs/design/laws-contracts-and-parallel-iterators.md:136` | Supersedes addendum 002:136 ("checked in debug and safe builds, skipped in fast builds"): contracts are checked in every build mode (item 1; revision 0002 round 2 §7) |

## Code samples

Every sample below was compiled with the C# compiler (`bayan check`, and `bayan test` for the test). Wrapped heads end the last clause line with `{` (`docs/bayan-style.md:14`); there is no own-line `{`.

Commands and exit codes (run from the repo root with `bayan` = `src/Bayan.Cli/bin/Debug/net10.0/bayan`; each file is the sample plus the stubs named below and an empty `void main() {}`, kept in the gitignored `tmp/`):

| Sample | File | Command | Exit |
| --- | --- | --- | --- |
| `transfer`, before | `tmp/s1/main.byn` | `bayan check tmp/s1/main.byn` | 0 |
| `transfer`, after | `tmp/s2/main.byn` | `bayan check tmp/s2/main.byn` | 0 |
| `wrapIndex` and its `@cases` test | `tmp/s3/main.byn` | `bayan check tmp/s3/main.byn` | 0 |
| `wrapIndex` test run | `tmp/s3/main.byn` | `bayan test tmp/s3/main.byn` | 0 (3 passed) |
| `clamp` with `@unobservable` | `tmp/s4/main.byn` | `bayan check tmp/s4/main.byn` | 0 |
| layout of the first three | `tmp/s1`, `tmp/s2`, `tmp/s3` | `bayan format --check tmp/<dir>/main.byn` | 0 each |
| range golden | `tests/cases/run/range-binds-looser-than-arithmetic.byn` | `dotnet test tests/Bayan.Tests -v q --filter "FullyQualifiedName~RunTests&DisplayName~range-binds"` | 0 (1 passed) |

The `transfer` pair from the drop, rewritten. The drop's version had an interface-typed field, which reports BYN2816, and an own-line `{`. The point is kept: a network lookup in `expects` runs on every call in every build, so it moves into the body as a business outcome.

```csharp
// Before: BYN6008 once it is checked (the clause calls a function that uses `net`)
public void transfer(ref this, Money amount, from Account payer, to Account payee)
    expects payer.id != payee.id && lookup(payer)
    uses net, suspend fails LedgerError {
    fail .unknownAccount unless this.contains(payer)
}

// After: the bug check stays a contract; the outside fact is a business outcome
public void transfer(ref this, Money amount, from Account payer, to Account payee)
    expects payer.id != payee.id
    uses net, suspend fails LedgerError {
    fail .unknownAccount unless this.contains(payer)
}
```

Both live in `struct Ledger { List<Account> accounts … }` with `struct Account { i64 id }`, `type distinct Money = i64`, `union error LedgerError` with the members `unknownAccount` and `insufficientFunds`, one per line, `bool lookup(Account account) uses net, suspend` and `bool contains(Account account)` on `Ledger` (a `for a in this.accounts` loop returning `true` when `a.id == account.id`, else `false`). "Before" compiles today (no effect check on `expects` yet), which is why Part C matters.

Postconditions without `ensures` (item 5). `ensures` and `result` are plain identifiers, so the first form is not Bayān:

```csharp
// Not Bayān
i64 wrapIndex(i64 i, from i64 lo, until i64 hi)
    expects lo < hi
    ensures result >= lo && result < hi { … }

// Bayān
i64 wrapIndex(i64 i, from i64 lo, until i64 hi)
    expects lo < hi {
    return lo + (i - lo) % (hi - lo)
}

@cases((0, 0, 5), (7, 0, 5), (3, 2, 6))
test "wrapIndex stays in range" (i64 i, i64 lo, i64 hi) {
    let r = wrapIndex(i, from: lo, until: hi)
    assert r >= lo && r < hi
}
```

## Verified findings (no change)

- **D-1.** A non-bool `expects x` reports BYN2320, "a `requires` clause must be `bool`, got `i32`". A constant argument that violates a clause, `width(5, until: 2)`, reports BYN2321, "`5` violates `requires start <= end` of `width`", with the help "pass a value that meets `requires start <= end`". SPEC §7.9 cites both for `expects`; the messages say `requires`. Rewording them changes `.diag` goldens and is Q1272 in the handoff.
- **B1** (an `expects` trap golden) is skipped: `tests/cases/run/requires.byn` and `tests/cases/run/requires-block.byn` already cover the trap ("panic: contract violated: …", exit 134).
- **Clause order and lockfile (D6).** Already recorded: revision 0020 items 24 and 26.
- **A21 and A23** in `docs/export/BAYAN-AUDIT.md` are closed by revision 0020. **A25** is closed by items 5 and 13. AUDIT A31's `.par()` and `bayan verify` items stay open.

## Sections

SPEC §0, §6.1, §7.9, §10, §15.5, §19.4, §20, §21.3, Appendix A; `docs/revisions/README.md`; `docs/STATUS.md`; `AGENTS.md`; the five header lines of item 12.

## Codes

`BYN6008` (effects family, error) is allocated as a plan code in `docs/diagnostics-allocated.txt`: `DiagnosticCodes.cs` ends the 6xxx family at BYN6007, and SPEC §7.9 names BYN6008 as not built (Part C, Q1273 in the handoff). None changed or retired.

## Part C: not in this revision

BYN6008 and the compiler work behind it are a separate later task: `EffectAnalysis.cs` does not analyze `expects` today (an `expects` that calls a `uses console` function inside a function with no `uses` compiles and runs), so the change is larger than "small and isolated" and needs scheduling. Proposed message: "`{0}` calls `{1}`, which uses `{2}`; a check runs in every build and must be pure". Proposed help: "Move the check into the body as `fail … unless …`, or into a type with `requires` if it needs no effects." The task also adds `docs/diagnostics/BYN6008.md`, a regenerated `docs/DIAGNOSTICS.md`, and goldens `diag/expects-effect`, `diag/requires-effect`, `diag/expects-polymorphic-effect` and `run/expects-pure-ok`. No `src/` file changes here.

## Sūq files

None affected. The new golden `run/range-binds-looser-than-arithmetic` is a language-level case.

## Effect on work already done

- No code changes. One golden is added; no existing golden changes.
- `docs/export/*` is a snapshot of 821afa40 and is not edited. Its "(rev 0016)" title and Appendix C wording are stale by design.

## Diff

The frozen documents below are not edited; this diff records how items 13 and 14 supersede them. Where this diff and the frozen text differ, this revision wins.

### Items 13, 14: `docs/design/laws-contracts-and-parallel-iterators.md`
```diff
--- a/docs/design/laws-contracts-and-parallel-iterators.md
+++ b/docs/design/laws-contracts-and-parallel-iterators.md
@@ :136
-- At runtime they behave like `[Check]` invariants: checked in debug and safe builds, skipped in fast builds, panicking with the clause text on violation.
+- At runtime they behave like `[Check]` invariants: checked in every build mode, panicking with the clause text on violation.
@@ :167
-- **New §14.x "Contracts"** — §3: `requires`/`ensures` runtime semantics now; verification marked as v1.x.
+- **New §14.x "Contracts"** — §3: `requires` runtime semantics now (`ensures` is not adopted); verification marked as v1.x.
```
