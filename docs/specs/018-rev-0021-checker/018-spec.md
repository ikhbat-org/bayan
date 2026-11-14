# 018 — Revision 0021 checker changes (Parts 5, 3, 4)
Status: in progress (all tasks done 2026-11-10; waits for the 0.3.0 tag)
Created: 2026-11-10

Source: `docs/revisions/0021-agreement-word-classes-doer-nouns.md` Parts 3–5 and its ground rules. That file is the contract;
this spec restates it as testable requirements and records what the code already has.

## Problem
Revision 0021 adds a help line to BYN7001, word classes to the grammar dictionary and four public-API naming lints. Both
compilers (C# in `src/`, self-hosted in `selfhost/`) must change together, byte-identical, or L028 (driver equivalence) breaks.

## Goals
- Each of Parts 5, 3, 4 reaches `dev` as one merge holding the C# change and its `.byn` port, in the order 5, 3, 4.
- Messages, help lines and fix-its are byte-identical in both compilers.
- Every existing golden passes unchanged, except the BYN5014 goldens Part 3 rewrites.

## Non-goals
- The revision's "Out of scope" list: `fixedWords`, restricted values, word pairs, definite/indefinite rules, the
  no-member-repeating-a-state rule, inlay hints, `then`, round-4 proposals, any renumbering.
- New sharing infrastructure for the lexicon (none exists: `Lexicon.cs` and `naming.byn` `buildLexicon` are two copies).
- Any code outside BYN5104–5107, no change to narrowing.

## Code as found (dev 2fe3a14a)
- `grammar.adjectives` already exists in both manifests (`Manifest.cs:38` `GrammarFields`, `naming.byn` `grammar.adjectives`)
  and BYN5014's selfhost help already names three classes; the C# message is "`{0}` is not a known verb or noun".
- The lexicon parity test (`SelfhostSemanticsT7Tests.cs:171`) compares counts and samples, not the whole lists.

## Requirements
- R1 (Part 5) BYN7001 gains the help "`{p}` doesn't narrow; write `if {x} is .{s}`" when it fires inside `if x.p { … }`, the
  body of member `p` is exactly `this is .s`, and `.s` is a state the call needs. Otherwise the help is unchanged. A code
  comment says the help may read a member's body but narrowing never does. One new golden.
- R2 (Part 3) `Grammar` gains `collectives`. A word in more than one of `verbs`, `nouns`, `adjectives`, `collectives` is a
  manifest error unless the overlap is exactly verb plus noun; reported through the existing manifest-validation path, no new
  code (if none fits, reported as a Question, not allocated).
- R3 (Part 3) A `forms` entry is read by the word's class (`-ed` for a verb, plural for a noun).
- R4 (Part 3) BYN5014 reads "`{0}` is not a known verb, noun or adjective."; its fix offers the three classes with the
  checker's best guess first; its goldens are rewritten from the C# output.
- R5 (Part 3) The built-in lexicon gains the revision's adjectives, collectives and irregular plurals (Part 3 item 4), plus
  every adjective already used by states or events in `lib/std`.
- R6 (Part 4) BYN5104 `NumberAgreement`, BYN5105 `CountName`, BYN5106 `DoerWithoutVerb`, BYN5107 `InstrumentChangesThis`,
  warnings on the public API only, with the revision's rules, messages and fix-its; rename attributes exempt a name.
- R7 (Part 4) Each of BYN5104–5107 has goldens for the positive case, the clean case and the exemptions (collectives,
  function-type aliases, rename attributes, private names, unrelated "-er" words), a DIAGNOSTICS entry and an explain page.
- R8 (all) The self-hosted checker produces the same diagnostics as the C# for every golden of R1, R4, R6–R7; a test asserts
  the two lexicon copies hold identical word sets (every list, not samples).

## Acceptance criteria
- Given `if order.isPaid { order.ship(by: carrier) }` with `bool isPaid => this is .paid`, when checked, then BYN7001 carries
  the help "`isPaid` doesn't narrow; write `if order is .paid`" from both compilers.
- Given `grammar: Grammar { adjectives: ["x"], nouns: ["x"] }`, when the manifest loads, then it is rejected by both compilers.
- After each part's merge, `dotnet test` and `laws-check.js --run` hold on `dev`.

## Law candidates
- None new. L028 (driver equivalence) already quantifies over every golden.

## Open questions
- None blocking. Mismatches between the revision and the code go to `docs/bayan-questions.md` Questions (Q1168–Q1175).
