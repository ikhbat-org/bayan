This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program reads iftar tables from standard input, one per line: `<host> <dates> <guests> <each>`, separated by single spaces, the last three whole numbers. Every line has this form. For each line it prints `<host>: <left> dates left, enough: <true or false>`, where `<left>` is the dates left after every guest takes `<each>` (it may be negative) and `enough` is whether `<left>` is at least 0.

```
/// Dates left after every guest takes `each`.
i64 remaining(i64 dates, for i64 guests, by i64 each) => dates - guests * each

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    for line in read.value.lines {
        var fields = List<string>()
        for part in line.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length != 4
        let dates = i64.tryParse(fields[1]) ?? 0
        let guests = i64.tryParse(fields[2]) ?? 0
        let each = i64.tryParse(fields[3]) ?? 0
        let left = remaining(dates, guests, each)
        print($"{fields[0]}: {left} dates left, enough: {left >= 0}")
    }
}
```

The compiler reports:

```
error BYN5005: `guests` is passed without its particle `for:`
  --> solution.byn:19:37

  19 │         let left = remaining(dates, guests, each)
     │                                     ^^^^^^ needs `for:`
     │
  help: add `for:` before the argument
     │ 19 │         let left = remaining(dates, for: guests, each)
     │    │                                     +++++

error BYN5005: `each` is passed without its particle `by:`
  --> solution.byn:19:45

  19 │         let left = remaining(dates, guests, each)
     │                                             ^^^^ needs `by:`
     │
  help: add `by:` before the argument
     │ 19 │         let left = remaining(dates, guests, by: each)
     │    │                                             ++++

✗ build failed: 2 errors, 0 warnings
  explain: bayan explain BYN5005
```

Example input:

```
Hamza 30 4 5
Zaynab 10 4 3
```

Expected output of the fixed program on that input:

```
Hamza: 10 dates left, enough: true
Zaynab: -2 dates left, enough: false
```
