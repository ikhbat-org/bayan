This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program reads from standard input, one word per line. Spaces around a word are ignored and blank lines are skipped. A word that names one of the five daily prayers (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, in lowercase and spelt exactly so) prints `<word>: <rak'ahs>`, the number of rak'ahs in its obligatory part. Any other word prints `unknown: <word>`. After the last line it prints `total: <sum of the rak'ahs>`. The obligatory part has 2 rak'ahs for `fajr`, 4 for `dhuhr`, 4 for `asr`, 3 for `maghrib` and 4 for `isha`.

```
/// The five daily prayers.
enum Prayer {
    fajr
    dhuhr
    asr
    maghrib
    isha
}

/// The prayer a word names, if any.
Prayer? prayerNamed(string word) {
    return .fajr if word == "fajr"
    return .dhuhr if word == "dhuhr"
    return .asr if word == "asr"
    return .maghrib if word == "maghrib"
    return .isha if word == "isha"
    return null
}

/// How many rak'ahs the obligatory part of `prayer` has.
i64 rakats(Prayer prayer) {
    var count: i64 = 0
    switch prayer {
        case .fajr: count = 2
        case .dhuhr: count = 4
        case .asr: count = 4
        case .isha: count = 4
    }
    return count
}

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    var total: i64 = 0
    for line in read.value.lines {
        let word = line.trimmed()
        continue if word.isEmpty
        let prayer = prayerNamed(word)
        if prayer is null {
            print($"unknown: {word}")
            continue
        }
        let count = rakats(prayer)
        total += count
        print($"{word}: {count}")
    }
    print($"total: {total}")
}
```

The compiler reports:

```
error BYN2410: `switch` does not handle every `Prayer`
  --> solution.byn:23:12

  23 │     switch prayer {
     │            ^^^^^^ not covered: .maghrib
     │
  help: add the missing cases or a `default:` section

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN2410
```

Example input:

```
asr
fajr
Isha
maghrib
```

Expected output of the fixed program on that input:

```
asr: 4
fajr: 2
unknown: Isha
maghrib: 3
total: 9
```
