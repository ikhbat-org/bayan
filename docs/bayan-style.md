# Bayān style guide

Version: 0.3.0 (matches `bayan --version`)
Revisions applied: 0001–0023

*Bayān (ASCII: Bayan). The CLI, package names, URLs and identifiers use `bayan`.*

Style is guidance, configurable per project. Layout is never compiler-enforced: `bayan format` applies it and it produces no diagnostic. Idiom lints are diagnostics, `.suggestion` by default, with severity set per lint in `package.byn` (`lints`). Grammar rules ([GRAMMAR](bayan-grammar.md)) are not style and cannot be configured away.

## Defaults

| Choice | Default |
|---|---|
| Braces | `{` always ends the line; a wrapped parameter list closes with `) {`. There is no own-line `{` and no `braces` knob |
| Indent | 4 spaces; header clauses and wrapped conditions continue at two levels (8) |
| Line width | 120 (`width`) |
| Alignment | `.runs` (`align`): consecutive lines of the same shape align their name and `=>` columns; a blank line or comment line ends the run. `.none` turns it off |
| Trailing commas | `.multiline` (`trailingCommas`): always in multi-line literals, argument lists and parameter lists; `.never` drops them |
| Member order | Fields, the `states` block, events, properties, static factories, methods |
| Signature clauses | `where`, `expects`, `uses`, `becomes`, `fails` (`bayan format` reorders; BYN1065) |
| Statements | One per line (postfix guards count as one) |
| Booleans | One spelling per project, set by `booleans`: `.symbols` (`!` `&&` `\|\|`) or `.words` (`not` `and` `or`) |
| Primitives | One spelling per project, set by `primitives`: `.sized` (`i32 i64 u8 f64 …`, the default) or `.csharp` (`int long byte double …`); `char`, `decimal` and `object` are not primitives under either |

## Declarations and bindings

Not configurable: declarations are type-first and local bindings name-first ([GRAMMAR §5](bayan-grammar.md)). `bayan format` rewrites the other order (BYN1043):

| Before | After |
|---|---|
| `public shippingWeight(order: Order) -> Grams { … }` | `public Grams shippingWeight(Order order) { … }` |
| `public ship(ref this, line: Line) { … }` | `public void ship(ref this, Line line) { … }` |
| `sku: Sku` (field) | `Sku sku` |
| `timeout(after: Millis)` (payload) | `timeout(Millis after)` |
| `Grams w = 0g` (in a function body) | `let w: Grams = 0g` |

## Text

- Use `std` operations for protocols, keys and identifiers, and `kit.intl` for text shown to people ([SPEC §16.4](bayan-spec.md)).
- Prefer `width:` in a format spec (`{id, width: 6, fill: '0'}`) over `padded(to:by:)`.

## Trees and graphs

Use typed indices (SPEC §3.5): nodes live in one list and refer to each other by a distinct index type, so there are no stored references, no region constraints and no per-access cost.

```csharp
type distinct NodeId = Index

struct Node {
    string name
    NodeId? parent
    List<NodeId> children
}

struct Tree {
    List<Node, NodeId> nodes
}
```

A `NodeId` cannot index a list with another index type (BYN3210, spec-only; not in 0.3: `List<T, I>` is not built, SPEC §3.5). Generational handles (`Handle<T>`, SPEC §9.6) wait until the selfhost AST or Sūq shows the need.

## Configuration

Configuration lives in `package.byn` as a Bayan struct literal:

```csharp
Package {
    name: "local/shop",
    version: "0.1.0",
    edition: 2027,
    kind: .app,
    capabilities: [.net],
    deps: [],
    style: Style {
        indent: 4,
        width: 120,
        align: .runs,                // or .none
        trailingCommas: .multiline,  // or .never
        booleans: .symbols,          // or .words
        primitives: .sized,          // or .csharp
        lints: [
            "guards.postfix": .warning,
            "functions.length": .none,
        ],
    },
}
```

(partial in 0.3: the manifest check (`src/Bayan.Syntax/Packages/Manifest.cs:35`, `selfhost/semantics/manifest.byn:369`) still takes the pre-2026-11-04 knobs (`braces`, a 100-column line knob, a bool `trailingCommas`) and rejects `width`, `align` and `lints`; `bayan format` reads only `booleans` and `primitives`)

## Style lints

Idioms are lints, `.suggestion` by default; `lints` in `style` sets the severity of each by name. Each takes a code in the `x900–x999` range of its area (revision 0017), assigned at the round-4 renumbering; none is allocated yet (not in 0.3).

| Lint | Flags |
|---|---|
| `guards.postfix` | an `if` block whose only statement is `return`, `fail`, `break` or `continue`: write `fail .x if c` |
| `lambdas.it` | `x => x.f` with one parameter: write `it.f` |
| `nesting.depth` | blocks nested more than 4 deep: exit early |
| `functions.length` | a body over N lines (off by default) |
| `conditions.named` | a control head that wraps: name the condition with a `let` |

## Opting out

```csharp
@unformatted because "rotation matrix laid out by hand"
const rotation = [
    1, 0,  0,
    0, c, -s,
    0, s,  c,
]
```

`@unformatted because "…"` is the only opt-out. It applies to declarations only; there are no comment toggles, and `bayan audit` lists every use (not in 0.3).
