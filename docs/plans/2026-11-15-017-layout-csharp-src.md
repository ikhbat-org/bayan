# Plan 017: `src/` → `csharp/`, `selfhost/` → `src/`, tests beside their code

Status: in progress
Release: unscheduled
Sources: user decisions 2026-11-15 ("src => csharp-src or something equiv, selfhost => src"; name `csharp`; "shared tests stay in tests"; "move / reorganize first then style spec"; "land everything you can merge back to dev and then start with a clean slate"; "The move has to be done properly through git, so the histories follow").

## Goal
The Bayān compiler lives in `src/`, the C# implementation in `csharp/`, and each side's tests sit beside it. `git log --follow` and `git blame` follow every moved file.

## Layout
| from | to |
|---|---|
| `src/Bayan.*` | `csharp/Bayan.*` |
| `src/runtime/` | `runtime/` (both compilers embed it) |
| `tests/native/` | `runtime/tests/` |
| `tests/Bayan.Tests/` (all but `Selfhost*.cs`) | `csharp/tests/Bayan.Tests/` |
| `tests/Bayan.Tests/Selfhost*.cs` (115 files) | `src/tests/` |
| `selfhost/{driver,emitter,lexer,parser,semantics}` | `src/{…}` |
| `tests/cases/`, `tests/parity/`, `tests/*.txt`, `tests/*.json` | stay (shared) |

One test assembly, `csharp/tests/Bayan.Tests/Bayan.Tests.csproj`, compiles `src/tests/**/*.cs` too. The two halves share helpers both ways (`Golden`, `TestSetup`, `TestTime`, `PeakSampler`, `ToolchainEnvironment`, `SelfhostSemanticsHarness`, `SelfhostDriverGoldenTests`), so two assemblies need a shared support project first; that split is out of scope (`work/todo.md`). Class names and namespaces do not change, so shard lists, `tests/windows-known-failures.txt` and `class-times.tsv` keep working.

## History
Git infers renames from content when `log`/`blame` run. So:
1. **Commit 1, renames only:** `src/runtime` → `runtime`, `tests/native` → `runtime/tests`, `src` → `csharp`, `tests/Bayan.Tests` → `csharp/tests/Bayan.Tests`.
2. **Commit 2, renames only:** `selfhost` → `src`, the `Selfhost*.cs` files → `src/tests/`.
3. **Later commits:** path fixes, regenerated files.

No content changes in 1 and 2, so every file is a 100% rename and a `.byn` file never pairs with an old `.cs` file. The tree does not build between 1 and the path-fix commit; bisect skips them. Path-limited `git log -- src/` lists both eras by design; the pre-move commit is named in `docs/bayan-contributing.md` and `CHANGELOG.md`.

## Path fixes
- Build: the six `csproj`, `Bayan.slnx`, `Directory.Build.props`, `.github/workflows/*`, `.gitattributes`, `.gitignore`, `.structure-audit.json`.
- Code: path literals in `csharp/`, `src/`, `tools/`, `bench/` (repo-relative `selfhost/`, `src/runtime`, `tests/native`, `tests/Bayan.Tests`).
- Scripts and their fixtures: `scripts/`, `tests/parity/`, `tests/cases/` expected files that print paths.
- Generated: `bootstrap/bayan.c`, goldens through `BAYAN_UPDATE=1`, each regenerated diff checked to be path text only.
- Docs: `AGENTS.md`, `README.md`, release-kind docs, `docs/laws/` (proof paths), and records whose `Status:` is open, in progress or approved. Done, superseded and rejected records keep the old paths as history; the mapping table goes in `docs/bayan-contributing.md`.
- Rewrite order, word-bounded: `src/runtime/` → `runtime/`, `tests/native/` → `runtime/tests/`, `tests/Bayan.Tests/Selfhost` → `src/tests/Selfhost`, `tests/Bayan.Tests` → `csharp/tests/Bayan.Tests`, `src/` → `csharp/`, then `selfhost/` → `src/`. The word `selfhost` without a slash (namespaces, class names, prose) stays.

## Clean slate (before the move)
- Every branch with work not on dev was checked with `git cherry`: 59 of 75 add nothing; the one finished fix (`mutate-batch.sh` Windows glob) is merged (93cfe60e). Unfinished mutation work (`chore/worker-mut-perfn`, `*-mut-schemata-progress`), scratch, probe and "Not done" worker branches stay as they are.
- `scripts/cleanup/2026-11-15-clean-slate.sh` (written, not run): removes every worktree, puts the main checkout on dev, deletes the branches whose patches are all on dev (`--delete-branches`).

## Verification
1. `dotnet build` and the full suite on bayan-test01 and wp1: 0 failed.
2. Every `ci.yml` step locally: macOS under `/bin/bash` with the system PATH, Linux on bayan-test01, Windows on wp1.
3. `git log --follow` on a sample of moved files reaches pre-move commits; `git diff -M --stat` of commits 1 and 2 shows only `R100` entries.
4. `scripts/docs/check.sh` and its tests, `laws-check.js --run`, `structure-audit.js`, `/code-review`.

Merges `--no-ff` into dev, unpushed. Then the style-guide spec.
