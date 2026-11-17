# 008 — Decisions after the v0.3.2 tag: std.regex, Q1282, Q1283, 020 T2, T15, v0.3.2 release, 019 open questions

Status: decided (the user accepted every recommendation on 2026-11-17)
Date: 2026-11-17
Release: unscheduled
Sources: two independent Fable reviews (think workers, keys `fable-decisions-a` and `fable-decisions-b`), each given the claims and asked to check them against the code; the user's answer "go with the recommended".

## Summary

| # | Question | Decision |
|---|---|---|
| D1 | `std.regex` API (spec 015 T14, R4) | Approved as built. |
| D2 | Q1283, `Glob.matches` shape and `*` | `Glob.matches(string pattern, for string path)`, path-aware. |
| D3 | Q1282, `looseReal` | Keep the local copies; no std `normalize`. |
| D4 | Spec 020 T2 (`result-cache.py`) | Deferred until after 019a. |
| D5 | T15 under the C# freeze; BYN2022 wording | T15 goes ahead after T13; BYN2022 waits for 019. |
| D6 | v0.3.2 release (skipped by L028) | Re-tag v0.3.2 on `984aa479` (the user's step). |
| D7 | Spec 019 OQ3–OQ10 | Defaults for OQ3, OQ4, OQ5, OQ7, OQ9, OQ10; OQ6, OQ8 and the language server's part stay open. |

## D1. std.regex (`lib/std/regex/`)

Approved as built:
- `matches` must match the whole text, the same meaning as `Glob.matches`.
- `replaced(by:)` inserts its replacement literally, for good. Group expansion, if it is ever wanted, arrives as a separate member, so a `$` in an existing replacement never changes meaning.
- `^` and `$` match only at the start and end of the whole text. There is no multiline flag; `(?i)` and other flags fail with `RegexError.unsupported`, so adding them later changes no accepted pattern.
- `findAll` drops an empty match that abuts the previous match, as Go's `regexp` does.
- `escaped` quotes the 14 bytes `\.+*?()|[]{}^$`, as Go's `QuoteMeta` does.

Fable checked the scripts T15 ports. Every `re.M` use anchors per line, so line splitting plus `find` is equivalent. The one lookaround (`coverage-gate.py:46`) is a word boundary, which `\b` covers. No replacement uses a group reference.

## D2. Q1283: `Glob.matches`

- Signature: `bool Glob.matches(string pattern, for string path)`, called `Glob.matches(p, for: path)`. It keeps S5's order and passes BYN5004/BYN5006.
- `*` and `?` do not cross `/`; `**` does. This is the same dialect as `Fs.glob`, so `Glob.matches(p, for: x)` holds for exactly the paths `glob(p)` returns.
- Parity cost today: none. The only starred patterns in the `mutate-plan` cases are `src/parser/*.byn` and `src/semantics/*.byn`, whose directories have no subdirectories. Patterns without `/` match the basename, where the two dialects agree.
- If a task file ever needs a recursive `*`, the tool rewrites the pattern; std does not bend.

## D3. Q1282: `looseReal`

Keep the three local copies (`tools/report-paths.byn`, `tools/coverage-missing.byn`, `tools/quality-baseline.byn`). R6 bytes hold, and no std API is added. A missing path already fails one line later with a path-specific message. Promotion to `std.path` is reconsidered only if a caller outside these three tools appears.

## D4. Spec 020 T2

Deferred until after 019a. T1 did its job (go, with `strace -f --seccomp-bpf`; `tmp/unattended-1117/020-t1-report.md`).
- The plan's unit is a `dotnet test` class read from TRX, which 019a removes.
- A Bayān tool needs SHA-256 and XML, which std lacks; a Python tool conflicts with spec 015's direction (R7, tooling port rules).
- Decision 006 pulls a slice of 020 forward only if the post-019 suite exceeds about 45 minutes.

After 019a, 020 is re-planned in Bayān on golden-case units.

## D5. T15 and BYN2022

- The C# freeze (decision 006 §2, 019 R10) covers the expected outputs captured at the tag, not C# source. T15 adds one `IoError.alreadyExists` case; adding new cases is not a freeze breach. T15 goes ahead after T13. It stops if a `typed` or `emit` golden turns out to list the `IoError` cases.
- The BYN2022 wording fix (`work/todo.md`) rewrites existing `.diag` goldens, which the freeze exists to prevent. It waits for 019.

## D6. v0.3.2 release

The `release` job was skipped because L028 failed, so v0.3.2 has no GitHub release at all: no archives, no docs tarball, no `SHA256SUMS`. PDFs were never attached automatically; no workflow runs `docs-pdf.sh`. `fix/release-0.3.2-l028` (`984aa479`) is one test-only commit on top of the tag, and `VERSION` there is 0.3.2. Decision: the user moves `v0.3.2` to that commit (fast-forward `main`, re-tag, force-push the tag). This happens before 019 records the freeze commit. Compiler outputs are identical, since the diff touches a test skip list only.

## D7. Spec 019 open questions

- OQ1 is stale: the tag resolves. Its commit follows D6.
- OQ3, OQ4, OQ5, OQ7, OQ9 and OQ10 take the spec's defaults. OQ5 note: `tools/Bayan.UnicodeGen` generates `unicode-tables.byn` (Q1142), so regenerating those tables after 019b still needs .NET until it is ported.
- Still open, for the user:
  - OQ6: where the R27 job runs. The default adds a release-blocking hosted job.
  - OQ8: a bounded stdin read for the language server. The default adds a public runtime API, against Q1141's "no new API now".
  - The language server port: decision 006 places it in 019b; the spec places it in 019a.

## Noted, not decided

Recorded in `work/todo.md`:
- `tryReal` in the three `looseReal` copies swallows every `Fs.realPath` error, not only "missing".
- `looseReal` calls `Path.fullPath` first; if that folds `..` lexically, a symlink followed by `..` resolves differently from Python.
- T14 was built before T13, although `015-tasks.md` lists T14 "after: T13".

## Moved question entries

As they stood in `docs/bayan-questions.md` when answered.

| Q1282 | Spec 015 T12: `looseReal` beside `Fs.realPath` for report paths | see the entry | keep the local `looseReal`, which matches Python `os.path.realpath` on missing paths; no std `normalize`. | the user (designer) |
| Q1283 | Spec 015 T13: S5 `Glob.matches(pattern, path)` needs a particle | see the entry | T13 waits; nothing ported, `mutate-batch.sh` keeps its Python. | the user (designer) |

### Q1282

1278. **Spec 015 T12: `looseReal` beside `Fs.realPath` for report paths.** S4 records T11's caller check: `Fs.realPath` alone serves every caller. The T12 ports (`tools/report-paths.byn`, used by `coverage-missing.byn` and `quality-baseline.byn`) found recorded runs that pass a missing path (parity cases `report-paths/no-such-file`, `coverage-missing/absolute-path`), where Python's `os.path.realpath` resolves the existing prefix and keeps the missing rest. R6 asks for byte-equal output, so T12 added a local `looseReal` (`tools/report-paths.byn:20-41`): `Fs.realPath` when it succeeds, else the parent resolved and the last component appended. *Conservative option:* keep the local `looseReal`; no `normalize` in std path. The user decides whether a missing report path should fail instead (S4's reading), or whether `looseReal` belongs in std path.

### Q1283

1279. **Spec 015 T13: S5 `Glob.matches(pattern, path)` needs a particle.** S5 settles `bool Glob.matches(string pattern, string path)` in `std.path`. The naming checker rejects it in std source: `BYN5004: matches has 2 unlabeled parameters; give each but one a particle` and `BYN5006: path is a required parameter besides the object and needs a particle` (spec §10). The T13 writer proposes `Glob.matches(string pattern, for string path)`, called `Glob.matches(p, for: path)`; `from`, `at` and `by` also pass the checker. A second point for the same decision: S5 has `*` and `?` stop at `/`, while Python `fnmatch` (used by `mutate-batch.sh:26-84` and guard-checks) lets `*` cross `/`; the recorded `mutate-plan` parity cases (12, passing against the original) may need `**` where the original pattern has `*`. *Conservative option:* T13 waits for the shape; nothing is ported and `mutate-batch.sh` keeps its inline Python. The user decides the particle and whether S5 keeps `fnmatch`-incompatible `*`.

