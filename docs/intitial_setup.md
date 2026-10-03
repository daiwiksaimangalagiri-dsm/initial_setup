# Initial Setup

Every tool on our machines, explained in plain words. Update this page each time you add or remove something.

- **Last verified:** 2026-10-02 on macOS 26.6.2 (arm64): 48 checks passed
- **One command:** run `initial-setup` inside any repo. It installs what's missing, sets up the repo, and checks everything.

---

## How the one command works

```bash
# First time on a new Mac
git clone https://github.com/daiwiksaimangalagiri-dsm/initial_setup.git ~/initial_setup && ~/initial_setup/setup.sh

# After that, inside any repo
initial-setup
```

| Step | Script | What it does |
|------|--------|--------------|
| 1 | `scripts/install.sh` | Installs every tool, plugin, MCP server and skill on your Mac. Skips anything already there. |
| 2 | `scripts/project-setup.sh` | Sets up the current repo: `CLAUDE.md`, `.mcp.json`, `.gitignore`, ruflo. Adds only what's missing and never overwrites your files. |
| 3 | `scripts/verify.sh --smoke` | Checks everything, runs each session-start hook, and opens real browsers. Any ✘ means something needs fixing. |

---

## At a glance

| Tool | What it is | Why we need it |
|------|------------|----------------|
| nvm + Node.js | JavaScript runtime | Runs Playwright, ruflo and most MCP servers |
| Bun | Fast JavaScript runtime | claude-mem's hooks need it. Without it, every session start fails |
| uv | Python tool installer | Installs headroom in its own isolated environment |
| gh | GitHub CLI | Create repos and PRs from the terminal |
| Google Chrome | Your normal browser | The real browser Claude tests in |
| Playwright + Chromium | Browser automation | Automated browser tests, plus a clean browser for them |
| Playwright MCP | Browser tools for Claude | Lets Claude open pages, click and fill forms |
| Playwright CLI | Browser control from the terminal | Quick checks without MCP |
| Claude Code | The AI coding agent | Everything else plugs into it |
| Claude Code plugins | Add-ons for Claude Code | Skills, memory, token savings, design tools |
| headroom | Local proxy | Shrinks what Claude sends, so sessions use fewer tokens |
| ruflo | Agent orchestration | Runs swarms of agents for big tasks |
| Status line | Live bar under Claude's prompt | Shows model, tokens, cost, prompt cache, money saved, repo and branch |
| OpenSpec | Spec-driven development | Write specs before code, change them in phases, keep the history |
| GitHub MCP | GitHub tools for Claude | Issues, PRs, repos and CI from inside Claude |
| Custom skills | Our own instructions for Claude | Same writing, workflow and secure-coding rules for everyone |

---

## Runtimes

### nvm 0.39.7 + Node.js v24.16.0 (LTS)
- **What:** nvm installs and switches Node versions. Node runs JavaScript tools.
- **Why:** Playwright, ruflo and most MCP servers are Node programs.
- **Install:** `curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash`, then `nvm install --lts`

### Bun 1.4.2
- **What:** A fast JavaScript runtime.
- **Why:** The claude-mem plugin runs its hooks with Bun. Before we installed it, every session start showed `Bun not found`.
- **Install:** `curl -fsSL https://bun.sh/install | bash -s "bun-v1.4.2"`

### uv 0.11.6
- **What:** Installs Python tools, each in its own environment.
- **Why:** headroom is a Python tool. uv keeps it separate from the system Python.
- **Install:** `curl -LsSf https://astral.sh/uv/install.sh | sh`

### GitHub CLI (gh) 2.102.0
- **What:** GitHub from the terminal: create repos, open PRs, check CI.
- **Why:** Lets Claude create and manage repos for you. git alone can only push.
- **Install:** the official binary from github.com/cli/cli releases (we check its checksum). Then sign in once: `gh auth login --git-protocol https --web`

### git 2.50.1 + Xcode Command Line Tools
- **What:** Version control, plus the compilers some packages need.
- **Install:** `xcode-select --install`

---

## Browsers and Playwright

### Google Chrome 154
- **What:** The browser you already use.
- **Why:** Claude tests in the same browser our users have.
- **Install:** by hand from google.com/chrome

### Playwright 1.63.0 + Chromium 153
- **What:** Microsoft's browser automation library, plus a Chromium build that matches it.
- **Why:** Automated tests need a clean browser that never touches your Chrome profile.
- **Install:** `npm install -g playwright@1.63.0 && playwright install chromium`

