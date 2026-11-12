#!/usr/bin/env bash
# The release job's guard (.github/workflows/release.yml): a draft GitHub Release is made only from a pushed v* tag
# that is not a release candidate. Exit 0 to go on, 1 with a message to stop.
#   refuse-draft.sh <tag> <event_name>
set -euo pipefail

tag="${1:?usage: refuse-draft.sh <tag> <event_name>}"; event="${2:?usage: refuse-draft.sh <tag> <event_name>}"
case "$tag" in *-rc*) echo "release: refusing to draft $tag: a release candidate is never released (dry run only)" >&2; exit 1 ;; esac
[ "$event" = push ] || { echo "release: refusing to draft from a $event run: only a pushed tag drafts a release" >&2; exit 1; }
