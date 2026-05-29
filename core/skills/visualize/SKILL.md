---
name: visualize
description: >
  Use when a CasaFlow stage produces a markdown artifact and the developer
  needs to comprehend it before continuing. Generates an interactive HTML
  companion file from ticket.md, spec.md, shipped.md, or qa.md and opens it in the
  developer's browser. Markdown remains the source of truth; HTML is a
  derived, human-facing view designed for stage-appropriate comprehension.
tier: workflow
alwaysApply: false
---

# Skill: Visualize

## Purpose

Markdown is the right format for Claude — flat, parseable, machine-readable.
It is the wrong format for humans reading dense documents. Devs ship features
faster than they can absorb a 400-line markdown file, and the cost of that
mismatch is comprehension gates that degrade into "press y to continue."

This skill solves that mismatch by generating an interactive HTML view of any
CasaFlow stage artifact. The markdown file stays canonical. The HTML is
derived, regenerable, and built around three principles:

1. **No walls of text.** Headlines first; content lives in collapsible pulls
   the developer chooses to open.
2. **Prediction-before-reveal** on forward-looking docs (ticket, spec). The
   developer commits to a one-line interpretation before the full document
   unlocks. The act of committing is the comprehension.
3. **No gates on backward-looking docs** (shipped). Artifacts of completed
   work are for reading, not for testing.

The developer's experience: when a stage produces a doc, Claude opens an
HTML view in the browser. The dev reads the doc in browser-mode (different
posture, different attention), then returns to terminal to continue. Two
modes, two artifacts, one workflow.

---

## When this skill is active

Invoked by:
- Other skills via `/casaflow:visualize <path-to-md-file>`
- Developer running `/casaflow:visualize <path>` directly to refresh a view

Common invocations across the pipeline:
- `spec` Step 0 — `ticket.md` after fetching from Jira
- `spec` Completion — `spec.md` after save
- `plan` Completion — `plan.md` after save
- `finish` — `shipped.md` after generating it from the spec-vs-reality diff

### Opt-in contract for invoking skills (REQUIRED)

Visualize is **opt-in every time**. Markdown is canonical; HTML is a
derived view. Some devs work faster in terminal-only mode and find a
browser tab break disruptive — others find the HTML view essential for
absorbing dense stage docs. The right answer varies per dev and per
moment, so it must be asked.

Any skill that wants to invoke visualize MUST:

1. Save the markdown first.
2. Tell the dev where the markdown lives.
3. Ask explicitly whether they want the HTML view rendered.
4. Only invoke `/casaflow:visualize` on an affirmative response.
5. If invoked, pause for a `ready` confirmation before continuing the
   workflow, so the dev has time to read the browser view.

Invokers must **not** auto-fire visualize, must **not** treat HTML as the
default, and must **not** dump the full markdown contents to terminal as
a substitute for the HTML view. The point of opt-in is that markdown
saved + a one-line confirmation is the floor; HTML is the ceiling.

This contract is enforced by reading the SKILL.md of each invoker. If you
are extending visualize to a new stage, follow the same protocol.

---

## Dispatch by filename

This skill produces a single output file per input. Dispatch is by filename:

| Input | Output | Template purpose |
|-------|--------|------------------|
| `ticket.md` | `ticket.html` | Pre-spec brief. Prediction = "what is this ticket actually asking for?" |
| `spec.md` | `spec.html` | Spec read. Prediction = "what'll be tricky to build?" |
| `plan.md` | `plan.html` | Plan read. Prediction = "which task do you think will hit a wall first?" |
| `shipped.md` | `shipped.html` | Ship artifact. Set-out-vs-shipped + divergence log. No gate. |
| `qa.md` | `qa.html` | QA review (reviewer-triggered). Change summary + automated results + per-check manual sign-off. No gate; exports verdicts back to Claude. |

If the input filename does not match a known template, abort with:

> "No visualization template exists for `<filename>`. Supported inputs:
> `ticket.md`, `spec.md`, `plan.md`, `shipped.md`, `qa.md`."

