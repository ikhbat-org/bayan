# Releasing Bayān

Version: 0.4.1 (matches `bayan --version`)

How a version is cut, checked, tagged, published; where the version and its docs live.

## Where the version lives

`VERSION` at the root is the source: `X.Y.Z` on a release commit, `X.Y.Z-dev` between releases. Its mirrors (`bayan_mirrors`, `scripts/release/version.sh`) are:

- `src/driver/main.byn`: `version`, what `bayan --version` prints;
- `tests/cases/out/dist.tree`: the `bayan dist` golden's `"compiler"` lines;
- `README.md`: the build example's `dist/<target>/<version>/bayan` path.

`bootstrap/bayan.c` is generated from `src/` by `scripts/selfhost/land.sh`; regenerate after a version change, never edit it.

The versioned docs (`bayan_header_docs`: `docs/bayan-spec.md`, `docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md`, `docs/STATUS.md`) open with:

```text
Version: X.Y.Z (matches `bayan --version`)
Revisions applied: 0001–0023
```

`Revisions applied` names the highest `docs/revisions/NNNN-*.md`; the range covers 0001 to it.

`docs/` has three doc kinds (`docs/decisions/2026-11-14-003-versioned-docs-and-provenance.md`), headers in the first ten lines:

| Kind | Docs | Header |
|---|---|---|
| Release | `bayan_release_docs`: header docs, this file, other maintained docs | `Version:` |
| Record | specs, plans, decisions, revisions, audits, progress log, proposals; laws as `release:`/`sources:` keys | `Status:`, `Release:`, `Sources:`; `Release:` is released, being built or `unscheduled` |
| Snapshot | `docs/export/`, `docs/misc/`, the design rounds, the Sūq reports and other dated notes | `Snapshot: <date>; not maintained. Current text: <path|none>` |

`bash scripts/release/set-version.sh <version>` writes `VERSION`, every mirror and release doc header, and prints each changed file.

## Generated docs

`docs/DIAGNOSTICS.md`, the keyword and stdlib rows of `docs/STATUS.md` and the spec index `docs/specs/README.md` are generated. Regenerate after changing `DiagnosticCodes.cs`, a diagnostic page, `Keywords.cs`, `TokenKind.cs`, `BuiltinMembers.cs`, a spec header or the version:

```sh
bash scripts/docs/gen-diagnostics.sh --write   # docs/DIAGNOSTICS.md
bash scripts/docs/gen-status.sh --write        # docs/STATUS.md, between the <!-- generated: … --> markers
bash scripts/docs/gen-spec-index.sh --write    # docs/specs/README.md
```

All three generated docs are release docs: each generator writes the `Version:` and `Revisions applied:` header from `VERSION` and the highest revision; without `--write` it prints to stdout, sorted, undated.

