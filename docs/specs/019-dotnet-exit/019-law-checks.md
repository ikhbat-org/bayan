# Law checks drafted but not live (spec 019 T31, R18)

Decision 2026-11-18 (owner): a live `check:` line is swapped only when the new command runs at least one existing case that covers the statement. These laws keep their old `check:` until the target lands. `bayan test --only X` exits 2 when X matches nothing (verified), so a drafted selector cannot pass vacuously. G = `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases`.

| law | drafted check | waits on |
|---|---|---|
| L002 | `G --only 'lex/'` | T17c: no no-panic fuzz is ported; lex/ cases do not cover it |
| L006 | `G --only '/l006-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L007 | `G --only '/l007-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L008 | `G --only '/l008-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L013 | `G --only '/l013-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L018 | `G --only 'parse/'` | T17c: no no-panic fuzz is ported; parse/ cases do not cover it |
| L019 | `G --only '/l019-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L020 | `G --only '/l020-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L021 | `G --only '/l021-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L022 | `G --only 'sem/'` | T17c: no sem/ kind yet |
| L023 | `G --only 'sem/'` | T17c: no sem/ kind yet |
| L024 | `G --only 'emit/'` | T17c: emit/ holds one case, not the emitter equivalence |
| L025 | `G --only 'emit/'` | T17c: emit/ holds one case, not the emitter equivalence |
| L027 | `bash scripts/ci/bootstrap-check.sh` | T46 (ddc-laws.txt) and a debug-mode, no-absolute-path/no-timestamp check; bootstrap-check.sh covers neither |
| L038 | `G --only '/l038-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L039 | `G --only 'cli/format'` | T17c: cli/ cases for format |

## Statement amendments for the owner

- L001, L017, L022, L024: name the C# lexer, parser, binder or emitter as the oracle; after 019b the oracle is the frozen expected files.
- L026, L039: name .NET's Path.* and the C# CLI as the oracle; same amendment.
- L005: names C# behaviour in its proof notes; after 019b the oracle is the T24b fixtures.
- L027: the Statement says "becomes a no-.NET check once T31 lands"; the frozen-tree half needs L027 in scripts/ci/ddc-laws.txt.
