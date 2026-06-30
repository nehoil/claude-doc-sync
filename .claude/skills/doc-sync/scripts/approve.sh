#!/usr/bin/env bash
# Write the doc-sync approval marker for the current staged diff (of the CWD repo).
# Called by the doc-sync skill AFTER reconciliation + re-staging.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Lib lives at .claude/hooks/ — resolve relative to THIS script, not the target repo.
source "$HERE/../../../hooks/doc-sync-lib.sh"
MARKER="$(doc_sync_marker_path)" || { echo "doc-sync: not a git repo" >&2; exit 1; }
doc_sync_staged_hash > "$MARKER"
echo "doc-sync: approved $(cat "$MARKER")"