Future templates (`brainstorm.html`, `retro.html`) will be added
incrementally. Do not invent templates that don't have a corresponding
example file in `examples/`.

---

## Step 1: Read the input markdown

Read the file at the path passed by the invoker. Parse:
- The frontmatter YAML (between the leading `---` lines)
- Each `## Section` heading and its content
- Subsections (`###`) where they appear

If the input file does not exist, abort with a clear error:

> "Cannot visualize: `<path>` does not exist."

---

## Step 2: Read the example HTML as the structural contract

Each template has a reference example in this skill's directory:

- `examples/ticket.html` — pre-spec brief structure
- `examples/spec.html` — spec read structure
- `examples/plan.html` — plan read structure
- `examples/shipped.html` — ship artifact structure
- `examples/qa.html` — QA review structure (no gate; sign-off + export)

Each example also has a paired `.md` file that shows the expected input
shape. Read both: the `.html` is the visual contract, the `.md` shows the
section mapping.

**The example HTML is the visual specification.** Copy its structure
exactly: same dark-theme CSS, same top bar with brand and ticket pill, same
readiness meter (for forward-looking docs), same handoff card. Do not
invent layout. Do not omit visual elements. The point of the visualize
skill is consistency across stage views — the developer learns the rhythm
of these documents over many features.

The example also encodes the prediction-before-reveal mechanic where
applicable. Preserve it exactly: the lock-on-load behavior, the
`pre-reveal` class on body, the JavaScript that unlocks sections when the
dev submits a prediction.

---

## Step 3: Generate the output HTML

Walk the example structure. For each region that displays content from the
source markdown, replace example content with content parsed from the input.

### For `ticket.html` (from `ticket.md`)

| HTML region | Source |
|-------------|--------|
| Hero title | `# Ticket: ...` heading |
| Topbar ticket badge + link | Frontmatter `ticket` and `ticket_url` |
| Metadata pills | Frontmatter (`issue_type`, `priority`, `reporter`, `status`, derive age from `created`) |
| Hero "pulled" tag with Jira link | Frontmatter `fetched` and `ticket_url` |
| Claude's read paragraph | `## Claude's one-line read` |
| Gaps panel items | `## Gaps detected` (one card per bullet) |
| Stated AC items | `## Stated acceptance criteria` (numbered list; Claude adds VAGUE/UNTESTABLE tags per criterion based on language) |
| Original description | Verbatim from `## Original description` |
| Context rows | `## Context` (reporter, linked tickets, comments) |
| Handoff command | `/casaflow:spec <TICKET-ID>` |

Cap gaps at 8. If the source has more, take the 8 most material — judgment
call based on which gaps are most likely to cause spec drift.

The prediction prompt stays: "In one sentence, what is this ticket actually
asking for?" — generic across all tickets. After reveal, show Claude's
one-line read from `## Claude's one-line read` next to the dev's answer.

### For `spec.html` (from `spec.md`)

| HTML region | Source |
|-------------|--------|
| Topbar title + ticket pill | `# Spec: ...` and frontmatter `ticket` |
| Hero title (one-line headline) | First sentence of `## Feature Summary`, rewritten as imperative if needed |
| Hero summary (revealed after prediction) | `## Feature Summary` (full paragraph) |
| Acceptance criteria cards | `## Acceptance Criteria` (numbered list) |
| Non-goals | `## Non-Goals` (bullets) |
| Test spec grid | Sub-sections of `## Test Spec` per criterion (4-column grid: criterion / happy / failure / false-positive) |
| Architecture file rows | Parse `## Architecture Sketch` for `NEW:` and `EDIT:` lines |
| Architecture prose | Remaining text in `## Architecture Sketch` |
| Feature flag block | `## Feature Flag Decision` + frontmatter `flag:` (decision, semantics, key, sunset, touched_repos) |
| Open questions | `## Open Questions` |

The prediction prompt stays: "What do you think the trickiest part of this
feature will be?" After reveal, show one-line "author's call" — Claude
infers this from the spec content. Typical heuristic: the open question
with the most architectural implication, or the section the developer
seemed most uncertain about.

### For `plan.html` (from `plan.md`)

