# 020 — Test-result cache
Status: approved (revised 2026-11-28: hybrid)
Release: unscheduled
Sources: none recorded
Created: 2026-11-13
Revised: 2026-11-28 (hybrid)

## Problem
The full suite (about 13,500 tests) takes about 40 minutes on one machine and is rerun for every merge, although most merges cannot change most results. Measured 2026-11-13 over the last 200 first-parent merges to `dev`: 152 (76%) touch neither the compiler, the self-hosted compiler nor the bootstrap; 28 (14%) touch the compiler but not the runtime or C backend; 20 (10%) touch the runtime or C backend; 75 touch the tests. So at least 77 merges (38%) changed neither compiler nor tests, and still paid for the whole suite. The program cache already removes most C compilation from a warm suite (112 C compiler calls against 1426 cold), so the remaining time (1844 s wall on mb1) is test execution, which only skipping can remove. The slowest host gains most: the golden cases on wp1's Windows side took 16,603 s (Neon review, 2026-11-28), and a design that reuses only on Linux gives that host nothing.

Skipping is dangerous. A reused pass that a real run would not have produced hides a failure, and nothing downstream can find it again. The user's condition (2026-11-13): "I want the test-result cache as well without the risk of hiding a failure." Tests here read goldens, start child processes, read the environment, the clock, the OS and the file system, and some reset caches or change process-wide state on purpose, so "the inputs did not change" is hard to know and easy to get wrong.

The first design keyed results on what `strace` saw a unit read. The Neon review (2026-11-28) found three holes: toolchain roots were digested by names, sizes and modification times only, not content; `strace` misses clock reads through the vDSO and metadata-only checks; and the key existed on Linux only, so wp1's Windows goldens got no speedup. The owner chose the hybrid (2026-11-28): the key is the declared inputs by content on every host, and `strace` verifies the declared lists every night instead of being the key.

Two partial mechanisms exist. Test selection by changed files (plan 008 B) picks which tests are asked for, from a hand-written map; it is a speed heuristic and is allowed to be incomplete because the full tier runs later. A whole-tree pass cache on the Windows offload (plan 008 D) reuses a pass when the commit's tree and the filter are identical; it hits only when nothing at all changed, and its key holds no toolchain or environment.

## Goals
- A reused result is one a real run on the same inputs would also have produced. Soundness comes first; hit rate second.
- No test is ever dropped: every test asked for gets a result, either from a run now or from a recorded pass whose declared inputs are shown unchanged.
- The same key on every host that runs the suite, so wp1's Windows goldens are reused as Linux ones are.
- The mechanism proves its own soundness continuously (nightly verification of the declared lists, laws, canaries, a shadow comparison), not once at review.
- A reader of any report can tell, per test, whether it ran or was reused, and from which run.
- Independent of the test framework: the unit is what `scripts/test.sh` schedules and reports as one.

