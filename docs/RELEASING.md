# Releasing Bayān

How a version is cut, checked, tagged and published, and where the version and the versioned docs live.

## Where the version lives

`VERSION` at the repo root is the source: `X.Y.Z` on a release commit, `X.Y.Z-dev` between releases. It is mirrored in
(`bayan_mirrors` in `scripts/release/version.sh`):

- `src/Bayan.Backend.C/Toolchain.cs`: `CompilerVersion`, what `bayan --version` prints;
- `selfhost/driver/main.byn`: `version`, the self-hosted driver's;
- `tests/cases/out/dist.tree`: the `"compiler": "bayan …"` lines of the `bayan dist` golden;
- `README.md`: the `dist/<target>/<version>/bayan` path in the build example.

`bootstrap/bayan.c` is generated from `selfhost/` by `scripts/selfhost/land.sh`; regenerate it after the version
changes, never edit it.

The versioned docs carry a header in their first lines (`bayan_header_docs`): `docs/bayan-spec.md`,
`docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md` and `docs/STATUS.md`.

```text
Version: 0.2.0 (matches `bayan --version`)
Revisions applied: 0001–0020
```

`Revisions applied` names the highest `docs/revisions/NNNN-*.md`; the range covers every revision from 0001.

`bash scripts/release/set-version.sh <version>` writes `VERSION`, every mirror and every `Version:` line, and prints
each file it changed.

## Generated docs

`docs/DIAGNOSTICS.md` and the keyword and stdlib rows of `docs/STATUS.md` are generated. Regenerate them after changing
`DiagnosticCodes.cs`, a diagnostic page, `Keywords.cs`, `TokenKind.cs`, `BuiltinMembers.cs` or the version:

```sh
bash scripts/docs/gen-diagnostics.sh --write   # docs/DIAGNOSTICS.md
bash scripts/docs/gen-status.sh --write        # docs/STATUS.md, between the <!-- generated: … --> markers
```

Without `--write` each prints to stdout. Output is sorted and has no dates.

- `gen-diagnostics.sh` reads `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs`: the descriptors, the `// BYNnnnn is
  retired|reserved` comments and the `// Reserved: round 4` block. It also checks which `docs/diagnostics/BYNnnnn.md`
  pages exist. Codes with no machine-readable source are in the hand-kept `docs/diagnostics-allocated.txt`, and the
  generator reads that file too. The file lists plan codes (allocated in a plan, spec or revision, with no descriptor
  yet), reservations with no descriptor, and retirements recorded only in a code's page. It holds one code per line:
  `plan|reserved|retired BYNnnnn Name-or-- note`. Edit it when such a code is allocated, reserved or retired, then
  regenerate.
- `gen-status.sh` reads `src/Bayan.Syntax/Lexing/Keywords.cs` and `TokenKind.cs` for keywords and
  `src/Bayan.Semantics/Binding/BuiltinMembers.cs` for stdlib members.

The feature, pattern, effect and unbuilt-keyword tables of `docs/STATUS.md` are hand-kept. Change a row's status
cell when that feature's status changes; `cut.sh` lists those changes in the CHANGELOG.

## What CI checks

The Linux job of `.github/workflows/ci.yml` (step "Docs and release script tests") runs `set-version.test.sh`,
`cut.test.sh`, `scripts/docs/*.test.sh` and `bash scripts/docs/check.sh`; `package.test.sh` runs in step "Script
tests" on Linux and macOS. `check.sh` prints one line per failure and fails when:

- (a) a header doc's `Version:` line is not `Version: <VERSION> (matches \`bayan --version\`)`;
- (b) the revision files do not run 0001 to the highest with no gap or repeat, or a `Revisions applied:` line does
  not name the highest;
- (c) `docs/DIAGNOSTICS.md` or `docs/STATUS.md` differs from what its generator prints;
- (d) a mirror's version differs from `VERSION`.

So a new revision, a new diagnostic or a version change lands with its headers and generated docs in the same
commit.

