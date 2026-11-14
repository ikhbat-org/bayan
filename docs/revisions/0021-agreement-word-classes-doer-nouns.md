# 0021 — Agreement, word classes and doer nouns

Status: accepted (user, 2026-11-09, handed off from ~/Downloads "Revision 001")

Parts 3–5 change both compilers; parity is required in every merge (user, 2026-11-09). Each of Parts 3, 4 and 5 lands as one merge holding the C# change and the matching `selfhost/` `.byn` port. C# is the reference: expected outputs come from C#, and the port goes through `scripts/selfhost/land.sh`. Messages, help lines and fix-its are byte-identical in both compilers. The lexicon data (adjectives, collectives, irregular plurals, doer-to-verb map) is shared through one data file or generated source if the compilers can already do that; otherwise two copies plus a test that they match, with no new sharing infrastructure. Order: Part 5, then Part 3, then Part 4.

## Message to the agent

Read this whole revision first. Do not interrupt or reorder in-flight work.

- **Parts 1 and 2 change documentation only.** Land them mid-flight as one standalone commit, if no in-flight step is editing the same doc sections. Otherwise wait.
- **Parts 3, 4 and 5 change the checker.** Land them after the step that currently owns `Naming.cs`, the lexicon or `Manifest.cs` finishes. If none does, they may land mid-flight on their own branch, provided every existing golden passes unchanged.
- Use the next free number in `docs/revisions/`.
- Allocate no codes other than BYN5104–5107, and renumber nothing (that waits for round 4).
- Where the code differs from what this revision assumes, report the difference instead of guessing.

## Ground rules

- **Every new rule is a lint.** That means a warning: it never blocks a build, and it applies to the public API only, like the other BYN51xx lints. Rename attributes exempt names forced from outside.
- **Messages are plain English.** Quote code in backticks. Arabic appears only as source notes in GRAMMAR.
- **Code examples in the docs** follow the current spec: type-first declarations, no `;`, particles.

## Part 1. Spec errata (docs only)

1. **SPEC §10** says "Modifiers precede the parameter name: `ref buf: StrBuf`, `move file: File`." That is name-first, but parameters are type-first. Change the examples to `ref StrBuf buffer` and `move File file`.
2. **SPEC §16.4**: `Display.formatInto(ref StrBuf out, as FormatSpec spec)` uses the keyword `out` as a parameter name. Rename it to `buffer` in SPEC and GRAMMAR. If `BuiltinMembers.cs` or the stdlib sources use the name `out`, rename it there too, as a separate small code commit.
3. **SPEC §9.4**: the `Lexer` example has a field `toks` (an abbreviation) and a method `tokens()` (a noun with no arguments, which should be a property). Change them to the field `List<Token> tokenList` and the property `ReadOnlySpan<Token> tokens => tokenList.span`.

## Part 2. GRAMMAR additions (docs only)

1. **Number agreement (muṭābaqa).** Add a section describing Parts 3 and 4 below, plus this guidance for local loop variables (no checker; loop variables are local):
   ```
   for line in lines { … }        // one element: singular
   for batch in batches { … }     // each element is itself a list: name it for the element
   ```
2. **Role marks.** One section explaining what each call-site mark means:

   | Mark                               | Meaning                                                      |
   | ---------------------------------- | ------------------------------------------------------------ |
   | none                               | read only                                                    |
   | `ref`                              | the callee may change it                                     |
   | `out`                              | the callee must write it; mainly for C, and returning `T?` or a tuple is preferred |
   | `move`                             | handed over; the caller can't use it afterwards              |
   | particle (`from:`, `to:`, `by:` …) | names the argument's role; no effect on memory               |

   - Add Arabic source notes: rafʿ for no mark, naṣb for `ref`/`out`, jarr for particles. `move` is Bayān's own and gets no Arabic note.
   - Add a "See GRAMMAR: Role marks" line to the explain pages for BYN5004, 5005, 5006, 5008 and 5013, and for the codes that report a missing `ref`, `out` or `move` at a call site. Grep for those codes and list them in your report.
3. **Exempt words.** One list collecting existing exemptions; no rule changes:
   - states: exempt from the `-ed` rule
   - math vocabulary
   - particles: reserved by BYN5009
   - names under rename attributes

   Add one line: codecs and algorithms are types, as in `Sha256.hash(d)` and `Base64.encode(d)`.
4. **State properties.** Add this style note: "An `isX` property such as `bool isPaid => this is .paid` is allowed and useful (interfaces, generic code, output), but it doesn't narrow. Use `order is .paid` when the block needs the state."
5. **GRAMMAR §6 source rows.** Add rows for muṭābaqa (agreement) and role marks (ʾiʿrāb), with Arabic notes only.

