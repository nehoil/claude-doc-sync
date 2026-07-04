#!/usr/bin/env bash
# Git pre-commit hook logic: block a commit whose staged diff isn't reconciled
# with the docs. Mirrors the Claude PreToolUse gate, but fires for HUMAN (and
# any non-Claude) commits too. Signals via exit code: 0 = allow, 1 = block.
#
# Activated by a thin .git/hooks/pre-commit shim that execs this file (see
# install.sh --git-hook). Kept here (tracked) so the logic is versioned/shared;
# only the shim lives in the per-clone .git/hooks/.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=doc-sync-lib.sh
source "$HERE/doc-sync-lib.sh"

# Escape hatch. Env only: a pre-commit hook can't read the commit message, so
# the [skip-doc-sync] message token works via the Claude gate, not here.
[ "${DOC_SYNC:-}" = "0" ] && exit 0

# Nothing staged -> let git handle it (it blocks empty commits itself).
STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
[ -z "$STAGED" ] && exit 0

# Approved for this exact staged diff? (marker written by the doc-sync skill /
# approve.sh, hashing `git diff --cached` — same as the Claude gate.)
MARKER="$(doc_sync_marker_path || true)"
if [ -n "$MARKER" ] && [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$(doc_sync_staged_hash)" ]; then
  exit 0
fi

cat >&2 <<'MSG'
doc-sync: staged changes are not reconciled with the docs — commit blocked.
  • With Claude Code:  ask it to run the doc-sync skill, then commit.
  • By hand:           reconcile the docs, then run
                         .claude/skills/doc-sync/scripts/approve.sh
                       to approve this exact staged diff, and re-commit.
  • Urgent/hotfix:     DOC_SYNC=0 git commit ...
MSG
exit 1
