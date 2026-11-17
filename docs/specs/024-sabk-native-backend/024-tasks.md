# 024 — Tasks
Status: approved (spec and plan verified by Fable 2026-11-16; build started 2026-11-17)
Release: unscheduled
Sources: ./024-spec.md, ./024-plan.md
Plan: ./024-plan.md

Order: T1–T4 (encoder) → T5 (labels) → T6 (Mach-O) → T7–T10 (SIR, allocator, lowering) → T11 (checker) → T12–T13 (xUnit, e2e) → T14 (docs) → T15–T18 (laws). Phase 1 touches nothing under `src/driver/` or `src/emitter/`; `bootstrap/bayan.c`, every golden case and every law stay byte-identical. A missing std or runtime piece is a stop for a decision (plan, Risks), never a workaround.

## Encoder
- [ ] T1 `Inst` union and register/condition types — files: src/sabk/enc/inst.byn, src/sabk/sabk.byn (imports every submodule) — covers: R1, R2 — done when: every form of the plan's subset table has a variant, `bayan test --package src src/sabk` passes (it checks the whole package; `bayan check` on a package with no `main` reports BYN2014, and sabk gets no entry point in phase 1), and nothing outside `src/sabk/` imports it.
- [ ] T2 Recorder and encodings table — files: scripts/sabk/record-encodings.sh, scripts/sabk/record-encodings.test.sh, src/sabk/testdata/encodings.s, src/sabk/testdata/encodings.tsv, scripts/ci/script-tests.sh (unix list) — covers: R3 — done when: the script (bash 3.2) assembles `encodings.s` with `zig cc -c -target aarch64-macos`, reads `__TEXT,__text` with `otool -t`, writes the TSV (form, assembler text, hex) with one row per subset form plus the range-edge rows (registers 0–30, immediate edges); running it twice gives the same TSV; the `.test.sh` passes.
- [ ] T3 `encode` for the subset — files: src/sabk/enc/encode.byn, src/sabk/enc/encode.test.byn — covers: R2, R3 — done when: the test reads `encodings.tsv` and every row's bytes equal `encode`'s; break-test: flipping one bit field fails it.
- [ ] T4 Refusals — files: src/sabk/enc/encode.byn, src/sabk/enc/encode.test.byn — covers: R2, R11 — done when: an out-of-range immediate, an out-of-range branch offset and an unsupported operand each return `EncodeError` naming the mnemonic and operand, and no bytes are written; no new `BYN` code (plan, Diagnostics).

## Labels and object file
- [ ] T5 Labels and fixups — files: src/sabk/enc/labels.byn, src/sabk/enc/labels.test.byn — covers: R4 — done when: in-section `b`/`bl`/`b.cond`/`cbz`/`adr` targets are patched (forward and backward), every `adrp` and every cross-section or external target becomes a relocation record, and an unbound label is a typed error.
- [ ] T6 Mach-O writer — files: src/sabk/macho/writer.byn, src/sabk/macho/writer.test.byn — covers: R5, R10 — done when: `writeObject` emits `MH_OBJECT` with one `LC_SEGMENT_64` (`__text`, `__cstring`, `__data`), `LC_BUILD_VERSION` (macOS, minos 15.0), `LC_SYMTAB`, `LC_DYSYMTAB`, symbols ordered local / defined external / undefined with leading underscores, `r_extern = 1` relocations (`BRANCH26`, `PAGE21`, `PAGEOFF12`, `UNSIGNED`); the buffer is sized from its input; a unit test checks header, load commands and symbol order byte by byte against values read from a `clang -c` object of the same assembly (recorded like T2, never typed by hand).

