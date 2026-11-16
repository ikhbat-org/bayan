# Releasing Bayān

Version: 0.3.3-dev (matches `bayan --version`)

How a version is cut, checked, tagged and published, and where the version and the versioned docs live.

## Where the version lives

`VERSION` at the repo root is the source: `X.Y.Z` on a release commit, `X.Y.Z-dev` between releases. It is mirrored in
(`bayan_mirrors` in `scripts/release/version.sh`):

- `csharp/Bayan.Backend.C/Toolchain.cs`: `CompilerVersion`, what `bayan --version` prints;
- `src/driver/main.byn`: `version`, the self-hosted driver's;
- `tests/cases/out/dist.tree`: the `"compiler": "bayan …"` lines of the `bayan dist` golden;
- `README.md`: the `dist/<target>/<version>/bayan` path in the build example.

`bootstrap/bayan.c` is generated from `src/` by `scripts/selfhost/land.sh`; regenerate it after the version
changes, never edit it.

The versioned docs carry a header in their first lines (`bayan_header_docs`): `docs/bayan-spec.md`,
`docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md` and `docs/STATUS.md`.

```text
Version: X.Y.Z (matches `bayan --version`)
Revisions applied: 0001–0023
```

`Revisions applied` names the highest `docs/revisions/NNNN-*.md`; the range covers every revision from 0001.

Each doc under `docs/` is one of three kinds (`docs/decisions/2026-11-14-003-versioned-docs-and-provenance.md`):

- **Release docs** (`bayan_release_docs`: the header docs, this file and the other maintained docs) carry the
  `Version:` line in their first ten lines.
- **Record docs** (specs, plans, decisions, revisions, audits, the progress log, the proposals) carry `Status:`,
  `Release:` and `Sources:` lines in their first ten lines; the laws carry `release:` and `sources:` keys in their
  frontmatter. `Release:` is a released version, the version being built, or `unscheduled`.
- **Snapshot docs** (`docs/export/`, `docs/misc/`, the design rounds, the Sūq reports and other dated notes) carry
  `Snapshot: <date>; not maintained. Current text: <path|none>`.

`bash scripts/release/set-version.sh <version>` writes `VERSION`, every mirror and the `Version:` line of every release
doc, and prints each file it changed.

## Generated docs

`docs/DIAGNOSTICS.md`, the keyword and stdlib rows of `docs/STATUS.md` and the spec index `docs/specs/README.md` are
generated. Regenerate them after changing
`DiagnosticCodes.cs`, a diagnostic page, `Keywords.cs`, `TokenKind.cs`, `BuiltinMembers.cs`, the header of a spec or the
version:

```sh
bash scripts/docs/gen-diagnostics.sh --write   # docs/DIAGNOSTICS.md
bash scripts/docs/gen-status.sh --write        # docs/STATUS.md, between the <!-- generated: … --> markers
bash scripts/docs/gen-spec-index.sh --write    # docs/specs/README.md
```

Without `--write` each prints to stdout. Output is sorted and has no dates. All three generated docs are release docs: each
generator writes the `Version:` and `Revisions applied:` header itself, from `VERSION` and the highest revision.

- `gen-diagnostics.sh` reads `csharp/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs`: the descriptors, the `// BYNnnnn is
  retired|reserved` comments and the `// Reserved: round 4` block. It also checks which `docs/diagnostics/BYNnnnn.md`
  pages exist. Codes with no machine-readable source are in the hand-kept `docs/diagnostics-allocated.txt`, and the
  generator reads that file too. The file lists plan codes (allocated in a plan, spec or revision, with no descriptor
  yet), reservations with no descriptor, and retirements recorded only in a code's page. It holds one code per line:
  `plan|reserved|retired BYNnnnn Name-or-- note`. Edit it when such a code is allocated, reserved or retired, then
  regenerate.
- `gen-status.sh` reads `csharp/Bayan.Syntax/Lexing/Keywords.cs` and `TokenKind.cs` for keywords and
  `csharp/Bayan.Semantics/Binding/BuiltinMembers.cs` for stdlib members.
- `gen-spec-index.sh` reads the title and the `Status:`, `Release:` and `Sources:` header lines of each
  `docs/specs/NNN-*/NNN-spec.md`, and which plan, tasks and api files sit beside it. It fails on a Status that starts
  with none of `done`, `in progress`, `approved`, `open`, `deferred`, `draft`, `rejected` or `superseded`.

