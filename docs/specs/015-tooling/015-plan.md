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
