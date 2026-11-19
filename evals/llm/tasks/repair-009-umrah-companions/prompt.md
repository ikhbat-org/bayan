This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program seats an umrah group on a bus. Each line of standard input is `<pilgrim>` or `<pilgrim> <companion>`, separated by one space. Spaces around a line are ignored. A blank line, a line with more than two fields, and a line whose pilgrim already signed up on an earlier line are skipped (with the companion it names). The seats go first to the pilgrims, in the order of their lines, then to the companions who did not sign up as pilgrims themselves, in the order of the pilgrims who bring them. A person gets one seat, however many pilgrims name them. The program prints one line per seat, `<seat>. <name>`, with seats counted from 1.

```
/// One line of the sign-up sheet.
struct Pilgrim {
    string name
    /// The companion the pilgrim brings, or "" for none.
    string companion
}

/// Whether `name` is in `names`.
bool has(List<string> names, for string name) {
    for n in names {
        return true if n == name
    }
    return false
}

/// The companion `name` signed up with, or "" for none.
string companionOf(List<Pilgrim> pilgrims, for string name) {
    for p in pilgrims {
        return p.companion if p.name == name
    }
    return ""
}

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    var pilgrims = List<Pilgrim>()
    var group = List<string>()
    for line in read.value.lines {
        let text = line.trimmed()
        continue if text.isEmpty
        var fields = List<string>()
        for part in text.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length > 2 || has(group, for: fields[0])
        let companion = fields.length == 2 ? fields[1] : ""
        pilgrims.append(Pilgrim { name: fields[0], companion: companion })
        group.append(fields[0])
    }
    for name in group {
        let companion = companionOf(pilgrims, for: name)
        continue if companion.isEmpty || has(group, for: companion)
        group.append(companion)
    }
    var seat: i64 = 0
    for name in group {
        seat += 1
        print($"{seat}. {name}")
    }
}
```

The compiler reports:

```
error BYN3004: `group` is modified while the `for` loop still borrows it
  --> solution.byn:47:9

  47 │         group.append(companion)
     │         ^^^^^^^^^^^^^^^^^^^^^^^ the loop over `group` is still running
     │
  help: collect the changes in another list and apply them to `group` after the loop

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN3004
```

Example input:

```
Sumayya Ammar
Suhayb
Ammar
```

Expected output of the fixed program on that input:

```
1. Sumayya
2. Suhayb
3. Ammar
```
