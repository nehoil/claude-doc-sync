#!/usr/bin/env bash
# Run: bash tests/doc-sync/test_pre_commit.sh
# Exercises the git pre-commit hook logic (exit code: 0 allow, 1 block).
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
HOOK="$ROOT/.claude/hooks/doc-sync-pre-commit.sh"
source "$ROOT/.claude/hooks/doc-sync-lib.sh"
PASS=0; FAIL=0

new_repo(){ local d; d="$(mktemp -d)"; git -C "$d" init -q;
  git -C "$d" config user.email t@t.t; git -C "$d" config user.name t; printf '%s' "$d"; }
run(){ local d="$1"; shift; ( cd "$d"; env "$@" bash "$HOOK" >/dev/null 2>&1 ); echo $?; }
check(){ if [ "$3" = "$2" ]; then echo "ok: $1"; PASS=$((PASS+1));
  else echo "FAIL: $1 (want $2 got $3)"; FAIL=$((FAIL+1)); fi; }
seed_marker(){ ( cd "$1"; doc_sync_staged_hash > "$(doc_sync_marker_path)" ); }

R="$(new_repo)"

# nothing staged -> allow
check "nothing staged allowed" 0 "$(run "$R")"

# staged code, no marker -> block
( cd "$R"; echo 'print(1)' > app.py; git add app.py )
check "staged no marker blocked" 1 "$(run "$R")"

# .md is gated too (no auto-trust)
( cd "$R"; git reset -q; echo x > README.md; git add README.md )
check "staged docs no marker blocked" 1 "$(run "$R")"

# DOC_SYNC=0 bypass -> allow
check "DOC_SYNC=0 allows" 0 "$(run "$R" DOC_SYNC=0)"

# marker matching the exact staged diff -> allow
seed_marker "$R"
check "marker match allows" 0 "$(run "$R")"

# stage more -> marker stale -> block
( cd "$R"; echo 'print(2)' > app2.py; git add app2.py )
check "new stage re-blocks" 1 "$(run "$R")"

echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]
