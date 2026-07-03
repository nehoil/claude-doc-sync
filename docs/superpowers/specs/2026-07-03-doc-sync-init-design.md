# doc-sync init — design

## Problem

`claude-doc-sync` keeps `.md` docs in sync with code via a commit gate, but it
assumes the docs already exist. A fresh repo has nothing to sync. There's no
standard way to bootstrap a documentation baseline, so every repo hand-rolls its
docs (and its `path-doc-map.md`) from scratch.

## Goal

Add an `init` capability that scaffolds a **standard documentation baseline** for
a repo — real first-draft docs generated from the codebase, plus a wired-up
`path-doc-map.md` — so the gate has something meaningful to reconcile from day one.

## Non-goals

- No empty/`{{placeholder}}` template files (they rot and immediately become drift
  — the exact thing the gate exists to prevent).
- No configurable doc set — the canonical set is fixed at four (below).
- No `DESIGN.md` (overlaps `ARCHITECTURE.md`).
- No auto-commit — the existing gate handles committing when the user commits.

## Canonical doc set

Four docs, each with one distinct purpose:

| Doc | Purpose | Audience |
|-----|---------|----------|
| `README.md` | What it is, install, how to run, contribute | Humans |
| `CLAUDE.md` | Conventions, "read this first", gotchas; loaded every session | Agents |
| `ARCHITECTURE.md` | Components, data flow, structure — how it's built | Both |
| `CONTEXT.md` | Domain glossary + key decisions (ADRs live in `docs/adr/`) | Both |

## Mechanism

A **new user-invocable skill, `doc-sync-init`** (separate from the `doc-sync`
gate skill — one-time bootstrap vs. recurring reconciliation are different jobs).
It is an LLM-driven skill because generating real doc content requires reading and
understanding the repo; the shell `install.sh` cannot do this.

`install.sh` copies the new skill in and its next-steps output tells the user to
run `/doc-sync-init`.

## Behavior (skill steps)

1. **Survey the repo** — languages, entry points, directory structure, package
   manifests, existing docs, README if present.
2. **Generate first drafts** of the four canonical docs. For each:
   - If the file **already exists, skip it** and report (never clobber). Idempotent
     and safe to re-run.
   - `CONTEXT.md`: if the project has no real domain language, write a short stub
     header pointing at `docs/adr/` rather than inventing a glossary.
3. **Wire up `path-doc-map.md`**:
   - Set the always-on list to the canonical docs that now exist.
   - Draft a starter `path → docs` table inferred from the repo's top-level layout.
   - Leave the Linear section as-is (its own configuration concern).
4. **Report**: list files created vs. skipped; confirm `path-doc-map.md` has no
   remaining `{{placeholders}}`.

## Verification

Doc *content* is LLM-generated and non-deterministic, so there is no unit test for
quality. The check is the skill's own end-of-run report (created/skipped +
placeholder-free map). If any never-clobber or map-wiring logic lands in a shell
script, it gets a shell test mirroring the existing `tests/doc-sync/` style;
otherwise no new automated test is added (the logic lives in the skill prose).

## Files touched

- `.claude/skills/doc-sync-init/SKILL.md` — new skill (the bulk of the work).
- `install.sh` — copy the new skill dir; update next-steps to mention `/doc-sync-init`.
- `README.md` — document `init` under a new section.
