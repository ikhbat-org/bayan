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
| BYN1076 functions.length (`lintFunctionLength`) | `src/parser/recover.byn`: `if lines <= maxFunctionLines { return }` → `if lines > -1 { return }` | `CheckAsCliApp(diag/style-functions-length-on/main.byn)`; project-layout comparison | Row passed 1/1: not caught (see below). The comparison caught it: style-functions-length-on DIFF, since C# prints `warning BYN1076` and the broken driver prints nothing; the other five folder cases stay the same |
| `.error` severity (`styleLintsAt` / `t26Failed`) | `src/semantics/compile.byn` `styleLintsAt`: `case .error: let _ = 0` → `case .error: copy.isNote = true` | `CheckAsCliApp(diag/style-severity-error/main.byn)`; project-layout comparison | Row passed 1/1: not caught (see below). The comparison caught it: style-severity-error DIFF, C# exit 1 with `error BYN1072`, broken driver exit 0; the other five folder cases stay the same |

The folder cases cannot catch a break through `CheckAsCliApp`. That row checks the isolated `main.byn` as a file, so the sibling
`package.byn` is compiled as a module and both sides stop at BYN1012 before any lint runs. `SelfhostDriverGoldenTests.DiagAsCSharpCli`
checks them with `--package`, and on that branch the C# CLI has no manifest (T7b). Only the project branch reads `lints`. The project-layout
comparison is `tmp/t9-bt/cmp.sh`: for each `style-severity-*` and `style-functions-length-*` folder case, it copies `package.byn` and
`src/app/main.byn` and runs `check .` with the C# CLI and with the driver, comparing stdout, stderr (seconds masked) and exit code. With
the restored sources, stage 2 (`tmp/bootstrap/stage2/bayan`) and the stage-1 driver both match on all six cases.

After the restore, `SelfhostDriverT2Tests.CheckAsCliApp`: 636/636 passed.
