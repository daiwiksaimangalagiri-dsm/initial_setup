# Changelog

One line per change, newest first. Use **Added**, **Updated** or **Removed**, and say what and why.

## 2026-10-02

- **Added** the GitHub CLI `gh` 2.102.0, and published this repo at github.com/daiwiksaimangalagiri-dsm/initial_setup.
- **Added** 14 secure-coding skills (`secure-*`) from righettod/code-assistant-skills-security-utils (GPL-3.0). The global `CLAUDE.md` and the project template tell Claude when to use each one.
- **Added** `setup.sh` / `initial-setup`: one command that installs everything, sets up the current repo, and verifies it. Replaces `new-project.sh` with `project-setup.sh`, which also works on existing repos.
- **Added** headroom 0.39.1 (proxy) to cut token use. It's always on through `ANTHROPIC_BASE_URL` and a launchd watchdog.
- **Added** ruflo 3.51.1 for agent swarms: a user-scope MCP server, plus a minimal init in each repo.
- **Added** the ponytail 4.10.1 plugin for the simplest working code. It's on in every session and subagent.
- **Added** the `stop-slop` skill for plain writing. It's on by default through the team block in `~/.claude/CLAUDE.md`.
- **Added** session defaults: effort `xhigh`, and a guide for picking a model and effort level.
- **Fixed** the broken session-start hook by installing Bun 1.4.2, which claude-mem needs. `verify.sh` now runs every session-start hook to catch this.
- **Checked** claude-mem 13.15.0: it was already installed, and its worker is now healthy.
- **Added** repo `initial_setup` with `install.sh` (one command), `verify.sh`, `new-project.sh` and `sync-skills.sh`. Gives one place to set up a machine and start projects.
- **Added** custom skills `task-observer` and `pr-description` in `skills/`, so teammates get the same skills.
- **Added** project templates (`CLAUDE.md`, `mcp.json`, `gitignore`), adapted from the team CLAUDE.md template.
- **Added** Playwright 1.63.0, Playwright Chromium, `@playwright/mcp` 0.0.83 and `@playwright/cli` 0.1.22 for browser automation and testing by Claude and by hand.
- **Added** the project MCP server `playwright-chrome` (Playwright MCP → Google Chrome).
- **Documented** what was already installed: nvm 0.39.7, Node v24.16.0, Google Chrome 154, Claude Code 2.1.287, and 8 Claude Code plugins.
