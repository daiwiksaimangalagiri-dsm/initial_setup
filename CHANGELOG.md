# Changelog

One line per change, newest first. Use **Added**, **Updated** or **Removed**, and say what and why.

## 2026-10-02

- **Added** diagram tools, chosen after researching 20+ options: Mermaid CLI 12.0.0 (uses your Chrome), LikeC4 1.59.4, dependency-cruiser 18.5.0 with TypeScript 5.9.3 pinned (TS 7 gives empty graphs), tach 0.35.2, Graphviz WASM 1.11.3, the drawio plugin and draw.io desktop 31.7.0. New `diagrams` skill, plus `diagram-render` and `diagram-deps` (with `--check` for CI). A "Diagrams" rule went into both CLAUDE.md templates; `project-setup.sh` adds it to existing repos. `verify.sh` renders a test diagram for each tool.
- **Updated** `install.sh` to run `gh auth setup-git` once gh is signed in, so `git push` uses the gh sign-in. `verify.sh` checks it.
- **Added** mandatory Conventional Commits 1.0.0. A "Commits" rule in the project `CLAUDE.md` template and the global team block tells Claude the format and asks for a body. A dependency-free `hooks/commit-msg` hook (with `--test`) rejects other messages. `project-setup.sh` installs it in every repo without overwriting a different hook and adds the rule to existing `CLAUDE.md` files; `verify.sh` checks both. Bypass with `--no-verify` is discouraged.
- **Added** a status line (`statusline/`): model and effort, repo and branch, context bar, tokens, cost, session time, prompt cache hit rate and warm time, money saved by the cache and headroom, model mix, rate limits, and a model row for each subagent. Python stdlib only, no new dependency. Prompt caching was already on (93% hit rate); Claude Code just never showed it.
- **Added** OpenSpec 1.14.0 for spec-driven development: one change per phase, spec deltas as amendments, a dated archive as history. `project-setup.sh` runs `openspec init` in each repo. We picked it over Spec Kit, BMAD and Kiro because it tracks amendments and has the smallest reviews. Telemetry is off.
- **Added** a "Specs (OpenSpec)" rule to the project `CLAUDE.md` template: OpenSpec owns specs, plans and decisions; superpowers runs the build. This stops two spec folders from forming.
- **Updated** `project-setup.sh` to run `openspec init` on every run, so every repo gets OpenSpec and missing commands come back. It also adds the OpenSpec rule to a repo's existing `CLAUDE.md`. `verify.sh` checks all three. The global team block tells Claude to run `initial-setup` in any repo that has no `openspec/`.
- **Added** `docs/openspec.md`, a plain guide to using OpenSpec.
- **Added** the GitHub MCP server (user scope, all sessions). It signs in through `scripts/github-mcp-headers.sh`, so no token is stored in the config.
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
