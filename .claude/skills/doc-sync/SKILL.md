---
name: doc-sync
description: Reconcile staged code changes with the repo's .md docs and offer Linear updates, then approve the commit. Invoke when the doc-sync commit gate blocks a git commit, or to manually sync docs before committing.
user-invocable: true
disable-model-invocation: false
---

# doc-sync

You were invoked because a `git commit` of code changes must be reconciled with
the docs before it lands (or the user asked to sync docs). Work through these
steps. Every doc edit and every Linear write is **offered**, not forced — the
user approves each. When done, you MUST run `scripts/approve.sh` so the commit
gate opens.

## 1. Read the change set
- `git diff --cached --name-only` and `git diff --cached`.
- If nothing is staged, or every staged path ends in `.md`, there is nothing to
  reconcile — run `scripts/approve.sh` and tell the user it's clear. Stop.

## 2. Scope the docs
- Read `path-doc-map.md` (next to this file). For each staged code path, collect
  its candidate docs plus the always-on set. Read only those docs.
- If `path-doc-map.md` is the unedited template (`{{REPO_NAME}}` / `{{...}}`
  placeholders present), tell the user the map hasn't been filled in for this
  repo yet — offer to draft one from the repo's actual file layout, then stop
  until they approve it.

## 3. Detect drift
For each candidate doc/section, judge whether the staged change **contradicts**,
**outdates**, or **should extend** it. Be specific and conservative — cite the
doc + section and the exact lines the change affects. Produce a short findings
list: `{doc, section, drift_type, suggested_edit}`. If you find none, say so.

## 4. Map to Linear
- Current branch: `git rev-parse --abbrev-ref HEAD`. Parse the configured issue
  key pattern from it (default: `{{LINEAR_ISSUE_PREFIX}}-\d+`, e.g. `GRO-\d+`)
  → the primary related issue.
- If no branch match, search Linear for a keyword/area match. Configured
  defaults for this repo:
  - Linear project: `{{LINEAR_PROJECT_NAME}}` (id `{{LINEAR_PROJECT_ID}}`)
  - Team: `{{LINEAR_TEAM}}`
  - Milestone (optional): `{{LINEAR_MILESTONE}}`
- If any of those placeholders are still literal `{{...}}`, treat the Linear
  step as unconfigured — skip writes, print intended actions for manual
  follow-up, and continue. Never block on it.

## 5. Present + apply (each item approved by the user)
Offer, and on approval apply:
- **Doc edits** — edit the `.md` files, then `git add` them (they ride in THIS commit).
- **Linear comment** — on the related issue: what changed, files/docs, commit intent.
- **Linear status** — move the issue (e.g. Todo→In Progress, →Done) when the diff implements/completes it.
- **New Linear issue** — when the change introduces new deferred work / a new TODO / drift the user defers.
If the Linear MCP is unavailable, skip the Linear writes, print the intended
actions for manual follow-up, and continue — never block on it.

## 6. Approve
Run: `bash .claude/skills/doc-sync/scripts/approve.sh`
This writes the marker for the **current** staged diff (including any doc edits
you just staged). Then tell the user they can retry the commit.

> The marker is keyed to the exact staged diff. If you stage anything after
> approving, the gate re-closes and you must re-run this skill.
