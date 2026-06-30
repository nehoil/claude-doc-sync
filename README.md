# claude-doc-sync

A Claude Code `PreToolUse` hook + companion skill that **gates every `git commit`
of code on a docs-and-Linear reconciliation step**.

When Claude tries to `git commit` a code change, the gate intercepts the tool
call and denies it with an instruction: *"run the `doc-sync` skill first"*. The
skill reads the staged diff, walks the repo's `.md` docs (per a per-repo path
map), surfaces drift, offers Linear updates, and only on completion writes an
approval marker keyed to the exact staged diff. The next `git commit` is then
allowed through.

Designed for Claude-driven workflows where Claude is the one running `git
commit` — it leans on Claude reading the gate's denial message and routing
itself into the skill.

## What's in the box

```
.claude/
├── hooks/
│   ├── doc-sync-gate.sh       # PreToolUse hook — blocks code commits w/o approval
│   └── doc-sync-lib.sh        # shared marker helpers
└── skills/
    └── doc-sync/
        ├── SKILL.md           # the skill Claude runs when the gate blocks
        ├── path-doc-map.md    # per-repo: which docs each code path touches
        └── scripts/
            └── approve.sh     # marker writer (skill calls this when done)
settings.example.json          # snippet to merge into .claude/settings.json
install.sh                     # one-shot installer
tests/doc-sync/                # gate + lib tests
```

## Install

```bash
git clone https://github.com/nehoil/claude-doc-sync.git /tmp/claude-doc-sync
bash /tmp/claude-doc-sync/install.sh /path/to/your/repo
```

(or run `./install.sh` from inside a clone, defaults to `$PWD`).

The installer copies the hook + skill files in, then merges
`settings.example.json` into the target repo's `.claude/settings.json` (or
creates one). Idempotent — existing files are kept.

Requires `jq` (the gate uses it at runtime; the installer uses it for the
settings merge).

## Configure per repo

After install, two files need editing:

1. **`.claude/skills/doc-sync/path-doc-map.md`** — fill in the `{{...}}`
   placeholders: which docs are "always-on" for this repo, and which code paths
   map to which docs. Also the Linear project / team / issue-key prefix.
2. **`.claude/skills/doc-sync/SKILL.md`** — the same Linear placeholders are
   referenced here for the Linear lookup step. Leave them as `{{...}}` if you
   want the skill to skip Linear writes (it'll print intended actions instead).

## How the gate works

The gate is a Claude Code `PreToolUse` Bash hook (registered in
`.claude/settings.json`). On every Bash tool call it:

1. Allows anything that isn't `git commit` (incl. `git commit --amend`).
2. Allows if the commit message contains `[skip-doc-sync]`, or `DOC_SYNC=0`
   is set inline / in env (emergency hotfix bypass).
3. **Denies** `git commit -a / -am / --all` — those stage at commit time and
   hide the change set from the skill.
4. Allows if nothing is staged (let git report the empty commit).
5. Allows if a marker file (`<git-dir>/doc-sync-approved`) exists and its
   contents match a sha256 of the current staged diff.
6. Otherwise **denies** with a message telling Claude to run the `doc-sync`
   skill.

The marker is keyed to the *exact* staged diff (`git diff --cached | sha256sum`),
so staging anything new after approval re-closes the gate. The marker lives in
`.git/`, which is local-only and never committed.

## Tests

```bash
cd /path/to/an/installed/repo
bash tests/doc-sync/test_lib.sh
bash tests/doc-sync/test_gate.sh
```

The tests spin up disposable git repos in `$TMPDIR` and exercise the allow /
deny paths against the gate stdin contract.

## Limits / honest caveats

- **Claude-driven workflows only.** A human committing from a terminal sees the
  denial, has to manually run the approve script (or invoke the skill via
  `/doc-sync`). It's not designed for human commit ergonomics.
- **No marketplace install.** This isn't a Claude Code plugin in the formal
  sense — there's no `plugin.json`, it doesn't show up under `/plugin install`.
  It's a copy-in repo. If you want plugin-style packaging, fork it.
- **Linear MCP optional.** The skill checks if Linear is reachable and degrades
  gracefully (prints intended writes) if not. The gate itself never touches
  Linear.
- **`jq` is a hard runtime dep** (the gate parses its stdin with jq).

## License

MIT.
