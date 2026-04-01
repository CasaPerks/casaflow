# Getting the Most Out of CasaFlow

CasaFlow is an AI engineering workflow built on one premise: **the developer must
understand what they're building, even when an AI is building it for them.**

This guide walks you through the philosophy behind every stage of the pipeline and
how to engage it in a way that makes you a better engineer — not just a faster one.

---

## The Philosophy

Most AI dev tools optimize for speed. CasaFlow optimizes for **comprehension first,
speed second** — because an engineer who doesn't understand their own codebase will
accumulate debt faster than any AI can generate it.

CasaFlow's four priorities, in order:

1. **Speed** — ship features without unnecessary friction
2. **Dev comprehension** — you own the code Claude writes
3. **Code robustness** — quality gates before every PR
4. **Developer education** — every session leaves you knowing more than when you started

The workflow is designed so that cutting corners on comprehension is harder than
just doing the work. That friction is intentional. Lean into it.

---

## The Full Pipeline

```
[SPEC] → DISCOVER → BRAINSTORM → PLAN → EXECUTE → REVIEW → SHIP → LEARN
  ↑                                          ↑
  Hard gate for features              Approve-gate after
  (no code without a spec)            every build stage
```

Every feature flows through every stage. Every bug flows through a lighter version.
There are no shortcuts past the spec gate or the approval gates for features — but
everything else is designed to move fast once those gates are passed.

---

## Stage by Stage

### 1. The Spec — `/casaflow:spec`

**Run this before anything else on a feature or improvement.**

The spec is not a formality. It is the mechanism by which you prove to yourself —
before a single line of code is written — that you understand what you're building.
A developer who can't spec a feature can't evaluate whether Claude's implementation
is correct.

**Claude will not write the spec for you.** It will interview you until you've
written it yourself. This is deliberate.

The spec has six sections:

| Section | What you're proving |
|---------|-------------------|
| Feature summary | You can state the problem in one paragraph without jargon |
| Acceptance criteria | You can define "done" in testable, specific terms |
| Non-goals | You know what this feature deliberately doesn't do |
| Test spec | You've thought through failure paths, not just the happy path |
| Architecture sketch | You know which files change and why before touching code |
| Open questions | You've surfaced your assumptions before they become bugs |

**How to get the most from the spec:**

- Write acceptance criteria as `Given / When / Then` statements. Vague criteria
  ("the UI should be responsive") will get pushed back on.
- List at least two non-goals. This is where scope creep gets stopped before it
  starts.
- Fill out the architecture sketch even if it's rough. Drawing the data flow in
  words before implementation catches misunderstandings early.
- Don't skip open questions. If you genuinely have none, Claude will push until
  you find some — because "no unknowns" almost always means unexplored assumptions.

The spec saves to `specs/<feature-slug>.md`. `/casaflow:kickoff` will not proceed
without it for features and improvements.

---

### 2. Kickoff — `/casaflow:kickoff`

**Run this to start the full pipeline.** It reads your spec and config, then
orchestrates every subsequent stage.

Kickoff handles:
- Finding or creating your Jira ticket
- Setting up your branch following the team naming convention
- Running the **concerns checklist** from `casaflow.config.md` during brainstorm
  (security, error-handling, test strategy, etc.)
- Generating a numbered plan where every task has file paths and verification steps

The brainstorm stage is where design happens. For features: the spec defined *what* —
brainstorm defines *how*. Don't skip it. The concerns checklist is walked explicitly
and marked N/A if it doesn't apply. Silent skips aren't allowed.

The plan that comes out of kickoff is Claude's contract for the build. The spec's
acceptance criteria are the definition of done.

---

### 3. Build — `/casaflow:build`

**Run this to execute the plan.** Claude auto-selects parallel or serial execution
based on the task graph and your config.

The real value here is not the code — it's the **approval gate** that fires after
every stage.

#### The Approval Gate — the heart of CasaFlow

After each build stage (Scaffold → Backend → Frontend → Polish), Claude pauses and
does two things before you can continue:

**Part 1 — Stage report**

Claude produces:
- Every file changed, with one sentence on why it exists and what breaks if it's removed
- Exact commands to run the app and exercise what was just built
- A manual test checklist derived from your spec's acceptance criteria
- An honest list of what was deferred and why
- The tradeoffs made — what was chosen, what the alternative was, what the downside is

Read this. Don't skim it. The tradeoffs section in particular is where the real
design knowledge lives.

**Part 2 — Three comprehension questions**

Claude asks exactly three questions, specific to what was just built:

1. **Structural** — trace a key interaction from user action to data layer
2. **Failure mode** — what happens when a realistic failure condition hits, and where do you look?
3. **Change impact** — if a specific thing needed to change, what other files would you touch?

You must answer all three correctly before the next stage begins. These questions
aren't a quiz — they're a calibration. If you can't answer them cleanly, that's a
signal to slow down, not a reason to feel bad. The next stage will be harder to
debug if you proceed without the mental model.

**How to get the most from the approval gate:**

- Answer in your own words, not by repeating back the code. "The middleware checks
  the token, and if it's expired it redirects" is a real answer. "It calls
  `verifyToken()`" is not.
- If your answer reveals a gap, ask Claude to explain the code path before continuing.
  That's what the gate is for.
- Don't rush. A five-minute pause here saves an hour of debugging later.

---

### 4. Explain — `/casaflow:explain`

**Use this aggressively. Don't wait until you're confused.**

`/casaflow:explain` gives you a deep technical explanation of any code just written.
You can target it at a file, a function, a stage number, or just run it on the most
recent increment.

It produces five sections — not summaries, but mental models:

