# CLAUDE.md — claude-doc-sync

## Commit hygiene — no throwaway scratch in git

Don't commit throwaway planning scratch: brainstorming notes,
agent/superpowers-generated intermediate design specs, ephemeral per-task
working `.md`. Those stay local. Only commit `.md` that is durable, curated
documentation (README, ARCHITECTURE, CONTEXT, ADRs, real PRDs). The line is
nature — throwaway vs curated — not cadence: a per-decision ADR is fine; a
per-task design note is not. Unsure? Ask before staging.

`docs/superpowers/` is gitignored (global + here) for exactly this reason. This
rule is the backstop for scratch paths that aren't yet ignored.

## Testing

`bash tests/doc-sync/test_gate.sh` and `bash tests/doc-sync/test_lib.sh` and
`bash tests/doc-sync/test_pre_commit.sh` — all must pass. jq is required.
