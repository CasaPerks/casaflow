# CasaFlow Plugin — Design Plan

**Date:** 2026-03-31
**Author:** Zak DeBrine
**Status:** Draft — ready for implementation

---

## Overview

CasaFlow is a fork/extension of the Jig framework, tuned for CasaPerks
codebases and engineering culture. It takes Jig's battle-tested pipeline
infrastructure and layers on CasaPerks' proven philosophy of
**comprehension-first development**.

The goal is a single plugin — installed into any CasaPerks repo — that
delivers on all four priorities:

| Priority | How CasaFlow addresses it |
|----------|--------------------------|
| **Speed** | Jig's parallel execution engine (team-dev), task graph analysis, PR automation |
| **Dev comprehension** | CasaPerks' approval gates with 3 mandatory comprehension questions per stage |
| **Code robustness** | Jig's review swarm (5 specialists), TDD discipline, mutation testing |
| **Developer education** | Explain command, failure-mode documentation, retro artifacts |

---

## Strategy: Jig as the Foundation, CasaPerks as the Lens

Rather than building from scratch or keeping two separate plugins, we
**evolve the jig repo into CasaFlow** using Jig's own discovery system
against itself:

```
team/           ← CasaPerks overrides (our customizations)
packs/          ← jira pack (flesh it out), engineering pack (unchanged)
core/           ← Jig defaults (mostly unchanged)
```

The `team/` directory is where CasaFlow lives. It overrides specific
core skills and adds CasaPerks-specific behavior. When a consumer installs
CasaFlow, they get all of Jig's infrastructure PLUS our team overrides
automatically.

We rename the plugin from `jig` → `casaflow` in `plugin.json`. Commands
become `/casaflow:` prefixed. The `casaflow.config.md` template gets a
`casaflow.config.md` variant with CasaPerks-specific defaults.

---

## Key Differences from Vanilla Jig

### 1. Spec-First Enforcement (CasaPerks Gate #0)

In vanilla Jig, `kickoff` goes directly from classification to brainstorm.
In CasaFlow, `kickoff` adds a hard gate: **no code until a spec exists**.

If no spec exists for the feature → invoke the CasaPerks `/spec` flow
(developer drives, Claude asks questions, spec saved to `specs/`).

If a spec exists → proceed normally into brainstorm/plan.

This is the single biggest philosophical addition. It forces developers to
articulate what they're building before any code is generated.

### 2. Approval Gates Baked Into Build

In vanilla Jig, `build` and `team-dev` focus on execution speed. They
have a `verify` step but no comprehension check.

In CasaFlow, every stage completion triggers the CasaPerks
**approve-gate protocol**:
- Stage report (files changed, how to run, what to test manually, deferrals,
  tradeoffs)
- Three comprehension questions (structural, failure-mode, change-impact)
- Hard stop — next stage does not begin until developer answers all three
  correctly

This is plugged in as a `team/skills/approve-gate/` override that extends
the core `verify` skill behavior.

### 3. Jira-Aware Pipeline

The Jira pack (`packs/jira/`) gets fleshed out with the full 7-step
protocol from casaperks-workflow. Every stage completion optionally syncs
status to Jira. The spec-writing flow auto-syncs the spec as a comment on
the ticket.

### 4. Enhanced Explain Command

CasaPerks' `/explain` is more education-focused than anything in vanilla
Jig. We add it as a `team/skills/explain/` skill with the five-section
format (approach/tradeoffs, failure modes, change surface, what to test,
what to refactor).

### 5. Mutation-Based Test Review

CasaPerks' `review-tests` (four-phase audit including mutation testing) is
more rigorous than Jig's `eng-testing`. We add it as
`team/skills/review-tests/` and wire it into the stage 4 (Polish) review.

### 6. Retro Artifacts

CasaPerks' `/retro` becomes `team/skills/retro/`, wired into Jig's `LEARN`
stage. Output is saved to `retros/<feature>.md` and Claude notes recurring
patterns across runs.

---

## Implementation Plan

### Phase 1 — Rename and Restructure

**Goal:** Turn the jig repo into casaflow with the right identity.

**Tasks:**

