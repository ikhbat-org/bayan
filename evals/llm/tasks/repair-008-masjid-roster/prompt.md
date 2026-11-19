This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program keeps the roster of volunteers who clean the masjid. Each non-blank line of standard input is one day's sign-up sheet: names separated by spaces (more than one space between names, or spaces around the line, are allowed). Blank lines are skipped and do not count as days. A name already on the roster is not added again; names are compared character for character, so case matters. For each day it prints `day <n>: new <names>; <count> on the roster`, where `<n>` counts the days from 1, `<names>` are the names that day added to the roster, in the order they were added and separated by one space, or `none` when it added no one, and `<count>` is the size of the roster after that day.

```
/// Whether `name` is in `names`.
bool has(List<string> names, for string name) {
    for n in names {
        return true if n == name
    }
    return false
}

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    var roster = List<string>()
    var day: i64 = 0
    for line in read.value.lines {
        let text = line.trimmed()
        continue if text.isEmpty
        day += 1
        let before = roster
        for name in text.parts(by: " ") {
            continue if name.isEmpty || has(roster, for: name)
            roster.append(name)
        }
        var fresh = ""
        for name in roster {
            continue if has(before, for: name)
            fresh = fresh.isEmpty ? name : $"{fresh} {name}"
        }
        fresh = "none" if fresh.isEmpty
        print($"day {day}: new {fresh}; {roster.length} on the roster")
    }
}
```

The compiler reports:

```
error BYN2780: implicit copy of a unique value: `List<string>` is unique: it owns its storage
  --> solution.byn:21:22

  21 │         let before = roster
     │                      ^^^^^^
     │
  help: hand the value over with `move roster`; make an independent copy with
        `roster.copy(to: alloc)`; pass it by `ref` to share it instead
     │ 21 │         let before = move roster
     │    │                      +++++

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN2780
```

Example input:

```
Sumayya Ammar
Ammar Suhayb
```

Expected output of the fixed program on that input:

```
day 1: new Sumayya Ammar; 2 on the roster
day 2: new Suhayb; 3 on the roster
```
