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

Here is a slightly bigger program: seats for a community iftar. A function that can fail says so in its
signature (`fails IftarError`), and the caller has to decide what happens for each error:

```
union error IftarError {
    full
    tooMany
}

i64 reserve(i64 seats, from i64 left) fails IftarError {
    fail .full if left == 0
    fail .tooMany if seats > left
    return left - seats
}

string book(string name, for i64 seats, from i64 left) {
    let rest = reserve(seats, from: left) catch switch {
        IftarError.full => return $"Sorry {name}, the iftar is full",
        IftarError.tooMany => return $"Sorry {name}, only {left} seats left",
    }
    return $"{name} booked {seats}, {rest} left"
}

void main() {
    print(book("Umar", for: 2, from: 5))
    print(book("Bilal", for: 4, from: 3))
    print(book("Yusuf", for: 1, from: 0))
}
```

```text
Umar booked 2, 3 left
Sorry Bilal, only 3 seats left
Sorry Yusuf, the iftar is full
```

A few things that may look unfamiliar:

- **Particles.** A function has at most one unlabeled parameter. The others carry a word such as `from`,
  `to`, `by` or `for`, and the call says it too: `book("Umar", for: 2, from: 5)`. Calls read like
  sentences, and you can't swap two arguments by accident.
- **Locals are `let`.** You write `let rest = …`, or `let rest: i64 = …` with a type. Declarations put the
  type first (`i64 reserve(…)`), local bindings put the name first; write it the other way and the error
  message shows you the fix.
- **`stmt if condition`** is a statement guarded by a condition, as in `fail .soldOut if left == 0`.

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

The self-hosted compiler lives in `selfhost/`. The original compiler is written in C# (`src/`). It still
builds the first stage, and it is the reference the tests check the self-hosted compiler against. You need
the .NET 10 SDK and zig.

```sh
dotnet test -v q                               # unit and golden tests
BAYAN_UPDATE=1 dotnet test                     # rewrite golden expected files
dotnet publish src/Bayan.Cli -c Release -r osx-arm64 -o tmp/publish
./tmp/publish/bayan --version
```

`bootstrap/bayan.c` is the self-hosted compiler as plain C, so you can build `bayan` with nothing but a
C compiler. See [`bootstrap/README.md`](bootstrap/README.md).

Local builds go in `dist/` (gitignored). There is one directory per target and version, plus a `latest/`
per target that every build replaces:

```sh
scripts/dist.sh                                # this host: dist/macos-arm64/0.3.0/bayan
scripts/dist.sh --from <publish-dir> --rid win-x64 --commit <sha>   # import a binary published on another OS
```

NativeAOT does not cross-compile between operating systems, so Linux and Windows binaries are published on
those systems and imported with `--from`.

The milestones and an index of the project docs are in [`docs/bayan-milestones.md`](docs/bayan-milestones.md), the
progress log is in [`docs/bayan-progress-log.md`](docs/bayan-progress-log.md), and how a version is cut is
in [`docs/RELEASING.md`](docs/RELEASING.md).
