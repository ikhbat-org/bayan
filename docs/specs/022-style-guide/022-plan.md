# 022 — Plan
Status: approved (unattended run, user 2026-11-15)
Release: 0.3.2
Sources: ./022-spec.md
Spec: ./022-spec.md

## Approach
The layout engine is a **token-and-line pass**, `csharp/Bayan.Cli/Layout.cs`. It runs after the existing fix and restyle passes in `Format.FormatFile` (`csharp/Bayan.Cli/Format.cs:324`), inside the same `MaxPasses` fixed-point loop.

It lexes the file (`Bayan.Syntax.Lexing.Lexer`) and builds lines of tokens. The comments are the source bytes between token spans; the lexer marks them with `TriviaBefore` and keeps no comment tokens. It then rewrites only the whitespace between tokens, plus trailing commas before a closer. Every break and join it makes is one spec §5 already allows:
- newlines inside `( )` and `[ ]` are free;
- a line that ends with `,`, `{`, `=`, `=>` or a binary operator continues;
- a line that starts with `.`, `?.`, `??`, `and`, `or`, `&&`, `||` or a clause keyword joins.

So no tree printer is needed. The alternative, a Wadler printer over the AST, would preserve comments only with trivia that the AST does not have, and it would double the self-hosted port.

**Safety net (R4).** After layout, the engine re-lexes its output. It compares the token sequence with the input's, ignoring trailing commas, and re-parses to compare the diagnostic codes. On any difference it keeps the input bytes for that file and prints `bayan format: layout skipped for <file>: <reason>` to stderr. The exit code does not change.

Tests assert that this message never appears on the corpus: `tests/cases/**`, `src/**`, `lib/**` and the doc examples. A skip is a bug to fix, not a fallback.

**Order of the passes over a file** (each pass is pure on bytes):
1. hygiene: LF, no trailing whitespace, final newline;
2. `@unformatted` spans marked as frozen;
3. joins: a list without an author's trailing comma that fits in `width` goes on one line, and so does a chain that fits, has fewer than 3 lambda calls and was broken only at leading `.` lines;
4. breaks: lists, header clauses, conditions and chains over `width`, or a list with the author's trailing comma;
5. indentation from bracket depth and continuation state;
6. horizontal spacing (proposal §3.8);
7. blank lines (proposal §3.1, §3.7);
8. alignment runs (`align: .runs`).

Struct-literal `{ … }` lists are broken when over width and never joined, so an author's vertical `Package { … }` stays as written.

**Self-hosted port.** `src/driver/layout.byn` is a line-for-line port of `Layout.cs`, under the port rules: names cite the C# line, no invented fallbacks, and expected bytes come from the C#. It is called from `src/driver/format.byn`'s `formatFile` in the same place. Parity uses the L028 harness: rows in `SelfhostDriverTests.cs` run every `FormatTests.cs` and `LayoutTests.cs` case through stage 2 and compare stdout, stderr, the exit code and the bytes after.

**Lints** (R7) live where their facts are:
- `guards.postfix`, `lambdas.it` and `conditions.named` are syntactic, in the parser's lint list beside BYN5103 (`Parser.LintLineJoins`, `Parser.cs:282`);
- `nesting.depth` and `functions.length` are in the same lint pass (block depth and line count are syntactic too).

They are reported by `bayan check` only: `Compilation.cs:173` adds `tree.Lints` today. A filter keeps style lints out of `build`/`run`/`test`, and `CliApp`'s check path re-adds them with the manifest's severity. `.none` drops a lint, `.suggestion` renders as `note`, `.warning` as a warning, and `.error` as an error that fails `bayan check`.

Codes, per revision 0017's mid-flight rule (the next free number in the current allocation):
- BYN1072 `guards.postfix`, `// target: 19xx lint`;
- BYN1073 `lambdas.it`, `// target: 19xx lint`;
- BYN1074 `conditions.named`, `// target: 49xx lint`;
- BYN1075 `nesting.depth`, `// target: 49xx lint`;
- BYN1076 `functions.length`, `// target: 09xx lint`.

The writer checks that 1072–1076 are free in `DiagnosticCodes.cs` and `docs/diagnostics-allocated.txt` and takes the next free ones if not. `functions.length` takes `lints: ["functions.length": .warning]` plus a fixed bound of 60 lines when on. A numeric knob would widen the closed set, so it goes to Questions.

