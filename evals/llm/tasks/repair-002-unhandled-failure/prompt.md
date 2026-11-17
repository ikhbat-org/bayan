This Bayān file does not compile. Fix it so that it compiles and prints the expected output below. Keep `Table` and `SeatError` as they are.

The program reads from standard input: the first line is the number of seats at the table, and each line after it is the name of a guest who arrives, in order. Spaces around a name are ignored and blank lines are skipped.

```
union error SeatError {
    /// Every seat at the table is taken.
    full
    /// The guest already has a seat.
    seated
}

struct Table {
    List<string> guests
    i64 seats

    void add(ref this, string guest) fails SeatError {
        fail .full if guests.length >= seats
        for g in guests {
            fail .seated if g == guest
        }
        guests.append(guest)
    }
}

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    var table = Table { guests: List<string>(), seats: 0 }
    var first = true
    for line in read.value.lines {
        let guest = line.trimmed()
        if first {
            table.seats = i64.tryParse(guest) ?? 0
            first = false
            continue
        }
        continue if guest.isEmpty
        table.add(guest)
        print($"{guest}: seated")
    }
    print($"{table.guests.length} of {table.seats} seats taken")
}
```

The compiler reports:

```
error BYN2602: `add` can fail; handle the error or pass it on
  --> solution.byn:37:9

  37 │         table.add(guest)
     │         ^^^^^^^^^^^^^^^^
     │
  help: propagate the error with `try`, or handle it with `catch`
     │ 37 │         try table.add(guest)
     │    │         ++++

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN2602
```

The loop must go on after a guest cannot be seated. For each guest it prints one line: `<guest>: seated`, `<guest>: already seated` or `<guest>: table full`. Once every seat is taken, each guest who arrives gets `table full`, even one already seated. After the guests it prints `<guests seated> of <seats> seats taken`.

Example input:

```
2
Aisha
Aisha
Idris
Khadija
```

Expected output of the fixed program on that input:

```
Aisha: seated
Aisha: already seated
Idris: seated
Khadija: table full
2 of 2 seats taken
```