## Test form and allocator
- [ ] T7 SIR — files: src/sabk/sir/sir.byn, src/sabk/sir/sir.test.byn — covers: R6 — done when: functions of blocks over virtual registers (`const`, `add`/`sub`/`mul`/`div`, `cmp`+branch, `call sym(args)`, `ret`), string constants and globals can be built and printed; the test builds the R8 program.
- [ ] T8 Liveness — files: src/sabk/ra/liveness.byn, src/sabk/ra/liveness.test.byn — covers: R6, R10 — done when: live intervals for straight-line, loop and call functions match expected sets in the test; the analysis is an iterative worklist with no recursion over input.
- [ ] T9 Linear scan — files: src/sabk/ra/linear.byn, src/sabk/ra/linear.test.byn — covers: R6, R10 — done when: AAPCS64 assignment (`x0`–`x7` args/results, `x9`–`x15` temporaries, `x19`–`x28` callee-saved only when used, `x18` never, values live across a call in callee-saved or spilled, `sp` 16-aligned); more live values than registers spill; more than 8 call arguments and an oversized frame are typed errors.
- [ ] T10 Lowering — files: src/sabk/ra/lower.byn, src/sabk/ra/lower.test.byn — covers: R6 — done when: allocated SIR lowers to `enc` instructions with prologue/epilogue (`stp x29, x30`, used callee-saved pairs, frame) and every instruction it emits encodes without `EncodeError`.

## Checker
- [ ] T11 Soundness checker — files: src/sabk/check/sound.byn, src/sabk/check/sound.test.byn — covers: R7, R10 — done when: forward dataflow (iterative worklist) over allocated code reports conflicts and reads of unwritten locations; it shares no code with `ra/`; it finds zero issues on every T7–T10 test function and finds each of two hand-corrupted allocations (shared register, read before write).

## Suite and end to end
- [ ] T12 `SabkTests` (a) and (b) — files: src/tests/SabkTests.cs — covers: R3, R9 — done when: (a) runs `bayan test --package src src/sabk` with the stage-2 driver, asserts 0 failed and a nonzero pass count; (b) re-runs the recorder and fails if the TSV differs; on non-arm64-macOS hosts each returns early with "sabk tests need arm64 macOS (024 R9)".
- [ ] T13 `SabkTests` (c), end to end — files: src/tests/SabkTests.cs, src/sabk/e2e.test.byn (or the module the plan's sabk test entry lives in) — covers: R4, R5, R8 — done when: a sabk entry writes `tmp/sabk/salam.o` (cross-section call to `_byn_print`, a `__cstring` "Salam, world!", a writable global), the test compiles `runtime/bayan-rt.c` with `clang -c -O2 -DBYN_NDEBUG`, links with `clang` with empty linker stderr, runs it, stdout is `Salam, world!` and the exit code is the expected one; `otool -l`/`nm -m` listings agree with a `clang -c` object of the same assembly.

## Docs
- [ ] T14 Docs — files: docs/memory-leaks.md, docs/bayan-roadmap.md, docs/bayan-progress-log.md — covers: R10 — done when: the memory-leaks sabk row (buffers sized from input, no recursion over input), roadmap item 5 "sabk phase 1 started (spec 024)", and a progress-log entry with the suite counts before and after on mb1 (R9: only sabk's own tests added or skipped).

## Laws (numbers after 019's L040–L045)
- [ ] T15 enact L046 Encoder agrees with the reference assembler — files: docs/laws/046-sabk-encoder-matches-assembler.md — covers: R3 — done when: drafted `proposed` with `/laws new` and the user has set `status: enacted`.
- [ ] T16 prove L046 via /prove — depends on T3, T12 — done when: the TSV test plus the generated sweep is tagged `Law=L046` and `laws-check.js --run` holds.
- [ ] T17 enact L047 Allocation is sound — files: docs/laws/047-sabk-allocation-sound.md — covers: R7 — done when: drafted `proposed` with `/laws new` and the user has set `status: enacted`.
- [ ] T18 prove L047 via /prove — depends on T11 — done when: `check` over every SIR test function and a generated set (straight-line, loop and call shapes, 0–40 live values) reports zero findings, tagged `Law=L047`, and `laws-check.js --run` holds.
