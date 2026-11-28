# 012 — Bayān scripts, speed and interop goals, hardening by default, wasm32 and sabk

Status: decided (owner 2026-11-28)
Release: unscheduled
Date: 2026-11-28
Sources: owner answers of 2026-11-28 to the 0.4 status report; `docs/audits/2026-11-28-decisions-0.4.md`; the Neon (gw-think) review of 2026-11-28, items 1–5 (an untracked scratch answer, summarised in section 5)

## 1. Scripts are written in Bayān

- Every new script is a Bayān program. No new shell, Python, Deno or Node scripts. This supersedes the "Shell or Bayān" rule of `2026-11-02-002-tooling-port-rules.md`, which kept shell for glue and sequencing.
- Existing shell scripts are ported to Bayān, extending spec 015 (which covered Python/Deno/Node).
- **Exception:** scripts that run before a Bayān compiler exists on the machine stay shell: `scripts/bootstrap-build.sh`, the CI bootstrap step and anything they call. The port spec lists them by name.
- **Exception:** cleanup scripts under `scripts/cleanup/` keep their fixed `.sh`/`.ps1` interface (dry run by default, `--execute`), since they run on hosts without `bayan` and are deleted once run.
- Name: **Bayān scripts** (owner 2026-11-28). No separate name or dialect: a script is an ordinary `.byn` program run with `bayan run`.

## 2. Speed: Rust level or better

The spec §Runtime goal ("Bayan targets Rust and Zig speed") is the bar. This is a long-term goal, not a 0.4 gate: every benchmark in `bench/` is to run at or below the time of Rust and Zig, and a program slower than either is a tracked finding.

## 3. Calling C libraries: best in class

C interop is to match or beat Zig's: header import, C ABI types and linker flags declared in `package.byn` (Neon item 2).

## 4. Hardening

- **The compiler's own build is always hardened.** The plan 020-hardening checks (determinism, C compiler matrix, sanitizers, Fil-C, emitted-C invariants, must-reject, fuzzing) run as part of building and releasing Bayān, not as an optional job.
- **Programs built with Bayān:** hardening is opt-in (a build option; its name and contents go to a spec).

## 5. Roadmap items accepted from the Neon review

| Neon item | Decision |
|---|---|
| 1. Freeze sabk | **Rejected.** sabk (native backend, spec 024) continues. |
| 2. C header import and linker flags | Accepted (item 3 above). |
| 3. `net`, TLS, small `http` on spec 027 | Accepted. |
| 4. `package.byn` dependency resolution, lockfile, git fetch | Accepted. |
| 5. wasm32 or server-side only | **Both.** wasm32 work continues (plan `2026-11-05-004-v0.4-interop.md` I05) alongside server-side `net`/`http`. |

## 6. Benchmarks

Go joins C, Rust and Zig in `bench/run.sh`, with more programs, run nightly on GitHub Actions (owner 2026-11-28), within GitHub's limits: two jobs a night, 30 min each, skipped when `dev` has not moved; gated on the Bayān/C ratio.

## 7. Reuse before writing (owner 2026-11-28)

Goal: far fewer one-off `tmp/` scripts, and fewer tokens spent rewriting the same job.

```
need a script → search → found? ── yes → run it with arguments
                   │                 └─ almost → add a parameter to it
                   └─ no → write a parameterized Bayān script in tools/<area>/
```

- **Search first.** `mcp__semble__search` over the repo with the job in plain words, then `deno run -A ~/.claude/tools/structure-audit.js --scripts` (lists every script with its `what:` line). A new script is written only when neither finds one.
- **Extend, don't copy.** A script that nearly fits gains a flag or argument; a second script doing the same job with other values is a review finding.
- **Parameterized.** Hosts, paths, shas, counts, filters and limits are arguments or flags with defaults, never edited into the body. `--help` prints the usage.
- **Organized by area.** Bayān scripts live in `tools/<area>/<verb-noun>.byn` (areas follow `scripts/`: `ci`, `docs`, `release`, `selfhost`, `hardening`, `quality`, `bench`, `hosts`); the 16 flat `tools/*.byn` files move into areas when the shell-port spec runs.
- **Findable.** Every script opens with two comment lines, `what: <one line>` and `usage: <command with its flags>`, which the finder and semble rank on. 76 existing scripts lack `what:`; the port spec adds it as each is touched.
- **`tmp/` is for output, not tools.** A multi-step command that would have been a throwaway `tmp/x.sh` becomes a parameterized script in the repo when its job can recur (a host run, a gate, a measurement); a true one-off reuses the fixed slot `tmp/run/x.sh`.
