# 020 — Plan
Spec: ./020-spec.md

## Approach
Key choice. Three candidates were weighed:

| Candidate | Sound? | Hit rate | Verdict |
|---|---|---|---|
| (a) declared inputs per test | only while every declaration is complete; a missing one hides a failure silently | high | rejected as a key. Declarations survive only as *ignore* lists (env allow-list, volatile paths), each proven by a canary |
| (b) traced inputs: what the process tree really read, by content | by construction for files, absent paths and listings, given the standard argument below | high for docs-, goldens- and selfhost-only merges | **chosen** |
| (c) coarse key: whole tree + toolchain + env | yes for in-repo files | hits only an identical tree | not added: (b) already hits whenever (c) would. The one existing instance (`wp1-test.sh`, plan 008 D) is tightened, spec Q2 |

Why (b) is complete: a deterministic process whose every consulted file, absent path, directory listing and environment value is unchanged makes the same sequence of reads and so the same result. The argument fails for inputs the trace cannot see (environment, clock, randomness, network, other processes), so those are handled by construction (scrubbed environment, R4) or by exclusion (R10, R11), and the claim is re-proved on every nightly by the shadow comparison (R15).

Mechanics. Everything is repo tooling in `scripts/selfhost/`, Python 3 and bash like its neighbours, so nothing depends on C# and it survives spec 019. One tool, `result-cache.py`, owns key, store, lookup, eviction and report; `shard-test.sh` calls it for a slice on a recording host.

