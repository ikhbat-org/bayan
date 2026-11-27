# Hardening handoff (written against 0.3.3), checked against `dev` at 0.4.1

Base checked: worktree `hardening-handoff` at 6a2ad3a4d (dev 36d332a87 plus the handoff). This is the first pass, so there is no earlier report to compare against.

## 1. Stale facts

| Handoff says | True now | Evidence |
|---|---|---|
| Base `0.3.3-dev` (l.3) | 0.4.1. The pinned driver at 36d332a87 prints `bayan 0.4.1 (selfhost)` | `VERSION:1`; `.cache/bayan/36d332a87…/bin/bayan version` |
| Revisions 0001–0024 applied (l.3) | Still correct: 0024 is the last revision | `docs/revisions/0024-numeric-conversions-and-dec.md`; `docs/bayan-roadmap.md:90` |
| The C# CLI and `Toolchain.cs` (l.74, 78, 90, 102) | The C# compiler was removed in 019b and archived at tag `csharp-final`. `Toolchain.cs` survives only as port comments in the driver | `AGENTS.md:6`; `docs/bayan-roadmap.md:92` (493d3fd78); `src/driver/cc.byn:1-3` |
| H1: add `BAYAN_CC` "if no override exists", in both CLIs | `BAYAN_CC` exists. It is read in one place and used by build, cache and doctor. There is only one CLI now | `src/driver/doctor.byn:206-231`; `src/driver/cache.byn:364,1132,1161`; `src/driver/cc.byn:250` |
| H2 DDC: "C#-built vs self-built" | Built as `scripts/ci/ddc.sh`: the frozen `csharp-final` C# build must reproduce `bootstrap/bayan.c`. It runs weekly | `scripts/ci/ddc.sh:2-15`; `.github/workflows/ddc.yml:11,31,65` |
| H2 fixpoint: stage 2 vs stage 3 | Built, as stage 1 vs stage 2 in `safe` and `debug`, plus a path and timestamp scan. It is law L027. The roadmap says stages 1, 2 and 3 emit identical C | `scripts/ci/fixpoint-check.sh:2-12`; `docs/laws/027-bootstrap-fixpoint.md:9-10`; `docs/bayan-roadmap.md:50` |
| "Bootstrap stages: list the stage commands" | Stage 0 is `cc` of `bootstrap/bayan.c`; stage 0 builds stage 1 with `build --mode safe --package src -o … src/driver` | `scripts/bootstrap-build.sh:2-8`; `bootstrap/README.md:3-27` |
| `--sanitize` "where built" | Named in the spec but not built in the self-hosted driver. The C# sanitizer path and its 5 tests were dropped in 019b | `docs/bayan-spec.md:2573,2597`; `src/driver/cache.byn:335`; `work/todo.md:1115`; not listed in `bayan --help` |
| `Untrusted<T>` taint as a full rule (H7) | Only the representation and the wrap/unwrap are implemented; "Sources are not yet wrapped". BYN8004 is spec-only, but the `Io.run`/`runBatch` sink check BYN2786 is built and has law L007 | `docs/bayan-spec.md:1816,1840`; `src/driver/diagdocs.byn:247`; `docs/laws/007-untrusted-never-reaches-a-command.md` (enacted) |
| TSan waits for `scope`/`spawn` | Still not built (§13 says "not in 0.x"). Spec 027 is being planned on an unmerged branch | `docs/bayan-spec.md:1708`; `docs/bayan-roadmap.md:98`; branch `docs/027-plan` |
| User fuzz "SPEC §20, not in 0.3" | The tag is "not in 0.4" now; `fuzz` is spec-only | `docs/STATUS.md:133`; `docs/plans/2026-11-05-001-v0.2a-loop.md:24` |
| H3: any C warning "under the flags the toolchain itself uses" is a finding | The toolchain passes `-w`, so those flags print no warnings. Warnings show only once `-w` is removed | `src/driver/cc.byn:163` |
| H6: "generated helpers carry none" (`#line`) | Generated code carries `#line N "main.c"`, which the emitter writes in place of `#line generated`. The spec text matches the handoff, not the emitter | `src/emitter/cprint/func.byn:16`; `src/emitter/cprint/program.byn:197-211`; `docs/bayan-spec.md:2764` |
| SPEC, GRAMMAR, DIAGNOSTICS, STATUS | `docs/bayan-spec.md`, `docs/bayan-grammar.md`, `docs/DIAGNOSTICS.md`, `docs/STATUS.md` | `ls docs` |
| Spec section numbers (§8, §12.5, §17, §18, §20, §21.2–21.5, §23, §24) | All still correct | headings at `docs/bayan-spec.md:1395,1665,2368,2382,2491,2590,2638,2645,2659,2734,2750` |
| 9xxx "planned for round 4's renumbering" | Revision 0017 assigns 9xxx to build, C backend and runtime traps; the codes have not been renumbered | `AGENTS.md:9` |
| Fil-C 0.687 | unverified (no network access was used) | — |
| Handoff file name | Repo layout names handoffs `YYYY-MM-DD-HHMM-topic.md`; this one has no HHMM | `~/.claude/docs/repo-layout.md:31` |

