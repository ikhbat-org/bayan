# 022 — Break-tests

## T9

Each row breaks one ported lint (or the `.error` severity) in the self-hosted compiler, rebuilds the driver the parity row
runs, runs the row with `--filter "FullyQualifiedName~SelfhostDriverT2Tests.CheckAsCliApp&DisplayName~<case>"`, and
restores the file from its `tmp/t9-bt/<name>.bak` copy (checked with `cmp`).

| lint | revert | parity row | result |
|---|---|---|---|
| BYN1072 guards.postfix (`lintPostfixGuard`) | `src/parser/stmts.byn` `parseIf`: `if !elseIf && !parenthesized { lintPostfixGuard(` → `if false { lintPostfixGuard(` | `CheckAsCliApp(diag/style-guards-postfix.byn)` | Failed 1/1: stderr line 1 differs, expected `note BYN1072: an early exit in a block can be a postfix guard` |
| BYN1073 lambdas.it (`lintItLambda`) | `src/parser/recover.byn`: `if param == "it" { return }` → `if param != "" { return }` | `CheckAsCliApp(diag/style-lambdas-it.byn)` | Failed 1/1: stderr line 1 differs, expected ``note BYN1073: `c => c.…` reads one member and can use `it` `` |
| BYN1074 conditions.named (`lintWrappedCondition`) | `src/parser/recover.byn`: `unless p.lexed.tokens[i].hasNewlineBefore { continue }` → `if i >= 0 { continue }` | `CheckAsCliApp(diag/style-conditions-named.byn)` | Failed 1/1: stderr line 1 differs, expected ``note BYN1074: this condition wraps; name it with a `let` `` |
| BYN1075 nesting.depth (`lintNestingDepth`) | `src/parser/recover.byn`: `if p.blockDepth != maxNesting + 1 { return }` → `if p.blockDepth != -100 { return }` | `CheckAsCliApp(diag/style-nesting-depth.byn)` | Failed 1/1: stderr line 1 differs, expected `note BYN1075: blocks nested more than 4 deep; flatten them with early exits` |
| BYN1076 functions.length (`lintFunctionLength`) | `src/parser/recover.byn`: `if lines <= maxFunctionLines { return }` → `if lines > -1 { return }` | `SelfhostDriverStyleLintsTests.CheckProjectAsCSharpCli(style-functions-length-on)` | Failed 1/7: stderr line 1 differs, expected `warning BYN1076: this function body is 61 lines; split it into named steps`; the other six passed. (`CheckAsCliApp(diag/style-functions-length-on/main.byn)` stays green, see below) |
| `.error` severity (`styleLintsAt` / `t26Failed`) | `src/semantics/compile.byn` `styleLintsAt`: `case .error: let _ = 0` → `case .error: copy.isNote = true` | `SelfhostDriverStyleLintsTests.CheckProjectAsCSharpCli(style-severity-error)` | Failed 1/7: exit code differs, expected 1 (the broken driver exits 0); the other six passed. (`CheckAsCliApp(diag/style-severity-error/main.byn)` stays green, see below) |

The folder cases cannot catch a break through `CheckAsCliApp`. That row checks the isolated `main.byn` as a file, so the sibling
`package.byn` is compiled as a module and both sides stop at BYN1012 before any lint runs. `SelfhostDriverGoldenTests.DiagAsCSharpCli`
checks them with `--package`, and on that branch the C# CLI has no manifest (T7b). Only the project branch reads `lints`.
`SelfhostDriverStyleLintsTests` (`src/tests/SelfhostDriverStyleLintsTests.cs`) covers that branch. For each `style-severity-*` and
`style-functions-length-*` folder case, it lays out `package.byn` and `src/app/main.byn` under `tmp/t9/<case>/`, runs `check .` with the
C# CLI and with the stage-1 driver, and asserts the same exit code, stdout and stderr (seconds masked).

After the restore: `SelfhostDriverStyleLintsTests` 7/7 passed (six cases plus `CoversTheFolderCases`); `SelfhostDriverT2Tests.CheckAsCliApp` 636/636 passed.
