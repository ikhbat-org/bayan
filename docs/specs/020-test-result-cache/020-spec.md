# 020 — Test-result cache
Status: approved (not started: T1–T27 open)
Created: 2026-11-13

## Problem
The full suite (about 13,500 tests) takes about 40 minutes on one machine and is rerun for every merge, although most merges cannot change most results. Measured 2026-11-13 over the last 200 first-parent merges to `dev`: 152 (76%) touch neither the compiler, the self-hosted compiler nor the bootstrap; 28 (14%) touch the compiler but not the runtime or C backend; 20 (10%) touch the runtime or C backend; 75 touch the tests. So at least 77 merges (38%) changed neither compiler nor tests, and still paid for the whole suite. The program cache already removes most C compilation from a warm suite (112 C compiler calls against 1426 cold), so the remaining time (1844 s wall on mb1) is test execution, which only skipping can remove.

Skipping is dangerous. A reused pass that a real run would not have produced hides a failure, and nothing downstream can find it again. The user's condition (2026-11-13): "I want the test-result cache as well without the risk of hiding a failure." Tests here read goldens, start child processes, read the environment, the clock, the OS and the file system, and some reset caches or change process-wide state on purpose, so "the inputs did not change" is hard to know and easy to get wrong.

Two partial mechanisms exist. Test selection by changed files (plan 008 B) picks which tests are asked for, from a hand-written map; it is a speed heuristic and is allowed to be incomplete because the full tier runs later. A whole-tree pass cache on the Windows offload (plan 008 D) reuses a pass when the commit's tree and the filter are identical; it hits only when nothing at all changed, and its key holds no toolchain or environment.

## Goals
- A reused result is one a real run on the same inputs would also have produced. Soundness comes first; hit rate second.
- No test is ever dropped: every test asked for gets a result, either from a run now or from a recorded pass whose inputs are shown unchanged.
- The mechanism proves its own soundness continuously (laws, canaries, a shadow comparison), not once at review.
- A reader of any report can tell, per test, whether it ran or was reused, and from which run.
- Independent of the test framework, so it survives the .NET exit (spec 019): the unit is "something that runs as its own process tree".

