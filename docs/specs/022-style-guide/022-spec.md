# 022 — Style guide: layout in `bayan format`, idiom lints, do/don't examples
Status: approved (unattended run, user 2026-11-15: "Spec + plan + build")
Release: 0.3.2
Sources: `docs/bayan-style-proposal.md` (decided 2026-11-04, C21 `{` ends the line); `docs/bayan-style.md`; revision 0017 (A2 code rules); user 2026-11-15 (a do and a don't example per rule; `bayan format` implements the layout rules; lints for the idiom rules; a `.git-blame-ignore-revs` entry; C21 stands)
Created: 2026-11-15

## Problem
Users and agents writing Bayān have no layout tool. `bayan format` only applies input-form fixes, the boolean and primitive spellings and the BYN5103 indent fix (spec §19.2, "partial in 0.3"). Three consequences:
- every file's indentation, spacing, blank lines, alignment and wrapping is whatever its author typed;
- review diffs mix layout with meaning;
- the style guide states rules without showing them.

The 2026-11-04 proposal settled the rules and the knobs, but none of it is built. The manifest check still takes the old knobs (`braces`, a 100-column line knob, a bool `trailingCommas`) and rejects `width`, `align` and `lints`. The five idiom lints are listed with no code and no implementation.

## Goals
- `bayan format` produces the layout of `docs/bayan-style.md` §Layout for every `.byn` file it can parse. The C# implementation and the self-hosted one give byte-identical output.
- Each layout rule and each lint in `docs/bayan-style.md` shows one "Do" example and one "Don't" example. Each Don't example, run through `bayan format` or `bayan check`, gives the Do example or the lint. The naming guideline (proposal §3.9) is the one exception: neither tool renames, so its pair is marked as a guideline and the doc-examples test skips it.
- The idiom lints are reported with a code and a severity the project sets.
- The repo's own `.byn` sources are formatted once. That commit is listed in `.git-blame-ignore-revs`.

## Non-goals
- `bayan format --range`, `--diff`, `--editorconfig`, and reading `.editorconfig`: proposal §4.3 and §4.5, a later spec.
- LSP formatting requests.
- `@unformatted` checked by `bayan audit`. The formatter does honour it.
- Prose translation (`--prose`).
- Renumbering existing codes (round 4).
- Formatting `tests/cases/**`. Their goldens carry line and column positions.

## User stories
- As a Bayān author, I run `bayan format` once and get the project's layout, so that I never hand-align a field run or fix a wrapped header.
- As a reviewer, I run `bayan format --check` in CI, so that diffs hold only meaning.
- As a project lead, I set `width`, `align`, `trailingCommas` and lint severities in `package.byn`, so that the project decides its trade-offs in one place.
- As a newcomer, I read a rule with a Do and a Don't example beside it, so that I know what the formatter or lint will do before it does it.

## Requirements
- **R1 Style guide.** `docs/bayan-style.md` states every layout rule of the proposal §3.1–§3.9 and every lint. Each rule or lint has a `Do` code block and a `Don't` code block. The rule `{` always ends the line (C21) is kept as written.
- **R2 Knobs.** `style` in `package.byn` accepts exactly `indent` (a positive integer), `width` (a positive integer), `align` (`.runs` or `.none`), `trailingCommas` (`.multiline` or `.never`), `booleans`, `primitives`, and `lints`. `lints` is a map from a lint name to `.none`, `.suggestion`, `.warning` or `.error`.
  - The defaults are 4, 120, `.runs`, `.multiline`, `.symbols`, `.sized`, and every lint at its default severity.
  - Any other field, or an old knob (`braces`, `maxLine`, a bool `trailingCommas`), is a manifest error. For an old knob the error names the new knob.
  - The C# check and the self-hosted check accept and reject the same manifests with the same diagnostics.
- **R3 Layout.** On a file that parses, `bayan format` applies:
  - **indentation:** `indent` spaces per block level, and two levels for header-clause and wrapped-condition continuations;
  - **horizontal spacing:** proposal §3.8;
  - **blank lines:** a single blank line is kept, a run collapses to one, and none is left after `{` or before `}`;
  - **top level:** one blank line between top-level declarations, except within a run of one-line declarations of the same kind;
  - **alignment runs** under `align: .runs`: field and property name columns, the `=>` of properties and switch arms, the `=` of one-line top-level declarations, and trailing comments;
  - **list wrapping at `width`:** one item per line, a trailing comma under `.multiline`, the closer on its own line, and `) {` for parameter lists. An author's trailing comma keeps a list vertical;
  - **chain breaking:** past the width, or with three or more calls that take lambdas, every link goes on its own line with a leading `.`;
  - **header clauses:** on the `) {` line when they fit, otherwise one per line at two levels;
  - **wrapped conditions:** a break before `and`, `or`, `&&` or `||`;
  - **files:** LF line endings, a final newline, and no trailing whitespace.
  - It never moves a `{` to its own line.
- **R4 Safety.** For every input that parses:
  - the output parses with the same diagnostics, apart from the layout-only lints the formatter fixes;
  - the output has the same token sequence, apart from trailing commas and newlines;
  - the output keeps every comment's text, in the same order;
  - formatting the output again changes nothing.
  - A file that does not parse is left unchanged and reported, as today.
- **R5 Opt-out.** A declaration with `@unformatted because "…"` keeps its text byte for byte from the attribute to the end of the declaration.
- **R6 Parity.** The self-hosted `bayan format` gives the same bytes, exit code and output as the C# one for every file of the parity corpus. The expected bytes come from the C#.
- **R7 Lints.** `guards.postfix`, `lambdas.it`, `nesting.depth` (more than 4), `conditions.named` and `functions.length` (off by default) are diagnostics with codes and fixes where the proposal names one (`guards.postfix`, `lambdas.it`).
  - Each lint's severity comes from `lints`; `.none` silences it.
  - `bayan check` reports lints. `build`, `run` and `test` do not.
  - A lint at `.error` makes `bayan check` fail, as an error does.
  - The C# and self-hosted implementations agree.
- **R8 Blame.** The repo's `src/**/*.byn` (and the other `.byn` sources outside `tests/cases/`) are formatted in one commit that changes nothing else. `.git-blame-ignore-revs` at the repo root lists that commit with a comment.
- **R9 Docs.** Spec §19.2 and §21.2, `docs/STATUS.md` and the CHANGELOG describe what is built, and the "partial in 0.3" tags that this spec resolves are removed.

## Acceptance criteria
- Given each Don't example in `docs/bayan-style.md`, when it is formatted (or checked, for a lint), then the output is its Do example (or the lint's diagnostic). A test reads the examples from the doc, so the doc and the tool cannot drift.
- Given a manifest with `braces: .sameLine`, when it is checked, then the error names `{` always ends the line and says that no knob replaces it. Given `maxLine: 100`, the error names `width`.
- Given the self-hosted compiler's own sources, when they are formatted twice, then the second run reports no change, and the formatted sources still build stage 1 to stage 3 with an unchanged bootstrap fixed point.
- Given `lints: ["guards.postfix": .error]` and an `if c { return }`, when `bayan check` runs, then it exits 1 with the lint.

## Law candidates
- **Format is idempotent and meaning-preserving:** for every source that parses, `format(format(s)) == format(s)`. `format(s)` parses with the same token sequence, apart from layout tokens, and the same comments. (Today's `FormattingIsIdempotent` test is one case; this quantifies over every input.)
- **Format parity:** for every source, the C# and self-hosted formatters give the same bytes.

## Decisions taken unattended (conservative; each is also in `docs/bayan-questions.md`)
- **Lint codes** follow revision 0017's rules for codes allocated mid-flight: the next free number in the current allocation of the phase that reports it, with a `// target: x9xx lint` comment. No number is taken from the round-4 target range.
- **Where lints run:** `bayan check` only, since `.suggestion` output on every build would bury real diagnostics. `.suggestion` renders with the existing `note` severity; no new severity enters the renderer, whose format is fixed by `DiagnosticRendererTests`.
- **Engine:** a layout pass over the token stream and the source bytes, with comments recovered from the trivia between tokens. Newlines inside `( )` and `[ ]` are free, and leading `.`, `and` and `or` join (spec §5), so every break the rules need is one the grammar already allows. A full tree printer is not needed for R3, and it would be twice the port.

## Open questions
- none blocking. The two above are recorded and can be reversed without rework of the layout engine.
