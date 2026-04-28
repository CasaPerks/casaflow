---
name: spec
description: >
  Use when writing a feature spec before any code is written. When Jira is
  configured, fetches ticket context to pre-seed the spec and routes bugs to
  /kickoff automatically. Guides the developer through feature summary,
  acceptance criteria, non-goals, test spec, architecture sketch, and open
  questions. Invoked by /spec or by kickoff when no spec exists for a feature.
tier: workflow
alwaysApply: false
---

# Skill: Feature Spec

## Purpose

This skill governs how Claude helps a developer write a feature spec before
any code is written. The spec is not bureaucracy — it is the mechanism by
which the developer proves to themselves (and to Claude) that they understand
what they're building before delegating implementation to AI.

A developer who cannot write a spec cannot evaluate whether Claude's output
is correct. The spec is the developer's intellectual stake in the feature.

**Claude does NOT write the spec for the developer.** Claude asks questions
and reflects answers back until each section is solid.

---

## When this skill is active

Invoked by:
- Developer running `/casaflow:spec`
- `kickoff` skill when no spec file exists for a feature/improvement

---

## Step 0: Jira Ticket Context (optional)

Before starting the spec interview, check whether Jira integration is
available. This step pre-seeds the spec with ticket context and routes bugs
to the correct workflow automatically.

### 0a. Check configuration

Read `casaflow.config.md`. Look for the `ticket-system`
value in the `## Team` section.

- If `ticket-system` is **not** `jira` → skip Step 0 entirely. Proceed
  directly to Section 1 (Feature Summary). Current behavior is unchanged.
- If `ticket-system` **is** `jira` → continue to 0b.

### 0b. Check MCP availability

Confirm the Atlassian MCP server is available. If Jira MCP tools are not
configured or not responding, say:

> "Jira is configured but the Atlassian MCP server is not available. To
> enable Jira integration, add the Atlassian MCP server to your Claude Code
> settings.json under `mcpServers`. Continuing without ticket context."

Then proceed directly to Section 1 (current behavior).

### 0c. Ask for ticket ID

> "Jira is connected. Do you have a ticket ID for this work?
> (paste the ticket ID, or type **skip** to continue without one)"

- If **skip** → proceed to Section 1 (current behavior, no ticket context).
- If a ticket ID is provided → continue to 0d.

### 0d. Fetch ticket

Use the Atlassian MCP to fetch the ticket by the provided ID. Extract:
- **Summary** (ticket title)
- **Description** (ticket body)
- **Issue type** (Bug, Story, Task, Epic, Sub-task, etc.)
- **Acceptance criteria** (if present in the description)

**If the fetch fails** (bad ID, network error, permissions):

> "Could not fetch ticket [ID]: [error reason]. You can:
> 1. Try a different ticket ID
> 2. Skip and continue without ticket context"

If the developer retries, repeat 0d. If they skip, proceed to Section 1.

### 0e. Display and confirm

Present the fetched ticket context:

> "Here's what I pulled from **[TICKET-ID]**:
>
> **Type:** [issue type]
> **Summary:** [summary]
> **Description:** [description, truncated if very long]
> **Acceptance Criteria:** [if present, otherwise "none listed"]
>
> Does this look right? (yes / try a different ticket / skip)"

- **try a different ticket** → return to 0c
- **skip** → proceed to Section 1 without ticket context
- **yes** → continue to 0f

### 0f. Route by issue type

**If issue type is "Bug":**

> "This is a bug ticket. Bugs follow a different workflow — root cause
> investigation before fixes, not a feature spec. Redirecting to
> `/kickoff` with the bug context so you don't have to re-enter it."

Then hand off to `/kickoff` with the following context stated explicitly
in the handoff message:
- **Work type:** bug
- **Ticket ID:** [the fetched ticket ID]
- **Ticket summary:** [summary]
- **Ticket description:** [description]
- **Acceptance criteria:** [if present]
- **Instruction to kickoff:** "Ticket context is pre-fetched. Skip the
  ticket prompt in DISCOVER. Proceed directly to branch setup and
  classify as bug."

**Stop the spec flow.** Do not proceed to Section 1.

**If issue type is anything other than "Bug"** (Story, Feature, Task,
Epic, Sub-task, Improvement, or any unrecognized type):

Treat as a feature. Pre-seed the Feature Summary section with the ticket
context:

> "Based on the ticket, here's a starting point for the feature summary:
>
> [Draft summary derived from ticket title and description]
>
> This is a starting point — not the spec. Let's refine it."

Then proceed to Section 1 (Feature Summary). Claude still asks the
developer to explain the feature in their own words. The ticket context
informs the conversation but does not replace the developer's articulation.

---

## Spec sections (developer writes all of these)

### 1. Feature summary
One paragraph. What is this feature? Who uses it? What problem does it solve?

**Claude's job**: Ask "why does this feature exist?" until the answer is
concrete and not generic. Push back on "we need this for users" — that's not
a reason, that's a category.

### 2. Acceptance criteria
A numbered list of concrete, testable statements. Format: "Given X, when Y,
then Z." Not vague goals — specific observable outcomes.

**Claude's job**: Push back on any criterion that can't be tested. "The UI
looks good" is not a criterion. "The modal closes within 300ms of clicking
confirm" is a criterion. Any criterion using the word "should" instead of
"will" needs to be rewritten.

Require at least three criteria. One criterion features are under-specified.

### 3. Explicit non-goals
What is this feature intentionally NOT doing?

