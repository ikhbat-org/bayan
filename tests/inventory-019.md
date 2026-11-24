# Inventory 019: test counts at v0.3.2

Rows: `tests/inventory-019.tsv`. Counts below are from one listing run of the suite at the `v0.3.2` tag.

## Listing command

```
export PATH=$HOME/.dotnet:$PATH DOTNET_ROOT=$HOME/.dotnet
cd <v0.3.2 checkout>
nice dotnet test csharp/tests/Bayan.Tests/Bayan.Tests.csproj --list-tests -v q
```

`Bayan.Tests.csproj` compiles `src/tests/**/*.cs` too, so one listing covers both suites. The count of a class is the number of listed names `Bayan.Tests.<Class>.<Test>[(row)]`, theory rows expanded.

## Totals

- Classes: 224 (the plan says 215; the 9 classes the plan leaves out are not identified)
- Expanded tests: 15589

| Family | Classes | Tests |
|---|---|---|
| runtime-c | 7 | 35 |
| csharp-internals | 27 | 1604 |
| cli | 27 | 408 |
| golden-folder | 11 | 2816 |
| infrastructure | 10 | 44 |
| law | 15 | 218 |
| language-server | 2 | 42 |
| selfhost-lexer | 4 | 34 |
| selfhost-coverage | 1 | 4 |
| selfhost-default | 12 | 1075 |
| selfhost-driver | 14 | 1678 |
| selfhost-emitter | 21 | 1928 |
| selfhost-parser | 16 | 391 |
| selfhost-path | 4 | 1052 |
| selfhost-revision | 4 | 67 |
| selfhost-semantics | 41 | 4120 |
| selfhost-snapshot | 1 | 10 |
| selfhost-std | 2 | 19 |
| std | 5 | 44 |

## OQ10 estimate, in test counts

- 019a without the language server: 15486 tests to port (15589 minus 42 server tests minus 61 dropped or no counterpart)
- Server port: 42 tests (`LanguageServerLeakTests` 22, `LanguageServerWorkspaceTests` 20)
- 019b: 61 tests leave without a port, plus the removal commit

## Per-class counts

