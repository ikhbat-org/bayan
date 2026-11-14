# Bayān: nice to have

Optional improvements with no commitment and no slot. State of `dev` at 04366a4f, 2026-11-14. An item here moves to `docs/bayan-roadmap.md` when someone commits to it. Items the user decided against are in `docs/bayan-not-planned.md`. Line numbers for `work/todo.md` are as of this date.

## Language

- Subjectless `switch { cond => … }`, with BYN1071 reserved (`docs/bayan-design-round-4-inventory.md`, R4D §7 subjectless switch).
- `!(x is .s)` as an input form, BYN1070 (`docs/bayan-design-round-4-inventory.md`, R4D §7 BYN1070).
- `dbg(x)` as an error in release builds (`docs/bayan-design-round-4-inventory.md`, R4D §7 dbg).
- A user-written cleanup member such as `dispose(ref this)`; the spec has only derived cleanup (`docs/bayan-design-round-4-inventory.md`, Sūq F-30).
- Format specifiers such as `{x:F2}` (`docs/bayan-design-round-4-inventory.md`, A001 §1; `CHANGELOG.md` `[0.1.0]` Known limits).
- An unordered `HashMap` (`docs/bayan-design-round-4-inventory.md`, HQ371).
- A consuming `finish()` through `move this` (`docs/bayan-design-round-4-inventory.md`, R4D §7 + rev 0018).
- `@deprecated(by:, until:)` (`docs/bayan-design-round-4-inventory.md`, R4D §10 R4.3).

## Compiler

- Return a borrowed slice from `Path.fileName`, `directoryName` and `extension` with no `alloc` (`work/todo.md` line 467, Q753 debt).
- Drop state-tag checks when the state is known (`docs/bayan-design-round-4-inventory.md`, R4D §4 P6).
- Derive `restrict` from borrow facts (`docs/bayan-design-round-4-inventory.md`, R4D §10 R4.6).
- Null-niche optionals and `Result`; the byte figures are unverified (`docs/bayan-design-round-4-inventory.md`, R4D §4 P4).
- A single-arena default allocator for `bayan run` and request handlers (`docs/bayan-design-round-4-inventory.md`, R4D §8 and §9 Q6).
- Decide which parser-port frictions become specs: no tuple destructuring, field moves out of `Owned`, flow typing on field paths and `is` pattern corners (`docs/bayan-handoff.md` line 411, "candidates for later specs").
- Give `Io.run` a working-directory argument, so the driver passes relative names as the C# compiler does (`work/todo.md` line 652).

## Tooling

- A bounds-check report (`docs/bayan-design-round-4-inventory.md`, R4D §7 bounds report).
- `bayan laws` and a laws gate in `package.byn` (`docs/bayan-design-round-4-inventory.md`, A002 §2.4–2.5).
- A libFuzzer engine for `bayan test --fuzz`, only if the built-in fuzzer misses a bug class (`docs/plans/2026-11-05-005-parking-lot.md`, M08).
- A beginner golden per feature, and a keyword count with a cap (`docs/bayan-design-round-4-inventory.md`, R4D §10 R4.5 and R4.4).

## Editor

- A configurable exclude list for `bayan-lsp`; the skipped directory names apply at any depth with no setting (`work/todo.md` line 522).
- Route the `bayan-lsp` log through an injectable writer instead of swapping `Console.Error` in tests (`work/todo.md` line 525).
- `tools/install-textmate.byn` prints `/` in a Windows path where the old script printed backslashes (`work/todo.md` line 719).

## Docs and site

- One sentence in the guide on type-first declarations against name-first locals (`docs/bayan-design-round-4-inventory.md`, R4D §2 word order).
- Multi-clause header layout in `docs/bayan-style-proposal.md` §3.4, left open by the design inputs review (`docs/misc/2026-11-04-design-inputs-review.md`; `docs/bayan-design-round-4-inventory.md`, "Unrelated issues").
- A generated documentation site, when public release planning starts (`docs/plans/2026-11-05-005-parking-lot.md`, D06).
