# Bayan — agent instructions

- Source of truth: `docs/bayan-spec.md`. Milestones: `docs/bayan-milestones.md`; what comes next: `docs/bayan-roadmap.md`; open questions: `docs/bayan-questions.md` (answered ones: `docs/decisions/2026-11-14-004-answered-questions.md`); working rules: `docs/bayan-contributing.md`. Read the spec and the milestones before working.
- Appendix A of the spec lists settled decisions; do not re-propose them. Spec gaps go to `docs/bayan-questions.md`, with the most conservative option implemented meanwhile.
- Add an entry to `docs/bayan-progress-log.md` at the end of every working session.
- Stack: C# / .NET 10, NativeAOT for `src/` (`IsAotCompatible`, warnings are errors). No reflection, no `Reflection.Emit`, no parser generators.
- Lexer works over `ReadOnlySpan<byte>` UTF-8; tokens are structs; positions are byte offsets (`TextSpan`).
- Tests: `dotnet test -v q`. Golden cases live in `tests/cases/<kind>/`; `BAYAN_UPDATE=1 dotnet test` rewrites expected files. Every new diagnostic needs a `diag/` case, every runtime feature a `run/` case.
- Diagnostic codes `BYN####`: 0001–0999 lexer, 1000–1999 parser, 2000–3999 semantics, 4000–4999 backend, 5000–5999 grammar and naming, 6000–6999 effects and concurrency, 7000–7999 typestate and contracts, 8000–8999 trust and security (the ranges in use today; `docs/revisions/0017-addendum-a2-diagnostic-codes.md` assigns target areas that differ for 0xxx (project and CLI), 4xxx (control flow and failure) and 9xxx (build, C backend and runtime traps), and the codes have not been renumbered to them yet). Rendered format is fixed by `DiagnosticRendererTests`.
- Scratch goes in `tmp/` (gitignored).
- Decisions: `docs/decisions/` (spec 010 landing gate and lessons: `2026-10-28-001-spec-010-landing-gate-and-lessons.md`; tooling ports, spec 015, replacing Python/Deno/Node scripts with Bayān or shell: `2026-11-02-002-tooling-port-rules.md` and `docs/specs/015-tooling/`); library placement: `docs/bayan-library-tiers.md`.
- Spec 010 work lands only through `scripts/selfhost/land.sh` (guard + an independent review against the C#, Q712). Tests take their expected lines from the C# implementation, never typed by hand. Port, do not invent: no fallbacks for unported siblings. The `in` parameter modifier is redundant (spec §10): leave it out of new code.
- Memory and disk bounds: read `docs/memory-leaks.md` before writing a walk, watcher, cache, child-process capture or input recursion; its *Release gate* must pass before any release.