1. **Update `.claude-plugin/plugin.json`**
   - `name`: `casaflow`
   - `description`: "CasaPerks AI engineering workflow — spec-first,
     comprehension-gated, Jira-native."
   - `version`: `1.0.0`
   - `author`: `{ "name": "Zak DeBrine" }`
   - `repository`: `https://github.com/CasaPerks/casaflow` (update after
     repo rename)
   - Add `team/` skills to the `skills` array (below)

2. **Create `team/` directory structure**
   ```
   team/
   ├── README.md
   ├── skills/
   │   ├── kickoff/SKILL.md       ← Override: spec-first gate
   │   ├── approve-gate/SKILL.md  ← New: CasaPerks approval gate
   │   ├── explain/SKILL.md       ← New: 5-section education explain
   │   ├── review-tests/SKILL.md  ← New: mutation testing audit
   │   ├── retro/SKILL.md         ← New: post-feature retrospective
   │   └── spec/SKILL.md          ← New: spec-writing guidance
   ├── agents/
   │   └── (empty for now)
   └── specialists/
       └── (empty for now)
   ```

3. **Create `casaflow.config.md` in `scaffold/`**
   - CasaPerks-specific defaults
   - Jira as default ticket-system
   - Approval gates: `enabled: true`
   - Stage definitions: scaffold → backend → frontend → polish

4. **Update command files in `commands/`**
   - Add: `spec.md`, `approve.md`, `explain.md`, `review-tests.md`,
     `retro.md`
   - Update: `kickoff.md` description to mention spec-first requirement
   - Update namespace references from `jig:` to `casaflow:` (or keep
     both — see note below)

   > **Note on namespace:** We can keep `/jig:` commands working alongside
   > `/casaflow:` commands during transition. Just update `plugin.json`
   > name. All commands are loaded by name so existing muscle memory works.

5. **Rename `casaflow.config.md` to `casaflow.config.md`** in self-install.
   Update `CLAUDE.md` references.

**Deliverables:** Plugin loads as `casaflow`, `team/` directory exists,
scaffold has CasaPerks config template.

**Tests:** `cat .claude-plugin/plugin.json | grep name` returns `casaflow`.
`ls team/skills/` shows expected directories.

---

### Phase 2 — Spec-First Gate (Override kickoff)

**Goal:** `kickoff` refuses to plan or build until a spec exists for the
feature.

**File:** `team/skills/kickoff/SKILL.md`

**Behavior change:**

When a developer runs `/casaflow:kickoff` (or `kickoff` is invoked by
another skill):

1. Classify work type as normal (bug/feature/improvement/task)
2. For `feature` and `improvement` work types:
   - Check if `~/Documents/<project-name>/<feature-slug>/spec.md` exists
   - If NO spec exists:
     - Say "No spec found for this feature. Run `/casaflow:spec <name>`
       first."
     - Invoke `spec` skill
     - **Hard stop** — do not enter brainstorm/plan until spec is written
   - If spec exists:
     - Load spec into context
     - Proceed to brainstorm/plan as normal, with spec as grounding
3. For `bug` and `task` work types:
   - Skip spec requirement (bugs and tasks don't need full specs)
   - Proceed normally

**Key rule:** This override inherits everything from core `kickoff` and
adds the spec gate. The spec file becomes the acceptance criteria for the
entire pipeline.

**Tradeoff note:** Bug fixes don't get gated because requiring a spec for
"fix the null pointer on checkout" creates friction without education
value. Features and improvements are where specs produce the biggest
learning return.

**Tests:**
- Run kickoff on a feature with no spec → spec flow is invoked
- Run kickoff on a feature with spec → proceeds to brainstorm
- Run kickoff on a bug → no spec required

---

### Phase 3 — Approval Gate Skill

**Goal:** After every stage completion, developer must pass three
comprehension questions before next stage begins.

**File:** `team/skills/approve-gate/SKILL.md`

**This is a direct port of CasaPerks' approve-gate skill.** Key sections:

**Stage Report (generated automatically after each stage):**
- Files changed (path, purpose, coupling)
- How to run (exact commands, URLs, interactions)
- What to test manually (checklist: action → expected result)
- What was deferred and why
- Tradeoffs made (chosen approach + alternatives considered + downsides)

**Comprehension Check (3 questions, all must pass):**

1. **Structural:** "Walk me through what happens when [key interaction].
   Start from the user action and trace it to the data layer."
2. **Failure mode:** "What happens in the code if [realistic failure
   condition]? Where would you look to debug it?"