Unrelated stale items seen on the way: `~/.local/bin/bayan` reports `0.3.3-dev`; `tests/cases/README.md:18` still names `csharp/tests/Bayan.Tests/Golden.cs`.

## 2. H0 inventory, answered

**C compiler selection**
- A non-empty `$BAYAN_CC` wins. If it names an existing file, it is used whole (so a path with spaces works); otherwise it is split on spaces (`src/driver/doctor.byn:209-229`).
- Otherwise the driver uses `zig cc` if found, else `cc`, `clang` or `gcc` from PATH (`src/driver/cc.byn:67-82`).
- Cross targets need zig (`src/driver/cc.byn:138-143`).
- TinyCC is not built. It is still a plan (`docs/bayan-spec.md:2756`; `docs/bayan-roadmap.md:134,137`).
- Also built: a compile timeout through `BAYAN_CC_TIMEOUT_S`, default 600 s (`src/driver/cache.byn:1020-1024`).

**Flags**
- Every build: `-std=c11 -fwrapv -ffp-contract=off -w`.
- `debug` adds `-O0 -g -DBYN_DEBUG`; other modes add `-O2 -DBYN_NDEBUG` (`src/driver/cc.byn:154-173`).
- `-ffile-prefix-map=<dir>=.` is passed for the runtime and for `main.c` (`src/driver/cc.byn:199,220`).

**`BAYAN_CFLAGS_EXTRA` or equivalent**
- None. Grep finds it only in the handoff.
- Workaround with no compiler change: point `BAYAN_CC` at a wrapper script that adds flags. A single existing file is taken as the program (`doctor.byn:213-215`).
- The cache key hashes the compiler command, its identity, the flags and the runtime (`src/driver/cache.byn:304-330,374-377`).
- Whether the identity probe tells two wrappers apart is unverified, so give each configuration its own `BAYAN_CACHE`.

**Emitted C**
- Goes to `out/<mode>/<target>/c/` (`docs/bayan-spec.md` §21.4, Outputs, from :2645).
- `#line N "file.byn"` is written by `src/emitter/cprint/common.byn:254-261`; generated code is reset to `main.c` (`program.byn:197-211`).

**`run/` golden format**
- Inputs: `*.byn`, optional `*.args`, `*.stdin`, `*.pending`.
- Expected: `*.stdout`, optional `*.stderr` and `*.exitcode` (`tests/cases/README.md:12`).
- Per-case `// os:` lines (`scripts/ci/nightly-modes.sh:12`) and `// mode: debug` (`src/driver/golden.byn:3930`).
- Emitted-C digests: `tests/cases/emit/run-c.sha256` (378 lines) and `emit/modes/expected.{debug,safe,fast}.sha256`.

**Runtime C**
- `bayan-rt.h` and `bayan-rt.c` are written into the scratch directory, compiled to `bayan-rt.o` with the same compiler and mode flags, then linked (`src/driver/cc.byn:194-206,256-288`).
- The cached runtime object comes from `t9RuntimeObject` (`src/driver/cache.byn:378`).
- Runtime C tests: `runtime/tests/run.sh:2-15`, using `$CC`, else `cc`, else `zig cc`.

