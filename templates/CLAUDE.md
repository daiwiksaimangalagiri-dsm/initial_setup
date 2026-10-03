# CLAUDE.md

{{PROJECT_NAME}}: TODO, one line on what this project is.

- TODO: one line per top-level folder (stack, version, purpose). Name the single source of truth for shared types or contracts.
- `.mcp.json`: project MCP config. `playwright-chrome` runs Playwright MCP against real Google Chrome.
- Machine setup and tool rationale: see `{{SETUP_REPO}}/docs/intitial_setup.md`.

Longer workflows belong in `.claude/skills/`, not in this file.

## Ask before you assume

Never guess at intent. If a task leaves anything open (which screen, which endpoint, what happens on failure, whether it's user-facing), stop and ask. One question up front costs less than work done in the wrong direction.

- Ask when the request could reasonably mean two different things.
- Ask before changing a public API shape, a DB schema, or shared contracts.
- Do not invent product decisions, copy, or acceptance criteria.
- Do not widen scope past what was asked. Note the adjacent thing you spotted; don't fix it unprompted.
- If you had to assume something you couldn't resolve, list it at the top of your summary.

## Specs (OpenSpec)

Specs live in `openspec/`. How to use it: `docs/openspec.md` in the initial_setup repo.

- Every feature or phase starts as a change: `/opsx:propose`. Build it with `/opsx:apply`, finish with `/opsx:archive`.
- OpenSpec owns all specs, designs, plans and decisions. Superpowers' brainstorming writes into the change's `proposal.md` and `design.md`; writing-plans writes into its `tasks.md`. Never create `docs/superpowers/specs/` or `docs/superpowers/plans/`.
- Superpowers still runs the build: TDD, debugging, verification and code review.
- Record each decision in `design.md` under `### Decision:` with the reason. A decision that spans changes goes in `docs/decisions/NNNN-title.md`; to change it, write a new one that supersedes it.

## The loop

Every change runs through the project's check, test and build commands. A task is not done until they pass.

> TODO: list the exact commands (type check, lint, format check, unit/integration tests, migrations) once the stack exists.

- Write the failing test first. Watch it fail for the right reason, then make it pass.
- Run the checks after every meaningful edit, not once at the end.
- Never report success while checks are failing. Never disable, skip, or `.only` a test to make the run pass.
- If a test is wrong, say so and explain why before changing it.
- Do not start long-running processes (dev servers, watchers) to "verify" a change. They never exit. Use the check commands.

## Type checking

Strict mode everywhere. Treat type errors as failures, not warnings.

- No `any`. If a type is genuinely unknown, use `unknown` and narrow it.
- No `as` casts or non-null `!` to escape an error. Fix the type or narrow properly.
- No `@ts-expect-error` (or language equivalent) without a comment naming the upstream issue.
- Parse all external input (request bodies, query params, API responses) with a schema, and infer the types from that schema.

Write it strict from the start; don't write loose code and fix it after the checker complains.

## Naming

Reuse the existing word instead of coining a new one. Consistency helps the model as much as it helps us.

- Keep one word per domain concept. Record them in a vocabulary table here as they emerge (`Use` / `Never`).
- CRUD functions: `createX`, `getX`, `listX`, `updateX`, `deleteX`. Not `fetch`, `remove`, `save`, `handle`.
- Booleans read as assertions: `isLoading`, `hasError`, `canEdit`.
- Test files sit beside their source: `x.service.ts` → `x.service.test.ts`.
- User-facing copy uses sentence case ("Save changes", not "Save Changes").
- Do not add new files at the repo root without asking.

## Dependencies

Code is cheap to write; maintenance is the real cost. Prefer the platform over a package, and a well-established package over writing your own.

Before installing anything, check these and state the results:

- Weekly downloads over ~100k, a release in the last six months, more than one maintainer.
- Nothing single-maintainer or freshly published for anything touching auth, crypto, networking, or file I/O.
- No new dependency for something the standard library or an existing dependency already does.

Ask before adding a dependency. Never add one as a side effect of another task. Pin exact versions and commit the lockfile.

Every tool installed for the team gets an entry in `{{SETUP_REPO}}/docs/intitial_setup.md`: version, install command, a one-line **What / Why / Used for**, and a way to verify it.

## Performance

> TODO: set a latency budget (e.g. p95 200ms per endpoint) once there is a backend.

- Filter, sort, aggregate and paginate in the database, never in application memory.
- Paginate every list endpoint with a default and a hard maximum. No unbounded queries.
- No N+1 queries. Join or batch.
- Do a performance pass at the end of any feature that reads data, and say what you checked.

## Security

For archives, CSV, email, outbound HTTP, file uploads (image/PDF/Word/Excel), JWT, logging, hashing, redirects, templates or XML, load the matching `secure-*` skill first and meet its checklist. The full table is in `~/.claude/CLAUDE.md`. Record any limit you change for this project here.

## Error handling

Fail early and loudly, and never swallow an error.

- No empty `catch`, and no `catch` that only logs. Handle the error meaningfully or let it propagate.
- Throw typed errors with a stable, machine-readable code. Never map unexpected errors to a success response.
- Error messages tell the client what failed and what to do next. "Something went wrong" is not an error message.
- Log with structured context (IDs, request ID), never a bare string.

## Browser testing (Playwright)

Tooling is installed by `{{SETUP_REPO}}/scripts/install.sh` and checked by `verify.sh`.

| Need | Use |
|------|-----|
| Claude drives real Chrome | Playwright MCP (`playwright-chrome` server, or the Playwright plugin) |
| Drive a browser from the shell | `playwright-cli open <url> --browser chrome --headed` |
| Headless or CI runs | Playwright library + bundled Chromium |

**End-to-end:** after any feature that spans frontend and backend, drive it the way a person would. Sign in, run the real flow, and check the result where it's stored. Test the unhappy paths on purpose (offline, expired session, double submit). Report what you clicked and what you saw. If a step fails, report the failure; don't work around it and call it a pass.

**UI:** passing tests don't tell you whether a screen looks right.

- Screenshot every screen you touch and look at it before saying it's done.
- Check small viewports, large text and dark mode.
- Use realistic data: long names, empty states, long lists. Never `Lorem ipsum` or "Test User".
- Look for clipped text, overlapping elements, content under safe areas, and missing empty or loading states.

## Architecture

Read this before exploring the codebase. If you catch yourself searching for something that belongs here, add it.

> TODO: request path, auth model, and a "Where things live" table (`You need` → `Look in`) once the code exists.

| You need | Look in |
|----------|---------|
| Installed tools and how to verify them | `{{SETUP_REPO}}/docs/intitial_setup.md` |
| Project MCP servers | `.mcp.json` |

## Keeping this file current

This file is a failure log, not a wishlist. Every rule in it should exist because something went wrong at least once.

When you make a mistake, get corrected, or find something about this workspace that wasn't written down:

1. Add one imperative line to the failure log below describing the correct behaviour.
2. Keep it specific to this repo. General advice doesn't belong here.
3. If the fix is a workflow rather than a rule, put it in `.claude/skills/` and link it from here.
4. Mention the change in your summary.

Keep this file under 500 lines. When a section grows too big, move it to a nested `CLAUDE.md` or a skill.

## Failure log

- Project MCP servers show "Pending approval" in `claude mcp list` until a session in this folder approves them. Don't report them as connected until then.
- `playwright-cli find` returns nested nodes, not always the clickable ref. Get the ref from the snapshot `.yml` it writes.
- Playwright writes snapshots and screenshots to `.playwright-mcp/` and `.playwright-cli/`. Keep them out of git.
