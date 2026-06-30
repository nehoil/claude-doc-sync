#!/usr/bin/env bash
# Run: bash tests/doc-sync/test_lib.sh
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
source "$ROOT/.claude/hooks/doc-sync-lib.sh"
PASS=0; FAIL=0
ok(){ echo "ok: $1"; PASS=$((PASS+1)); }
no(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

d="$(mktemp -d)"; git -C "$d" init -q
cd "$d"   # no subshell, so ok/no update the parent counters

[ -n "$(doc_sync_git_dir)" ] && ok "git_dir nonempty in repo" || no "git_dir"

h0="$(doc_sync_staged_hash)"
echo "x" > a.txt; git add a.txt
h1="$(doc_sync_staged_hash)"
{ [ -n "$h1" ] && [ "$h1" != "$h0" ]; } && ok "staged_hash changes on stage" || no "staged_hash"

case "$(doc_sync_marker_path)" in
  */doc-sync-approved) ok "marker path" ;;
  *) no "marker path" ;;
esac

echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]