**Bootstrap**
- `bootstrap/bayan.c` is the C stage 1 emits (`bootstrap/README.md:3-27`).
- `bootstrap-check.sh` checks freshness and the chain from the previous commit (`scripts/ci/bootstrap-check.sh:2-17`; ci.yml:91).
- `fixpoint-check.sh` and `ddc.sh` are covered in §1.
- Law L045 (two bootstraps agree) is retired (`docs/laws/045-two-bootstraps-agree.md`).

**Built status of the features H0 asks about**

| Feature | Status | Evidence |
|---|---|---|
| `--sanitize` | not built | §1 |
| `test --mutate`, `--run` | built | `src/driver/main.byn:36-37` |
| `mutate --binary` | built | `src/driver/main.byn:38-39`; `src/driver/mutate.byn:188-198` |
| `--coverage` | built (`test` and `build`) but missing from `--help` | `src/driver/test.byn:94`; `src/driver/build.byn:102` |
| DIR interpreter | not built: `src/` holds only driver, lexer, parser, semantics, emitter and sabk | `AGENTS.md:6`; plan at `docs/bayan-spec.md:2754` |
| `linux-arm64`, `wasm32` | in the target table (`aarch64-linux-musl`, `wasm32-wasi`), cross-built through zig. Running their outputs is unverified | `src/driver/cc.byn:21-48` |
| `--jobs` | built for `test` and `mutate --binary` but missing from `--help`; law L041 says the job count does not change the result | `src/driver/test.byn:99`; `src/driver/mutate.byn:198`; `docs/laws/041-job-count-does-not-change-the-result.md` |
| Range analysis | not built ("After v0.0.1") | `docs/bayan-spec.md:2641` |

**CI**
- All runners are GitHub-hosted.
  - `ci.yml`: ubuntu-, macos- and windows-latest on push and PR (`.github/workflows/ci.yml:3-6,30`).
  - `laws-nightly`: daily cron at 04:00, ubuntu-latest plus ubuntu-24.04 and macos-15 (`laws-nightly.yml:8,25,91`).
  - `ddc`: weekly (`ddc.yml:11`).
  - `mutation`: dispatch only, cron commented out (`mutation.yml:12`).
  - `editor-gate`: ubuntu-24.04.
- No Blacksmith reference found. No self-hosted runner in any workflow. No Linux arm64 runner.
- wp1 and wlt1 are manual hosts for full, Windows and mutation runs; the Linux on wp1 is a Debian WSL (`AGENTS.md:11`).
  - `scripts/selfhost/wp1-test.sh:2-13` runs under Git Bash on wp1, or on wlt1 through `WIN_HOST`.

**Allocators that never free (affects LSan)**
- `General` never frees (Q31; arena per phase only partly done): `docs/memory-leaks.md:78`.
- `StrBuf` growth abandons old blocks: `docs/memory-leaks.md:82`.
- A caught panic skips `byn_arena_free`: `docs/memory-leaks.md:86`.
- A `List`'s last buffer is left allocated at exit: `docs/memory-leaks.md:176`.
- Scripts use a never-freed arena: `docs/bayan-spec.md:2744`.
- Expect LSan noise on every program until Q31 is done.

## 3. Per phase H1–H11

