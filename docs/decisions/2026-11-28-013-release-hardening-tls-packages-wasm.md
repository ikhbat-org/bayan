# 013 — 0.4.2, hardening levels, TLS, packages, wasm, spec order

Status: decided (owner 2026-11-28)
Release: unscheduled
Date: 2026-11-28
Sources: owner answers of 2026-11-28 to the open asks (0.4.2, `--harden`, TLS, packages, wasm); `docs/handoffs/2026-11-27-hardening.md` (H0, H11, §8 R1/R2/R4); decision 012

## 1. 0.4.2

Cut now. The agent runs the release checks; the owner tags and pushes. Before the cut, each of the five open 0.4.0 audit HIGHs (07 #3, 07 #4, 09 #1, 09 #3, 10 #2) has a regression golden, and the release commit fixes the roadmap row.

## 2. Hardening: one setting with levels, not a `--harden` flag

A single flag would mix three things that do not belong together:

| Level | What | Where it may run |
|---|---|---|
| `.flags` | PIE, RELRO, CFI, FORTIFY, stack-clash: cheap, for production | everywhere; candidate default once the H11 numbers are in (R4) |
| `.sanitized` | ASan/UBSan: testing only, slow, adds attack surface | `test` and `run` only; `build` for release with it is an error |
| `.filc` | Fil-C: a separate compiler, not combinable with ASan | Linux only; a container or VM elsewhere (R1) |

Manifest key `hardening: .flags | .sanitized | .filc` plus a CLI override. Covers R1, R2 and R4 of the hardening handoff §8. The spec is written after 0.4.2 and after H0/H11 report.

## 3. TLS: an existing library behind a Bayān interface

- `std.tls` is an interface, so backends swap without API churn.
- First backend: OpenSSL 3 through the C header import, linked dynamically on Linux.
- System TLS differs by OS (SChannel, Network.framework) and system OpenSSL breaks hermetic cross-compiles, so one vendorable static backend (mbedTLS or BoringSSL) is evaluated for `zig cc` cross builds.
- Certificate verification is on by default; turning it off needs `@allow … because "…"`.
- Long term: a Bayān TLS state machine over vetted crypto primitives (the rustls model). Never home-made crypto.

## 4. Packages: git and a lockfile first, a registry later

- Lock to commit hash plus content hash, never a tag or branch.
- `package.lock.byn` per SPEC §21.4.
- The `uses:` effect grants of the 2026-11-01 packages design are enforced.
- No install scripts; generators run sandboxed (R11).
- Offline and vendor mode.
- A package's identity is the name in its `package.byn`, not its URL, so imports survive a registry or a host/org move.

## 5. wasm: WASI first, then browser JS calls

- The wasm spec states which WASI version I05 targets.
- Browser JS calls reuse the `extern`/C-import machinery: a wasm import is an extern with a module name, under its own effect. No second FFI.

## 6. Spec order

```text
1 C header import ──┬──> 3 net/TLS/http
                    └──> 6 wasm in the browser
2 Package dependencies
4 App hardening (after 0.4.2 and H0/H11)
5 Shell → Bayān script port (extends 015)
```

Order: 1 C header import, 2 package dependencies, 3 net/TLS/http, 4 app hardening, 5 shell → Bayān port, 6 wasm in the browser. Nothing lands mid-flight unless it does not disrupt the current wave.
