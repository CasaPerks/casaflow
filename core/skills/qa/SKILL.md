---
name: qa
description: >
  Use when a reviewer picks up a shipped or in-review change to verify it
  before merge — a reviewer-triggered QA pass, not part of the main build
  pipeline. Runs the feature's existing tests (discovering the stack's test
  command, not just package.json); for web changes it generates/runs Playwright
  e2e for the acceptance criteria, while non-web changes (mobile, backend,
  config) route to the existing suite or an AC-derived manual checklist. Writes
  a qa.md with result pending|PASS|FAIL|BLOCKED (pending = manual checks await
  sign-off; BLOCKED only when the AC can't be exercised by any form). If the
  target ticket has subtasks, it QAs them one at a time rather than the whole
  epic at once. Then it offers an opt-in qa.html and lists any checks the
  reviewer must run manually. Invoked by
  /casaflow:qa <CAS-NNNN | PR url | branch>.
tier: workflow
alwaysApply: false
---

# Skill: QA

## Purpose

QA answers one question: **with the current code, does this feature work as
expected?** The change has already been through code review and merged to dev —
QA is *not* a second code review. It's functional verification: run it, and
confirm it behaves the way the acceptance criteria say it should.

The guiding rule: **test the change, don't reverse-engineer it.** Earlier
versions of this skill tried to reconcile spec vs. diff, infer backend request
shapes from the code, and back-engineer what the feature "must" do — turning QA
into an investigation that took longer than testing by hand. Don't do that.
Read the acceptance criteria, run the tests, report pass/fail. There's a real
balance between rigorous QA and doing too much; stay on the "does it work" side
of it.

**And don't over-automate.** Generating Playwright specs for the repeatable
flows is the high-value thing this skill does — those become permanent
regression coverage and you should lean into them. But automation isn't the
goal; *confident verification* is. Some checks are faster and more meaningful
done by hand — a visual/UX judgment, a one-off data state, an exploratory
"does this feel right" pass. For those, don't burn time forcing a brittle
spec. Recommend a **manual check** and make it genuinely runnable: explicit,
numbered, tool-aware steps (see Step 4).

CasaPerks pillars, applied to QA:
- **Speed** — repeatable checks are automated; the skill doesn't go spelunking.
- **Comprehension** — the reviewer stays in control of scope and signs off.
- **Robustness** — Playwright e2e generated for the AC become repeatable checks.

---

## When this skill is active

Invoked by a reviewer running `/casaflow:qa <target>`, where `<target>` is a
Jira ticket ID (`CAS-1234`), a PR URL, or a branch name.

QA is **not** part of the `kickoff` pipeline. It's picked up independently —
typically on a change that's already code-reviewed and merged to dev, when a
teammate is confirming the feature actually works as expected.

---

## Step 0: Resolve the target — and check for subtasks

### 0a. Resolve target → ticket + PR + branch

| Given | Resolve the rest via |
|-------|----------------------|
| Ticket ID | Atlassian MCP → remote issue links (Jira→PR link) → PR + branch |
| PR URL | `gh pr view <url> --json ...` → head branch → Jira key from branch/body |
| Branch name | `gh pr list --head <branch>` → PR → Jira key from branch name |

Branch convention is `{username}/jig-{number}-{kebab-title}`; PR↔ticket linking
is via Jira remote links. If a link is missing, parse the key from the branch
name or PR title and confirm with the reviewer.

### 0b. If the ticket has subtasks, QA one at a time

When the target is a ticket, check whether it has subtasks (Atlassian MCP
`getJiraIssue` returns them). **A parent ticket with subtasks is not one QA
target — it's several.**

- If there are subtasks, **list them and ask which to start with.** Default to
  going through them sequentially, one at a time, each as its own QA run with
  its own `qa.md`. Do not collapse the whole epic into a single pass.
  > "CAS-1234 has 3 subtasks:
  > 1. CAS-1235 — <summary>
  > 2. CAS-1236 — <summary>
  > 3. CAS-1237 — <summary>
  > I'll QA them one at a time. Start with #1, or pick another?"
- If there are no subtasks, proceed with this single target.
- If the target is a PR or branch (not a ticket), there's no subtask concept —
  proceed directly.

### 0c. Gather what to test (lightly)

Pull just enough to know what the change *claims* to do:
1. **Ticket / subtask** (Atlassian MCP): description + acceptance criteria.
2. **PR** (`gh`): title, body, and the list of changed files.
   ```bash
   gh pr view <pr> --json title,body,headRefName,baseRefName,files,url
   ```
3. **`spec.md`** from the casavault *if it exists* — for the AC the team
   committed to. Path: `~/Documents/<project-name>/<feature-slug>/spec.md`
   (read `vault-path` / `project-name` from `casaflow.config.md`).

The acceptance criteria are what you test against. Read the diff only to see
*what surfaces changed* (which pages/flows to exercise) — **not** to derive new
checks the AC never mentioned. If something is unclear, ask the reviewer rather
than inferring it from the code.

---

## Step 1: Run the feature's existing tests

Before generating anything, run the tests that already cover this change —
whatever the repo's stack uses. **Discover the command; don't assume one.**

- **Node / web** — `test*` scripts in `package.json`
- **iOS / mobile** — `xcodebuild test`, a Fastlane lane, or the repo's test script
- **Python / Go / Ruby / etc.** — `pytest`, `go test`, `rake test`, a Makefile target

If the convention isn't obvious, fall back to the command the repo's **CI**
runs (`.github/workflows/*`, other CI config) — that's the source of truth for
"how this repo tests itself."

Run the relevant suite (scope to the feature's files/dir when you can, so the
run is fast). Record pass/fail. If a feature test fails, that's a QA finding —
capture it; don't try to fix it. If the stack genuinely has no runnable test
suite, note it and rely on the e2e / manual forms below — don't invent one.

---

## Step 2: Web e2e via Playwright (web/UI changes)

Generating Playwright specs for the AC's web flows is the high-value automation
this skill does — lean into it for **web/UI** changes. For **non-web** changes
there's no Playwright to generate; the automated coverage is the existing suite
from Step 1, and the rest is manual (Step 4):
- **mobile** → the device/UI checks become a manual AC checklist (Step 4)
- **backend / API** → the integration suite from Step 1 (+ a targeted call if needed)
- **config / refactor / docs** → the relevant build + the targeted check that proves it

If this isn't a web change, skip to Step 3. Otherwise:

### 2a. Discover the Playwright runtime
```bash
fd -HI 'playwright.config.*' || find . -name 'playwright.config.*' -not -path '*/node_modules/*'
jq '.scripts | to_entries[] | select(.value|test("playwright|test:e2e"))' package.json
```
Infer the **e2e directory**, the **test script**, the **base URL**
(`use.baseURL`), and the **auth pattern** (an existing spec / `storageState` /
global-setup fixture).

If no Playwright config exists, **skip generation** — note "no Playwright
harness found; e2e checks routed to manual" in `qa.md` and move on. Don't
invent a test setup.

### 2b. Decide what to automate vs. check by hand
Go AC by AC and split them, deliberately:
- **Automate** the deterministic, repeatable flows — a clear user path with an
  observable outcome (form submits, value appears, redirect happens). These are
  worth a spec because they'll catch regressions on every future run.
- **Leave manual** the checks where a spec is slower or worth less than a human
  doing it: visual/layout/UX judgment, animations and feel, a hard-to-reach or
  one-off data state, anything needing a login the repo can't auto-provide, or
  exploratory "does this behave sensibly" passes. Don't write a brittle spec
  just to claim full automation — route it to Step 4 as a manual check instead.

Briefly tell the reviewer the split before generating ("automating 3 of the 5
checks; 2 are faster by hand — I'll write up steps for those").

### 2c. Use existing e2e, or generate specs for the automated set
- If e2e specs already cover the change's flows, just run them.
- Otherwise generate **one spec per check you chose to automate** — the
  observable user flow, named after the AC. Mirror the repo's existing
  Playwright style. Keep them straightforward; don't chase edge cases the AC
  doesn't call for.

**Login:** reuse the repo's existing auth fixture / `storageState`. Never inline
credentials in a spec — go through the env var / fixture the repo already uses.
If a flow needs login and the repo has no reusable auth pattern, route that
check to **manual** rather than building a login harness. (An optional
`QA-Accounts-Registry.md` at the vault root can supply role credentials if the
team maintains one — see `reference/`; creds stay in the vault, never in a spec.)

### 2d. Run
```bash
npx playwright test <e2e-dir-or-generated-specs> --reporter=line
```
Record per check: `pass` / `fail` / `error`, and the trace/screenshot path. A
spec that passes then fails on retry is `flaky` — record it as such.

---

## Step 3: Write qa.md (the pass/fail doc)

Write `qa.md` to the feature folder
(`~/Documents/<project-name>/<feature-slug>/qa.md`), using the format below.
This is the canonical QA artifact — one per subtask when QAing subtasks.

Compute the overall result — and **distinguish "not done yet" from "can't be
done":**
- any check failed (automated, or a signed-off manual check) → **FAIL**
- checks ran/generated but one or more **manual checks still await reviewer
  sign-off** → **pending** — QA is mid-flight, *not* blocked; it resolves to
  PASS/FAIL once the reviewer signs off (Step 4)
- all checks pass **and** every manual check is signed off → **PASS**
- the AC **could not be exercised by any form** — no automated path *and* no
  runnable manual check is possible → **BLOCKED**

**`BLOCKED` is narrow and rare.** "No Playwright harness," "needs a login,"
"this is a mobile / backend / config change" are **not** blocked — they route
to the existing suite (Step 1) or a manual checklist (Step 4) and still reach
PASS. Reserve `BLOCKED` for "there is genuinely no way to exercise this AC."
A change waiting on the reviewer to walk its manual checks is `pending`, never
`BLOCKED`.

The front matter must **reconcile** with this result: count checks still
awaiting sign-off as `manual.unsigned`, so `result: pending` ⟺ `manual.unsigned
> 0` with nothing failed. When sign-off completes, `unsigned` drops to 0 and the
result settles to PASS or FAIL.

---

## Step 4: Offer qa.html and list manual steps

After `qa.md` is written, do two things:

**1. Ask whether the reviewer wants `qa.html`** — this is a required prompt, not
a judgment call. The HTML lays out the results and gives a per-check sign-off
control; it's the reviewer's choice, never skip it or decide for them.

> "QA done for <CAS-NNNN>. Results in `<path-to-qa.md>` — N automated
> (X passed, Y failed), M manual checks.
>
> Want the interactive `qa.html`? It shows the results and a pass/fail control
> per manual check. Reply **html**, or **continue** to work from the markdown."

- **html** → invoke `/casaflow:visualize <path-to-qa.md>`. The page's **Export
  results** button produces a fenced ```` ```casaflow-qa-results ```` block;
  the reviewer pastes it back and you record the verdicts into `qa.md`.
- **continue** → walk the manual checks in the terminal and record verdicts.

**2. Write each manual check as a runnable, tool-aware recipe.** This is where
the skill earns its keep when automation isn't worth it — so don't hand-wave it
with "verify the feature works." For every manual check, write:
- **assertion** — the observable outcome being confirmed
- **steps** — explicit, numbered, in order. Use the *real* environment you
  discovered: the actual base URL and route, the account role to log in as, the
  exact button/field labels, the data to enter.
- **tools to use** — name the concrete tools available in this session that make
  the check faster, and how. Tailor to what's actually connected — e.g.
  `agent-browser` to drive the page and screenshot, the **mongodb** / **supabase**
  MCP to confirm the row/state changed, `gh` for PR/CI state, the **Atlassian**
  MCP for ticket context, `curl` for a one-off API call. Only reference tools
  that are actually present.
- **expected result** — what the reviewer should see / what value confirms pass.

Aim for steps a teammate could follow cold without asking you a question. These
land in `qa.md` under `## Manual checks` and render as cards in `qa.html`.

**Guard the manual path against rubber-stamping** — it's the easiest form to
wave through, so keep it honest: every manual check must trace to a specific AC
item (one check per AC item, not a free-form "looks good"), and the reviewer
signs off **each item individually**, never the checklist as a whole. Any
unsigned item keeps the result `pending`, not PASS.

If QAing subtasks one at a time, after finishing one, offer to move to the next.

---

## qa.md file format

```markdown
---
ticket: <CAS-NNNN>
ticket_url: <url>
pr_url: <github pr url>
branch: <head branch>
parent_ticket: <CAS-NNNN or "none">   # set when this qa.md is for a subtask
spec_path: <path or "none">
reviewer: <email>
qa_date: YYYY-MM-DD
result: pending | PASS | FAIL | BLOCKED
# pending  = manual checks await reviewer sign-off (mid-flight, not a failure)
# PASS     = all checks pass AND every manual check signed off
# FAIL     = a check failed
# BLOCKED  = AC could not be exercised by ANY form (rare; not "no harness")
automated: { total: N, passed: X, failed: Y, flaky: Z }
manual: { total: M, pass: , fail: , blocked: , unsigned: }
# manual.unsigned = checks awaiting reviewer sign-off; result is `pending`
# while unsigned > 0 (and nothing has failed)
---

# QA: <Feature / Subtask Name>

## What changed
One-paragraph reviewer-facing summary of what this change does, from the AC.

## Feature tests
The existing test command run and its result.

## Automated e2e
Per check: assertion · pass/fail/flaky · trace/screenshot path · spec path.

## Manual checks
Per check, as a runnable recipe (see Step 4):
- **assertion** — the observable outcome
- **steps** — explicit numbered steps using the real URL/route, account role,
  and exact labels
- **tools to use** — the concrete session tools that speed it up (agent-browser,
  mongodb/supabase MCP, gh, curl…), only those actually available
- **expected** — what confirms a pass

Verdict filled at sign-off.

## Sign-off
Overall result + per-check verdicts + reviewer notes.
```

---

## What this skill does NOT do

- Does not reconcile spec/shipped divergences or reverse-engineer the feature
  from the diff — it tests against the acceptance criteria.
- Does not derive backend check matrices or infer API request/response shapes
  from the code.
- Does not promote specs to a regression branch/PR, spawn bug tickets, or post
  Jira/PR reviews. QA reports results; acting on them is a separate step.
- Does not write credentials anywhere outside the casavault.
- Does not invent a test harness when none exists — it routes those checks to
  manual.
- Does not over-automate — it doesn't force a brittle spec for a check that's
  faster or more meaningful by hand; it writes a runnable manual recipe instead.
- Does not QA an entire epic at once when the ticket has subtasks — it does them
  one at a time.

---

## Red flags

Stop and surface explicitly:

- **Target can't be resolved** to a ticket/PR — report what you found and ask.
- **Ticket has subtasks** — list them and QA one at a time; don't bundle.
- **No Playwright harness** — route e2e checks to manual, don't build one. This
  is **not** `BLOCKED`.
- **About to mark a change `BLOCKED` because it isn't web / has no Playwright** —
  wrong. Route it to the existing suite or a manual checklist; `BLOCKED` is only
  "no way to exercise the AC at all."
- **About to mark manual-checks-awaiting-sign-off as `BLOCKED`** — that's
  `pending`, not blocked; QA is mid-flight.
- **Assuming `package.json` / Playwright is the stack** — discover the repo's
  actual test command (iOS, Python, Go…), falling back to what CI runs.
- **A flow needs login the repo can't auto-provide** — route to manual rather
  than building a login harness.
- **A credential is about to leak** into a spec, log, or artifact — never; use
  the existing env/fixture indirection.
- **You're tempted to investigate what the feature "must" do** — stop. Read the
  AC, or ask the reviewer. Don't back-engineer it.
- **About to force a spec for an awkward check** — if a manual check is faster or
  tells you more, write the manual recipe instead of fighting a brittle test.
- **About to skip the `qa.html` prompt** — never; the choice is the reviewer's.

---

## Reference

- `reference/QA-Accounts-Registry.template.md` — optional test-account registry
  schema, if the team maintains shared QA logins in the vault.
