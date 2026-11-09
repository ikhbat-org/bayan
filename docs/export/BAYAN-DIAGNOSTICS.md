Commit `8d5e5c71`, 2026-11-09.

# Bayān diagnostics

Every `BYN` code, from `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs`, `docs/diagnostics/`, the A2 scheme (`docs/revisions/0017-addendum-a2-diagnostic-codes.md`) and the plans and revisions that allocate codes. Message text is the format string as written in the source: `{0}` is an argument, `{{` and `}}` are literal braces.

## Status

- `live`: emitted somewhere under `src/`, `selfhost/`, `editors/` or `tools/` (a use of the descriptor outside `DiagnosticCodes.cs`). Every live code also has a `docs/diagnostics/` page.
- `plan`: allocated, with a name and message, in a plan, spec or revision but absent from `DiagnosticCodes.cs`.
- `reserved`: the number is set aside (a descriptor kept for a later feature, or a round-4 comment line) and nothing reports it.
- `retired`: a descriptor and page kept, never reported again, number never reused.

Severity is a default; A2 rule 5 says it is not encoded in the number.

## Counts

| Status | Codes |
|---|---|
| live | 314 |
| plan | 10 |
| reserved | 9 |
| retired | 10 |
| total | 343 |

Descriptors in `DiagnosticCodes.cs`: 328 (314 live, 10 retired, 4 reserved). Round-4 reserved comment lines: 4. Allocated elsewhere: 10 plan, 1 further reserved (BYN8004).

## Registered codes (`DiagnosticCodes.cs`)

Evidence for live is the first file that uses the descriptor plus the number of files under `tests/cases/` that name the code.

