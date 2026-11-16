# 026 — Extensible error sets
Status: approved (owner 2026-11-17: Fable's recommendation)
Release: 0.4 (lands before spec 015 T15 part 2b)
Sources: owner 2026-11-17 (chose Rule 1 as `docs/bayan-spec.md` §3.13 states it); Fable's report `tmp/fable-e/out.log` (design source, not in the repository); `docs/bayan-spec.md` §3.13 (line 462) and §8 (line 1417); decision 006 §2 (C# outputs frozen at `v0.3.2`); decision 008 D5 (the freeze covers captured outputs, not C# source; the file is in commit da6ff94e, not yet on this branch); spec 019 R10, R12, R13, R14; spec 023 R1, R5 and item #6; spec 015 T15 and its plan section "The wave-brief lock (U4, Q1140)"; commits fe0ef3f1 and 11b3ca88
Created: 2026-11-17

## Problem
A `catch switch` over an error set must name every case (BYN2410). That is the point of a closed set, and it means that adding one case to a set breaks every program that switches over it without a fallback arm.

Spec 015 T15 part 2b adds `IoError.alreadyExists`, the signal the wave-brief lock needs to tell "someone else holds the lock" from any other failure of `Fs.rename`. Commit fe0ef3f1 built it and was reverted by 11b3ca88, because the new case shifts every later error code, changes the emitted error table of every program, and breaks `tests/cases/run/io-missing-file.byn`, which names all eleven cases. `IoError` mirrors what an operating system can report, so this will happen again: each newly modelled condition is a new case.

The spec already has the answer at §3.13: "Public enums and error sets are closed unless marked `extensible`, which forces callers to include a fallback case". It was never built: `extensible` is a contextual keyword that no declaration form parses (`union error extensible Fault { … }` is BYN1001 today). The same paragraph of §8 that lists the built-in codes is also off by one: it says user variants are numbered from 13, while `ParseError` takes 13 and 14 and user variants start at 15.

The owner looked at three rules:

- Rule 1: sets that mirror the outside world are marked `extensible`, and a switch over them needs a fallback arm.
- Rule 2: every set is closed; a set grows only at a minor version, listed as breaking in the changelog.
- Rule 3: every set is closed for good; new conditions arrive as `other(detail)` with a platform code.

The owner chose Rule 1 for `IoError`, with Rule 2 as the growth rule of the sets that stay closed. This spec states that choice as requirements.

## Goals
- G1. Adding a case to an extensible error set does not break a program that compiled before.
- G2. The compiler, not a convention, makes callers ready for that: a missing fallback arm is an error at the switch.
- G3. Closed sets keep full exhaustiveness checking with no forced dead arm.
- G4. `IoError` is extensible before `alreadyExists` is added, so users of `IoError` change their switches once.
- G5. The spec says what is promised about error code numbers and what is not.

## Non-goals
- `enum open`, and `extensible` on `enum` or `union` declarations. They stay with spec 023 item #6.
- Adding `IoError.alreadyExists` or any other case. That is spec 015 T15 part 2b.
- A warning when a known case falls into the fallback arm (OQ4).
- Reserving a code range for built-in sets, or emitting only reachable cases, to cut the cost of re-pinning (OQ5).
- Any change to the runtime (`runtime/bayan-rt.{h,c}`). This spec adds no case, so no code moves.
- Fixing `Io.readText` on a directory, which yields `.other` and not `.isDirectory` on 0.3.1.

## User stories
- As a program author I switch over `IoError`, name the cases I handle, and add one fallback arm. When a later release adds a case, my program still compiles and the new case reaches my fallback.
- As a library author I mark my own set `extensible` when it reports conditions I do not control, and I can add a case in a patch release.
- As a library author I leave a set I do control closed, and my callers get an error at every switch the day I add a case, at a minor version.
- As the builder of the wave-brief lock I add `alreadyExists` to `IoError` without editing any existing switch.

## Requirements
### The marker
- **R1 Syntax.** An error set is marked with the contextual keyword `extensible` after the kind, as §0 rule 12 requires for modifiers: `union error extensible Name { … }` and, for a composition, `union error extensible Name = A, B except .c`. Visibility and other leading modifiers stay where they are (`public union error extensible Name { … }`). `extensible` stays usable as a name everywhere else.
- **R2 Wrong order.** `extensible union error Name` is reported by the existing keyword-order diagnostic BYN1044 with the corrected text as its fix. No new parser code is added for it.
- **R3 What the mark means.** A set is extensible when it is marked, or when it is composed from at least one extensible set, with or without `except`. A composition does not need the mark to inherit it; marking a composition of closed sets makes the composition extensible and leaves its members closed.
- **R4 Any set may be marked.** The mark is accepted on a set of any visibility. No diagnostic is added for a marked set that is not public (OQ3).

### The check
- **R5 Fallback arm required.** A `switch` or a `catch switch` whose subject is an extensible set needs a fallback arm for every extensible set the subject is, or is composed from. A fallback arm is one of: a `_` arm; `default:` in a statement `switch`; a set arm that names the extensible set (`IoError e => …`). Naming every case that exists today does not satisfy the rule.
- **R6 Hard error.** A missing fallback arm is an error, not a lint and not a warning, with the new code BYN2412 (semantics range, beside BYN2410 and BYN2411; free in `csharp/`, `src/`, `docs/` and `docs/diagnostics-allocated.txt` on 2026-11-17). Message: "`{0}` is extensible, so this `{1}` needs a fallback arm", where `{0}` is the set and `{1}` is `switch` or `catch switch`. The primary label sits where BYN2410 puts its label and reads "no `_ => …` or `{0} e => …` arm". A help line says that the set may gain cases in a later version.
- **R7 One diagnostic per switch.** When BYN2412 is reported for a switch, BYN2410 is not also reported for the same extensible set. The closed members of a composed subject are still checked case by case under BYN2410.
- **R8 Closed sets unchanged.** A switch over a closed set behaves as today: every case named or a fallback arm, else BYN2410. No fallback arm is forced.
- **R9 Other forms unchanged.** `catch value`, `catch return`, `catch { … }`, `catch (Set.case) …`, `try`, `fails` clauses and `==` on error values are not checked and do not change. The rule applies in every package, including the one that declares the set (OQ2).
- **R10 Explain page.** BYN2412 has an explain page `docs/diagnostics/BYN2412.md` and the matching entry in the self-hosted compiler, with a before and after example.

### Built-in and user sets
- **R11 `IoError` is extensible.** The built-in declaration becomes `public union error extensible IoError { … }` with the same eleven cases in the same order.
- **R12 Other sets are closed.** `Utf8Error`, `ParseError` and every other built-in set stay closed: their cases are a property of the language, a forced fallback would be a dead arm, and the full check is worth more. A user set is closed unless marked.
- **R13 Rule 2 for closed sets.** A closed public set gains a case only at a minor version, and the change is listed as breaking in `CHANGELOG.md`. This holds for built-in sets and is the stated convention for package authors. An extensible set may gain a case in any release; the changelog names the case.
- **R14 Which sets to mark.** The spec text says when to mark: a set that mirrors something outside the program (the operating system now; network, process and database conditions later). It is guidance, not a check.
- **R15 Rule 3 rejected.** The spec records that new conditions do not arrive as `other(detail)` with a platform code, and why: the meaning moves into numbers that differ by platform (17 is `EEXIST` on Linux and macOS and nothing a reader can name); the checker cannot catch a wrong number; the wave-brief lock (Q1140) needs "already exists" as a named branch; and promoting a code to a real case later makes every `.other(17)` test silently stop matching. `other` stays as the case for conditions not yet modelled.

### Error code numbers
- **R16 The numbering, stated correctly.** §8 says: built-in variants are numbered first, in declaration order, `IoError` 1 to 11 (`signaled` 10, `timeout` 11), `Utf8Error.invalidSequence` 12, `ParseError.badDigit` 13 and `ParseError.overflow` 14; user variants are numbered from 15. This replaces "numbered from 13".
- **R17 What is not promised.** The number of an error case is not part of the language. No Bayān expression reads it, it is not the process exit code, and it may differ between two compiler versions. Adding a case to a built-in set shifts every later number.
- **R18 What is promised.** Case names, payload shapes, and the exit code given by `@exitCode` (1 when absent). C code that links the runtime uses the `BYN_IO_*` names from `bayan-rt.h` against the runtime of the same compiler version, and `BYN_RUNTIME_VERSION` is bumped by every change that moves a built-in code.

### The C# freeze
- **R19 Where it is built.** While spec 019a has not landed (0 of 78 tasks done on 2026-11-17) the xUnit parity harnesses compare the two compilers on every case, so the feature is built in both `csharp/` and `src/`, in the same change, with the same code, message and label. This is inside the freeze: decision 006 §2 and decision 008 D5 freeze the expected outputs captured at `v0.3.2`, not C# source. If 019a lands first, the feature is built in `src/` only (spec 023 R1) and the cases added here get rows in `tests/cases/DIVERGENCES.tsv` (019 R12). OQ1 holds the alternative.
- **R20 How expected files are produced.** No expected file is typed by hand. Under R19's first branch they are written by `BAYAN_UPDATE=1 dotnet test` from the C# compiler and the self-hosted compiler must match them before the change lands. Under the second branch they are written by the self-hosted compiler through the golden runner and each new file is read by a person against this spec (spec 023 R5). In both branches a change to an existing expected file goes in a commit that holds only expected files and names its cause (019 R14).
- **R21 Frozen inputs.** `tests/cases/run/io-missing-file.byn` exists at `v0.3.2` and its input changes here (one fallback arm added, `.stdout` unchanged). The change is recorded so spec 019's export does not take the tag's version of the file: a row in `tests/cases/DIVERGENCES.tsv` if that file exists when this lands, else a note in spec 019's tasks. Cases added by this spec are not in the tag and are not part of the export.
- **R22 The emit pin.** Marking `IoError` extensible does not change the emitted error table, so only the `tests/cases/emit/run-c.sha256` lines of new and edited `run/` cases change. A change to any other line stops the work and is reported, as decision 008 D5 requires.

### Order with spec 015 T15 part 2b
- **R23 This spec first.** Spec 015 T15 part 2b (`IoError.alreadyExists` and the wave-brief lock; held commit fe0ef3f1 on `chore/worker-015-t15`) is built after this spec lands. Spec 015's tasks say so.
- **R24 What part 2b gains.** `tests/cases/run/io-missing-file.byn` and every other switch over `IoError` in `src/`, `lib/`, `tools/`, `examples/` and `tests/cases/` already has a fallback arm, so adding `alreadyExists` breaks none of them and users break once, here. A program reaches the new case through its fallback until it names it.
- **R25 What part 2b still owes.** The full re-record of `tests/cases/emit/run-c.sha256` (all lines, one golden-only commit), the regenerated `bootstrap/`, the §8 renumbering (`IoError` 1 to 12, `Utf8Error` 13, `ParseError` 14 and 15, user variants from 16), `src/tests/SelfhostSemanticsT9Tests.cs`, and the bump of `BYN_RUNTIME_VERSION` from 3 to 4 in `runtime/bayan-rt.h` with the generated `src/driver/runtime.byn` and `bootstrap/bayan-rt.h`. fe0ef3f1 changed `BYN_UTF8_INVALID_SEQUENCE` from 12 to 13 and added `BYN_IO_ALREADY_EXISTS` without that bump. Under R13 the changelog entry for `alreadyExists` names the case and is not marked breaking.

### Tests and documents
- **R26 Cases.** BYN2412 has `diag/` cases for: a `catch switch` over `IoError` naming all cases; a statement `switch` over a user extensible set; a composed set that inherits the mark; a closed set that still gets BYN2410. The feature has `run/` cases for: a user extensible set matched through `_`; `IoError` matched through `IoError e`. The marker has a `parse/` case for both declaration forms.
- **R27 Spec text.** `docs/bayan-spec.md` §3.13 and §8, `docs/bayan-grammar.md`, and `docs/STATUS.md` change through revision 0025. §3.13 keeps "not in 0.3" for `open` and for `extensible` on enums.

## Acceptance criteria
- Given `union error extensible Fault { a, b }` and a `catch switch` with arms `.a` and `.b` only, when it is compiled, then BYN2412 is reported once and BYN2410 is not (R1, R5, R6, R7).
- Given the same switch with a third arm `_ => …` or `Fault e => …`, then it compiles, and a value of case `.b` takes the `.b` arm (R5).
- Given `union error Closed { a, b }` and a switch naming `.a` only, then BYN2410 is reported as today; naming both compiles with no fallback arm (R8, R12).
- Given `union error Both = IoError, Closed` and a switch naming every case of both with no fallback, then BYN2412 names the extensible set (R3, R5).
- Given `extensible union error Fault { a }`, then BYN1044 is reported with `union error extensible Fault` as the fix (R2).
- Given `tests/cases/run/io-missing-file.byn` as it is at `v0.3.2`, when compiled after this spec, then BYN2412 is reported; with one fallback arm added its `.stdout` is byte-identical (R11, R21).
- Given the whole suite after this spec, then `tests/cases/emit/run-c.sha256` differs from before only on lines of cases this spec added or edited (R22).
- Given `docs/bayan-spec.md` §8 after revision 0025, then it says user variants are numbered from 15 and lists `ParseError` 13 and 14 (R16).
- Given a later change that only appends a case to `IoError`, then no `.byn` file in the repository needs an edit to compile (R24).

## Law candidates
- An extensible set stays extensible: removing the mark from a published set is a breaking change of the same weight as adding a case to a closed set.
- A new built-in error case is one change with one golden-only commit and one `BYN_RUNTIME_VERSION` bump.

## Open questions
Each has the most conservative option as the default; work proceeds on the default unless the owner says otherwise.

- **OQ1 Built in both compilers, or self-hosted only.** The report says the feature is self-hosted only with a divergence row if it lands after the 019 freeze work. 019a has not started, and until it does a self-hosted-only diagnostic fails the parity harnesses on every new case. *Default:* both compilers now (R19 first branch); self-hosted only if 019a lands first.
- **OQ2 The rule inside the declaring package.** A package could be let off the fallback arm for its own extensible sets, since it changes the set and the switches together. BYN2712 (the union lint) is scoped to the declaring package in the opposite direction. *Default:* the rule applies everywhere, the standard library included. It is the stricter option and can be loosened later without breaking a program; the reverse cannot.
- **OQ3 `extensible` on a non-public set.** §3.13 speaks of public sets. A private extensible set forces fallback arms on its own author for no gain. *Default:* accepted with no diagnostic (R4); a style lint can be added later.
- **OQ4 Warning for a known case caught by the fallback.** The report mentions a warning, in the manner of Swift's `@unknown default`, when a case that exists today is not named and falls into the fallback. *Default:* not built. The fallback is the user's stated intent, and a warning can be added in a later release without breaking a program.
- **OQ5 Cost of re-pinning.** Each new built-in case re-records every line of `run-c.sha256` and regenerates `bootstrap/`. The report names two ways out: emit only the cases a program can reach, or reserve a number range for built-in sets. *Default:* dense numbering as today; revisit if a third built-in case is added within one release.
- **OQ6 Set arm on a composed subject.** `work/todo.md` records that a multi-set alias is rejected as an arm pattern. Whether `IoError e => …` is accepted as an arm when the subject is `union error Both = IoError, Closed` is not known. *Default:* T5 probes it; if it is rejected today, `_` and `default:` are the only fallback arms for a composed subject in this spec and the message label says only `_ => …` there.
- **OQ7 When Rule 1 would be dropped.** The report lists what would change the recommendation: nobody outside the repository depends on the standard library before 1.0 (Rule 2 alone would do), or the re-pin cost proves too high (Rule 3). *Default:* neither holds; no action.
