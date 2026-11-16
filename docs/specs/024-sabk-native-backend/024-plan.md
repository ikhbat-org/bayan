# 024 — Plan
Spec: ./024-spec.md

## Approach
Sabk lives in its own directory, `src/sabk/`, as Bayān modules with `*.test.byn` unit tests run by `bayan test --package src src/sabk`; `src/sabk` imports every submodule, so that one command reaches all of them. Nothing in `src/driver/` or `src/emitter/` imports it in phase 1, so the driver's C (`bootstrap/bayan.c`), every golden case and every law stay byte-identical (spec goal 3). Phase 2 adds the import and `--backend native`.

Four modules, each testable alone, in build order:
1. `enc` — the arm64 encoder: a closed `Inst` union over the subset below, `u32 encode(Inst inst) fails EncodeError`, and a label table for in-section fixups.
2. `macho` — the Mach-O relocatable writer: sections, symbols, relocations, written to a byte buffer sized from its input.
3. `sir` + `ra` — sabk's own small test form (virtual registers, blocks, calls, returns) and a linear-scan allocator over it, followed by lowering to `enc` instructions with AAPCS64 prologue/epilogue.
4. `check` — the R7 soundness checker, written independently of `ra` (forward dataflow over the allocated code), so the allocator never grades itself.

Linear scan over graph colouring: a debug backend needs fast, predictable allocation, and linear scan is what debug backends use; spills are allowed to be poor.

Expected encoder bytes come from the reference assembler, recorded once into a committed table: `scripts/sabk/record-encodings.sh` calls zig directly (`zig cc -c -target aarch64-macos`) on `src/sabk/testdata/encodings.s`, reads the `__TEXT,__text` bytes back with `otool -t` (macOS only: `zig objcopy` rejects Mach-O, and wp1 is Windows), and writes `src/sabk/testdata/encodings.tsv` (form, assembler text, hex). The encoder test reads only the TSV. An xUnit test re-runs the recorder and fails if the TSV differs, so a hand-edited row cannot survive (R3).

## Tech / dependencies
- Bayān only for sabk (R1). No C# counterpart; the C# oracle stays frozen at 0.3.2.
- Assembler and linker: the existing toolchain lookup in `src/driver/cc.byn` (`$BAYAN_CC`, else `zig cc`, else `cc`/`clang`). Mac-local: `/Users/sy/.local/bin/zig`, Xcode `as`/`ld`.
- Runtime: the e2e test compiles `runtime/bayan-rt.c` itself with `clang -c -O2 -DBYN_NDEBUG`, not the cached zig object (`src/driver/cc.byn:178-190`, `src/driver/cache.byn:459`), so the link sees a system-toolchain object.
- Linker: the e2e test links with `clang` (which runs `/usr/bin/ld`) named explicitly, never `zig cc`: zig hides `ld`'s warnings, and R5 needs them visible. The R8 program calls `byn_print(byn_builtin_Stream w0, byn_str {ptr,len} in x1/x2)` (`runtime/bayan-rt.h:182`; a 16-byte struct goes in two registers under AAPCS64), then `byn_stdout_flush`.

## Instruction subset (phase 1)
Enough for the R8 program, the allocator's spills, calls and branches; 64- and 32-bit variants where marked.

| Group | Forms |
|---|---|
| Move | `movz`, `movk` (shift 0/16/32/48), `mov` reg (`orr` alias), `mov` to/from `sp` (`add #0`) |
| Arithmetic | `add`/`sub` imm12 (optional `lsl #12`) and shifted reg; `subs`/`cmp`; `mul`, `sdiv`, `msub`; `neg` |
| Logic | `and`/`orr`/`eor` shifted reg |
| Compare | `cset` (`csinc` alias), `csel` |
| Memory | `ldr`/`str` x/w unsigned imm offset; `ldur`/`stur` signed 9-bit; `stp`/`ldp` x pre/post-index and signed offset |
| Branch | `b`, `bl`, `b.cond`, `cbz`/`cbnz`, `br`, `blr`, `ret` |
| Address | `adrp` + `add` with `@PAGE`/`@PAGEOFF` (Mach-O syntax; `PAGE21`/`PAGEOFF12` relocs), `adr` |

Anything else is an `EncodeError` naming the mnemonic and operand; an out-of-range immediate or branch offset is an `EncodeError` too, never a truncated encoding (R2). The allocator refuses, as a typed error, a call with more than 8 arguments and a frame larger than the `stp`/`ldp` and `sub sp` immediates reach.

