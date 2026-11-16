# 015 — Bayān tooling: replace Python, Deno and other non-Bayān scripts
Status: in progress (T1–T13, T16 landed: review-brief, plan-strings-check, install-textmate, gen-lowercase, stryker-to-quality, manifest-builds, quality-baseline, report-paths, coverage-missing and mutate-plan ported, Base64 added; T14, T15, T17 open)
Release: unscheduled
Created: 2026-11-02

Sources: the 2026-11-02 tooling brief (filed as 015 because 014 is the `Path` module; its decisions T1–T4 and port rules are in `docs/decisions/2026-11-02-002-tooling-port-rules.md`) and
`docs/bayan-library-tiers.md` (library placement; it wins over the tooling rules record). Decisions T1–T4 in that record are settled and not
re-proposed here. Porting starts after 012 passes (S1, which updates T3's "after 010"); the decisions are below.

## Problem
Building, testing and gating Bayān needs Python 3 (11 scripts plus 3 inline blocks), Deno (1 script and its test),
PowerShell (1 script) and Node (GitHub's artifact actions, the VS Code extension). Each is a runtime to install, pin and
audit, and none of them exercises Bayān. The user set a zero-dependency target on 2026-11-02 and asked that the repo's
tooling run on Bayān itself.

## Goals
- Every script in the repo is Bayān or shell, except the Keep list (R2).
- No CI step runs Python or Deno; only `upload-artifact`/`download-artifact` run on Node.
- Every library API a port adds lives in the module `docs/bayan-library-tiers.md` names, with tests.
- Each port matches the script it replaces on recorded inputs (R6) before the old script is deleted.

## Non-goals
- The C# compiler, its tests, Stryker (`scripts/quality/mutate.sh`) and `tools/Bayan.UnicodeGen` (C#): they leave with
  self-hosting (010–012), not here.
- Library scope beyond what a port needs (T1); `std.cli` derivation, `kit.tls`, native HTTP.
- Changing what any tool decides or prints. A port that finds a bug in its original records it in `work/todo.md` and
  matches the original first.

## Inventory
Found by extension, shebang, manifest (`package.json` only; no `deno.json`, `requirements*.txt` or `pyproject.toml`
exist) and every workflow step. `scripts/cleanup/` (19 one-off scripts, written for the user to run) is out of scope.

### Python (runtime: Python 3)

| File | Lines | What it does | Called from |
| --- | --- | --- | --- |
| `scripts/selfhost/mutation-exempt.py` | 26 | lines a `// mutation-exempt: Qnnn` marker skips, checked against the Questions | `guard.sh` |
| `scripts/selfhost/review-brief.py` | 68 | the reviewer brief for a 010 task (task text, C# ranges, files) — **done**: ported (T3) and deleted | `land.sh` |
| `scripts/selfhost/wave-brief.py` | 198 | the writer brief for a 010 task; reads `BAYAN_BASE`; records `q-ranges.tsv` under a lock — **done**: ported (T15 part 2a, without the lock) and deleted | `land.sh`, by hand |
| `scripts/selfhost/guard-checks.py` | 124 | guard checks A–E (oracle, stubs, ctx sections, gating Questions) over `git diff` — **done**: ported (T15 part 1) and deleted | `guard.sh` |
| `scripts/selfhost/coverage-gate.py` | 186 | changed-function coverage gate over `git diff -U0` and two JSON files — **done**: ported (T15 part 1) and deleted | `guard.sh` |
| `scripts/selfhost/quality-baseline.py` | 74 | `check`/`update` of `tests/quality-baseline.json` — **done**: ported (T12) and deleted | `mutate-batch.sh`, `land.sh`, `mutation.yml` |
| `scripts/selfhost/replay.py` | 68 | replays recorded runs (`runs.jsonl`: program, args, cwd, base64 stdin) under a mutant | `mutation-step.sh` (as `bayan mutate`'s test command) |
| `scripts/quality/stryker_to_quality.py` | 105 | Stryker JSON → `bayan-quality` JSON | `scripts/quality/mutate.sh` |
| `scripts/quality/cobertura_to_quality.py` | 105 | Cobertura XML → `bayan-quality` JSON | `scripts/quality/coverage.sh` |
| `scripts/ci/known-failures.py` | 59 | failed tests in `.trx` files vs `tests/windows-known-failures.txt` | `ci.yml` (Windows) |
| `scripts/unicode/gen-lowercase.py` | 76 | downloads `UnicodeData.txt`, regenerates the case tables in `runtime/bayan-rt.c` (rev 0015) — **done**: ported (T9) and deleted | by hand |
| inline in `scripts/selfhost/mutate-batch.sh:26` | ~60 | the group/file/filter plan: glob `src/**/*.byn`, brace-expand and match task patterns, shard | `mutate-batch.sh` |
| inline in `scripts/selfhost/mutate-batch.sh:100` | 12 | rewrites report paths repo-relative | `mutate-batch.sh` |
| inline in `scripts/selfhost/mutation-step.sh:25` | 1 | lists `binary<TAB>sites` from `manifest.json` | `mutation-step.sh` |
| inline in `scripts/selfhost/guard.sh:80` | 1 | coverage-report files missing from the changed list (`realpath` over the report's paths); found by the 2026-11-08 inventory | `guard.sh` |

### Deno, PowerShell, JavaScript, other

| File | What it does | Runtime |
| --- | --- | --- |
| `scripts/plan-strings-check.js` (128) + `.test.js` (156) | plan diagnostic strings vs `csharp/` and `docs/diagnostics/` — **done**: ported (T4) and deleted, Deno left | Deno |
| `editors/visualstudio/install-textmate.ps1` (8) | copies the TextMate grammar into `%USERPROFILE%\.vs\Extensions\bayan` | PowerShell |
| `editors/vscode/extension.js`, `package.json`, `.vscodeignore` | the VS Code extension | VS Code's Node |
| `docs/assets/artifact.js` | browser behaviour for generated HTML docs; synced from `~/.claude/tools/html/` | browser |
| `.config/dotnet-tools.json` (`dotnet-stryker`) | C# mutation testing | .NET |

### Shell (bash) — already in the target form
`scripts/ci/install-zig.sh`, `scripts/ci/install-dotnet.sh` (on `chore/ci-shell-checkout-dotnet`), `scripts/pinned-bayan.sh`,
`scripts/quality/{coverage,mutate}.sh`, `scripts/selfhost/{guard,land,mutate-batch,mutation-step}.sh`, and the 12 `*.test.sh`
files. `mutate-batch.sh` (127 lines) is the only one past the ~50-line rule; its logic is the inline Python above, and
the rest is sequencing.

### Workflow steps

| Workflow | Step | Today |
| --- | --- | --- |
| `ci.yml` | checkout, setup .NET | JS actions; shell on `chore/ci-shell-checkout-dotnet` (T4, held for 013 T19) |
| `ci.yml` | Install zig | shell |
| `ci.yml` | Script tests | bash; the tests call Python |
| `ci.yml` | Test, Test (Windows), Publish (NativeAOT), Smoke test | `dotnet` |
| `ci.yml` | Check known failures (Windows) | `python -I scripts/ci/known-failures.py` |
| `mutation.yml` | checkout, setup .NET | JS actions; shell on the T4 branch |
| `mutation.yml` | Install zig, Build, Mutate | shell / `dotnet`; Mutate runs `mutate-batch.sh` (Python inside) |
| `mutation.yml` | Merge | `python3 -I scripts/selfhost/quality-baseline.py` |
| `mutation.yml` | upload/download artifact | JS actions (Keep) |

## Classification

| Item | Class | Reason |
| --- | --- | --- |
| VS Code extension | Keep | VS Code loads only JS (R2) |
| `upload-artifact`, `download-artifact` | Keep | no supported shell equivalent |
| `scripts/pinned-bayan.sh`, `install-zig.sh`, `install-dotnet.sh` | Keep (shell) | run before any `bayan` exists |
| Stryker, `scripts/quality/mutate.sh`, `tools/Bayan.UnicodeGen` | Keep | C#-side tooling, leaves with self-hosting |
| `docs/assets/artifact.js` | Keep | runs in the reader's browser; owned by `~/.claude` (S11) |
| `guard.sh`, `land.sh`, `mutation-step.sh`, `coverage.sh`, the `*.test.sh` files | Shell | sequencing; their callers switch to the ports |
| `mutate-batch.sh` | Shell, after its inline Python moves into a Bayān port (`tools/mutate-plan.byn`) | |
| `install-textmate.ps1` | Bayān (S10) | 3 file copies; Windows then needs only `bayan` |
| All 11 `.py` files and the 3 inline blocks | Bayān | parsing (JSON, XML, Markdown task lists, diffs) and decisions |
| `plan-strings-check.js` (+ its test) | Bayān | reads C# sources and a plan, regex matching |

## Requirements
- R1 Every item classed Bayān runs as `bayan run tools/<name>.byn` (a package under `tools/` only when shared) under the
  pinned `bayan` (`scripts/pinned-bayan.sh`), never the working tree's.
- R2 After the last port, the repo holds no `.py`, Deno or PowerShell file and no `.js` outside the Keep list.
  `scripts/cleanup/` is exempt (amended 2026-11-08): each one-off there is deleted by its own cleanup run, so
  `scripts/cleanup/022-self-hosted-emitter-wp1.ps1` does not count against R2.
- R3 Each library API a port adds is in the module the tiers doc names, declares its effects, takes outside data as
  `Untrusted<T>`, calls libc only through `rt`, and has `std.test` tests and doc comments; nothing a port does not use.
- R4 No new public API is written before the user approves its shape (*Decisions* below records the approved ones).
- R5 A port replaces its script in one commit: callers (CI, shell, docs) switch, the old script and its test go.
- R6 A port lands only after its parity check (below) passes on every recorded input, the old script's test cases among them.
- R7 When the last user of Python, Deno or PowerShell goes, that runtime leaves CI and the setup docs in the same commit.
- R8 A port that would fetch over HTTPS calls `curl` through the process builtin and records a `work/todo.md` line (§12.5).
- R9 Ports land only through the normal branch flow, between 010–013 task merges, and change no language behavior,
  emitted C, goldens, `lex-diff` or 010 parity (addendum A1).

## APIs per port
Status: **Exists** = v0.1 builtin in the compiler today; **Spec-only** = in the language spec, not built; **New** = in
neither, settled under *Decisions*; **014-path** = specified by spec 014 (`Path`), built there.

| API | Module (tiers doc) | Status | First port |
| --- | --- | --- | --- |
| `args`, `i32 main(ReadOnlySpan<string> args)` exit code | builtins | Exists | all |
| `readText`, `readFile`, `writeFile`, `listDir` | builtins (`fs`) | Exists | all |
| `print`, `print(…, to: .stderr)`, `stdin` | builtins (`console`) | Exists | all |
| `run(program, args)` → `exitCode`, `stdout`, `stderr` | `std.process` | Exists | `guard-checks` |
| string members: `lines`, `parts`, `trimmed`, `position`, `replaced`, `joined`, slices | `core` | Exists (v0.1 set) | all |
| `List`, `Map`, stable `sort` | `std.collections` | Exists (in part) | all |
| `Path.combine`, `fileName`, `directoryName`, `isRooted`, `fullPath`, `relative` | `std.path` | 014-path (spec 014) | `review-brief` |
| environment variable read | `std.env` | New (S2) | `wave-brief` |
| regex match, search, find-all, replace, escape | `std.regex` | New (S3) | none yet (S13) |
| `Fs.fileExists`, `Io.createDirectory` (exist); `Fs.rename(path, to:)`, `Fs.copy`, `Fs.modified`/`setModified` (`Time`), `Fs.realPath`, `IoError.crossDevice` (fs slice, `feat/017`); `canonical` = `Fs.realPath` (S4, aligned 2026-11-08) | builtins (`fs`) | fs slice in flight; `normalize` (std path) only if a caller needs it (plan G4) | `gen-lowercase` (`rename`), `quality-baseline` (`realPath`) |
| recursive glob / walk; shell-style pattern match (`fnmatch`) | `std.fs` | Spec-only, API New (S5) | `mutate-plan` |
| `run` with `directory:`, `input:` bytes, `env:` over the inherited env | `std.process` | New (S6) | `replay` |
| JSON read (decode to a struct or a tree) and write (2-space indent, Python's `json.dumps(indent=2)` layout) | `std.json` | Spec-only (decoders, §11), API New (S7) | `quality-baseline` |
| `Base64.decode` | byte codecs, module Open (Q3) | Spec-only (J83) | `replay` |
| XML pull reader (.trx, Cobertura) | `kit.xml` | Not built (S9) | — |
| `f64` formatting matching Python `repr`, for ratios in quality JSON | `core` | New (S8) | `stryker-to-quality` |
| Unicode data lines → tables | `core` strings + `std.fs` | Exists | `gen-lowercase` |
| HTTPS fetch | `kit.http` | Spec-only; `curl` via `run` meanwhile (R8) | `gen-lowercase` |

## Port order
Easiest first; each New API arrives with the first port that needs it. Group by group, after 010 lands.

| # | Port (`tools/…`) | Replaces | Introduces |
| --- | --- | --- | --- |
| 1 | not ported | `mutation-exempt.py` | nothing: dead since Q910, removed by `scripts/cleanup/022-self-hosted-emitter.sh` (Q916 (a), 015 T2) |
| 2 | `review-brief.byn` — **done** (T3; `review-brief.py` deleted) | `review-brief.py` | uses `std.path` (014) |
| 3 | `wave-brief.byn` — **done** (T15 part 2a, without the Q1140 lock; `wave-brief.py` deleted) | `wave-brief.py` | `std.env`, `std.fs` exists |
| 4 | `plan-strings-check.byn` — **done** (T4; `plan-strings-check.{js,test.js}` deleted, Deno left) | `plan-strings-check.js` + test (Deno leaves, R7) | — |
| 5 | `guard-checks.byn` | `guard-checks.py` | `std.fs` pattern match |
| 6 | `quality-baseline.byn` | `quality-baseline.py` | `std.json` read/write, `fs` real path |
| 7 | `mutate-plan.byn`, `report-paths.byn`, manifest listing | the 3 inline blocks | `std.fs` glob/walk |
| 8 | `coverage-gate.byn` | `coverage-gate.py` | — |
| 9 | `stryker-to-quality.byn` | `stryker_to_quality.py` | `f64` formatting (S8) |
| 10 | `replay.byn` — skipped, gated on Q1141 (T16; `Base64` in `std.encoding` done) | `replay.py` | `run` with `directory:`/`input:`/`env:`, `Base64` |
| 11 | not ported (S9) | `known-failures.py`, deleted with the C# suite | — |
| 12 | not ported (S9) | `cobertura_to_quality.py`, deleted with the C# suite | — |
| 13 | `gen-lowercase.byn` — **done** (T9; `gen-lowercase.py` deleted) | `gen-lowercase.py` (Python leaves once the C# suite and its two S9 scripts go, R7) | `curl` shell-out (R8) |
| 14 | Bayān | `install-textmate.ps1` (PowerShell leaves) | per S10 |

The order of the remaining rows was revised on 2026-11-08 (plan *Revision 2026-11-08*, groups G1–G7): 14 first (S10),
then 13, then 9 and the manifest block, then 6 with the report-paths and `guard.sh:80` blocks, then `mutate-plan`, then
5, 8 and 3 together with `std.regex`, and 10 last, gated on Q1141.

## Decisions (user, 2026-11-02)
The questions S1–S12 and D1–D4 were answered on 2026-11-02. Signatures are the approved shapes; names follow the house
rule of no abbreviations. Nothing below is built before its first port (R4 now reads: built as approved here).

| # | Decision |
| --- | --- |
| S1 | **Wait for self-hosting (option B).** Library source, `import std.x` and new runtime builtins land after 012 passes (A1). Prep now: this spec, the CI chore (CI shell steps in `docs/decisions/2026-11-02-002-tooling-port-rules.md`), shell-only ports, parity baselines (`tests/parity/`). Revisit option A (a narrow A1 exception) if 011 + 012 run past 4 weeks; see *Timing* below. |
| S2 | `Untrusted<string>? Env.get(string name) uses env` (absent → `none`); no `set`. `run` takes `env:` (S6). |
| S3 | `std.regex`, RE2-style: classes, `\d\s\w`, anchors, groups, `?*+{m,n}`, alternation, lazy quantifiers; no backreferences or lookaround; linear time. Members as proposed: `Regex.parse(pattern) fails RegexError`, `matches`, `find → Match?`, `findAll`, `replaced(text, by:)`, `Match.group(i)`, `Match.span`, `Regex.escaped(text)`. |
| S4 | Path strings now, under `uses fs`. Aligned 2026-11-08 to the fs slice decided on `feat/017`: `Fs.fileExists` and `Io.createDirectory` already exist (`createDirectory` is idempotent, as .NET `Directory.CreateDirectory`); the slice adds `Fs.rename(path, to: dest)`, `Fs.copy`, `Fs.modified`/`Fs.setModified` (a builtin `Time` struct, i64 ns since the Unix epoch), `Fs.realPath(path)` (symlinks resolved; fails if the path is missing) and `IoError.crossDevice`. `canonical` is `Fs.realPath`; a pure lexical `normalize` in std path (not a builtin) is added only if a port canonicalizes a path that may not exist (plan G4, T11). T11 caller check (2026-11-17): `Fs.realPath` alone serves every caller, no `normalize`: `guard.sh:85` resolves `COVER` entries, which `guard.sh:54` filters to existing files (`[ -f "$f" ]`), and report paths of files the same run compiled; `mutate-batch.sh:128,134` resolves the repo root and report paths whose absence is already an error (`is no file under the repo root`, `:139`), so a `realPath` failure there keeps the run failing, naming the path; `quality-baseline.py:21` resolves paths of reports the same guard or batch run wrote, after `mutate-batch.sh` made them root-relative, so a missing one is a stale report and failing is the conservative outcome. T12 (2026-11-17) found recorded runs that pass missing paths and kept Python's result with a local `looseReal` in `tools/report-paths.byn` (Q1282). `IoError.alreadyExists` is added for the wave-brief lock (plan U4, Q1140). The same verbs later on capability `Dir` handles. Supersedes the 2026-11-02 shapes `rename(string from, string to)` and `canonical`. |
| S5 | `List<string> glob(string pattern) uses fs, alloc` in `std.fs` (`**`, `*`, `?`, `[…]`, `{a,b}`; sorted; `/` separators); `bool Glob.matches(string pattern, for string path) uses alloc` in `std.path` (no `fs`: it reads only its arguments), called `Glob.matches(p, for: path)`; `*` and `?` do not cross `/`, `**` does, the same dialect as `glob` (Q1283, decision 008). |
| S6 | Named arguments on `run`: `run(program, args, directory: string? = none, input: ReadOnlySpan<u8>? = none, env: Map<string, string>? = none)`. The environment is inherited; `env:` entries are added over it (user, 2026-11-02). A clean-environment switch (`inheritEnv: false`) is added only when a port needs one. No `Command` builder. |
| S7 | `std.json` in layers: a pull reader first, the tree (`JsonValue`: null, bool, number as `f64` plus its text, string, list, object in key order) built on the reader, `Json.encode(JsonValue v, i32 indent = 0)`; struct derivation later, on the reader. Decoded values are `Untrusted`. |
| S8 | Parity on float fields compares numbers, not bytes; `tests/quality-baseline.json` was to change once when its writer moved (`1.0` → `1`); the T12 port writes floats through `pyFloat`, which keeps `1.0`, so the file did not change. Measured on the pinned build: `5.0 / 6.0` → `0.8333333333333334`, `0.1 + 0.2` → `0.30000000000000004` (both as Python), `1.0` → `1`, `1e21` → `1e21` (Python `1e+21`). `1.0 → 1` is logged for round 4 (`docs/bayan-design-round-4-draft.md` §3). |
| S9 | `kit.xml` is not built (user, 2026-11-02): `known-failures.py` and `cobertura_to_quality.py` are not ported and are deleted with the C# test suite; R7 (no `python` in CI) holds from that commit. Both XML readers (`known-failures.py` over `.trx`, `cobertura_to_quality.py` over coverlet output) serve the C# suite, which self-hosting retires. |
| S10 | `install-textmate.ps1` is ported to Bayān (Windows then needs only `bayan`), using S4. |
| S11 | `docs/assets/artifact.js` is on the Keep list. |
| S12 | `Base64` lives in `std.encoding` with `Hex` (settles tiers Q3). |
| S13 | Superseded by Q916 (a) (015 T2): port 1 is not ported. `mutation-exempt` is ported to Bayān with string members only (`lines`, `position`, slices, `i64.tryParse`), not with `std.regex` and not to awk (user, 2026-11-02). `std.regex` (S3) arrives with the first later port that needs it. |
| D1 | The macOS 10x timing test stays as it is (green three runs in a row). |
| D2 | The .NET SDK stays pinned exactly (10.0.403, sha512) with a monthly reminder to bump the patch. |
| D3 | The `bayan new --ci github` template moves to `actions/checkout@v5` now: the scaffolder is CLI code that 010 does not port, so this is an A1 exception the user granted. |
| D4 | Script mode imports `kit` explicitly; no auto-import (tiers Q10 dropped). |

### Timing
010 finished on 2026-11-01 (`Status: done`). A1 holds until 012 passes, so porting waits for 011 (lowering and the C
emitter: about 4,580 C# lines, matched on 269 `run/` goldens; spec drafted, no plan yet) and 012 (driver and bootstrap;
not yet specified). 010 took 6 days for 40 tasks. Estimate: 011 in 7–10 days, 012 in 5–7, so porting starts around
2026-11-20 to 2026-11-23, about 3 weeks out, under the 4-week bound. Check on 2026-11-16: if 011 has not landed, put
option A back to the user.

## Parity plan
One check per port, run before it lands: old script and port on the same inputs, comparing exit code, stdout, stderr and
every file written.

| Port | Inputs | Compare |
| --- | --- | --- |
| mutation-exempt | not ported (Q916 (a)) | none |
| review-brief, wave-brief | each of the 40 tasks in `010-tasks.md` on the current spec files; `wave-brief.test.sh` cases | bytes |
| plan-strings-check | the default plan, `--all-help`, each code; the Deno test's fixtures | bytes; exit code |
| guard-checks | the last 10 landed 010 tasks (`<base> <task> <globs>` from `land.sh` history); `guard-checks.test.sh` | bytes |
| quality-baseline | `check` and `update` over the last mutation run's reports; `quality-baseline.test.sh` | output bytes; written baseline bytes (S8 may make floats normalized) |
| mutate-plan, report-paths, manifest | `--shard k/4` for k=1..4, `--files` cases from `mutate-batch.test.sh` | bytes |
| coverage-gate | merge bases of the last 10 010 landings with their reports | bytes |
| stryker-to-quality | `scripts/quality/fixtures/` plus one real Stryker report (Cobertura is not ported, S9) | JSON: bytes, or parsed-equal if S8 says so |
| replay | a recorded snapshot from `guard.test.sh`, with and without a mutant | exit code, stdout, stderr per record |
| gen-lowercase | `UnicodeData.txt` 16.0.0 (the script's `UNICODE_VERSION`) from `tmp/ucd-16.0.0/`; then a fresh download | regenerated `bayan-rt.c` bytes |
| install-textmate | a scratch `USERPROFILE` | file tree and bytes |

Baselines are recorded now, while the originals run (S1 prep): `tests/parity/<tool>/<case>/` holds a case's inputs and
the original's exit code, stdout, stderr and resulting files; `scripts/parity/run.sh <tool> [--impl '<port>']` replays
them (`--record` writes them, from the original only), and `scripts/parity/run.test.sh` in CI keeps them true against the
originals. A port passes `--impl "$(scripts/pinned-bayan.sh) run tools/<name>.byn"`; its commit deletes the original and
its `impl` line points at the port (R5). The last run's output goes into this spec's port record. `replay` (needs built
mutants), `gen-lowercase` (needs the Unicode download), the report-paths and manifest blocks (not runnable alone) and
`install-textmate` are recorded at their port.

## Acceptance criteria
- Given the repo after port 14, when searching by extension and shebang, then only the Keep list remains non-Bayān,
  non-shell (R2).
- Given CI after the last port and the C# suite's retirement (S9), then no step runs `python`, `python3` or `deno` (R7).
- Given a port, when its parity check runs, then every recorded input matches (R6), and its commit removes the old script (R5).
- Given a working tree whose compiler is broken, when a gate runs a port, then it runs the pinned build (R1).

## Law candidates
- For every ported tool and every recorded input, the port's exit code and outputs equal the original's (R6); holds
  only until the original is deleted, so a parity check, not a law.

## Open questions
- Conflicts found: the original brief's paths `GRAMMAR.md`, `HANDOFF.md`, `bootstrap/`, `npm run lsp`, `npm run grammar` and
  `tests/lsp-regress.js` do not exist here (the first two are `docs/bayan-grammar.md`, `docs/bayan-milestones.md`; the
  rest have no counterpart, so nothing to port).

## Port record
- T9 `gen-lowercase`: `tools/gen-lowercase.byn` replaces `scripts/unicode/gen-lowercase.py`; `PASS gen-lowercase 3 cases` (`cached`, `missing-begin`, `path-arg`); `scripts/unicode/gen-lowercase.test.sh` rewritten in bash (`PASS`).
- T10 `stryker-to-quality`, `manifest-builds`: `tools/stryker-to-quality.byn` replaces `scripts/quality/stryker_to_quality.py` and `tools/manifest-builds.byn` replaces the inline `python3 -I -c` manifest probes; `PASS stryker-to-quality 4 cases` (float fields parsed-equal, S8), `PASS manifest-builds 4 cases`.
- T12 `quality-baseline`, `report-paths`, `coverage-missing`: `tools/quality-baseline.byn` replaces `scripts/selfhost/quality-baseline.py`, `tools/report-paths.byn` and `tools/coverage-missing.byn` replace inline blocks in `guard.sh`/`mutate-batch.sh`; `guard.sh`, `land.sh`, `mutate-batch.sh` and `mutation.yml` call them through `scripts/bayan-tool.sh`; `PASS quality-baseline 25 cases`, `PASS report-paths 14 cases`, `PASS coverage-missing 12 cases`. Missing paths keep Python's `realpath` result (`looseReal`, Q1282); floats keep `1.0` (S8), so `tests/quality-baseline.json` is unchanged; `round4` half-even ties are not covered by a case.
- T13 `mutate-plan`: `tools/mutate-plan.byn` replaces the inline Python block of `scripts/selfhost/mutate-batch.sh` (which now holds no Python and calls it through `scripts/bayan-tool.sh`); `glob` in `std.fs` and `Glob.matches` in `std.path` added (S5, Q1283); `PASS mutate-plan 12 cases` (`--shard k/4` for k=1..4, `--files`). Task-file patterns match with the path-aware `Glob.matches` (`*` stops at `/`; `fnmatch`'s crossed it), which changes no recorded case. A task line's status mark must be one byte and line breaks are `\n`, `\r\n`, `\r` only. A missing pinned bayan now fails the run before any group (exit 3, the pin's message), not inside the first group.
- T15 (part 1) `guard-checks`, `coverage-gate`: `tools/guard-checks.byn` and `tools/coverage-gate.byn` replace `scripts/selfhost/guard-checks.py` and `scripts/selfhost/coverage-gate.py`; `guard.sh` calls them through `scripts/bayan-tool.sh`; `PASS guard-checks 6 cases`, `PASS coverage-gate 7 cases`; `guard-checks.test.sh`, `coverage-gate.test.sh`, `guard.test.sh` pass (`guard.test.sh`'s missing-CLI case now fails at the content checks, which also need the pin, before mutation). Regex via `std.regex`: each `re.M` is a per-line `find`; coverage-gate's `(?<!\w)…(?!\w)` is `Regex.escaped` + `findAll` with an ASCII `\w` check on each side, so a match overlapping an earlier rejected one is not tried; `os.walk` is `fs.glob` re-sorted to walk order (at most 64 levels deep). `\w \d \s \b` and whitespace split/strip are ASCII, not Unicode; `os.path.exists` is `Fs.fileExists` (a directory reads as absent); `specs.tsv` is read under `BAYAN_REPO_ROOT`; a citation line number over 15 digits reads as -1; every JSON syntax error reads `Expecting value` with a byte offset; a malformed report names `KeyError`/`TypeError` with approximate text, and functions are validated before the exempt FAIL items print; too few arguments or a missing spec row print one error line and exit 1, not a traceback. wave-brief, the Q1140 lock and `IoError.alreadyExists` stay open (T15 part 2).
- T15 (part 2a) `wave-brief`: `tools/wave-brief.byn` replaces `scripts/selfhost/wave-brief.py`; `land.sh` and `wave-brief.test.sh` call it through `scripts/bayan-tool.sh`; `PASS wave-brief 10 cases` (none re-recorded); `wave-brief.test.sh`, `land.test.sh` (its stub brief is now a stub `PINNED_BAYAN`) and `land-rows.test.sh` pass. Each `re.M` is a per-line `find`; `git cat-file --batch` is `Io.run` with `input:`. Differences from the Python: no lock around `q-ranges.tsv`: the table is read, then rewritten through a temp file in its directory and `Fs.rename`, so two briefs written at once can take the same range or drop a row (`wave-brief.test.sh` runs its three briefs one after another until part 2b); a questions file on a local branch that is not UTF-8 stops the run before anything is written (`wave-brief: OSError: …`, exit 1), where the Python read it with U+FFFD (`Io.run` fails `invalidUtf8` on such output); `specs.tsv`, `writer-protocol.md` and `bayan-cheatsheet.md` are read under `BAYAN_REPO_ROOT`; `\b \w \s \d` are ASCII; the task name is matched as text, not as a regex; a plain file under `docs/specs/` is skipped (`os.listdir` raised); an unknown task, a missing spec row, a task line with no files list and an unreadable file print one `wave-brief: <Error>: …` line and exit 1, not a traceback; the stdout line's list repr escapes only `\` and `'`. The Q1140 lock and `IoError.alreadyExists` stay open (T15 part 2b).
- T16 `Base64` in `std.encoding` (S12): `encode`, `decode` with `std.test` tests; `replay` stays skipped, gated on Q1141.
- T14 `std.regex` (S3): `lib/std/regex/regex.byn` (`Regex.parse` failing `RegexError` (`syntax`, `unsupported`, `tooLarge`), `matches` (whole text), `find`, `findAll`, `replaced(text, by:)` (literal replacement), `Regex.escaped`, `Match.group(i)`, `Match.span`), a Pike VM over the runes of UTF-8 text; `regex.test.byn` 106 pass, expected values recorded from Go `regexp` (RE2); backreferences, lookaround, flags, named groups and POSIX classes fail `unsupported`; `(a*)*b` and `(x+x+)+y` on 20000 bytes and `(a?){100}a{100}` run in linear time.
