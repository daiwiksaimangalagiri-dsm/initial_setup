# Skills Catalog

A skill is a set of instructions that Claude loads only when a task needs it. This page lists every skill the team gets. `verify.sh` fails if a skill in `skills/` has no entry here.

## Our skills (in `skills/`, installed to `~/.claude/skills/`)

| Skill | What it does | When it runs | Source |
|-------|--------------|--------------|--------|
| `stop-slop` | Removes AI writing habits: filler, hype, em dashes, vague claims | Any prose people read. It's on by default through `~/.claude/CLAUDE.md` | Hardik Pandya, MIT |
| `task-observer` | Logs what went wrong or right in each session, so we can improve our skills | Start of every task session (line in `~/.claude/CLAUDE.md`) | Eoghan Henn / rebelytics, CC BY 4.0 |
| `pr-description` | Writes PR descriptions in a **What / Why** format | When you create a PR | Team |

## Secure coding skills (in `skills/`, from righettod/code-assistant-skills-security-utils)

Rules for writing code that resists common attacks. Claude loads the matching one whenever it writes or reviews code in that area; the global `CLAUDE.md` tells it to. The examples are in Java, and the limits are strict on purpose. Source: Dominique Righetto, GPL-3.0 (see `licenses/`).

| Skill | Protects against | Key rules |
|-------|------------------|-----------|
| `secure-archive-decompression` | Zip Slip, zip bombs | No `../` or links. Max 20 entries, 10 MB per entry, 50 MB total |
| `secure-csv-generation` | CSV formula injection | Prefix cells starting with `= + - @` with `'` |
| `secure-email-validation` | Email parser tricks | RFC-valid only. No encoded words, comments, punycode or quoted local parts |
| `secure-http-request-dns-rebinding-prevention` | SSRF, DNS rebinding | Public IPs only, no redirects, 10 s timeout |
| `secure-image-validation` | Payloads hidden in images | PNG/JPEG/GIF/BMP only, nothing appended, shrink by 1px to strip hidden code |
| `secure-pdf-validation` | Malicious PDFs | Max 5 MB. No JavaScript, attachments, XFA or launch links |
| `secure-microsoft-word-validation` | Malicious .docx | Max 5 MB. No macros, OLE or DDE |
| `secure-microsoft-excel-validation` | Malicious .xlsx | Max 5 MB. No macros, OLE, DDE or external links |
| `secure-jwt-validation` | Forged or misused tokens | Asymmetric algorithm, check every claim, reject `jku`/`x5u`/`jwk` |
| `secure-log-entry-generation` | Log forging | Strip newlines and ANSI codes, encode HTML, max 100 chars |
| `secure-message-digest-generation` | Weak hashes, collisions | SHA3-512, `\|` separators, UTF-8, hex output |
| `secure-relative-url-validation` | Open redirects | Relative paths only, no scheme, no `//` |
| `secure-template-rendering` | Template injection, XSS | Static templates only, auto-escape on |
| `secure-xml-parsing` | XXE, entity expansion | DTD, entities and XInclude off. Max 1 MB |

## Skills from plugins (installed by `install.sh`)

| Plugin | Main skills | Use for |
|--------|-------------|---------|
| ponytail | ponytail (`/ponytail lite\|full\|ultra`) | Simplest code that works. On in every session and subagent |
| superpowers | brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion | Building step by step and checking your work |
| claude-mem | mem-search, make-plan, do, smart-explore | Finding past work, planning and running big tasks |
| frontend-design | frontend-design | UI that doesn't look like a template |
| figma | figma-use, figma-design-to-code, figma-generate-design | Moving between Figma and code |
| claude-code-setup | claude-automation-recommender | Picking hooks, skills and MCP servers for a repo |

## Skills from ruflo (added per repo by `ruflo init`)

`swarm-orchestration`, `swarm-advanced`, `sparc-methodology`, `pair-programming`, `verification-quality`, `hooks-automation`, `stream-chain`, `skill-builder`. They live in each repo's `.claude/skills/`, not in this repo.

> Skills that sync with your claude.ai account (docx, pdf, xlsx, pptx, skill-creator) aren't in this repo. Everyone gets them from their own account.

## Add, update or remove a skill

| Action | Steps |
|--------|-------|
| **Add** | Build the skill in `~/.claude/skills/<name>/` → `./scripts/sync-skills.sh <name>` → add a row above → CHANGELOG line |
| **Add from GitHub** | Read every file first. Copy `SKILL.md`, `references/` and `LICENSE` into `skills/<name>/`, then follow the Add steps |
| **Update** | Edit the live skill → `./scripts/sync-skills.sh` → CHANGELOG line. Teammates run `initial-setup --update-skills` |
| **Remove** | `git rm -r skills/<name>` → delete its row → CHANGELOG line. Teammates delete `~/.claude/skills/<name>` themselves |

Before sharing a skill, check it for personal paths and secrets: `grep -rniE "/Users/|token|secret" skills/<name>`.