3. **Change impact:** "If we needed to change [specific thing just built],
   what other files would you need to touch and why?"

**Gate outcomes:**
- **Pass** → Confirm stage complete, describe next stage, list any concerns
- **Fail** → Re-state what was misunderstood, ask question differently, do
  not proceed
- **Redirect** → Developer specifies change; small changes skip re-question,
  large changes require new gate

**Wiring into the pipeline:** This skill is invoked by name from the
`build` flow at the end of each stage. It is also invoked by the
`/casaflow:approve` command directly.

**Stage definitions (in casaflow.config.md):**

```yaml
Stages:
  1: scaffold     # Project structure, deps, config, CI skeleton
  2: backend      # API endpoints, data layer, auth, validation, security
  3: frontend     # UI components, API integration, error handling, UX
  4: polish       # Tests, docs, edge cases, performance, accessibility
```

Teams can override these in their own `casaflow.config.md`.

**Tests:**
- Incomplete answer → gate fails, question re-asked
- Correct answers to all 3 → gate passes
- Never moves to next stage without explicit approval

---

### Phase 4 — Flesh Out Jira Pack

**Goal:** Full 7-step Jira sync protocol, wired into spec flow and
stage updates.

**File:** `packs/jira/skills/jira-sync/SKILL.md`

This is a direct port and enhancement of CasaPerks' `jira-sync` skill.

**7-Step Protocol (from casaperks-workflow, preserved exactly):**

1. **Ask whether to sync** — Developer opts in or skips
2. **Gather context** — Jira project key + current state (neither/epic-only/both)
3. **Generate summary** — Feature name, 2-3 sentence description, acceptance
   criteria, non-goals
4. **Show preview** — Developer approves before any MCP call
5. **Execute** — Create/update epic + ticket based on state
6. **Verify** — Read back by key, confirm description and comment exist
7. **Confirm and hand off** — Output ticket key, proceed to `/build`

**New in CasaFlow vs. casaperks-workflow:** Stage-level updates.

After each approved stage, optionally update Jira ticket status:
- Stage 1 complete → transition ticket to "In Progress"
- Stage 4 complete → transition ticket to "In Review" / "Done"
- PR created → post PR URL as comment on ticket

This closes the loop between code and Jira without requiring manual updates.

**Configuration (in casaflow.config.md):**

```yaml
Ticket-system: jira
Jira:
  auto-sync-spec: true
  auto-update-on-stage: true
  project-key: CASA          # Default project key (override per repo)
  done-on-merge: true
```

**Prerequisite check:** Before invoking any Jira MCP tools, check that
`atlassian` MCP server is configured. If not → skip gracefully, never block.

**Tests:**
- Spec written, Jira configured → sync flow invoked after spec save
- Jira not configured → spec flow completes, warning shown, build continues
- Stage approved → Jira ticket status updated (if auto-update enabled)
- MCP call fails → graceful fallback, manual instructions provided

---

### Phase 5 — Explain Skill

**Goal:** Deep technical explanation with failure-mode focus, education
over summary.

**File:** `team/skills/explain/SKILL.md`

Direct port of CasaPerks' `/explain` with Jig-style formatting.

**Five sections (non-negotiable):**

1. **Approach and tradeoffs** — Why this implementation over alternatives.
   Name at least two alternatives considered and their downsides.
2. **Failure modes** — Three most likely production failures:
   - What triggers it
   - What the symptom looks like from outside
   - Where to look in code to diagnose it
3. **Change surface** — If [specific behavior] changed, what files to touch
   and why. Traces dependency graph.
4. **What to test** — Three most important tests + the bug each test catches
   if production code is broken.
5. **What to refactor** — One specific improvement with file path, line
   range, and approach.

**Invocation modes:**
- `/casaflow:explain` — Explains most recently written code
- `/casaflow:explain <file>` — Explains specific file
- `/casaflow:explain <function>` — Explains specific function

