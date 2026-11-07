# 017 — Self-hosted compiler as the default `bayan`
Status: approved
Created: 2026-11-07

## Problem
Bayān builds itself (spec 012), but the `bayan` a user downloads is still the C# compiler (`release.yml` runs `dotnet
publish src/Bayan.Cli`). The self-hosted driver (`selfhost/driver/main.byn`) refuses twelve commands — `doctor`,
`format`, `audit`, `features`, `explain`, `test`, `mutate`, `new`, `init`, `dist`, `cache`, `clean` — and has no
`--json` diagnostics or build cache, so it cannot replace the C# binary. Until it does, every compiler change is written
twice and the language is not used to develop itself (user, 2026-11-07: 0.3.0's headline is the self-hosted default).

## Goals
- The release archives for 0.3.0 contain a `bayan` built from `selfhost/` (by the bootstrap chain), not from `src/`.
- Every command and flag of the C# CLI works in the self-hosted driver with the same output, exit code and files
  written, so a user cannot tell which compiler they run except by `bayan version`.
- The C# compiler stays in the repo as the oracle for the equivalence laws (L027/L028) for this release.

## Non-goals
- Deleting `src/` or the C# test suite (a later release, once the oracle is no longer needed).
- `bayan-lsp`: stays the C# binary in 0.3.0 and ships beside the self-hosted `bayan`.
- New commands or flags; changing any command's behavior (port, do not invent).
- Compile speed beyond R6's bound.

## User stories
- As a Bayān user, I want the released `bayan` to be written in Bayān, so that the language I use is the one its own
  compiler is written in.
- As a compiler maintainer, I want to change one compiler, so that a feature is not written in C# and Bayān both.

## Requirements
- R1 Each of `explain`, `features`, `version`, `help`, `clean`, `cache`, `new`, `init`, `doctor`, `audit`, `format`
  (incl. `--check`), `test` (incl. `--json`, `--changed`, `--base`, `--only`, `--run`, `--all`, `-v`, `--coverage`,
  `--mutate`), `mutate` and `dist` (incl. `--target`) runs in the self-hosted driver.
- R2 `--diagnostics json` and the build cache behave as in the C# CLI.
- R3 For every command in R1–R2, on the run/, diag/ and CLI test corpora, the self-hosted driver's stdout, stderr, exit
  code and written files equal the C# CLI's (L028 extended to every command).
- R4 Terminal style (color, `--ascii`, `--color`, progress lines) matches the C# CLI (spec 005).
- R5 The release workflow builds `bayan` from `selfhost/` via the bootstrap chain on every release target, and
  `bayan version` says which compiler built it.
- R6 The self-hosted `bayan` builds the self-hosted compiler no slower than 2x the C# CLI on the same host.
- R7 Memory and disk bounds of `docs/memory-leaks.md` hold for the self-hosted binary (its release gate passes).

## Acceptance criteria
- Given any command line in the CLI test corpus, when run with the C# CLI and with stage-2 `bayan`, then the outputs,
  exit codes and written files are equal (an L028 test per command).
- Given a `v0.3.0` tag, when `release.yml` runs, then every archive's `bayan version` names the self-hosted compiler.
- Given `bayan test lib/std/json` with stage-2 `bayan`, then 94 tests pass, as with the C# CLI.

## Law candidates
- L028 extended: for every command line in the CLI corpus, stage-2 output equals the C# CLI's (an amendment, not a new law).

## Decisions (agent, 2026-11-07, conservative; listed in the handoff Questions for the user)
- D1 `bayan-lsp` stays C# for 0.3.0.
- D2 Port order easiest first: explain, features, clean, cache, new/init, doctor, audit, `--json` diagnostics, format,
  test, dist, mutate, then the release switch.
- D3 No fallback: the self-hosted driver never shells out to the C# CLI for an unported command; the release switch
  waits until R1–R4 hold.

## Open questions
- None blocking; D1–D3 are recorded for the user to overturn.
