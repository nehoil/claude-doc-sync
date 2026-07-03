---
name: doc-sync-init
description: Scaffold a standard documentation baseline (README, CLAUDE, ARCHITECTURE, CONTEXT) by reading the repo and writing real first drafts, then wire up path-doc-map.md so the doc-sync commit gate has something meaningful to reconcile. Use once when bootstrapping docs in a repo, or run again to fill in any of the four that are missing.
user-invocable: true
disable-model-invocation: false
---

# doc-sync-init

You were invoked to scaffold a repo's **standard documentation baseline** and wire
it into the doc-sync commit gate. Unlike a template dump, you generate *real*
first-draft docs by reading the actual code — the way a good `/init` does. Work
through these steps in order.

> **Never clobber.** For every file below, if it already exists, leave it exactly
> as-is and just report it. This skill is idempotent — re-running it only fills in
> what's missing. You edit `path-doc-map.md` (step 4) regardless.

## 1. Survey the repo
Build an accurate picture before writing a word:
- Languages, frameworks, and package manifests (`package.json`, `pyproject.toml`,
  `go.mod`, `Cargo.toml`, etc.) — name, scripts, dependencies, entry points.
- Directory structure (top two levels) and where the real code lives.
- How it's run/built/tested (scripts, Makefile, CI config, Dockerfile).
- Any docs that already exist — read them; do not contradict or duplicate them.
If the repo is nearly empty or you can't tell what it does, ask the user rather
than inventing content.

## 2. Generate the four canonical docs
Write a real first draft of each (skip any that already exist — see the clobber
rule). Keep each focused on its distinct purpose; do not let them overlap.

- **`README.md`** — human-facing. What the project is and why, install, how to run,
  how to contribute. The one a newcomer reads first.
- **`CLAUDE.md`** — agent-facing working notes loaded every session. Conventions,
  "read this first" rules, structure rules, gotchas, how to run the tests. Written
  as instructions to a future agent, not marketing.
- **`ARCHITECTURE.md`** — how it's built. Components and their responsibilities,
  data flow, key modules, and the boundaries between them. Distinct from README
  (which is how to *use* it).
- **`CONTEXT.md`** — domain glossary + key decisions. Define the project's real
  terms and the reasoning behind non-obvious choices. **If the project has no real
  domain language** (e.g. a small generic utility), write a short stub: a one-line
  header and a pointer to `docs/adr/` for future decision records — do not invent a
  glossary to fill space.

Draft from evidence in the code, not guesses. Where you're genuinely unsure, write
a clearly-marked `> TODO:` line for the user rather than a confident fabrication.

## 3. Confirm with the user
Show which files you created vs. skipped, and offer to adjust any draft before
moving on. Apply edits they request.

## 4. Wire up `path-doc-map.md`
This is what makes the gate useful immediately. Edit
`.claude/skills/doc-sync/path-doc-map.md` (create it from the doc-sync template if
absent):
- Set the **always-on** list to the canonical docs that now exist in the repo.
- Draft a starter **path → docs** table mapping the repo's real top-level code
  paths to the docs they affect (e.g. `src/api/** → ARCHITECTURE.md`).
- Fill `{{REPO_NAME}}`. Leave the **Linear** section alone — that's a separate
  configuration concern the user handles if they use Linear.
- After editing, confirm no `{{...}}` placeholders remain **except** the Linear
  ones (which are intentionally optional).

## 5. Report
Summarize: files created, files skipped (already existed), and that
`path-doc-map.md` is wired to the canonical set. Remind the user that from here the
doc-sync gate keeps these docs reconciled on every code commit. Do **not** commit —
the gate handles that when the user next commits.