**Key constraint:** Never produces a code summary. Always focused on mental
model transfer. If Claude is tempted to list what the code does, it should
instead explain why it does it that way and what would break if it did it
differently.

---

### Phase 6 — Review-Tests Skill

**Goal:** Four-phase test quality audit with mutation testing.

**File:** `team/skills/review-tests/SKILL.md`

Direct port of CasaPerks' `review-tests` skill. This supplements Jig's
`eng-testing` pack skill (which provides test strategy) with rigorous
quality evaluation after implementation.

**Four phases:**

**Phase 1 — Coverage Audit**
Build coverage table for each spec criterion:
```
✓ = tested  ✗ = not tested  ~ = partially tested
```

**Phase 2 — False Positive Detection (mutation testing)**
For each test in the suite:
- Claude proposes a mutation to the production code that should break the test
- Developer makes the mutation
- Developer runs the test
- If test still passes → false positive detected, test needs strengthening

**Phase 3 — Test Quality Rubric**
Score each test across five dimensions:
1. Isolation (no shared state between tests)
2. Specificity (tests one thing, asserts one outcome)
3. Realistic inputs (uses production-realistic data, not trivial fixtures)
4. Edge cases (null, empty, overflow, concurrent access)
5. Behavior over implementation (tests what it does, not how)

**Phase 4 — Summary**
- Letter grade: A / B / C / D
- Action items with file:line references
- What's already solid (don't touch these)

**After review:** Developer chooses to fix issues themselves or have Claude fix
them. Either way, re-running `/casaflow:review-tests` after fixes grades the
improvements.

**Wiring:** Automatically invoked at end of Stage 4 (Polish) in the
`approve-gate` flow, before the stage gate questions.

---

### Phase 7 — Retro Skill

**Goal:** Post-feature retrospective that produces living team learning
artifacts.

**File:** `team/skills/retro/SKILL.md`

Direct port of CasaPerks' `/retro`. Wired into Jig's `LEARN` stage.

**Five questions (conversational, one at a time, wait for real answer):**

1. What surprised you? (unexpected complexity — what was harder than spec implied)
2. What would you spec differently? (what ambiguity caused rework)
3. What did you learn about the codebase? (architecture discoveries, hidden coupling)
4. What did you learn about AI-assisted development? (when AI was wrong/misleading)
5. What's your one rule for next time? (specific, checkable, yours)

**Output:** Saved to `retros/<feature-name>.md`

**Pattern detection:** Claude notes if a recurring theme appears across
multiple retros in the same directory. Example: "I notice 'unexpected
coupling to UserService' has come up in 3 retros. Worth a dedicated
refactor session?"

**Wiring:** `/casaflow:retro` invoked by `finish` skill after merge, or
by developer directly.

---

### Phase 8 — CasaPerks Config Template

**Goal:** Teams using CasaFlow get sensible defaults for CasaPerks repos.

**File:** `scaffold/casaflow.config.md`

```markdown
# CasaFlow Config

## Team

name=<your-team-name>
platform=claude
git-host=github
ticket-system=jira

## Pipeline

stages=discover,brainstorm,plan,execute,review,ship,learn
work-types=bug,feature,improvement,task

## Spec Gate

spec-required-for=feature,improvement
spec-dir=specs/

## Approval Gates

gates-enabled=true
stages=scaffold,backend,frontend,polish

## Jira

project-key=<YOUR-PROJECT-KEY>
auto-sync-spec=true
auto-update-on-stage=true
done-on-merge=true

## Branching

format="{username}/{ticket-id}-{kebab-title}"
main-branch=main

## Concerns

# Skills invoked during brainstorm based on work type
error-handling: feature, improvement
security: feature, improvement
test-strategy: feature, improvement
eng-testing: feature, improvement, bug

## Review

fast-pass-model=claude-sonnet-4-6
full-review-model=claude-opus-4-6
specialist-model-default=claude-haiku-4-5-20251001

## Execution

parallel-threshold=3
strategy=team-dev

## Commit

convention=conventional
scopes=[]          # Fill in your team's scopes

## Retro

auto-prompt=true   # Prompt for retro after finish
retro-dir=retros/
```