| Phase | State | What already covers it | What remains |
|---|---|---|---|
| H1 | partly done | `BAYAN_CC` (`doctor.byn:209`); the cache key includes compiler and flags (`cache.byn:304-330`); `BAYAN_CC` is documented in `docs/bayan-contributing.md:18` and `docs/diagnostics/BYN4001.md:3` | `BAYAN_CFLAGS_EXTRA` only. The `BAYAN_CC` wrapper (§2) makes it unnecessary for H3–H5. Leave it until the in-flight branches land (§5) |
| H2 | mostly done | L027 fixpoint; `ddc.sh`; L041 and L040 (jobs); L020 and L024 (emit digests, `golden.byn:2372`); the fixpoint path and timestamp scan; `-ffile-prefix-map` | A two-path, two-`BAYAN_CACHE` rebuild of the `run/` cases with emitted-C and binary diffs. No script does that today |
| H3 | not started | Mode variation exists only as `emit/modes` digests and the nightly coverage/mutate equivalence (`nightly-modes.sh:9-17`) | Cross-compiler, `-O` and mode runs against goldens; a warnings run with `-w` stripped |
| H4 | not started | `nightly-modes.sh` has no sanitizer mode (modes: coverage, mutate, ownership, libc, bound; `:41-43`). Debug builds carry the runtime owner checker (`byn_own`), and safe/fast must not (`nightly-modes.sh:18-19`; law L008). macOS `leaks --atExit` is a release check (`docs/memory-leaks.md:175-176`) | UBSan, then ASan with `detect_leaks` off or suppressions for the allocators in §2; build the compiler under ASan through `CC=` in `bootstrap-build.sh:4` |
| H5 | not started | nothing | All of it. Linux x86_64 only: GitHub ubuntu-24.04 or wp1 WSL |
| H6 | partly done | `libc-inventory-check.sh --emitted` (nightly libc mode, `nightly-modes.sh:20-24`); `printer-boundary-check.sh`; the ownership mode | The `#line`, check-form and overflow invariants. The bounds elision log cannot exist yet (no range analysis) |
| H7 | partly done | About 870 `diag/` cases (1742 files). By name: 74 move, 48 borrow, 48 unique, 60 escape, 10 Untrusted, 16 expects/requires; by content, 33 typestate. Typed corpus and no-panic laws L023 and L025 | The rule→case index, the gap cases and the mutant tool. The Untrusted mutants can only target BYN2786 sinks |
| H8 | partly done | No-panic laws L002, L018, L023 and L025 (`src/driver/nopanic-l0*.test.byn`). Formatter: L038 proposed, "Not proven" (`docs/laws/038-…:10-20`); L039 parity. `tools/Bayan.SyntaxFuzz/` is an untracked `bin/` leftover, not code | The crash fuzzer with a time budget, the proof of L038, and the program generator |
| H9 | not started | L038 compares emitted C after formatting, as a proposal | The morph tool |
| H10 | mostly done | `test --mutate` and `mutate --binary`; `mutation.yml` (dispatch only); `scripts/selfhost/mutate-batch.sh`; `tools/mutate-plan.byn`; `tests/quality-baseline.json`; L019 and L021; `scripts/quality/coverage.sh`. Emitted-C snapshots already exist as `emit/run-c.sha256` and `emit-c/` (23 classes) | A per-module kill-rate report. Do not add `c-snapshots/`, which would duplicate L024 |
| H11 | not started | nothing (no RELRO, PIE or FORTIFY hits) | Measurement only, through the `BAYAN_CC` wrapper |

## 4. Conflicts with repo rules

1. **Code and tool layout.**
   - `tools/` is the repo's Bayān tool directory: scripts are `tools/<name>.byn`, and a shared tool is a small package under `tools/` (`docs/decisions/2026-11-02-002-tooling-port-rules.md:34`; `docs/bayan-library-tiers.md:365`; precedent `tools/lex-diff/main.byn`). So `tools/hardening/` fits if it is one shared package; otherwise use flat `tools/clint.byn`, `tools/smith.byn` and so on.
   - Tools must run under the pinned `bayan` through `scripts/bayan-tool.sh`, never the working tree (decision 002 T2, `:11,19-22`).
2. **Shell versus Bayān.** Shell scripts use `set -euo pipefail` and must be ShellCheck-clean; anything past about 50 lines, or that parses, is Bayān (decision 002 `:32-33`). The handoff's rule 7 agrees. Existing Python (`scripts/ci/known-failures.py`, `scripts/quality/cobertura_to_quality.py`, `scripts/selfhost/replay.py`) is not a precedent.
3. **CI steps.** Checkout is a shell `git init`/`fetch` of `GITHUB_SHA` at an explicit depth, not `actions/checkout` (decision 002 T4, `:13,26`).
   - zig comes from `scripts/ci/install-zig.sh`. Pin Fil-C, Wasmtime and qemu the same way, with checksums.
   - The new workflow must not take `laws-nightly`'s 04:00 slot (`laws-nightly.yml:8`).
