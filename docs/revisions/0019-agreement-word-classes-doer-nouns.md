# 0019 — Agreement, word classes and doer nouns

Status: accepted (user, 2026-11-09, handed off from ~/Downloads "Revision 001")

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