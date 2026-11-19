This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The masjid has shoe cubbies numbered 0 to 255, sixteen to a rack: cubbies 0 to 15 are on rack 1, shelves 1 to 16, cubbies 16 to 31 on rack 2, and so on. The program reads standard input, one line per worshipper: `<name> <cubby>`, separated by one space. Spaces around a line are ignored, and a blank line or a line that does not have two fields is skipped. For a cubby that is a whole number from 0 to 255 it prints `<name>: rack <rack>, shelf <shelf>`. For any other cubby (a negative number, a number above 255, or not a number) it prints `<name>: no such cubby` and goes on with the next line.

```
/// Where shoe cubby `cubby` is: rack, then shelf.
string placeOf(u8 cubby) => $"rack {cubby / 16 + 1}, shelf {cubby % 16 + 1}"

void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    for line in read.value.lines {
        let text = line.trimmed()
        continue if text.isEmpty
        var fields = List<string>()
        for part in text.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length != 2
        let number = i64.tryParse(fields[1]) ?? -1
        let cubby: u8? = number
        if cubby is null {
            print($"{fields[0]}: no such cubby")
            continue
        }
        print($"{fields[0]}: {placeOf(cubby)}")
    }
}
```

The compiler reports:

```
error BYN2202: expected `u8?`, found `i64`
  --> solution.byn:19:26

  19 │         let cubby: u8? = number
     │                          ^^^^^^

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN2202
```

Example input:

```
Sumayya 20
Ammar 300
```

Expected output of the fixed program on that input:

```
Sumayya: rack 2, shelf 5
Ammar: no such cubby
```
