This Bayān file does not compile. Fix it so that it compiles and prints the expected output below. Keep `Table` and `SeatError` as they are.

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
    var table = Table { guests: List<string>(), seats: 3 }
    for guest in ["Aisha", "Bilal", "Aisha", "Maryam", "Yusuf"] {
        table.add(guest)
        print($"{guest}: seated")
    }
    print($"{table.guests.length} of {table.seats} seats taken")
}
```

The compiler reports:

```
error BYN2602: `add` can fail; handle the error or pass it on
  --> solution.byn:24:9

  24 │         table.add(guest)
     │         ^^^^^^^^^^^^^^^^
     │
  help: propagate the error with `try`, or handle it with `catch`
     │ 24 │         try table.add(guest)
     │    │         ++++

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN2602
```

The loop must go on after a guest cannot be seated. For each guest it prints one line: `<guest>: seated`, `<guest>: already seated` or `<guest>: table full`.

Expected output of the fixed program:

```
Aisha: seated
Bilal: seated
Aisha: already seated
Maryam: seated
Yusuf: table full
3 of 3 seats taken
```
