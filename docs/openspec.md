# How to use OpenSpec

OpenSpec keeps our specs in the repo, next to the code. You write down what you're building, the team reviews it, Claude builds it, and the spec stays up to date afterwards.

## The idea in one minute

- **Specs** describe how the app behaves today. They live in `openspec/specs/`.
- A **change** is one piece of work: a feature, a fix, or a phase of the project. It lives in its own folder under `openspec/changes/`.
- A change doesn't rewrite the spec. It lists only the differences: requirements **ADDED**, **MODIFIED** or **REMOVED**.
- When the change is done, you **archive** it. Its differences merge into the main spec, and the folder moves to `openspec/changes/archive/` with the date in front of its name. That archive is your history.

## The three commands you need

Type these in Claude Code.

| Step | Command | What happens |
|------|---------|--------------|
| 1. Plan | `/opsx:propose add login page` | Claude asks questions, then creates the change folder with a proposal, design, tasks and spec edits |
| 2. Build | `/opsx:apply` | Claude works through `tasks.md` and ticks each task off |
| 3. Finish | `/opsx:archive` | The spec edits merge into the main spec, and the change moves to the archive |

Other commands:

- `/opsx:explore`: think an idea through with Claude before you commit to a change. Nothing gets written.
- `/opsx:update`: change the plan for a change that's already open.
- `/opsx:sync`: merge spec edits into the main spec early, without archiving.

## What's in a change folder

```
openspec/changes/add-login-page/
├── proposal.md   why we're doing it, and what's in and out of scope
├── design.md     how we'll build it, and the decisions we made
├── tasks.md      checklist of work, ticked off during /opsx:apply
└── specs/        the spec edits (ADDED / MODIFIED / REMOVED)
```

A spec edit looks like this:

```markdown
## ADDED Requirements

### Requirement: Login with email
Users SHALL be able to sign in with email and password.

#### Scenario: Wrong password
- GIVEN a registered user
- WHEN they enter the wrong password
- THEN they see "Email or password is wrong" and stay on the page
```

## Building in phases

Make each phase its own change: `phase-1-accounts`, `phase-2-billing` and so on. Finish and archive one before the next depends on it. Two changes can be open at once if they touch different requirements.

## Reviewing and debating with the team

1. Run `/opsx:propose` on a new branch.
2. Open a pull request with only the change folder in it, before any code.
3. The team reads `proposal.md`, then `design.md`, then the spec edits, and argues it out in PR comments.
4. Fix the plan with `/opsx:update`, push, and repeat until everyone agrees.
5. Merge the PR. That's the approval. Then build with `/opsx:apply`.

## Changing a spec later

Don't edit `openspec/specs/` by hand. Open a new change that MODIFIES or REMOVES the requirement. That way every amendment has a reason, a review and a date.

## Recording decisions

- A decision for one change goes in its `design.md`:

  ```markdown
  ### Decision: Use Postgres, not SQLite
  Why: we need several servers writing at the same time.
  ```

- A decision that affects the whole project goes in `docs/decisions/0001-use-postgres.md`. If it changes later, don't edit it. Write a new decision that says it replaces 0001.

## OpenSpec and superpowers

We use both, and each has its own job:

| Job | Tool |
|-----|------|
| Specs, designs, plans, decisions | OpenSpec (in `openspec/`) |
| Building: tests first, debugging, checking work, code review | superpowers |

Superpowers normally saves its own specs in `docs/superpowers/`. Our `CLAUDE.md` tells it to write into the OpenSpec change folder instead, so there's only ever one place to look.

## Setup

`initial-setup` installs OpenSpec and runs `openspec init` in your repo, so you don't need to do anything. To do it by hand:

```bash
npm install -g @fission-ai/openspec@1.14.0
openspec init --tools claude
```

Useful terminal commands: `openspec list` shows open changes, and `openspec view` opens a dashboard.

Project-wide rules for every spec go in `openspec/config.yaml` under `context:`, for example "All screens must work on mobile".