| HTML region | Source |
|-------------|--------|
| Topbar title + ticket pill | `# <Feature Name> Implementation Plan` and frontmatter `ticket` (or referenced spec/PRD path if no frontmatter) |
| Hero tag | `Plan · <date>` |
| Hero title | Goal line (one-sentence imperative from `**Goal:**`) |
| Hero summary (revealed after prediction) | Architecture line (`**Architecture:**`) + tech stack pills |
| Tech stack pills | `**Tech Stack:**` (comma-split into pills) |
| File structure rows | The `## File Structure` table (one row per file with action tag CREATE / MODIFY / TEST) |
| Task cards | Each `### Task N: <name>` becomes a collapsible card with task number, title, file count, step count, dependency badge, and expandable steps |
| Step rows inside a task | Each `- [ ] **Step N: ...**` becomes a numbered row; code blocks render as monospace blocks inside the step |
| Feature flag callout | If a Task 1 of "Create the feature flag" exists, surface a callout pill on the task DAG noting "Flag task first" |
| Footer handoff | `/casaflow:build` |

The prediction prompt: "Which of these tasks do you think will hit a wall
first?" After reveal, show one-line "author's call" — Claude infers this
from the plan: the task with the most cross-file dependencies, or the
task with the longest step list, or the task whose verification command
looks most fragile. Use judgment.

Dependency arrows on the task DAG are optional in v1 — a "Depends on Task
N" badge inside each card is sufficient. If the plan has more than 12
tasks, collapse all task cards by default; if 12 or fewer, leave the
first three open.

### For `shipped.html` (from `shipped.md`)

**No prediction gate.** Page lands fully unlocked. Remove the `pre-reveal`
class from the body and the prediction card / reveal logic from the
example.

| HTML region | Source |
|-------------|--------|
| Topbar title + ticket pill + "Shipped" badge | Frontmatter `ticket` |
| Hero "shipped" tag + PR link | Frontmatter `shipped_date`, `spec_date` (compute days delta), `pr_url` |
| Set-out card | `## One-line set-out` |
| Shipped card | `## One-line shipped` (highlight changed words with `<strong>`) |
| Delta line | Count divergences, spawned tickets, AC dropped/added from frontmatter and md |
| Divergence panel items | `## Divergences from spec` (one card per `### N. ...` sub-section, with when/why) |
| AC diff rows | `## Acceptance criteria — final` (status tags KEPT / CHANGED / EXPANDED / DROPPED / NEW based on the bold prefix in each line) |
| Architecture diff stats + rows | `## Architecture — files actually touched` (tags As planned / Modified / Unplanned) |
| Spawned tickets | `## Tickets spawned` (frontmatter `spawned_tickets` for IDs, body for descriptions) |
| Open questions: resolved vs emerged | Resolved questions from divergence entries; emerged from `## Open questions emerging from build` |
| Tests stats | `## Tests` |

Handoff card hands off to `/casaflow:retro`.

### For `qa.html` (from `qa.md`)

**No prediction gate.** The audience is a *reviewer*, not the author —
prediction-before-reveal doesn't fit. Page lands fully unlocked, like
`shipped.html`. Remove any `pre-reveal` class and reveal logic.

