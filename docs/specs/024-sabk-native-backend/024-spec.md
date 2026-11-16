# 024 — Sabk, the native debug backend (phase 1)
Status: draft
Release: none yet (phase 1 ships no user-visible flag)
Sources: `docs/plans/2026-11-05-005-parking-lot.md` (B04), `docs/bayan-roadmap.md` (Next releases, item 5), `docs/bayan-milestones.md` (Target: zero dependencies)
Created: 2026-11-16

## Problem
Every Bayān build goes through a C compiler: the compiler writes C, then zig or a system `cc` turns it into machine code. That C step dominates debug-build time and keeps a C toolchain on the list of dependencies the zero-dependency target removes. The user scheduled an own debug backend on 2026-11-13 (B04, named sabk, سبك, "casting metal into a mould") and on 2026-11-16 chose to start it now, in parallel with spec 019, provided integrity is guaranteed.

Starting before 019a lands carries one risk: the frontend's lowered form may still change. Phase 1 therefore builds only the parts that do not depend on it.

## Goals
- Phase 1 produces, from Bayān code, a standalone instruction encoder, object-file writer and register allocator for arm64 macOS, each tested on its own.
- A small program assembled from sabk's own test input links with the system linker and the prebuilt runtime object, runs on arm64 macOS, and prints what it should.
- Nothing a user runs today changes: the C backend stays the only backend `bayan build` uses, and no existing test, golden case or law changes because of sabk.

## Non-goals
- Hooking sabk to the frontend's lowered form, and `bayan build --backend native`. Both wait for 019a; that is phase 2.
- x86_64 Linux (ELF), Windows, other targets. Phase 2 or later.
- An own linker. The system linker is used through the existing toolchain; an own linker is a later phase, and zig stays a dependency until then.
- Optimisation beyond what register allocation needs. Release builds keep the C path (and LLVM where it applies).
- Debug information (DWARF), unwinding tables beyond what the system linker requires to accept the object.
- Any change to the syntax, the frontend, the C backend, or the C# compiler (frozen as oracle at 0.3.2).

## User stories
- As the compiler maintainer, I want a native backend built in pieces that cannot break the compiler people use, so that it can start now without waiting for the frontend to settle.
- As a contributor, I want each piece testable alone with exact expected bytes, so that a regression shows up as a failing test, not as a crash in a built program.
- As a Bayān user (phase 2 onward), I want debug builds that skip the C compiler, so that the edit-build-run loop is faster.

## Requirements
- R1 Sabk is written in Bayān, as part of the self-hosted compiler's source, with no C# counterpart.
- R2 The encoder turns a described arm64 instruction (operation, registers, immediates, labels) into its 4-byte machine encoding for the instruction subset phase 1 lists; an instruction or operand outside that subset is refused with a diagnostic, never encoded wrongly.
- R3 For every instruction form in the subset, the encoder's bytes equal the bytes the reference assembler (the one in the current toolchain) produces for the same instruction. The expected bytes are taken from the reference assembler, never typed by hand.
- R4 Branches and address loads to labels are resolved when the label is in the same section, and emitted as relocations when it is not.
- R5 The object writer produces a Mach-O relocatable object (arm64) with text, constant data and writable data sections, a symbol table with local and external symbols, and the relocations from R4. The system linker accepts it without warnings.
- R6 The register allocator takes a function in sabk's own small test form (virtual registers, basic blocks, calls) and assigns arm64 registers and stack slots following the platform calling convention (arguments, results, callee-saved registers, stack alignment).
- R7 After allocation, no two values live at the same point share a register or stack slot, and every value read was written on every path reaching the read.
- R8 An end-to-end check assembles a small program from sabk's test form (one that calls into the runtime to print "Salam, world!" and returns an exit code), links it with the prebuilt runtime object through the system linker, runs it, and compares its output and exit code with the expected ones.
- R9 Sabk's tests run in the normal test suite on arm64 macOS and are skipped with a stated reason on other hosts; the full suite on wp1, wlt1 and the VM is unchanged.
- R10 Sabk's memory use is bounded per `docs/memory-leaks.md`: no unbounded recursion over input, every buffer sized from its input.
- R11 Every new diagnostic has a `diag/` case.

## Acceptance criteria
- Given the instruction subset table, when the encoder test runs, then each form's bytes equal the reference assembler's bytes (R2, R3).
- Given an instruction outside the subset, when it is encoded, then a diagnostic names it and no bytes are written (R2, R11).
- Given a test object with a cross-section call, a constant string and a writable global, when it is linked by the system linker, then the link succeeds with no warnings and the program runs (R4, R5).
- Given a set of test functions (straight-line, loops, calls, more live values than registers), when allocated, then the R7 checker finds no conflict and no undefined read, and the end-to-end program prints the expected output (R6, R7, R8).
- Given the suite run on wp1, wlt1 and the VM, when compared with the run before sabk, then the passed count changes only by sabk's own skipped tests and nothing fails (R9).

## Law candidates
- **Encoder agrees with the reference assembler:** for every instruction form in the subset and every operand value the test generator draws, sabk's bytes equal the reference assembler's bytes (R3).
- **Allocation is sound:** for every function the allocator accepts, no two simultaneously live values share a location, and no read sees an unwritten location on any path (R7).
- Phase 2 will add the integrity law the user's 2026-11-16 condition rests on: for every `run/` golden case, the native build's stdout and exit code equal the C build's.

## Decisions (user, 2026-11-16)
- First target: arm64 macOS (Mach-O); x86_64 Linux follows.
- Linking: the system linker through the existing toolchain; own linker later.
- Phase 1: encoder, object writer, register allocator, tested standalone; hookup to the frontend after 019a.
- Integrity: sabk sits behind `--backend native` only; the C backend stays the default until the phase-2 parity law holds for every `run/` case; sabk never changes the frontend; it lands through the usual 0 HIGH / 0 MEDIUM bar.

## Open questions
- None blocking phase 1. For `/plan`: the instruction subset (enough for the R8 program and the allocator's spills, calls and branches), where sabk's source lives in the self-hosted tree, and how the reference-assembler bytes are recorded so the tests do not need the assembler at run time.
