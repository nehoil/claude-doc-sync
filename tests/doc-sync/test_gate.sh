#!/usr/bin/env bash
# Run: bash tests/doc-sync/test_gate.sh
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
GATE="$ROOT/.claude/hooks/doc-sync-gate.sh"
source "$ROOT/.claude/hooks/doc-sync-lib.sh"
PASS=0; FAIL=0

new_repo(){ local d; d="$(mktemp -d)"; git -C "$d" init -q;
  git -C "$d" config user.email t@t.t; git -C "$d" config user.name t; printf '%s' "$d"; }
run_gate(){ # cwd, command  -> gate stdout
  jq -n --arg c "$2" --arg w "$1" \
    '{tool_name:"Bash", cwd:$w, tool_input:{command:$c}}' | bash "$GATE"; }
check(){ # desc, want, gate-stdout
  local got
  if [ -z "$3" ]; then got="allow"   # silent gate output = allow
  else got="$(printf '%s' "$3" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' 2>/dev/null)"; fi
  [ -z "$got" ] && got="allow"
  if [ "$got" = "$2" ]; then echo "ok: $1"; PASS=$((PASS+1));
  else echo "FAIL: $1 (want $2 got $got)"; FAIL=$((FAIL+1)); fi; }
seed_marker(){ ( cd "$1"; doc_sync_staged_hash > "$(doc_sync_marker_path)" ); }

R="$(new_repo)"

# 1. non-commit allowed
check "non-commit allowed" allow "$(run_gate "$R" 'git status')"

# 5. docs-only allowed
( cd "$R"; echo a > README.md; git add README.md )
check "docs-only allowed" allow "$(run_gate "$R" 'git commit -m docs')"

# 7. code change denied (no marker)
( cd "$R"; echo 'print(1)' > app.py; git add app.py )
check "code denied (no marker)" deny "$(run_gate "$R" 'git commit -m feat')"

# 2. skip token bypasses
check "skip token allows" allow "$(run_gate "$R" 'git commit -m "feat [skip-doc-sync]"')"
# 2. DOC_SYNC inline bypasses
check "DOC_SYNC=0 inline allows" allow "$(run_gate "$R" 'DOC_SYNC=0 git commit -m feat')"

# 3. -a denied
check "-a denied" deny "$(run_gate "$R" 'git commit -a -m feat')"
# 3. -am (combined) denied
check "-am denied" deny "$(run_gate "$R" 'git commit -am feat')"
# 3. --all denied
check "--all denied" deny "$(run_gate "$R" 'git commit --all -m feat')"

# 6. marker match allows
seed_marker "$R"
check "marker match allows" allow "$(run_gate "$R" 'git commit -m feat')"
# 6b. stage more -> marker stale -> denied
( cd "$R"; echo 'print(2)' > app2.py; git add app2.py )
check "new stage re-closes gate" deny "$(run_gate "$R" 'git commit -m feat')"

# E2E: deny -> approve.sh -> allow, for the same staged diff.
E="$(new_repo)"
( cd "$E"; echo 'print(3)' > svc.py; git add svc.py )
check "e2e: denied before approve" deny "$(run_gate "$E" 'git commit -m feat')"
( cd "$E"; bash "$ROOT/.claude/skills/doc-sync/scripts/approve.sh" >/dev/null 2>&1 )
check "e2e: allowed after approve" allow "$(run_gate "$E" 'git commit -m feat')"

echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]
