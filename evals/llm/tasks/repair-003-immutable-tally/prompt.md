This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

The program reads from standard input, one reader per line: `<name> <pages>`, separated by one space, the second a whole number of pages. A blank line, or a line that does not have exactly two fields, is skipped. It prints `readers: <n>`, the number of lines it counted, then `pages: <sum>`, the sum of their pages.

```
void main() {
    let read = Io.stdin.readAll()
    if !read.isOk {
        print("cannot read input", to: .stderr)
        return
    }
    let readers = 0
    let pages: i64 = 0
    for line in read.value.lines {
        var fields = List<string>()
        for part in line.parts(by: " ") {
            fields.append(part)
        }
        continue if fields.length != 2
        readers += 1
        pages += i64.tryParse(fields[1]) ?? 0
    }
    print($"readers: {readers}")
    print($"pages: {pages}")
}
```

The compiler reports:

```
error BYN2104: `readers` is immutable
  --> solution.byn:15:9

  15 │         readers += 1
     │         ^^^^^^^ declared with `let` on line 7
     │
  help: declare it with `var` if it should change
     │  7 │     var readers = 0
     │    │     +++

error BYN2104: `pages` is immutable
  --> solution.byn:16:9

  16 │         pages += i64.tryParse(fields[1]) ?? 0
     │         ^^^^^ declared with `let` on line 8
     │
  help: declare it with `var` if it should change
     │  8 │     var pages: i64 = 0
     │    │     +++

✗ build failed: 2 errors, 0 warnings
  explain: bayan explain BYN2104
```

Example input:

```
Hamza 10
Khadija 25
```

Expected output of the fixed program on that input:

```
readers: 2
pages: 35
```