### Playwright MCP 0.0.83 (`@playwright/mcp`)
- **What:** Gives Claude browser tools: open, click, type, screenshot.
- **Why:** Claude can test a UI flow the way a person would.
- **Install:** `npm install -g @playwright/mcp@0.0.83`
- **Per repo:** `.mcp.json` adds a `playwright-chrome` server pointed at real Chrome. Claude asks you to approve it the first time you open the repo.

### Playwright CLI 0.1.22 (`@playwright/cli`)
- **What:** The same browser actions, run from the terminal.
- **Why:** Fast manual checks, and it uses fewer tokens than MCP.
- **Install:** `npm install -g @playwright/cli@0.1.22`
- **Try it:** `playwright-cli open https://example.com --browser chrome --headed`

---

## Claude Code 2.1.287

- **What:** The AI coding agent.
- **Install:** `curl -fsSL https://claude.ai/install.sh | bash`

### Plugins (installed for your user account, active in every session)

| Plugin | What it does | Runs at session start? |
|--------|--------------|------------------------|
| superpowers 6.4.1 | Step-by-step workflows: plan, test first, debug, verify | Yes |
| claude-mem 13.15.0 | Remembers past sessions and brings back useful context | Yes (needs Bun) |
| headroom 0.35.0 | Makes sure the headroom proxy is running | Yes |
| ponytail 4.10.1 | Pushes Claude toward the simplest code that works | Yes (also in every subagent) |
| playwright | Browser tools in every project | No |
| context7 | Up-to-date docs for libraries | No |
| frontend-design | Guidance for good-looking UI | No |
| figma | Figma ↔ code (run `/mcp` once to sign in) | No |
| claude-code-setup | Suggests hooks, skills and MCP servers for a repo | No |

**Install one:** `claude plugin install <name>@<marketplace>`. Plugins from outside the official marketplace need `claude plugin marketplace add <owner/repo>` first:

| Plugin | Marketplace |
|--------|-------------|
| claude-mem | `thedotmack/claude-mem` |
| headroom | `headroomlabs-ai/headroom` |
| ponytail | `DietrichGebert/ponytail` |

### headroom 0.39.1 (proxy)
- **What:** A small local server that compresses what Claude Code sends to the API.
- **Why:** Saves tokens on long sessions. Our first test went from 15,462 to 15,176 tokens.
- **How it's always on:** `headroom deploy` added `ANTHROPIC_BASE_URL=http://127.0.0.1:8787` to `~/.zshrc`, and a launchd job restarts the proxy if it stops. The headroom plugin checks it at every session start.
- **Install:** `uv tool install --python 3.13 "headroom-ai[all]==0.39.1"`, then `headroom deploy --providers manual --target claude --no-telemetry`
- **Check:** `headroom install status`. See savings at `http://127.0.0.1:8787/stats`.
- **Turn off:** `headroom unwrap claude`, then open a new terminal.

### ruflo 3.51.1
- **What:** Runs teams of AI agents (swarms) with shared memory.
- **Why:** Useful for large tasks you can split across several agents.
- **How it's always on:** its MCP server is added for your user account, so every session has its tools. Tool search loads them only when they're needed.
- **Per repo:** `ruflo init --minimal` adds 8 ruflo skills and a `.claude-flow/` folder. Our setup script removes the old model that ruflo pins, so your default model still applies.
- **Install:** `npm install -g ruflo@3.51.1 && claude mcp add ruflo -s user -- ruflo mcp start`
- **Note:** ruflo has one maintainer and releases often. We pin the version on purpose.

### OpenSpec 1.14.0 (`@fission-ai/openspec`)
- **What:** Keeps specs in the repo. Each feature or phase is a "change" with a proposal, design, tasks and spec edits. Finished changes merge into the main spec and move to a dated archive.
- **Why:** We agree on what to build before code, review it in a PR, and keep a history of every spec change and decision. Superpowers still runs the build (TDD, debugging, review), but specs live only in OpenSpec.
- **Per repo:** `initial-setup` runs `openspec init --tools claude` in every repo, every time. It adds `openspec/` and the `/opsx:*` commands, keeps your existing specs and config, and adds the OpenSpec rule to an existing `CLAUDE.md`. `verify.sh` fails if any of these is missing.
- **Install:** `npm install -g @fission-ai/openspec@1.14.0`, then `openspec config set telemetry.enabled false`
- **Check:** `openspec --version`
- **How to use it:** **[openspec.md](openspec.md)**

---

### GitHub MCP server
- **What:** GitHub's official MCP server. Claude can read and manage issues, PRs, repos and CI runs directly.
- **Why:** Claude works with GitHub without you copying and pasting links or output.
- **How it signs in:** `scripts/github-mcp-headers.sh` reads your token from `gh` or the macOS keychain each time Claude connects. The token is never written to Claude's config.
- **Install:** `claude mcp add-json github -s user '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headersHelper":"<repo>/scripts/github-mcp-headers.sh"}'`
- **Check:** `claude mcp list` shows `github: ✔ Connected`.