1. **Unit** = one test class today, the unit `shard-test.sh` already packs and filters by (`FullyQualifiedName~Ns.Class.`). A recorded run starts one process tree per unit against the already-built test assembly (no build step, `MSBUILDDISABLENODEREUSE=1`, `DOTNET_CLI_USE_MSBUILD_SERVER=0`, so no pre-existing server process escapes the trace) and reads per-test outcomes from its TRX file, as `shard-test.sh times` does.
2. **Recorder** (Linux only in v1) = `strace -f` around the unit, logging file, process and network system calls. `ptrace` sees statically linked children and raw system calls, which an `LD_PRELOAD` shim would miss (zig's own binaries make raw calls on Linux). The parser turns the log into the R2 input list, drops paths the unit created first (R3), maps reads under a toolchain root to that root's identity (R5), and bars the unit on a network call, a write to a tracked file, or a volatile path off the list (R11).
3. **Run with reuse on**: compute the fingerprint once; for each asked unit, `lookup`; hits are reported and not started; misses on admitted or candidate units run recorded, one process each; barred units run together in the normal shared process, exactly as today. A sample of hits is rerun (R16). Reports are merged into the existing `summary`.
4. **Nightly shadow**: the full tier on the VM runs everything as today, then calls `lookup` for every unit against the tree it ran and compares (R15). It costs lookups only.
5. **Order of work**: T1 is a measurement and a go/no-go, not a build. Later tasks do not start if T1 fails its gate.

T1 gate (on bayan-test01, numbers reported to the user before T2): strace present and permitted under the `bt` systemd-run unit; the R19 canaries pass; wall time of one recorded full pass against the 2026-11-13 warm baseline; per-unit process start-up cost; and a replay of the last 200 merges to `dev` against the recorded input lists giving the share of unit seconds that would have been reused. Stop and report if recording a miss costs more than the reuse saves over those 200 merges.

Rejected: tracing inside the normal shared test process (reads cannot be attributed to a class when four classes share one process); recording on macOS or Windows without privilege (no mechanism known to work: `fs_usage` and DTrace need root, ETW file tracing needs administrator; to be confirmed in T1, spec Q1); a sandbox that denies undeclared reads (three per-OS implementations, and it is (a) with enforcement); storing results in the repo's `tmp/` (the VM slice directory `/home/bt/shard/<sha8>-<i>` is new on every run).

## Tech / dependencies
- Python 3 (standard library only: `hashlib`, `json`, `xml.etree`), as `scripts/ci/known-failures.py` and `scripts/selfhost/coverage-gate.py`. 3.12.13 on mb1 (read 2026-11-13); the VM's version is read in T1.
- `strace` on bayan-test01: **not verified**. It is not installed on mb1 (macOS, not applicable). T1 reads `strace -V` on the VM and confirms the options it needs exist there (`-f`, `-o`, a syscall selection that includes directory reads, and path decoding of file descriptors) with the R19 canaries, before any option is written into a script. If the VM's `kernel.yama.ptrace_scope` forbids tracing children, T1 reports it and stops.
- `git` for the tracked-file list and clean-tree check.
- No new package, no change to `tests/Bayan.Tests/Bayan.Tests.csproj` (xunit 2.9.3, Microsoft.NET.Test.Sdk 17.14.1, xunit.runner.visualstudio 3.1.4, read from the project file 2026-11-13).
- zig: the pinned version from `scripts/ci/install-zig.sh`; its identity enters the fingerprint through `zig version` and the root digest.

## Changes by area
- `scripts/selfhost/result-cache.py` (new) — sub-commands `fingerprint`, `parse-trace`, `lookup`, `store`, `sample`, `shadow`, `evict`, `stats`, `clean`, `bar`, `admit`. Key and lookup (R2, R3, R5, R7, R8), outcome rule (R9), admission count (R10), barring (R11), integrity (R17, R20), store layout and bounds (R21, R22), listing and emptying (R23), report lines (R24).
- `scripts/selfhost/result-record.sh` (new) — runs one unit under the recorder with the scrubbed environment (`env -i` plus the allow-list), leaves the trace and the TRX for `parse-trace`; refuses on a host whose canaries have not passed (R1, R4, R12); on failure reruns the unit once unrecorded and reports that result (R26).
- `scripts/selfhost/result-cache.tsv` (new) — the human-kept lists, one kind per row with a reason column: `env` (allow-listed variables), `volatile` (system paths ignored), `root` (toolchain roots), `never` (never-cache units). A row without a reason is refused. Its digest is part of every key (R4, R8, R11).
- `scripts/selfhost/result-cache.test.sh` (new) — offline tests in the style of `shard-test.test.sh`: lookup hit and every single-change miss (R7, R18), poisoning table (R20), corrupt and unknown-version entries (R17), failure/skip/timeout never stored (R9), admission and barring (R10, R11), eviction to the cap and staging sweep (R22), report text (R24), switch off (R25), gate guard below (R13). Trace parsing is tested from recorded trace files kept under `tests/cases/result-cache/` so it runs on macOS too.
- `scripts/selfhost/result-canary.test.sh` (new, Linux only, skips with a message elsewhere) — the R19 canary table: small shell and C programs that read, exec, probe an absent path, list a directory, follow a link, and do each through a child, a grandchild and a zig-built static child; each must appear in the parsed record. Writes the host's "recorder proven" marker that `result-record.sh` requires (R12, R19).
- `scripts/selfhost/shard-test.sh` — for the `vm` host only and only when the switch is on: after packing, each vm slice runs `lookup`, starts hits' sample and the misses through `result-record.sh`, runs barred units in one normal `dotnet test` as today; `merge` adds the reused/run counts and the per-unit reuse lines to `summary` (R14, R16, R24, R25). `shard-test.test.sh` gains the merge and dry-run cases.
- `scripts/selfhost/preflight.sh`, `scripts/selfhost/test-map.tsv` — not changed. Selection hands a class list to the run; the cache receives that list and never reads the map (R14). A test in `result-cache.test.sh` asserts `result-cache.py` does not open `test-map.tsv`.
- `scripts/selfhost/pre-push-laws.sh`, `.github/workflows/laws-nightly.yml`, `.github/workflows/release.yml`, `.github/workflows/ci.yml`, `scripts/release/` — not changed in behaviour. `pre-push-laws.sh` and the release scripts export the switch as off at their top; a test fails if any of these files, or `docs/laws/*.md` `check:` lines, sets it on (R13). Classes carrying `[Trait("Law", …)]` (34 files today) are barred by a scan at `fingerprint` time (R11).
- Nightly shadow — a step in the dispatcher's nightly VM run (`shard-test.sh run` followed by `result-cache.py shadow tmp/shard/<sha8>`): non-zero exit and a `SOUNDNESS:` line on any disagreement, and the unit is barred (R15). Where this nightly is scheduled is the dispatcher's (no cron exists in the repo for the VM today; T-last adds one line to the handoff, written by the dispatcher).
- `scripts/ci/known-failures.py` lists — read, not changed: every unit holding a listed test is barred (R11).
- `scripts/selfhost/wp1-test.sh`, `wp1-test.test.sh` — pending spec Q2: the `tmp/wp1/cache/<tree>-<filter>` key gains the Windows host's fingerprint (dotnet, zig, OS build, read over the same ssh call) and the `cached:` line gains the recorded date (R7, R24 applied to the existing cache).
- `src/Bayan.Backend.C/Toolchain.cs` (key at line 238), and its port in `selfhost/driver/` (file located in T1, not guessed here) — pending spec Q5: the program cache key gains the C compiler's version output, probed once per process. Law L028 (driver equivalence) and the bootstrap fixpoint must still hold; `bootstrap/` is regenerated by `land.sh` as usual. Until Q5 is decided, program-cache files are ordinary content-hashed inputs (R6).
- `docs/laws/` — the six law candidates become `status: proposed` files at the next free numbers (the listing ends at 031 with 029 and 030 absent; the writer asks the dispatcher which numbers to take). Proofs are `result-cache.test.sh` and `result-canary.test.sh`, each with the law id literally in a test name and an explicit `check:` line (shell proofs, so the derived xunit check does not apply).
- `docs/memory-leaks.md` — a catalog row under *Tests and tooling* for the result store with its bound, and `bash scripts/selfhost/result-cache.test.sh` added to the *Release gate* block; `scripts/release/memory-gate.sh` and `memory-gate.test.sh` follow, since the test fails when they drift (R22).
- `docs/bayan-handoff.md` — the dispatcher's, not a writer's: how to switch reuse on, read the report, and clear the store.

## Data / interfaces
- Switches (new names): `BAYAN_RESULT_CACHE=off|on` (default `off`; anything else is an error, never "on"), `BAYAN_RESULT_CACHE_DIR` (default `$XDG_CACHE_HOME/bayan-results` or `~/.cache/bayan-results`), `BAYAN_RESULT_CACHE_MAX_MB` (default 512; 0 is refused, unlike the program cache, so the store is always bounded).
- Store layout: `<dir>/v1/CACHEDIR.TAG`, `<dir>/v1/units/<unit>/<entry id>.json`, `<dir>/v1/state.json` (admission counts, barred units with reason and date), `<dir>/v1/tmp/` (staging, swept after 24 h), `<dir>/v1/recorder-proven` (canary marker: strace version, kernel, date). At most 8 entries per unit, least recently used first out; writes go to `tmp/` then rename.
- Entry: `{ version: 1, unit, tool: <digest of result-cache.py + result-cache.tsv>, fingerprint: { os, osVersion, arch, cpus, roots: [{ path, version, digest }] }, env: { name: value }, inputs: [{ kind: file|exec|absent|listing|link, path, sha256 }], tests: [{ name, seconds }], recorded: { commit, date, host }, checksum }`. `checksum` is SHA-256 of the entry with the field empty. The entry id is SHA-256 of unit + tool + fingerprint + env + inputs.
- Paths: inside the checkout they are stored relative to the repo root, so a new slice directory still hits; outside it they are absolute.
- Lookup: for each entry of the unit, newest first: checksum, `tool`, fingerprint and env equal; then every input re-evaluated against the working tree (file digests memoised per run; tracked, unmodified files may take their digest from one `git ls-files -s` pass instead of a read, if T1 shows the mapping is exact). First entry that matches entirely is the hit. A dirty tree is allowed: inputs are compared by content, not by commit.
- Report lines, in `summary` and on the terminal: `result cache: N units (T tests) reused from cache, M units run, S reused units rerun as a sample, B barred`, then one line per reused unit: `reused <unit> (<n> tests) from <commit8> <date> <host>`; with the switch off: `result cache: off`.
- Sample (R16): units ordered by SHA-256 of commit + unit name; the first max(1, ceil(5%)) of the hits.
- Exit codes of `result-cache.py`: 0 ok, 1 soundness failure (R15, R16), 2 usage or unreadable store.

## Risks & mitigations
- **An input kind the trace misses** (a system call not selected, `io_uring`, a read by a process started outside the tree such as a compiler server). Mitigation: the canary table (R19) covers each kind and gates recording per host; no server reuse; the nightly shadow comparison (R15) catches what canaries do not, within a day. Residual: up to a day of exposure on `dev`, never on `main` or a release (R13).
- **Clock, randomness, load.** Invisible to the trace. Mitigation: three identical recordings before admission (R10), the never list, permanent barring on any disagreement. Residual: a unit that passes or fails by date; the never list is its only defence, so T1 greps the suite for clock use and lists the units it finds for the user.
- **Fewer units in one process changes interference** (the known `BAYAN_CACHE` process-wide flake). Recorded units run alone, so a failure that needs a neighbour does not occur there. Mitigation: gates in R13 always run the full mix; units known to change shared state go on the never list.
- **Recording slows or breaks tests** (ptrace overhead, timeouts). Mitigation: R26 rerun; T1 measures the overhead and stops the work if it eats the gain.
- **Toolchain root digest is not content** (spec Q7). Mitigation: stated assumption; roots are package-managed; R13 gates.
- **Program cache key and the compiler's identity** (spec Q5). Plan 009 (`docs/plans/2026-11-13-009-prebuilt-runtime-object.md`) added it: the compiler's version output plus the path and write time of each word of its command that names a file (a launcher such as `xcrun clang` and the compiler it runs), in the C# compiler and the self-hosted driver.
- **Imbalanced slices**: a vm slice whose units all hit finishes early while wp1 still runs. Accepted in v1; packing after lookup is a later change.
- **Store growth or corruption.** Cap, eviction, sweep, checksum, atomic rename (R17, R22), with the bound test in the release memory gate.
- **Trust.** The store is written and read by one user on one host; no network, no shared store, no CI writer in v1 (spec Q6). An entry is data, never executed.
- **Short life before spec 019.** Only step 1 of Approach (how a unit is started and its outcomes read) is specific to today's suite; spec Q4 lets the user defer.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Approach 1; `result-record.sh` |
| R2 | Approach 2; `result-cache.py parse-trace`; entry `inputs` |
| R3 | `parse-trace` created-first rule and tracked-write bar |
| R4 | `result-record.sh` scrubbed environment; `env` rows of `result-cache.tsv`; entry `env` |
| R5 | `fingerprint`; `root` rows; entry `fingerprint` |
| R6 | `Toolchain.cs` key change (spec Q5), else program-cache files as plain inputs |
| R7 | Data / interfaces, Lookup |
| R8 | entry `tool` digest and `version` |
| R9 | `store` outcome rule; test in `result-cache.test.sh` |
| R10 | `state.json` admission counts; `admit` |
| R11 | `parse-trace` bars; `never` and `volatile` rows; Law-trait scan; known-failures lists |
| R12 | `recorder-proven` marker; `result-record.sh` refusal; v1 host is `vm` only |
| R13 | switch exported off in gate scripts; guard test over workflows, scripts and law `check:` lines |
| R14 | `shard-test.sh` vm slice; `preflight.sh` and `test-map.tsv` untouched; no-read test |
| R15 | `shadow`; nightly step |
| R16 | `sample`; Data / interfaces, Sample |
| R17 | entry `checksum`; `lookup` rejection |
| R18 | single-change miss table in `result-cache.test.sh` |
| R19 | `result-canary.test.sh` |
| R20 | poisoning table in `result-cache.test.sh` |
| R21 | store location outside the checkout; no copy command exists |
| R22 | store bounds; `evict`; `docs/memory-leaks.md` and memory gate |
| R23 | `stats`, `clean` |
| R24 | report lines; `shard-test.sh merge` |
| R25 | `BAYAN_RESULT_CACHE`, default off |
| R26 | `result-record.sh` unrecorded rerun |