## Non-goals
- Caching failures, skips or timeouts.
- Any reuse in release, nightly, law or `main` gates.
- Deciding which tests are relevant to a change: that stays with selection (plan 008 B).
- Finer invalidation than "the built test program changed" for a change to test code (no per-class dependency analysis of the test program).
- Sharing results between machines.
- Making flaky or order-dependent tests deterministic. They are excluded, not fixed, here.
- Speeding up C compilation (the program cache's job).

## User stories
- As the dispatcher, I want a docs-only or goldens-only merge to rerun only the tests that read what changed, so that the gate takes minutes.
- As the user, I want proof on every nightly that the cache would not have hidden a failure, so that I can leave it on.
- As a reviewer, I want the report to name each reused test and the run it came from, so that I know what evidence a green run rests on.
- As anyone debugging, I want one switch that turns all reuse off.

## Requirements

Unit and key
- R1 The unit of reuse is a **test unit**: a named group of tests that is run as one isolated process tree (today a test class). A result is recorded and reused for whole units only; the report still lists every test in it.
- R2 A recorded result is keyed on the **recorded inputs** of the run that produced it: everything that unit's process tree actually consulted, observed from outside the process while it ran. Recorded input kinds: the content of every file read or executed; every path looked up and found absent; the name list of every directory listed; the target of every link followed.
- R3 Paths the unit itself created before reading them are not inputs. A unit that writes to a version-controlled file, or reads a file and then writes it, is never recorded.
- R4 Inputs that cannot be observed from outside are covered by construction instead: a recorded run is given a fixed environment made only of an allow-list of variables, and every allow-listed value is in the key. A variable not on the list does not exist for the unit.
- R5 The key also holds a **host fingerprint**: OS, OS version, architecture, processor count, and the identity of every installed toolchain root the unit read (each root: its version, and a digest of its file names, sizes and modification times).
- R6 A store of derived files (the program cache) may stand in the key by entry name instead of content only if its own key is shown to cover every input of what it stores, the C compiler's identity included. Otherwise its files are ordinary inputs (R2).
- R7 A lookup is a hit only if every recorded input, every allow-listed variable and the whole fingerprint equal the current state, the entry is intact (R17), and the entry is for this unit. Anything else is a miss, and the unit runs.
- R8 A change to the recording mechanism, the key format or any ignore list invalidates every entry made before it.

What is never cached
- R9 Only a unit in which every test passed is recorded. A unit with a failure, a skip, a timeout or a crash is never recorded and always runs.
- R10 A unit is **admitted** for reuse only after three recorded passes on separate runs with identical recorded inputs for identical state. Until then it runs every time. A unit whose recorded inputs differ between two runs on the same state is not admitted.
- R11 A unit is **barred** (never recorded, never reused) if any of these holds: its run used the network; it read a volatile system path outside a short named list (each entry with a written reason, changed only by a human); it contains a law proof; it is on the known-flaky list; it is on a human-kept never-cache list (tests that depend on time, randomness, load, other processes, or that reset caches or change shared state on purpose). A unit that cannot be shown to meet R2–R6 is treated as barred.
- R12 Recording exists only on a host where the observation of R2 is available and proven by R19. On any other host the cache neither records nor reuses.

Gates
- R13 These always run every unit, with reuse and recording both off, and a test proves they cannot be switched on: a release; the nightly full tier; the laws gate and every law proof run; any merge to `main`.
- R14 Where reuse is allowed (the full-suite run before a merge to `dev`, and local runs), it composes with selection: selection chooses the units asked for; the cache then decides, per asked unit, run or reuse. The cache never removes a unit from a run and never reads the selection map.

Verification
- R15 **Shadow comparison.** Every nightly full run also computes, without using it, what the cache would have answered for each unit. A unit the cache would have reused and that did not pass is a soundness failure: the run fails, names the unit and the entry, the unit is barred and its entries are removed. Only a human re-admits it.
- R16 **Sampled rerun.** Every run with reuse on reruns a sample of its hits (at least 5%, never fewer than one unit, chosen from the commit so it is repeatable) and applies R15's rule to them.
- R17 Every entry carries a checksum over its whole content. An entry that fails it, cannot be parsed, or has an unknown format version is deleted and counts as a miss.
- R18 **Mutation check.** For every input kind of R2, every allow-listed variable and every fingerprint part, a test changes exactly that one thing after a recorded pass and requires a miss.
- R19 **Recorder completeness.** For every way a process tree can consult the file system (read, execute, failed lookup, directory listing, link, a child, a grandchild, a statically linked child), a canary unit that does it must show that input in its record. A host where any canary fails does not record (R12).
- R20 **Poisoning check.** An entry recorded for one unit, one input set or one host is never reused for another; an entry altered after it was written is rejected (R17); an entry claiming a pass for inputs that differ from the current state by one byte is a miss.

Storage
- R21 Results are stored on the host that recorded them, outside any checkout, and are never copied to another host.
- R22 The store is bounded: a cap on total size and on entries per unit, least-recently-used eviction, a sweep of staging left by killed processes, atomic writes, and a cache-directory tag. Its bound has a test that joins the release memory gate.
- R23 The store can be listed (units, entries, bytes, admitted and barred units with reasons) and emptied by one command each.

Visibility and control
- R24 Every report states "N reused from cache, M run", and for each reused unit: its tests, and the commit, date and host of the recorded run. A reused test is never printed as if it had run.
- R25 One switch turns reuse and recording off for a run. The default outside the runs named in R14 is off.
- R26 A recorded run that fails is rerun once without recording, and that second result is the one reported; it is never stored.

## Acceptance criteria
- Given an admitted unit and a merge that changes only files it did not read, when the suite runs with reuse on, then the unit is reported reused, with the recorded run named, and no process is started for it.
- Given an admitted unit, when one byte of one file it read changes, or a file appears at a path it found absent, or a directory it listed gains a name, then the unit runs (R18).
- Given a unit that reads a file through a grandchild process built without the system C library, when it is recorded, then that file is in its record (R19).
- Given a store in which every unit is marked passed for wrong inputs, when a release, nightly, laws or `main` gate runs, then every unit runs and a failing test fails the gate (R13, R20).
- Given a nightly where a unit the cache would have reused fails, then the nightly fails with a soundness message, and the next run with reuse on runs that unit (R15).
- Given a unit that opens a network connection or writes a version-controlled file, when it is recorded, then no entry is written and the report says why (R3, R11).
- Given a host with no proven recorder, when reuse is switched on, then the run says the cache is unavailable there and runs everything (R12).
- Given a store over its size cap, when a run ends, then it is under the cap and the newest entries remain (R22).
- Given the last 200 merges to `dev` replayed against real records, then the measured share of unit time reused is reported, and the feature is not switched on for the gate if it saves less than the recording costs.

## Law candidates
- For every entry and every single change to one recorded input, allow-listed variable or fingerprint part, lookup is a miss (R7, R18). Kind: property.
- For every sequence of runs, the store never holds an entry for a unit that had a failure, skip, timeout or crash, or for a barred unit (R9, R11). Kind: invariant.
- For every entry, any change to its stored bytes makes lookup reject it (R17, R20). Kind: property.
- For every consultation kind in the canary table, the record of a unit that performs it contains that input (R19). Kind: guard.
- For every gate named in R13 and every store content, the gate starts every unit (R13). Kind: guard.
- For every unit, a variable outside the allow-list is not visible to a recorded run (R4). Kind: guard.

## Decisions (user, 2026-11-13)
1. **Hosts.** Version 1 records and reuses on Linux only (the ghosthive VM `bayan-test01`); mb1, wp1 and wlt1 run everything (R12).
2. **Windows offload pass cache (plan 008 D).** Its key gains the host fingerprint and environment, and it comes under R9, R13, R17 and R24 (recommendation, not objected to).
3. **Merges to `dev`** may count a reused pass; the nightly shadow comparison (R15) checks every such reuse. `main`, release, nightly and laws never reuse (R13).
4. **Timing against spec 019.** Task 1 measures the per-unit process cost on the VM; build now with a thin adaptor if it is cheap, otherwise after 019.
5. **Program cache key.** It gains the C compiler's identity (its version output plus the path and write time of each word of its command that names a file; no size or hash, user 2026-11-13; plan 009, `docs/plans/2026-11-13-009-prebuilt-runtime-object.md`), in the C# compiler and the self-hosted driver alike (R6); every user rebuilds once after the upgrade.
6. **CI.** No reuse on hosted runners in version 1 (recommendation, not objected to).
7. **Toolchain roots** are identified by version plus a digest of file names, sizes and modification times (R5); the uncached gates are the backstop (recommendation, not objected to).

## Open questions
- None.
