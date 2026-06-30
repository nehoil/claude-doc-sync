# Path → doc relevance map ({{REPO_NAME}})

> **Per-repo template.** Fill in `{{...}}` placeholders + the table rows below
> for *this* repo. The `doc-sync` skill reads this file to decide which `.md`
> docs to inspect for each staged code path. Keep it short — only entries that
> earn their keep.

Always-on (check on any code commit): {{ALWAYS_ON_DOCS}}
<!-- e.g. `CLAUDE.md`, `TODO.md`, `README.md`, `CONTEXT.md` -->

| Changed path (glob) | Candidate docs / sections |
|---------------------|---------------------------|
| `src/example.py`    | `ARCHITECTURE.md` (the relevant section); `docs/adr/NNNN-xxx.md` |
| `src/another/**`    | `README.md` (subsystem overview) |

If a changed path is unmapped, check the always-on set and report the unmapped
path so this map can be extended.

## Linear settings (used by step 4 of the skill)

- `LINEAR_ISSUE_PREFIX`: `{{LINEAR_ISSUE_PREFIX}}`  <!-- e.g. `GRO` so branches like `gro-123-foo` match -->
- `LINEAR_PROJECT_NAME`: `{{LINEAR_PROJECT_NAME}}`
- `LINEAR_PROJECT_ID`:   `{{LINEAR_PROJECT_ID}}`
- `LINEAR_TEAM`:         `{{LINEAR_TEAM}}`
- `LINEAR_MILESTONE`:    `{{LINEAR_MILESTONE}}`  <!-- optional, delete line if unused -->