| Section | What you get |
|---------|-------------|
| Approach and tradeoffs | Why this approach? What were the alternatives? What's the downside? |
| Failure modes | The 3 most likely production failures, with exact file/function locations |
| Change surface | Which files cascade if requirements shift, and in what order |
| What to test | The most important tests and what specific bugs they'd catch |
| What to refactor | One specific thing, with exact location, if you had one more pass |

The rule: Claude never summarizes the code. Every section answers "why" or "what
happens if." You can read the code. What you need is the reasoning behind it.

**When to use it:**
- After any stage where Claude made architectural decisions you didn't fully follow
- On a file that feels opaque or over-engineered
- Before writing tests, to understand what failure modes are worth covering
- Before a PR review, to be able to defend every decision

---

### 5. Review — `/casaflow:review`

**Run before any PR.** Dispatches a specialist swarm in parallel:

| Specialist | What it catches |
|-----------|----------------|
| security | Auth bypasses, injection risks, sensitive data exposure |
| dead-code | Unused exports, unreachable branches, zombie imports |
| error-handling | Unhandled rejections, swallowed errors, missing boundary checks |
| async-safety | Race conditions, missing awaits, concurrent mutation |
| performance | N+1 queries, unnecessary re-renders, blocking I/O |

Fix Critical and Major findings before creating the PR. Minor findings are your
judgment call — but they should be acknowledged, not silently ignored.

---

### 6. Review Tests — `/casaflow:review-tests`

**Runs automatically at the Polish stage.** You can also run it manually at any time.

Four phases:
1. **Coverage table** — which acceptance criteria have tests, which don't
2. **Mutation analysis** — for each test, describe one mutation to the production
   code that would make the test pass when the code is actually broken
3. **Quality rubric** — speed, isolation, clarity, coverage, false-positive resistance
4. **Letter grade** — A through F with specific gaps called out

The mutation analysis is the highest-value part. A test that can't fail is not a test.

---

### 7. Ship — `/casaflow:pr-create` + `/casaflow:pr-respond`

`/casaflow:pr-create` runs the review swarm first, then writes the PR description
with a test plan, tradeoffs, and context. If Jira is configured, it posts the PR
URL as a comment on the ticket automatically.

`/casaflow:pr-respond` handles reviewer feedback: fetches comments, fixes them,
commits, pushes, replies to the comment thread, and resolves it.

---

### 8. Retro — `/casaflow:retro`

**Run this after every feature merge.** It takes 10 minutes and compounds over time.

Five questions that generate a team artifact:
- What surprised you during this build?
- Where did the AI go wrong and how did you catch it?
- Which gate caught a real problem?
- What would you do differently on the next feature?
- What should be added to the concerns checklist?

Claude looks for patterns across retros. If the same failure mode shows up three
times, it surfaces the pattern and suggests a pipeline change. This is how the
workflow improves itself.

---

## The Commands at a Glance

| Command | When to run |
|---------|-------------|
| `/casaflow:spec` | Before any feature or improvement — no exceptions |
| `/casaflow:kickoff` | To start the full pipeline |
| `/casaflow:build` | To execute a plan |
| `/casaflow:approve` | To pass a stage gate (also runs automatically) |
| `/casaflow:explain` | After any stage where you want deeper understanding |
| `/casaflow:review` | Before creating a PR |
| `/casaflow:review-tests` | After implementation, to audit test quality |
| `/casaflow:pr-create` | To create the PR with swarm review + description |
| `/casaflow:pr-respond` | To handle PR reviewer feedback |
| `/casaflow:debug` | When something is broken — root cause before fixes |
| `/casaflow:tdd` | When you want red-green-refactor discipline |
| `/casaflow:retro` | After every feature merge |

---

## Common Mistakes

**Skimming the stage report.** The coupling notes and tradeoffs section are the
most valuable parts. If you skim them, you've let Claude make architectural
decisions you don't understand. Those decisions will come back as bugs.

**Rushing through the comprehension questions.** Answering vaguely to get past
the gate defeats the entire purpose. The gate is not a box to check — it's a
calibration. A wrong answer is useful information.

**Treating non-goals as optional.** Non-goals are where scope creep gets caught.
Features that seem simple tend to expand when implementation starts. Writing
"this does NOT support X" before you start is the easiest way to prevent a
week of extra work.

**Skipping the retro.** The retro is the compounding mechanism. Skipping it means
the next engineer (or future you) doesn't get the benefit of what you learned.

**Starting `/casaflow:build` without reviewing the plan.** The plan is Claude's
contract. If you don't read it before execution starts, you'll be surprised by
what gets built — and surprised is bad during an approve-gate.

---

## When Things Go Off Script

**Mid-feature redirect** — if requirements change during a build stage, say so at
the approve-gate. Small changes (a different variable name, a different endpoint
path) don't require re-running the comprehension questions. Large redirects
(architecture changes, new acceptance criteria) do. Claude will adjust and re-scope.

**Can't answer a comprehension question** — this is normal, especially on unfamiliar
patterns. Ask Claude to walk you through the code path before answering. Don't
guess. The gate is a learning moment, not a performance review.

**AI output looks wrong** — stop and use `/casaflow:debug` or `/casaflow:explain`
before overriding. The spec's acceptance criteria are the source of truth. If
Claude's output doesn't satisfy a criterion, name the criterion and ask for a fix.

---

## The Bottom Line

CasaFlow will make you a faster engineer over time — not because the AI is faster,
but because you'll accumulate deep understanding of the codebase instead of
accumulated debt. Every approval gate answered, every spec written, every retro
filed is an investment in the comprehension that makes future features faster
and safer.

The workflow is designed to make understanding the path of least resistance.
Follow it, and that's what you'll get.
