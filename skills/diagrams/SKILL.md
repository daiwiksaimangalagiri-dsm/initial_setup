---
name: diagrams
description: Team standard for drawing diagrams. Use whenever you create or update an architecture blueprint, approach or flow diagram, sequence diagram, process flow, or a dependency graph between projects, packages or modules. Also use when the user asks to "draw", "diagram", "visualize", "map the dependencies" or "show the flow".
---

# Diagrams

Diagrams are text in the repo. Mermaid is the default because GitHub, GitLab, Notion, Obsidian and VS Code all render it. Every diagram goes through the loop below before you call it done.

## 1. Pick the tool

| Job | Tool | Notes |
|-----|------|-------|
| Approach / idea | Mermaid `flowchart` | 5–15 nodes |
| Process flow | Mermaid `flowchart` | Use `subgraph` for lanes or phases |
| Sequence | Mermaid `sequenceDiagram` | Never draw sequences in draw.io or FigJam: they drop notes, loops and alt blocks |
| Architecture blueprint, one picture | Mermaid `flowchart` with subgraphs | Fine for a single view |
| Architecture blueprint, several views (context, containers, components) | LikeC4 (`.c4` files) | One model, views never drift. Export with `likec4 gen mermaid` |
| Module / package dependencies | Generate it: `diagram-deps` | Never hand-draw a dependency graph |
| Polished picture people will drag around | draw.io plugin, saved as `.drawio.svg` | Keep the Mermaid or LikeC4 source as the truth; regenerating from Mermaid overwrites manual layout |

## 2. Write it (Mermaid rules that prevent most errors)

- Write Mermaid **11** syntax. GitHub and GitLab lag behind the latest release, so skip v12-only types (`agentflow-beta`, `usecase`).
- Short IDs, labels in quotes: `api["Orders API"]`. Never use `end`, `graph`, `subgraph`, `class` or `style` as IDs.
- Quote any label with `( ) [ ] { } : ; , # & < >` or non-ASCII text. Write `#quot;` for a double quote inside a label.
- One idea per diagram. Keep it under about 20 nodes. Split big pictures into an overview plus detail diagrams.
- Direction: `LR` for flows and pipelines, `TB` for hierarchies and layers.
- Sequence diagrams: declare `participant` aliases first; use `alt`/`opt`/`loop` for branches; use `-->>` for replies; `autonumber` for anything over 6 messages.
- Label every edge that isn't obvious. No colours unless they carry meaning (and say what in a legend).

## 3. Render and look (required)

```bash
diagram-render docs/diagrams/checkout.mmd        # writes checkout.svg and checkout.png next to it
```

1. If it fails, read the error, fix the source, render again.
2. Open the PNG with the Read tool and look at it: clipped labels, crossing lines, unreadable text, wrong arrow direction, a hairball. Fix and re-render. Two rounds is usually enough.
3. Only then show the diagram or commit it.

For LikeC4: `likec4 validate` in the folder with the `.c4` files, then `likec4 gen mermaid -o docs/diagrams/c4` and render those files.

## 4. Dependency graphs (generated, never drawn)

```bash
diagram-deps                 # detects the stack, writes docs/diagrams/dependencies.mmd
diagram-deps --check         # exits 1 if the committed diagram is stale (use in CI)
```

- JS/TS: dependency-cruiser. Folders become subgraphs. For big repos use `--focus`, `--collapse` or `--affected` (see the script).
- Python: tach if the repo has `tach.toml` (it also enforces module boundaries with `tach check`), otherwise pyreverse.
- Mermaid refuses diagrams over 50,000 characters. If the graph is too big, collapse to folder level and add one diagram per package.

## 5. Where diagrams live

- `docs/diagrams/<name>.mmd` with the rendered `<name>.svg` beside it.
- In Markdown, embed the Mermaid in a ` ```mermaid ` block so it renders on GitHub.
- Name files by what they show: `checkout-sequence.mmd`, `system-context.mmd`.
- In OpenSpec changes, put the diagrams inside the change folder next to `design.md`.

## Checklist before you finish

- [ ] Right tool for the job (table in section 1)
- [ ] Rendered with `diagram-render` and the PNG checked by eye
- [ ] Under about 20 nodes, every non-obvious edge labelled
- [ ] Dependency graphs generated, not drawn
- [ ] Source (`.mmd` / `.c4`) committed next to the rendered SVG
