This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program seats iftar tables in a hall. The first line of standard input is the number of chairs in the hall. Each later line is `<host> <guests>`, separated by one space: a table for `<host>` with `<guests>` guests. Blank lines are skipped, and so is a line that does not have two fields or whose guests are not a whole number of 1 or more. A table needs the next even number of chairs at or above its guests. It is seated when that many chairs are free, and the program prints `<host>: <chairs> chairs`; otherwise it prints `<host>: turned away`. After the last line it prints `tables: <seated tables>, guests: <guests at the seated tables>, free chairs: <chairs left>`. A new hall has no tables and no chair used.

```
/// One table at the iftar.
struct Table {
    string host
    i64    guests
    i64    chairs
}

/// The hall and what is seated in it.
struct Hall {
    List<Table> tables
    i64         capacity
    i64         used
}

/// What the hall holds at the end.
struct Summary {
    i64 tables
    i64 guests
    i64 free
}

/// Chairs for `guests`: the next even number.
i64 chairsFor(i64 guests) => guests % 2 == 0 ? guests : guests + 1

/// A table for `host` with room for `guests`.
Table tableFor(string host, for i64 guests) {
    return Table { host: host, guests: guests }
}

/// An empty hall with `capacity` chairs.
Hall emptyHall(i64 capacity) {
    return Hall { capacity: capacity }
}

/// Seats `table` if the chairs left allow it. Returns whether it did.
bool seat(ref Hall hall, for Table table) {
    return false if hall.used + table.chairs > hall.capacity
    hall.tables.append(table)
    hall.used += table.chairs
    return true
}

/// Counts what `hall` holds.
Summary countHall(Hall hall) {
    var guests: i64 = 0
    for table in hall.tables {
        guests += table.guests
    }
    return Summary { tables: hall.tables.length, guests: guests }
}

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    var hall = emptyHall(0)
    var first = true
    for line in read.value.lines {
        let text = line.trimmed()
        continue if text.isEmpty
        if first {
            hall = emptyHall(i64.tryParse(text) ?? 0)
            first = false
            continue
        }
        var fields = List<string>()
        for part in text.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length != 2
        let guests = i64.tryParse(fields[1]) ?? 0
        continue if guests < 1
        let table = tableFor(fields[0], for: guests)
        if seat(ref hall, for: table) {
            print($"{table.host}: {table.chairs} chairs")
        } else {
            print($"{table.host}: turned away")
        }
    }
    let summary = countHall(hall)
    print($"tables: {summary.tables}, guests: {summary.guests}, free chairs: {summary.free}")
}
```

The compiler reports:

```
error BYN2109: `Table` needs a value for `chairs`
  --> solution.byn:27:12

  27 │     return Table { host: host, guests: guests }
     │            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     │
  help: set it: `Table { chairs: … }`

error BYN2109: `Hall` needs a value for `tables`, `used`
  --> solution.byn:32:12

  32 │     return Hall { capacity: capacity }
     │            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
     │
  help: set them: `Hall { tables: …, used: … }`

error BYN2109: `Summary` needs a value for `free`
  --> solution.byn:49:12

  49 │     return Summary { tables: hall.tables.length, guests: guests }
     │            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     │
  help: set it: `Summary { free: … }`

✗ build failed: 3 errors, 0 warnings
  explain: bayan explain BYN2109
```

Example input:

```
10
Hamza 5
Khadija 3
Idris 2
```

Expected output of the fixed program on that input:

```
Hamza: 6 chairs
Khadija: 4 chairs
Idris: turned away
tables: 2, guests: 8, free chairs: 0
```