The feature, pattern, effect and unbuilt-keyword tables of `docs/STATUS.md` are hand-kept. Change a row's status
cell when that feature's status changes; `cut.sh` lists those changes in the CHANGELOG.

## What CI checks

The Linux job of `.github/workflows/ci.yml` (step "Docs and release script tests") runs `set-version.test.sh`,
`cut.test.sh`, `scripts/docs/*.test.sh` and `bash scripts/docs/check.sh`; `package.test.sh` runs in step "Script
tests" on Linux and macOS. `check.sh` prints one line per failure and fails when:

- (a) a release doc's `Version:` line is not `Version: <VERSION> (matches \`bayan --version\`)`;
- (b) the revision files do not run 0001 to the highest with no gap or repeat, or a `Revisions applied:` line does
  not name the highest;
- (c) `docs/DIAGNOSTICS.md`, `docs/STATUS.md` or `docs/specs/README.md` differs from what its generator prints;
- (d) a mirror's version differs from `VERSION`;
- (e) SPEC, GRAMMAR or STYLE has a `(not in A.B` or `(partial in A.B` status tag whose `A.B` is not the major.minor
  of `VERSION` (`-dev` stripped);
- (h) a record doc lacks its `Status:`, `Release:` or `Sources:` line (a law, its `status:`, `release:` or `sources:`
  key), or its release is not a `## [X.Y.Z]` version of `CHANGELOG.md`, the `VERSION` target or `unscheduled`; or a
  snapshot doc lacks its `Snapshot:` line;
- (i) a `docs/revisions/NNNN-*.md` file is not cited in `docs/bayan-feature-history.md`, or a numbered section of the
  spec has no `### §N.` row there (`scripts/docs/check-history.sh`).

So a new revision, a new diagnostic or a version change lands with its headers and generated docs in the same
commit.

## Cutting a release

Run it from `dev`, with `VERSION` at `X.Y.Z-dev` and `check.sh` passing.

1. **Cut.** First update `docs/bayan-roadmap.md` (the states, the order, the `State of `dev` at <sha>, <date>.` line);
   `cut.sh` refuses a roadmap dated before the previous release. Then run `bash scripts/release/cut.sh X.Y.Z`. It:
   - sets `VERSION`, the mirrors and the headers to `X.Y.Z`, with `Revisions applied` at the highest revision;
   - regenerates the generated docs;
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
   - once spec 019 adds the R27 job (diverse double-compiling), a red R27 run means fix the job's environment (the SDK download,
     the runner image) and re-run it; it does not mean the release is broken (decided 2026-11-17);
   - the release job adds `bayan-X.Y.Z-docs.tar.gz` (the same six docs, and every other release doc under its path
     below `docs/`, among them `specs/README.md` and `bayan-feature-history.md`, under `bayan-X.Y.Z-docs/share/doc/bayan/`)
     and `SHA256SUMS`, and opens a draft GitHub Release whose notes are the CHANGELOG section. While the major version is 0 the draft
     is marked a prerelease (`package.sh release-flags`; user, 2026-11-14).

   Publishing the draft is a manual step.
8. **PDFs.** Run `bash scripts/release/docs-pdf.sh` (needs Chrome; `CHROME` names it; `BAYAN` names the compiler that runs the book's examples, default the CLI
   built from `HEAD` by `scripts/pinned-bayan.sh`) and attach `dist/bayan-manifesto-X.Y.Z.pdf`
   and `dist/bayan-book-X.Y.Z.pdf` to the GitHub release.
9. **Next dev version.** `bash scripts/release/next-dev.sh X.Y.(Z+1)` (or the next minor) sets `VERSION`, the mirrors
   and the headers to `-dev` and regenerates the generated docs. Regenerate `bootstrap/bayan.c` and commit all of it
   as one commit on `dev`.

## Known limits

Until the per-phase arenas are finished (Q31), the stage-2 build of `src/driver` peaks at 1.69 GB of memory
(macOS, 2026-11-14; 2.94 GB on 2026-11-12). `scripts/release/package.sh notes` prints that line after the CHANGELOG section, so every release's notes
carry it.

## Archive

Git tags are the archive. The docs of any release are the files at its `vX.Y.Z` tag, and the release's
`bayan-X.Y.Z-docs.tar.gz`. Past versions are not copied into the repo. `docs/export/` is a dated snapshot
(821afa40); it is not shipped, and `check.sh` checks only its `Snapshot:` line.
