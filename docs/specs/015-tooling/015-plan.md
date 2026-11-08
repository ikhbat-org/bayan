# 015 — Plan
Spec: ./015-spec.md

## Approach
Each port is one `tools/<name>.byn` program run by `scripts/bayan-tool.sh <name> [args]`, which execs the pinned
`bayan` (`scripts/pinned-bayan.sh`, R1/T2) as `bayan run tools/<name>.byn -- args`; exit code, stdout and stderr pass
through. Callers and the tool's `tests/parity/<tool>/impl` switch to `bash $ROOT/scripts/bayan-tool.sh <name>`, and the
port's commit deletes the original and its test, replacing the test with a shell test of the port (R5). A port lands
when `scripts/parity/run.sh <tool>` passes every recorded case (R6). Ports use only APIs that exist today; a port that
needs a New API (S2–S8) waits for the task that builds it, so the order below departs from the spec's table where a
port's needs are larger than the table says (measured 2026-11-06).

Each tool starts with `#!/usr/bin/env bayan`, so `bayan run` compiles it alone (script mode); without it every `.byn` in
`tools/` would build as one program (BYN2013). The launcher refuses a tool without that line, and drops PATH entries
under the caller's directory (parity stubs) before finding the pin.

Port 1 (`mutation-exempt`) is not ported: the script has had no reader since Q910 and is removed by
`scripts/cleanup/022-self-hosted-emitter.sh` (user decision Q916 (a)). `scripts/parity/run.test.sh` probes with
`review-brief` instead.

## Tech / dependencies
The pinned `bayan` (C# CLI at the `dev` tip). Exists today: `Io.readFile`/`writeFile`/`listDir`/`run` (no working
directory, no stdin, fails on non-UTF-8 output: Q1009, Q1065), `Env.get`, `Fs.fileExists`, `Path.*` (014), string
members, `List`, `Map`. Not built: `flock`, `run(…, input:, directory:, env:)` (S6), `std.json` (S7), glob (S5).

## Changes by area
- `scripts/bayan-tool.sh` (new) + `.test.sh` — the launcher (R1).
- `tools/review-brief.byn` — port 2; `land.sh`, `wave-brief.py` text and `wave-brief.test.sh` callers (R5, R6).
- `tools/plan-strings-check.byn` — port 4; `preflight.sh`, `wave-brief.py` text; `plan-strings-check.test.js` becomes
  `scripts/plan-strings-check.test.sh` (R5, R6, R7 for Deno once no other Deno user remains).
- Later, each with the API task it needs first: `wave-brief` (`flock`, stdin to `git cat-file --batch`), `guard-checks`
  (S5 match), `quality-baseline` (S7), `mutate-plan` (S5), `coverage-gate`, `stryker-to-quality` (S8), `replay` (S6,
  Base64), `gen-lowercase` (R8), `install-textmate` (S4, S10).

## Data / interfaces
`scripts/bayan-tool.sh <name> [args...]`: runs from the caller's directory; exit 2 on a missing or path-like name.

## Risks & mitigations
- A port reads repo files and runs `git` with argument lists only (no shell strings), as the originals do.
- Python's text-mode read turns `\r\n` and lone `\r` into `\n`; ports split the same way where the original does.
- Lint BYN2311 calls a `var` map that is written only by index "never reassigned"; `let` then fails BYN2104 (todo line).

## Coverage check
R1 launcher; R5/R6 per port task; R2/R7 at the last port; R3/R4 at each API task (none in the first two ports); R8 at
`gen-lowercase`; R9 holds (no compiler change in the first ports).

## Revision 2026-11-08: the remaining ports
Inputs: the inventory of `feat/015-tooling-ports` at 3a90aede (`tmp/015-inventory.md`, 2026-11-08) and the user's
decisions of 2026-11-08 (below, U1–U5). The section above stays as history; where the two differ, this section wins.

