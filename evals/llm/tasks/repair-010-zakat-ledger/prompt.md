This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require. Keep every declaration that is `public` public.

The program works out zakat from a ledger on standard input. Spaces around a line are ignored and blank lines are skipped. The first non-blank line is the nisab, a whole number. Each later line is `<owner> <kind> <amount>`, separated by single spaces, where `<kind>` is `gold`, `silver`, `cash` or `debt` and `<amount>` is a whole number of 0 or more. A line with another number of fields, another kind, or an amount that is not such a number is skipped. An owner's net is the sum of their `gold`, `silver` and `cash` amounts minus the sum of their `debt` amounts. For each owner, in the order of their first counted line, the program prints `<owner>: below nisab` when the net is below the nisab, and otherwise `<owner>: zakat <due>`, where `<due>` is the net divided by 40, rounded down.

```
/// What an amount in the ledger counts as.
public enum Kind {
    gold
    silver
    cash
    debt
}

/// One owner's sums.
public struct Holding {
    string owner
    i64    wealth
    i64    debts
}

/// The zakat ledger: holdings in the order their owners first appear.
public struct Ledger {
    i64 nisab
    List<Holding> holdings
}

/// The kind a word names, if any.
public Kind? kindNamed(string word) {
    return .gold if word == "gold"
    return .silver if word == "silver"
    return .cash if word == "cash"
    return .debt if word == "debt"
    return null
}

/// An empty ledger with the nisab `nisab`.
public Ledger newLedger(i64 nisab) => Ledger { nisab: nisab, holdings: List<Holding>() }

/// Adds `amount` of `kind` to the holding of `owner`.
public void record(ref Ledger ledger, for string owner, as Kind kind, by i64 amount) {
    var at: i64 = -1
    for i in 0..ledger.holdings.length {
        at = i if ledger.holdings[i].owner == owner
    }
    if at < 0 {
        ledger.holdings.append(Holding { owner: owner, wealth: 0, debts: 0 })
        at = ledger.holdings.length - 1
    }
    switch kind {
        case .debt: ledger.holdings[at].debts += amount
        default: ledger.holdings[at].wealth += amount
    }
}

/// What `holding` is worth after its debts.
public i64 netOf(Holding holding) => holding.wealth - holding.debts

/// Reads the ledger from standard input, or null when it cannot be read.
public Ledger? readLedger() {
    let read = Io.stdin.readAll()
    return null if !read.isOk
    var ledger = newLedger(0)
    var first = true
    for line in read.value.lines {
        let text = line.trimmed()
        continue if text.isEmpty
        if first {
            ledger.nisab = i64.tryParse(text) ?? 0
            first = false
            continue
        }
        var fields = List<string>()
        for part in text.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length != 3
        let kind = kindNamed(fields[1])
        let amount = i64.tryParse(fields[2]) ?? -1
        continue if kind is null || amount < 0
        record(ref ledger, for: fields[0], as: kind, by: amount)
    }
    return ledger
}

/// Prints one line per owner.
public void report(Ledger ledger) {
    for holding in ledger.holdings {
        let net = netOf(holding)
        if net < ledger.nisab {
            print($"{holding.owner}: below nisab")
        } else {
            print($"{holding.owner}: zakat {net / 40}")
        }
    }
}

void main() {
    let ledger = readLedger()
    if ledger is null {
        print("cannot read input", to: .stderr)
        return
    }
    report(ledger)
}
```

The compiler reports:

```
error BYN6002: `newLedger` uses `alloc` but does not declare it
  --> solution.byn:32:72

  32 │ public Ledger newLedger(i64 nisab) => Ledger { nisab: nisab, holdings: List<Holding>() }
     │                                                                        ^^^^^^^^^^^^^^^ uses
     │                                                                                        `alloc`
     │
  help: add `alloc` to the `uses` clause, or remove the call
     │ 32 │ public Ledger newLedger(i64 nisab) uses alloc => Ledger { nisab: nisab, holdings: List<Holding>() }
     │    │                                   +++++++++++

error BYN6002: `record` uses `alloc` but does not declare it
  --> solution.byn:41:9

  41 │         ledger.holdings.append(Holding { owner: owner, wealth: 0, debts: 0 })
     │         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ uses `alloc`
     │
  help: add `alloc` to the `uses` clause, or remove the call
     │ 35 │ public void record(ref Ledger ledger, for string owner, as Kind kind, by i64 amount) uses alloc {
     │    │                                                                                     +++++++++++

error BYN6002: `readLedger` uses `console` but does not declare it
  --> solution.byn:55:16

  55 │     let read = Io.stdin.readAll()
     │                ^^^^^^^^^^^^^^^^^^ uses `console`
     │
  help: add `console` to the `uses` clause, or remove the call
     │ 54 │ public Ledger? readLedger() uses alloc, console {
     │    │                            ++++++++++++++++++++

error BYN6002: `readLedger` uses `alloc` but does not declare it
  --> solution.byn:55:16

  55 │     let read = Io.stdin.readAll()
     │                ^^^^^^^^^^^^^^^^^^ uses `alloc`
     │
  help: add `alloc` to the `uses` clause, or remove the call
     │ 54 │ public Ledger? readLedger() uses alloc, console {
     │    │                            ++++++++++++++++++++

error BYN6002: `report` uses `console` but does not declare it
  --> solution.byn:85:13

  85 │             print($"{holding.owner}: below nisab")
     │             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ uses `console`
     │
  help: add `console` to the `uses` clause, or remove the call
     │ 81 │ public void report(Ledger ledger) uses console {
     │    │                                  +++++++++++++

✗ build failed: 5 errors, 0 warnings
  explain: bayan explain BYN6002
```

Example input:

```
100
Sumayya gold 300
Ammar cash 150
Ammar debt 60
```

Expected output of the fixed program on that input:

```
Sumayya: zakat 7
Ammar: below nisab
```
