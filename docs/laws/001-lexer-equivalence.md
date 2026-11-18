---
id: L001
title: The Bayan lexer and the C# lexer agree on every input
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: src/lexer/lexer.byn
proof: src/tests/SelfhostLexerTests.cs
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'lex/'
timeout: 1800
enacted: 2026-10-20
---

## Statement
For every byte sequence (including invalid UTF-8, unbalanced interpolation, non-NFC identifiers and bidi controls), `bayan-lex` and the C# lexer produce identical structured token dumps (`--json`: kinds, spans, values, diagnostics with codes, spans and fixes). Both lexers read Unicode data from the same generated tables in the repository; neither consults the system's ICU.

## Proposed statement (019 T31, owner-approved template 2026-11-18)

For every lex case in the freeze manifest, `bayan-lex` prints the frozen expected output byte for byte. The frozen files are the C# compiler's output at the freeze (L043).

Dropped from the current Statement: the clause that both lexers read Unicode data from the same generated tables and neither consults the system's ICU. It describes the C# lexer's data source, and no frozen lex case records it. The frozen lex cases hold the token dump (`*.tokens`) only, so the `--json` form is not covered.

## Counterexample looks like
An input `let é = 1;` written with `e` + U+0301 where the C# JSON dump has a BYN0005 diagnostic with fix `é` and the Bayan JSON dump has none, or the two dumps differ in one token's span.