## Status line (`statusline/`)

- **What:** Three lines at the bottom of Claude Code, plus a row for each subagent.

  ```
  🧠 Opus 5.5 · xhigh │ 📂 IU_Workspace ⎇ main ●8 │ 💬 Spec-driven documentation │ 😎 vibin
  ▰▰▱▱▱▱▱▱▱▱ 19% of 1M │ 🪙 5.2M in · 39.6k out │ 💸 $5.25 │ ⏱️ 23m 49s (api 8m 40s) │ +465 −0
  🧊 cache 93% hit 🔥 warm 59m left · 3 misses │ 💰 saved $16.97 cache + $0.65 headroom │ 🧠×45
  ```
  Subagent row: `⏳ Search docs │ 🐇 haiku 4.5 · low │ 50k tok (25%) │ ⏱️ 1:15`
- **Why:** Prompt caching runs all the time, but Claude Code doesn't show it. This shows the hit rate, how long the cache stays warm, why it missed, and the money it saved. It also shows which model each subagent runs on.
- **How "saved" is worked out:** cache reads cost 5–10% of normal input, so each cached token saves the difference. The extra cost of writing the cache is subtracted. Prices for Opus 5.5, Sonnet 5.5 and Haiku 4.5 are in `statusline.py`. "headroom" is the proxy's own total since it started.
- **The vibe:** the last slot on line 1 changes with the session: ✨ fresh session, 😎 vibin, 🫠 context kinda full, 💀 /compact era, 🌙 goblin hours (1–5am), 🧑‍🍳 cooking fr (500+ lines), 💸 big spender ($20+), 🏎️ speedrun (fast mode).
- **Install:** `install.sh` sets `statusLine` and `subagentStatusLine` in `~/.claude/settings.json`. If you already have your own status line, it keeps yours.
- **Check:** `python3 statusline/statusline.py --test`
- **Turn off:** `/statusline delete` in Claude Code.

## Session defaults (apply to every session)

| Default | Where it lives | What it does |
|---------|----------------|--------------|
| Effort `xhigh` | `~/.claude/settings.json` → `effortLevel` | Claude thinks hard by default |
| Model and effort guide | `~/.claude/CLAUDE.md` (team block) | haiku for search, sonnet for routine work, opus for the main session, `/effort max` for hard problems, Ultracode for big builds |
| stop-slop | `~/.claude/CLAUDE.md` (team block) | Plain, direct writing in docs and messages |
| Secure coding | `~/.claude/CLAUDE.md` (team block) | Loads the matching `secure-*` skill for archives, uploads, JWT, XML and similar code |
| task-observer | `~/.claude/CLAUDE.md` | Logs lessons from each session to improve our skills |
| Session-start hooks | the plugins above | superpowers, claude-mem, headroom, ponytail |

The team block comes from `templates/global-CLAUDE.md`. To change it, edit the template and re-run `initial-setup`. Your own lines in `~/.claude/CLAUDE.md` are never touched.

---

## Custom skills

Our skills live in `skills/` and get copied to `~/.claude/skills/`. Full list: **[skills.md](skills.md)**.

---

## Project templates (`templates/`)

| File | Goes to | Purpose |
|------|---------|---------|
| `CLAUDE.md` | repo root | Team rules for Claude: ask first, test, strict types, naming |
| `mcp.json` | `.mcp.json` | Playwright MCP → Chrome |
| `gitignore` | `.gitignore` | Ignores secrets, `node_modules`, Playwright output |
| `global-CLAUDE.md` | `~/.claude/CLAUDE.md` | Team defaults for every session |

---

## Add or remove a tool

1. Install it and check that it works.
2. Add a short section here: **What / Why / Install**.
3. Add it to `scripts/install.sh` with a pinned version, and to `scripts/verify.sh`.
4. Add a line to `CHANGELOG.md`.
5. Run `initial-setup` and make sure it ends with 0 failures. Then commit.

To remove a tool, delete it from all four places. Don't leave old entries behind.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Error at session start | Run `./scripts/verify.sh`. The "Session-start hooks" section names the hook that's broken |
| `Bun not found` | Install Bun (see above) |
| Claude can't connect after installing headroom | Run `headroom install status`. If it isn't healthy, run `headroom install restart` |
| `playwright-chrome` shows "Pending approval" | Open `claude` in that repo and approve it |
| figma or context7 need auth | Run `/mcp` inside Claude Code |
