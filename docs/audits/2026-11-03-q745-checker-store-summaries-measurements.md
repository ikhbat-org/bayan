# Q745 checker store summaries: measurements
Status: measured 2026-11-03; Q745 is landed on dev (spec 010 T41, `fix/q745`). Numbers are from the two measuring rounds before the merge and are kept as the evidence behind Q745 in `docs/decisions/2026-11-14-004-answered-questions.md`. Nothing is left to do here except the open item in section 8.

Q745 makes the C# checker keep per-callee store summaries (A) with a type filter inside (B), return summaries, loop-item lending and a loan-only `StrBuf.finish()`. Round 1 is the first C# rule (`chore/worker-q745-csharp` 6e45c9f6). Round 2 (store and return summaries, `finish()` loan only, option (a): `append` is not a mutation) is the rule that shipped. Revision 0018 (`docs/revisions/0018-strbuf-finish-loan.md`) records the `finish()` change.

## 1. Round 1: effect on goldens and the selfhost sources

- Existing `run/` goldens that changed: 0 (RunTests and OwnershipCheckerTests over `run/` pass unchanged; only the 18 new ref-out cases needed `BAYAN_UPDATE`).
- `tests/cases/emit/run-c.sha256` gained 2 lines, one per new `run/` case (`MutantSchemataTests.PlainBuildEmitsTheSameC` hashes every `run/` case); no existing line changed.
- `selfhost/` sites still rejected: 37, all BYN3002, built as `SelfhostSemanticsTests.Builds` builds them. Groups: G (genuine store) 3, F (rule 4 via `format`) 9, C (cascade) 25. The prototype f6c98241 refused about 90.
  - G: function-local `StrBuf` text (`x.finish()`) passed to `reportFix`, whose summary stores it into the receiver or `c` (it goes on into `diagnostics.fixReplacement`).
  - F: `report(message: format(..., by: args))` stores into `this` or `c`; the result of `format` borrows every argument, and an argument is block-local text (`utf8(...)` of a span of the source bytes, or `sb`/`sig`/`joined.finish()`), although `format` copies.
  - C: flow-insensitive; after one F or G store, `c`, `b`, `p` and locals read from them borrow the block-local text for the whole function, so later stores through them are flagged too.

| site | message | why |
|---|---|---|
| lexer/lexer.byn:584:13 | the temporary on line 582 does not live as long as `this`, which borrows it | F |
| lexer/lexer.byn:601:13 | the temporary on line 582 does not live as long as `this`, which borrows it | F |
| lexer/lexer.byn:627:9 | `fix` does not live as long as `this`, which borrows it | G |
| lexer/lexer.byn:683:17 | the temporary on line 680 does not live as long as `this`, which borrows it | F |
| lexer/lexer.byn:848:21 | the temporary on line 848 does not live as long as `this`, which borrows it | F |
| lexer/lexer.byn:854:21 | the temporary on line 854 does not live as long as `this`, which borrows it | F |
| lexer/lexer.byn:865:9 | the temporary on line 865 does not live as long as `this`, which borrows it | F |
| parser/decls.byn:605:21 | `block` does not live as long as `p`, which borrows it | G |
| parser/decls.byn:608:21 | `block` does not live as long as `p`, which borrows it | C |
| parser/decls.byn:913:17 | `sb` does not live as long as `p`, which borrows it | G |
| semantics/declare2.byn:578:54 | `sb` does not live as long as `path`, which borrows it | C |
| semantics/declare2.byn:589:9 | `sb` does not live as long as `c`, which borrows it | F |
| semantics/express.byn:200:16 | `sig` does not live as long as `text`, which borrows it | C |
| semantics/express.byn:265:13 | `sig` does not live as long as `c`, which borrows it | F |
| semantics/express.byn:289:9 | `sig` does not live as long as `pNames`, which borrows it | C |
| semantics/express.byn:294:27 | `sig` does not live as long as `pNames`, which borrows it | C |
| semantics/express.byn:303:17 | `sig` does not live as long as `pNames`, which borrows it | C |
| semantics/express.byn:306:35 | `sig` does not live as long as `pNames`, which borrows it | C |
| semantics/express.byn:321:22 | `sig` does not live as long as `names`, which borrows it | C |
| semantics/express.byn:346:5 | `sig` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:590:20 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:599:9 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:603:18 | `joined` does not live as long as `stName`, which borrows it | C |
| semantics/express3.byn:612:9 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:626:13 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:628:44 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:653:21 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:655:40 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:664:13 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:666:21 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:676:13 | `joined` does not live as long as `c`, which borrows it | C |
| semantics/express3.byn:679:25 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:686:28 | `joined` does not live as long as `missing`, which borrows it | C |
| semantics/express3.byn:697:24 | `joined` does not live as long as `missing`, which borrows it | C |
| semantics/express3.byn:714:9 | `joined` does not live as long as `c`, which borrows it | F |
| semantics/express3.byn:721:16 | `joined` does not live as long as `b`, which borrows it | C |
| semantics/express3.byn:726:12 | `joined` does not live as long as `b`, which borrows it | C |

