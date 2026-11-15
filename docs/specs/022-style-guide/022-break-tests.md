# 022 — Break-tests
Status: in progress
Release: 0.3.2
Sources: ./022-tasks.md

## T7b

Each row breaks one line, runs the narrowest test filter, then restores the file from a backup and checks it with `cmp`.

| test | change | result |
|---|---|---|
| b1 `sections.banner` column | `Parser.cs` `BannerColumn = 80` to `79` | caught: `DiagGolden(style-sections-banner)` |
| b2 `conditions.patterns` range order | `Parser.cs` dropped `lo.Value <= hi.Value` from the range check | caught: `DiagGolden(style-conditions-patterns)`, `FixGivesTheFixedRunCase(conditions-patterns)` |
| b3 `literals.empty` fix text | `Parser.cs` `(callee.Span, "[]")` to `(callee.Span, "{}")` | caught: `DiagGolden(style-literals-empty)`, `FixClearsItsLintAndIsIdempotent(style-literals-empty)`, `FixKeepsTheSameC(style-literals-empty)` |
| b4 `optionals.bind` exit form | `Parser.cs` `var head = simple ?` to `var head = true ?` (always `?? exit`) | caught: `DiagGolden(style-optionals-bind)`, `FixGivesTheFixedRunCase(optionals-bind)` |
| b5 `optionals.bind` local form, rename | `Parser.cs` `NarrowLint` appends `bind.Name` instead of `x` | caught: `DiagGolden(style-optionals-bind)`, `FixClearsItsLintAndIsIdempotent(style-optionals-bind)`, `FixGivesTheFixedRunCase(optionals-bind)` |
| b6 `optionals.bind` local form, type check | `Compilation.cs` `NarrowableLocal` accepts any local kind (`true \|\|`) | caught: `DiagGolden(style-optionals-bind)`, `FixClearsItsLintAndIsIdempotent(style-optionals-bind)`, `FixGivesTheFixedRunCase(optionals-bind)` |
| b7 `NoteLintOperand` on `is` | `BinderExpressions.cs` removed `_c.NoteLintOperand(i.Value, value)` | caught: `DiagGolden(style-optionals-bind)`, `FixGivesTheFixedRunCase(optionals-bind)` |
| b10 `NoteLintOperand` on a binary left | `BinderExpressions.cs` removed `_c.NoteLintOperand(b.Left, left)` | caught: `DiagGolden(style-conditions-patterns)`, `FixClearsItsLintAndIsIdempotent(style-conditions-patterns)`, `FixGivesTheFixedRunCase(conditions-patterns)`, `FixDoesNotFormat` |
| b8 `bayan fix` repeats until stable | `FixCommand.cs` `pass < Format.MaxPasses` to `pass < 1` | caught: `FixClearsItsLintAndIsIdempotent(style-optionals-bind)`, `FixGivesTheFixedRunCase(optionals-bind)` (the BYN1072 follow-on fixes need a second pass) |
| b9 `check --package` reads the package's `lints` | `CliApp.cs` `StyleLintsAt(manifest ?? lintManifest)` to `StyleLintsAt(manifest)` | caught: `CheckPackageReadsTheRootsLints` |