| Code | Name | Message | Severity | Status | Evidence / note |
|---|---|---|---|---|---|
| BYN0001 | BidiControl | bidirectional control character U+{0} is not allowed outside string literals | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0002 | UnexpectedCharacter | unexpected character `{0}` | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0003 | UnterminatedString | unterminated string literal | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 2 golden file(s) |
| BYN0004 | UnterminatedComment | unterminated block comment | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0005 | IdentifierNotNfc | identifier `{0}` is not in Unicode normalization form C | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 2 golden file(s) |
| BYN0006 | InvalidEscape | invalid escape sequence `{0}` | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 2 golden file(s) |
| BYN0007 | EmptyCharLiteral | empty char literal | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0008 | UnterminatedCharLiteral | unterminated char literal | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0009 | CharLiteralTooLong | a char literal holds exactly one Unicode scalar | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0010 | InvalidNumber | invalid numeric literal: {0} | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0011 | SuffixOnHexOrBinary | unit suffix `{0}` is not allowed on a {1} literal | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0012 | ReservedKeyword | `{0}` is reserved and cannot be used as an identifier | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 2 golden file(s) |
| BYN0013 | InvalidUnicodeEscape | `{0}` is not a Unicode scalar value | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0014 | UnescapedCloseBrace | `}}` in an interpolated string must be doubled | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0015 | InvalidUtf8 | source is not valid UTF-8 (byte 0x{0}) | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN0016 | InterpolationTooDeep | interpolated strings are nested too deeply | Error | live | src/Bayan.Syntax/Lexing/Lexer.cs; 1 golden file(s) |
| BYN1001 | Expected | expected {0}, found {1} | Error | live | selfhost/semantics/conformance.byn; 9 golden file(s) |
| BYN1002 | ExpectedExpression | expected an expression, found {0} | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 3 golden file(s) |
| BYN1003 | ExpectedType | expected a type, found {0} | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1004 | ExpectedMember | expected a field, property, constructor or method, found {0} | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1005 | MissingLineBreak | expected a line break after the statement | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 4 golden file(s) |
| BYN1006 | UnlessWithElse | `unless` cannot have an `else` branch | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 4 golden file(s) |
| BYN1007 | UnlessNegated | `unless` with a negated condition is a double negative | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 6 golden file(s) |
| BYN1008 | PostfixNotSimple | a postfix `{0}` applies only to a simple statement | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN1009 | PostfixChained | postfix conditions cannot be chained | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1010 | Goto | `goto` does not exist in Bayan | Error | live | selfhost/parser/codes.byn; 2 golden file(s) |
| BYN1011 | InvalidAssignmentTarget | cannot assign to this expression | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1012 | InvalidExpressionStatement | this expression does nothing as a statement | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 5 golden file(s) |
| BYN1013 | TernaryInCollection | a conditional expression inside a collection literal must be parenthesized | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1014 | StackedCaseLabels | stacked `case` labels | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1015 | CStyleFor | C-style `for` loops do not exist in Bayan | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1016 | ModifierNotAllowed | `{0}` is not allowed here | Error | live | src/Bayan.Semantics/Compilation.cs; 8 golden file(s) |
| BYN1017 | ParenthesizedCondition | parentheses around a condition are an input form | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 6 golden file(s) |
| BYN1018 | BodyNeedsBraces | the body of `{0}` must be a block | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 7 golden file(s) |
| BYN1019 | ForInputForm | `for (let x in xs)` is an input form; write `for x in xs` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 3 golden file(s) |
| BYN1020 | ErrdeferInput | `errdefer` is now `defer failing` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1021 | FieldInitEquals | `{0} = …` in a literal is an input form; write `{0}: …` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 4 golden file(s) |
| BYN1022 | UnlessCompound | `unless` with `&&`/`\|\|` reads as a double negative | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 3 golden file(s) |
| BYN1023 | UnlessNull | `unless x is null` is not allowed; write `if x is not null` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN1025 | CatchBinding | `catch (e)` is an input form; bind the error in a `catch switch` arm | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1028 | DelegateDecl | `delegate` is not Bayan; write a function type `type {0} = {1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 3 golden file(s) |
| BYN1029 | ErrorSetPipe | an error set is declared `union error {0} = A, B` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1030 | RetiredCSharpTypeName | retired: C# primitive names are accepted | Error | retired | C# primitive names accepted (round 3 §28) |
| BYN1031 | FailsShorthand | `T!E` is an input form; write `T f() fails E` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 9 golden file(s) |
| BYN1032 | RetiredNegatedIfToUnless | retired: `if !x` is no longer rewritten | Error | retired | `if !x` no longer rewritten (round 3 §5) |
| BYN1033 | UnlessLikelihood | `unless` takes no likelihood word; write `if unlikely !…` or drop `{0}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1040 | SemicolonInput | `;` is an input form; a statement ends at the newline | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 5 golden file(s) |
| BYN1041 | ElseOnNewLine | `else` must follow `}}` on the same line | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1042 | OnNewLine | `{0}` takes its value on the same line | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s); second message form for a stranded postfix modifier |
| BYN1043 | TypeNameOrder | `{0}` is an input form; write `{1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 4 golden file(s) |
| BYN1044 | DeclarationKeywordOrder | `{0}` is an input form; write `{1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1045 | BracketAttribute | `[{0}]` is an input form; write `@{1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1046 | PatternOutsideConst | `pattern` is allowed only after `=` in a `const` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1047 | BlockComment | `/* */` is an input form; write `//` lines | Error | live | editors/language-server/Analysis/Indexer.cs; 3 golden file(s) |
| BYN1048 | CharInput | `char` is now `rune` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1049 | RetiredUnlessNot | retired: merged into BYN1007 | Error | retired | never raised; merged into BYN1007 |
| BYN1050 | RequiresValue | `value` in `requires` is now `it` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1051 | ExceptInCase | `except` is not allowed in a `case` pattern | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 3 golden file(s) |
| BYN1052 | ExceptNotPattern | `except` takes a pattern, not a condition | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1053 | OneLineDeclarations | `{0}` declares its cases on one line; write one per line | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1054 | TryCoversMore | `try` covers `{0}`, which cannot fail | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN1055 | FatArrowFunctionType | `=>` in a type is an input form; write `->` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN1056 | ReturnErrorInput | `return .{0}` returns an error; write `fail .{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 2 golden file(s) |
| BYN1057 | CastInput | `({0})x` is an input form; write `{0}(x)` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN1058 | RestInput | `{0}` is an input form; write `rest ReadOnlySpan<{1}> {2}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1059 | StateLineInput | `state {0}` is an input form; declare the states in one `states {{ … }}` block | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1060 | InterfaceGetInput | `{0} {1} {{ get }}` is an input form; write `{0} {1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1061 | ReceiverWithoutState | `this` without a state is the default receiver | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1062 | TrustInput | `trust(x, reason: …)` is now `x.trustUnchecked() because \"…\"` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1063 | RequiresOnFunction | `requires` on a function is an input form; write `expects` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1064 | PayloadNeedsName | payload `{0}` of `.{1}` needs a name | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1065 | ClauseOrder | `{0}` must come before `{1}`; the order is `where`, `expects`, `uses`, `becomes`, `fails` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 5 golden file(s) |
| BYN1066 | PrefixPointerInput | `{0}` is an input form; write `{1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1067 | PointerOutsideExtern | pointer types are allowed only in `extern` declarations | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN1068 | CompactFormatSpec | `{0}` is an input form; write `{1}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN1069 | StatementAttribute | attribute `{0}` is not allowed before a statement | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN2001 | UndefinedName | `{0}` is not defined | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 8 golden file(s) |
| BYN2002 | UnknownType | unknown type `{0}` | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2003 | UnknownMember | `{0}` is not a member of `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 20 golden file(s) |
| BYN2004 | UnknownModule | no module `{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2005 | NotVisible | `{0}` is not visible here | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2006 | DuplicateDeclaration | `{0}` is declared twice | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 5 golden file(s) |
| BYN2007 | Shadowing | `{0}` is already a local here | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2008 | TypeCasing | type name `{0}` must be PascalCase | Error | live | src/Bayan.Semantics/Naming.cs; 2 golden file(s) |
| BYN2009 | ValueCasing | `{0}` must be camelCase | Error | live | src/Bayan.Semantics/Naming.cs; 3 golden file(s) |
| BYN2010 | ImportCycle | import cycle: {0} | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2011 | CircularAlias | type alias `{0}` refers to itself | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2012 | CircularConstant | constant `{0}` depends on itself | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2013 | DuplicateMain | the program has two entry points | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2014 | NoMain | the program has no entry point | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2015 | StatementOutsideEntry | top-level statements are allowed only in the entry module | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2017 | InstanceMemberWithoutThis | `{0}` needs an instance | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2018 | ThisOutsideMethod | `this` is only available inside instance methods | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2019 | NotAValue | `{0}` is a {1}, not a value | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 4 golden file(s) |
| BYN2020 | UnknownLabel | no enclosing loop is labeled `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2021 | UnknownParameter | `{0}` has no parameter `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN2022 | Unsupported | {0} is not supported in v0.1 | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 8 golden file(s) |
| BYN2023 | WrongTypeArgumentCount | `{0}` takes {1} type argument(s), not {2} | Error | live | src/Bayan.Semantics/TypeResolver.cs; 8 golden file(s) |
| BYN2024 | NestedOptional | `{0}?` is already optional | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2025 | VoidValue | `void` is not a value type | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2026 | DeclarationAsBody | a declaration cannot be the whole body of a statement | Error | retired | braceless body is BYN1018 (round 2) |
| BYN2027 | NullEquality | compare with `is null` / `is not null`, not `==` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2028 | SameTypeShadowing | `{0}` shadows an earlier `{0}` of the same type `{1}` | Warning | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2029 | NestedIt | `it` inside a lambda that already uses `it`; name one lambda | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2031 | ToStringCall | Bayan has no `toString()`; display is `format()` (derived from `formatInto(ref StrBuf)`) | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2032 | UnknownStdModule | no std module `{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2033 | StdImportsPackage | std module `{0}` imports `{1}`, which is not a std module | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2034 | CircularFieldDefault | the default of field `{0}` depends on itself | Error | live | src/Bayan.Semantics/Compilation.cs; 3 golden file(s) |
| BYN2101 | MissingInitializer | `{0} {1}` needs a value | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2102 | UseBeforeAssign | `{0}` is used before it is assigned | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 2 golden file(s) |
| BYN2103 | OutNotAssigned | `out` parameter `{0}` is not assigned on every path | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 1 golden file(s) |
| BYN2104 | ImmutableAssignment | `{0}` is immutable | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 21 golden file(s) |
| BYN2105 | ReadonlyField | field `{0}` is readonly | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2106 | MutateTemporary | cannot modify this value | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 20 golden file(s) |
| BYN2107 | GetterMutates | property `{0}` modifies the value | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2108 | RequiredWithDefault | required field `{0}` has a default value | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2109 | MissingFields | `{0}` needs a value for `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2110 | DuplicateFieldInit | field `{0}` is set twice | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2111 | LiteralWithConstructor | `{0}` has a constructor; call it instead of using a struct literal | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2112 | NoConstructor | `{0}` has no constructor | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2113 | RecursiveStruct | struct `{0}` contains itself | Error | retired | superseded by BYN2761 since M21 |
| BYN2114 | NotAStruct | `{0}` is not a struct | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2115 | MutatesWithoutRefThis | `{0}` modifies `this` but is not declared `ref this` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2116 | RefThisOnOperator | operators cannot take `ref this` | Error | reserved | operators with `ref this`; operator declarations are spec-only (spec §2) |
| BYN2117 | RefThisNotFirst | `ref this` must be the first parameter | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN2201 | StringIndexer | a `string` cannot be indexed | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2202 | TypeMismatch | expected `{1}`, found `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 13 golden file(s) |
| BYN2203 | LiteralOutOfRange | {0} does not fit in {1} | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN2204 | ConstantOverflow | constant arithmetic overflows `{0}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2205 | DivisionByZero | division by zero | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2206 | InvalidCast | cannot convert `{0}` to `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2207 | BadUnaryOperand | `{0}` cannot be applied to `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2208 | BadBinaryOperands | `{0}` cannot be applied to `{1}` and `{2}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 6 golden file(s) |
| BYN2209 | StringConcatenation | strings cannot be joined with `+`; use interpolation | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2210 | CoalesceNotOptional | `??` needs an optional value on the left, found `{0}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2211 | MemberOfOptional | `{0}` is not a member of `{1}`; the value may be null | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2212 | NotIndexable | `{0}` cannot be indexed | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2213 | IndexOutOfRange | index {0} is out of range for `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2214 | FromEndOutsideIndex | `^` is only allowed inside an index or slice | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2215 | OpenRange | a range needs both ends here | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2216 | BranchTypeMismatch | branches have different types: `{0}` and `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2217 | CannotInferType | cannot infer the type of `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2218 | NoTargetType | `{0}` needs a known type here | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 3 golden file(s) |
| BYN2219 | NotConstant | {0} must be a compile-time constant | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN2220 | NotCallable | `{0}` cannot be called | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2221 | NotIterable | `{0}` cannot be iterated | Error | live | selfhost/semantics/binder3.byn; 2 golden file(s) |
| BYN2222 | ArrayLengthMismatch | `{0}` needs exactly its length in elements, found {1} | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2223 | TupleNameMismatch | tuple element `{0}` is named `{1}` in the target type | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2224 | InterpolationNotAllowed | an interpolated string must be passed directly to an output | Error | retired | `$"…"` is an expression anywhere since M14 |
| BYN2225 | NotFormattable | `{0}` cannot be formatted | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 7 golden file(s) |
| BYN2226 | NotDisposable | `using` needs a value that owns memory, not `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2227 | AmbiguousVariant | `.{0}` is ambiguous; it exists in `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN2228 | UnknownVariant | `{0}` is not a variant of `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 5 golden file(s) |
| BYN2229 | InvalidConstArray | module-level `const` array `{0}` must hold literal numbers, `bool`s, `rune`s or `string`s | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2230 | RenamedMember | `{0}` is now `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 9 golden file(s) |
| BYN2234 | WhileLetNotOptional | `while let` needs a `T?` value, got `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2235 | SpreadNotSequence | `..{0}` spreads a `{1}`, which is not a sequence | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2236 | MapLiteralMixed | a map literal needs `key: value` in every element | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2301 | MissingArgument | missing argument `{0}` for `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 2 golden file(s) |
| BYN2302 | TooManyArguments | `{0}` takes {1} argument(s) | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 4 golden file(s) |
| BYN2303 | DuplicateArgument | `{0}` is passed twice | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2304 | PositionalAfterNamed | a positional argument cannot follow a named one | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2305 | ArgumentMustBeNamed | argument for `{0}` must be named | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2306 | ArgumentModifierMismatch | argument for `{0}` must be passed as {1} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2307 | RetiredArgumentsSwapped | retired: particles replace the same-type naming rule | Error | retired | particles replace same-type naming; swap is BYN5005 (round 3 §15) |
| BYN2310 | SpanParameterNeverWritten | `{0}` is never written through; use `ReadOnlySpan<{1}>` | Warning | live | src/Bayan.Semantics/Binding/SpanParameterLint.cs; 2 golden file(s) |
| BYN2311 | NeverReassignedVar | `{0}` is never reassigned; declare it with `let` | Warning | live | src/Bayan.Semantics/Binding/NeverReassignedVarLint.cs; 5 golden file(s) |
| BYN2320 | RequiresNotBool | a `requires` clause must be `bool`, got `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2321 | RequiresViolated | `{0}` violates `requires {1}` of `{2}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 3 golden file(s) |
| BYN2322 | RetiredRequiresNotHere | retired: `requires` is checked at construction | Error | retired | `requires` checked at construction (round 3 step 5.3b, rev 0006) |
| BYN2401 | MissingReturn | `{0}` must return `{1}` on every path | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 3 golden file(s) |
| BYN2402 | MissingReturnValue | this function returns `{0}`; `return` needs a value | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2403 | ReturnValueInVoid | `{0}` returns nothing, but `return` has a value | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2404 | NeverReturns | `{0}` returns `never` but can reach its end | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 1 golden file(s) |
| BYN2405 | UnreachableCode | unreachable code | Warning | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 1 golden file(s) |
| BYN2406 | JumpOutsideLoop | `{0}` outside a loop | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN2407 | ContinueSwitch | `continue {0}` refers to a `switch`, not a loop | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2408 | LabelNotOnLoop | label `{0}` must be on a loop or `switch` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2409 | DuplicateDefault | `switch` has more than one `default` section | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2410 | NonExhaustive | `switch` does not handle every `{0}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 14 golden file(s) |
| BYN2411 | PatternMismatch | {0} cannot match `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 6 golden file(s) |
| BYN2601 | TryInDefer | `try` is not allowed in `defer` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2602 | UnhandledFailure | `{0}` can fail; handle the error or pass it on | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 4 golden file(s) |
| BYN2603 | UndeclaredError | `{0}` is not in the `fails` clause of `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 7 golden file(s) |
| BYN2604 | PropagateFromInfallible | `{0}` cannot fail, so it cannot pass on `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 2 golden file(s) |
| BYN2605 | NothingToHandle | `{0}` needs a call that can fail | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 6 golden file(s) |
| BYN2606 | ErrdeferWithoutFails | `defer failing` in a function that cannot fail | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 2 golden file(s) |
| BYN2607 | PublicInferredFails | public function `{0}` must list its errors | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2608 | NotAnErrorSet | `{0}` is not an error enum | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2609 | EmptyErrorSet | error enum `{0}` has no variants | Error | live | src/Bayan.Semantics/Compilation.cs; 2 golden file(s) |
| BYN2610 | JumpOutOfDefer | `{0}` cannot leave a `defer` or `defer failing` body | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 2 golden file(s) |
| BYN2611 | CatchBlockCompletes | this `catch` block can complete normally; end it with `return`, `break`, `continue` or a panic | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 2 golden file(s) |
| BYN2612 | PanicHandlerRestricted | {0} is not allowed in a panic handler | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 8 golden file(s) |
| BYN2613 | PanicHandlerReads | a panic handler reads only `let` bindings and parameters | Error | live | src/Bayan.Semantics/Binding/PanicHandlerCheck.cs; 1 golden file(s) |
| BYN2614 | OnPanicPlacement | `Panic.handler` may be set only as the first statement of `main` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN2615 | PanicHandlerReadsMoved | a panic handler reads `{0}`, which is moved after the handler is registered | Error | live | src/Bayan.Semantics/Binding/OwnershipAnalysis.cs; 2 golden file(s) |
| BYN2700 | UnknownUnionVariant | `{0}` is not a variant of union `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2701 | DuplicateUnionVariant | union `{0}` already has a variant `{1}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2702 | EmptyUnion | union `{0}` has no variants | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2703 | VariantPatternArity | variant `{0}` has {1} payload field(s), but the pattern lists {2} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2704 | PayloadNeedsPattern | the payload of a `{0}` is read with a pattern, not `.{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2705 | VariantNeedsPayload | variant `{0}` carries a payload | Error | live | src/Bayan.Semantics/Binding/BinderErrors.cs; 2 golden file(s) |
| BYN2706 | VariantHasNoPayload | variant `{0}` has no payload | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 3 golden file(s) |
| BYN2707 | RecursiveUnion | union `{0}` contains itself | Error | retired | superseded by BYN2761 since M21 |
| BYN2708 | BorrowPayload | a union payload cannot hold a borrowed `{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2709 | UnionValueNotInteger | a case value must be an integer constant | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2710 | UnionValueOnPayload | `{0}` carries data and cannot have a value | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2711 | DuplicateUnionValue | `{0}` and `{1}` share the value {2} | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2712 | WildcardOnLocalUnion | `_` hides future cases of `{0}`, declared in this package | Warning | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 3 golden file(s) |
| BYN2720 | UnknownEnumMember | `{0}` is not a member of `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 3 golden file(s) |
| BYN2721 | DuplicateEnumMember | enum `{0}` already has a member `{1}` | Error | live | src/Bayan.Semantics/Compilation.cs; 2 golden file(s) |
| BYN2722 | EmptyEnum | enum `{0}` has no members | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2723 | EnumArgumentNotConstant | argument `{0}` of `{1}` must be a compile-time constant | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2724 | InvalidEnumParameter | enum parameter `{0}` must be a number, `bool`, `rune`, `string` or a plain enum | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2740 | CannotInferTypeArgument | cannot infer type argument `{0}` of `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2741 | ConflictingTypeArgument | type argument `{0}` of `{1}` is inferred as both `{2}` and `{3}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2742 | GenericArgumentCount | `{0}` takes {1} type argument(s), not {2} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2743 | TypeParameterOperator | `{0}` cannot be applied to a value of type parameter `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2744 | TypeParameterMember | `{0}` is not a member of type parameter `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2760 | InvalidMapKey | `{0}` cannot be a `Map` key | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 4 golden file(s) |
| BYN2761 | RecursiveByValue | `{0}` contains itself by value: {1} | Error | live | src/Bayan.Semantics/Compilation.cs; 3 golden file(s) |
| BYN2762 | SharedStorageCopy | a `{0}` cannot be copied | Error | retired | replaced by BYN2780 (spec 002) |
| BYN2770 | UnknownAttribute | unknown attribute `{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 2 golden file(s) |
| BYN2771 | InvalidMainSignature | `main` must return `void` or `i32` and take nothing or `ReadOnlySpan<string> args` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2772 | InvalidExitCode | `@exitCode` needs one integer constant from 1 to 255 | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2773 | CasesArity | `@cases` gives {0} values but the test takes {1} parameters | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2774 | CasesNotConstant | each `@cases` value must be a constant | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2775 | AssertNotBool | `assert` needs a `bool`, got `{0}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN2780 | ImplicitCopy | implicit copy of a unique value: {0} | Error | live | src/Bayan.Semantics/Binding/OwnershipAnalysis.cs; 16 golden file(s) |
| BYN2781 | UseAfterMove | `{0}` is used after it was moved | Error | live | src/Bayan.Semantics/Binding/OwnershipAnalysis.cs; 16 golden file(s) |
| BYN2782 | CannotMove | cannot move out of {0} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN2783 | MutateBorrow | `{0}` borrows from what it was bound to and cannot be changed or moved | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN2784 | CopyUniqueElement | a `{0}` holding `{1}` cannot be copied: the copy would share its storage | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2785 | MapSlotNoDefault | `slot` needs a default value, and `{0}` has none | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2786 | UntrustedSink | `{0}` cannot be passed to `{1}`: it is `Untrusted` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2787 | TrustReason | `trust` needs a reason: a non-empty string literal | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN2788 | TakeUnsupported | `take()` needs a `List`, `Map`, `StrBuf` or an optional of a unique type, not `{0}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2789 | SwitchMoveSubject | `switch move …` needs a local or a `move` parameter, not {0} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2790 | OwningPatternOverlap | pattern `{0}` binds the same storage more than once in `switch move …` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN2791 | OwningBindingMutatedInGuard | `{0}` is mutated in the guard of `switch move …`; a guard that fails gives the value back | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 3 golden file(s) |
| BYN2800 | InterfaceName | `{0}` must start with `I` and an uppercase letter | Error | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s) |
| BYN2801 | MissingInterfaceMember | `{0}` does not provide `{1}` required by `{2}` | Error | live | src/Bayan.Semantics/Conformance.cs; 3 golden file(s) |
| BYN2802 | InterfaceMemberMismatch | `{0}.{1}` is `{2}` but `{3}` requires `{4}` | Error | live | src/Bayan.Semantics/Conformance.cs; 7 golden file(s) |
| BYN2803 | MissingAssociatedType | `{0}` does not bind `type {1}` of `{2}` | Error | live | src/Bayan.Semantics/Conformance.cs; 1 golden file(s) |
| BYN2804 | NotAnInterface | `{0}` is not an interface | Error | live | src/Bayan.Semantics/Compilation.cs; 4 golden file(s) |
| BYN2805 | DuplicateConformance | `{0}` lists `{1}` twice | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2806 | ConstraintMember | `{0}` has no member `{1}` in its constraints ({2}) | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2807 | ConstraintNotSatisfied | `{0}` does not conform to `{1}`: missing `{2}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2808 | NotDynSafe | `{0}` cannot be used with `dyn`: `{1}` {2} | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2809 | DynByValue | `dyn {0}` is not supported yet | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2810 | StaticAbstract | `static` interface members are not supported yet | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2811 | ExtensionConformance | `extension {0} : {1}` is not supported yet | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2812 | WhereUnknownParameter | `where` names `{0}`, which is not a type parameter | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2813 | DynReadonlyMutation | `{0}` takes `ref this`, but the receiver is `dyn ref readonly {1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2814 | RefThisMismatch | `{0}.{1}` must match `{2}.{1}`, which {3} `ref this` | Error | live | src/Bayan.Semantics/Conformance.cs; 1 golden file(s) |
| BYN2815 | NonStructConformance | `{0}` is {1}; only structs can conform yet | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN2816 | InterfaceAsType | `{0}` is an interface, not a type | Error | live | src/Bayan.Semantics/TypeResolver.cs; 1 golden file(s) |
| BYN2820 | LambdaArity | this lambda takes {0} parameter(s) but `{1}` takes {2} | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2821 | CannotCapture | `{0}` cannot be captured: {1} | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2822 | FunctionTypeNotHere | a function type is not supported as {0} yet | Error | live | selfhost/semantics/declare2.byn; 3 golden file(s) |
| BYN2823 | MemberNotLambda | `.{0}` is a member, not a lambda | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2824 | NotAFunctionValue | `{0}` cannot be used as a value: {1} | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN2830 | HashMapNotSupported | `HashMap` is not supported yet: `Map` hashes the same way and keeps insertion order | Error | live | src/Bayan.Semantics/TypeResolver.cs; 4 golden file(s) |
| BYN2831 | KeyPartNotHashable | `{0}` cannot be a `Map` key: {1} `{2}` is a `{3}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN2832 | StringNotSymbol | a `string` value is not a `Symbol`; only a string literal converts | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN3001 | BorrowField | a struct field cannot hold a borrowed `{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 2 golden file(s) |
| BYN3002 | BorrowOutlivesSource | {0} does not live as long as `{1}`, which borrows it | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 46 golden file(s) |
| BYN3003 | BorrowReturned | cannot return a borrow of {0}, which is freed when `{1}` returns | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 4 golden file(s) |
| BYN3004 | ModifiedWhileBorrowed | `{0}` is modified while {1} still borrows it | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 31 golden file(s) |
| BYN3005 | RefAndValue | `{0}` is passed by `ref` and again in the same call | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 2 golden file(s) |
| BYN3006 | MovedWhileBorrowed | `{0}` is moved while {1} still borrows it | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 3 golden file(s) |
| BYN3100 | ManifestNotData | `package.byn` is data only: expected {0} | Error | live | src/Bayan.Syntax/Packages/Manifest.cs; 3 golden file(s) |
| BYN3101 | ManifestUnknownField | `{0}` is not a field of `{1}` | Error | live | src/Bayan.Syntax/Packages/Manifest.cs; 4 golden file(s) |
| BYN3102 | ManifestInvalidValue | `{0}` must be {1} | Error | live | src/Bayan.Syntax/Packages/Manifest.cs; 7 golden file(s) |
| BYN3103 | ManifestMissingField | `package.byn` has no `{0}` | Error | live | src/Bayan.Syntax/Packages/Manifest.cs; 1 golden file(s) |
| BYN3104 | ManifestEquals | `package.byn` uses `field: value` | Error | live | src/Bayan.Syntax/Packages/Manifest.cs; 2 golden file(s) |
| BYN3201 | UnusedValue | the value of this `{0}` is unused | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 2 golden file(s) |
| BYN3202 | DuplicateErrorCase | `{0}` and `{1}` both have a case `{2}` | Error | live | src/Bayan.Semantics/Compilation.cs; 3 golden file(s) |
| BYN3204 | BareLiteralForDistinct | `{0}` is not a `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderExpressions.cs; 1 golden file(s) |
| BYN3206 | RuleTargetNotField | `at .{0}` names no field of `{1}` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN3207 | LiteralNeedsTry | a literal of `{0}` can fail its `requires`; write `try {0} {{ … }}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN3208 | CheckedFieldAssignment | fields of `{0}` cannot be assigned one at a time; its `requires` are checked at construction | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN3209 | UniqueConst | a `unique` type cannot be `const` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN3213 | OverlappingOverloads | `{0}` and `{1}` both accept `{2}` | Error | reserved | v0.1 overloads differ by particle set only |
| BYN3214 | RestEscapes | `{0}` is borrowed for the call and cannot be stored | Error | live | src/Bayan.Semantics/Binding/RegionAnalysis.cs; 1 golden file(s) |
| BYN3215 | AmbiguousOverloadReference | `{0}` is overloaded; give the reference a function type | Error | reserved | v0.1 has no references to overloaded names |
| BYN3216 | FieldWriteOutside | `{0}.{1}` can be written only by `{0}`'s own methods or with `with`: `{0}` {2} | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 3 golden file(s) |
| BYN3217 | BorrowCrossesFiber | `{0}` holds a reference into `{1}` and cannot be passed to a fiber that may outlive it | Error | reserved | v0.1 has no fibers |
| BYN3218 | RequiresMixesFields | this `requires` reads `it` and other fields | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN3219 | UnknownMutationOperator | `{0}` is not a mutation operator | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN4001 | CCompilerRejected | internal compiler error: the C compiler rejected the generated C; this is a bug in the Bayan compiler | Error | live | src/Bayan.Cli/CliApp.cs; 3 golden file(s) |
| BYN4002 | ErrorNodeReachedLowering | internal compiler error: a bound error expression reached lowering with no error reported; this is a bug in the Bayan compiler | Error | live | src/Bayan.Cli/CliApp.cs; 3 golden file(s) |
| BYN5001 | ParticipleChangesThis | `{0}` changes `this`; name it `{1}` | Error | live | src/Bayan.Semantics/Naming.cs; 2 golden file(s) |
| BYN5002 | StateMemberMutates | `{0}` reads as state but modifies `this` | Error | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s) |
| BYN5003 | TryWrongReturn | `try{0}` must return `{1}?` or `bool`; it is derived from `{2}() fails` | Error | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s) |
| BYN5004 | ParticleRequired | `{0}` has {1} unlabeled parameters; give each but one a particle | Error | live | src/Bayan.Semantics/Particles.cs; 8 golden file(s) |
| BYN5005 | ArgumentNeedsParticle | `{0}` is passed without its particle `{1}:` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN5006 | ParameterNeedsParticle | `{0}` is a required parameter besides the object and needs a particle | Error | live | src/Bayan.Semantics/Particles.cs; 7 golden file(s) |
| BYN5007 | LogLevelAsVerb | `Log.{0}` names a level, not the act; write `log(…, as: .{0})` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN5008 | UnknownParticle | `{0}` is not a particle | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN5009 | ParticleAsMemberName | `{0}` is a particle; name the member with a verb or a noun | Error | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s); second message form for an instance `toX`/`asX` member |
| BYN5011 | ExpectsSingleParameter | this `expects` reads only `{0}`; a type with `requires` checks it once | Warning | live | src/Bayan.Semantics/Binding/Binder.cs; 3 golden file(s) |
| BYN5013 | RepeatedParticle | `{0}` uses the particle `{1}` twice | Error | live | src/Bayan.Semantics/Particles.cs; 2 golden file(s) |
| BYN5014 | UnknownWord | `{0}` is not a known verb or noun | Warning | live | src/Bayan.Semantics/Naming.cs; 2 golden file(s) |
| BYN5101 | NounOnMutator | `{0}` is a noun on a `ref this` member; name the action | Warning | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s) |
| BYN5102 | BoolWithoutPrefix | `{0}` is a `bool` state; prefix with `is`, `has` or `can` | Warning | live | src/Bayan.Semantics/Naming.cs; 1 golden file(s) |
| BYN5103 | LineJoinIndent | a line starting with `{0}` joins the statement above; indent it deeper | Warning | live | src/Bayan.Syntax/Parsing/Parser.cs; 7 golden file(s) |
| BYN6001 | NoallocRemoved | `{0}` is removed; a function without `uses` is already pure | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN6002 | EffectNotDeclared | `{0}` uses `{1}` but does not declare it | Error | live | src/Bayan.Semantics/Binding/EffectAnalysis.cs; 31 golden file(s) |
| BYN6003 | UnknownEffect | `{0}` is not an effect | Error | live | src/Bayan.Semantics/Binding/EffectAnalysis.cs; 2 golden file(s) |
| BYN6004 | CapabilityExceeded | `{0}` uses `{1}`, which package `{2}` does not declare in `capabilities` | Error | live | src/Bayan.Semantics/Binding/EffectAnalysis.cs; 1 golden file(s) |
| BYN6005 | EffectBoundExceeded | `{0}` uses `{1}`, beyond the bound `{2}` declared by `{3}` | Error | live | src/Bayan.Semantics/Binding/EffectAnalysis.cs; 4 golden file(s) |
| BYN6006 | ContextBlockInput | `context (…) {{ }}` is now `provide … {{ }}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 1 golden file(s) |
| BYN6007 | UnknownHandler | `{0}` is not a handler; `provide` takes `alloc`, `net`, `fs`, `clock`, `random`, `env`, `process`, `console` or `log` | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |
| BYN7001 | WrongState | `{0}` needs `{1}` to be `.{2}`, but it is `{3}` | Error | live | src/Bayan.Semantics/Binding/BinderStates.cs; 2 golden file(s) |
| BYN7002 | PayloadNotInState | `{0}` is a payload of `.{1}`; `{2}` is not known to be `.{1}` | Error | live | src/Bayan.Semantics/Binding/BinderStates.cs; 3 golden file(s) |
| BYN7003 | BecomeUndeclared | `become` needs `becomes .{0}` on `{1}` | Error | live | src/Bayan.Semantics/Binding/BinderStates.cs; 3 golden file(s); three message forms (rev 0010 adds `becomes` call on `this`) |
| BYN7004 | StateSwitchNotExhaustive | the switch does not handle state `.{0}` | Error | live | src/Bayan.Semantics/Binding/BinderStates.cs; 1 golden file(s) |
| BYN7005 | StateLiteralNeedsState | `{0}` has states; a literal must name one: `{0}.{1} {{ … }}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 2 golden file(s) |
| BYN7006 | SingleStateInline | `{0} is .{1}` is an input form; write `{2}` | Error | live | src/Bayan.Syntax/Parsing/Parser.cs; 2 golden file(s) |
| BYN7007 | UnknownState | `{0}` has no state `.{1}` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN7008 | StateShadowsStatic | state `.{0}` has the same name as static member `{1}.{0}` | Error | live | src/Bayan.Semantics/Compilation.cs; 1 golden file(s) |
| BYN7009 | MissingBecome | `{0}` declares `becomes .{1}` but returns here without `become` | Error | live | src/Bayan.Semantics/Binding/FlowAnalysis.cs; 2 golden file(s) |
| BYN7010 | BecomesNeedsRef | `{0}` declares `becomes .{1}` but takes `{2}`; a transition needs `ref this` | Error | live | src/Bayan.Semantics/Compilation.cs; 3 golden file(s) |
| BYN7011 | BecomesOnRefParameter | `{0}` changes the state of `{1}`, a `ref` parameter; a state changes in place only through `ref this` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 1 golden file(s) |
| BYN7012 | AssignmentChangesState | `{0}` would change state here; a state changes only through `become` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN8001 | MissingBecause | `{0}` bypasses a safety rule and needs `because \"…\"` | Error | live | src/Bayan.Semantics/Binding/BinderCalls.cs; 5 golden file(s) |
| BYN8006 | ExpectsReadsUntrusted | `expects` reads `{0}`, which is `Untrusted`; a violation would trap on outside data | Error | live | src/Bayan.Semantics/Binding/Binder.cs; 1 golden file(s) |

## Allocated but not in `DiagnosticCodes.cs`

### Plan

| Code | Name | Message | Severity | Source |
|---|---|---|---|---|
| BYN2233 | UnlikelyOnErrorReturn | `unlikely` on an error return is redundant | Warning | plan 2026-10-21-001-design-round-2.md; cited docs/bayan-spec.md |
| BYN3203 | BareLiteralForUnit | `{0}` has no unit; `{1}` needs a unit literal | Error | plan 2026-10-22-002-design-round-3.md; docs/bayan-spec.md:270; rev 0005 |
| BYN3205 | CoarserUnitImplicit | `{0}` to `{1}` loses precision | Error | plan round-3; docs/bayan-spec.md |
| BYN3210 | IndexTypeMismatch | `{0}` indexes `{1}`, which uses `{2}` | Error | plan round-3 §9; docs/bayan-spec.md:301; docs/bayan-style.md:56; rev 0005 |
| BYN3211 | RowNotFlat | `Row` needs flat fields; `{0}` is a `{1}` | Error | plan round-3; docs/bayan-spec.md:791 |
| BYN3212 | ExceptOnNonSequence | `except` needs a sequence, set or error set; `{0}` is neither | Error | plan round-3; docs/bayan-design-round-4-draft.md:68 |
| BYN5010 | EventOnPrefix | (message not quoted; stored function field or event named with `on`) | Error | docs/bayan-design-round-3-addendum-1.md:70; docs/bayan-spec.md:368 |
| BYN8002 | SecretInDerivation | `{0}` derives `{1}`, which would read the secret field `{2}` | Error | plan round-3; docs/bayan-spec.md:790; rev 0005 |
| BYN8003 | SinkNeedsType | `{0}` takes `{1}`, not `string` | Error | plan round-3; docs/bayan-spec.md:1678 |
| BYN8005 | SqlArgumentCount | `sql"…"` has {0} placeholders but {1} arguments follow it | Error | plan round-3 J40; docs/suq-round3-review-response.md:92 (reserved) |

Revision 0005 counts 12 SPEC allocations that no v0.1 compiler step raises; this table lists the 10 that could be found by grep. The other 2 are unverified.

### Reserved

| Code | Name | Note | Target |
|---|---|---|---|
| BYN1070 | NegatedIsInput | `!(x is .s)` | 19xx input form |
| BYN1071 | SwitchExpressionNeedsElse | subjectless `switch` | 41xx switch |
| BYN2825 | BorrowedClosureStored | closure escape rule | 3xxx borrows |
| BYN7013 | FinalStateNotReached | `final` states | 7xxx typestate |
| BYN8004 | - | `Untrusted<T>` reaching a layer-2 sink (spec §15.1); plan: "reserved" | none given |

BYN1070, BYN1071, BYN2825 and BYN7013 sit in the `// Reserved: round 4` block at the end of `DiagnosticCodes.cs`; `DiagnosticCodesTests.NoLiveCodeReusesAReservedNumber` fails if a live code takes one. The round-4 renumbering (A2) will move them, and keeps old codes as aliases for one edition.

## Cited but never allocated

Grep of `BYN[0-9]{4}` over `docs/`, `src/`, `selfhost/`, `tests/`, minus every code above. The first five are placeholders or test fixtures, not codes.

| Code | Cited in | What the citation means |
|---|---|---|
| BYN0000 | tests/Bayan.Tests/DiagJsonTests.cs (2) | test fixture |
| BYN1000 | docs/specs/009-self-hosted-parser/009-plan.md; tests/Bayan.Tests/DiagnosticRendererTests.cs | range start / fixture |
| BYN2000 | docs/bayan-handoff.md (2); docs/specs/010-self-hosted-semantics/010-spec.md; selfhost/semantics/codes.byn; DiagnosticRendererTests.cs (9); SelfhostSemanticsT2Tests.cs (2) | range start / fixture |
| BYN2200 | docs/bayan-handoff.md (2); docs/specs/010-self-hosted-semantics/reviews/2026-10-28-first-review-T12-T13.md | range start |
| BYN8999 / BYN9999 | docs/bayan-handoff.md; selfhost/semantics/codes.byn; SelfhostSemanticsT2Tests.cs; CliTests.cs; SelfhostDefaultT1Tests.cs | fixture codes for unknown-code handling |
| BYN1024 | docs/plans/2026-10-21-001-design-round-2.md | "`IfNeverBody`? not needed"; never allocated |
| BYN1026 | docs/plans/2026-10-21-001-design-round-2.md | `WhileLetNotOptional`, moved to semantics as BYN2234 |
| BYN2030 | docs/plans/2026-10-21-001-design-round-2.md | `DelegateKeyword`, "reserve now"; the teaching error shipped as BYN1028 |
| BYN2232 | docs/bayan-spec.md; docs/plans/2026-10-21-001-design-round-2.md (2) | `ForWithoutTry`: plan says "not added"; spec cites it as a code of round 2 §4 (for loops) |
| BYN2817 | docs/specs/007-lambdas/007-plan.md | "unused" (BYN2817-2819 were skipped) |
| BYN3405 | docs/bayan-handoff-addendum-002.md:154; docs/bayan-design-round-4-inventory.md:68 | parallel-closure example; inventory says it "needs a renumbered code" |
| BYN5012 | docs/bayan-design-round-3-addendum-1.md; docs/bayan-design-round-3.md; docs/plans/2026-10-22-002-design-round-3.md | `@allow(BYN5012)` example; plan says "skipped" |
| BYN5100 | docs/bayan-design-round-4-draft.md:269; docs/bayan-design-round-4-inventory.md (2) | "Naming rules BYN5100/5101", a v0.2 proposal; no name or message. BYN5101 is the existing `NounOnMutator` lint |

The 10 plan codes above are also cited without a descriptor; they are allocated, so they are not listed here.
