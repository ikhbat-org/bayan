# Bayān style guide

Version: 0.4.0-dev (matches `bayan --version`)
Revisions applied: 0001–0024

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

## Layout

Each rule below shows what `bayan format` produces (Do) from the same code laid out otherwise (Don't). Layout never produces a diagnostic: run the formatter. The examples assume indent 4, width 120, `align: .runs` and `trailingCommas: .multiline`.

### Paragraphs inside functions

A blank line separates the steps of a function; the formatter keeps one blank line you wrote, collapses a run of blank lines to one, removes blank lines directly after `{` and before `}`, and never inserts one, so breaking paragraphs is your call.

Do:

```bayan
public Money total(Cart cart) {
    let subtotal = cart.subtotal()

    let tax = subtotal * cart.region.multiplier
    return subtotal + tax
}
```

Don't:

```bayan
public Money total(Cart cart) {

    let subtotal = cart.subtotal()


    let tax = subtotal * cart.region.multiplier
    return subtotal + tax
}
```

### Alignment runs

Under `.runs`, consecutive fields or properties of the same shape align their name column and the `=>` column, and a blank line or a `//` comment line ends the run; a `///` doc comment does not.

Do:

```bayan
struct Customer {
    CustomerId id
    Email      email
    string     name
    Tier       tier = .standard

    public bool   isVip       => tier is .gold or .platinum
    public string displayName => $"{name} <{email}>"
}
```

Don't:

```bayan
struct Customer {
    CustomerId id
    Email email
    string name
    Tier tier = .standard

    public bool isVip => tier is .gold or .platinum
    public string displayName => $"{name} <{email}>"
}
```

### Switch arms

Single-line switch arms form a run and align their `=>`; a multi-line arm ends the run.

Do:

```bayan
let label = order switch {
    .placed    => "Awaiting payment",
    .paid p    => $"Paid via {p.payment.method}",
    .shipped s => $"Shipped, tracking {s.tracking}",
    .canceled  => "Canceled",
}
```

Don't:

```bayan
let label = order switch {
    .placed => "Awaiting payment",
    .paid p => $"Paid via {p.payment.method}",
    .shipped s => $"Shipped, tracking {s.tracking}",
    .canceled => "Canceled",
}
```

### Outliers in a run

A line whose column sits more than 8 columns past the next-widest in its run (fields, properties, switch arms) leaves the run and stays unaligned, so one long line does not push the rest out.

Do:

```bayan
bool literal(TokenKind kind) => kind switch {
    .integerLiteral => true,
    .floatLiteral   => true,
    .stringLiteral or .rawStringLiteral or .cStringLiteral => true,
    _               => false,
}
```

Don't:

```bayan
bool literal(TokenKind kind) => kind switch {
    .integerLiteral                                        => true,
    .floatLiteral                                          => true,
    .stringLiteral or .rawStringLiteral or .cStringLiteral => true,
    _                                                      => false,
}
```

### Field defaults

In a run of fields, the `=` of each default aligns too; a field without a default takes part in the name column only.

Do:

```bayan
struct DistSource {
    string? commit = null
    bool    dirty  = false
    i64     count
}
```

Don't:

```bayan
struct DistSource {
    string? commit = null
    bool    dirty = false
    i64     count
}
```

### Doc comments in a run

A `///` line documents the next member and does not end its run; a blank line or a `//` line does.

Do:

```bayan
struct CCtx {
    /// `OwnershipChecks`.
    public bool   checks = false
    /// `_packageRoot`.
    public string root   = ""
}
```

Don't:

```bayan
struct CCtx {
    /// `OwnershipChecks`.
    public bool checks = false
    /// `_packageRoot`.
    public string root = ""
}
```

### Top-level layout

Top-level declarations are separated by one blank line, except consecutive one-line declarations of the same kind, which form a run and align their `=`.

Do:

```bayan
type distinct CustomerId = i64
type distinct Sku        = string requires it.length <= 16

effect db = net, fs

union error QuoteError {
    noTaxRegion
    discontinued(Sku sku)
}
```

Don't:

```bayan
type distinct CustomerId = i64
type distinct Sku        = string requires it.length <= 16
effect db = net, fs
union error QuoteError {
    noTaxRegion
    discontinued(Sku sku)
}
```

### Blocks and bodies

A block with statements always spans lines; only a `=>` body stays on one line.

Do:

```bayan
public void promote(ref this, to Tier next) {
    tier = next
}
```

Don't:

```bayan
public void promote(ref this, to Tier next) { tier = next }
```

### Case bodies

A `case` body on its own lines is indented one level past its `case`.

Do:

```bayan
switch kind {
    case .binary:
        let op = c.op
        go(op)
    default: {}
}
```

Don't:

```bayan
switch kind {
    case .binary:
    let op = c.op
    go(op)
    default: {}
}
```

### Empty arms

An empty arm, `default: {}`, stays on one line.

Do:

```bayan
switch kind {
    case .a: go()
    default: {}
}
```

Don't:

```bayan
switch kind {
    case .a: go()
    default:
        {}
}
```

### Attributes

An attribute goes on its own line above a type or function, and inline before a field or parameter.

Do:

```bayan
@derive(Json)
struct Note {
    @json(name: "note") string text
}
```

Don't:

```bayan
@derive(Json) struct Note {
    @json(name: "note") string text
}
```

### Member groups

One blank line separates member groups (fields, `states`, properties, static members, methods) and each method from the next.

Do:

```bayan
struct Cart {
    List<Line> lines

    public i32 count => lines.length

    public void add(ref this, Line line) {
        lines.append(line)
    }

    public void clear(ref this) {
        lines = []
    }
}
```

Don't:

```bayan
struct Cart {
    List<Line> lines
    public i32 count => lines.length
    public void add(ref this, Line line) {
        lines.append(line)
    }
    public void clear(ref this) {
        lines = []
    }
}
```

### Wrapped parameter lists and `) {`

`{` always ends the line: a parameter list that does not fit takes one parameter per line and closes with `) {` (with any clauses that fit); there is no own-line `{` and no `braces` knob.

Do:

```bayan
Booking book(
    Carrier carrier,
    Route route,
    Date date,
    Passenger passenger,
    Seat preferredSeat,
    Meal meal,
    Insurance insurance
) uses net, suspend fails BookingError {
    return try carrier.quote(route, on: date)
}
```

Don't:

```bayan
Booking book(Carrier carrier, Route route, Date date, Passenger passenger, Seat preferredSeat, Meal meal, Insurance insurance) uses net, suspend fails BookingError {
    return try carrier.quote(route, on: date)
}
```

### Header clauses

When the clauses do not fit on the header line, each gets its own line at two levels (8) and the last ends with ` {`, so the body at one level never lines up with a clause.

Do:

```bayan
public Money quote(Cart cart, for Customer customer)
        expects cart.lines.length > 0 && customer.region.isKnown
        uses db
        fails QuoteError {
    return cart.total(for: customer)
}
```

Don't:

```bayan
public Money quote(Cart cart, for Customer customer) expects cart.lines.length > 0 && customer.region.isKnown uses db fails QuoteError {
    return cart.total(for: customer)
}
```

### Wrapped conditions

A condition that does not fit breaks before `&&` or `||` (`and` or `or` under `booleans: .words`), continues at two levels (8) and ends with ` {`.

Do:

```bayan
if order is .paid
        && order.total >= freeShippingThreshold
        && customer.region.shipsFree
        && !order.hasOversizedOrHazardousItems {
    order.shipping = .free
}
```

Don't:

```bayan
if order is .paid && order.total >= freeShippingThreshold && customer.region.shipsFree && !order.hasOversizedOrHazardousItems {
    order.shipping = .free
}
```

### Chains

A chain that exceeds the width, or has three or more calls taking lambdas, puts every link on its own line with a leading `.`.

Do:

```bayan
let reminders = orders
    .where(it.placedAt < cutoff && it.total > minimum)
    .sorted(by: it.placedAt)
    .take(50)
    .map(Reminder(it.id, for: it.customer))
```

Don't:

```bayan
let reminders = orders.where(it.placedAt < cutoff && it.total > minimum).sorted(by: it.placedAt).take(50).map(Reminder(it.id, for: it.customer))
```

### Argument lists and literals

A list that fits stays on one line; otherwise it takes one item per line, a trailing comma (not in a parameter list, whose grammar has none) and the closing bracket on its own line, indented one level and never aligned to the opening parenthesis.

Do:

```bayan
let shipment = carrier.book(
    parcel,
    from: warehouse.address,
    to: order.shippingAddress,
    by: order.deadline,
    as: .express,
    insured: order.total > insuranceThreshold,
)
```

Don't:

```bayan
let shipment = carrier.book(parcel, from: warehouse.address, to: order.shippingAddress, by: order.deadline, as: .express, insured: order.total > insuranceThreshold)
```

### Trailing comma as intent

A list that fits stays on one line unless you end it with a trailing comma, which keeps it one item per line; without the comma the formatter joins it.

Do:

```bayan
let shipment = carrier.book(parcel, as: .express)
```

Don't:

```bayan
let shipment = carrier.book(
    parcel,
    as: .express
)
```

### Break order

An expression that does not fit breaks before every operator of its lowest precedence level (`??`, then `||`, then `&&`), in `if`, `let` and `return` alike; a parenthesised group that fits stays on one line, and nothing breaks inside an argument list while an operator break remains. Shown at width 60.

Do:

```bayan
bool hidden(i64 c) {
    return c < 0x20
        || (c >= 0x7F && c <= 0x9F)
        || c == 0x61C
        || (c >= 0x202A && c <= 0x202E)
}
```

Don't:

```bayan
bool hidden(i64 c) {
    return c < 0x20 || (c >= 0x7F && c <= 0x9F) || c == 0x61C
        || (c >= 0x202A
            && c <= 0x202E)
}
```

### Groups that do not fit

Only when a line still does not fit after its own operators have broken does a group break, before its own lowest operators. Shown at width 50.

Do:

```bayan
let inInstance = host != -1
    && !c.fns[host].isStatic
    && (c.fns[host].kind == .method
        || c.fns[host].kind == .getter)
```

Don't:

```bayan
let inInstance = host != -1 && !c.fns[host].isStatic && (
    c.fns[host].kind == .method || c.fns[host].kind == .getter)
```

### Indexes and members stay whole

A line never breaks inside an index bracket or a unit literal, or before a `.member` that follows `]`. Shown at width 56.

Do:

```bayan
let empty = c.variants[i].payload.length == 0
    && c.errors[c.variants[i].variant].fields.length > 0
```

Don't:

```bayan
let empty = c.variants[i].payload.length == 0
    && c.errors[
        c.variants[i].variant
    ].fields.length > 0
```

### Ternary ladder

A ternary that does not fit breaks before `?` and before `:`, each one continuation in. A line that starts with `?` or `:` would end a statement, so the ladder applies inside brackets only; a chain inside a ternary breaks only after the ternary has broken. Shown at width 80.

Do:

```bayan
shown.append(
    compiled.manifest is not null
        ? Path.relative(compiled.root, to: output).replaced("\\", by: "/")
        : output,
)
```

Don't:

```bayan
shown.append(
    compiled.manifest is not null ? Path
        .relative(compiled.root, to: output)
        .replaced("\\", by: "/") : output,
)
```

### Arrow bodies

A header with a `=>` body that does not fit breaks after `=>` first; its parameters wrap only when the header alone still does not fit. Shown at width 60.

Do:

```bayan
i64 total(i64 firstArgument, i64 secondArgument) =>
    firstArgument + secondArgument
```

Don't:

```bayan
i64 total(
    i64 firstArgument,
    i64 secondArgument
) => firstArgument + secondArgument
```

### Scalar lists

A list made only of scalars (numbers, chars, strings of 16 columns or fewer) fills each line, keeping as many items per row as your first row when that fits, and otherwise as many as fit the width.

Do:

```bayan
const t: u32[8] = [
    0x0041, 0x005A, 0x005F, 0x005F,
    0x0061, 0x007A, 0x00AA, 0x00AA,
]
```

Don't:

```bayan
const t: u32[8] = [
    0x0041, 0x005A, 0x005F, 0x005F,
    0x0061,
    0x007A, 0x00AA,
    0x00AA,
]
```

### Horizontal spacing

Binary operators, `=>`, `??` and `=` take one space on each side; ranges, calls, unary operators and generic arguments are tight; an annotation or label has no space before `:` and one after; struct literals have spaces inside the braces, and list literals and calls have none. A unit literal is tight by its grammar: `30 s` lexes as two tokens, so only `30s` is a duration.

Do:

```bayan
void show(List<Sku> skus) {
    let total = price * quantity
    let port = config.port ?? 8080
    let span = 0..n
    let origin = Point { x: 1, y: 2 }
    let sizes = [1, 2]
    let label = format(total)
    let done = !finished
    let w: Grams = -weight
}
```

Don't:

```bayan
void show(List< Sku > skus) {
    let total = price*quantity
    let port = config.port??8080
    let span = 0 .. n
    let origin = Point {x:1, y:2}
    let sizes = [ 1, 2 ]
    let label = format( total )
    let done = ! finished
    let w : Grams = - weight
}
```

### Interpolation holes

An interpolation hole is spaced like named arguments.

Do:

```bayan
let tag = $"{n, as: .hex}"
```

Don't:

```bayan
let tag = $"{n ,as:.hex}"
```

### Comments

A comment is `// ` followed by text, and trailing comments align within a run.

Do:

```bayan
struct Server {
    i64  port // default 8080
    bool tls  // on by default
}
```

Don't:

```bayan
struct Server {
    i64  port // default 8080
    bool tls // on by default
}
```

### Files

Files are UTF-8 with LF line endings, a final newline and no trailing whitespace (the Don't line below ends in spaces).

Do:

```bayan
let total = price * quantity
```

Don't:

```bayan
let total = price * quantity   
```

### Naming

Not changed by the formatter; a guideline. Types are `PascalCase`, everything else `camelCase`, acronyms are words (`Utf8`, `Json`, `httpClient`), and kind never appears as a prefix or suffix (`I…`, `_field`, `m_`), so the test skips this pair.

Do:

```bayan
struct Customer {
    string name
    HttpClient httpClient
}
```

Don't:

```bayan
struct customer {
    string m_name
    HTTPClient http_client
}
```

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

The `style` knobs are checked from 0.3.2; an old knob (`braces`, `maxLine`, a bool `trailingCommas`) is an error that names its replacement.

## Style lints

Idioms are lints, `.suggestion` by default and reported by `bayan check` only; `lints` in `style` sets the severity of each by name (`.none`, `.suggestion`, `.warning`, `.error`). Each Do block is the code the lint suggests.

### `guards.postfix` (BYN1072)

An `if` block whose only statement is `return`, `fail`, `break` or `continue` is written as a postfix guard.

Do:

```bayan
fail .emptyCart if cart.lines.isEmpty
```

Don't:

```bayan
if cart.lines.isEmpty {
    fail .emptyCart
}
```

### `lambdas.it` (BYN1073)

A lambda with one parameter that only reads a member is written with `it`.

Do:

```bayan
let names = customers.map(it.name)
```

Don't:

```bayan
let names = customers.map(c => c.name)
```

### `conditions.named` (BYN1074)

A control head that wraps is better served by naming the condition with a `let`.

Do:

```bayan
let shipsFree = order is .paid
    && order.total >= freeShippingThreshold
    && customer.region.shipsFree
    && !order.hasOversizedItems

order.shipping = .free if shipsFree
```

Don't:

```bayan
if order is .paid
        && order.total >= freeShippingThreshold
        && customer.region.shipsFree
        && !order.hasOversizedItems {
    order.shipping = .free
}
```

### `nesting.depth` (BYN1075)

Blocks nested more than 4 deep are flattened with early exits.

Do:

```bayan
void pack(Order order) {
    return if order is not .paid
    for line in order.lines {
        continue if !line.inStock
        continue if line.weight <= 0g
        continue if !line.fits(box)
        stow(line)
    }
}
```

Don't:

```bayan
void pack(Order order) {
    if order is .paid {
        for line in order.lines {
            if line.inStock {
                if line.weight > 0g {
                    if line.fits(box) {
                        stow(line)
                    }
                }
            }
        }
    }
}
```

### `functions.length` (BYN1076)

Off by default (set `"functions.length": .suggestion` in `lints` to turn it on); a body over 60 lines is split into named steps.

Do:

```bayan
void process(Order order) {
    validate(order)
    charge(order)
    ship(order)
}

void validate(Order order) {
    audit(order, step: 1)
    audit(order, step: 2)
    audit(order, step: 3)
    audit(order, step: 4)
    audit(order, step: 5)
    audit(order, step: 6)
    audit(order, step: 7)
    audit(order, step: 8)
    audit(order, step: 9)
    audit(order, step: 10)
    audit(order, step: 11)
    audit(order, step: 12)
    audit(order, step: 13)
    audit(order, step: 14)
    audit(order, step: 15)
    audit(order, step: 16)
    audit(order, step: 17)
    audit(order, step: 18)
    audit(order, step: 19)
    audit(order, step: 20)
}

void charge(Order order) {
    audit(order, step: 21)
    audit(order, step: 22)
    audit(order, step: 23)
    audit(order, step: 24)
    audit(order, step: 25)
    audit(order, step: 26)
    audit(order, step: 27)
    audit(order, step: 28)
    audit(order, step: 29)
    audit(order, step: 30)
    audit(order, step: 31)
    audit(order, step: 32)
    audit(order, step: 33)
    audit(order, step: 34)
    audit(order, step: 35)
    audit(order, step: 36)
    audit(order, step: 37)
    audit(order, step: 38)
    audit(order, step: 39)
    audit(order, step: 40)
}

void ship(Order order) {
    audit(order, step: 41)
    audit(order, step: 42)
    audit(order, step: 43)
    audit(order, step: 44)
    audit(order, step: 45)
    audit(order, step: 46)
    audit(order, step: 47)
    audit(order, step: 48)
    audit(order, step: 49)
    audit(order, step: 50)
    audit(order, step: 51)
    audit(order, step: 52)
    audit(order, step: 53)
    audit(order, step: 54)
    audit(order, step: 55)
    audit(order, step: 56)
    audit(order, step: 57)
    audit(order, step: 58)
    audit(order, step: 59)
    audit(order, step: 60)
    audit(order, step: 61)
}
```

Don't:

```bayan
void process(Order order) {
    audit(order, step: 1)
    audit(order, step: 2)
    audit(order, step: 3)
    audit(order, step: 4)
    audit(order, step: 5)
    audit(order, step: 6)
    audit(order, step: 7)
    audit(order, step: 8)
    audit(order, step: 9)
    audit(order, step: 10)
    audit(order, step: 11)
    audit(order, step: 12)
    audit(order, step: 13)
    audit(order, step: 14)
    audit(order, step: 15)
    audit(order, step: 16)
    audit(order, step: 17)
    audit(order, step: 18)
    audit(order, step: 19)
    audit(order, step: 20)
    audit(order, step: 21)
    audit(order, step: 22)
    audit(order, step: 23)
    audit(order, step: 24)
    audit(order, step: 25)
    audit(order, step: 26)
    audit(order, step: 27)
    audit(order, step: 28)
    audit(order, step: 29)
    audit(order, step: 30)
    audit(order, step: 31)
    audit(order, step: 32)
    audit(order, step: 33)
    audit(order, step: 34)
    audit(order, step: 35)
    audit(order, step: 36)
    audit(order, step: 37)
    audit(order, step: 38)
    audit(order, step: 39)
    audit(order, step: 40)
    audit(order, step: 41)
    audit(order, step: 42)
    audit(order, step: 43)
    audit(order, step: 44)
    audit(order, step: 45)
    audit(order, step: 46)
    audit(order, step: 47)
    audit(order, step: 48)
    audit(order, step: 49)
    audit(order, step: 50)
    audit(order, step: 51)
    audit(order, step: 52)
    audit(order, step: 53)
    audit(order, step: 54)
    audit(order, step: 55)
    audit(order, step: 56)
    audit(order, step: 57)
    audit(order, step: 58)
    audit(order, step: 59)
    audit(order, step: 60)
    audit(order, step: 61)
}
```

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