## Cutting a release

Run it from `dev`, with `VERSION` at `X.Y.Z-dev` and `check.sh` passing.

1. **Cut.** `bash scripts/release/cut.sh X.Y.Z`. It:
   - sets `VERSION`, the mirrors and the headers to `X.Y.Z`, with `Revisions applied` at the highest revision;
   - regenerates both generated docs;
   - turns the `## [Unreleased]` body of `CHANGELOG.md` into `## [X.Y.Z] - <today>`, leaving `[Unreleased]` empty.

   The new section gets two lists:
   - `### Revisions`: the revision files added since the previous `v*` tag (the highest `vA.B.C` below `X.Y.Z`, reachable from HEAD
     or not);
   - `### Status changes`: the hand-kept `docs/STATUS.md` rows whose status cell changed or that are new since that
     tag.

   It fails, before it touches the CHANGELOG, when a tracked file still contains the previous `-dev` version
   (for example `1.2.0-dev`). It prints each file it changed and the new section. It never commits, tags or pushes.
2. **Regenerate `bootstrap/bayan.c`** with `scripts/selfhost/land.sh`, so the bootstrap compiler reports the new
   version.
3. **Review.** Edit the CHANGELOG section (a summary, known limits). Run the tests, `bash scripts/docs/check.sh` and
   the memory gate (`bash scripts/release/memory-gate.sh`, `docs/memory-leaks.md`).
4. **Commit** the release as one commit, and merge it to `main`.
5. **Dry run.** Run the release workflow by hand on that commit (Actions, `release`, Run workflow) with `dry_run:
   true` and version `X.Y.Z-rc.N`. It runs every job but the draft. The release job refuses a `-rc` tag or a
   dispatch run (`scripts/release/refuse-draft.sh`), so a dry run never drafts a release.
6. **Tag** that commit `vX.Y.Z` and push the tag.
7. **The workflow.** The tag starts `.github/workflows/release.yml`:
   - `package.sh check-tag` refuses a tag that is not `v` + `VERSION`, or a prerelease `VERSION`, and
     `scripts/docs/check.sh` refuses a `VERSION` its mirrors do not match;
   - each target builds the NativeAOT compiler, smoke-tests `--version` and packs
     `bayan-X.Y.Z-<target>.tar.gz` (`.zip` on Windows). The binary, `README.md` and the docs go under
     `share/doc/bayan/`: `SPEC.md`, `GRAMMAR.md`, `STYLE.md`, `DIAGNOSTICS.md`, `STATUS.md` and `CHANGELOG.md`;
   - the memory gate runs on Linux and macOS, the editor gate (`bayan-lsp` memory tests, the extension packaged under a
     size bound) on Linux, and the full tier of every enacted law (`laws-nightly.yml`, up to 180 minutes);
   - the release job adds `bayan-X.Y.Z-docs.tar.gz` (the same six docs under `bayan-X.Y.Z-docs/share/doc/bayan/`)
     and `SHA256SUMS`, and opens a draft GitHub Release whose notes are the CHANGELOG section.

   Publishing the draft is a manual step.
8. **Next dev version.** `bash scripts/release/next-dev.sh X.Y.(Z+1)` (or the next minor) sets `VERSION`, the mirrors
   and the headers to `-dev` and regenerates the generated docs. Regenerate `bootstrap/bayan.c` and commit all of it
   as one commit on `dev`.

## Known limits

Until the per-phase arenas are finished (Q31), the stage-2 build of `selfhost/driver` peaks at 1.69 GB of memory
(macOS, 2026-11-14; 2.94 GB on 2026-11-12). `scripts/release/package.sh notes` prints that line after the CHANGELOG section, so every release's notes
carry it.

## Archive

Git tags are the archive. The docs of any release are the files at its `vX.Y.Z` tag, and the release's
`bayan-X.Y.Z-docs.tar.gz`. Past versions are not copied into the repo. `docs/export/` is a dated snapshot
(821afa40); it is not shipped and not checked.