| Class | Family | Tests | Disposition |
|---|---|---|---|
| BootstrapTests | runtime-c | 7 | shell |
| BuiltinResultsTests | csharp-internals | 13 | sem |
| CInventoryTests | csharp-internals | 14 | bayan-test |
| CacheTests | cli | 24 | cli |
| CliEnvironmentTests | cli | 28 | cli |
| CliMemoryBoundsTests | cli | 25 | bayan-test |
| CliTests | cli | 64 | cli |
| CliToolchainTests | cli | 7 | cli |
| CollectionLiteralTests | csharp-internals | 3 | emit-c |
| ContrastTests | cli | 6 | shell |
| CoverageReportTests | cli | 8 | cli |
| CoverageSummaryTests | cli | 4 | cli |
| CoverageTests | golden-folder | 350 | golden |
| DiagJsonTests | golden-folder | 3 | golden |
| DiagTests | golden-folder | 642 | golden |
| DiagnosticCodesTests | csharp-internals | 11 | check |
| DiagnosticRendererTests | csharp-internals | 19 | cli |
| DynRefEmitTests | csharp-internals | 3 | emit-c |
| ErrorUnionTypeTests | csharp-internals | 1 | sem |
| ExternalModeTests | cli | 11 | cli |
| FormatTests | golden-folder | 76 | golden |
| FunctionTypeTests | csharp-internals | 12 | sem |
| GatesTests | cli | 8 | cli |
| GenericsTests | csharp-internals | 2 | emit-c |
| GoldenTests | infrastructure | 7 | dropped |
| GrammarDictionaryTests | csharp-internals | 8 | check |
| HashSeedTests | cli | 2 | run |
| HelpLanguageTests | cli | 2 | cli |
| InstrumentedRunLawTests | law | 1 | check |
| InterfaceDeclarationTests | csharp-internals | 4 | sem |
| InterfaceUseTests | csharp-internals | 2 | diag |
| L004UnionSwitchTests | law | 38 | check |
| L005RunBatchTests | law | 23 | check |
| L006OwnershipGuardTests | law | 69 | check |
| L007UntrustedSinkTests | law | 24 | check |
| L008OwnershipRuntimeTests | law | 3 | check |
| L010Utf8DecodeTests | law | 1 | check |
| L011ColourAddsOnlyEscapesTests | law | 23 | check |
| L012InterfaceDispatchTests | law | 2 | check |
| L013DirectAndIndirectCallsAgreeTests | law | 2 | check |
| L014CaptureByCopyTests | law | 13 | check |
| LambdaEmitTests | csharp-internals | 2 | emit-c |
| LanguageServerLeakTests | language-server | 22 | shell |
| LanguageServerWorkspaceTests | language-server | 20 | shell |
| LayoutTests | csharp-internals | 1393 | golden |
| LexDiffTests | infrastructure | 5 | shell |
| LexerCaseSnapshotRecordingTests | selfhost-lexer | 1 | dropped |
| LexerSnapshotRecordingTests | selfhost-lexer | 1 | dropped |
| LexerTests | golden-folder | 29 | golden |
| LfOutputTests | cli | 2 | run |
| LineDirectiveTests | cli | 7 | emit-c |
| LoweringInvariantTests | csharp-internals | 5 | no counterpart |
| ManifestTests | cli | 70 | cli |
| MapKeyEmitTests | csharp-internals | 5 | emit-c |
| MapKeyLawTests | law | 13 | check |
| MapModelTests | csharp-internals | 49 | bayan-test |
| MessagesTests | csharp-internals | 4 | no counterpart |
| MutantSchemataTests | golden-folder | 362 | golden |
| MutationRunnerTests | cli | 6 | cli |
| MutatorTests | csharp-internals | 17 | cli |
| NamingGrammarTests | csharp-internals | 25 | diag |
| NamingPackageGrammarTests | csharp-internals | 2 | diag |
| NeverReassignedVarLintTests | cli | 24 | diag |
| NotEmittedLawTests | law | 2 | check |
| OutputTests | cli | 14 | cli |
| OwnershipCheckerTests | golden-folder | 368 | golden |
| OwnershipGeneratorTests | runtime-c | 3 | shell |
| OwnershipTableTests | runtime-c | 3 | shell |
| ParserPerfTests | csharp-internals | 2 | bayan-test |
| ParserTests | golden-folder | 217 | golden |
| PeakSamplerTests | infrastructure | 1 | dropped |
| PowerAssertTests | cli | 8 | cli |
| ProgressTests | cli | 11 | cli |
| QualityReportTests | cli | 8 | cli |
| RegionAnalysisPerfTests | csharp-internals | 1 | check |
| RunTests | golden-folder | 346 | golden |
| RuntimeNativeTests | runtime-c | 15 | shell |
| RuntimeSizeOverflowTests | runtime-c | 1 | shell |
| ScaffoldTests | cli | 17 | cli |
| SelfhostCoverageTests | selfhost-coverage | 4 | cli |
| SelfhostDefaultBoundsTests | selfhost-default | 17 | bayan-test |
| SelfhostDefaultJsonCountTests | selfhost-default | 1 | cli |
| SelfhostDefaultP2Tests | selfhost-default | 3 | cli |
| SelfhostDefaultSpeedTests | selfhost-default | 1 | bayan-test |
| SelfhostDefaultT10Tests | selfhost-default | 701 | cli |
| SelfhostDefaultT12Tests | selfhost-default | 86 | cli |
| SelfhostDefaultT1Tests | selfhost-default | 32 | cli |
| SelfhostDefaultT2Tests | selfhost-default | 25 | cli |
| SelfhostDefaultT3Tests | selfhost-default | 31 | cli |
| SelfhostDefaultT4Tests | selfhost-default | 65 | cli |
| SelfhostDefaultT5Tests | selfhost-default | 19 | cli |
| SelfhostDefaultT9Tests | selfhost-default | 94 | cli |
| SelfhostDriverApiTests | selfhost-driver | 2 | cli |
| SelfhostDriverFixTests | selfhost-driver | 33 | cli |
| SelfhostDriverGoldenTests | selfhost-driver | 187 | golden |
| SelfhostDriverMutateTests | selfhost-driver | 46 | cli |
| SelfhostDriverRuntimeTests | selfhost-driver | 2 | cli |
| SelfhostDriverStage2FormatTests | selfhost-driver | 139 | cli |
| SelfhostDriverStyleCaseTests | selfhost-driver | 147 | cli |
| SelfhostDriverStyleEnvironmentTests | selfhost-driver | 84 | cli |
| SelfhostDriverStyleLintsTests | selfhost-driver | 13 | cli |
| SelfhostDriverT1Tests | selfhost-driver | 181 | cli |
| SelfhostDriverT2Tests | selfhost-driver | 761 | cli |
| SelfhostDriverT3Tests | selfhost-driver | 62 | cli |
| SelfhostDriverT5Tests | selfhost-driver | 16 | cli |
| SelfhostDriverT8Tests | selfhost-driver | 5 | cli |
| SelfhostEmitterApiTests | selfhost-emitter | 2 | emit-c |
| SelfhostEmitterEquivalenceLawTests | selfhost-emitter | 7 | check |
| SelfhostEmitterHarnessTests | selfhost-emitter | 1422 | emit-c |
| SelfhostEmitterNoPanicLawTests | selfhost-emitter | 3 | check |
| SelfhostEmitterParityTests | selfhost-emitter | 353 | emit-c |
| SelfhostEmitterPrinterBoundaryTests | selfhost-emitter | 9 | emit-c |
| SelfhostEmitterSpeedTests | selfhost-emitter | 1 | bayan-test |
| SelfhostEmitterT10Tests | selfhost-emitter | 7 | emit-c |
| SelfhostEmitterT11Tests | selfhost-emitter | 6 | emit-c |
| SelfhostEmitterT13Tests | selfhost-emitter | 1 | emit-c |
| SelfhostEmitterT21Tests | selfhost-emitter | 2 | emit-c |
| SelfhostEmitterT22Tests | selfhost-emitter | 5 | emit-c |
| SelfhostEmitterT2Tests | selfhost-emitter | 10 | emit-c |
| SelfhostEmitterT3Tests | selfhost-emitter | 11 | emit-c |
| SelfhostEmitterT4Tests | selfhost-emitter | 26 | emit-c |
| SelfhostEmitterT5Tests | selfhost-emitter | 5 | emit-c |
| SelfhostEmitterT6Tests | selfhost-emitter | 32 | emit-c |
| SelfhostEmitterT7Tests | selfhost-emitter | 13 | emit-c |
| SelfhostEmitterT8Tests | selfhost-emitter | 7 | emit-c |
| SelfhostEmitterT9Tests | selfhost-emitter | 3 | emit-c |
| SelfhostEmitterTests | selfhost-emitter | 3 | emit-c |
| SelfhostLexerCaseTests | selfhost-lexer | 1 | lex |
| SelfhostLexerTests | selfhost-lexer | 31 | lex |
| SelfhostParserEquivalenceLawTests | selfhost-parser | 1 | check |
| SelfhostParserGeneratorTests | selfhost-parser | 6 | dropped |
| SelfhostParserNoPanicLawTests | selfhost-parser | 1 | check |
| SelfhostParserO3Tests | selfhost-parser | 7 | parse |
| SelfhostParserT10Tests | selfhost-parser | 1 | parse |
| SelfhostParserT11Tests | selfhost-parser | 1 | parse |
| SelfhostParserT12Tests | selfhost-parser | 2 | parse |
| SelfhostParserT13Tests | selfhost-parser | 5 | parse |
| SelfhostParserT3Tests | selfhost-parser | 2 | parse |
| SelfhostParserT4Tests | selfhost-parser | 1 | parse |
| SelfhostParserT5Tests | selfhost-parser | 1 | parse |
| SelfhostParserT6Tests | selfhost-parser | 66 | parse |
| SelfhostParserT7Tests | selfhost-parser | 31 | parse |
| SelfhostParserT8Tests | selfhost-parser | 1 | parse |
| SelfhostParserT9Tests | selfhost-parser | 1 | parse |
| SelfhostParserTests | selfhost-parser | 264 | parse |
| SelfhostPathT4Tests | selfhost-path | 1029 | bayan-test |
| SelfhostPathT5Tests | selfhost-path | 10 | bayan-test |
| SelfhostPathT7Tests | selfhost-path | 10 | bayan-test |
| SelfhostPathT8Tests | selfhost-path | 3 | bayan-test |
| SelfhostRevisionT2Tests | selfhost-revision | 20 | run |
| SelfhostRevisionT4Tests | selfhost-revision | 24 | run |
| SelfhostRevisionT7Tests | selfhost-revision | 14 | run |
| SelfhostRevisionT8Tests | selfhost-revision | 9 | run |
| SelfhostSemanticsApiTests | selfhost-semantics | 1 | sem |
| SelfhostSemanticsCorpusParityTests | selfhost-semantics | 2 | sem |
| SelfhostSemanticsEquivalenceLawTests | selfhost-semantics | 1 | check |
| SelfhostSemanticsGeneratorTests | selfhost-semantics | 6 | dropped |
| SelfhostSemanticsHarnessTests | selfhost-semantics | 5 | dropped |
| SelfhostSemanticsHostTests | selfhost-semantics | 5 | sem |
| SelfhostSemanticsNoPanicLawTests | selfhost-semantics | 2 | check |
| SelfhostSemanticsParityTests | selfhost-semantics | 1302 | sem |
| SelfhostSemanticsT10Tests | selfhost-semantics | 94 | sem |
| SelfhostSemanticsT11Tests | selfhost-semantics | 35 | sem |
| SelfhostSemanticsT12Tests | selfhost-semantics | 11 | sem |
| SelfhostSemanticsT13Tests | selfhost-semantics | 18 | sem |
| SelfhostSemanticsT14Tests | selfhost-semantics | 8 | sem |
| SelfhostSemanticsT15Tests | selfhost-semantics | 47 | sem |
| SelfhostSemanticsT16Tests | selfhost-semantics | 25 | sem |
| SelfhostSemanticsT17Tests | selfhost-semantics | 118 | sem |
| SelfhostSemanticsT18Tests | selfhost-semantics | 125 | sem |
| SelfhostSemanticsT19Tests | selfhost-semantics | 220 | sem |
| SelfhostSemanticsT20Tests | selfhost-semantics | 98 | sem |
| SelfhostSemanticsT21Tests | selfhost-semantics | 98 | sem |
| SelfhostSemanticsT22Tests | selfhost-semantics | 45 | sem |
| SelfhostSemanticsT23Tests | selfhost-semantics | 51 | sem |
| SelfhostSemanticsT24Tests | selfhost-semantics | 100 | sem |
| SelfhostSemanticsT25Tests | selfhost-semantics | 152 | sem |
| SelfhostSemanticsT2Tests | selfhost-semantics | 8 | sem |
| SelfhostSemanticsT34Tests | selfhost-semantics | 95 | sem |
| SelfhostSemanticsT35Tests | selfhost-semantics | 161 | sem |
| SelfhostSemanticsT36Tests | selfhost-semantics | 29 | sem |
| SelfhostSemanticsT37Tests | selfhost-semantics | 98 | sem |
| SelfhostSemanticsT38Tests | selfhost-semantics | 4 | sem |
| SelfhostSemanticsT39Tests | selfhost-semantics | 48 | sem |
| SelfhostSemanticsT3Tests | selfhost-semantics | 5 | sem |
| SelfhostSemanticsT40Tests | selfhost-semantics | 5 | sem |
| SelfhostSemanticsT41Tests | selfhost-semantics | 993 | sem |
| SelfhostSemanticsT4Tests | selfhost-semantics | 5 | sem |
| SelfhostSemanticsT5Tests | selfhost-semantics | 3 | sem |
| SelfhostSemanticsT6Tests | selfhost-semantics | 8 | sem |
| SelfhostSemanticsT7Tests | selfhost-semantics | 39 | sem |
| SelfhostSemanticsT8Tests | selfhost-semantics | 6 | sem |
| SelfhostSemanticsT9Tests | selfhost-semantics | 8 | sem |
| SelfhostSemanticsTests | selfhost-semantics | 36 | sem |
| SelfhostSnapshotTests | selfhost-snapshot | 10 | emit-c |
| SelfhostStdImportTests | selfhost-std | 17 | run |
| SelfhostStdSourceTests | selfhost-std | 2 | shell |
| SipHashTests | runtime-c | 1 | shell |
| SnapshotSkipTraitTests | infrastructure | 10 | dropped |
| StateLiteralTests | cli | 1 | run |
| StdEnvTests | std | 6 | bayan-test |
| StdFsTests | std | 17 | bayan-test |
| StdImportTests | std | 13 | run |
| StdPathLawTests | law | 2 | check |
| StdPathTests | std | 5 | bayan-test |
| StdTestFilesTests | std | 3 | shell |
| StyleGuideExamplesTests | cli | 34 | diag |
| StyleLintSeverityTests | cli | 5 | diag |
| StyleTests | golden-folder | 22 | golden |
| SymbolEmitTests | csharp-internals | 3 | emit-c |
| SymbolLawTests | law | 2 | check |
| SymbolLoweringTests | csharp-internals | 1 | run |
| SyntaxFuzzTests | infrastructure | 1 | dropped |
| TargetTests | cli | 8 | run |
| TempSweepTests | infrastructure | 1 | dropped |
| TestDirsTests | infrastructure | 2 | dropped |
| TestTimeTests | infrastructure | 9 | dropped |
| ToolchainSanitizerTests | runtime-c | 5 | run |
| TypedDumpTests | golden-folder | 401 | golden |
| UnionValueTests | csharp-internals | 1 | run |
| UnobservableBindingTests | cli | 4 | diag |
| UserIterationTests | csharp-internals | 2 | run |
| WarmUpTests | infrastructure | 2 | dropped |
| ZigVersionPinTests | infrastructure | 6 | shell |
