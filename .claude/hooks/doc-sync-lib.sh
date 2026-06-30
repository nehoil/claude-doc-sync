#!/usr/bin/env bash
# Shared helpers for the doc-sync commit gate. Sourced by the gate and approver.

doc_sync_git_dir() {
  # Absolute so the marker resolves to the same file regardless of CWD.
  git rev-parse --absolute-git-dir 2>/dev/null
}

doc_sync_staged_hash() {
  git diff --cached 2>/dev/null | sha256sum | awk '{print $1}'
}

doc_sync_marker_path() {
  local gd
  gd="$(doc_sync_git_dir)" || return 1
  [ -n "$gd" ] || return 1
  printf '%s/doc-sync-approved\n' "$gd"
}
