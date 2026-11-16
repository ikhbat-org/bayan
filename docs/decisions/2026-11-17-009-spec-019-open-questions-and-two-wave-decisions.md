# 009 — Spec 019 language server, OQ8 and OQ6; error-set growth; the wave-brief lock

Status: decided (the owner accepted Fable's recommendations on 2026-11-17)
Release: unscheduled
Date: 2026-11-17
Sources: an independent Fable review (think worker, key `fable-lsp-f`) of the spec 019 language server placement, OQ8 and OQ6; an independent Fable review of error-set growth (key `fable-e`); the owner's answer "let's go with Fable's recommendations". Continues decision 008 D7, which left OQ6, OQ8 and the language server's part open.

## Summary

| # | Question | Decision |
|---|---|---|
| D1 | Language server placement (spec 019) | C, hybrid: the port runs in 019a, 019a lands without it, 019b waits for it. |
| D2 | OQ8, reading one message at a time | C: `Io.stdin.read(into:)` as the first piece of the Q1141 stream API; signature owner to approve. |
| D3 | OQ6, where the R27 job runs | A: hosted, weekly, required by `release.yml`. |
| D4 | Growth of error sets (spec 026) | Rule 1: mark `IoError` `extensible`; callers need a fallback arm. |
| D5 | The wave-brief lock (spec 015 T15 part 2b) | Check the lock after a failed rename. |

## D1. Language server placement

C. Spec 019 R24 exempts `editor-gate.yml` and the server part of the memory gate from "no .NET" until the Bayān `bayan-lsp` passes R21 and R22. R30 adds R20–R23 as a 019b entry condition. The placement text in the spec, the plan and the tasks says the same.

Why: the syntax freeze is the expensive part, and the server is the one part of 019a blocked on an undecided API (OQ8). The C# server has its own lexer and keyword list, so it does not depend on the C# compiler. Cost: until the port passes, each new keyword is added to two servers, and "CI has no .NET" is not true on the day 019a lands.

## D2. OQ8: `Io.stdin.read(into:)`

C. One member fills a buffer the caller owns and returns the number of bytes read; 0 means the pipe closed; it blocks until at least one byte is available and may return fewer than the buffer holds; it fails with `IoError`. The framing loop (header, then `Content-Length` bytes) and R22's size limit live in the server. The owner approves the signature as the first piece of the Q1141 stream design (Q1141 ruled "no new API now" for a one-off bytes form of `Io.run`, 2026-11-08). No runtime code is part of this decision.

Why: the editor keeps standard input open for hours, and `readAll` returns only when it closes, so the server would answer nothing. A reader half is needed by any stream API, so it is a first slice and not the one-off Q1141 refused. Open checks: `Io.stdout.write` flushes each reply, and Windows reads standard input as raw bytes.

## D3. OQ6: the R27 job

A. A scheduled workflow on a hosted Linux runner, plus a `needs:` entry in `release.yml`. `docs/RELEASING.md` says a red R27 run means fix the environment and re-run.

Why: the check loses its value if nobody looks, and the release gate is what guarantees a look. A red run will usually mean the surroundings changed (SDK download, runner image), not that the release is bad, hence the RELEASING line. Revisit if environment failures block two releases (advisory, plus a green last weekly run) or if the job passes about 30 minutes on hosted runners.

## D4. Error sets: Rule 1

Mark `IoError` `extensible`; a `switch` or `catch switch` over it needs a fallback arm (`_` or `IoError e`) as a hard error. Unmarked sets stay closed and grow only by a versioned break. Rule 3 (`other(detail)`) is rejected. Built in spec 026.

Why: `docs/bayan-spec.md` already states this rule ("closed unless marked `extensible`"), and the marker scopes it to the sets that need to grow. It lets `IoError` gain members, such as `alreadyExists`, without breaking callers.

## D5. The wave-brief lock

In spec 015 T15 part 2b, the lock code checks the lock after a failed rename and does not treat the failure as a lost lock.

Why: a failed rename does not show that another process holds the lock, so the check keeps a holder from losing a live lock (T15 test 4: a failed verify renames the directory back and the holder keeps it).