## Part 3. Dictionary keys (`package.byn`)

1. **New keys.** `Grammar` gains two lists:
   - `adjectives`: from rev 0002 item 26, missing from SPEC §19.2 (AUDIT A30).
   - `collectives`: new.
   ```
   grammar: Grammar {
       verbs: ["upsert", "reindex"],
       nouns: ["sku", "kyc", "criterion"],
       adjectives: ["overdue", "refundable"],
       collectives: ["ledger"],
       forms: ["upsert": "upserted", "criterion": "criteria"],
   }
   ```
2. **What `forms` means.** A `forms` entry is read by the word's class: the `-ed` spelling for a verb, the plural for a noun.
   - Document the limit: a word in both `verbs` and `nouns` with irregular forms both ways can't be declared.
   - A word listed in more than one of `verbs`, `nouns`, `adjectives` and `collectives` is allowed only for verb plus noun (`record`). Any other overlap is a manifest error. Use the existing manifest-validation code if one fits; otherwise list the problem in your report and don't allocate a code.
3. **BYN5014.**
   - New message: "`{0}` is not a known verb, noun or adjective."
   - The fix offers all three classes, with the checker's best guess first.
   - Update its golden files.
4. **The built-in lexicon** gains:
   - **Adjectives:** at least `empty`, `low`, `high`, `full`, `stale`, `valid`, `overdue`, and every adjective already used by states or events in the stdlib.
   - **Collectives:** `span`, `list`, `map`, `set`, `array`, `buffer`, `queue`, `stack`, `batch`, `history`, `inventory`, `catalog`, `data`, `metadata`.
   - **Irregular plurals:** at least `people`, `children`, `criteria`, `indices`, `matrices`, `data`.

## Part 4. New lints

### BYN5104 `NumberAgreement` (warning, public API)

**Rule.** A public field, property or parameter whose type is a collection is named with a plural or a collective. A non-collection is named with a singular.

- **Collection types:** `List`, `Set`, `Map`, `T[]`, `var T[]`, `Span<T>`, `ReadOnlySpan<T>` and sequences.
- **Status wrappers are looked through**, so `Untrusted<List<T>>` counts as a collection.
- **Never collections:** `string`, `StrBuf`, `Range`.
- **The last word of the name decides:** `firstLine`, `lineItems`.

**Messages:**
- "`{0}` holds a collection; name it with a plural, `{1}`"
- "`{0}` holds one `{1}`; name it with a singular noun"

The fix renames, when a plural or singular is known.

```
// before
public struct Order {
    public List<Line> line
    public Line lines
    public Map<Sku, Grams> weight
}

// after
public struct Order {
    public List<Line> lines
    public Line firstLine
    public Map<Sku, Grams> weights
    public List<u8> buffer        // collective: no warning
}
```

### BYN5105 `CountName` (warning, public API)

**Rule.** A public integer field or property that counts items is named singular noun + `Count`. A count named `<plural>Count`, `num<Plural>` or `numberOf<Plural>` gets the warning. `length` stays the size name.

**Message:** "`{0}` counts items; name it `{1}`". The fix renames.

```
public i64 linesCount    // before
public i64 numLines      // before
public i64 lineCount     // after
```

### BYN5106 `DoerWithoutVerb` (warning, public API)

**Which types.** A public struct or interface whose name ends in a doer or tool noun. "Ends in" means the last word of the name (`CsvParser` → `parser`). A noun counts if it is:
- **Built in:** `parser`, `builder`, `reader`, `writer`, `recorder`, `encoder`, `decoder`, `scanner`, `loader`, `scheduler`, `renderer`, `formatter`, `handler`, `hasher`, `comparer`. Each maps to its verb in the lexicon.
- **`codec`**, which maps to `encode` and `decode`.
- **Derived from a project verb**, by regular spelling only (`upsert` → `upserter`, `scan` → `scanner`). Irregular agent nouns are not checked.

**Not covered:**
- function-type aliases (`type Pricer = Line -> Money uses net`)
- stored function fields
- every other word ending in "-er" (`Carrier`, `Ledger`, `Pointer`, `User`)

**Rule.** The type exposes a public member named its verb, or a derived form of it (`tryX`, `xInto`, `xOp`). A static or instance member both count. For `codec`, either verb counts.

**Message:** "`{0}` is named for the act `{1}` but has no `{1}` member"

```
// before
public struct CsvParser {
    public Table read(ref this)
}

// after
public struct CsvParser {
    public Table parse(ref this)
}
```

### BYN5107 `InstrumentChangesThis` (warning, public API)

**Rule.** A type named for a tool (`hasher`, `comparer`, `codec`) has no `ref this` member. Fixed settings in fields are fine. A type fed data step by step is a doer and should be named like one.