<!-- prose-check: off -->
- `gen-diagnostics.sh` reads the diagnostic tables of `src/`, `scripts/docs/data/csharp-facts.tsv` (read once from the retired C# `DiagnosticCodes.cs`: its `// BYNnnnn is retired|reserved` comments and `// Reserved: round 4` block) and the hand-kept `docs/diagnostics-allocated.txt` (`plan|reserved|retired BYNnnnn Name-or-- note` per line: plan codes with no descriptor, reservations with none, retirements only in a page), and which `docs/diagnostics/BYNnnnn.md` pages exist. Edit `docs/diagnostics-allocated.txt` on a new allocation, reservation or retirement, then regenerate.
<!-- prose-check: on -->
<!-- prose-check: off -->
- `gen-status.sh` reads the `kw` and `mem` rows of `scripts/docs/data/csharp-facts.tsv` for keywords and stdlib members (extracted once from the retired C# `Keywords.cs`, `TokenKind.cs` and `BuiltinMembers.cs`).
<!-- prose-check: on -->
- `gen-spec-index.sh` reads each `docs/specs/NNN-*/NNN-spec.md` title and `Status:`, `Release:` and `Sources:` header lines, plus any plan, tasks and api files beside it. It fails on a Status that starts with none of `done`, `in progress`, `approved`, `open`, `deferred`, `draft`, `rejected` or `superseded`.

The feature, pattern, effect and unbuilt-keyword tables of `docs/STATUS.md` are hand-kept: change a status cell with the feature's status; `cut.sh` lists those in the CHANGELOG.

## What CI checks

The Linux job of `.github/workflows/ci.yml` (step "Docs and release script tests") runs `set-version.test.sh`, `cut.test.sh`, `scripts/docs/*.test.sh` and `bash scripts/docs/check.sh`; `package.test.sh` runs in step "Script tests" on Linux and macOS. `check.sh` prints one line per failure; among its checks, it fails when:

- (a) a release doc's `Version:` is not `Version: <VERSION> (matches \`bayan --version\`)`;
- (b) revisions do not run 0001 to the highest without gaps or repeats, or `Revisions applied:` is not the highest;
- (c) `docs/DIAGNOSTICS.md`, `docs/STATUS.md` or `docs/specs/README.md` differs from its generator;
- (d) a mirror's version differs from `VERSION`;
- (e) SPEC, GRAMMAR or STYLE has a `(not in A.B`/`(partial in A.B` tag whose `A.B` is not `VERSION`'s major.minor (`-dev` stripped);
- (h) a record doc lacks `Status:`, `Release:` or `Sources:` (a law, its `status:`, `release:` or `sources:` key), or its release is not a `## [X.Y.Z]` CHANGELOG version, `VERSION` or `unscheduled`; or a snapshot doc lacks `Snapshot:`;
- (i) a revision is not cited in `docs/bayan-feature-history.md`, or a numbered spec section has no `### §N.` row there (`scripts/docs/check-history.sh`).

So a new revision, a new diagnostic or a version change lands with its headers and generated docs in the same commit.

## Cutting a release

From `dev`, with `VERSION` at `X.Y.Z-dev` and `check.sh` passing.

1. **Cut.** Update `docs/bayan-roadmap.md` first (states, order, the `State of `dev` at <sha>, <date>.` line); `cut.sh` refuses a roadmap dated before the previous release. Then `bash scripts/release/cut.sh X.Y.Z`, which:
   - sets `VERSION`, mirrors and headers to `X.Y.Z`, `Revisions applied` at the highest;
   - regenerates the generated docs;
   - turns `## [Unreleased]` in `CHANGELOG.md` into `## [X.Y.Z] - <today>`, leaving `[Unreleased]` empty;
   - adds `### Revisions` (revision files since the last `v*` tag, the highest `vA.B.C` below `X.Y.Z`, reachable or not) and `### Status changes` (the hand-kept `docs/STATUS.md` rows whose status cell changed or that are new since it).

   It fails, before touching the CHANGELOG, if a tracked file still contains the previous `-dev` version (such as `1.2.0-dev`); prints each changed file and the new section; never commits, tags or pushes.
2. **Regenerate `bootstrap/bayan.c`** with `scripts/selfhost/land.sh`, so the bootstrap compiler reports the new version.
3. **Review.** Edit the CHANGELOG section (a summary, known limits). Run the tests, `bash scripts/docs/check.sh` and the memory gate (`bash scripts/release/memory-gate.sh`, `docs/memory-leaks.md`).
4. **Commit** the release as one commit and merge it to `main`.
5. **Dry run.** Run the release workflow by hand on that commit (Actions, `release`, Run workflow) with `dry_run: true`, version `X.Y.Z-rc.N`: every job but the draft. The release job refuses a `-rc` tag or dispatch (`scripts/release/refuse-draft.sh`), so no dry run drafts.
6. **Tag** that commit `vX.Y.Z` and push the tag.
7. **The workflow.** The tag starts `.github/workflows/release.yml`:
   - `package.sh check-tag` refuses a tag that is not `v` + `VERSION`, or a prerelease `VERSION`; `scripts/docs/check.sh` refuses a `VERSION` its mirrors do not match;
   - each target builds the self-hosted compiler (stage 1 from `bootstrap/bayan.c`, stage 2 from `src/driver`), smoke-tests `--version` and packs `bayan-X.Y.Z-<target>.tar.gz` (`.zip` on Windows); binary and `README.md` at the root, docs under `share/doc/bayan/`: `SPEC.md`, `GRAMMAR.md`, `STYLE.md`, `DIAGNOSTICS.md`, `STATUS.md`, `CHANGELOG.md`;
   - the memory gate runs on Linux and macOS; the editor gate (`bayan-lsp` memory tests, the extension under a size bound) on Linux; every enacted law's full tier (`laws-nightly.yml`, up to 180 minutes);
   - a red R27 run (diverse double-compiling) means its environment changed (SDK download, runner image): fix that and re-run; the release is not broken (decided 2026-11-17);
   - the release job adds `bayan-X.Y.Z-docs.tar.gz` (the six docs plus every other release doc at its `docs/` path, including `specs/README.md` and `bayan-feature-history.md`, under `bayan-X.Y.Z-docs/share/doc/bayan/`) and `SHA256SUMS`, and opens a draft GitHub Release with the CHANGELOG section as notes; while the major version is 0 it is a prerelease (`package.sh release-flags`; user, 2026-11-14).

   Publishing the draft is a manual step.
8. **PDFs.** Run `bash scripts/release/docs-pdf.sh` (needs Chrome, named by `CHROME`; `BAYAN` names the compiler running the book's examples, default the `HEAD` CLI of `scripts/pinned-bayan.sh`); attach `dist/bayan-manifesto-X.Y.Z.pdf` and `dist/bayan-book-X.Y.Z.pdf` to the GitHub release.
9. **Next dev version.** `bash scripts/release/next-dev.sh X.Y.(Z+1)` (or the next minor) sets `VERSION`, the mirrors and headers to `-dev`, and regenerates the generated docs. Then regenerate `bootstrap/bayan.c` and commit all of it as one commit on `dev`.

## Known limits

Until the per-phase arenas finish (Q31), the stage-2 build of `src/driver` peaks at 1.69 GB (macOS, 2026-11-14; 2.94 GB on 2026-11-12). `scripts/release/package.sh notes` prints that line after the CHANGELOG section, so every release carries it.

## Archive

Git tags are the archive: a release's docs are the files at its `vX.Y.Z` tag and its `bayan-X.Y.Z-docs.tar.gz`; past versions are not in the repo. `docs/export/` is a dated snapshot (821afa40), not shipped; `check.sh` checks only its `Snapshot:` line.