| HTML region | Source |
|-------------|--------|
| Topbar title + ticket pill + "QA" badge | Frontmatter `ticket`, `ticket_url` |
| Hero tag + PR link + branch | Frontmatter `pr_url`, `branch` |
| Hero title | `# QA: ...` heading |
| Hero summary | `## What changed` |
| Delta pills | Frontmatter `automated` + `manual` counts |
| Feature-tests row | `## Feature tests` (the command run + result) |
| Automated check cards | `## Automated e2e` (one card per check: assertion, PASS/FAIL/flaky badge, trace/screenshot path, spec path, failure note) — these verdicts are **fixed**, not editable |
| Manual check cards | `## Manual checks` entries. Each card renders the **assertion**, the **numbered steps** (as an ordered list — preserve order), a **Tools to use** line, and the **Expected** result, followed by three verdict buttons (pass/fail/blocked) + a notes textarea. The step-by-step recipe is the point — render it in full, don't truncate it. |
| API/data sub-step | If a manual check's steps include a runnable request, render a **Copy as cURL** button for that step and an editable **Actual** field so the reviewer can paste the real response (rides along in the export as `actual`). **Never render a real token** — only a `{{token}}` placeholder |
| Sticky sign-off bar | Live overall verdict (any fail→FAIL, else any blocked→BLOCKED, else PASS) + manual sign-off count + Export button |
| Export modal | Serializes all verdicts to a fenced ```` ```casaflow-qa-results ```` JSON block + copy-to-clipboard |

**The findings round-trip is the load-bearing mechanic — preserve it
exactly.** The reviewer marks each manual check, clicks Export, and the page
emits a `casaflow-qa-results` JSON block (type, ticket, pr_url, overall, per
-check id/kind/surface/verdict/note/actual). The reviewer pastes it back into
the CasaFlow chat; the `qa` skill (Step 4) parses it to record the verdicts in
`qa.md` and set the result. Keep the `QA_META` / `AUTOMATED` constants at the top of the
script populated from the source markdown so the export carries correct
identifiers.

**Security:** never render credentials, emails, passwords, or auth tokens.
Refer to test accounts by their `role` label only (e.g., `casaperks-resident`),
and show auth in API cards as the `{{token}}` placeholder.

Handoff card explains the export → paste-back loop (it does not hand off to
another pipeline command, since QA is reviewer-triggered).

---

## Step 4: Write the output file

Write to the same directory as the input md, with the `.html` extension.

Example: input `~/Documents/casaflow/reward-expiry-warnings/spec.md`
         output `~/Documents/casaflow/reward-expiry-warnings/spec.html`

If the output file already exists, overwrite it. HTML is derived and
regenerable. Do not prompt before overwriting.

---

## Step 5: Open in browser

After writing the file, open it for the developer:

```bash
open <output-path>
```

This is the macOS default. If the team runs on Linux, use `xdg-open`. The
invoking skill may also choose to skip the open step (e.g., during
non-interactive automation).

Then return control:

- If the invoker is paused waiting for the developer (e.g., `spec` Step 0):
  the invoker handles the pause prompt. This skill returns after opening.
- If the developer ran `/casaflow:visualize` directly: report the output
  path so they can re-open if the browser missed focus.

> "Visualized: `<output-path>` — opened in your default browser."

---

## What this skill does NOT do

- Does not modify the source markdown. The `.md` is canonical.
- Does not commit the HTML output. HTML lives in the casavault, not git.
- Does not call external services (Jira, GitHub, etc.). All input comes
  from the md file and its frontmatter.
- Does not generate templates for stages without an example file. Adding
  a new template means: drop the example HTML in `examples/`, document
  the md → html mapping in Step 3 above.

---

## Red flags

Stop and surface explicitly:

- **Input md file does not exist** — cannot proceed; report the path
- **Input filename does not match a known template** — list the supported templates
- **Source md is missing required sections** (e.g., `spec.md` without `## Acceptance Criteria`) — report which sections are missing rather than producing broken HTML
- **Output directory is not writable** — report and ask the dev to fix permissions
- **`open` command fails or is unavailable** — write the file successfully, then report the path and ask the dev to open it manually

---

## Output format constraints

- Single self-contained HTML file. No external CSS, no external JS, no network requests at render time.
- Use the dark-theme palette defined in the example CSS variables (`--bg`, `--accent`, `--warn`, etc.). Do not deviate.
- Keep file size reasonable. Each output should be under ~1500 lines.
- Preserve all interactive behavior from the example (collapsible sections, readiness meter, prediction reveal where applicable).

---

## Future work

Templates not yet implemented:

- `brainstorm.html` — alternatives as side-by-side comparison cards with decision rationale
- `retro.html` — captured reflections; opens after `/casaflow:retro`

When adding a new template:
1. Build the example HTML in `examples/<name>.html` with a paired `.md`
2. Add the input → output row to the dispatch table in this skill
3. Document the md → html mapping for that template in Step 3
