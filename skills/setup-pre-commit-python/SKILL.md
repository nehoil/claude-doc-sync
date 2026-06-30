---
name: setup-pre-commit-python
description: Set up Python pre-commit hooks using the `pre-commit` framework with ruff (lint + format) and pyright (type check) in the current repo. Use when user wants to add Python pre-commit hooks, set up ruff, set up pyright, or configure commit-time linting/formatting/type-checking for a Python project. Distinct from the Husky/JS `setup-pre-commit` skill.
---

# Setup Python Pre-Commit Hooks

## What This Sets Up

- **pre-commit** framework (Python, https://pre-commit.com)
- **ruff** hook (lint with `--fix`) and **ruff-format** hook
- **pyright** as a local system hook, run via the repo's package manager

## Steps

### 1. Detect the package manager

Check in order:

- `uv.lock` or `[tool.uv]` in `pyproject.toml` → **uv**
- `poetry.lock` or `[tool.poetry]` in `pyproject.toml` → **poetry**
- otherwise → **pip** (plain venv)

This decides the `pyright` entry below.

### 2. Write `.pre-commit-config.yaml`

If the file already exists, diff against the target and only add hooks that are missing (do NOT overwrite). Otherwise create it fresh.

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: local
    hooks:
      - id: pyright
        name: pyright
        entry: uv run pyright
        language: system
        pass_filenames: false
        types: [python]
```

**Adapt the pyright `entry`** based on detection in step 1:

| Manager | `entry` |
|---------|---------|
| uv      | `uv run pyright` |
| poetry  | `poetry run pyright` |
| pip     | `pyright` |

### 3. Ensure pyright is a dev dependency

Check `pyproject.toml` / `requirements-dev.txt` for `pyright`. If missing, tell the user to add it:

| Manager | Command |
|---------|---------|
| uv      | `uv add --dev pyright` |
| poetry  | `poetry add --group dev pyright` |
| pip     | `pip install pyright` (or add to `requirements-dev.txt`) |

### 4. Ensure `pre-commit` is installed and activated

Tell the user to run (only the ones they don't already have):

```bash
# install the pre-commit tool itself, if missing
uv tool install pre-commit          # uv users
pipx install pre-commit             # or pipx
pip install pre-commit              # or pip

# wire it into .git/hooks/pre-commit
pre-commit install
```

### 5. Verify

- [ ] `.pre-commit-config.yaml` exists with both ruff hooks + pyright
- [ ] `pyright` resolves under the chosen package manager
- [ ] `pre-commit run --all-files` passes (or surfaces real findings to fix)

### 6. Commit

Stage `.pre-commit-config.yaml` (and any `pyproject.toml` / lockfile changes from adding pyright) and commit with: `Add pre-commit hooks (ruff + pyright)`.

The commit itself runs through the new hooks — smoke test.

## Notes

- `ruff` covers both linting and formatting; no need for black + isort + flake8.
- `pyright` is a local hook (not from a remote repo) because it needs the project's resolved environment to type-check correctly. `pass_filenames: false` makes it type-check the whole project on each invocation rather than only staged files.
- `rev: v0.6.9` is pinned to match the source repo. Bump with `pre-commit autoupdate` when desired.
- This is the **Python** pre-commit setup. For the JS/Husky version, use the sibling `setup-pre-commit` skill.