### What the inventory found
- T3 and T4 deleted their originals: `review-brief.py` and `plan-strings-check.{js,test.js}` are gone from `git ls-files`.
- S6 has landed here (T5, `byn_io_run_with`, `src/runtime/bayan-rt.h:464`) and is not on `dev`. No script uses a
  subprocess timeout or streaming.
- `std.json` exists only on `dev` (`lib/std/json/{reader,value}.byn`); this branch has no `lib/`.
- Missing on both branches: regex (S3), `Base64` (S12), glob/walk (S5), a file lock, append-mode open. The fs slice in
  flight on `feat/017` (not here yet) brings `Fs.rename(path, to: dest)`, `Fs.copy`, `Fs.modified`/`setModified` (a new
  builtin `Time` struct, i64 ns since the Unix epoch), `Fs.realPath` (fails if the path is missing) and
  `IoError.crossDevice`; D6 (`Io.run` `timeout`, `null` removes an `env:` variable, W0 status mapping,
  `.timeout(Millis)`/`.signaled(i32)`) follows it.
- Q1065 is still open: `byn_io_run_with` captures through `byn_process_finish` (`src/runtime/bayan-rt.c:3174`), which
  fails `invalidUtf8` on non-UTF-8 output and drops the exit code. A byte-exact `replay` needs a bytes-returning
  `Io.run`, which is new API (R4): Q1067.
- `Io.createDirectory` is idempotent (`Builtins.cs:378`, as .NET `Directory.CreateDirectory`; `byn_mkdir_all`,
  `src/runtime/bayan-rt.c:3050`, returns 0 on an existing directory), so "atomic creation of a lock directory" cannot
  be built on it as is: Q1066.
- Spec inventory was stale (line counts, a missing inline block, two deleted originals, `scripts/cleanup/` vs R2); fixed
  in the spec in this revision.

### User decisions 2026-11-08
| # | Decision |
| --- | --- |
| U1 | D6 builds on T5's `Io.run`, not a duplicate: T5 landed `env:`, `directory:`, `input:` here; D6 adds only `timeout`, the `null`-removes-variable rule on the existing `env:`, and W0's status mapping. If the two diverged, the 015 merge reconciles them into one `Io.run` signature. |
| U2 | Branch flow: (1) the fs slice (with D6/W0) lands on `dev`; (2) `dev` is merged into 015 and conflicts resolved; (3) 015 is merged into `dev` right away; (4) every later port goes on a short branch off `dev`, one per group, not on the long-lived 015 branch. (Not the D6 of the `Io.run` slice.) |
| U3 | Order: S10 now; gen-lowercase after the merge (temp file + `Fs.rename`, no `mv`); json-only ports after the merge; S4 (check each caller first; `realPath` covers existing paths, a pure lexical `normalize` in std path, not a builtin, only if a caller canonicalizes a path that may not exist); S5 glob; S3 regex and the three hard scripts, with coverage-gate's lookaround rewritten as two-step matches in Bayan code (no lookaround in S3); replay last, gated on Base64 in std (built in this plan) and byte-exact `Io.run` output, a listed skip until both exist. |
| U4 | wave-brief's lock and append: no new builtins. Lock: atomic creation of a lock directory holding the owner's pid, stale when `Fs.modified` shows it older than a fixed age, then taken over; `IoError` gets a distinct `.alreadyExists` variant if missing. Append: under the lock, read, write a temp file, `Fs.rename` (the writeReplacing pattern). If either fails in practice it is a Question to the user; A1 is never widened. |
| U5 | Spec fixes in the same change: wave-brief 198, coverage-gate 186, guard-checks 124 lines; add inline `guard.sh:80`; R2 exempts `scripts/cleanup/`; review-brief.py and plan-strings-check.js marked done. |

### Groups, in order
Each group after G0 is one short branch off `dev` (U2), landed through the normal flow (R9). "Leaves" is R7: the
runtime that goes when the group's last original is deleted; Python leaves only with the S9 deletions, so every group
but the last says "none".