**Message:** "`{0}` is a tool; `{1}` must not change `this`"

```
// before
public struct OrderHasher {
    public u64 hash(ref this, Order order)
}

// after
public struct OrderHasher {
    public u64 hash(Order order)
}
```

### Tests

Each of BYN5104–5107 needs golden files covering:
- the positive case and the clean case;
- the exemptions: collectives, function-type aliases, rename attributes, private names, and unrelated "-er" words.

Every code also needs a DIAGNOSTICS entry and an explain page.

## Part 5. BYN7001 help text

Add one help line, with no new code and no change to narrowing. It applies when:
- BYN7001 fires inside `if x.p { … }`;
- the body of member `p` is exactly `this is .s`;
- `.s` is the state the call needs.

Help: "`{p}` doesn't narrow; write `if {x} is .{s}`"

Narrowing still comes only from a visible `is`. Add a code comment saying the help text may read a member's body but narrowing must never do so.

```
if order.isPaid {
    order.ship(by: carrier)
}
// error BYN7001: `ship` needs `order` to be `.paid`, but it is `Order`
//   help: `isPaid` doesn't narrow; write `if order is .paid`
```

Add one golden file.

## Out of scope

Do not implement any of these:
- the `fixedWords` key, restricted values, word pairs, definite/indefinite rules, and the "no member repeating a state" rule (all dropped)
- inlay hints (parked until the language server exists)
- `then` and the other round-4 proposals
- any renumbering

## Report back

1. Commits per part.
2. Which parts landed mid-flight and which waited, with the reason.
3. The call-site `ref`/`out`/`move` codes you found.
4. Any lexicon words you added beyond the lists above.
5. Any mismatch between this revision and the code.

### Answers

Written 2026-11-10 from `git log` on dev, `docs/bayan-progress-log.md` (Progress log and Questions), `docs/specs/018-rev-0021-checker/018-plan.md` and `018-tasks.md`, `src/Bayan.Semantics/Lexicon.cs` and `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs`. The Question states in item 5 are as of that date; `docs/bayan-questions.md` holds the current state.

#### 1. Commits per part

Spec 018 covers Parts 3, 4 and 5. Parts 1 and 2 are docs only and came before it.

| Part | Merge into dev | Main feature commits |
| ---- | -------------- | -------------------- |
| 1, 2 (docs) | 2fe3a14a Merge branch 'docs/rev-0019-agreement' into dev | 269cd130 chore(worker): rev-0019-docs: work in progress (stopped for revision renumber); 8ccfa8a3 chore(worker): rev-0019-docs: Parts 1 and 2 of revision 0021 are finished, docs only, and…; 0a796f26 chore(worker): land rev-0019-docs |
| 5 (T1, T2) | 36921d29 Merge branch 'feat/018-rev-0021-checker' into dev (rev 0021 Part 5: T1, T2) | f27d6c35 chore(worker): land 018-t1; 683fa119 chore(018): land T2 |
| 3 (T3, T4) | 71021224 Merge branch 'feat/018-rev-0021-checker' into dev (rev 0021 Part 3: word classes) | 25be193e chore(worker): land 018-t3; 53e2bd09 chore(018): land T4 |
| 4 (T5-T10) | 10bb0a0d Merge branch 'feat/018-rev-0021-checker' into dev | 5c0b3b92 chore(worker): land 018-t5; 2a827008 chore(worker): land 018-t6; 8e781e0a chore(018): land T8 (T7 and T8 together; T7 has no land commit of its own); 17547bb5 docs(018): regenerate DIAGNOSTICS.md for BYN5104-5107 (T9); b76792a7 chore(018): land T10 |

Parts 1 and 2 were first merged with the revision numbered 0019 and renumbered to 0021 (68e5adc1). The 018 task map is in `docs/specs/018-rev-0021-checker/018-tasks.md`: T1, T2 are Part 5; T3, T4 are Part 3; T5-T10 are Part 4 (T10 is the branch-review fix).

#### 2. Landed mid-flight and waited

The plan (`018-plan.md`, Approach) lands each part on `feat/018-rev-0021-checker` and merges it to dev `--no-ff` before the next starts, in the order 5, 3, 4. It says no step of 017 or 015 owns `Naming.cs`, `Lexicon.cs`, `Manifest.cs` or `states.byn` (checked 2026-11-10), so the parts land mid-flight as the revision allows, provided every existing golden passes unchanged.

