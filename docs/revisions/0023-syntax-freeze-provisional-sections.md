# 0023 — Syntax freeze to 0.3.0, provisional sections, §13 placeholder

Status: accepted (user decision 2026-11-12, "I approve any changes", after an outside review of the 2026-11-09 export)

## Problem

An outside review of the export at `8d5e5c71` (`docs/export/BAYAN-AUDIT.md`), checked against dev at `9fda8d47`, raised four points that hold:

1. Syntax revisions keep landing while spec 017 makes the self-hosted compiler the default. Every syntax change is paid twice, in `src/` and in `selfhost/`.
2. Revision 0020 tags unbuilt features `(not in 0.2)`, but the tagged text is still normative: every revision has to stay consistent with designs nobody has built or tested together.
3. SPEC §13's heading says `scope`/`spawn` replaces it (revision 0019), but its body still specifies `async`/`await`, `Io.group`, `provide timeout:` and fibers in the present tense (AUDIT A20).
4. A cited code can be missing from the diagnostics index: revision 0022 cited BYN6008 with no entry until review fix 2026-11-12-3 added one.

## Decision

1. **Syntax freeze until 0.3.0 is released.** No revision adds, removes or renames a keyword, operator, clause or grammar form until the 0.3.0 release tag exists. The numeric-conversions revision from the 2026-11-11 drop (planned as 0023 in earlier notes, now **0024**) is the last syntax change admitted. Errata, status tags, doc-consistency fixes and revisions that remove unbuilt text are allowed.
2. **Tagged text is provisional.** A section or item tagged `(not in 0.2)`, `(not in 0.x)`, `(partial in 0.2: …)` or `spec-only` describes a design, not a promise. Building it may change it by revision with no compatibility cost (SPEC §19.4 applies to released behaviour only), and a revision need not keep provisional text consistent with itself: a conflict is resolved when the feature is built. The text stays in the spec, so section numbers and the many `§n` citations in code, goldens and docs stay valid. Moving it to a separate proposals document was considered and rejected for that reason.
3. **SPEC §13 becomes a placeholder.** §13.1–13.5 are removed. 0.x programs are single-threaded; the planned design is `docs/bayan-concurrency.md`, a design document (not normative) that a later revision turns into spec text. The lexer keeps `async` and `await` as reserved words (no keyword change under item 1). SPEC §9 (BYN3217) now points at the design document, not §13.3.
4. **Cited codes are checked.** `scripts/docs/check.sh` (e): every `BYNnnnn` in SPEC, GRAMMAR and STYLE must appear in `docs/DIAGNOSTICS.md`, so a planned code is allocated in `docs/diagnostics-allocated.txt` (or as a `// BYNnnnn Name: … // target:` comment in `DiagnosticCodes.cs`) before a document cites it.

## Naming errors reviewed (no change in this revision)

The review proposed demoting the naming rules (SPEC §5.2) to lints. The test applied: a rule stays an error only when breaking it breaks something mechanical (particle call syntax, a derivation contract, a name that collides with syntax); a rule that depends on classifying English words becomes a lint. The ten `BYN50xx` errors:

| Code | Rule | Mechanical? | Verdict |
|---|---|---|---|
| BYN5001 | an `xed()` member takes `ref this` | No: needs the lexicon to read a word as a participle, and English participles are irregular (`read`, `set`, `split`, `cut`, `put`) | **lint candidate** |
| BYN5002 | an `isX`/`hasX`/`canX` member modifies `this` | Yes: fixed prefixes, no word classification | keep |
| BYN5003 | `tryX` returns neither `T?` nor `bool` | Yes: the `tryX` derivation contract (partial in 0.2) | keep |
| BYN5004 | several unlabeled parameters | Yes: particle call syntax | keep |
| BYN5005 | an argument without its particle | Yes: particle call syntax | keep |
| BYN5006 | a required parameter with no particle | Yes: particle call syntax | keep |
| BYN5007 | `Log.<level>` as a verb | Yes: a missing member with a teaching message | keep |
| BYN5008 | an unknown particle | Yes: particle call syntax | keep |
| BYN5009 | a member named like a particle (`to`, `as`, `toX`, `asX`) | Yes: collides with particle syntax | keep |
| BYN5013 | a particle used twice | Yes: particle call syntax | keep |

The nine `BYN51xx` rules are lints already and never block a build. So one error (BYN5001) fails the test. Demoting it changes both compilers and their goldens, so it waits for a revision after 0.3.0 (`work/todo.md`).

## Sections

- SPEC header (status note), §9 (BYN3217 line), §13.
- `docs/revisions/README.md`: the freeze rule.

## Codes

None added, changed or retired. BYN1016 (`async` as a modifier) and BYN6002 (`suspend`) stay; their §13 cross-references were in the removed text.

## Sūq files

None.