---

## Updated Plugin Manifest

`plugin.json` after all phases complete:

```json
{
  "name": "casaflow",
  "version": "1.0.0",
  "description": "CasaPerks AI engineering workflow — spec-first, comprehension-gated, Jira-native. Combines Jig's pipeline infrastructure with CasaPerks' education philosophy.",
  "author": { "name": "Zak DeBrine" },
  "repository": "https://github.com/CasaPerks/casaflow",
  "license": "MIT",
  "commands": "./commands/",
  "skills": [
    "./team/skills/kickoff",
    "./team/skills/spec",
    "./team/skills/approve-gate",
    "./team/skills/explain",
    "./team/skills/review-tests",
    "./team/skills/retro",
    "./core/skills/brainstorm",
    "./core/skills/prd",
    "./core/skills/plan",
    "./core/skills/build",
    "./core/skills/team-dev",
    "./core/skills/sdd",
    "./core/skills/review",
    "./core/skills/pr-create",
    "./core/skills/pr-respond",
    "./core/skills/postmortem",
    "./core/skills/debug",
    "./core/skills/verify",
    "./core/skills/tdd",
    "./core/skills/finish",
    "./core/skills/ticket",
    "./core/skills/extend",
    "./packs/engineering/skills/eng-copywriting",
    "./packs/engineering/skills/eng-logging",
    "./packs/engineering/skills/eng-testing",
    "./packs/jira/skills/jira-sync"
  ],
  "agents": [
    "./core/agents/commit.md",
    "./core/agents/code-reviewer.md",
    "./core/agents/pr-reviewer.md"
  ]
}
```

---

## New Commands to Add

| Command file | Slash command | Maps to skill |
|---|---|---|
| `commands/spec.md` | `/casaflow:spec` | `team/skills/spec` |
| `commands/approve.md` | `/casaflow:approve` | `team/skills/approve-gate` |
| `commands/explain.md` | `/casaflow:explain` | `team/skills/explain` |
| `commands/review-tests.md` | `/casaflow:review-tests` | `team/skills/review-tests` |
| `commands/retro.md` | `/casaflow:retro` | `team/skills/retro` |

Existing commands stay unchanged (kickoff, build, debug, etc.).

---

## Full Workflow — How It Hangs Together

```
Developer starts a feature:

/casaflow:kickoff "add checkout flow"
  ↓
[Kickoff classifies as: feature]
  ↓
[Checks: does specs/add-checkout-flow.md exist?]
  NO → invokes /casaflow:spec
         Developer answers questions, spec saved
         Jira sync: creates epic + ticket, attaches spec
  YES → loads spec, proceeds
  ↓
[Brainstorm] — Design exploration with concerns checklist
  ↓
[Plan] — Spec → task graph with TDD tasks
  ↓
[Build — Stage 1: Scaffold]
  → team-dev executes in parallel
  → Stage complete
  → approve-gate: stage report + 3 comprehension questions
  → Developer passes gate → /casaflow:approve
  → Jira: ticket moves to "In Progress"
  ↓
[Build — Stage 2: Backend]
  → Same pattern
  ↓
[Build — Stage 3: Frontend]
  → Same pattern
  ↓
[Build — Stage 4: Polish]
  → review-tests invoked automatically (4-phase audit)
  → approve-gate: final stage gate
  ↓
[Review] — Full specialist swarm (security, dead-code, error-handling,
           async-safety, performance)
  ↓
[PR Create] — Review swarm runs first, then PR description written
  → Jira: PR URL posted as comment on ticket
  ↓
[PR Respond] — Fetches comments, fixes, replies, resolves
  ↓
[Finish] — Merge, clean worktrees
  → Jira: ticket transitions to Done
  → Prompts: /casaflow:retro
  ↓
[Retro] — 5 questions, saved to retros/
```

---

## Files to Create / Modify

### New Files

