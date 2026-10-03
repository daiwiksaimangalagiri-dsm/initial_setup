<!-- initial_setup:start (managed by initial_setup/scripts/install.sh, edit the template, not this block) -->
## Team defaults

**Writing:** Use the `stop-slop` skill for any prose that people will read: docs, READMEs, PR descriptions, summaries, messages. It doesn't apply to code or code comments.

**Secure coding:** Before writing or reviewing code in one of these areas, load the matching `secure-*` skill and follow its checklist:

| Area | Skill |
|------|-------|
| Unzipping archives | `secure-archive-decompression` |
| Writing CSV | `secure-csv-generation` |
| Validating emails | `secure-email-validation` |
| Outbound HTTP to user-supplied URLs (SSRF) | `secure-http-request-dns-rebinding-prevention` |
| Validating uploaded images, PDF, Word, Excel | `secure-image-validation`, `secure-pdf-validation`, `secure-microsoft-word-validation`, `secure-microsoft-excel-validation` |
| Validating JWT access tokens | `secure-jwt-validation` |
| Logging user input | `secure-log-entry-generation` |
| Hashing / message digests | `secure-message-digest-generation` |
| Redirect targets (open redirect) | `secure-relative-url-validation` |
| Template engines | `secure-template-rendering` |
| Parsing XML | `secure-xml-parsing` |

The examples are in Java. Translate them to the project's language. The limits (file sizes, counts, lengths) are strict defaults: keep them unless the project's `CLAUDE.md` sets others, and say so when you change one.

**Specs:** every repo uses OpenSpec (`openspec/`) for specs, plans and decisions. If a repo has no `openspec/` folder, run `initial-setup` in it before writing any spec. Superpowers' brainstorming and writing-plans write into the OpenSpec change folder, never `docs/superpowers/specs/` or `docs/superpowers/plans/`.

**Commits:** every git commit in every repo uses Conventional Commits 1.0.0: `<type>(<optional scope>): <description>`, with type one of `feat fix docs style refactor perf test build ci chore revert`. Subject is imperative, lowercase, no trailing period, 72 characters or fewer. Add a body (blank line after the subject, what and why) for anything but a trivial change. Mark breaking changes with `!` or a `BREAKING CHANGE:` footer. One logical change per commit. A `commit-msg` hook enforces this; never bypass it with `--no-verify`.

**Diagrams:** Use the `diagrams` skill for any blueprint, flow, sequence, process or dependency diagram. Mermaid by default, generate dependency graphs with `diagram-deps`, and render with `diagram-render` and look at the image before you show it.

**Model and effort:** pick the cheapest setting that does the job well.

| Task | Model | Effort |
|------|-------|--------|
| Search, file lookups, simple reads (subagents) | `haiku` | default |
| Routine edits, tests, docs (subagents) | `sonnet` | default |
| Main session: planning, building, reviewing | `opus` | `xhigh` (the default) |
| Hard bugs, architecture, security review | `opus` | `/effort max` |
| Large multi-step builds across many files | `opus` | Ultracode: `/effort ultracode on`, or put "ultracode" in the prompt |

- When spawning subagents, set `model` to match the task above. Don't run a search agent on opus.
- Go back down to `xhigh` after a `max` or Ultracode task.
<!-- initial_setup:end -->