- Other C# test fallout in round 1 (not selfhost):
  - `CliTests.TallyLiteChecksWithoutWarnings`, `TallyLitePrintsTheSettlement` and `TallyLiteTestsPass`: `examples/tally-lite/ledger/ledger.byn:38` `credit(share, to: ref totals)` is refused (`e` does not live as long as `totals`), with a note at :47 "`credit` stores `share` into `totals` here". The cause predates Q745: `e.participants` (a List field of the loop copy `e`) passed as a span is lent with region `e`, and rule 4 carries it into `share`. The dev checker refuses the same store written inline (`totals.append(n)` in the loop); Q745 only exposes it through `credit`. Not fixed in round 1 (`examples/` unchanged).
  - `LexerSnapshotRecordingTests.BuildAndRunsAreRecordedUnderASnapshotDirectory` and `SelfhostSnapshotTests.*` build `selfhost/lexer` and were refused at the lexer sites above.
- Expected red in round 1: `SelfhostSemanticsTests.Builds` and every test that builds `selfhost/` (`Selfhost*Tests`, `LexerSnapshotRecordingTests`, `SelfhostSnapshotTests`).
- 010 generator seeds (79 programs, `tmp/semantics-corpus/generator/seeds`): accepted before (dev) 39, after 39, newly rejected none (identical lists).
- Checker speed, 1 MiB generated program (`tmp/semantics-corpus/generator/big.byn`):
  - In-process `CliCheck` (`OneMegabyteWithinTenTimes`), dev: 257 ms median of 5. After: not measurable, because the test needs the selfhost build, which was refused.
  - Process wall time `dotnet bayan.dll check`, median of 5, two interleaved rounds: before 868 and 837 ms, after 843 and 841 ms (no measurable change; startup dominates).
  - Selfhost `bayan-check` baseline on dev, once: 915 ms on the same program (ratio 3.56 to the in-process C# check).

## 2. Round 2: method

Builds compared: dev (`tmp/before-cli`, `tmp/before-tests`, the worktree base); branch (`tmp/after4-cli` and the current test build, option (a)); option (b) (`tmp/after3-cli`, the branch plus `append`/`appendRepeated` as Mutate). Refusals were listed in-process by `tmp/bench`, a console tool that references each build's `Bayan.Semantics.dll` and calls `Compilation.Create`:
- `run/` cases: one file each, with `run/` as package root (as RunTests does);
- selfhost: `selfhost/semantics/*.byn` with package root `selfhost/` (as `SelfhostSemanticsTests.Builds` does);
- examples: `examples/tally-lite/main.byn` and `examples/hello/main.byn`, each with its own directory as root;
- seeds: each `tmp/seeds-snapshot/*/main.byn`, with its directory as root.

## 3. Round 2: sites the C# checker still refuses (option (a))

- `run/`: 0 region refusals and 0 existing goldens changed. The tool lists 4 BYN2014 "the program has no entry point" (`assert-fails.test.byn`, `suq-money.test.byn`, `test-cases.test.byn`, `test-output.test.byn`); it compiles `.test.byn` files without test mode, so this is its own artifact, and dev lists the same 4.
- `selfhost/`: 0 sites. `selfhost/semantics` builds and `SelfhostSemanticsTests.Builds` passes. All 37 round-1 sites are gone.
- `examples/hello`: no refusals. `examples/tally-lite`:

| site | message | cause |
|---|---|---|
| examples/tally-lite/ledger/ledger.byn:38:13 | BYN3002 `e` does not live as long as `totals`, which borrows it | the chain below |
| examples/tally-lite/ledger/ledger.byn:41:12 | BYN3003 cannot return a borrow of `e`, which is freed when `balances` returns | cascade of :38: after the store, `totals` borrows `e`, and `totals` is returned |

  The chain behind :38: (1) the call is `splitEvenly(e.amount, to: e.participants)`, and `e.participants` is a List field of the loop copy `e`, passed as a span; (2) lend gives that span region `e`, the loop variable's scope, although the list's storage is the caller's `expenses`; (3) `splitEvenly`'s return summary names that parameter, because it returns names taken from it, so `share` borrows `e`; (4) `credit`'s store summary stores `share` into `totals`. The region on a loop copy's list field predates the branch: dev refuses the same store written inline, and refuses neither ledger site only because it has no store summary for `credit`.
- Generator seeds (79, `tmp/seeds-snapshot`): 39 accepted, the same list as dev. The 40 rejected seeds each have one non-region error, the same as dev: BYN2001 x8, BYN2102 x8, BYN2202 x8 (expected `i64`, found `string`), BYN2602 x8 (`parseDigit` can fail), BYN2781 x8 (`ownedN` is used after it was moved). No seed has a BYN30xx refusal.

## 4. Round 2: compile-fail goldens that depend on the call-result borrow (R3)

Making every call result `Borrow.None` (a temporary edit, reverted) changed 6 `DiagTests` goldens. On the branch each still fails with its golden code and its `DiagGolden` test passes:

| golden | code |
|---|---|
| diag/borrow-escapes-region | BYN3002 |
| diag/borrow-stored-through-span | BYN3002 |
| diag/borrow-then-mutated-in-initializer | BYN3004 |
| diag/lambda-capture-borrow-through-call | BYN3004 |
| diag/ref-out-escape-call-result | BYN3002 |
| diag/ref-out-escape-returned-source | BYN3002 |

Three goldens were regenerated in round 2 with `BAYAN_UPDATE`: `borrow-escapes-region`, `borrow-stored-through-span` and `strbuf-grow-escapes-context`. Their codes and spans are unchanged. The region they name moves from `sb` to the buffer's real storage (the `stackalloc` buffer, or arena `arena`), because `finish()` no longer takes the local's scope.

New tests (golden output generated with `BAYAN_UPDATE=1`):
- `diag/ref-out-return-one`: `first(a, by: b)` returns `a`. Storing `first("bob", by: name)` is accepted; `first(name, by: "bob")` is refused with BYN3002.
- `diag/ref-out-return-through-local`: returning through `let t = s; return t` and through a nested call; both refused with BYN3002.
- `diag/ref-out-return-mutual-recursion`: `f` and `g` return each other's parameters. Only the argument that can reach the result is refused (BYN3002).
- `diag/ref-out-return-arena-two-levels`: `mk2` calls `mk`, which returns `s.copy(to: a)`; the result stored past the arena is refused with BYN3002. dev accepts this because an `Arena` argument carried no region. Fixed: when the result may borrow an arena argument, that argument now lends its memory.
- `diag/strbuf-finish-then-clear`: `finish()`, then `clear()`, then use the string: BYN3004. It replaces `strbuf-finish-then-append`, per R2 amended.
- `run/strbuf-finish-then-append`: `finish()`, append, then print. It prints `before` (the pre-append text), then `before after`. `tests/cases/emit/run-c.sha256` gained one line for it.
- `BuiltinResultsTests`: one case per builtin table entry plus a control (returning arena text is BYN3003). All 13 pass. With the table disabled, 10 of the 12 entries fail; the other two, `string.invalidUtf8At` (`i64`) and `Symbol.intern` (`Symbol`), return types that cannot borrow, so their entries are redundant.
- `CacheTests.ACallerIsRecheckedWhenACalleeStartsOrStopsReturningAnArgument` (R5) passes.

## 5. Round 2: timings, 1 MiB generated program

| measurement | dev | branch |
|---|---|---|
| C# in-process, `OneMegabyteWithinTenTimes` path (CliCheck, median of 5) | 421 ms | 295 ms (earlier run 322 ms) |
| C# in-process, direct `Compilation.Create` (warm-up 1, then 5, GC between runs), median per round | 388 / 336 ms | 432 / 385 ms |
| same, minimum per round | 243 / 245 ms | 241 / 247 ms |
| process wall time, `dotnet bayan.dll check main.byn`, median of 5 interleaved | 726 ms (726, 724, 730, 722, 737) | 734 ms (743, 745, 731, 734, 725) |
| selfhost `bayan-check`, median of 5 (`OneMegabyteWithinTenTimes`) | 948 ms | 950 ms |

Within each process the direct runs rise (dev 243 to 570 ms), so those medians are noisy. The minimums are equal and the two in-process methods disagree in direction, so there is no measurable difference. The process wall time difference is +8 ms. Selfhost builds on the branch and the selfhost checker itself is unchanged.

## 6. Option (b) "append mutates": extra refusals

Toggled locally with `tmp/after3-cli`, then reverted. selfhost: 0. examples: 0. seeds: 0. `run/`: 0 existing cases; only the new `run/strbuf-finish-then-append` would be refused, which is what (b) means. `diag/lambda-capture-borrow-modified` gains one BYN3004 at line 6 (`buf.append("more")` while `f` captures `buf.view`); under option (a) its `.diag` is byte-identical to dev. Option (a) was approved 2026-11-03 (Q745).

## 7. `finish()`: spec and implementation mismatch

- Spec, `docs/bayan-spec.md:303`: `finish()` "consumes the buffer and returns it as a string without copying".
- Checker, `src/Bayan.Semantics/Binding/BuiltinMembers.cs:123-124`: "finish() returns the text borrowed from the buffer, like view; it does not consume the buffer yet". `finish()` binds to `BuiltinMember.StrBufAsString`, as `view` does.
- Emitter, `src/Bayan.Backend.C/CEmitter.cs:2242-2243`: `finish()` and `view` emit the same string view of the writer.
- Runtime, `src/runtime/bayan-rt.h:432`: `byn_strbuf_str(byn_writer w)` returns `(byn_str){w.buf, w.len}`, a view into the buffer's storage, and the buffer stays usable afterwards.
- Growth, `src/runtime/bayan-rt.c:362`: `BYN_WRITE_GROW` allocates a fresh block and never frees or overwrites the old one, so `append` never invalidates text already taken.
- Implemented (the loan-only reading): the `finish()` result borrows the buffer's storage plus a loan on the `StrBuf` local, but not the local's scope. `view` shares `StrBufAsString` and is unchanged; the new path applies only to the call syntax `finish()` on a local receiver. The spec wording is revision 0018's subject.

## 8. Round 2: failing tests, grouped by cause

Full suite (`tmp/full3.log`): 170 failed of 6171. 101 of those were C# test-harness breakage, fixed; with the fix, 69 failed. Later T41 ported the summaries to selfhost, which is the fix for the first five rows.

| cause | test class | count |
|---|---|---|
| selfhost has no Q745 summaries (expected, not fixed in round 2) | `SelfhostSemanticsT25Tests.DiagMatches` | 21 |
| same | `SelfhostSemanticsParityTests.GoldenParity` | 21 |
| same | `SelfhostSemanticsParityTests.CheckParity` | 21 |
| same, plus a pinned count | `SelfhostSemanticsEquivalenceLawTests.BayanCheckEqualsTheCCheckerOnEveryCleanParse` | 1 |
| not diagnosed | `SelfhostSemanticsNoPanicLawTests.BayanCheckNeverPanicsAndEveryDiagnosticSpanLiesInItsFile` | 1 |
| `ledger.byn:38` refusal (section 3) | `CliTests`: `TallyLiteChecksWithoutWarnings`, `TallyLitePrintsTheSettlement`, `TallyLiteTestsPass` | 3 |

- Selfhost parity: the same 21 diag goldens fail in each of the three parity groups: the 16 round-1 `ref-out-escape-*`; the 3 round-2 regenerated goldens (`borrow-escapes-region`, `borrow-stored-through-span`, `strbuf-grow-escapes-context`); `ref-out-return-one`, `ref-out-return-mutual-recursion` and `ref-out-return-arena-two-levels`. `ref-out-return-through-local` and `strbuf-finish-then-clear` match the selfhost checker.
- EquivalenceLaw reports "456 diag cases parse clean and 90 do not, pinned 435 and 90 (Q658)". The 21 new diag cases raise the clean-parse count, and the selfhost checker differs on the Q745 goldens anyway.
- NoPanicLaw: the set of random corpus files it lists differs (expected `random/00189`, `02199`, `05136`, `05466`; actual `random/02135`, `06275`, `07150`, `07782`, `09041`). The cause was not established; a selfhost-versus-C# divergence on region diagnostics is the likely one.
- Fixed in round 2, C# test-harness breakage (98 + 3 tests): `SelfhostSemanticsT37Tests.CaseMatches` (98) and `SelfhostSemanticsT25Tests` `ComputeMatches`, `UnionAndLentMatch` and `RunMatches r-a/r-b` reach `RegionAnalysis` internals by reflection. Five signature changes broke them: the constructor gained a `summary` parameter, the new static tables added a static constructor, `Region` gained a `Source` parameter, `StoreInto` gained a `note` parameter, and `AllocatedFrom` gained an overload. The reflection call sites in `SelfhostSemanticsT25Tests.cs` and `SelfhostSemanticsT37Tests.cs` were updated; T25 plus T37 then gave 140 passed and 21 failed (the 21 are the `DiagMatches` rows).
- All other tests passed, including `DiagTests`, `RunTests`, the `CacheTests`, `BuiltinResultsTests` and `MutantSchemata` PlainBuild. `dotnet build -c Release -warnaserror` gave 0 warnings and 0 errors.

## Open

- [ ] Confirm the `examples/tally-lite/ledger/ledger.byn:38` refusal (section 3) is resolved on dev: Q745's option (a) was approved 2026-11-03 for the loop-copy case, so the three `CliTests.TallyLite*` rows should pass. Done when they pass on the current tree.
