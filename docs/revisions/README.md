# Revisions

After round 3's documentation deliverables, `docs/bayan-spec.md`, `docs/bayan-grammar.md` and `docs/bayan-style.md` change only through a numbered revision here (HANDOFF round 3 §32).

- File: `NNNN-title.md`, four digits, next = highest + 1, kebab-case title.
- Sections: **Problem**, **Decision**, **Sections** (spec sections changed), **Codes** (diagnostics added, changed, retired), **Sūq files** (affected or added; a revision that adds a feature adds its Sūq use), and, when it amends a design document, **Effect on work already done** and the **Diff**.
- A revision is applied to the spec in one commit; the file stays as the record.
- The agent never changes the frozen documents on its own: a conflict it finds becomes a draft revision (`Status: draft`) for the user to accept.
- New features are built from the current design documents; a revision's diff drives the changes to features already built.
- An erratum (a counting or wording error that leaves the decision's meaning unchanged) is fixed in place, with a line in the status: `Erratum (YYYY-MM-DD): …` saying what was corrected. Keep the original text beside the correction only when the meaning changes; then it is a new revision, not an erratum.
- Precedence (revision 0022): an unapplied revision outranks the SPEC text it changes. Addenda, drafts, plans and owner decisions take effect when a revision records them. Between two revisions, the later one wins. Addenda folded before revision 0022 (handoff addenda 001 and 002, design round 3 addendum 1) stay as applied.
- Compatibility (revision 0022): adding or narrowing an `expects` or `requires` on a released public function or type is a breaking change (SPEC §19.4).
- Syntax freeze (revision 0023): until the 0.3.0 release tag exists, no revision adds, removes or renames a keyword, operator, clause or grammar form; 0024 (numeric conversions) is the last one admitted. Errata, status tags, consistency fixes and removals of unbuilt text are allowed.
