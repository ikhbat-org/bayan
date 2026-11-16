# 022 — Break-tests
Status: in progress
Release: 0.3.2
Sources: ./022-tasks.md

## T6c

Each row reverts one rule in `csharp/Bayan.Cli/Layout.cs` (line numbers from the restored file), runs `dotnet test csharp/tests/Bayan.Tests/Bayan.Tests.csproj -v q --filter "FullyQualifiedName~LayoutTests|FullyQualifiedName~StyleGuideExamplesTests"`, and restores the file from a backup (`cmp` clean after every row). `Corpus(x)` is `LayoutTests.TheCorpusLaysOutOnceAndForAll(file: "src/x.byn")`; `Guide("t")` is `StyleGuideExamplesTests.DontFormatsToDo(title: "t")`. Rows marked *new* had all tests green under their revert, so this round added the case named in the row.

| Rule | LayoutTests case(s) | Revert | Result |
|---|---|---|---|
| D: break before the lowest operators | AnExpressionBreaksBeforeItsLowestOperators, AnOperatorBreaksBeforeAnArgumentList | `BreakLine`:887 `LowestOperators(s, p, e)` replaced by an empty list | 15 failed: AControlHeadGroupBreaksAfterTheTopLevelOperators, AGroupThatDoesNotFitBreaksInside, AnAuthorsChainInATernaryJoinsForTheLadder, AnAuthorsGroupBreakGivesWayToItsOperators, AnExpressionBreaksBeforeItsLowestOperators, AnIndexAndAMemberAfterItStayWhole, AnOperatorBreaksBeforeAnArgumentList, AParenthesisedHeadIsNotBrokenAfter, ATernaryInAnArgumentBreaksBeforeQuestionAndColon, Proposal34WrappedConditionBreaksBeforeEachAnd, StyleWrappedConditionBreaksBeforeEachAmpAmp, Guide("Break order"), Guide("Groups that do not fit"), Guide("Ternary ladder"), Guide("Wrapped conditions") |
| A group breaks at its own operators (widest group) | AGroupThatDoesNotFitBreaksInside, AControlHeadGroupBreaksAtItsOwnOperators | `BreakLine`:888 `if (ops.Count == 0)` forced false (no widest-group fallback) | 2 failed: AControlHeadGroupBreaksAfterTheTopLevelOperators, AControlHeadGroupBreaksAtItsOwnOperators |
| No break after a control head's `)` (BYN1017) | AParenthesisedHeadIsNotBrokenAfter, AControlHeadGroupBreaksAtItsOwnOperators | `LowestOperators`:991 guard `Kind(k - 1) == TokenKind.CloseParen` forced false | 12 failed: AControlHeadGroupBreaksAfterTheTopLevelOperators, AControlHeadGroupBreaksAtItsOwnOperators, AParenthesisedHeadIsNotBrokenAfter, Corpus(driver/audit), Corpus(driver/progress), Corpus(emitter/lower), Corpus(semantics/binder2), Corpus(semantics/calls), Corpus(semantics/calls3), Corpus(semantics/effects), Corpus(semantics/express), Corpus(semantics/ownership) |
| Control-head group: its lines indent as a header group | AControlHeadGroupBreaksAtItsOwnOperators, AControlHeadGroupBreaksAfterTheTopLevelOperators | `Levels`:371 `outer.Control && !CallLike(k - 1)` forced false | 2 failed: AControlHeadGroupBreaksAfterTheTopLevelOperators, AControlHeadGroupBreaksAtItsOwnOperators |
| Control-head group: the head's `(` never opens as a list | AControlHeadGroupOpensTheCallInside, AControlHeadGroupDoesNotOpen (*new*) | `BreakLine`:938 `\|\| control && o == p + 1` removed from the list skip | 1 failed: AControlHeadGroupDoesNotOpen |
| A group around one operand before a member is an atom | AGroupAroundAnOperandBeforeAMemberStaysWhole | `BreakLine`:943 `Kind(c + 1) is TokenKind.Dot or TokenKind.QuestionDot` forced false | 1 failed: AGroupAroundAnOperandBeforeAMemberStaysWhole |
| Atoms: an index does not open | AnIndexAndAMemberAfterItStayWhole | `BreakLine`:938 `\|\| IsIndex(o)` removed from the list skip | 1 failed: AnIndexAndAMemberAfterItStayWhole |
| Atoms: no operator break inside an index | AnOperatorInsideAnIndexDoesNotBreak (*new*) | `LowestOperators`:988 `&& !(o >= 0 && IsIndex(o))` removed | 1 failed: AnOperatorInsideAnIndexDoesNotBreak |
| Atoms: the member after an index stays on its line | AChainAfterAnIndexKeepsItsFirstMember (*new*) | `Chains`:724 `&& Kind(j - 1) != TokenKind.CloseBracket` removed | 1 failed: AChainAfterAnIndexKeepsItsFirstMember |
| Atoms: a unit literal | none | none: a unit literal (`5ms`) is one token, so no break point exists to revert | n/a |
| Ternary ladder: break before `?` and `:` | ATernaryInAnArgumentBreaksBeforeQuestionAndColon, AnAuthorsChainInATernaryJoinsForTheLadder | `LowestOperators`:978 `TokenKind.Question when Trivia(k) => 0` forced false | 3 failed: AnAuthorsChainInATernaryJoinsForTheLadder, ATernaryInAnArgumentBreaksBeforeQuestionAndColon, Guide("Ternary ladder") |
| Ternary ladder: only inside `( )` or a list's `[ ]` | ATernaryColonKeepsItsSpaceAfterABreak, AChainInATernaryWaitsForTheTernary | `LowestOperators`:989 `(level > 0 \|\| o >= 0 && Kind(o) is TokenKind.OpenParen or TokenKind.OpenBracket)` replaced by `(level >= 0)` | 34 failed: AChainInATernaryWaitsForTheTernary, ATernaryColonKeepsItsSpaceAfterABreak, and 32 Corpus: driver/mutate, driver/quality, emitter/cprint/builtin, emitter/cprint/func, emitter/lowerassert, emitter/lowerexpr, emitter/lowerpat, emitter/lowerstmt, emitter/main, emitter/schemata, lexer/lexer, parser/decls, parser/exprs, parser/stmts, semantics/binder, semantics/binder2, semantics/binder3, semantics/calls, semantics/calls2, semantics/calls3, semantics/cli, semantics/compile, semantics/conformance, semantics/declare, semantics/declare2, semantics/express, semantics/express2, semantics/express3, semantics/express4, semantics/flow, semantics/region2, semantics/typeresolve |
| Chains wait for the ternary (Breaks) | AChainInATernaryWaitsForTheTernary | `BreakLine`:928 `if (ternary[b[0] - s]) continue;` forced false | 1 failed: AChainInATernaryWaitsForTheTernary |
| Chains wait for the ternary (Joins, `InUnbrokenTernary`) | AnAuthorsChainInATernaryJoinsForTheLadder | `Joins`:611 `if (InUnbrokenTernary(chain.Start))` forced false | 2 failed: AnAuthorsChainInATernaryJoinsForTheLadder, Guide("Ternary ladder") |
| Chains wait for the ternary: a `:` scan stops at a line start | ATernaryColonAfterABrokenChainKeepsItsSpace, ACaseLabelAfterATernaryKeepsItsColonTight (*new*) | `SpacedColon`:1613 `if (_lineStart[k] && depth == 0 && !IsWasl(k)) return false;` forced false | 1 failed: ACaseLabelAfterATernaryKeepsItsColonTight |
| Outlier limit (A/B) | AnOutlierLeavesTheRun | `Align`:1357 `target - sorted[^2] > 8` forced false | 2 failed: AnOutlierLeavesTheRun, Guide("Outliers in a run") |
| `=` defaults: fields align their `=` | FieldDefaultsAlignTheirEquals | shapes:1267 `("field", [name, First(TokenKind.Equals, name, e)])` anchor replaced by `-1` | 4 failed: ADocCommentDoesNotEndARun, FieldDefaultsAlignTheirEquals, Guide("Doc comments in a run"), Guide("Field defaults") |
| `=` defaults: top-level consts align their `=` | TopLevelConstsAlignTheirEquals | shapes:1264 `or GlobalStatement { Statement: LocalDecl { Kind: BindingKind.Const } }` removed | 1 failed: TopLevelConstsAlignTheirEquals |
| C: `=>` first (Breaks) | AnArrowHeaderBreaksAfterTheArrowFirst, AnArrowHeaderBreaksAfterTheArrowBeforeAStructDefault (*new*) | `BreakLine`:860 `if (_headerArrow[k] && ...)` forced false | 1 failed: AnArrowHeaderBreaksAfterTheArrowBeforeAStructDefault |
| C: `=>` first (Joins, `HeaderArrow`) | AnAuthorsWrappedParametersJoinBeforeTheArrowBreaks | `Joins`:596 `HeaderArrow(c) is var arrow and > 0 && ...` forced false | 2 failed: AnAuthorsWrappedParametersJoinBeforeTheArrowBreaks, Guide("Arrow bodies") |
| E: scalar fill | AScalarListFillsToTheWidth | `BreakList`:778 `Row(o, starts, widths)` replaced by `1` | 3 failed: AScalarListFillsToTheWidth, AScalarListKeepsTheAuthorsFirstRow, Guide("Scalar lists") |
| E: the author's first row is kept | AScalarListKeepsTheAuthorsFirstRow | `Row`:827 `if (Fits(first)) return first;` forced false | 3 failed: AScalarListFillsToTheWidth, AScalarListKeepsTheAuthorsFirstRow, Guide("Scalar lists") |
| Case bodies go one level in | ACaseBodyGoesOneLevelIn | `Levels`:344 `top.Switch` forced false | 3 failed: ACaseBodyGoesOneLevelIn, ACaseLabelAfterATernaryKeepsItsColonTight, Guide("Case bodies") |
| An empty arm stays on its line | AnEmptyArmStaysOnItsLine | `Guide`:1111 `_lineStart[o] = false;` replaced by a no-op | 2 failed: AnEmptyArmStaysOnItsLine, Guide("Empty arms") |
| `///` does not end a run | ADocCommentDoesNotEndARun | `Separated`:1326 `&& !Doc(x)` removed | 2 failed: ADocCommentDoesNotEndARun, Guide("Doc comments in a run") |
| Round 4: the author's group break goes | AnAuthorsGroupBreakGivesWayToItsOperators | `Joins`:587 `_lineStart[k] = false;` in the group loop replaced by a no-op | 2 failed: AnAuthorsGroupBreakGivesWayToItsOperators, Guide("Groups that do not fit") |

The same filter on the restored `Layout.cs`: 1396 passed, 0 failed (Total: 1396).

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
| b11 `bayan fix` on a missing path exits 2 | `FixCommand.cs` the not-found branch returns `CliApp.ExitFailure` instead of `CliApp.ExitUsage` | caught: `CliTests.FixOfAMissingPathExits2LikeFormat` |
| b12 `conditions.patterns` takes relational terms in `\|\|` groups | `Parser.cs` `PatternItem` relational branch disabled (`if (false && relational && ...)`) | caught: `DiagTests.DiagGolden(diag/style-conditions-patterns.byn)`, `FormatTests.FixGivesTheFixedRunCase(conditions-patterns)` |