## Non-goals
- Caching failures, skips or timeouts.
- Any reuse in release, nightly, law or `main` gates.
- Deciding which tests are relevant to a change: that stays with selection (plan 008 B).
- Finer invalidation than "the built test program changed" for a change to test code (no per-unit dependency analysis of the test program).
- Sharing results between machines.
- Making flaky or order-dependent tests deterministic. They are excluded, not fixed, here.
- Speeding up C compilation (the program cache's job).

## User stories
- As the dispatcher, I want a docs-only or goldens-only merge to rerun only the units whose declared inputs changed, on every host, so that the gate takes minutes.
- As the user, I want proof on every nightly that the declared lists are complete and that the cache would not have hidden a failure, so that I can leave it on.
- As a reviewer, I want the report to name each reused test and the run it came from, so that I know what evidence a green run rests on.
- As anyone debugging, I want one switch that turns all reuse off.

## Requirements

Unit and key
- R1 The unit of reuse is a **test unit**: a named group of tests that `scripts/test.sh` schedules and reports as one (a golden class folder, a Bayān package, a parity tool, a script-test group, or the runtime C tests). A result is recorded and reused for whole units only; the report still lists every test in it.
- R2 A recorded result is keyed on the unit's **declared inputs**, by content (SHA-256): the `BAYAN_EXE` binary; `runtime/`; `lib/std/`; the unit's own files (its case folder, package, parity case folder or script-test group); every other file or executable the declared list names for its kind; the toolchain identity (R5); the allow-listed environment (R4); and the tool's own digest (R8). The declared lists are human-kept, per unit kind, one row per input with a reason, and are proven every night (R27), not trusted.
- R3 Under verification (R27), paths the unit itself created before reading them are not reads outside its list. A unit that writes to a version-controlled file, or reads a file and then writes it, is barred.
- R4 Inputs that no list can name are covered by construction instead: a run whose results may be recorded is given a fixed environment made only of an allow-list of variables, and every allow-listed value is in the key. A variable not on the list does not exist for the unit.
- R5 The key also holds a **host fingerprint**: OS, OS version, architecture, processor count, and the **toolchain identity**: the version output of the C compiler and of zig, and a SHA-256 of the content of each one's executable and of every file under its root. Names, sizes and modification times never stand in for content. A part with no file to hash (on macOS the system libraries live in the dyld shared cache, not as files) is named in the plan, is covered by the OS version, and is backed by R13.
- R6 The program cache never stands in the key, and its keys are not reused as test keys: its compiler identity (version output plus the path and write time of the compiler, plan 009, user 2026-11-13) and its mtime-based script key are not content, and stay as decided for that cache. Every input the program cache derives a test binary from (`BAYAN_EXE`, `runtime/`, the unit's sources, the toolchain by content) is already in the key (R2, R5), so the result cache computes its own identity and never reads the program cache's.
- R7 A lookup is a hit only if every declared input, every allow-listed variable and the whole fingerprint equal the current state, the entry is intact (R17), the entry is for this unit, and the unit is not barred. Anything else is a miss, and the unit runs.
- R8 A change to the key format, the cache tool, any declared list or any ignore list invalidates every entry made before it.

What is never cached
- R9 Only a unit in which every test passed is recorded. A unit with a failure, a skip, a timeout or a crash is never recorded and always runs.
- R10 A unit is **admitted** for reuse only after three recorded passes on separate runs with the same key. Until then it runs every time. A unit whose outcome differs between two runs with the same key is barred.
- R11 A unit is **barred** (never recorded, never reused) if any of these holds: verification (R27) saw it use the network, write a tracked file, read a volatile system path outside a short named list (each entry with a written reason, changed only by a human), or read outside its declared list; any file in its declared inputs or seen by verification is named in a `proof:` line, or any command it runs is a `check:` line, of an enacted `docs/laws/*.md` file; it is on the known-flaky list; it is on a human-kept never-cache list (tests that depend on time, randomness, load, other processes, or that reset caches or change shared state on purpose). A unit that cannot be shown to meet R2–R6 is treated as barred.
- R12 Recording and reuse exist on every host that runs the suite: mb1 (macOS), wp1 (Windows and its Debian WSL), wlt1, and bayan-test01. A host where the key cannot be computed (a toolchain part unreadable, no `BAYAN_EXE`) neither records nor reuses, and says why. Verification (R27) runs on Linux only, where `strace` is available and proven by R19; its verdict reaches every host through the declared lists.

Gates
- R13 These always run every unit, with reuse and recording both off, and a test proves they cannot be switched on: a release; the nightly full tier; the laws gate and every law proof run; any merge to `main`.
- R14 Where reuse is allowed (the full-suite run before a merge to `dev`, and local runs), it composes with selection: selection chooses the units asked for; the cache then decides, per asked unit, run or reuse. The cache never removes a unit from a run and never reads the selection map.

Verification
- R15 **Shadow comparison.** Every nightly full run also computes, without using it, what the cache would have answered for each unit. A unit the cache would have reused and that did not pass is a soundness failure: the run fails, names the unit and the entry, the unit is barred and its entries are removed. Only a human re-admits it.
- R16 **Sampled rerun.** Every run with reuse on reruns a sample of its hits (at least 5%, never fewer than one unit, chosen from the commit so it is repeatable) and applies R15's rule to them.
- R17 Every entry carries a checksum over its whole content. An entry that fails it, cannot be parsed, or has an unknown format version is deleted and counts as a miss.
- R18 **Mutation check.** For every declared input kind of R2, every allow-listed variable and every fingerprint part, a test changes exactly that one thing after a recorded pass and requires a miss.
- R19 **Recorder completeness.** For every way a process tree can consult the file system (read, execute, failed lookup, directory listing, link, a child, a grandchild, a statically linked child, a relative open after `chdir` in a child, an `openat` relative to a directory fd, a read through a relative symlink), a canary unit that does it must show that input, with its absolute path, in the list verification observes. The canaries prove the verifier, not the key. A host where any canary fails does not verify, and the night fails (R27).
- R20 **Poisoning check.** An entry recorded for one unit, one input set or one host is never reused for another; an entry altered after it was written is rejected (R17); an entry claiming a pass for inputs that differ from the current state by one byte is a miss.
- R27 **Nightly verification.** Every night a scheduled job on GitHub-hosted `ubuntu-latest` runs every unit under `strace -f` and compares every observed read, execute, failed lookup and directory listing with the unit's declared inputs. A read outside the list fails the night with the unit and the path, and bars that unit from reuse on every host: the failure prints the `bar` row for the human-kept lists, whose digest is in every key (R8), and the unit stays barred until a human adds the input to its list. A night that does not run or does not finish is a failure.

Storage
- R21 Results are stored on the host that recorded them, outside any checkout, and are never copied to another host. The one exception is the nightly job's own store, carried between its runs by the workflow cache and read only by its shadow comparison (R15).
- R22 The store is bounded: a cap on total size and on entries per unit, least-recently-used eviction, a sweep of staging left by killed processes, atomic writes, and a cache-directory tag. Its bound has a test that joins the release memory gate.
- R23 The store can be listed (units, entries, bytes, admitted and barred units with reasons) and emptied by one command each.

Visibility and control
- R24 Every report states "N reused from cache, M run", and for each reused unit: its tests, and the commit, date and host of the recorded run. A reused test is never printed as if it had run.
- R25 One switch turns reuse and recording off for a run. The default outside the runs named in R14 is off.
- R26 A unit that fails under verification's trace is rerun once untraced, and that second result is the one reported; it is never stored. The traced run's reads are still compared (R27).

## Bounded risk (accepted by the owner, 2026-11-28)
A declared list can miss an input. Until the next nightly verification sees the read, a change to that input does not miss the key, and a reused pass can hide a failure on `dev` for up to a day. The sampled rerun (R16, 5% of hits) and the nightly shadow comparison (R15) stay to catch it sooner, and the cache is forced off for a release, the laws gate, law proofs, the pre-push gate and `main` (R13), so the exposure never reaches `main` or a release. Reads `strace` cannot see (the clock through the vDSO, metadata-only checks that do not open a file) are not caught by verification at all; they are covered only by the never-cache list, admission (R10), R16 and R15.

## Acceptance criteria
- Given an admitted unit and a merge that changes only files outside its declared inputs, when the suite runs with reuse on (on any host, wp1 Windows included), then the unit is reported reused, with the recorded run named, and no process is started for it.
- Given an admitted unit, when one byte of one declared input changes, or one byte of the C compiler's or zig's executable or root, or one allow-listed variable, then the unit runs (R18).
- Given a unit whose declared list lacks a file it reads, when the nightly verification runs, then the night fails naming the unit and the path, and once the printed `bar` row is committed no host reuses that unit (R27).
- Given a unit that reads a file through a grandchild process built without the system C library, when it is verified, then that file is in the observed list (R19).
- Given a store in which every unit is marked passed for wrong inputs, when a release, nightly, laws or `main` gate runs, then every unit runs and a failing test fails the gate (R13, R20).
- Given a nightly where a unit the cache would have reused fails, then the nightly fails with a soundness message, and the next run with reuse on runs that unit (R15).
- Given a unit that opens a network connection or writes a version-controlled file under verification, then it is barred and the report says why (R3, R11).
- Given a host where the key cannot be computed, when reuse is switched on, then the run says the cache is unavailable there and runs everything (R12).
- Given a store over its size cap, when a run ends, then it is under the cap and the newest entries remain (R22).
- Given the last 200 merges to `dev` replayed against the declared lists, then the measured share of unit time reused is reported per host, and the feature is not switched on for the gate if it saves less than computing the key costs.

## Law candidates
- For every entry and every single change to one declared input, allow-listed variable or fingerprint part, lookup is a miss (R7, R18). Kind: property.
- For every sequence of runs, the store never holds an entry for a unit that had a failure, skip, timeout or crash, or for a barred unit (R9, R11). Kind: invariant.
- For every entry, any change to its stored bytes makes lookup reject it (R17, R20). Kind: property.
- For every consultation kind in the canary table, the list verification observes for a unit that performs it contains that input (R19). Kind: guard.
- For every gate named in R13 and every store content, the gate starts every unit (R13). Kind: guard.
- For every unit, a variable outside the allow-list is not visible to a run whose results may be recorded (R4). Kind: guard.

## Decisions (user, 2026-11-13; revised 2026-11-28)
1. **Hosts.** Records and reuses on every host: mb1, wp1 (Windows and Debian WSL), wlt1 and bayan-test01 (R12; owner chose the hybrid, 2026-11-28). Verification runs nightly on GitHub-hosted `ubuntu-latest` (no self-hosted runner exists; dispatcher, 2026-11-28); wp1's Debian WSL (bayan-test01 only when wp1 is busy, owner 2026-11-28) runs the same steps by hand for T1 and when GitHub is down.
2. **Windows offload pass cache (plan 008 D).** Its key gains the host fingerprint and environment, and it comes under R9, R13, R17 and R24 (recommendation, not objected to).
3. **Merges to `dev`** may count a reused pass; the nightly shadow comparison (R15) and verification (R27) check every such reuse. `main`, release, nightly and laws never reuse (R13).
4. **Timing.** Task 1 measures dev as it is today (no longer the 2026-11-13 C# baseline): the key's cost and the reusable share on each host, wp1's Windows goldens included, and the recorded pass on wp1's Debian WSL.
5. **Program cache key.** It gained the C compiler's identity (its version output plus the path and write time of each word of its command that names a file; no size or hash, user 2026-11-13; plan 009, `docs/plans/2026-11-13-009-prebuilt-runtime-object.md`) in the self-hosted driver. That identity and the mtime-based script key stay as decided for the program cache; the result cache does not use them (R6).
6. **CI.** No reuse on hosted runners (recommendation, not objected to); the nightly job's store serves only its shadow comparison (R21).
7. **Toolchain roots** are identified by version output plus a content digest of their files (R5; Neon review, 2026-11-28, replacing names, sizes and modification times); the uncached gates are the backstop for a part with no file.
8. **Hybrid** (owner 2026-11-28, after the Neon review): declared inputs are the key on every host, `strace` verifies them nightly, and the bounded risk above is accepted.

## Open questions
- None.
