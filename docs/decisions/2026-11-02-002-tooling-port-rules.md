# Tooling ports: scope, pinned build and language rules
Status: decided (user, 2026-11-02). Spec 015 (`docs/specs/015-tooling/015-spec.md`) carries the port list and its own decisions S1–S13; this record holds what that spec does not repeat.

## Decisions

| # | Decision |
| --- | --- |
| T1 | **Std scope is per port, homes fixed now.** Add only what the script being ported needs, in the module `docs/bayan-library-tiers.md` names. Every new public API is a spec question to the user before it is written. The tiers doc wins where it and any other text disagree; where it lists something as Open, ask before acting. |
| T2 | **Tooling and gates run a pinned `bayan`**, built from the last merge into `dev` and cached by commit. Never the working tree. |
| T3 | **Spec 015 is written now; ports wait for 012** (later refined to S1 in the spec). Do not interrupt other in-flight specs. |
| T4 | **CI replaces `actions/checkout` and `actions/setup-dotnet` with shell steps.** `upload-artifact` and `download-artifact` stay. |

T2 and T4 are built (the installer checks sha512 where the original text said SHA-256): `scripts/pinned-bayan.sh` and `scripts/ci/install-dotnet.sh`, and `ci.yml`, `mutation.yml` and `laws-nightly.yml` fetch the exact commit at depth 1 (the repo is public, so no token).

## Rules for the pinned build (T2)

- The helper resolves the last merge commit on `dev`, builds `bayan` from it into `.cache/bayan/<sha>/` if missing (in a worktree; it never touches the caller's tree) and prints the binary path.
- `guard.sh`, `land.sh` and every tooling script that runs `bayan` call it through the helper.
- A failed pinned build exits non-zero with the commit and the build log path. It never falls back to the working tree.
- The pin follows `dev`; nobody edits it by hand. The compiler's own tests keep using the working tree. `.cache/` is git-ignored.

## Rules for CI shell steps (T4)

- Checkout: `git init` and `fetch` of the exact `GITHUB_SHA` with an explicit depth (full history only where a job needs it); a `GITHUB_TOKEN` header only if the repo is private.
- .NET: `dotnet-install.sh` with the script verified by a pinned hash, or vendored in the repo. Never pipe a live download into a shell. Pin the SDK version as before.
- Verify: the workflow passes on a branch and the job logs show the same SDK version and commit as before.

## Shell or Bayān

- Shell (`sh` or `bash`, `set -euo pipefail`, ShellCheck-clean): glue, sequencing other tools, environment setup, and anything that must run without `bayan`.
- Bayān: parsing (JSON, XML, text formats), data transformation, hashing, decisions over structured data, or anything past roughly 50 lines of shell.
- A Bayān tool is a script (`bayan run tools/<name>.byn`); a shared one is a small package under `tools/`.
- Tests and generators around editor tooling (`npm run lsp`, `npm run grammar`, `tests/lsp-regress.js`) are port candidates.

## Rules for new Bayān code in a port

- Current syntax: type-first declarations, no `fn`, `because "…"` as a clause (not `because:`), plain parameters (not `in`), each particle at most once per signature, naming per `docs/bayan-grammar.md` (fallible pairs `parse`/`tryParse`, `-ed` copies, no `toX`/`asX`, codecs as static `encode`/`decode`).
- Public functions declare `uses`; I/O goes through the matching effect (`fs`, `env`, `process`, `net`, `console`, `clock`, `random`). Data read from outside is `Untrusted<T>`.
- Libraries call libc only through `rt` (K4). Spec changes go through numbered revisions in `docs/revisions/`.
- Each port is followed by: confirm its APIs are approved; add missing APIs with `std.test` tests, doc comments and declared effects, grammar checker clean, only what this port needs; write the port and run it under the pinned `bayan`; run the parity check on recorded inputs; switch callers and delete the old script in the same commit; when the last script needing a runtime (Node, Python, Deno) is gone, remove that runtime from CI and the dev setup docs.

## Left to do

- [ ] Ask the user before acting on these (Open in `docs/bayan-library-tiers.md`): Q1 database module names (`std.db` interfaces plus `kit.db.*` drivers proposed), Q4 where the Unicode case tables live (revision 0015 against 0003), Q9 `kit.xml` placement and scope, and any new module or API not listed in the tiers doc. Q3 is settled by S12 (`std.encoding`) and Q8 by the tiers doc (`curl` shell-outs now, a C library via `std.c` for `kit.tls` in v0.3). Done when each is answered in the tiers doc.
- [ ] Per port report: what landed (commit), what was deferred and why, every spec question raised with its proposed signature, and any conflict between this record, the tiers doc and the spec. Goes in `docs/specs/015-tooling/015-spec.md` port record.