## Changes by area
- `src/sabk/enc/inst.byn`, `enc/encode.byn` — `Inst` union, register and condition types, `encode`. (R2, R3)
- `src/sabk/enc/labels.byn` — label binding, in-section fixups for `b`/`bl`/`b.cond`/`cbz`/`adr`; cross-section and external targets become relocation records. (R4)
- `src/sabk/testdata/encodings.s`, `encodings.tsv`; `scripts/sabk/record-encodings.sh` (bash 3.2) and its `.test.sh` (added to the unix list in `scripts/ci/script-tests.sh`). (R3)
- `src/sabk/macho/writer.byn` — `MH_OBJECT` header, one `LC_SEGMENT_64` with `__TEXT,__text`, `__TEXT,__cstring`, `__DATA,__data`; `LC_BUILD_VERSION` (platform macOS, minos 15.0, sdk 0, so `ld` does not warn about a missing platform); `LC_SYMTAB`, `LC_DYSYMTAB`; relocations `ARM64_RELOC_BRANCH26`, `PAGE21`, `PAGEOFF12`, `UNSIGNED`; string table; symbols ordered local, then defined external, then undefined, as `LC_DYSYMTAB` requires. Three Mach-O rules hold throughout: relocations are symbol-based (`r_extern = 1`), every `adrp` carries a relocation even to a local target, and C symbols carry a leading underscore (`_byn_print`). (R5)
- `src/sabk/sir/sir.byn` — the test form: functions of blocks, instructions on virtual registers (`const`, `add`/`sub`/`mul`/`div`, `cmp`+branch, `call sym(args)`, `ret`), string constants and globals. (R6)
- `src/sabk/ra/liveness.byn`, `ra/linear.byn` — live intervals (iterative, no recursion over input), linear scan over AAPCS64: arguments/results `x0`–`x7`, temporaries `x9`–`x15`, callee-saved `x19`–`x28` (saved in the prologue only when used), `x18` never touched (Apple reserved), `x29`/`x30` frame, `sp` 16-byte aligned, values live across a call kept in callee-saved registers or spilled. (R6, R10)
- `src/sabk/ra/lower.byn` — allocated SIR to `enc` instructions plus prologue/epilogue. (R6)
- `src/sabk/check/sound.byn` — the R7 checker: per-point map location → value, forward dataflow to a fixed point (iterative worklist), reports conflicts and reads of unwritten locations. (R7)
- `src/sabk/*.test.byn` — unit tests per module, including failure paths (refused instructions, out-of-range branches, too many live values → spills).
- `src/tests/SabkTests.cs` (xUnit, the normal suite) — (a) runs `bayan test --package src src/sabk` with the stage-2 driver and asserts 0 failed and a nonzero pass count; (b) re-runs the recorder and compares the TSV; (c) the R8 end-to-end: a sabk test entry creates `tmp/sabk/` with `Io.createDirectory` and writes `salam.o` with `Io.writeFile`, the test compiles `runtime/bayan-rt.c` with `clang -c -O2 -DBYN_NDEBUG`, links both with `clang`, asserts no linker output on stderr, runs the program, asserts stdout `Salam, world!` and the expected exit code. All three run on arm64 macOS only, as R9 says; elsewhere each returns early with "sabk tests need arm64 macOS (024 R9)". (R8, R9)
- `docs/memory-leaks.md` — sabk row: buffers sized from input, no recursion over input. (R10)
- `docs/bayan-roadmap.md` item 5 — "sabk phase 1 started (spec 024)".

## Data / interfaces
- `encode(inst: Inst) -> u32 | EncodeError`; `EncodeError { mnemonic: string, reason: string }`.
- `Section { name, bytes: List<u8>, relocs: List<Reloc>, align }`; `Reloc { offset, symbol, kind }`; `Symbol { name, section?, offset, external }`.
- `writeObject(sections, symbols) -> List<u8>`; tests write it with `Io.writeFile` into `tmp/sabk/`, created with `Io.createDirectory`.
- `allocate(f: SirFunction) -> Allocated` (a location per virtual register per interval, the frame size, used callee-saved set); `check(a: Allocated) -> List<Unsound>`.

## Diagnostics (R2, R11)
In phase 1 no user program can reach sabk, so every phase-1 refusal is a typed error (the spec's "diagnostic" in R2 reads as this in phase 1): sabk refuses with typed `EncodeError`/allocator errors returned to its caller, not with `BYN` diagnostics; a `diag/` case cannot exist for an error no `bayan check` input can produce. R11 therefore holds with zero new codes. Phase 2, when user code reaches sabk, maps these errors to codes in the backend range with `diag/` cases.

## Laws
Drafted as `proposed` with `/laws new` during `/tasks`; the user enacts:
- **Encoder agrees with the assembler** — proof: the TSV test over every form plus a generated sweep (registers 0–30, immediates at range edges) recorded the same way.
- **Allocation is sound** — proof: `check` over every SIR test function and a generated set (random straight-line, loop and call shapes with 0–40 live values), zero findings.

## Risks & mitigations
- **Frontend churn (019a).** Phase 1 has no dependency on the lowered tree; SIR is sabk's own. Phase 2 writes the lowered-tree → SIR step.
- **Mach-O details the linker tolerates but later tools do not** (symbol order, `n_sect`, alignment). Mitigation: link through `clang`/`ld` and also run `otool -l`/`nm -m` in the e2e test; compare section and symbol listings with a `clang -c` object of the same assembly.
- **Self-hosted compiler gaps** (e.g. byte-buffer writes, `u32` bit operations). Any missing std/runtime piece is a stop for a decision, not a workaround in sabk (spec non-goal: no frontend or runtime changes).
- **Test host spread (R9).** All sabk tests run on arm64 macOS only and are skipped elsewhere with the R9 reason, as the spec says, so the suite on wp1, wlt1 and the VM changes only by those skipped tests. Running (a) on every host would need a spec amendment; it is left for phase 2.
- **Recorder trust.** The TSV is regenerated from the assembler and checked by a test, so no expected byte is typed by hand (R3).
- No auth, input-handling, network or data-exposure surface.

## Coverage check
| Req | Covered by |
|---|---|
| R1 | Approach; all of `src/sabk/` is Bayān |
| R2 | `enc/encode.byn`, subset table, `EncodeError` |
| R3 | recorder script, `encodings.tsv`, TSV re-run test |
| R4 | `enc/labels.byn`, relocation records |
| R5 | `macho/writer.byn`, e2e link with no linker output |
| R6 | `sir`, `ra/liveness`, `ra/linear`, `ra/lower` |
| R7 | `check/sound.byn`, allocation-sound law |
| R8 | `SabkTests` (c) |
| R9 | `SabkTests` host guard; suite counts before/after |
| R10 | iterative algorithms, `docs/memory-leaks.md` row |
| R11 | Diagnostics section: no new codes in phase 1 |

No uncovered requirement.
