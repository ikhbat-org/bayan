# Bayān hardening handoff
Status: received (2026-11-27); superseded for order and facts by plan 020
Release: unscheduled (report-only tooling)
Sources: the owner

For: the coding agent. Base: `dev`, 0.3.3-dev, revisions 0001–0024 applied. Written 2026-11-27.

This handoff adds checks that keep the compiler honest: determinism, differential testing, sanitizers, Fil-C, soundness corpora and fuzzing. It runs **beside** current work. It changes no language semantics, no diagnostics and no spec text.

---

## 0. Ground rules (read first)

1. **Additive only.** Do not change language behaviour, diagnostic codes or messages, existing goldens under `tests/cases/`, SPEC, GRAMMAR, DIAGNOSTICS or STATUS. Anything that would need a spec change is listed in §8 as a *proposed revision*. Do not apply those.
2. **Reuse before adding.** SPEC already names several of these tools: `bayan test --sanitize` (ASan/UBSan, §20), `bayan test --mutate` and `bayan mutate --binary` (§20), and the DIR interpreter (§24). Where H0 finds them built, the phases below use them. Where they aren't built, the phases use a script beside the CLI and never a new CLI flag.
3. **Own directories.** New work lives in:
   - `scripts/hardening/`: runners and installers.
   - `tests/hardening/`: corpora, mutants, snapshots, known findings.
   - `tools/hardening/`: Bayān tools (generator, mutator, C lint).
   - `docs/hardening.md`: inventory, how to run, phase status table.
   - `docs/hardening/findings.md`: the findings log (§5).
   - One new CI workflow (e.g. `.github/workflows/hardening.yml`, or the equivalent for whatever CI exists).
4. **Report-only.** Every new CI job is non-blocking (`continue-on-error` or equivalent). Only the user promotes a job to blocking.
5. **Stay out of in-flight work.** Never edit files touched by the current milestone wave. If a phase needs compiler code (only H1 might):
   - make it the smallest possible change,
   - leave it off by default,
   - put it in its own commit,
   - land it between waves, rebased on `dev`.
6. **Don't fix what you find.** A bug found here goes into the findings log with a reproducer under `tests/hardening/known/`, not into the main suite. The fix goes through the normal milestone workflow.
7. **Tooling language.** Use POSIX shell or Bayān. No Python, Node or Deno. Plain C only where a tool requires it (e.g. a sanitizer or fuzzer entry point), kept minimal. Tools that need Bayān syntax trees should use the self-hosted compiler's modules in `src/` (if they can be imported) or its `--diagnostics json` output rather than a second parser.
8. **Never slow the default path.** `bayan build`, `run` and `test` and the existing CI must not get slower or change output. Everything here is opt-in.
9. **Pin and checksum** every external tool (Fil-C, Wasmtime, qemu-user) in `scripts/hardening/versions.env`. Don't vendor binaries.

## 1. Goals and non-goals

**Goals:** catch miscompilation, unsoundness in the safety rules, undefined behaviour in emitted C, compiler crashes, and non-determinism, each with an independent oracle.

**Non-goals:**
- Byte-identical binaries across different C compilers. This is impossible and not needed.
- Making Fil-C the default compiler.
- Changing any user-visible CLI behaviour (see §8).

## 2. Oracles

