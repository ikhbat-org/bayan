# Bayān

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="site-prototypes/brand/mascot/bayan-hoopoe-dark.svg">
    <img src="site-prototypes/brand/mascot/bayan-hoopoe-light.svg" alt="Bayān, the hoopoe mascot" width="160">
  </picture>
</p>

A small, explicit language that compiles to native executables. Errors are values, memory is visible.

[![CI](https://github.com/ikhbat-org/bayan/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/ikhbat-org/bayan/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-0.4.x-1F3A5F)](CHANGELOG.md)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-1F3A5F)](#install)
[![Runtime](https://img.shields.io/badge/runtime-none-C08A2E)](#what-bayān-has-instead)
[![GC](https://img.shields.io/badge/GC-none-C08A2E)](#memory-you-can-see)
[![License: ISL-P](https://img.shields.io/badge/license-ISL--P%201.2-1F3A5F)](LICENSE.md)

Bayān (بيان, "clear statement") compiles to a small native executable, with no runtime to install, no
garbage collector and no exceptions. Values are copied by default, errors are return values the compiler
makes you handle, and memory comes from scopes and allocators you can see. The compiler is written in
Bayān itself and turns your program into C for a C compiler.

```swift
string greeting() {
    return "Salam, world!"
}

void main() {
    print(greeting())
}
```

```text
Salam, world!
```

A program starts at `void main()`. A file holding only `print("Salam, world!")`, with no `main`, runs too: `bayan run hello.byn`.

> [!NOTE]
> Bayān is young (version 0.4.x). The language is usable and the compiler builds itself, but expect rough
> edges, and expect things to change between versions.

*Bayān (ASCII: Bayan). The CLI, package names, URLs and identifiers use `bayan`.*

---

## Contents

- [Install](#install)
- [Your first program](#your-first-program)
- [Batteries included](#batteries-included)
- [How it works](#how-it-works)
- [A taste of the language](#a-taste-of-the-language)
- [What Bayān has instead](#what-bayān-has-instead)
- [Where to go next](#where-to-go-next)
- [Working on the compiler](#working-on-the-compiler)
- [License](#license)

---

## Install

You need two things: the `bayan` binary and a C compiler.

1. **Get `bayan`.** Download the archive for your machine from the
   [releases page](https://github.com/ikhbat-org/bayan/releases): `bayan-0.4.1-macos-arm64.tar.gz`,
   `bayan-0.4.1-macos-x64.tar.gz`, `bayan-0.4.1-linux-x64.tar.gz`, `bayan-0.4.1-linux-arm64.tar.gz`,
   `bayan-0.4.1-windows-x64.zip` or `bayan-0.4.1-windows-arm64.zip`. Unpack it and put the
   `bayan` binary somewhere on your `PATH`:

   ```sh
   tar -xzf bayan-0.4.1-macos-arm64.tar.gz
   cp bayan-0.4.1-macos-arm64/bayan ~/.local/bin/
   ```

   On Windows, unzip the archive and put `bayan.exe` on your `PATH`:

   ```powershell
   Expand-Archive bayan-0.4.1-windows-x64.zip -DestinationPath .
   $env:Path += ";$PWD\bayan-0.4.1-windows-x64"
   ```

2. **Get a C compiler.** Bayān prefers [zig](https://ziglang.org) (`zig cc`), because it can build for
   other platforms too. If zig is not installed, it uses `cc`, `clang` or `gcc` from your `PATH`.

3. **Check your setup:**

   ```sh
   bayan doctor
   ```

   This lists the compiler, zig, git and the build cache that `bayan` found. If something is missing, it
   tells you how to fix it.

---

## Your first program

```sh
bayan new greet
cd greet
bayan run
```

```text
Salam, world!
```

`bayan new` created a few files; these are the ones that matter:

- `package.byn` describes the project: its name, version and dependencies.
- `src/app/main.byn` is the program.
- `tests/app.test.byn` is a test.

Open `src/app/main.byn`:

```swift
/// The line this app prints.
string greeting() {
    return "Salam, world!"
}

print(greeting())
```

It has top-level statements and no `main`: the compiler runs them as the program. Change the greeting to `"Salam, Aisha!"` and run `bayan run` again. To run the tests, use `bayan test`.
The test will now fail, because it still expects the old greeting. Change it to `"Salam, Aisha!"` too
and it passes.

`main` can do real work. Save this as `guests.byn` outside the project. It fails with an error, and
`@exitCode` sets the process exit code:

```swift
union error GuestError {
    /// The guest list is empty.
    @exitCode(3)
    noGuests
}

i32 countGuests(string list) fails GuestError {
    fail .noGuests if list.isEmpty
    return 1
}

void main() fails GuestError {
    let guests = try countGuests("")
    print($"{guests} guests")
}
```

```sh
bayan run guests.byn; echo $?
```

```text
error: The guest list is empty.
3
```

`int` and `long` also compile, and `bayan format` rewrites them to the spelling set by `style.primitives`
in `package.byn` (spec §3.1).

---

## Batteries included

One `bayan` binary holds the compiler, the formatter, the test runner and the release builder. There is
nothing else to install except a C compiler. The commands are from `bayan --help`, except `bayan test --coverage`, which works but is not in the help text yet.

| Command | What it does |
|---|---|
| `bayan new`, `bayan init` | Create an app, library (`--lib`) or script (`--script`), in a new or an existing directory |
| `bayan run` | Compile and run a project, a script or a file |
| `bayan build` | Compile to an executable; `--mode debug\|safe\|fast`, `--target`, `--emit-c` |
| `bayan test` | Run each test in its own process; `--coverage` for a report of lines, branches and error paths; `--mutate` for mutation testing; `--changed` for modules touched since `HEAD`; `--json` |
| `bayan check` | Report diagnostics without building; `--diagnostics json` for tools |
| `bayan format` | Rewrite input forms and apply the `style` in `package.byn`; `--check` writes nothing |
| `bayan explain` | Explain a diagnostic code, for example `bayan explain BYN6002` |
| `bayan doctor` | Check the C compiler, zig, git and the build cache, with a fix for each problem |
| `bayan dist` | Build release binaries into `dist/<version>/`; `--target all` cross-compiles through zig |
| `bayan mutate` | Run a command once per mutant site of a prebuilt `--mutate` binary |
| `bayan audit` | List every `because` bypass and every `unsafe` or `extern` declaration, with its reason |
| `bayan clean`, `bayan cache stats` | Remove `out/` (and `dist/`, the cache on request); show the shared build cache |
| `bayan lex`, `types`, `features --used <path>` | Look inside the compiler: tokens, inferred types, features a build used |

An editor language server, `bayan-lsp`, lives in [`editors/`](editors/README.md) with a VS Code extension.
The server is early. Each release archive holds it beside `bayan` (`bayan-lsp.exe` on Windows).

The standard library is compiled in, so a program needs no package manager to use it:

| Piece | What it gives you |
|---|---|
| `Io` | Files (`Io.readText`), standard streams, processes, random numbers; each use shows up in `uses` |
| `Path` | File names and paths, for example `Path.fileName` |
| `List`, `Map` | Growable collections that take their memory from an allocator |
| `StrBuf` | A string builder for loops |
| `Arena` | Allocate many things, free them all together |
| `std.json` | A JSON reader and a `Json` value type: `import std.json` |

`std.time` and `std.db` are specified in [`docs/bayan-spec.md`](docs/bayan-spec.md) but not built yet.

---

## How it works

`bayan` parses and checks your `.byn` files, lowers them to C, and hands the C to `zig cc` (or `cc`). The
output is one native executable.

```mermaid
flowchart LR
    A[".byn source"] --> B["bayan<br/>parse, check, lower"]
    B --> C["C"]
    C --> D["zig cc / cc"]
    D --> E["native executable"]
```

`bayan build --emit-c` prints the generated C. A project build keeps it in `out/<mode>/<target>/c/main.c`.

---

## A taste of the language

Small programs around a community iftar. Each runs as it is with `bayan run main.byn`.

### Errors are values

Booking can fail, and the signature says so (`fails BookingError`). The compiler checks that the caller
handles every error. An error can carry data, like `notEnough(i32 left)`.

```swift
union error BookingError {
    /// Every seat is taken.
    full
    /// Fewer seats are left than were asked for.
    notEnough(i32 left)
}

struct Iftar {
    i32 seats
    i32 booked

    i32 left => seats - booked

    void reserve(ref this, i32 count) fails BookingError {
        fail .full if left == 0
        fail .notEnough(left) if count > left
        booked += count
    }

    string book(ref this, string guest, for i32 count) {
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

`///` is a doc comment, and on an error case its first line is the error's message (`$"{e}"` prints `Every seat is taken.`). A plain `//` comment, also allowed at the end of a line, is not part of the program.

`fail` returns the error. A call that can fail is marked `try` (pass it on) or `catch` (handle it here).

### Effects are part of the signature

A public function lists what it touches: files (`fs`), memory (`alloc`), the console, the network and so
on. With no `uses` clause it only computes. Private functions, `main` and scripts work their effects out
from their calls.

```swift
/// Counts the names in a guest list, one per line. No `uses` clause: it only computes.
public i32 countGuests(string list) {
    var count = 0
    for line in list.lines {
        count += 1 if !line.trimmed().isEmpty
    }
    return count
}

/// Reads the guest list from a file, so it declares `uses fs`.
public i32 guestsIn(string path) uses fs, alloc fails IoError {
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

With a `guests.txt` of three names:

```text
3 guests, 9 dates to break the fast
```

Without the file it prints `No guest list yet`. Leave `alloc` out of `uses` and the compiler says so, with the fix:

<details>
<summary>The compiler error</summary>

```text
error BYN6002: `guestsIn` uses `alloc` but does not declare it
  --> ~/iftar/main.byn:12:20

  12 │     let list = try Io.readText(path)
     │                    ^^^^^^^^^^^^^^^^^ uses `alloc`
     │
  help: add `alloc` to the `uses` clause, or remove the call
     │ 11 │ public i32 guestsIn(string path) uses fs, alloc fails IoError {
     │    │                                         +++++++

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN6002
```

</details>

### States the compiler tracks

An order is placed, then paid, then delivered. Each method names the state it needs (`is .paid`) and the
one it leaves (`becomes .delivered`). A state can carry data (`paid(i32 amount)`).

```mermaid
stateDiagram-v2
    [*] --> placed
    placed --> paid: pay(amount)
    paid --> delivered: deliver()
    delivered --> [*]
```

```swift
struct Order {
    string dish
    i32 plates
    states {
        placed
        paid(i32 amount)
        delivered(i32 amount)
    }

    void pay(ref this is .placed, i32 amount) becomes .paid {
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

Deliver before paying (drop `order.pay(120)`) and it does not compile:

<details>
<summary>The compiler error</summary>

```text
error BYN7001: `deliver` needs `order` to be `.paid`, but it is `Order.placed`
  --> ~/iftar/main.byn:29:5

  29 │     order.deliver()
     │     ^^^^^
     │
  help: check the state with `is` or `switch` first

✗ build failed: 1 error, 0 warnings
  explain: bayan explain BYN7001
```

</details>

### Memory you can see

Text and lists come from an allocator, and `provide` picks which. Here one arena holds every invitation
and frees them together at the end of its scope.

```swift
void main() {
    let guests = ["Umar", "Aisha", "Bilal"]
    using let arena = Arena()
    provide allocator: arena {
        for guest in guests {
            let card = $"Assalamu alaykum {guest}, join us for iftar on Friday"
            print(card)
        }
    }
}
```

```text
Assalamu alaykum Umar, join us for iftar on Friday
Assalamu alaykum Aisha, join us for iftar on Friday
Assalamu alaykum Bilal, join us for iftar on Friday
```

### A few more things

- **Particles.** At most one parameter is unlabeled; the rest carry a word such as `for`, and the call
  says it too: `iftar.book("Umar", for: 2)`. You can't swap two arguments by accident.
- **Locals** are `let` or `var`: `let list = …`, or `let list: string = …` with a type. Declarations put
  the type first (`i32 countGuests(…)`), local bindings put the name first; write it the other way and the
  error message shows you the fix.
- **`stmt if condition`** guards a statement, as in `fail .full if left == 0`.
- **Errors teach.** Each has a code; `bayan explain BYN1043` explains it.

---

## What Bayān has instead

| Often found elsewhere | In Bayān |
|---|---|
| Exceptions | `fails` in the signature; `fail` returns the error; `try` and `catch` at the call |
| Garbage collector | Scopes and allocators; `Arena` and `provide allocator:` |
| Runtime to install | None; the output is one native executable |
| Hidden side effects | `uses` clauses on public functions |
| Run-time checks of object lifecycle | `states`, `is` and `becomes`, checked at compile time |

---

## Where to go next

- `bayan --help` lists every command.
- [`docs/bayan-spec.md`](docs/bayan-spec.md) is the language specification, the full reference.
- [Bayān grammar guide](docs/bayan-grammar.md) is the naming guide; [Bayān style guide](docs/bayan-style.md)
  is the style guide.
- [`docs/DIAGNOSTICS.md`](docs/DIAGNOSTICS.md) lists every error and warning.
- [`CHANGELOG.md`](CHANGELOG.md) says what changed in each version.
- [`docs/bayan-roadmap.md`](docs/bayan-roadmap.md) says what is coming next; [`docs/bayan-not-planned.md`](docs/bayan-not-planned.md)
  lists what Bayān will not do, and [`docs/bayan-nice-to-have.md`](docs/bayan-nice-to-have.md) the ideas with no slot yet.
- Home: <https://bayan.run>. Repository: <https://github.com/ikhbat-org/bayan> (Ikhbat Foundation).

Found a bug or a confusing error message? Please open an issue. A small program that shows the problem
helps most.

---

## Working on the compiler

The compiler lives in `src/` and is written in Bayān. You need a C compiler; zig is optional.

Build the self-hosted compiler with any `bayan`, or with only a C compiler from `bootstrap/bayan.c` (the
self-hosted compiler as plain C). Both produce the self-hosted `bayan`. See
[`bootstrap/README.md`](bootstrap/README.md).

```sh
bayan build --mode safe --package src -o tmp/bayan-selfhost src/driver
cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o tmp/bayan-boot
./tmp/bayan-selfhost --version                 # bayan <version> (selfhost)
```

`bash scripts/test.sh` runs the whole suite (golden cases, Bayān `test` blocks, CLI parity, script tests, runtime C
tests); `--only <part>` runs one part.

Local builds go in `dist/` (gitignored). `scripts/dist.sh` writes `dist/<target>/<version>/` plus a `latest/`
per target that every build replaces. `bayan dist` writes `dist/<version>/` and one `dist/latest/`.

```sh
scripts/dist.sh                                # this host: dist/macos-arm64/0.4.1/bayan
scripts/dist.sh --from <publish-dir> --rid win-x64 --commit <sha>   # import a binary published on another OS
```

`scripts/dist.sh --rid <rid>` cross-builds another target through zig; `--from` imports a binary built elsewhere.

The milestones and an index of the project docs are in [`docs/bayan-milestones.md`](docs/bayan-milestones.md), the
progress log is in [`docs/bayan-progress-log.md`](docs/bayan-progress-log.md), and how a version is cut is
in [`docs/RELEASING.md`](docs/RELEASING.md).

Code fences in this README use Swift highlighting until GitHub knows `.byn`.

---

## License

Bayān is released under the Islamic Software License - Permissive (ISL-P), Version 1.2. See [`LICENSE.md`](LICENSE.md).
