# 011 — The C# compiler archive (`csharp-final`)

Status: decided (spec 019 R31, R32; owner 2026-11-18, option a of T65)
Release: unscheduled (0.4.0)
Date: 2026-11-23
Sources: `docs/specs/019-dotnet-exit/019-spec.md` (R31–R34), `019-tasks.md` (T65, T66, T67)

The C# compiler stops being part of the tree with 019b. Its last state is kept as an annotated git tag, so it can be read, built and restored without searching history.

## The tag

| | |
|---|---|
| Tag | `csharp-final` (annotated) |
| Commit | `e57839016`, the 019a merge commit on `dev` (`Merge feat/019-dotnet-exit: 019a, the .NET exit (ci 45168518573, laws-nightly 45168530621 green)`) |
| Checked before the tag is pushed | one `dotnet test` and one manual ddc run on that commit (R31); the tag was made locally on 2026-11-23 and is pushed by the owner after both pass |
| 019b starts at | the commit after it on `dev`; the removal commit is titled `chore(019b): remove the C# compiler` (R33) |

## What it holds

- `csharp/`: the C# compiler (lexer, parser, semantics, C backend, CLI) and its xUnit suite under `csharp/tests/Bayan.Tests/`.
- `src/tests/*.cs`, `Bayan.slnx`, the C# sources of `editors/language-server`, `tools/Bayan.SyntaxFuzz` and `tools/Bayan.UnicodeGen`.
- The .NET CI jobs as they ran at that commit (`.github/workflows/`).

`global.json` stays in the tree after 019b: `scripts/ci/install-dotnet.sh` reads it for the weekly ddc job (R27, R34), which builds the C# compiler from this tag.

## Reading, checking out and restoring it

Read one file:

```
git show csharp-final:csharp/Bayan.Cli/Program.cs
```

Check out the whole tree beside the working copy:

```
git worktree add ../bayan-csharp csharp-final
```

Restore `csharp/` into the current tree:

```
git restore --source=csharp-final -- csharp/
```

The tag is frozen: it is never moved, and C# fixes are not made after it. The weekly ddc job (`.github/workflows/ddc.yml`) defaults to it since T65 (pushed 2026-11-23) and builds the C# compiler from it to reproduce `bootstrap/bayan.c` (diverse double-compiling).