- Parts 1 and 2 landed 2026-11-09 (Progress log, "Revision 0021 Parts 1-2 (docs only)").
- Parts 5 and 3 landed mid-flight, each merged to dev as soon as its C# and `.byn` tasks were done (36921d29, 71021224).
- Part 4 waited. Its tasks ran on the branch, and the merge to dev (10bb0a0d) came after a clean wp1 full run at eafeaf65 and the branch review, as the Progress log says ("Next: merge feat/018 into dev after a wp1 full suite and the branch review"). Inside it, T7 waited for T8: T7 alone failed T6's C# BYN5106/5107 rows, so both landed in one `land.sh 018 T8` (8e781e0a; Q1196, Q1200).
- The full suite caught two spec-010 test breaks that the per-task filters never ran (Q1206), and T10's two goldens moved L028's pinned domain to 524 (Progress log "Session close", commit eafeaf65).

#### 3. Call-site `ref`/`out`/`move` codes

Only one code reports a call-site `ref`/`out` mark that does not match the parameter:

- BYN2306 `ArgumentModifierMismatch` (`DiagnosticCodes.cs:196`): "argument for `{0}` must be passed as {1}". The argument's `ref` or `out` mark must match the parameter's (reported at `BinderCalls.cs:505`, with a fix that inserts the keyword).

No code was found that reports a missing `move` at a call site. `BinderCalls.cs` accepts `move x` for a plain or `move` parameter and does not report an absent one; the move codes found are about use after the move, not the call-site mark: BYN2781 `UseAfterMove` (`DiagnosticCodes.cs:271`) and BYN2782 `CannotMove` (`:272`). Per Part 2, "See GRAMMAR: Role marks" is on BYN2306, 5004, 5005, 5006, 5008 and 5013 (checked in `docs/diagnostics/`).

#### 4. Lexicon words added beyond the lists

None, checked. `Lexicon.cs` `Adjectives` (line 86) contains every adjective the revision names (`empty`, `low`, `high`, `full`, `stale`, `valid`, `overdue`); only `overdue` was new (Q1170). `Collectives` (line 98) is the revision's fourteen. `IrregularPlurals` (line 105) is the revision's six. No Question in Q1160-Q1210 records an extra word. The one addition that is not in the lists is not a word class entry: `Lexicon.IrregularSingulars` (line 108), the six singulars, added by T10 (Q1208).

#### 5. Mismatches between the revision and the code

| Question | Mismatch | State |
| -------- | -------- | ----- |
| Q1186 | The revision says to exempt names under rename attributes "as BYN5101/5102 do"; they honour none (`@json`/`@column` is BYN2770). BYN5104/5105 skip such names; BYN5101/5102 are unchanged. | Open ("Decision needed": accept the attributes in `CheckAttributes` and extend the exemption to all BYN51xx). |
| Q1190 | The rule as written flags numbers named with a plural (`cents`, `digits`) and 26 struct members in `selfhost/` (41 with Q1187's positions). BYN5104's second form skips numeric types. | Open (keep the numeric exemption or report units; rename the self-hosted names or leave the warnings). Q1206 skips BYN5104 in one test meanwhile. |
| Q1191 | `lib/std/json` `JsonReader` has act `next`, so BYN5106 would fire in every program importing `std.json`. `Naming.CheckDoer` skips std modules. | Open (rename `JsonReader`, add `read`, accept `next`, or keep the skip). |
| Q1189 | "The last word decides" flagged `modulesByDir`, `byPath` and others; the word before the first particle or function word decides. | Open ("Decision needed": keep, or follow the revision literally). |
| Q1168 | The overlap error uses BYN3102, no new code. | Open ("Decision needed": keep BYN3102 or allocate a code). |
| Q1169 | BYN5014 guesses the class from the member only. | Open ("Decision needed if a finer guess is wanted"). |
| Q1172 | The BYN5014 message has no final full stop, unlike the revision's quote; `collectives` also changes the BYN3101 help list in golden `manifest/grammar-invalid.diag`. | Decided in the code (forced by the existing message style; no "Decision needed" line). |
| Q1170 | `lib/std` has no state or event adjectives, so only `overdue` was added. | Decided (recorded as done). |
| Q1194 | 3 BYN5106 hits in `selfhost/` (`LPushPanicHandler`, `LPopPanicHandler`, `Parser`); no revision exemption covers them. | Open ("Decision needed": rename them, add `parse`, or accept the warnings). |
| Q1207 | `IsPlural` accepted a verb's `-ed` form as a plural. | Decided and fixed in T10 (b76792a7). |
| Q1208 | The six irregular plurals had no singulars, so fix-its and BYN5105 were wrong for them. | Decided and fixed in T10 (b76792a7). |
| Q1196, Q1197, Q1203, Q1206 | Test-harness and coverage-exemption mismatches (code-table extras lists, `compile.byn` call line, a `manifest.byn` exemption, two spec-010 tests). | Decided; each Question records the fix. |
