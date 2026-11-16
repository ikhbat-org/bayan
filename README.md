# Bayān

*Bayān (ASCII: Bayan). The CLI, package names, URLs and identifiers use `bayan`.*

Bayān (بيان, "clear statement") is a programming language that compiles to small native executables. There
is no runtime to install, no garbage collector and no exceptions. Values are copied by default, errors are
ordinary return values that the compiler makes you handle, and memory is managed by scopes and allocators
you can see in the code.

The compiler is written in Bayān itself. It turns your program into C, then hands that C to a C compiler
to produce the executable.

Bayān is young (version 0.3.0). The language is usable and the compiler builds itself, but expect rough
edges, and expect things to change between versions.

## Install

You need two things: the `bayan` binary and a C compiler.

1. **Get `bayan`.** Download the archive for your machine from the
   [releases page](https://github.com/ikhbat-org/bayan/releases): `bayan-0.3.0-macos-arm64.tar.gz`,
   `bayan-0.3.0-linux-x64.tar.gz`, `bayan-0.3.0-windows-x64.zip` and so on. Unpack it and put the
   `bayan` binary somewhere on your `PATH`:

   ```sh
   tar -xzf bayan-0.3.0-macos-arm64.tar.gz
   cp bayan-0.3.0-macos-arm64/bayan ~/.local/bin/
   ```

2. **Get a C compiler.** Bayān prefers [zig](https://ziglang.org) (`zig cc`), because it can build for
   other platforms too. If zig is not installed, it uses `cc`, `clang` or `gcc` from your `PATH`.

3. **Check your setup:**

   ```sh
   bayan doctor
   ```

   This lists the compiler, zig, git and the build cache that `bayan` found. If something is missing, it
   tells you how to fix it.

## Your first program

Create a project and run it:

```sh
bayan new greet
cd greet
bayan run
```

The program prints `Salam, world!`. `bayan new` created a few files; these are the ones that matter:

- `package.byn` describes the project: its name, version and dependencies.
- `src/app/main.byn` is the program.
- `tests/app.test.byn` is a test.

Open `src/app/main.byn`:

```
/// The line this app prints.
string greeting() {
    return "Salam, world!"
}

print(greeting())
```

Change the greeting to `"Salam, Aisha!"` and run `bayan run` again. To run the tests, use `bayan test`.
The test will now fail, because it still expects the old greeting. Change it to `"Salam, Aisha!"` too
and it passes.

For a one-off script you don't need a project. Write a single `.byn` file and run it with
`bayan run hello.byn`.

## A taste of the language

The examples below are small programs around a community iftar. Each one runs as it is with
`bayan run main.byn`.

### Errors are values

The iftar keeps its own count of seats, so a guest asks only for what they need. Booking can fail, and
the signature says so (`fails BookingError`). The caller has to handle each error; the compiler checks that
none is left out:

```
union error BookingError {
    /// Every seat is taken.
    full
    /// Fewer seats are left than were asked for.
    notEnough(i64 left)
}

struct Iftar {
    i64 seats
    i64 booked

    i64 left => seats - booked

    void reserve(ref this, i64 count) fails BookingError {
        fail .full if left == 0
        fail .notEnough(left) if count > left
        booked += count
    }

    string book(ref this, string guest, for i64 count) {
        reserve(count) catch switch {
            .full => return $"Sorry {guest}, the iftar is full",
            .notEnough(let left) => return $"Sorry {guest}, only {left} left",
        }
        return $"{guest} booked {count}, {left} left"
    }
}

void main() {
    var iftar = Iftar { seats: 6, booked: 0 }
    print(iftar.book("Umar", for: 2))
    print(iftar.book("Aisha", for: 3))
    print(iftar.book("Bilal", for: 4))
    print(iftar.book("Yusuf", for: 1))
    print(iftar.book("Maryam", for: 1))
}
```

```text
Umar booked 2, 4 left
Aisha booked 3, 1 left
Sorry Bilal, only 1 left
Yusuf booked 1, 0 left
Sorry Maryam, the iftar is full
```

An error can carry data: `notEnough(i64 left)` tells the guest how many seats remain. There are no
exceptions: `fail` returns the error to the caller, and a call that can fail is marked with `try` (pass the
error on) or `catch` (handle it here).

### Effects are part of the signature

A public function lists what it touches outside its own arguments: files (`fs`), memory (`alloc`), the
console, the network and so on. A public function with no `uses` clause only computes, so you can call
it anywhere and test it with plain values. Private functions, `main` and scripts work their effects out
from what they call, which is why `main` below needs no clause:

```
/// Counts the names in a guest list, one per line. No `uses` clause: it only computes.
public i64 countGuests(string list) {
    var count = 0
    for line in list.lines {
        count += 1 if !line.trimmed().isEmpty
    }
    return count
}

/// Reads the guest list from a file, so it declares `uses fs`.
public i64 guestsIn(string path) uses fs, alloc fails IoError {
    let list = try Io.readText(path)
    return countGuests(list)
}

void main() {
    let guests = guestsIn("guests.txt") catch {
        print("No guest list yet")
        return
    }
    print($"{guests} guests, {guests * 3} dates to break the fast")
}
```

With a `guests.txt` holding `Umar`, `Aisha` and `Bilal` on separate lines, it prints
`3 guests, 9 dates to break the fast`. Without the file it prints `No guest list yet`.

Leave `alloc` out of the `uses` clause and the compiler tells you, with the fix:

```text
error BYN6002: `guestsIn` uses `alloc` but does not declare it
  --> main.byn:12:20

  12 │     let list = try Io.readText(path)
     │                    ^^^^^^^^^^^^^^^^^ uses `alloc`
     │
  help: add `alloc` to the `uses` clause, or remove the call
     │ 11 │ public i64 guestsIn(string path) uses fs, alloc fails IoError {
     │    │                                         +++++++
```

### States the compiler tracks

A catering order is placed, then paid, then delivered. Its `states` block names the steps, each method
says which state it needs (`ref this is .paid`) and which it leaves behind (`becomes .delivered`), and a
state can carry its own data (`paid(i64 amount)`):

```
struct Order {
    string dish
    i64 plates
    states {
        placed
        paid(i64 amount)
        delivered(i64 amount)
    }

    void pay(ref this is .placed, i64 amount) becomes .paid {
        become .paid(amount)
    }

    void deliver(ref this is .paid) becomes .delivered {
        become .delivered(amount)
    }
}

string status(Order o) => o switch {
    .placed => $"{o.plates} plates of {o.dish}, waiting for payment",
    .paid(let amount) => $"{o.dish} paid ({amount}), on its way",
    .delivered => $"{o.dish} delivered",
}

void main() {
    var order = Order.placed { dish: "lentil soup", plates: 40 }
    print(status(order))
    order.pay(120)
    print(status(order))
    order.deliver()
    print(status(order))
}
```

```text
40 plates of lentil soup, waiting for payment
lentil soup paid (120), on its way
lentil soup delivered
```

Leave out `order.pay(120)`, so the order is delivered before it is paid, and the program does not compile:

```text
error BYN7001: `deliver` needs `order` to be `.paid`, but it is `Order.placed`
  --> main.byn:29:5

  29 │     order.deliver()
     │     ^^^^^
     │
  help: check the state with `is` or `switch` first
```

### Memory you can see

There is no garbage collector. Text and lists come from an allocator, and `provide` picks which one. Here
every invitation is built in one arena, and all of them are freed together when the arena's scope ends:

```
void main() {
    let guests = ["Umar", "Aisha", "Bilal"]
    using let arena = Arena()
    provide allocator: arena {
        for guest in guests {
            let card = $"Salam {guest}, join us for iftar on Friday"
            print(card)
        }
    }
}
```

```text
Salam Umar, join us for iftar on Friday
Salam Aisha, join us for iftar on Friday
Salam Bilal, join us for iftar on Friday
```

### A few more things

- **Particles.** A function has at most one unlabeled parameter. The others carry a word such as `from`,
  `to`, `by` or `for`, and the call says it too: `iftar.book("Umar", for: 2)`. Calls read like sentences,
  and you can't swap two arguments by accident.
- **Locals are `let`** (or `var` when they change). You write `let list = …`, or `let list: string = …`
  with a type. Declarations put the type first (`i64 countGuests(…)`), local bindings put the name first;
  write it the other way and the error message shows you the fix.
- **`stmt if condition`** is a statement guarded by a condition, as in `fail .full if left == 0`.

The compiler's error messages try to teach. Each error has a code, and `bayan explain <code>` explains
it in more detail, for example `bayan explain BYN1043`.

## Where to go next

- `bayan --help` lists every command: `build`, `run`, `test`, `format`, `check`, `dist` and more.
- [`docs/bayan-spec.md`](docs/bayan-spec.md) is the language specification, the full reference.
- [`docs/bayan-style.md`](docs/bayan-style.md) and [`docs/bayan-grammar.md`](docs/bayan-grammar.md) cover
  naming and style.
- [`docs/DIAGNOSTICS.md`](docs/DIAGNOSTICS.md) lists every error and warning.
- [`CHANGELOG.md`](CHANGELOG.md) says what changed in each version.
- [`docs/bayan-roadmap.md`](docs/bayan-roadmap.md) says what is coming next; [`docs/bayan-not-planned.md`](docs/bayan-not-planned.md)
  lists what Bayān will not do, and [`docs/bayan-nice-to-have.md`](docs/bayan-nice-to-have.md) the ideas with no slot yet.
- Home: <https://bayan.run>. Repository: <https://github.com/ikhbat-org/bayan> (Ikhbat Foundation).

Found a bug or a confusing error message? Please open an issue. A small program that shows the problem
helps most.

## Working on the compiler

The self-hosted compiler lives in `src/`. The original compiler is written in C# (`csharp/`). It still
builds the first stage, and it is the reference the tests check the self-hosted compiler against. You need
the .NET 10 SDK and zig.

```sh
dotnet test -v q                               # unit and golden tests
BAYAN_UPDATE=1 dotnet test                     # rewrite golden expected files
dotnet publish csharp/Bayan.Cli -c Release -r osx-arm64 -o tmp/publish
./tmp/publish/bayan --version
```

`bootstrap/bayan.c` is the self-hosted compiler as plain C, so you can build `bayan` with nothing but a
C compiler. See [`bootstrap/README.md`](bootstrap/README.md).

Local builds go in `dist/` (gitignored). There is one directory per target and version, plus a `latest/`
per target that every build replaces:

```sh
scripts/dist.sh                                # this host: dist/macos-arm64/0.3.2-dev/bayan
scripts/dist.sh --from <publish-dir> --rid win-x64 --commit <sha>   # import a binary published on another OS
```

NativeAOT does not cross-compile between operating systems, so Linux and Windows binaries are published on
those systems and imported with `--from`.

The milestones and an index of the project docs are in [`docs/bayan-milestones.md`](docs/bayan-milestones.md), the
progress log is in [`docs/bayan-progress-log.md`](docs/bayan-progress-log.md), and how a version is cut is
in [`docs/RELEASING.md`](docs/RELEASING.md).
