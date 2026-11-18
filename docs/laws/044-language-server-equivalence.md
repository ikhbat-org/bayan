---
id: L044
title: Language server equivalence
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 019 R21
kind: property
scope: editors/language-server/src/**, editors/language-server/sessions/
proof: editors/language-server/sessions/l044.law.test.sh
check: bash editors/language-server/sessions/l044.law.test.sh
timeout: 900
---

## Statement
For every recorded session under `editors/language-server/sessions/`, the replies of the Bayān `bayan-lsp` equal the recorded replies, message for message.

## Counterexample looks like
A session file and the first request whose reply from the Bayān server differs from the recorded reply, or a reply that is missing or extra.

## Proof notes
Mutation: server.byn:1184 writeMarkup kind "markdown" -> "plaintext"; L044 failed with "session requests-tour: first difference at message 3,6c3,6" (1 of 53 sessions differ).

## History
Amended 2026-11-18 (spec 019 D13) to "the recorded replies". Enact when T37 lands.
