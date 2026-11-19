This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program shares out sadaqah coins into purses. It reads standard input, one line per giver: `<giver> <coins> <purses>`, separated by single spaces, the last two whole numbers. A line that does not have three fields is skipped. For each other line it prints `<giver>: <each> in each purse, <rest> left over`, where the coins are split evenly and `<rest>` is what cannot be split.

Fewer than 1 purse, or more purses than coins, is a mistake in the list, not a line to skip. The author made that rule the precondition of `perPurse`, and the program must not go on after such a line: it ends there with exit code 134, printing nothing for that line or after it.

```
/// Coins in each purse when `coins` are shared out evenly into `purses`.
i64 perPurse(i64 coins, by i64 purses)
        requires purses >= 1 && purses <= coins {
    return coins / purses
}

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
        continue if fields.length != 3
        let coins = i64.tryParse(fields[1]) ?? 0
        let purses = i64.tryParse(fields[2]) ?? 0
        let each = perPurse(coins, by: purses)
        print($"{fields[0]}: {each} in each purse, {coins - each * purses} left over")
    }
}
```

The compiler reports:

```
error BYN1063: `requires` on a function is an input form; write `expects`
  --> solution.byn:3:9

  3 │         requires purses >= 1 && purses <= coins {
    │         ^^^^^^^^ the input form
    │
  help: use `expects` for a precondition; `requires` is checked at construction
    │ 3 │         expects purses >= 1 && purses <= coins {
    │   │         ++++++

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN1063
```

Example input:

```
Sumayya 10 3
Ammar 4 4
Suhayb 2 0
Umar 6 2
```

Expected output of the fixed program on that input, ending with exit code 134:

```
Sumayya: 3 in each purse, 1 left over
Ammar: 1 in each purse, 0 left over
```
