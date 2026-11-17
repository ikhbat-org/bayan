---
id: L044
title: Language server equivalence
status: proposed
release: unscheduled
sources: spec 019 R21
kind: property
scope: editors/language-server/src/**, editors/language-server/sessions/
---

## Statement
For every recorded session under `editors/language-server/sessions/`, the replies of the Bayān `bayan-lsp` equal the replies the C# server recorded at the freeze, message for message.

## Counterexample looks like
A session file and the first request whose reply from the Bayān server differs from the recorded reply, or a reply that is missing or extra.
