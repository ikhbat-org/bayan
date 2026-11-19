---
id: L002
title: The Bayan lexer never panics and keeps spans inside the input
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: src/lexer/lexer.byn
proof: src/driver/nopanic-l002.test.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L002:'
timeout: 1800
enacted: 2026-10-20
---

## Statement
For every byte sequence supplied on stdin, `bayan-lex` terminates with exit code 0 or 1 (never a panic, exit 134), and every token span, doc-comment span, diagnostic span and fix span it produces lies within `[0, input length]`. I/O failures (an unreadable input, exit code 4) are outside this law.

## Counterexample looks like
Stdin ending in `$"{` followed by an invalid UTF-8 byte on which `bayan-lex` prints `panic: index out of range`, or a token with span start 10 in a 9-byte input.

## Proof notes
History (C#, before spec 019 T31c): the proof was `BayanLexNeverPanicsAndKeepsSpansInsideTheInput` in src/tests/SelfhostLexerTests.cs:376, checked by `dotnet test -v q --filter "Law=L002"`. It piped 10,021 inputs (the 21 `tests/cases/lex/*.byn` in ordinal order, then the 10,000 of `GenerateCorpus`, :183-232) one process each into `bayan-lex --json`, 30 s per run scaled by `TestTime.Scale`, a timed-out run retried once, and read every `"start":a,"end":b` in the JSON as `a <= b <= length`. No tiers.

Bayān port (2026-11-19, spec 019 T31c S1): the test block `L002:` in src/driver/nopanic-l002.test.byn builds the lexer program with `goldenProgram("lexer", …)`, ports `GenerateCorpus` (xorshift64 from `0x9E3779B97F4A7C15`, the C# call order, the 9 invalid UTF-8 sequences and the 42 specials) and writes the 10,000 inputs plus the 21 lex cases (as `lex-<name>`) to tmp/l002-nopanic, removed after a pass. Each generated input's SHA-256 must equal the frozen C# blob of `tests/cases/lex/SelfhostLexerTests/CorpusMatchesTheReferenceLexer-<i + 1>/input.byn.ref` (input 0: the case with no suffix); all 10,000 match. One `bayan-lex --many` run over the directory must exit 0 with no `panic:` on stderr, print every `== <name>` header in name order and no `span out of range` line (`checkSpans`, src/lexer/main.byn: token, doc, diagnostic and fix spans). The 21 cases and the empty input also go to `bayan-lex --json` on stdin: exit 0 or 1, no `panic:`, every JSON span `a <= b <= length`. Other stdin inputs are covered through `--many`, which runs the same `lex` on the file's bytes.

Counts per tier: the C# had no tiers, so `BAYAN_LAW_TIER=quick` and `full` both run 10,000 generated inputs plus 21 cases under `--many` (10,021 sections) and 22 stdin runs. Wall time on macOS (arm64), lexer program already built: the block 5.7 s quick, 4.8 s full; the whole `bayan test --only 'L002:'` command 15.4 s and 12.6 s.

Break: src/lexer/main.byn:65 (was :64), `inside` changed from `span.end <= size` to `span.end < size`. The block fails at nopanic-l002.test.byn:301 with `tmp/l002-nopanic/00000.byn: span out of range: token 0+0` (the EOF token of the empty input), all 10,021 headers seen. Undone; `git diff src/lexer/main.byn` is empty.