| File | Phase | Notes |
|------|-------|-------|
| `team/README.md` | 1 | CasaPerks overrides guide |
| `team/skills/kickoff/SKILL.md` | 2 | Spec-first gate override |
| `team/skills/spec/SKILL.md` | 2 | Port casaperks spec-writing skill |
| `team/skills/approve-gate/SKILL.md` | 3 | Port casaperks approve-gate skill |
| `team/skills/explain/SKILL.md` | 5 | Port casaperks explain skill |
| `team/skills/review-tests/SKILL.md` | 6 | Port casaperks review-tests skill |
| `team/skills/retro/SKILL.md` | 7 | Port casaperks retro skill |
| `packs/jira/skills/jira-sync/SKILL.md` | 4 | Port casaperks jira-sync skill |
| `scaffold/casaflow.config.md` | 8 | CasaPerks config template |
| `commands/spec.md` | 1 | New slash command |
| `commands/approve.md` | 1 | New slash command |
| `commands/explain.md` | 1 | New slash command |
| `commands/review-tests.md` | 1 | New slash command |
| `commands/retro.md` | 1 | New slash command |

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| `.claude-plugin/plugin.json` | 1 | Rename to casaflow, add team skills |
| `commands/kickoff.md` | 1 | Add note about spec requirement |
| `casaflow.config.md` | 1 | Update to casaflow.config.md format |
| `CLAUDE.md` | 1 | Update for CasaFlow identity |
| `README.md` | 1 | CasaFlow public docs |
| `packs/jira/pack.json` | 4 | Add jira-sync skill to pack |

---

## Open Questions

1. **Namespace:** Keep `/jig:` commands or rename everything to `/casaflow:`?
   Recommendation: rename `plugin.json` name field only. Commands load by
   plugin name prefix, so consumers see `/casaflow:kickoff` automatically.

2. **Repo strategy:** Fork `duronext/jig` into a new `casaflow` repo, or
   maintain as a fork? Recommendation: new repo. CasaFlow will diverge
   enough that syncing upstream becomes a maintenance burden.

3. **Consumer install:** How do CasaPerks repos install this?
   Add to their `.claude/settings.json`:
   ```json
   {
     "enabledPlugins": { "casaflow@casaperks-casaflow": true },
     "extraKnownMarketplaces": {
       "casaperks-casaflow": {
         "source": { "source": "github", "repo": "CasaPerks/casaflow" }
       }
     }
   }
   ```

4. **Jira MCP prerequisite:** The Jira sync only works if the developer
   has the Atlassian MCP server configured. Should we add a `bootstrap`
   command that checks and guides setup? Recommendation: yes, add a
   `/casaflow:bootstrap` command in Phase 9 (optional future phase).

5. **Stage count:** CasaPerks has 4 fixed stages. Jig's build skill is
   more flexible. Should CasaFlow enforce exactly 4 stages, or allow
   config-driven stage counts? Recommendation: default to 4 but allow
   override in `casaflow.config.md`.

---

## Build Order

```
Phase 1: Rename + Restructure (plugin identity, directories, commands)
Phase 2: Spec-First Gate (kickoff override + spec skill)
Phase 3: Approval Gates (approve-gate skill, wired into build)
Phase 4: Jira Pack (full jira-sync protocol)
Phase 5: Explain Skill
Phase 6: Review-Tests Skill
Phase 7: Retro Skill
Phase 8: Config Template
```

Each phase is independently releasable. Phase 1 alone makes a working
casaflow plugin. Each subsequent phase adds a new capability.

---

## Success Criteria

After all phases:

- [ ] `cat .claude-plugin/plugin.json | grep '"name"'` returns `casaflow`
- [ ] `/casaflow:kickoff "new feature"` refuses to proceed without spec
- [ ] `/casaflow:spec "new feature"` creates `specs/new-feature.md`
- [ ] After spec: Jira sync flow is offered (if MCP configured)
- [ ] After each build stage: 3 comprehension questions are asked
- [ ] Stage does not advance until all 3 are answered correctly
- [ ] `/casaflow:explain` produces 5-section failure-mode analysis
- [ ] `/casaflow:review-tests` includes mutation testing phase
- [ ] After merge: `/casaflow:retro` is prompted automatically
- [ ] Consumer repo install works via `settings.json` marketplace config
- [ ] All 5 new skills load without errors (`find team/ -name SKILL.md`)
- [ ] Jira sync gracefully skips when MCP not configured
