# Hardening findings (plan 020)
Status: in progress (one entry per finding)
Release: unscheduled
Sources: plan 020 runs

One entry per finding, format from `docs/handoffs/2026-11-27-hardening.md` §5. Repros live in `tests/hardening/known/HF-NNNN/`.

```
HF-0001  Untrusted<bool> assigns to bool without trustUnchecked (string and i64 are rejected with BYN2202)
  oracle:     H7 safety mutants (scripts/hardening/safety-mutate.sh, kind untrusted-to-trusted; source run/untrusted-clean-facts)
  repro:      tests/hardening/known/HF-0001/
  severity:   unsound
  first seen: 70be08e7e (dev)
  status:     open

HF-0002  A read after a `ref` call in the same expression is unsequenced in the emitted C (gcc prints 30, zig 40)
  oracle:     H1 sanitizer matrix, gcc cells on wp1 WSL (golden run/operand-ref-spill, every cell)
  repro:      tests/hardening/known/HF-0002/
  severity:   miscompile
  first seen: 51379f861 (dev)
  status:     open
```

## Harness notes (not compiler findings)

- **ASan start-up loop on wp1 WSL (2026-11-27).** Kernel 6.18.54.1-microsoft-standard-WSL2, gcc 12: 4 of 30 ASan starts of `runtime/tests/path-relative-cases.c` printed `AddressSanitizer:DEADLYSIGNAL` forever (25.7 GB in 68 min, then `io-read-release` 2.4 GB); 0 of 30 under `setarch $(uname -m) -R`. Address-randomization interplay with the sanitizer runtime, not Bayān code. `sanitize.sh` and `fuzz.sh --afl/--triage` now start under `setarch -R` and `sanitize.sh` caps file size with `ulimit -f`. The first WSL ASan cell was stopped and rerun: 73 timeouts became 0, and the gcc+clang matrix took 5 min (2026-11-27, 507c90184).
