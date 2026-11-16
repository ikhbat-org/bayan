# Every doc is versioned, specs are indexed, and features keep their history

Status: done (decided 2026-11-14)
Release: 0.3.0
Sources: user, 2026-11-14 ("all docs, not just spec, style and status, should be versioned … we should be able to understand where a feature came from and why a feature wasn't implemented or why a feature was changed"); extends revision 0020; plan `docs/plans/2026-11-14-016-versioned-docs-and-provenance.md`.

## Decision
1. **Three kinds of doc.**
   - **Release docs** describe the software at a version and carry `Version: X.Y.Z (matches \`bayan --version\`)`. Every release bumps them.
   - **Record docs** are specs, plans, decisions, revisions, audits, laws and the progress log. Each carries `Status:`, `Release:` and `Sources:`. Its body is history and is not rewritten.
   - **Snapshot docs** carry `Snapshot: <date>; not maintained`.
2. **Spec index.** `docs/specs/README.md` is generated from spec headers. It lists every feature spec as built, in progress, to be built (with a target release) or rejected.
3. **Feature history.** `docs/bayan-feature-history.md` gives each SPEC section its origin, every change with the revision and reason, the release it was built in, and the rejected features with reasons. A new revision adds its row in the same commit.
4. **Guards.** `scripts/docs/check.sh` enforces 1–3, so a release cannot ship a doc that names another version or a feature with no trail.
5. **Archive.** Git tags stay the archive, and past versions are not copied into the repo. The docs archive of each release ships every release doc.

## Rejected
- **Per-version copies of the docs in the repo** (`docs/0.3/…`). Tags and the release docs archive already freeze them, and copies drift.
- **A version header on record docs.** A plan or a decision belongs to the release it targeted or shipped in (`Release:`). Bumping it every release would rewrite history.
