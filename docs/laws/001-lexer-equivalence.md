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
amended: 2026-11-20
---

## Statement

For every lex case in the freeze manifest, `bayan-lex` prints the frozen expected output byte for byte. The frozen files are the C# compiler's output at the freeze (L043).

Kept from the statement in force before 2026-11-20, for `bayan-lex` alone: it reads Unicode data from the generated tables in the repository and does not consult the system's ICU. Only the C# lexer's half of that clause goes away with the oracle. Dropped: the `--json` form. The frozen lex cases hold the token dump (`*.tokens`) only, so it is not covered.

## Counterexample looks like
An input `let é = 1;` written with `e` + U+0301 where the C# JSON dump has a BYN0005 diagnostic with fix `é` and the Bayan JSON dump has none, or the two dumps differ in one token's span.