4. **Docs placement.**
   - The layout has no `docs/hardening.md` or `docs/hardening/`, and `.structure-audit.json` exempts only `docs/diagnostics/`.
   - Proposed:
     - the plan and status table in `docs/plans/2026-11-27-NNN-hardening.md` (`repo-layout.md:30`);
     - the findings log in `docs/audits/2026-11-27-hardening-findings.md`, beside the existing audits;
     - each new oracle as a `proposed` law in `docs/laws/` (`repo-layout.md:34`), which is how this repo records "must never break" checks (e.g. L027, L041).
   - Session log entry: `AGENTS.md:5`.
5. **Where it runs.** Full runs, Windows runs and mutation runs go to wp1 or wlt1, never the working machine (`AGENTS.md:11`). Script output prints counts and exceptions only, with logs in `tmp/` (`AGENTS.md:12`). Hardening scripts must follow both.
6. **Memory rules.** A walk, a child-process capture or a fuzz loop must read `docs/memory-leaks.md` first (`AGENTS.md:15`). A new long-running component needs a bound test in the release gate (`docs/memory-leaks.md:179-180`). The fuzzer and differential runner are tooling and not shipped, but their child captures should use the bounded `Io.run` with `timeout:` (`docs/memory-leaks.md:81`).
7. **Goldens and diagnostics.**
   - Every new diagnostic needs a `diag/` case, every runtime feature a `run/` case (`AGENTS.md:8`).
   - Golden-update commits must carry only expected files and name a cause (`scripts/ci/golden-commit-check.sh:2-14`).
   - The handoff's rule against new codes is consistent with this.
   - Moving a repro into the main suite (handoff §5) is a `run/` or `diag/` golden commit and must pass this check.
   - FREEZE.tsv and L043 mean exported cases are frozen.
   - `tests/hardening/` sits outside `tests/cases/`, so the golden runner and the check ignore it. That works, but the H7 must-reject runner must assert codes itself.
8. **Code ranges.** R5's 9xxx is the target range of revision 0017, which has not been renumbered (`AGENTS.md:9`). Any trap code needs a numbered revision (decision 002 `:41`).
9. **Bootstrap regeneration.** A driver change (H1, a sanitizer flag) forces `bootstrap/bayan.c` to be regenerated through `scripts/selfhost/land.sh` (`bootstrap/README.md:27`; `AGENTS.md:14`). That is more than the handoff's "smallest possible change".

## 5. Overlap with in-flight work

Unmerged branches with commits ahead of `dev` (all dated 2026-11-27). `chore/release-0.4.1` and `fix/audit-040-mediums-1` are 0 ahead.

| Branch (ahead) | Files outside goldens |
|---|---|
| fix/audit-040-highs (11) | `src/emitter/lowerassert.byn`, `lowerexpr.byn`, `lowerstmt.byn`; `src/semantics/calls4.byn`, `express.byn`, `express2.byn`; `src/driver/golden.byn`; `bootstrap/bayan.c`; `tests/cases/{diag,run}/…`; FREEZE.tsv; DIVERGENCES.tsv; `emit/run-c.sha256` |
| fix/audit-040-highs-2 (19) | the above plus `src/driver/bounds.byn`, `build.byn`, `cache.byn`, `diagdocs.byn`, `src/semantics/generics.byn`, `docs/bayan-spec.md`, `docs/bayan-questions.md`, `work/todo.md` |
| fix/audit-040-lows-2 (19) | `src/driver/cache.byn`, `commands.byn`, `main.byn`, `golden.byn`; `src/parser/*`; `scripts/ci/golden-commit-check.sh`, `script-tests.sh`, `diagnostic-codes*.test.sh`; `bootstrap/bayan.c` |
| fix/audit-040-lows-3 (31) | lows-2 plus `.github/workflows/ci.yml`, `src/lexer/*`, `lib/std/{fs,path,regex}`, `editors/*`, `scripts/release/{editor-gate,package}.sh`, `scripts/ci/known-failures.py` |
| fix/audit-040-docs-impl (7) | `src/driver/commands.byn`, `dist.byn`, `format.byn`, `golden.byn`, `main.byn`; `bootstrap/README.md`; `docs/bayan-spec.md`; `README.md`; `site/content/*`. Whether it touches `bayan.c` is unverified (filtered out of the listing) |
| docs/027-plan (4), docs/028-plan (5) | `docs/specs/027-concurrency/*`, `docs/specs/028-units-duration-uptime/*`, `docs/specs/README.md` |