**Claude's job**: Prompt for at least two non-goals. Developers almost always
forget this section. Non-goals prevent scope creep and help the developer
communicate constraints to the AI implementer.

### 4. Test spec
For each acceptance criterion, define:
- Happy path test: what does success look like in a test?
- Failure path test: what does failure look like? What should the system do?
- "How to break this test" check: describe one way to make this test a false
  positive. Confirm it can't happen accidentally.

**Claude's job**: For each acceptance criterion, Claude **proposes** all three
paths (happy, failure, false positive) based on the criterion and architecture
context. The developer then reviews, edits, or approves each suggestion.
Developers should not be expected to generate these from scratch — Claude
drafts, the developer refines. A spec without failure tests is still
incomplete, but the developer's job is curation and correction, not invention.

### 5. Architecture sketch
Before implementation: what files will change? What new files will be created?
What data flows through this feature? Draw it in words or pseudocode.

**Claude's job**: Ask "where does this data come from and where does it go?"
If the developer can't answer, they don't understand the feature yet. Do not
proceed to `/build` until this is answered.

### 6. Feature Flag Decision

Every spec records an explicit decision about feature flags. This is captured in two places: as YAML frontmatter at the top of `spec.md` (so downstream skills can parse it) AND as a human-readable section in the body.

**The frontmatter contract** — written at the top of `spec.md` immediately after the title line:

```yaml
---
flag:
  decision: yes | no | already-flagged
  semantics: kill-switch | adoption       # required if decision == yes
  expected_sunset: YYYY-MM-DD             # required if decision == yes
  touched_repos:                          # required if decision == yes
    - CasaPerks-Web-React
  reason: <one-line>                      # required if decision == no
---
```

**The body section** — restates the decision in prose for human readers and captures any rationale that doesn't fit in the frontmatter.

**Claude's job by branch:**

- **User-facing UI features** → require `decision: yes` or `already-flagged`. Run the eng-flags concerns guidance (key naming, semantics choice, sunset date — see `packs/engineering/skills/eng-flags/SKILL.md`).
- **Backend-only / internal config / docs-only** → `decision: no` is acceptable, but require a `reason` of at least 20 characters explaining why no flag is needed.
- **Already-flagged** (the feature lives behind an existing flag being expanded) → record the existing flag key in the body section and skip eng-flags invocation in the build.

**Red flag:** A `decision: no` with a one-character reason or whitespace-only reason. Reject and re-prompt.

### 7. Open questions
What does the developer not know yet? What assumptions are they making?

**Claude's job**: Surface assumptions the developer hasn't made explicit.
Common ones: "I'm assuming the API already exists," "I'm assuming auth is
handled upstream," "I'm assuming this data is already in the database."

If the developer says they have no open questions, push: "What would surprise
you during implementation? What are you most uncertain about?"

---

## Red flags (Claude watches for these)

Stop and surface explicitly before moving on:

- **Developer can't describe failure cases** → spec is not ready
- **Criteria use "should" instead of "will"** → too vague, rewrite required
- **No non-goals listed** → scope will creep
- **Architecture sketch is missing** → developer is guessing at implementation
- **Zero open questions** → developer is overconfident; probe harder

---

## Completion

When all six sections are solid, Claude produces the spec document.

**Save location**: Read `vault-path` and `project-name` from
`casaflow.config.md`. Create a feature directory and save the spec:

```
~/Documents/<project-name>/<feature-slug>/spec.md
```

Feature slug: lowercase, hyphens, derived from the feature name
(e.g., "Add checkout flow" → `~/Documents/casaflow/add-checkout-flow/spec.md`).

Create the feature directory if it does not exist.

**Mandatory final comprehension check** before handing off:

> "Spec complete. Before we start building: can you describe in your own
> words what happens when [most complex acceptance criterion]? I want to
> make sure the spec reflects your mental model before we write any code."

This check is not optional. Claude does not skip it and does not move on if
the answer is vague.

After the comprehension check passes, invoke the `jira-sync` skill if
configured. Then prompt the developer to start the full pipeline:

> "Spec saved. Run `/casaflow:kickoff` to start the development pipeline —
> it will set up your ticket, branch, design, plan, and guide you through
> the full build."

Do **not** hand off directly to `/build` — the developer needs the full
pipeline (discover → brainstorm → plan → execute → review → ship → learn).

---

## Spec file format

```markdown
---
ticket: <TICKET-ID>                    # if a ticket exists
ticket_url: <url>                       # if a ticket exists
work_type: feature | improvement | bug | task
date: YYYY-MM-DD
flag:
  decision: yes | no | already-flagged
  # If decision == yes, also include:
  semantics: kill-switch | adoption
  expected_sunset: YYYY-MM-DD
  touched_repos: [CasaPerks-Web-React, ...]
  # If decision == no, also include:
  reason: <one-line, ≥ 20 chars>
---

# Spec: [Feature Name]

Date: YYYY-MM-DD

## Feature Summary
[One paragraph]

## Acceptance Criteria
1. Given [context], when [action], then [outcome].
2. Given [context], when [action], then [outcome].
...

## Non-Goals
- [What this explicitly does not do]
- [What this explicitly does not do]

## Test Spec
### Criterion 1: [criterion text]
- Happy path: [what success looks like in a test]
- Failure path: [what failure looks like; what the system should do]
- False positive check: [one way this test could pass when it shouldn't]
...

## Architecture Sketch
[Files that change, data flow, pseudocode]

## Feature Flag Decision
[Restate the frontmatter decision in prose; include rationale.]

## Open Questions
- [Assumption or unknown]
- [Assumption or unknown]
```