## Tech / dependencies
- C# / .NET 10, NativeAOT, no reflection: AGENTS.md.
- The self-hosted side in Bayān, through the existing `src/driver` and `src/semantics` modules.
- No new packages.

## Changes by area
- **`docs/bayan-style.md`** (R1): rewritten so each rule is a `### ` heading with one line of rule text, a `Do:` fenced `bayan` block and a `Don't:` fenced `bayan` block. The C21 text is kept. A new `csharp/tests/Bayan.Tests/StyleGuideExamplesTests.cs` reads every pair: layout pairs format Don't → Do, and lint pairs check Don't → the lint code.
- **`csharp/Bayan.Syntax/Packages/Manifest.cs`** and **`src/semantics/manifest.byn`** (R2): the new knob set, its types and defaults, and errors for old knobs that name the new one. `Manifest` exposes `Indent`, `Width`, `Align`, `TrailingCommas` and `Lints`. Tests are new `diag/` manifest cases and `ManifestTests` rows, with parity through the existing semantics harness.
- **`csharp/Bayan.Cli/Layout.cs`** (new) and **`Format.cs`** (R3–R5): the engine, and the call from `FormatFile`.
- **`csharp/tests/Bayan.Tests/LayoutTests.cs`** (new): unit cases per rule, idempotence and the safety check over the corpus (R4), and `@unformatted` (R5).
- **`src/driver/layout.byn`** (new), **`src/driver/format.byn`** and **`SelfhostDriverTests.cs`** rows (R6).
- **Lints** (R7):
  - `csharp/Bayan.Syntax/Parsing/Parser.cs` (lint pass), `DiagnosticCodes.cs`, `docs/diagnostics/BYN1072.md`–`BYN1076.md`, and `tests/cases/diag/` cases, one per lint;
  - the `check` severity plumbing in `csharp/Bayan.Cli`;
  - the self-hosted ports in `src/parser` and `src/driver`, with parity rows.
- **Repo sources** (R8): `bayan format` over `src/`, `lib/` and the other non-case `.byn` files, in one commit. Then `bootstrap/bayan.c` is regenerated in the next commit, and `.git-blame-ignore-revs` names the format commit.
- **Docs** (R9):
  - spec §19.2, the `bayan format` row of §21.2, and the "partial in 0.3" tags that this resolves;
  - `docs/STATUS.md` rows, `docs/DIAGNOSTICS.md` (regenerated) and the CHANGELOG;
  - two laws drafted as `proposed` in `docs/laws/`, which the user enacts;
  - `docs/bayan-questions.md` entries for the two unattended decisions and for the `functions.length` bound.

## Data / interfaces
- `Layout.Apply(byte[] source, LayoutOptions options) -> (byte[] Output, string? SkipReason)`.
- `LayoutOptions` holds `Indent`, `Width`, `Align` and `TrailingCommas`.
- The Bayān port has the same shape: `layoutApply(bytes, options) -> LayoutResult`.

## Risks & mitigations
- **The formatter changes meaning.** The token and parse safety net (R4) runs on every file, and the corpus test asserts that no skip happens.
- **The C# and self-hosted outputs drift.** Parity rows on every layout case and on the formatted `src/` tree; L028 already enforces the driver's equality with the C#.
- **R8 reformat changes the bootstrap.** Regenerate `bootstrap/bayan.c` with `BAYAN_UPDATE=1` BootstrapTests in the next commit. The stage-3 fixed point is checked by `SelfhostDriverTests`.
- **Goldens with source positions.** `tests/cases/**` is excluded from R8.
- **A huge diff hides a bug.** The layout and lint tasks land one at a time, each with `/code-review` and the corpus test. R8 is its own commit.

## Coverage check
| Requirement | Plan section |
|---|---|
| R1 | `docs/bayan-style.md`, `StyleGuideExamplesTests` |
| R2 | `Manifest.cs`, `manifest.byn` |
| R3 | `Layout.cs`, passes 1 and 3–8 |
| R4 | the safety net, `LayoutTests` corpus |
| R5 | pass 2 |
| R6 | `layout.byn`, the parity rows |
| R7 | Lints |
| R8 | Repo sources |
| R9 | Docs |

All covered.