Per phase:

| Phase | Collision |
|---|---|
| H1, H4-in-driver | `cache.byn` (highs-2, lows-2, lows-3), `cc.byn`/`doctor.byn` (none), `bootstrap/bayan.c` (all src branches) |
| H6 | reads the `src/emitter/lower*.byn` files that highs and highs-2 change, so its invariant citations would go stale |
| H7 index | lists `tests/cases/diag/`, which highs, highs-2 and lows-2 add to (e.g. `span-let-write`, `field-write-outside-indirect`, `top-level-statement-attribute*`) |
| H10 snapshots | duplicate `emit/run-c.sha256`, which highs and highs-2 change |
| New CI workflow | none, as long as `ci.yml` (lows-3) is not edited |
| Gated TSan row | tracks `docs/027-plan` |

H2, H3, H5, H8, H9 and H11 scripts touch no in-flight file.

## 6. Proposed integration order

Cost estimates are mine and unverified; the `run/` corpus is about 378 cases (`emit/run-c.sha256`).

| # | Phase (re-scoped) | Files to add | One command | Host | Cost | Can start now |
|---|---|---|---|---|---|---|
| 0 | H0 docs | `docs/plans/2026-11-27-NNN-hardening.md`, `docs/audits/2026-11-27-hardening-findings.md` | none | mac | under 1 h | yes |
| 1 | CC wrapper (replaces H1) | `scripts/hardening/cc-wrap.sh` (adds `$HARDEN_FLAGS`, optionally strips `-w`), `scripts/hardening/versions.env` | `BAYAN_CC=scripts/hardening/cc-wrap.sh …` | any | small | yes |
| 2 | H2 rebuild determinism (fixpoint and ddc exist) | `scripts/hardening/determinism.sh` | `BAYAN_EXE=… bash scripts/hardening/determinism.sh` | wp1 WSL; GitHub ubuntu-24.04 and macos-15 nightly | about 2× the `run/` build time; 20–40 min | yes |
| 3 | H4 UBSan, then ASan (LSan off until Q31) | `scripts/hardening/sanitize.sh`, `tests/hardening/lsan.supp` | `bash scripts/hardening/sanitize.sh --ubsan` | wp1 WSL, GitHub ubuntu | 30–60 min; compiler under ASan 1–2 h | yes |
| 4 | H3 compilers × `-O` × modes; warnings run | `scripts/hardening/differential.sh` | `bash scripts/hardening/differential.sh` | wp1 WSL (gcc and clang), mac (clang, zig) | 3 cc × 3 O × 3 modes ≈ 27× a `run/` pass; split into a weekly tier | yes |
| 5 | H6 lint (`#line`, overflow builtins, check form) | `tools/clint.byn` (or a `tools/hardening/` package) | `bash scripts/bayan-tool.sh clint out/` | any | small | yes; cite emitter lines after highs/highs-2 merge |
| 6 | H7 index plus gap cases | `tests/hardening/must-reject/index.md`, `<rule>/` | `bash scripts/hardening/must-reject.sh` | mac (selectors only) | small | yes; index read-only |
| 7 | H8 crash fuzz (extends L002/L018/L023/L025) | `scripts/hardening/fuzz.sh`, `tests/hardening/fuzz-corpus/` | `bash scripts/hardening/fuzz.sh --minutes 30` | GitHub ubuntu nightly | 30 min budget | yes |
| 8 | H5 Fil-C | `scripts/hardening/install-filc.sh` | `bash scripts/hardening/filc.sh` | Linux x86_64 only (wp1 WSL, GitHub ubuntu) | install plus 1–2 h for the compiler | yes; release asset and arm64 unverified |
| 9 | H9 morph; H8 smith; proof of L038 | `tools/morph.byn`, `tools/smith.byn` | `bash scripts/hardening/morph.sh` | GitHub nightly | medium | yes |
| 10 | H10 per-module kill rate (no new snapshots) | report only, from existing `mutate-batch.sh` output | `gh workflow run mutation.yml` | wp1 or wlt1 (`AGENTS.md:11`) | 6 h per shard (`mutation.yml:11`) | yes |
| 11 | H11 flag costs | `scripts/hardening/flags-cost.sh` | `bash scripts/hardening/flags-cost.sh` | wp1 WSL and mac | small | yes |
| 12 | `BAYAN_CFLAGS_EXTRA`, `--sanitize` in the driver | `src/driver/cc.byn`, `cache.byn`, a `bootstrap/bayan.c` regen through `land.sh` | — | — | — | **no**: wait for the audit-040 branches |

