# setup-pre-commit-python

Claude Code plugin that scaffolds a Python `pre-commit` setup in the current repo: **ruff** (lint + format) and **pyright** (type-check), wired into the `pre-commit` framework.

## What it sets up

A `.pre-commit-config.yaml` containing:

- `ruff` with `--fix` (lint)
- `ruff-format` (format)
- `pyright` as a local system hook, run through the repo's package manager (uv / poetry / pip)

Plus reminders to install `pre-commit` itself and to add `pyright` as a dev dependency if missing.

## Install

Drop the plugin into the Claude Code plugins cache and reload Claude Code. One option:

```bash
unzip setup-pre-commit-python-plugin.zip -d ~/.claude/plugins/cache/
```

After that the `setup-pre-commit-python` skill should be available. Invoke by asking Claude things like "set up Python pre-commit hooks here" / "add ruff and pyright pre-commit hooks".

> Note: the exact destination directory layout under `~/.claude/plugins/` may differ depending on how you manage plugins (marketplace install vs. local drop-in). If unsure, the simplest path is to copy the contents of `skills/setup-pre-commit-python/` into `~/.claude/skills/setup-pre-commit-python/` — that registers it as a standalone skill regardless of plugin wiring.

## Usage

In any Python repo, ask Claude:

> "Set up Python pre-commit hooks."

The skill will:

1. Detect `uv` / `poetry` / `pip`.
2. Write `.pre-commit-config.yaml` (or merge missing hooks if one already exists).
3. Tell you exactly how to install `pre-commit` and `pyright` for your stack.
4. Tell you to run `pre-commit install` and commit.

## Why not Husky?

Husky / lint-staged is the JS-world tool. For Python, the `pre-commit` framework (https://pre-commit.com) is the standard. Use the sibling `setup-pre-commit` skill for JS repos.

## License

MIT
