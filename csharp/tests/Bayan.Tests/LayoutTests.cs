using System.Text;
using Bayan.Cli;
using Bayan.Syntax.Lexing;
using Bayan.Syntax.Packages;
using Bayan.Syntax.Text;

namespace Bayan.Tests;

public sealed class LayoutTests
{
    private static string Lay(string source, LayoutOptions? options = null)
    {
        var (output, skipped) = Layout.Apply(Encoding.UTF8.GetBytes(source), options ?? new LayoutOptions());
        Assert.Null(skipped);
        return Encoding.UTF8.GetString(output);
    }

    private static (int Exit, string Out, string Err) Run(params string[] args)
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var exit = CliApp.Run(args, stdout, stderr);
        return (exit, stdout.ToString(), stderr.ToString());
    }

    /// <summary>A fresh file under <c>tmp/layout/</c> holding <paramref name="text"/>.</summary>
    private static string Fresh(string name, string text)
    {
        var dir = Path.Combine(Golden.RepoRoot, "tmp", "layout", name);
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, "main.byn");
        File.WriteAllText(file, text);
        return file;
    }

    // ── Hygiene ──

    [Fact]
    public void LineEndingsBecomeLf() => Assert.Equal("let a = 1\nlet b = 2\n", Lay("let a = 1\r\nlet b = 2\r\n"));

    [Fact]
    public void TrailingWhitespaceIsDropped() => Assert.Equal("let a = 1 // one\nlet b = 2\n", Lay("let a = 1 // one \t\nlet b = 2   \n"));

    [Fact]
    public void AFinalNewlineIsAdded() => Assert.Equal("let a = 1\n", Lay("let a = 1"));

    [Fact]
    public void ExtraFinalNewlinesAreDropped() => Assert.Equal("let a = 1\n", Lay("let a = 1\n\n\n"));

    [Fact]
    public void AnEmptyFileStaysEmpty() => Assert.Equal("", Lay(""));

    // ── Indentation ──

    [Fact]
    public void BlocksIndentOneLevel() => Assert.Equal(
        "void main() {\n    let a = 1\n    if a > 0 {\n        print(a)\n    }\n}\n",
        Lay("void main() {\nlet a = 1\n  if a > 0 {\n print(a)\n      }\n}\n"));

    [Fact]
    public void AWaslLineGoesOneLevelDeeper() => Assert.Equal(
        "void main() {\n    let s = xs\n        .map(f)\n        ?? ys\n}\n",
        Lay("void main() {\n    let s = xs\n    .map(f)\n  ?? ys\n}\n"));

    [Fact]
    public void ALineAfterAnOperatorContinues() => Assert.Equal(
        "void main() {\n    let s = a +\n        b\n    print(s)\n}\n",
        Lay("void main() {\n    let s = a +\nb\n    print(s)\n}\n"));

    [Fact]
    public void HeaderClausesTakeTwoLevels() => Assert.Equal(
        "public Money quote(Cart cart)\n        expects cart.total > 0\n        uses db\n        fails QuoteError {\n    return cart.total\n}\n",
        Lay("public Money quote(Cart cart)\n    expects cart.total > 0\n    uses db\n    fails QuoteError {\n    return cart.total\n}\n"));

    [Fact]
    public void AWrappedConditionTakesTwoLevels() => Assert.Equal(
        "void main() {\n    if a\n            and b {\n        print(a)\n    }\n}\n",
        Lay("void main() {\n    if a\n    and b {\n        print(a)\n    }\n}\n"));

    [Fact]
    public void ACloserSitsAtItsOpenersLevel() => Assert.Equal(
        "void main() {\n    f(\n        1,\n        2,\n    )\n    let xs = [\n        1,\n    ]\n}\n",
        Lay("void main() {\n    f(\n1,\n            2,\n        )\n    let xs = [\n  1,\n  ]\n}\n"));

    [Fact]
    public void ACommentLineTakesTheNextLinesLevel() => Assert.Equal(
        "void main() {\n    // first\n    let a = 1\n    // last\n}\n",
        Lay("void main() {\n// first\n    let a = 1\n        // last\n}\n"));

    // ── Spacing ──

    [Fact]
    public void BinaryOperatorsTakeOneSpaceEachSide() => Assert.Equal(
        "let a = b + c - d == e && f || g ?? h\n",
        Lay("let a=b+c  -d==e&&f||g??h\n"));

    [Fact]
    public void ArrowsAndAssignmentsAreSpaced() => Assert.Equal(
        "bool isA(rune c) => c == 'a'\n",
        Lay("bool isA(rune c)=>c=='a'\n"));

    [Fact]
    public void RangesAreTight() => Assert.Equal("for i in 0..10 {\n    print(i)\n}\nfor i in 0..<n {\n    print(i)\n}\n",
        Lay("for i in 0 .. 10 { print(i) }\nfor i in 0 ..< n { print(i) }\n"));

    [Fact]
    public void UnaryOperatorsAreTight() => Assert.Equal("let a = -b\nlet c = !d\n", Lay("let a = - b\nlet c = ! d\n"));

    [Fact]
    public void AColonTakesASpaceAfterOnly() => Assert.Equal(
        "let p = Point { x: 1, y: 2 }\nf(ref c, by: d)\n",
        Lay("let p = Point{x :1,y:2}\nf(ref c , by :d)\n"));

    [Fact]
    public void TernaryAndConformanceColonsAreSpaced() => Assert.Equal(
        "let a = b ? c : d\nstruct S : I { i32 x }\n",
        Lay("let a = b ? c:d\nstruct S: I { i32 x }\n"));

    [Fact]
    public void GroupsAreNotPaddedAndCallsAreTight() => Assert.Equal(
        "let a = f(x, y)[0]\n",
        Lay("let a = f ( x,y ) [ 0 ]\n"));

    [Fact]
    public void ASpaceBeforeAParenAfterAKeywordOrLiteralIsKept() => Assert.Equal(
        "test \"positive\" (i32 n) {\n    assert(n > 0)\n}\n",
        Lay("test \"positive\" (i32 n) {\n    assert(n > 0)\n}\n"));

    [Fact]
    public void GenericsPointersAndUnitsStayTight() => Assert.Equal(
        "List<i32> xs = make()\nu8* p = q\nlet t = 30s\nlet s = a >> 2\n",
        Lay("List<i32> xs = make()\nu8* p = q\nlet t = 30s\nlet s = a >> 2\n"));

    [Fact]
    public void ATrailingCommentTakesOneSpace() => Assert.Equal(
        "let a = 1 // a  note\nlet b = 2 // b\n",
        Lay("let a = 1      // a  note\nlet b = 2// b\n"));

    [Fact]
    public void ACommentTakesOneSpaceAfterItsSlashes() => Assert.Equal(
        "// tight\n/// doc\n//\nlet a = 1 // b  c\n",
        Lay("//tight\n///doc\n//\nlet a = 1 //b  c\n"));

    [Fact]
    public void StringContentsAreNotTouched() => Assert.Equal(
        "let a = \"x  =  y \"\nlet b = $\"  x {a}  -\"\n",
        Lay("let a  =  \"x  =  y \"\nlet b = $\"  x {a}  -\"\n"));

    [Fact]
    public void InterpolationHolesAreSpacedAsNamedArguments() => Assert.Equal(
        "let s = $\"{n, as: .hex} and {a + 1}\"\n",
        Lay("let s = $\"{n,as:.hex} and { a+1 }\"\n"));

    [Fact]
    public void BecomesKeepsTheSpaceBeforeItsState() => Assert.Equal(
        "void pay(ref this is .draft) becomes .paid {\n}\n",
        Lay("void pay(ref this is .draft) becomes .paid {\n}\n"));

    [Fact]
    public void IsKeepsTheSpaceBeforeEachOfSeveralStates() => Assert.Equal(
        "i64 amount(this is .paid or .shipped) => payment\n",
        Lay("i64 amount(this is .paid or .shipped) => payment\n"));

    [Fact]
    public void ReturnKeepsTheSpaceBeforeItsCase() => Assert.Equal(
        "Color pick() {\n    return .red\n}\n",
        Lay("Color pick() {\n    return .red\n}\n"));

    [Fact]
    public void FailKeepsTheSpaceBeforeItsCase() => Assert.Equal(
        "void check(string s) fails ParseError {\n    fail .empty if s.isEmpty\n}\n",
        Lay("void check(string s) fails ParseError {\n    fail .empty if s.isEmpty\n}\n"));

    [Fact]
    public void CaseKeepsTheSpaceBeforeItsPattern() => Assert.Equal(
        "i64 f(Color c) => c switch {\n    case .red => 1\n    case .green => 2\n}\n",
        Lay("i64 f(Color c) => c switch {\n    case .red => 1\n    case .green => 2\n}\n"));

    [Fact]
    public void ExceptKeepsTheSpaceBeforeItsCase() => Assert.Equal(
        "union error Retryable = SendError except .rejected\n",
        Lay("union error Retryable = SendError except .rejected\n"));

    [Fact]
    public void AndKeepsTheSpaceBeforeItsState() => Assert.Equal(
        "void f(Order o) requires o is .paid and o is .shipped {\n}\n",
        Lay("void f(Order o) requires o is .paid and o is .shipped {\n}\n"));

    [Fact]
    public void MemberAccessAfterANameStaysJoined() => Assert.Equal(
        "let a = order.paid\nlet b = f().x\n",
        Lay("let a = order.paid\nlet b = f().x\n"));

    // ── Blank lines ──

    [Fact]
    public void BlankLineRunsCollapseToOne() => Assert.Equal(
        "void main() {\n    let a = 1\n\n    let b = 2\n}\n",
        Lay("void main() {\n\n    let a = 1\n\n\n\n    let b = 2\n\n}\n"));

    [Fact]
    public void ABlankLineGoesBetweenTopLevelDeclarations() => Assert.Equal(
        "void f() {\n}\n\nvoid g() {\n}\n",
        Lay("void f() {\n}\nvoid g() {\n}\n"));

    [Fact]
    public void OneLineDeclarationsOfOneKindStayTogether() => Assert.Equal(
        "struct A { i32 x }\nstruct B { i32 y }\n\ntype F = i32 -> bool\n\nvoid f() {\n}\n",
        Lay("struct A { i32 x }\nstruct B { i32 y }\ntype F = i32 -> bool\nvoid f() {\n}\n"));

    [Fact]
    public void AnAuthorsBlankLineBetweenOneLinersIsKept() => Assert.Equal(
        "struct A { i32 x }\n\nstruct B { i32 y }\n",
        Lay("struct A { i32 x }\n\n\nstruct B { i32 y }\n"));

    // ── Joins and breaks: the proposal's §3.1, §3.4–§3.6 ──

    private const string QuoteBody =
        "    let rates = taxRates.forRegion(customer.region) ?? fail .noTaxRegion\n" +
        "    var subtotal = Money.zero(cart.currency)\n" +
        "    for line in cart.lines {\n" +
        "        let product = try catalog.find(line.sku)\n" +
        "        fail .discontinued(line.sku) if product.isDiscontinued\n" +
        "        subtotal = subtotal + product.price * line.quantity\n" +
        "    }\n" +
        "    let discount = customer.tier.discount(on: subtotal)\n" +
        "    let total = (subtotal - discount) * rates.multiplier\n" +
        "    log($\"quote {cart.id}: {total}\", as: .debug)\n" +
        "    return total\n" +
        "}\n";

    private const string Proposal31Before =
        "public Money quote(Cart cart, for Customer customer) expects cart.lines.length > 0 uses db fails QuoteError {\n" + QuoteBody;

    private const int Proposal31Width = 100;

    // The Before header is 109 columns, so it fits at 120; at 100 its clauses wrap. The After's blank lines are the
    // author's: the formatter never inserts one (docs/bayan-style.md, "Paragraphs inside functions").
    [Fact]
    public void Proposal31ParagraphsWrapTheHeaderClausesAndAddNoBlankLines() => Assert.Equal(
        "public Money quote(Cart cart, for Customer customer)\n        expects cart.lines.length > 0\n        uses db\n" +
        "        fails QuoteError {\n" + QuoteBody,
        Lay(Proposal31Before, new LayoutOptions(Width: Proposal31Width)));

    [Fact]
    public void Proposal31AfterIsLaidOut()
    {
        const string after =
            "public Money quote(Cart cart, for Customer customer)\n        expects cart.lines.length > 0\n        uses db\n" +
            "        fails QuoteError {\n" +
            "    let rates = taxRates.forRegion(customer.region) ?? fail .noTaxRegion\n" +
            "    var subtotal = Money.zero(cart.currency)\n\n" +
            "    for line in cart.lines {\n" +
            "        let product = try catalog.find(line.sku)\n" +
            "        fail .discontinued(line.sku) if product.isDiscontinued\n\n" +
            "        subtotal = subtotal + product.price * line.quantity\n" +
            "    }\n\n" +
            "    let discount = customer.tier.discount(on: subtotal)\n" +
            "    let total = (subtotal - discount) * rates.multiplier\n\n" +
            "    log($\"quote {cart.id}: {total}\", as: .debug)\n" +
            "    return total\n" +
            "}\n";
        Assert.Equal(after, Lay(after));
    }

    [Fact]
    public void Proposal34WrappedConditionBreaksBeforeEachAnd() => Assert.Equal(
        "if order is .paid\n        and order.total >= freeShippingThreshold\n        and customer.region.shipsFree\n" +
        "        and not order.hasOversizedItems {\n    order.shipping = .free\n}\n",
        Lay("if order is .paid and order.total >= freeShippingThreshold and customer.region.shipsFree and not order.hasOversizedItems {\n" +
            "    order.shipping = .free\n}\n"));

    [Fact]
    public void Proposal35ChainBreaksEveryLink() => Assert.Equal(
        "let reminders = orders\n    .where(it.placedAt < cutoff and it.total > minimum)\n    .sorted(by: it.placedAt)\n    .take(50)\n" +
        "    .map(Reminder(it.id, for: it.customer))\n",
        Lay("let reminders = orders.where(it.placedAt < cutoff and it.total > minimum).sorted(by: it.placedAt).take(50).map(Reminder(it.id, for: it.customer))\n"));

    [Fact]
    public void Proposal36ArgumentListBreaksWithATrailingComma() => Assert.Equal(
        "let shipment = carrier.book(\n    parcel,\n    from: warehouse.address,\n    to: order.shippingAddress,\n" +
        "    by: order.deadline,\n    as: .express,\n)\n",
        Lay("let shipment = carrier.book(parcel, from: warehouse.address, to: order.shippingAddress, by: order.deadline, as: .express)\n"));

    // ── Joins and breaks: docs/bayan-style.md Don't → Do ──

    [Fact]
    public void StyleWrappedParameterListTakesNoTrailingCommaAndClosesWithParenBrace() => Assert.Equal(
        "Booking book(\n    Carrier carrier,\n    Route route,\n    Date date,\n    Passenger passenger,\n    Seat preferredSeat,\n" +
        "    Meal meal,\n    Insurance insurance\n) uses net, suspend fails BookingError {\n    return try carrier.quote(route, on: date)\n}\n",
        Lay("Booking book(Carrier carrier, Route route, Date date, Passenger passenger, Seat preferredSeat, Meal meal, Insurance insurance) uses net, suspend fails BookingError {\n" +
            "    return try carrier.quote(route, on: date)\n}\n"));

    [Fact]
    public void StyleHeaderClausesGoOnePerLine() => Assert.Equal(
        "public Money quote(Cart cart, for Customer customer)\n        expects cart.lines.length > 0 && customer.region.isKnown\n" +
        "        uses db\n        fails QuoteError {\n    return cart.total(for: customer)\n}\n",
        Lay("public Money quote(Cart cart, for Customer customer) expects cart.lines.length > 0 && customer.region.isKnown uses db fails QuoteError {\n" +
            "    return cart.total(for: customer)\n}\n"));

    [Fact]
    public void StyleWrappedConditionBreaksBeforeEachAmpAmp() => Assert.Equal(
        "if order is .paid\n        && order.total >= freeShippingThreshold\n        && customer.region.shipsFree\n" +
        "        && !order.hasOversizedOrHazardousItems {\n    order.shipping = .free\n}\n",
        Lay("if order is .paid && order.total >= freeShippingThreshold && customer.region.shipsFree && !order.hasOversizedOrHazardousItems {\n" +
            "    order.shipping = .free\n}\n"));

    [Fact]
    public void StyleChainBreaksEveryLink() => Assert.Equal(
        "let reminders = orders\n    .where(it.placedAt < cutoff && it.total > minimum)\n    .sorted(by: it.placedAt)\n    .take(50)\n" +
        "    .map(Reminder(it.id, for: it.customer))\n",
        Lay("let reminders = orders.where(it.placedAt < cutoff && it.total > minimum).sorted(by: it.placedAt).take(50).map(Reminder(it.id, for: it.customer))\n"));

    [Fact]
    public void StyleArgumentListBreaksWithATrailingComma() => Assert.Equal(
        "let shipment = carrier.book(\n    parcel,\n    from: warehouse.address,\n    to: order.shippingAddress,\n" +
        "    by: order.deadline,\n    as: .express,\n    insured: order.total > insuranceThreshold,\n)\n",
        Lay("let shipment = carrier.book(parcel, from: warehouse.address, to: order.shippingAddress, by: order.deadline, as: .express, insured: order.total > insuranceThreshold)\n"));

    [Fact]
    public void StyleAListThatFitsWithoutATrailingCommaJoins() => Assert.Equal(
        "let shipment = carrier.book(parcel, as: .express)\n",
        Lay("let shipment = carrier.book(\n    parcel,\n    as: .express\n)\n"));

    // ── Joins and breaks: the rules ──

    [Fact]
    public void AnAuthorsTrailingCommaKeepsAListVertical() => Assert.Equal(
        "let s = f(\n    a,\n    b,\n)\nlet t = [\n    x,\n    y,\n]\n",
        Lay("let s = f(a, b,)\nlet t = [\n    x, y,\n]\n"));

    [Fact]
    public void NeverDropsTrailingCommasAndAddsNone() => Assert.Equal(
        "let s = f(a, b)\nlet t = g(\n    argumentNumberOne,\n    argumentNumberTwo,\n    argumentNumberThree\n)\n",
        Lay("let s = f(\n    a,\n    b,\n)\nlet t = g(argumentNumberOne, argumentNumberTwo, argumentNumberThree)\n",
            new LayoutOptions(Width: 40, TrailingCommasMultiline: false)));

    [Fact]
    public void AStructLiteralBreaksButNeverJoins() => Assert.Equal(
        "let p = Point {\n    x: 1,\n    y: 2\n}\nlet q = Point {\n    x: firstCoordinate,\n    y: secondCoordinate,\n}\n",
        Lay("let p = Point {\n    x: 1,\n    y: 2\n}\nlet q = Point { x: firstCoordinate, y: secondCoordinate }\n", new LayoutOptions(Width: 40)));

    [Fact]
    public void AChainBrokenAtLeadingDotsThatFitsJoins() => Assert.Equal(
        "let n = xs.take(2).count()\n",
        Lay("let n = xs\n    .take(2)\n    .count()\n"));

    [Fact]
    public void ThreeLambdaCallsBreakAChainThatFits() => Assert.Equal(
        "let n = xs\n    .map(it + 1)\n    .where(it > 0)\n    .sorted(by: it)\n",
        Lay("let n = xs.map(it + 1).where(it > 0).sorted(by: it)\n"));

    [Fact]
    public void APartlyBrokenChainBreaksEveryLink() => Assert.Equal(
        "let n = xs\n    .map(it + 1)\n    .where(it > 0)\n    .sorted(by: it)\n",
        Lay("let n = xs.map(it + 1)\n    .where(it > 0).sorted(by: it)\n"));

    [Fact]
    public void AVerticalListTakesOneItemPerLine() => Assert.Equal(
        "let t = f(\n    1,\n    2,\n    3,\n)\n",
        Lay("let t = f(1, 2,\n    3,\n)\n"));

    [Fact]
    public void AParenthesisedHeadIsNotBrokenAfter() => Assert.Equal(
        "if (alpha || beta) && gamma\n        && delta {\n    go()\n}\n",
        Lay("if (alpha || beta) && gamma && delta {\n    go()\n}\n", new LayoutOptions(Width: 30)));

    [Fact]
    public void AnOverWideOneLineBodyOpens() => Assert.Equal(
        "if ready {\n    launch(firstArgument, secondArgument)\n}\n",
        Lay("if ready { launch(firstArgument, secondArgument) }\n", new LayoutOptions(Width: 45)));

    // `check(…) {` reads like a parameter list, so it takes no trailing comma.
    [Fact]
    public void ABodyAfterAListBrokenInAConditionStaysAtOneLevel() => Assert.Equal(
        "void main() {\n    if a\n            && check(\n                firstArgument,\n                secondArgument\n            ) {\n" +
        "        go()\n    }\n}\n",
        Lay("void main() {\n    if a\n            && check(firstArgument, secondArgument) {\n        go()\n    }\n}\n", new LayoutOptions(Width: 40)));

    [Fact]
    public void APatternAndAnIndexTakeNoTrailingComma() => Assert.Equal(
        "void main() {\n    switch k {\n        case .pair(let first, let second): return f(\n            first,\n" +
        "            by: grid[rowNumber, columnNumber],\n        )\n    }\n}\n",
        Lay("void main() {\n    switch k {\n        case .pair(let first, let second): return f(first, by: grid[rowNumber, columnNumber])\n    }\n}\n",
            new LayoutOptions(Width: 72)));

    [Fact]
    public void AVerticalPatternTakesNoTrailingComma()
    {
        const string source = "void main() {\n    switch k {\n        case .pair(\n            let firstValue,\n            let secondValue\n        ): go()\n    }\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 30)));
    }

    [Fact]
    public void ATernaryColonKeepsItsSpaceAfterABreak() => Assert.Equal(
        "let x = c ? first(\n    argumentNumberOne,\n    argumentNumberTwo,\n) : \"\"\n",
        Lay("let x = c ? first(argumentNumberOne, argumentNumberTwo) : \"\"\n", new LayoutOptions(Width: 40)));

    // ── Alignment runs: the proposal's §3.2, §3.3, §3.7 ──

    // The member-group blank lines and the opened method body of the After are taken as written: R3 has no rule for
    // either, so the input has them and the test checks the alignment.
    [Fact]
    public void Proposal32FieldAndPropertyRunsAlign() => Assert.Equal(
        "@derive(Json, Row)\npublic struct Customer {\n    CustomerId id\n    Email      email\n    string     name\n" +
        "    Region     region\n    Tier       tier = .standard\n    Instant    createdAt\n\n" +
        "    public bool   isVip       => tier is .gold or .platinum\n    public string displayName => $\"{name} <{email}>\"\n\n" +
        "    public void promote(ref this, to Tier next) {\n        tier = next\n    }\n}\n",
        Lay("@derive(Json, Row)\npublic struct Customer {\n    CustomerId id\n    Email email\n    string name\n    Region region\n" +
            "    Tier tier = .standard\n    Instant createdAt\n\n    public bool isVip => tier is .gold or .platinum\n" +
            "    public string displayName => $\"{name} <{email}>\"\n\n    public void promote(ref this, to Tier next) {\n" +
            "        tier = next\n    }\n}\n"));

    // The proposal writes `switch order { … }` with no commas, which does not parse; the arms are those of
    // docs/bayan-style.md. Its After leaves `.canceled =>` unaligned against its own rule; the rule wins.
    [Fact]
    public void Proposal33OneLineArmsAlignTheirArrows() => Assert.Equal(
        "let label = order switch {\n    .placed    => \"Awaiting payment\",\n    .paid p    => $\"Paid via {p.payment.method}\",\n" +
        "    .shipped s => $\"Shipped, tracking {s.tracking}\",\n    .canceled  => \"Canceled\",\n}\n",
        Lay("let label = order switch {\n    .placed => \"Awaiting payment\",\n    .paid p => $\"Paid via {p.payment.method}\",\n" +
            "    .shipped s => $\"Shipped, tracking {s.tracking}\",\n    .canceled => \"Canceled\",\n}\n"));

    // The proposal's `quote(…) …` is given a body so that it parses.
    [Fact]
    public void Proposal37OneLineDeclarationsAlignTheirEquals() => Assert.Equal(
        "type distinct CustomerId = i64\ntype distinct Sku        = string requires it.length <= 16\n\neffect db = net, fs\n\n" +
        "union error QuoteError {\n    noTaxRegion\n    discontinued(Sku sku)\n}\n\n" +
        "public Money quote(Cart cart, for Customer customer) {\n    return cart.total\n}\n",
        Lay("type distinct CustomerId = i64\ntype distinct Sku = string requires it.length <= 16\neffect db = net, fs\n" +
            "union error QuoteError {\n    noTaxRegion\n    discontinued(Sku sku)\n}\n" +
            "public Money quote(Cart cart, for Customer customer) {\n    return cart.total\n}\n"));

    // ── Alignment runs: docs/bayan-style.md Don't → Do ──

    [Fact]
    public void StyleAlignmentRuns() => Assert.Equal(
        "struct Customer {\n    CustomerId id\n    Email      email\n    string     name\n    Tier       tier = .standard\n\n" +
        "    public bool   isVip       => tier is .gold or .platinum\n    public string displayName => $\"{name} <{email}>\"\n}\n",
        Lay("struct Customer {\n    CustomerId id\n    Email email\n    string name\n    Tier tier = .standard\n\n" +
            "    public bool isVip => tier is .gold or .platinum\n    public string displayName => $\"{name} <{email}>\"\n}\n"));

    [Fact]
    public void StyleSwitchArms() => Assert.Equal(
        "let label = order switch {\n    .placed    => \"Awaiting payment\",\n    .paid p    => $\"Paid via {p.payment.method}\",\n" +
        "    .shipped s => $\"Shipped, tracking {s.tracking}\",\n    .canceled  => \"Canceled\",\n}\n",
        Lay("let label = order switch {\n    .placed => \"Awaiting payment\",\n    .paid p => $\"Paid via {p.payment.method}\",\n" +
            "    .shipped s => $\"Shipped, tracking {s.tracking}\",\n    .canceled => \"Canceled\",\n}\n"));

    [Fact]
    public void StyleTopLevelLayout() => Assert.Equal(
        "type distinct CustomerId = i64\ntype distinct Sku        = string requires it.length <= 16\n\neffect db = net, fs\n\n" +
        "union error QuoteError {\n    noTaxRegion\n    discontinued(Sku sku)\n}\n",
        Lay("type distinct CustomerId = i64\ntype distinct Sku        = string requires it.length <= 16\neffect db = net, fs\n" +
            "union error QuoteError {\n    noTaxRegion\n    discontinued(Sku sku)\n}\n"));

    [Fact]
    public void StyleTrailingCommentsAlign() => Assert.Equal(
        "struct Server {\n    i64  port // default 8080\n    bool tls  // on by default\n}\n",
        Lay("struct Server {\n    i64  port // default 8080\n    bool tls // on by default\n}\n"));

    // ── Alignment runs: the rules ──

    [Fact]
    public void ABlankLineEndsARun() => Assert.Equal(
        "struct S {\n    i32 a\n\n    string bb\n    i64    c\n}\n",
        Lay("struct S {\n    i32 a\n\n    string bb\n    i64 c\n}\n"));

    [Fact]
    public void ACommentLineEndsARun() => Assert.Equal(
        "struct S {\n    i32 a\n    // the rest\n    string bb\n    i64    c\n}\n",
        Lay("struct S {\n    i32 a\n    // the rest\n    string bb\n    i64 c\n}\n"));

    [Fact]
    public void AMultiLineArmEndsARun() => Assert.Equal(
        "let n = k switch {\n    .a => 1,\n    .bb => f(\n        x,\n    ),\n    .ccc => 3,\n    .d   => 4,\n}\n",
        Lay("let n = k switch {\n    .a => 1,\n    .bb => f(\n        x,\n    ),\n    .ccc => 3,\n    .d => 4,\n}\n"));

    [Fact]
    public void FieldsAndPropertiesAreRunsOfTheirOwn() => Assert.Equal(
        "struct S {\n    i32    a\n    string bb\n\n    public i64 c  => a\n    bool       dd => true\n}\n",
        Lay("struct S {\n    i32 a\n    string bb\n    public i64 c => a\n    bool dd => true\n}\n"));

    [Fact]
    public void TrailingCommentsAlignOnlyAtOneLevel() => Assert.Equal(
        "void main() {\n    let a = 1   // one\n    let bcd = 2 // two\n    if a > 0 {  // three\n        go() // four\n    }\n}\n",
        Lay("void main() {\n    let a = 1 // one\n    let bcd = 2 // two\n    if a > 0 { // three\n        go() // four\n    }\n}\n"));

    [Fact]
    public void AColumnThatWouldPassTheWidthStaysUnaligned()
    {
        const string source = "struct S {\n    i32 aaaaaaaaaaaaaaaaaaaa\n    LongerTypeName b\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 30)));
    }

    [Fact]
    public void AGapTheParserReadsIsNotPadded()
    {
        const string source = "struct S {\n    u8* p\n    Instant n\n}\n";
        Assert.Equal(source, Lay(source));
    }

    [Fact]
    public void NoneAlignsNothing()
    {
        const string source = "type A = i64\ntype Bb = string\n\nstruct S {\n    i32 a // x\n    string bb // y\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(AlignRuns: false)));
    }

    private const string AlignNoneInput = "struct S {\n    i32 a\n    string bb\n}\n";
    private const string AlignNonePackage = "Package { name: \"local/t\", version: \"0.1.0\", style: Style { align: .none } }\n";

    [Fact]
    public void TheManifestsAlignNoneReachesLayout()
    {
        var file = Fresh("align", AlignNoneInput);
        File.WriteAllText(Path.Combine(Path.GetDirectoryName(file)!, "package.byn"), AlignNonePackage);
        var (exit, _, stderr) = Run("format", file);
        Assert.Equal(CliApp.ExitOk, exit);
        Assert.DoesNotContain("skipped", stderr);
        Assert.Equal(AlignNoneInput, File.ReadAllText(file));
    }

    [Fact]
    public void AlignmentIsIdempotent()
    {
        var once = Lay("struct S {\n    i32 a // x\n    string bb = \"q\" // y\n    public bool c => a > 0\n    i64 dd => 2\n}\n" +
                       "type A = i64\ntype Bb = string\n");
        Assert.Equal(once, Lay(once));
    }

    // ── The guide's rules T4–T6 left out (docs/bayan-style.md) ──

    [Fact]
    public void ABinaryOperatorIsSpacedAndAUnaryMinusStaysTight() => Assert.Equal(
        "void show() {\n    let d = a - b\n    let w: Grams = -weight\n    let f = c ?? -d\n}\n",
        Lay("void show() {\n    let d = a-b\n    let w: Grams = - weight\n    let f = c??-d\n}\n"));

    [Fact]
    public void StyleHorizontalSpacing() => Assert.Equal(
        "void show(List<Sku> skus) {\n    let total = price * quantity\n    let port = config.port ?? 8080\n    let span = 0..n\n"
        + "    let origin = Point { x: 1, y: 2 }\n    let sizes = [1, 2]\n    let label = format(total)\n"
        + "    let done = !finished\n    let w: Grams = -weight\n}\n",
        Lay("void show(List< Sku > skus) {\n    let total = price*quantity\n    let port = config.port??8080\n    let span = 0 .. n\n"
            + "    let origin = Point {x:1, y:2}\n    let sizes = [ 1, 2 ]\n    let label = format( total )\n"
            + "    let done = ! finished\n    let w : Grams = - weight\n}\n"));

    [Fact]
    public void APointerWrittenTightStaysAPointer()
    {
        const string source = "void f(u8*p) {\n    let n = a * b\n}\n";
        Assert.Equal(source, Lay(source));
    }

    [Fact]
    public void StyleGenericsAndUnits() => Assert.Equal(
        "void fill(List<Sku> skus) {\n    let wait = 30s\n}\n",
        Lay("void fill(List< Sku > skus) {\n    let wait = 30s\n}\n"));

    [Fact]
    public void AGapBetweenTwoGenericClosersIsKept() => Assert.Equal(
        "Map<string, List<i32> > m = make()\nList<List<i32>> n = make()\n",
        Lay("Map< string, List< i32 > > m = make()\nList<List< i32 >> n = make()\n"));

    [Fact]
    public void StyleAttributes() => Assert.Equal(
        "@derive(Json)\nstruct Note {\n    @json(name: \"note\") string text\n}\n",
        Lay("@derive(Json) struct Note {\n    @json(name: \"note\") string text\n}\n"));

    [Fact]
    public void AFieldAttributeStaysInline()
    {
        const string source = "struct Note {\n    @json(name: \"note\") string text\n}\n";
        Assert.Equal(source, Lay(source));
    }

    [Fact]
    public void EachFunctionAttributeTakesItsOwnLine() => Assert.Equal(
        "@allow(unusedValue) because \"warm\"\n@cases(1)\nvoid warm() {\n}\n",
        Lay("@allow(unusedValue) because \"warm\" @cases(1) void warm() {\n}\n"));

    [Fact]
    public void StyleBlocksAndBodies() => Assert.Equal(
        "public void promote(ref this, to Tier next) {\n    tier = next\n}\n",
        Lay("public void promote(ref this, to Tier next) { tier = next }\n"));

    [Fact]
    public void ABlockTakesOneStatementPerLineAndAnArrowBodyStays() => Assert.Equal(
        "bool ok() => true\n\nvoid main() {\n    if a {\n        b()\n    } else {\n        c()\n    }\n}\n",
        Lay("bool ok() => true\n\nvoid main() { if a { b() } else { c() } }\n"));

    [Fact]
    public void StyleMemberGroups() => Assert.Equal(
        "struct Cart {\n    List<Line> lines\n\n    public i32 count => lines.length\n\n" +
        "    public void add(ref this, Line line) {\n        lines.append(line)\n    }\n\n" +
        "    public void clear(ref this) {\n        lines = []\n    }\n}\n",
        Lay("struct Cart {\n    List<Line> lines\n    public i32 count => lines.length\n" +
            "    public void add(ref this, Line line) {\n        lines.append(line)\n    }\n" +
            "    public void clear(ref this) {\n        lines = []\n    }\n}\n"));

    [Fact]
    public void AFunctionBodyGetsNoBlankLine()
    {
        const string source = "struct Cart {\n    public void add(ref this, Line line) {\n        let n = 1\n        print(n)\n" +
                              "        lines.append(line)\n    }\n}\n\nvoid main() {\n    let a = 1\n    print(a)\n}\n";
        Assert.Equal(source, Lay(source));
    }

    // ── The T6c rules (docs/specs/022-style-guide/022-tasks.md), from the self-hosted compiler ──

    [Fact]
    public void AnExpressionBreaksBeforeItsLowestOperators() => Assert.Equal(
        "bool hidden(i64 c) {\n    return c < 0x20\n        || (c >= 0x7F && c <= 0x9F)\n        || c == 0x61C\n" +
        "        || (c >= 0x202A && c <= 0x202E)\n}\n",
        Lay("bool hidden(i64 c) {\n    return c < 0x20 || (c >= 0x7F && c <= 0x9F) || c == 0x61C || (c >= 0x202A && c <= 0x202E)\n}\n",
            new LayoutOptions(Width: 60)));

    [Fact]
    public void AnOperatorBreaksBeforeAnArgumentList() => Assert.Equal(
        "let ok = ready\n    && check(firstArgument, secondArgument)\n    && done\n",
        Lay("let ok = ready && check(firstArgument, secondArgument) && done\n", new LayoutOptions(Width: 44)));

    [Fact]
    public void AGroupThatDoesNotFitBreaksInside() => Assert.Equal(
        "let inInstance = host != -1\n    && !c.fns[host].isStatic\n    && (c.fns[host].kind == .method\n" +
        "        || c.fns[host].kind == .getter)\n",
        Lay("let inInstance = host != -1 && !c.fns[host].isStatic && (c.fns[host].kind == .method || c.fns[host].kind == .getter)\n",
            new LayoutOptions(Width: 50)));

    [Fact]
    public void AnIndexAndAMemberAfterItStayWhole() => Assert.Equal(
        "let empty = c.variants[i].payload.length == 0\n    && c.errors[c.variants[i].variant].fields.length > 0\n",
        Lay("let empty = c.variants[i].payload.length == 0 && c.errors[c.variants[i].variant].fields.length > 0\n",
            new LayoutOptions(Width: 50)));

    // driver/mutate.byn:728 at width 100: `(move parsed).member` does not open, as `xs[i].member` does not.
    [Fact]
    public void AGroupAroundAnOperandBeforeAMemberStaysWhole()
    {
        const string source = "void f() {\n    let root = (move parsed).trustUnchecked() because \"a site map only names sites; each field is checked below\"\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 100)));
    }

    // The author's break after a group's `(` goes: the group breaks before its own operators.
    [Fact]
    public void AnAuthorsGroupBreakGivesWayToItsOperators() => Assert.Equal(
        "let inInstance = host != -1\n    && !c.fns[host].isStatic\n    && (c.fns[host].kind == .method\n        || c.fns[host].kind == .getter)\n",
        Lay("let inInstance = host != -1 && !c.fns[host].isStatic && (\n    c.fns[host].kind == .method || c.fns[host].kind == .getter)\n",
            new LayoutOptions(Width: 50)));

    // The author's broken chain in a ternary joins, and the ternary breaks first.
    [Fact]
    public void AnAuthorsChainInATernaryJoinsForTheLadder() => Assert.Equal(
        "shown.append(\n    compiled.manifest is not null\n        ? Path.relative(compiled.root, to: output).replaced(\"\\\\\", by: \"/\")\n" +
        "        : output,\n)\n",
        Lay("shown.append(\n    compiled.manifest is not null ? Path\n        .relative(compiled.root, to: output)\n        .replaced(\"\\\\\", by: \"/\") : output,\n)\n",
            new LayoutOptions(Width: 80)));

    // The author's wrapped parameters join when the header fits once the `=>` body moves to the next line.
    [Fact]
    public void AnAuthorsWrappedParametersJoinBeforeTheArrowBreaks() => Assert.Equal(
        "i64 total(i64 firstArgument, i64 secondArgument) =>\n    firstArgument + secondArgument\n",
        Lay("i64 total(\n    i64 firstArgument,\n    i64 secondArgument\n) => firstArgument + secondArgument\n", new LayoutOptions(Width: 60)));

    [Fact]
    public void ATernaryInAnArgumentBreaksBeforeQuestionAndColon() => Assert.Equal(
        "shown.append(\n    compiled.manifest is not null\n        ? Path.relative(compiled.root, to: output).replaced(\"\\\\\", by: \"/\")\n" +
        "        : output,\n)\n",
        Lay("shown.append(compiled.manifest is not null ? Path.relative(compiled.root, to: output).replaced(\"\\\\\", by: \"/\") : output)\n",
            new LayoutOptions(Width: 80)));

    [Fact]
    public void AnOutlierLeavesTheRun() => Assert.Equal(
        "bool literal(TokenKind kind) => kind switch {\n    .integerLiteral => true,\n    .floatLiteral   => true,\n" +
        "    .stringLiteral or .rawStringLiteral or .cStringLiteral => true,\n    _               => false,\n}\n",
        Lay("bool literal(TokenKind kind) => kind switch {\n    .integerLiteral => true,\n    .floatLiteral => true,\n" +
            "    .stringLiteral or .rawStringLiteral or .cStringLiteral => true,\n    _ => false,\n}\n"));

    [Fact]
    public void FieldDefaultsAlignTheirEquals() => Assert.Equal(
        "struct DistSource {\n    string? commit = null\n    bool    dirty  = false\n    i64     count\n}\n",
        Lay("struct DistSource {\n    string? commit = null\n    bool dirty = false\n    i64 count\n}\n"));

    [Fact]
    public void AnArrowHeaderBreaksAfterTheArrowFirst() => Assert.Equal(
        "i64 total(i64 firstArgument, i64 secondArgument) =>\n    firstArgument + secondArgument\n",
        Lay("i64 total(i64 firstArgument, i64 secondArgument) => firstArgument + secondArgument\n", new LayoutOptions(Width: 60)));

    [Fact]
    public void AScalarListKeepsTheAuthorsFirstRow() => Assert.Equal(
        "const t: u32[8] = [\n    0x0041, 0x005A, 0x005F, 0x005F,\n    0x0061, 0x007A, 0x00AA, 0x00AA,\n]\n",
        Lay("const t: u32[8] = [\n    0x0041, 0x005A, 0x005F, 0x005F,\n    0x0061, 0x007A,\n    0x00AA, 0x00AA,\n]\n"));

    [Fact]
    public void AScalarListFillsToTheWidth() => Assert.Equal(
        "const t: u32[8] = [\n    0x0041, 0x005A, 0x005F,\n    0x005F, 0x0061, 0x007A,\n    0x00AA, 0x00AA,\n]\n",
        Lay("const t: u32[8] = [0x0041, 0x005A, 0x005F, 0x005F, 0x0061, 0x007A, 0x00AA, 0x00AA]\n", new LayoutOptions(Width: 30)));

    [Fact]
    public void ACaseBodyGoesOneLevelIn() => Assert.Equal(
        "void f() {\n    switch kind {\n        case .binary:\n            let op = c.op\n            go(op)\n" +
        "        default: {}\n    }\n}\n",
        Lay("void f() {\n    switch kind {\n        case .binary:\n        let op = c.op\n        go(op)\n" +
            "        default: {}\n    }\n}\n"));

    [Fact]
    public void AnEmptyArmStaysOnItsLine() => Assert.Equal(
        "void f() {\n    switch kind {\n        case .a: go()\n        default: {}\n    }\n}\n",
        Lay("void f() {\n    switch kind {\n        case .a: go()\n        default:\n            {}\n    }\n}\n"));

    [Fact]
    public void ADocCommentDoesNotEndARun() => Assert.Equal(
        "struct CCtx {\n    /// `OwnershipChecks`.\n    public bool   checks = false\n    /// `_packageRoot`.\n" +
        "    public string root   = \"\"\n    // ── T2 state\n    public i64    n      = 0\n    public string longer = \"\"\n}\n",
        Lay("struct CCtx {\n    /// `OwnershipChecks`.\n    public bool checks = false\n    /// `_packageRoot`.\n" +
            "    public string root = \"\"\n    // ── T2 state\n    public i64 n = 0\n    public string longer = \"\"\n}\n"));

    // A ternary at statement level cannot break, so its chain stays whole and the argument list breaks.
    [Fact]
    public void AChainInATernaryWaitsForTheTernary() => Assert.Equal(
        "void f() {\n    let shown = ready ? Path.relative(\n        root,\n        to: output,\n    ).replaced(\"a\", by: \"/\") : output\n}\n",
        Lay("void f() {\n    let shown = ready ? Path.relative(root, to: output).replaced(\"a\", by: \"/\") : output\n}\n",
            new LayoutOptions(Width: 60)));

    // binder2.byn:305 at width 120 (indent 36): the head group breaks at its own `||`, and never opens as a list. A line
    // after its `)` would read `(…)` as the whole condition (BYN1017), so `&&` stays on the `)` line.
    [Fact]
    public void AControlHeadGroupBreaksAtItsOwnOperators() => Assert.Equal(
        "void f() {\n    if (member == \"handler\"\n            || member == \"onPanic\") && t15Lookup(ref b, for: \"Panic\") == -1 {\n" +
        "        return bindOnPanic(ref b, through: ref c, for: in a.value)\n    }\n}\n",
        Lay("void f() {\n    if (member == \"handler\" || member == \"onPanic\") && t15Lookup(ref b, for: \"Panic\") == -1 {\n" +
            "        return bindOnPanic(ref b, through: ref c, for: in a.value)\n    }\n}\n",
            new LayoutOptions(Width: 88)));

    // lower.byn:692 at width 100 (indent 8): the top-level `&&` that may break goes first, then the group's `||`.
    [Fact]
    public void AControlHeadGroupBreaksAfterTheTopLevelOperators() => Assert.Equal(
        "void f() {\n    if (i < barrier && !isTrivial(in c, through: in l, for: values[i])\n            || movedFirst[i]) && !lvalue\n" +
        "            && !isVoidExpr(values[i]) {\n        values[i] = spill(ref c, through: ref l, for: values[i])\n    }\n}\n",
        Lay("void f() {\n    if (i < barrier && !isTrivial(in c, through: in l, for: values[i]) || movedFirst[i]) && !lvalue && !isVoidExpr(values[i]) {\n" +
            "        values[i] = spill(ref c, through: ref l, for: values[i])\n    }\n}\n",
            new LayoutOptions(Width: 96)));

    // cprint/expr.byn:191 at width 100 (indent 16): a head group with no operator to break opens the call inside it.
    [Fact]
    public void AControlHeadGroupOpensTheCallInside() => Assert.Equal(
        "void f() {\n    if (checkedStore(\n        ref cc,\n        for: ref f,\n        from: ref c,\n        through: t,\n" +
        "        at: t.assignExprs[i].target,\n        to: t.assignExprs[i].value,\n        claim: false,\n    ) is { } stored) {\n" +
        "        return stored\n    }\n}\n",
        Lay("void f() {\n    if (checkedStore(ref cc, for: ref f, from: ref c, through: t, at: t.assignExprs[i].target, to: t.assignExprs[i].value, claim: false) is { } stored) {\n" +
            "        return stored\n    }\n}\n",
            new LayoutOptions(Width: 88)));

    // With nothing else to break, the head's `(` still does not open.
    [Fact]
    public void AControlHeadGroupDoesNotOpen()
    {
        const string source = "void f() {\n    if (originalValueNumberOne == originalValueNumberTwo) is true {\n        return 1\n    }\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 40)));
    }

    [Fact]
    public void AnOperatorInsideAnIndexDoesNotBreak()
    {
        const string source = "let v = table[\n    firstKeyNameValue ?? secondKeyNameValue ?? thirdKeyNameValue\n].value\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 40)));
    }

    [Fact]
    public void AChainAfterAnIndexKeepsItsFirstMember() => Assert.Equal(
        "let w = rows[i].first()\n    .second(alphaValue)\n    .third(betaValue)\n    .fourth()\n",
        Lay("let w = rows[i].first().second(alphaValue).third(betaValue).fourth()\n", new LayoutOptions(Width: 40)));

    // The ternary's line ends the scan: the next label's `:` takes no space.
    [Fact]
    public void ACaseLabelAfterATernaryKeepsItsColonTight()
    {
        const string source = "void f() {\n    switch kind {\n        case .binary:\n            let op = ready ? c.op : d.op\n" +
            "        case .unary:\n            go(op)\n        default: {}\n    }\n}\n";
        Assert.Equal(source, Lay(source));
    }

    // The parameters cannot join again around the struct literal, so the `=>` must break first.
    [Fact]
    public void AnArrowHeaderBreaksAfterTheArrowBeforeAStructDefault() => Assert.Equal(
        "Point moved(Point p, Point by = Point { x: 0, y: 0 }) =>\n    p.plus(by)\n",
        Lay("Point moved(Point p, Point by = Point { x: 0, y: 0 }) => p.plus(by)\n", new LayoutOptions(Width: 60)));

    [Fact]
    public void ATernaryColonAfterABrokenChainKeepsItsSpace()
    {
        const string source = "void f() {\n    let shown = ready ? Path\n        .relative(root, to: output)\n        .replaced(\"a\", by: \"/\") : output\n}\n";
        Assert.Equal(source, Lay(source, new LayoutOptions(Width: 60)));
    }

    [Fact]
    public void TopLevelConstsAlignTheirEquals() => Assert.Equal(
        "const distMaxFiles: i64 = 20000\nconst distMaxDirs: i64  = 4000\nconst distMaxDepth: i64 = 64\n",
        Lay("const distMaxFiles: i64 = 20000\nconst distMaxDirs: i64 = 4000\nconst distMaxDepth: i64 = 64\n"));

    // ── Idempotence, @unformatted ──

    private const string Messy =
        "struct Order{i64 total\n  str  name}\r\n" +
        "public Money quote(Cart cart)\n expects cart.total>0\n uses db {\n\n" +
        "let x=[1,2 ,3]   // three\n" +
        "  if x.length>0\n  and ok {\n print(x[0])\n}\n\n\n" +
        "    // done\n}\n";

    [Fact]
    public void LayoutIsIdempotent()
    {
        var once = Lay(Messy);
        Assert.NotEqual(Messy, once);
        Assert.Equal(once, Lay(once));
    }

    private const string UnformattedTable = "@unformatted because \"a table\"\nvoid t() {  \r\n  let grid = [\n  1,   0,\t\n  0,   1,\n  ]\n}\n";

    private const string UnformattedInput = UnformattedTable + "void f() {\nlet a=1\n}\n";

    [Fact]
    public void AnUnformattedDeclarationKeepsItsBytes() =>
        Assert.Equal(UnformattedTable + "\nvoid f() {\n    let a = 1\n}\n", Lay(UnformattedInput));

    /// <summary>
    /// The cases that format <c>main.byn</c> beside a <c>package.byn</c> of their own, by case name, with both texts;
    /// <c>SelfhostDriverStage2FormatTests.ManifestInputsFormatAsCliApp</c> replays each through stage 2.
    /// </summary>
    public static IEnumerable<(string Name, string Source, string Package)> ManifestInputs() =>
    [
        (nameof(TheManifestsAlignNoneReachesLayout), AlignNoneInput, AlignNonePackage),
        (nameof(TheManifestsIndentWidthAndCommasReachLayout), KnobsInput, KnobsPackage),
    ];

    /// <summary>
    /// The inputs these cases build from a literal and a named constant, by case name, with the <c>Style</c> fields their options
    /// need. <c>SelfhostDriverStage2FormatTests.ComposedInputsFormatAsCliApp</c> formats each whole through stage 2.
    /// </summary>
    public static IEnumerable<(string Name, string Source, string Style)> ComposedInputs() =>
    [
        (nameof(Proposal31ParagraphsWrapTheHeaderClausesAndAddNoBlankLines), Proposal31Before, $"width: {Proposal31Width}"),
        (nameof(AnUnformattedDeclarationKeepsItsBytes), UnformattedInput, ""),
    ];

    [Fact]
    public void AnUnformattedMemberKeepsItsBytes()
    {
        const string source = "struct S {\n    @unformatted because \"columns\"\n    i32 f() {\n      return   1\n    }\n  i32 g() {\nreturn   2\n}\n}\n";
        Assert.Equal(
            "struct S {\n    @unformatted because \"columns\"\n    i32 f() {\n      return   1\n    }\n\n    i32 g() {\n        return 2\n    }\n}\n",
            Lay(source));
    }

    // ── Gaps the parser reads, knobs, tabs (review fixes of the T4 land) ──

    [Fact]
    public void AnUnlikelyHintKeepsItsSpace()
    {
        const string source = "void main() {\n    if unlikely (a).length > 0 {\n        print(1)\n    }\n}\n";
        Assert.Equal(source, Lay(source));
    }

    [Fact]
    public void GapsTheParserReadsAreKeptAsWritten()
    {
        const string source = "let s = x >> 2\nlet d = 30s\nlet p = u8* b\nlet q = a * b\n";
        Assert.Equal(source, Lay(source));
    }

    private const string KnobsInput = "void main() {\n    let t = g(argumentNumberOne, argumentNumberTwo)\n    let s = f(\n        a,\n        b,\n    )\n}\n";
    private const string KnobsPackage =
        "Package { name: \"local/t\", version: \"0.1.0\", style: Style { indent: 2, width: 30, trailingCommas: .never } }\n";

    [Fact]
    public void TheManifestsIndentWidthAndCommasReachLayout()
    {
        var file = Fresh("knobs", KnobsInput);
        File.WriteAllText(Path.Combine(Path.GetDirectoryName(file)!, "package.byn"), KnobsPackage);
        var (exit, _, stderr) = Run("format", file);
        Assert.Equal(CliApp.ExitOk, exit);
        Assert.DoesNotContain("skipped", stderr);
        Assert.Equal("void main() {\n  let t = g(\n    argumentNumberOne,\n    argumentNumberTwo\n  )\n  let s = f(a, b)\n}\n",
            File.ReadAllText(file));
    }

    [Fact]
    public void ATabIndentedRequiresLineCountsATabAsALevel() => Assert.Equal(
        "struct S {\n    i32 x\n        requires x > 0\n}\n",
        Lay("struct S {\n    i32 x\n\t\trequires x > 0\n}\n"));

    // ── Safety net ──

    [Fact]
    public void ABlockCommentIsSkipped()
    {
        var source = "let a = 1 /* b */\n"u8.ToArray();
        var (output, skipped) = Layout.Apply(source, new LayoutOptions());
        Assert.NotNull(skipped);
        Assert.Equal(source, output);
    }

    /// <summary>
    /// No stage-2 row replays this case: it injects its fault through <c>Layout.OutputHook</c>, a C#-only seam no CLI run can reach.
    /// </summary>
    [Theory]
    [InlineData("tokens", "let a = 1\nlet b = 2\n", "let a = 1\nlet b = 3\n", "the tokens changed")]
    [InlineData("diagnostics", "let a = 1\nlet b = 2\n", "let a = 1 let b = 2\n", "the diagnostics changed")]
    [InlineData("comments", "let a = 1 // one\n", "let a = 1 // two\n", "the comments changed")]
    [InlineData("adjacency", "let a = 1\nlet b = x >> 2\n", "let a = 1\nlet b = x > > 2\n", "the spacing the parser reads changed")]
    public void ADifferenceKeepsTheInput(string name, string source, string broken, string reason)
    {
        Layout.OutputHook = _ => Encoding.UTF8.GetBytes(broken);
        try
        {
            var bytes = Encoding.UTF8.GetBytes(source.Replace("=", "  =  "));
            var (output, skipped) = Layout.Apply(bytes, new LayoutOptions());
            Assert.Equal(reason, skipped);
            Assert.Equal(bytes, output);

            var file = Fresh(name, source.Replace("=", "  =  "));
            var (exit, _, stderr) = Run("format", file);
            Assert.Equal(CliApp.ExitOk, exit);
            Assert.Contains($"bayan format: layout skipped for {file}: {reason}", stderr);
            Assert.Equal(source.Replace("=", "  =  "), File.ReadAllText(file));
        }
        finally { Layout.OutputHook = null; }
    }

    // ── Corpus ──

    /// <summary>The roots <see cref="Corpus"/> walks; <c>SelfhostDriverStage2FormatTests.CorpusFormatsAsCliApp</c> copies the same.</summary>
    public static readonly string[] CorpusRoots = [Golden.CasesRoot, Path.Combine(Golden.RepoRoot, "src"), Path.Combine(Golden.RepoRoot, "lib")];

    /// <summary>The file filter <see cref="Corpus"/> walks each of <see cref="CorpusRoots"/> with.</summary>
    public const string CorpusPattern = "*.byn";

    public static IEnumerable<object[]> Corpus() =>
        CorpusRoots
            .SelectMany(root => Directory.EnumerateFiles(root, CorpusPattern, SearchOption.AllDirectories))
            .Order(StringComparer.Ordinal)
            .Select(f => new object[] { Path.GetRelativePath(Golden.RepoRoot, f) });

    [Theory]
    [MemberData(nameof(Corpus))]
    public void TheCorpusLaysOutOnceAndForAll(string file)
    {
        var source = File.ReadAllBytes(Path.Combine(Golden.RepoRoot, file));
        var stderr = new StringWriter();
        var once = Format.FormatFile(file, source, BooleanStyle.Symbols, PrimitiveStyle.Sized, new HashSet<string>(), stderr, out _);
        // A file with an error the formatter cannot fix is reported and left alone, as on disk.
        var twice = once is null ? null : Format.FormatFile(file, once, BooleanStyle.Symbols, PrimitiveStyle.Sized, new HashSet<string>(), stderr, out _);
        Assert.DoesNotContain("layout skipped", stderr.ToString());
        Assert.DoesNotContain("still changing", stderr.ToString());
        // Layout keeps every token but trailing commas, whatever its safety net says (R4); newlines are not tokens.
        var (laidOut, _) = Layout.Apply(source, new LayoutOptions());
        Assert.Equal(Tokens(source), Tokens(laidOut));
        if (once is null) return;
        Assert.NotNull(twice);
        Assert.Equal(Encoding.UTF8.GetString(once), Encoding.UTF8.GetString(twice));
    }

    /// <summary>The tokens as kind and text, less each trailing comma (a <c>,</c> before <c>)</c>, <c>]</c> or <c>}</c>).</summary>
    private static List<(TokenKind, string)> Tokens(byte[] bytes)
    {
        var tokens = Lexer.Lex(new SourceText("corpus", bytes)).Tokens.ToArray();
        return [.. tokens
            .Where((t, i) => !(t.Kind == TokenKind.Comma && i + 1 < tokens.Length
                               && tokens[i + 1].Kind is TokenKind.CloseParen or TokenKind.CloseBracket or TokenKind.CloseBrace))
            .Select(t => (t.Kind, Encoding.UTF8.GetString(bytes, t.Start, t.Length)))];
    }
}