Workflow: one `.github/workflows/hardening.yml` with shell checkout, `continue-on-error: true`, scheduled away from 04:00 UTC.

## 7. Proposed revisions §8 check

| R | Status | Path |
|---|---|---|
| R1 Fil-C mode | Not covered. `--sanitize` is specified as ASan/UBSan only; no Fil-C text anywhere in `docs/` | `docs/bayan-spec.md:2573,2597` |
| R2 `hardened:` manifest key | Not covered (manifest §19.2 not read in full: unverified) | `docs/bayan-spec.md:2428` |
| R3 document `BAYAN_CC` | Partly decided. Q976 kept `cc.byn` on PATH only; Q1095 covers a `BAYAN_CC` that names no program. `BAYAN_CC` is documented in contributing and the BYN4001 page but not in spec §21.4. `BAYAN_CFLAGS_EXTRA` is not covered | `docs/decisions/2026-11-14-004-answered-questions.md:688,782`; `docs/bayan-contributing.md:18`; `docs/diagnostics/BYN4001.md:3` |
| R4 default hardening flags | Not covered | — |
| R5 Fil-C traps as 9xxx | Consistent with revision 0017's target areas; not renumbered | `AGENTS.md:9`; `docs/revisions/0017-addendum-a2-diagnostic-codes.md` |
| R6 native audit mode | Partly covered: `Handle<T>` generations (§9.6, "not in 0.4"); the debug-only runtime owner checker `byn_own` and law L008 | `docs/bayan-spec.md:1487`; `docs/laws/008-unique-never-aliased-at-runtime.md`; `docs/bayan-progress-log.md:180` |
| R7 `bayan audit` | `bayan audit` is specified and built. The `uses:` grants belong to the packages design. `uses: unsafe` is unverified | `docs/bayan-spec.md:727`; `bayan --help`; `docs/plans/2026-11-05-003-v0.3-packages.md:10` |
| R8 NFC and confusables | NFC is already decided and built (BYN0005), so that half is contradicted. Confusables are planned for package names only | `docs/bayan-spec.md:75`; `docs/diagnostics/BYN0005.md`; `docs/bayan-milestones.md:51`; `docs/plans/2026-11-05-003-v0.3-packages.md:19` |
| R9 wasm64 | Not covered; `wasm32-wasi` is planned and in the target table | `docs/plans/2026-11-05-004-v0.4-interop.md:21`; `src/driver/cc.byn:29,46` |
| R10 `bug-report` and `reduce` | Not covered | — |
| R11 OS sandbox | Not decided. The language-level comptime sandbox and deny-by-default script permissions exist; seccomp appears only as a measuring tool | `docs/bayan-spec.md:1650,2745`; `docs/decisions/2026-11-17-008-decisions-after-v0-3-2.md:44` |
| R12 Sigstore and SBOM | Planned in a different shape: signed publishes with a transparency log, and an SBOM from a separate `bayan dependencies --sbom` (CycloneDX), not inside `BUILDINFO.json` | `docs/plans/2026-11-05-003-v0.3-packages.md:17,21`; `docs/design/lessons-from-other-languages.md:130,134`; `docs/bayan-spec.md` §21.4 (BUILDINFO) |

Not reached: whether the `BAYAN_CC` wrapper's cache identity separates configurations, spec §19.2 and `docs/bayan-concurrency.md`, the files inside the 027/028 plans, running any cross-target output, Fil-C release assets, and timing measurements.
