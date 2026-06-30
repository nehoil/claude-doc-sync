#!/usr/bin/env bash
# Install claude-doc-sync into a target repo.
#
# Usage:
#   ./install.sh                    # install into $PWD
#   ./install.sh /path/to/repo      # install into a specific repo
#
# Idempotent: existing files are left untouched (re-running prints a status report).
# Refuses to overwrite — to upgrade an existing install, delete the relevant
# files first and re-run.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TGT="${1:-$PWD}"

if [ ! -d "$TGT/.git" ]; then
  echo "install.sh: target '$TGT' is not a git repo (no .git/ dir). Aborting." >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "install.sh: 'jq' is required (the gate uses it at runtime too). Install jq and retry." >&2; exit 1; }

copy_if_missing() {
  local rel="$1"
  local src="$SRC/$rel"
  local dst="$TGT/$rel"
  if [ -e "$dst" ]; then
    echo "  exists, kept: $rel"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  case "$rel" in *.sh) chmod +x "$dst" ;; esac
  echo "  copied:       $rel"
}

echo "Installing claude-doc-sync into: $TGT"

copy_if_missing .claude/hooks/doc-sync-gate.sh
copy_if_missing .claude/hooks/doc-sync-lib.sh
copy_if_missing .claude/skills/doc-sync/SKILL.md
copy_if_missing .claude/skills/doc-sync/path-doc-map.md
copy_if_missing .claude/skills/doc-sync/scripts/approve.sh

SETTINGS="$TGT/.claude/settings.json"
EXAMPLE="$SRC/settings.example.json"

if [ ! -f "$SETTINGS" ]; then
  mkdir -p "$(dirname "$SETTINGS")"
  cp "$EXAMPLE" "$SETTINGS"
  echo "  created:      .claude/settings.json"
else
  # Merge the doc-sync gate into existing settings.json without clobbering other hooks.
  if jq -e '.hooks.PreToolUse // [] | map(.hooks[]?.command // "" | contains("doc-sync-gate.sh")) | any' "$SETTINGS" >/dev/null; then
    echo "  exists, kept: .claude/settings.json (doc-sync-gate already registered)"
  else
    TMP="$(mktemp)"
    jq --slurpfile add "$EXAMPLE" '
      .hooks = (.hooks // {})
      | .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $add[0].hooks.PreToolUse)
    ' "$SETTINGS" > "$TMP"
    mv "$TMP" "$SETTINGS"
    echo "  merged:       .claude/settings.json (added doc-sync-gate PreToolUse hook)"
  fi
fi

cat <<EOF

Done. Next steps:

  1. Edit  .claude/skills/doc-sync/path-doc-map.md  — fill in the {{...}}
     placeholders with this repo's actual docs + Linear settings.
  2. Edit  .claude/skills/doc-sync/SKILL.md         — same; or leave the
     {{...}} placeholders if you want Linear-side writes disabled.
  3. Restart Claude Code in this repo so the PreToolUse hook is picked up.
  4. Test:  stage a code change, ask Claude to commit. The gate should block
     and tell Claude to run the doc-sync skill.

EOF
