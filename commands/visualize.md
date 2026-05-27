---
description: "Generate an interactive HTML view of a CasaFlow stage artifact (ticket.md, spec.md, or shipped.md) and open it in the browser. Markdown stays canonical; HTML is a derived, human-facing view designed for stage-appropriate comprehension."
---

# /casaflow:visualize

Load and follow the instructions in `core/skills/visualize/SKILL.md` verbatim.

## What this command does

Generates an interactive HTML companion for a CasaFlow markdown artifact and opens it in the developer's default browser. The HTML uses stage-appropriate comprehension mechanics:

- **`ticket.md` → `ticket.html`** — pre-spec brief with alignment-check prediction and a prominent "gaps to fill" panel
- **`spec.md` → `spec.html`** — spec read with prediction-before-reveal opener, collapsible section pulls, test spec as a grid, prominent open questions
- **`shipped.md` → `shipped.html`** — backward-looking artifact with set-out-vs-shipped hero, divergence log, AC and architecture diffs, and handoff to retro. No comprehension gate.

## Usage

```
/casaflow:visualize <path-to-md-file>
```

## Invocation by other skills

This skill is invoked automatically by:

- `spec` Step 0 — after fetching the Jira ticket, produces `ticket.html` and opens it before starting the spec interview
- `spec` Completion — after the spec is saved, produces `spec.html` and opens it for review
- `finish` — at branch completion, after generating `shipped.md` from the spec-vs-reality diff, produces `shipped.html` as the artifact handed off to retro

## Principles

1. **Markdown is the source of truth.** Claude reads md. Git tracks md. Visualize never modifies the md.
2. **HTML is derived.** The output is regenerable any time by re-running this command.
3. **No prediction gate on backward-looking docs.** Shipped artifacts are for reading, not for testing.
4. **Visual consistency.** Every stage view uses the same dark theme, the same readiness meter pattern (for forward-looking docs), the same handoff card. Devs learn the rhythm over many features.

## Future templates

Not yet implemented:

- `brainstorm.html` — alternative comparison cards
- `plan.html` — task DAG renderer
- `retro.html` — captured reflections

Adding a new template means dropping an example HTML in `core/skills/visualize/examples/` and documenting the md → html mapping in the skill.
