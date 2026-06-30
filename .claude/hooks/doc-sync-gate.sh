#!/usr/bin/env bash
# PreToolUse gate: block `git commit` of code changes until doc-sync has run.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=doc-sync-lib.sh
source "$HERE/doc-sync-lib.sh"

allow(){ exit 0; }   # silent = defer to normal permission flow
deny(){
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

INPUT="$(cat)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null || true

# 1. Only gate `git commit` (incl. amend). Everything else passes.
printf '%s' "$COMMAND" | grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+commit([^[:alnum:]_-]|$)' || allow

# 2. Escape hatch.
if printf '%s' "$COMMAND" | grep -q '\[skip-doc-sync\]' \
   || printf '%s' "$COMMAND" | grep -Eq '(^|[[:space:]])DOC_SYNC=0([[:space:]]|$)' \
   || [ "${DOC_SYNC:-}" = "0" ]; then allow; fi

# 3. -a / -am / --all stage at commit time and hide the change set from review.
#    Matches a short-flag cluster containing 'a' (-a, -am, -na…) or the long --all.
#    (A literal "-a" inside a commit message can false-positive; bypass with [skip-doc-sync].)
if printf '%s' "$COMMAND" | grep -Eq '(^|[[:space:]])-[a-z]*a[a-z]*([[:space:]]|$)' \
   || printf '%s' "$COMMAND" | grep -q -- '--all'; then
  deny "doc-sync: 'git commit -a/-am/--all' hides the change set. Stage explicitly with 'git add', then commit — or add [skip-doc-sync] to bypass."
fi

# 4. Nothing staged -> let git handle it.
STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
[ -z "$STAGED" ] && allow

# 5. Approved for this exact staged diff?
MARKER="$(doc_sync_marker_path || true)"
if [ -n "$MARKER" ] && [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$(doc_sync_staged_hash)" ]; then
  allow
fi

# 7. Gate closed.
deny "doc-sync: staged code changes are not reconciled with the docs. Invoke the doc-sync skill now — it analyzes the staged diff against the .md docs, offers Linear updates, and writes the approval marker. Do not retry the commit until it has run. Bypass with [skip-doc-sync] only for urgent/hotfix commits."
