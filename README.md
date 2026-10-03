# initial_setup

The team's living starter kit. It holds every tool, plugin and skill we use, the reason for each, and scripts that install and verify them on a new Mac.

## One command

```bash
# First time on a new Mac
git clone https://github.com/daiwiksaimangalagiri-dsm/initial_setup.git ~/initial_setup && ~/initial_setup/setup.sh

# Then, inside any repo
initial-setup
```

It installs anything missing (tools, plugins, MCP servers, skills, session defaults), sets up the current repo, and checks it all. A clean run ends with `Failed: 0`.

## What's inside

| Path | What it is |
|------|------------|
| [`docs/intitial_setup.md`](docs/intitial_setup.md) | **Tools:** every installation with what it is, why we need it, what it's used for, and how to verify it |
| [`docs/skills.md`](docs/skills.md) | **Skills:** catalog of custom and plugin skills, and how to add or remove them |
| [`CHANGELOG.md`](CHANGELOG.md) | **History:** dated record of every addition, update and removal |
| `setup.sh` (`initial-setup`) | The one command: install → set up repo → verify |
| `scripts/install.sh` | Machine install (`--update-skills` to pull skill changes) |
| `scripts/project-setup.sh [dir]` | Repo setup: `CLAUDE.md`, `.mcp.json`, `.gitignore`, ruflo, commit-msg hook. Never overwrites files |
| `scripts/verify.sh [--smoke] [dir]` | Checks tools, plugins, hooks and session defaults, and optionally a repo |
| `scripts/sync-skills.sh [name]` | Copy your edited live skills back into the repo |
| `hooks/commit-msg` | Git hook that enforces Conventional Commits (`--test` runs its self-check) |
| `skills/` | Custom skills that get installed to `~/.claude/skills/` |
| `templates/` | Repo files, plus the team block for `~/.claude/CLAUDE.md` |

## Keeping it current

This repo only stays useful if every change lands here.

1. **Install something new:** add it to `docs/intitial_setup.md` (one line each for What / Why / Used for), `install.sh` and `verify.sh`.
2. **Change a skill:** run `sync-skills.sh` and update `docs/skills.md`.
3. **Remove something:** delete it from the script and its doc row. Don't leave stale entries.
4. **Every change:** add a CHANGELOG line, run `initial-setup` until it ends with `Failed: 0`, then commit.

`verify.sh` fails if a skill folder has no catalog entry, so docs can't silently drift from what's shipped.