| Oracle | Catches | Phase |
|---|---|---|
| Same source → byte-identical emitted C (any path, host, cache or parallelism) | Non-determinism, hidden state | H2 |
| Bootstrap fixpoint (stage 2 C == stage 3 C) | Self-hosting miscompiles | H2 |
| Diverse double-compiling (C#-built vs self-built compiler emit the same C) | Bootstrap-compiler bugs, trusting-trust | H2 |
| Same behaviour across C compilers × opt levels × modes | UB in emitted C, C compiler bugs, mode-dependent meaning | H3 |
| No C compiler diagnostic on emitted C (SPEC §24: such a diagnostic is an internal compiler error) | Ill-formed or suspicious emitted C | H3 |
| UBSan must stay silent | Any UB the emitter promised to define away | H4 |
| ASan + LSan clean | Memory errors, broken `dispose`/`defer` codegen | H4 |
| Fil-C clean (outputs, and the compiler itself built with Fil-C) | Memory-safety holes, borrow escapes, runtime bugs | H5 |
| Emitted-C invariants | Codegen drift away from the safety design | H6 |
| Must-reject corpus + safety mutants | Unsound checker rules | H7 |
| Crash fuzzing, formatter properties | Compiler crashes, hangs, formatter bugs | H8 |
| Random well-typed programs through H3–H5 | Miscompilation in uncovered shapes | H8 |
| Meaning-preserving transforms keep output | Miscompilation sensitive to layout or naming | H9 |

### Comparing runs
Used by H3, H5, H8 and H9:
- **Exact:** stdout, the exit status, and the termination signal if there is one.
- **stderr:** compare only the panic or trap message line. Strip error return traces (recorded in debug builds only, SPEC §8) and stack traces (addresses differ between compilers).
- **Fil-C traps:** these end the process with Fil-C's own message, not Bayān's. A Fil-C trap on a program whose golden doesn't trap is a finding.
- **Skips:** a golden the compiler rejects in some mode (e.g. `dbg(…)` is an error in release builds, SPEC §21.2) is skipped for that mode and listed in the run's report.

## 3. Phases

Each phase stands alone, so do them in order but stop anywhere. Each phase ends with:
- a row in the `docs/hardening.md` status table: phase, state, how to run, last result,
- findings logged,
- its CI job wired as report-only.

### H0. Inventory (read-only, no code changes)
Find and record in `docs/hardening.md`:
- **C compiler selection.** How the C compiler and flags are chosen (`Toolchain.cs`, self-hosted driver in `src/`). SPEC §24 plans TinyCC for debug where a CI probe passes, the system cc elsewhere, and clang or `zig cc` for release and cross-compiles: which of these is built? Is there already an override?
- **Emitted C.** Where it lands (`out/<mode>/<target>/c/`) and how `#line` is written.
- **Goldens.** How `run/` goldens record expected stdout, stderr and exit status.
- **Runtime C.** How the C runtime and helper sources are compiled.
- **Bootstrap stages.** Whether the C# CLI and the self-hosted driver can each build the self-hosted compiler. List the stage commands.
- **Built status of:**
  - `bayan test --sanitize`,
  - `bayan test --mutate` and `bayan mutate --binary`,
  - the DIR interpreter,
  - the `wasm32` and `linux-arm64` targets,
  - a jobs/parallelism option,
  - range analysis that removes checks.
- **CI.** Which CI system and runners exist (OS, arch).
- **Allocators.** Which of them never free on purpose (affects LSan). SPEC §23 makes scripts default to a never-freed arena, and `main` uses `General`.

### H1. C compiler override (only if H0 finds none)
- If no override exists, add internal dev knobs `BAYAN_CC` and `BAYAN_CFLAGS_EXTRA` (environment variables) to both the C# CLI and the self-hosted driver.
- Unset means behaviour is byte-for-byte unchanged.
- Include them in the cache key. SPEC §21.4 already says the key hashes the C compiler and flags, so verify that and fix only if it's missing.
- Document them in `docs/hardening.md` only (spec text is §8, R3).
- Test: unset → identical emitted C and binary hashes against `dev`.

### H2. Determinism and bootstrap
- `scripts/hardening/determinism.sh`:
  - Build every `run/` golden twice, in two different absolute paths, with a different `$BAYAN_CACHE` and, if H0 found a jobs option, different parallelism.
  - Diff the emitted C byte-for-byte.
  - Diff the binaries when the C compiler and flags are the same. If a binary differs only by an embedded build path (debug info), log it as a `nondeterminism` finding with that note.
- `scripts/hardening/fixpoint.sh`: stage 1 builds stage 2, and stage 2 builds stage 3. The C that stage 2 and stage 3 each emit for the self-hosted source must be identical.
- `scripts/hardening/ddc.sh`: compiler A is the self-hosted source built by the C# CLI; compiler B is the same source built by the self-hosted compiler. A and B compiling the self-hosted source must emit identical C.

### H3. Differential C compilers, opt levels and modes
`scripts/hardening/differential.sh` runs every `run/` golden across:
- each available C compiler: clang, gcc, `zig cc`, and TinyCC if H0 shows the toolchain uses it,
- -O0, -O2 and -O3 (TinyCC has no optimization levels; run it as-is),
- each built mode: `debug`, `safe`, `fast`.

Check:
- Results must agree with the golden under the comparison rules in §2. SPEC §17 and the overflow rule "must not change meaning with the build mode" make mode differences bugs.
- Any C compiler warning or error on the emitted C, under the flags the toolchain itself uses, is a finding.

Optional second tier, skipped when a tool is absent or H0 shows the target isn't built: `linux-arm64` under qemu-user, and `wasm32` under Wasmtime.

### H4. Sanitizers
If H0 shows `bayan test --sanitize` is built, run through it. Otherwise pass the flags via the H1 knobs.
- **UBSan:** `-fsanitize=undefined -fno-sanitize-recover=all` over all `run/` goldens. **Any report is a finding**, because SPEC §24 says the emitter defines everything C leaves undefined (`-fwrapv`, explicit checks, `-ffp-contract=off`).
- **ASan + LSan:** expect no leaks. A suppression file is allowed only for allocators that never free on purpose (H0), each with a reason; scripts are excluded from LSan.
- **MSan** (clang only) as an optional tier.
- **The compiler itself:** build the self-hosted compiler with ASan + UBSan and run the full test suite with it.

### H5. Fil-C
- `scripts/hardening/install-filc.sh`: install a pinned Fil-C release (0.687 as of 2026-11-27) from `github.com/pizlonator/fil-c/releases`, recording its SHA-256.
  - Fil-C runs only on Linux x86_64 and Linux ARM64.
  - Check that a release asset exists for the runner's arch before relying on ARM64.
  - On any other host, skip with a message; don't fail.
- **Outputs:** run all `run/` goldens built with Fil-C's compiler (`filcc`, through the H1 knob or an existing override). Compare under §2.
- **Compiler:** build the self-hosted compiler with Fil-C, then:
  1. run the full test suite with it,
  2. use it to compile the self-hosted source; that emitted C must equal what the normally built stage emits.
- **Runtime C changes:** small Fil-C compatibility tweaks are allowed only if behaviour under the normal compilers is unchanged (verify with H3). Otherwise log a finding.
- Keep Fil-C trap output raw for now. Mapping it to Bayān diagnostics is §8, R5.

### H6. Emitted-C lint
`tools/hardening/clint.byn` runs over `out/**/c/` and checks invariants derived from the emitter source. Each invariant cites the emitter code it comes from. Start with:
1. **`#line`:** every user statement's code is preceded by `#line N "file.byn"`; generated helpers carry none (SPEC §24, revision 0001).
2. **Bounds checks:** every span/array index goes through the check form from SPEC §21.3 (a compare and a branch to the shared `noreturn`, cold trap function for that check kind), unless it's in the elision log. The elision log exists only once range analysis is built (H0).
3. **Overflow:** checked integer arithmetic uses the `__builtin_*_overflow` family (SPEC §21.3). Wrapping (`+%`) and saturating (`+|`) forms are emitted only where the source uses them.
4. **Denylist:** constructs the agent derives from what the emitter must never produce. Document each entry with its reason.

### H7. Soundness corpus and safety mutants
- `tests/hardening/must-reject/index.md` lists, per safety rule, the **existing** `tests/cases/diag/` goldens that cover it. The rules: regions/borrows, `ref`/`out` escape, `unique`/`move`, mutation while borrowed, effects/capabilities, `Untrusted<T>` taint, typestate, `expects`/`requires`.
- Add new cases only for gaps, under `tests/hardening/must-reject/<rule>/`, each with an expected-code header. The runner asserts rejection with that code.
- `tools/hardening/mutate.byn` takes accepted `run/` programs and injects violations:
  - use after `move`,
  - storing a borrow into a longer-lived place,
  - writing while borrowed,
  - calling an effect outside `uses`,
  - using an untrusted value where a trusted one is required.
- **An accepted mutant is a finding.** Triage it by running it under ASan and Fil-C.
- This is separate from `bayan test --mutate`, which changes program logic to grade tests. These mutants attack the checker.

### H8. Fuzzing and random programs
- **Crash fuzzing:**
  - Byte- and token-level mutation of the `tests/cases` inputs, then `bayan check` under a timeout.
  - A crash, internal error or hang is a finding; diagnostics are fine.
  - Bounded to 30 minutes nightly; keep the corpus in `tests/hardening/fuzz-corpus/`.
  - This fuzzes the compiler. It is separate from user-level `fuzz` tests (SPEC §20, not in 0.3) and their `testdata/fuzz/`.
- **Formatter properties** (SPEC §21.5 already requires the first two):
  - formatting is idempotent,
  - rewriting an input form and then formatting again gives identical bytes,
  - formatted code gives the same diagnostics and the same run output.
- **Program generator** `tools/hardening/smith.byn` (Csmith-style):
  - Generates well-typed, deterministic, self-checking programs (they print a checksum).
  - Uses **built features only**, checked against STATUS. Start with integers, the wrapping and saturating operators if built, structs, functions, loops, spans, `switch` and error sets. Grow it as features land.
  - Every program goes through H3, H4 and H5.
  - Save failing seeds under `tests/hardening/known/`.

### H9. Metamorphic transforms
`tools/hardening/morph.byn` applies meaning-preserving transforms to `run/` goldens:
- rename locals,
- reorder top-level declarations,
- extract a block into a helper,
- insert dead code,
- inline a single-use `let`.

Output must match the golden under §2.

### H10. Self-measurement (report-only)
- **Mutation score:** if H0 shows mutation testing is built, measure the compiler test suite's mutation score with `bayan test --mutate` or `bayan mutate --binary`, and report the kill rate per module.
- **Emitted-C snapshots** for a curated set in `tests/hardening/c-snapshots/`, with `scripts/hardening/update-snapshots.sh`. Diffs are reported, never block.

### H11. Hardening flags evaluation (measure only)
Measure the cost of the following on the existing benchmarks and on binary size:
- PIE,
- full RELRO,
- `-fstack-clash-protection`,
- `-fcf-protection=full` (x86_64) or `-mbranch-protection=standard` (arm64),
- `_FORTIFY_SOURCE=3` for the runtime/helper C (and C dependencies once SPEC §18 is built).

Report the numbers. Changing the defaults is §8, R4.

### Gated: wait for the feature, then add
| Check | Waits for |
|---|---|
| Interpreter vs. compiled: same program through the DIR interpreter and through C (SPEC §24) | DIR interpreter built |
| Comptime vs. runtime: same function evaluated both ways, excluding `@fastMath` (SPEC §17) | `comptime` built |
| Hardened tests for `unsafe`/`extern`/`addCSource` code | SPEC §18 FFI built |
| OS sandbox and Fil-C runs for tier-3 generators | Generators (SPEC §12.5) built |
| TSan | `scope`/`spawn` built |
| Check-elision audit: re-insert removed checks as asserts | Range analysis built |
| `wasm64` in H3 | `wasm64` target (§8, R9) |

## 4. Cadence
- **Per PR:** nothing new, so no existing CI changes.
- **Nightly:** H2, H3, H4, H5, H6, H7, plus H8 fuzzing (30 min), H9.
- **Weekly:** longer fuzzing, H10, the H3 second tier.
- Prefer a Linux x86_64 runner and, if available, a Linux ARM64 runner (H5 needs Linux).

## 5. Findings protocol
`docs/hardening/findings.md`, one entry per finding:

```
HF-0001  <one-line summary>
  oracle:     H4 UBSan
  repro:      tests/hardening/known/HF-0001/
  severity:   miscompile | unsound | ub | crash | nondeterminism | flaky
  first seen: <commit>
  status:     open | fixed in <commit> | not a bug (<reason>)
```

- Reduce the repro by hand or with a script before logging.
- Don't open fixes from this work; the user schedules them.
- When a fix lands, move the repro into the main suite as a regular golden in the fix's own commit.

## 6. Done means
For each phase:
- its script runs locally with one command,
- its CI job is wired as report-only,
- `docs/hardening.md` shows how to run it and its last result,
- every failure it found is in the findings log.

## 7. Questions for the user (don't block on them; pick the safe default and note it)
1. Which CI runners can host the nightly jobs (self-hosted on Hetzner/Incus? an ARM64 machine)? Default: GitHub-hosted Linux x86_64.
2. Nightly time budget? Default: 60 minutes total.
3. When should report-only jobs become blocking? Default: never without the user's say-so.

## 8. Proposed revisions (do not apply; for round 4 or a numbered revision)
- **R1** Fil-C as an opt-in mode on `bayan test`, `run` and `build`: Fil-C on Linux, a Linux container/VM elsewhere. Spelling to decide: extend the existing `--sanitize` (e.g. `--sanitize filc`), or a separate `--hardened`.
- **R2** A manifest key in `package.byn`, e.g. `hardened: .never | .tests | .always`.
- **R3** Document `BAYAN_CC` / `BAYAN_CFLAGS_EXTRA` in SPEC §21.4 (if H1 added them).
- **R4** Default hardening flags for user binaries, based on H11's numbers.
- **R5** Fil-C traps reported in Bayān's runtime-trap format with `.byn` locations, in the trap code range planned for round 4's renumbering (9xxx).
- **R6** A Bayān-native audit mode on every target: generation counters on `unique` pointer handles, poisoned frees, arena canaries and quarantine.
- **R7** `bayan audit`: count `unsafe` per package, plus a `uses: unsafe` grant in `package.byn`.
- **R8** A lint for confusable identifiers, and NFC normalization in the lexer.
- **R9** A `wasm64` target (Memory64), kept beside `wasm32`, which stays the default.
- **R10** `bayan bug-report` (bundles a reproducer) and `bayan reduce` (automatic test-case reduction).
- **R11** OS-level sandboxing (Landlock/seccomp, macOS sandbox, AppContainer) for comptime and generators, on top of the language-level rules.
- **R12** Signed releases (Sigstore) and an SBOM in `BUILDINFO.json`.
