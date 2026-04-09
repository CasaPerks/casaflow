---
description: "Use when starting development work on a bug, feature, improvement, or task. Orchestrates the full pipeline: discover, brainstorm, plan, execute, review, ship."
---

# CasaFlow Development Pipeline

**PURPOSE**: The pipeline orchestrator. Ensures every task flows through a
predictable sequence of stages with quality checks at each transition.

**CASAFLOW ADDITION**: For `feature` and `improvement` work types, this skill
enforces a **spec-first gate** — no brainstorming or planning begins until a
feature spec exists. This is not optional; it is the primary mechanism by which
developers stay in comprehension of what they're building.

**CONFIGURATION**: Reads `casaflow.config.md` for
pipeline stages, work type overrides, ticket system, branching format, and
concerns checklist.

---

## When to Use

Invoke this skill when:
- Starting development work of any kind
- "I need to add/fix/build/improve..."
- "Let's work on [ticket]"
- "There's a bug in..."
- Beginning a new session with a development task

**Do NOT use when** you only need a single stage (e.g., just creating a PR —
use `pr-create` directly).

---

## Step 1: Classify the Work

Determine work type before anything else.

```
BUG           — broken / incorrect behavior
IMPROVEMENT   — making an existing thing better
FEATURE       — new capability
TASK / CHORE  — config, refactor, dependency update
```

Ask the user if the type isn't obvious from context.

**Spec gate applies to**: `feature`, `improvement`
**Spec gate skipped for**: `bug`, `task`

---

## Step 2: Spec Gate (features and improvements only)

**This gate runs before DISCOVER, BRAINSTORM, or PLAN.**

1. Derive a slug from the work description (e.g., "add checkout flow" →
   `add-checkout-flow`).
2. Read `vault-path` and `project-name` from `casaflow.config.md`.
3. Check whether `~/Documents/<project-name>/<slug>/spec.md` exists and is
   non-empty.

**If no spec exists:**

> "No spec found for this feature. A spec is required before we write any
> code — it's how we make sure you understand what you're building before
> delegating to AI.
>
> Run `/casaflow:spec` and I'll guide you through writing it. When the spec
> is done, run `/casaflow:kickoff` again and we'll pick up from here."

Then **stop**. Do not enter DISCOVER, BRAINSTORM, or PLAN.

**If spec exists:**

Load `~/Documents/<project-name>/<slug>/spec.md` into context. Proceed to
Step 3 with the spec as the grounding document for all subsequent stages.
The spec's acceptance criteria become the pipeline's definition of done.

**For bugs and tasks:** Skip this step entirely. Proceed directly to Step 3.

---

## Step 3: DISCOVER

**Gate**: A ticket exists and the problem is understood.

1. **Check for existing ticket**: Read `casaflow.config.md` for `ticket-system`
   and use the appropriate integration. If on Jira and a ticket key was
   provided, fetch it. If no ticket exists, ask whether to create one.

2. **Understand the problem**:
   - For features: load the spec. Confirm scope matches.
   - For bugs: check error context, reproduce if possible.
   - For improvements: confirm existing behavior before proposing changes.

3. **Set up the branch**: Read `branching.format` from config.

**Gate check:**
- [ ] Ticket exists (or user opted to skip tracking)
- [ ] Branch created following naming convention
- [ ] Problem is understood, not just the title

---

## Step 4: BRAINSTORM

**Gate**: A design is approved by the user.

For **features**: full brainstorm with concerns checklist. The spec defines
*what* — brainstorm defines *how*. Do not re-litigate what's in the spec.

For **improvements**: medium brainstorm — existing patterns, 2-3 approaches,
tradeoffs.

For **bugs**: light brainstorm — root cause, minimal fix, regression risk,
test plan.

For **tasks/chores**: skip. Move to PLAN.

Run the concerns checklist from `casaflow.config.md`. Walk through each
concern explicitly. Mark N/A if it doesn't apply — do not skip silently.

**Gate check:**
- [ ] Design approved by user
- [ ] Concerns checklist completed
- [ ] Design doc saved to `~/Documents/<project-name>/<feature-slug>/design.md`

---

## Step 5: PLAN

**Gate**: A numbered plan exists with tasks, files, and verification steps.

Invoke `plan`. Every plan must include:
- Numbered tasks scoped to 2-5 minutes each
- File paths per task (create vs modify)
- Dependency relationships (`blockedBy`)
- Verification steps per task
- Commit message per task

Save to `~/Documents/<project-name>/<feature-slug>/plan.md`.

If a spec and/or PRD exists, include a header reference:
```
> **Spec:** ~/Documents/<project-name>/<feature-slug>/spec.md
> **For Claude:** Use `build` to execute this plan.
```

**Gate check:**
- [ ] Plan reviewed and approved
- [ ] Tasks have clear file paths
- [ ] Dependencies identified
- [ ] Plan saved

---

## Step 6: EXECUTE

**Gate**: All tasks implemented, tested, and committed.

Invoke `build`. It auto-selects parallel (`team-dev`) or serial (`sdd`) based
on the task graph and `casaflow.config.md` settings.

**CasaFlow addition**: At the end of each build stage, `build` invokes the
`approve-gate` skill. The developer must pass three comprehension questions
before the next stage begins. This is not optional.

**Gate check:**
- [ ] All plan tasks implemented
- [ ] Tests pass
- [ ] Changes committed
- [ ] All approve-gate questions answered for each stage

---

## Step 7: REVIEW

**Gate**: Code passes specialist swarm and self-audit.

Run `review` — dispatches parallel specialist swarm (security, dead-code,
error-handling, async-safety, performance). Fix Critical and Major issues
before creating a PR.

For the final stage (Polish), `review-tests` runs as part of the approve-gate
before the swarm — test quality is evaluated before code quality.

**Gate check:**
- [ ] No Critical issues in review report
- [ ] Major issues addressed or acknowledged with rationale

---

## Step 8: SHIP

**Gate**: PR created and merged.

1. `commit` agent — conventional commit with scope
2. `pr-create` — runs review swarm first, then writes PR description
3. `pr-respond` — address reviewer feedback
4. Merge

If Jira is configured, `pr-create` posts the PR URL as a comment on the
ticket and optionally transitions the ticket status.

---

## Step 9: LEARN

After merge, prompt:

> "Feature shipped. Run `/casaflow:retro` while it's fresh — it takes
> 10 minutes and the output becomes a team artifact."

Then invoke `postmortem` to analyze reviewer patterns and update skills.

---

## Stage Transition Map

```
CLASSIFY
  └──> [SPEC GATE — features/improvements only]
         └──> DISCOVER
                ├──> BRAINSTORM (features, improvements, bugs)
                │    └──> PLAN
                └──> PLAN (tasks skip brainstorm)
                       └──> EXECUTE (with approve-gate per stage)
                              └──> REVIEW
                                     └──> SHIP
                                            └──> LEARN
```

---

## Quick Reference

| Stage | CasaFlow addition |
|-------|-----------------|
| Classify | Determines spec gate applicability |
| Spec Gate | Hard stop if no spec for features/improvements |
| Discover | Jira ticket lookup/creation |
| Brainstorm | Concerns checklist from config |
| Plan | Spec acceptance criteria as definition of done |
| Execute | approve-gate after every stage |
| Review | review-tests before swarm on final stage |
| Ship | Jira status update + PR URL comment |
| Learn | retro prompt + postmortem |