| Group | Branch | Ports | Blockers (must exist first) | Parity (R6) | Callers that switch (R5) | Leaves (R7) |
| --- | --- | --- | --- | --- | --- | --- |
| G0 merge | `dev` → 015 → `dev` | none | fs slice and D6 on `dev` | the recorded parity tools (`tests/parity/`) still pass against their originals (`scripts/parity/run.test.sh`) | none | none |
| G1 S10 | 015 (now, before G0) | `install-textmate` | none: `Env.get`, `createDirectory`, `Path.combine`, `readFile`/`writeFile` exist here (inventory row; no `Fs.copy` needed) | scratch `USERPROFILE`: file tree and bytes, recorded at the port | `editors/README.md`, `editors/visualstudio/README.md`; delete the `.ps1` | PowerShell (R2 now holds for PowerShell outside `scripts/cleanup/`) |
| G2 gen-lowercase | off `dev` after G0 | `gen-lowercase` | `Fs.rename` (G0); `curl` through `Io.run` (R8) replaces `urllib.request.urlretrieve` (`scripts/unicode/gen-lowercase.py:13,51`); `os.replace` (`:52`) becomes write `.part` then `Fs.rename(…, to: path)` | `UnicodeData.txt` 16.0.0 from `tmp/ucd-16.0.0/`, then a fresh download: regenerated `bayan-rt.c` bytes | `gen-lowercase.test.sh`, handoff, rev 0015 text | none |
| G3 json-only | off `dev` after G0 | `manifest-builds` (inline `mutation-step.sh:25`), `stryker-to-quality` (S8), the inline JSON test probes (`quality-baseline.test.sh` ×7, `mutate-batch.test.sh` ×3, `guard.test.sh` ×2, `land.test.sh` ×1, `converters.test.sh` ×1) | `std.json` on `dev` (S7 layers: reader and `JsonValue`, `Json.encode(v, indent)`); S8 is measured, no new API | `scripts/quality/fixtures/` plus one real Stryker report (S8: parsed-equal on float fields); the manifest line: bytes | `scripts/quality/mutate.sh:57`, `mutation-step.sh:25`, `converters.test.sh`, each probe with the port it tests | none |
| G4 S4 realPath | off `dev` after G3 | `quality-baseline`, `report-paths` (inline `mutate-batch.sh:100-111`), `coverage-missing` (inline `guard.sh:80`) | `Fs.realPath` (G0); `std.json` (G3). First step: read each `realpath` call and record whether its path can be missing (`quality-baseline.py:21` resolves report entries and `root`; `guard.sh:80` resolves report paths; `mutate-batch.sh:100` rewrites report paths). Only if one can be missing does G4 add a pure lexical `normalize` to `std.path` (R4: its shape goes to the user first) | `check` and `update` over the last mutation run's reports; `quality-baseline.test.sh`; the two inline blocks: bytes, recorded at the port | `guard.sh:80,122`, `land.sh:92,99`, `mutate-batch.sh:100,126,133`, `mutation.yml:96-97`, the 4 tests, handoff | none |
| G5 S5 glob | off `dev` after G4 | `mutate-plan` (inline `mutate-batch.sh:26-84`) | S5: `List<string> glob(pattern) uses fs` in `std.fs`, pure `Glob.matches` in `std.path` (shapes settled, S5) | `--shard k/4` for k=1..4, `--files` cases from `mutate-batch.test.sh`: bytes | `mutate-batch.sh:26`; `mutate-batch.sh` is then sequencing only | none |
| G6 S3 regex | off `dev` after G5 | `std.regex` (S3), then `guard-checks`, `coverage-gate`, `wave-brief` | S3 as settled (no lookaround). coverage-gate's `(?<!\w)…(?!\w)` (`coverage-gate.py:46`) becomes `Regex.escaped(text)` found with `findAll`, each match then checked by hand for a `\w` byte before and after; `os.walk` (`:63`) uses S5 `glob`. guard-checks' `fnmatch` uses `Glob.matches` (G5). wave-brief's `fcntl.flock` on `a+` (`wave-brief.py:106-116`) becomes the Q1066 lock plus writeReplacing of `q-ranges.tsv` (temp file in the same directory, so no `crossDevice`); needs `Fs.modified`, `Fs.rename` (G0) and `.alreadyExists` if Q1066 keeps it | guard-checks: the last 10 landed 010 tasks and `guard-checks.test.sh`; coverage-gate: merge bases of the last 10 landings with their reports; wave-brief: each 010 task and `wave-brief.test.sh`; all bytes | `guard.sh:91,109`, `land.sh:32`, `preflight.sh`, `land-rows`, `parity/run.sh`, the three `.test.sh`, handoff | none |
| G7 replay | off `dev`, last | `Base64` in `std.encoding` (S12) now; `replay` only when Q1067 is answered | (a) `Base64.decode` (spec-only J83, small; built here with `std.test` tests, R3); (b) a bytes-returning `Io.run` form: Q1067, conservative answer = `replay.py` stays a listed skip and `mutation-step.sh:33,36` keep calling Python | a recorded snapshot from `guard.test.sh`, with and without a mutant: exit code, stdout, stderr per record | `mutation-step.sh:33,36`, `guard.test.sh:132-133` | Python, together with the S9 deletions (`known-failures.py`, `cobertura_to_quality.py` go with the C# suite) and `mutation-exempt.py` (cleanup 022, Q916 (a)) |

Not ported, unchanged: `known-failures.py`, `cobertura_to_quality.py` (S9), `mutation-exempt.py` (S13/Q916 (a)),
`scripts/cleanup/022-self-hosted-emitter-wp1.ps1` (out of scope; R2 now says so).

### The wave-brief lock (U4, Q1066)
Planned as the conservative default until the user answers Q1066: make a temp directory beside the lock path holding a
`pid` file, then `Fs.rename(temp, to: lockPath)`. On POSIX and Windows the rename fails when `lockPath` is a non-empty
directory (ENOTEMPTY/EEXIST), which is the "taken" signal; a lock older than a fixed age by `Fs.modified` is stale and
is renamed away then removed, after which the taker retries. Release: rename the lock away, then remove it. Caveat,
stated in Q1066: POSIX `rename` onto an *empty* directory succeeds, so the lock is only safe while the `pid` file is
written before the rename, which this order guarantees. Error mapping today: the runtime's `IoError` codes are
`notFound`, `permissionDenied`, `invalidUtf8`, `notADirectory`, `other`, `invalidInput`, `unsupported`
(`src/runtime/bayan-rt.h:430-436`), so a failed rename onto an existing directory would surface as `.other`, which the
lock cannot tell from a real failure; `.alreadyExists` (U4) is therefore still needed, mapped from EEXIST and
ENOTEMPTY on `Fs.rename`, and its addition is an approved R4 shape (U4), built in G6's first task.

### Risks (added)
- G0 may produce two `Io.run` shapes (T5's named arguments here, D6's on `dev`); the merge keeps one signature (U1)
  and its `run/` goldens; T5's tests are the oracle for `env:`/`directory:`/`input:`.
- `Fs.realPath` fails on a missing path; G4's first step decides whether any caller needs `normalize`, so no port
  guesses.
- Two-step lookaround in coverage-gate must match Python's `\w` (Unicode word characters); the parity cases (identifiers
  in C# and Bayan sources, ASCII) decide whether an ASCII check suffices; a difference is a `work/todo.md` line, and the
  port matches the original first (spec *Non-goals*).

### Coverage check (revision)
R1 holds (every port runs through `scripts/bayan-tool.sh`); R2/R7 at G7 with the S9 deletions; R3/R4 at `Base64`
(G7), `std.regex` (G6), `glob`/`Glob.matches` (G5), `.alreadyExists` and any `normalize` (G6, G4; Q1066, G4's first
step); R5/R6 per port in the table; R8 at G2; R9 by U2's branch flow.
