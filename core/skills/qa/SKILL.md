---
name: qa
description: >
  Use when a second developer picks up a shipped or in-review change to
  verify it before merge — a reviewer-triggered QA pass, not part of the
  main build pipeline. Assembles ticket + PR + spec.md + shipped.md, derives
  a check matrix from acceptance criteria AND the diff, auto-discovers the
  Playwright runtime to generate and run e2e for everything testable using
  provisioned QA accounts, and produces an opt-in qa.html the reviewer signs
  off check-by-check. Invoked by /casaflow:qa <CAS-NNNN | PR url | branch>.
tier: workflow
alwaysApply: false
---

# Skill: QA

## Purpose

Build skills (`spec` → `plan` → `build` → `finish`) serve the developer who
*wrote* the code. QA serves a *different* developer — the reviewer who picks
the change up to verify it before merge. They didn't build it, so they start
cold, and the highest-leverage thing this skill can do is hand them an
honest, pre-computed picture of what changed and run the deterministic checks
so they never hand-click them.

The skill reconciles **intended** (ticket AC + `spec.md`) against **actual**
(PR diff + `shipped.md` divergences), derives a check matrix, auto-runs every
check it can via Playwright using real provisioned QA accounts, and produces
a `qa.html` the reviewer works through. Their per-check sign-off comes back
to Claude, which posts the review and records the result.

The four CasaPerks pillars, applied to review:
- **Speed** — context assembly and deterministic flows are automated.
- **Comprehension** — the reviewer must understand the change to sign off.
- **Upskilling** — a junior doing QA sees *how* checks are derived from AC +
  diff, and where regression risk actually hides.
- **Robustness** — checks come from the diff (not just the AC), and green
  generated specs can be promoted into the permanent regression suite.

---

## When this skill is active

Invoked by:
- A reviewer running `/casaflow:qa <target>` where `<target>` is a Jira
  ticket ID (`CAS-1234`), a PR URL, or a branch name.

QA is **not** part of the `kickoff` pipeline. It is picked up independently,
typically once a PR is open and a teammate is assigned to verify it.

---

## Step 0: Resolve the target and assemble context

Reconciliation is the whole point — *intended* vs *actual*. Pull four
sources and hold them side by side.

### 0a. Resolve the target into ticket + PR + branch

| Given | Resolve the rest via |
|-------|----------------------|
| Ticket ID | Atlassian MCP → remote issue links (the Jira→PR link) → PR + branch |
| PR URL | `gh pr view <url> --json ...` → head branch → Jira key from branch name / PR body |
| Branch name | `gh pr list --head <branch>` → PR → Jira key from branch name |

Branch convention is `{username}/jig-{number}-{kebab-title}` and PR↔ticket
linking is via **Jira remote links** (confirmed team setup). If a link is
missing, parse the ticket key from the branch name or PR title and confirm
with the reviewer before proceeding.

### 0b. Pull the four sources

1. **Jira ticket** (Atlassian MCP): description, acceptance criteria,
   comments, linked issues, status.
2. **PR** (`gh`): description, the diff, changed file list, commits.
   ```bash
   gh pr view <pr> --json title,body,headRefName,baseRefName,files,url
   gh pr diff <pr>
   ```
3. **`spec.md`** from the casavault if it exists — the AC the team actually
   committed to. Path: `~/Documents/<project-name>/<feature-slug>/spec.md`
   (read `vault-path` and `project-name` from `casaflow.config.md`; derive
   the slug from the ticket summary, lowercase-hyphenated).
4. **`shipped.md`** if it exists — the **divergence log is the highest-value
   input.** It tells the reviewer exactly where reality drifted from spec,
   which is precisely where QA effort should concentrate.

If `spec.md` / `shipped.md` are absent, proceed from ticket AC + diff alone
and note in `qa.md` that no casavault artifacts were found.

---

## Step 1: Load the QA accounts registry

Automated flows need to log in as real user types. Credentials live in the
developer's casavault, never in the repo.

Read `~/Documents/<project-name>/QA-Accounts-Registry.md` (vault root, shared
across all features — not per-feature). This file lists provisioned **test**
accounts and passwords for every CasaPerks and WorkPerks user type.

- **If it exists** — parse it (schema in
  `reference/QA-Accounts-Registry.template.md`). Index accounts by `product`
  (casaperks | workperks) and `role`.
- **If it is missing** — copy
  `reference/QA-Accounts-Registry.template.md` to the vault root, tell the
  reviewer:
  > "No QA accounts registry found. I've dropped a template at
  > `~/Documents/<project-name>/QA-Accounts-Registry.md`. Fill in the
  > provisioned test accounts for each user type, then re-run. I'll generate
  > guided manual checks in the meantime."
  Then continue with automation **disabled** for any check needing login.

### Security contract (non-negotiable)
- The registry stays in the casavault. **Never** copy it, its values, or any
  password into the repo, a generated spec, a log line, `qa.md`, `qa.html`,
  or a Jira/PR comment.
- Generated Playwright specs read credentials from **environment variables /
  the auth fixture at runtime**, never inline literals. See Step 3.
- In any artifact, refer to accounts by **role label only** (e.g.,
  `casaperks-resident`), never by email or password.

---

## Step 2: Derive the check matrix

From AC + `spec.md` + the **diff**, produce a list of verifiable checks.
Pulling from the diff (not only the AC) is deliberate: it surfaces
regression surface the ticket never mentioned. Concentrate extra checks on
the `shipped.md` divergences — that is where intent and reality parted.

For each check record:
- **id** (`QA-1`, `QA-2`, …) and a one-line **assertion** (observable
  outcome, "given/when/then" style)
- **source** — which AC, spec criterion, or diff hunk it came from
- **surface** — `frontend` (UI flow) or `backend` (API / data assertion).
  A change usually needs both: the UI behaves *and* the endpoint enforces
  the rule. Server-side rules (caps, permissions, validation) belong on the
  backend surface even when the UI also checks them — that is exactly where
  client-only enforcement bugs hide.
- **kind** — `automatable` or `manual` (visual/UX judgment, external
  integration, hard-to-reach data state)
- **account** — the registry role label the check needs, or `none`
- **risk** — `high` for divergence-related or auth/permission/money paths,
  else `normal`
- **request** (backend only) — method, path, headers, body shape, and the
  expected response. Needed both to generate the automated assertion and to
  render the manual API card if it can't be automated.

Keep the matrix honest: if something genuinely can't be automated, mark it
`manual` with precise repro steps (or, for `backend`, a runnable request)
rather than faking a flaky test. For every server-side rule the diff
introduces, add a `backend` check even if a `frontend` check already covers
the happy path — the bug is almost always that the rule is enforced on the
client but not the server.

---

## Step 3: Discover the runtime, generate, and run

The exact test setup is not assumed — **discover it at runtime** so the skill
keeps working even if the layout differs from expectation, and degrades
cleanly when there's no harness.

### 3a. Auto-discover
```bash
# frontend: playwright config + e2e dir + scripts + base URL + auth pattern
fd -HI 'playwright.config.*' || find . -name 'playwright.config.*' -not -path '*/node_modules/*'
jq '.scripts | to_entries[] | select(.value|test("playwright|test:e2e"))' package.json
# backend: an existing API test harness, if any
fd -HI 'jest.config.*|vitest.config.*|pytest.ini|conftest.py'
grep -rl "supertest\|APIRequestContext\|TestClient\|request(app)" --include=*.ts --include=*.py -m1 . 2>/dev/null | head
```
Infer the **e2e directory**, the **test script**, the **base URL** (from
`playwright.config` `use.baseURL`, an API base env var, or `shipped.md`), the
**auth pattern** (an existing spec / `storageState` / global-setup fixture),
and whether a **backend test harness** already exists.

If neither a Playwright config nor any backend harness exists: skip
generation, mark every `automatable` check as `manual`, and note "no test
harness discovered — all checks routed to manual" in `qa.md`.

### 3b. Mint auth once, reuse for both surfaces
Backend requests need a logged-in token. Get it from the **same login the
frontend auth pattern already uses** — either lift the bearer token out of
the Playwright `storageState`, or do a programmatic login against the auth
endpoint with the registry credentials for the check's role. Mint one token
per role needed.

**The token is minted at runtime and never persisted** — not in a spec, not
in `qa.md`, not in `qa.html`, not in a log or comment. Treat it like the
passwords in Step 1.

### 3c. Generate (quarantined)
Write generated specs to a quarantine dir inside the discovered e2e folder,
e.g. `e2e/__casaflow_qa__/<feature-slug>/`. They are **not** committed yet.
One file per automatable check, named `QA-<n>.spec.ts` (match the repo's
extension), assertion text as the test title.

- **`frontend` checks** → mirror the discovered Playwright auth pattern; pull
  the test user via the Step 2 registry role; inject the credential through
  the **env var / fixture the existing setup already uses**, never inline.
- **`backend` checks** → prefer the discovered backend harness
  (supertest/jest, pytest). If none exists, use **Playwright's
  `APIRequestContext`** (the `request` fixture) — it's already present. Send
  the authenticated request with the minted token in the `Authorization`
  header, assert on status + JSON body against the `request.expected` from
  the matrix. Server-side rule checks (e.g. "API rejects a 95% share") live
  here.
- **`backend` + not automatable** (hard-to-reach state, external dependency)
  → do **not** fake a test. Emit a **manual API check**: the method, path,
  headers, body, and expected response, with auth shown as a `{{token}}`
  placeholder. Step 4 renders it as a card with a copy-as-cURL button and an
  editable "actual" field; the reviewer runs it and records the verdict.

### 3d. Run
Run only the quarantine dir, capture results plus artifacts:
```bash
npx playwright test e2e/__casaflow_qa__/<feature-slug> --reporter=line
# or the discovered backend harness command, scoped to the generated tests
```
Record per-check: `pass` / `fail` / `error`, duration, and artifact paths.
A spec that fails twice on retry is `flaky` — record it, don't promote it.

---

## Step 4: Produce qa.md and offer the HTML view

Write `qa.md` to the feature folder (`~/Documents/<project-name>/<feature-slug>/qa.md`)
using the format below. This is the canonical QA artifact.

Then offer the interactive view — **opt-in every time**, per the visualize
contract. Do not auto-fire it, do not dump the matrix as a terminal wall of
text as a substitute.

> "QA matrix built and automated checks have run. Results saved to
> `<path-to-qa.md>` — N automated (X passed, Y failed), M manual checks for
> you to work through.
>
> Want the interactive `qa.html` in your browser? It lays out the change
> summary, the automated results inline, and gives you a pass/fail/blocked
> control per manual check with an Export button that sends your sign-off
> back to me. Reply **html**, or **continue** to work from the markdown."

- **html** → invoke `/casaflow:visualize <path-to-qa.md>`, then:
  "Opened `qa.html`. Work through the manual checks, then click **Export
  results** and paste the block back here so I can post the review."
- **continue** → walk the manual checks in terminal, collecting a verdict
  per check.

---

## Step 5: Collect sign-off and post the review

`qa.html` is a static file with no server, so the reviewer's verdicts come
back to Claude explicitly. The page's **Export results** button produces a
fenced ```casaflow-qa-results``` block (JSON) the reviewer copies and pastes
back into this chat.

When you receive the block (pasted, or collected in terminal under
**continue**):

1. **Parse** every check's verdict (`pass` | `fail` | `blocked`), notes, and —
   for manual API checks — the `actual` response the reviewer pasted in.
   Record the `actual` next to its `expected` in `qa.md` so the diff is
   captured for any failure.
2. **Compute the overall verdict:**
   - any `fail` → **FAIL**
   - no fail but any `blocked` → **BLOCKED**
   - all `pass` → **PASS**
3. **Record** the verdicts and overall result back into `qa.md` (update the
   sign-off section + frontmatter `result:`).
4. **Post the review:**
   - **Jira** (Atlassian MCP): add a comment summarizing the result, counts,
     and any failures with their assertion text. Role labels only, no creds.
   - **GitHub** (`gh`): post a PR review —
     `gh pr review <pr> --approve` on PASS, or
     `gh pr review <pr> --request-changes` on FAIL, with a body listing each
     failed/blocked check.
   - Always confirm with the reviewer before posting (`approve` /
     `request-changes` is consequential).
5. **Spawn bug tickets** for each `fail` — reuse the spawned-tickets concept
   from `shipped.md`: create a Jira issue per failure, link it to the
   original ticket, and list the new IDs in `qa.md`.
6. **Offer to promote** green, non-flaky generated specs into the permanent
   e2e suite (move out of the quarantine dir, into the discovered e2e folder,
   for the reviewer to commit). This is how every QA pass grows the
   regression net instead of evaporating. Flaky or failing specs are never
   promoted.

---

## qa.md file format

```markdown
---
ticket: <CAS-NNNN>
ticket_url: <url>
pr_url: <github pr url>
branch: <head branch>
spec_path: <path or "none">
shipped_path: <path or "none">
reviewer: <email>
qa_date: YYYY-MM-DD
result: pending | PASS | FAIL | BLOCKED
automated: { total: N, passed: X, failed: Y, flaky: Z }
manual: { total: M, pass: , fail: , blocked: }
spawned_tickets: []        # bug tickets opened from failures
---

# QA: <Feature Name>

## What changed
One-paragraph reviewer-facing summary reconciling ticket/spec intent with
the actual diff. Call out the shipped.md divergences explicitly.

## Check matrix
For each check: id · assertion · source · surface · kind · account role · risk.

## Automated results
Per automatable check: pass/fail/flaky · duration · trace/screenshot path ·
the generated spec path (quarantine). Backend checks also note the endpoint
asserted.

## Manual checks
- Frontend: assertion · precise repro steps · expected result · account role.
- Backend (API): assertion · method + path + headers + body · expected
  response · `{{token}}` placeholder for auth · account role.
Verdict (and, for API checks, the pasted `actual` response) filled at sign-off.

## Sign-off
Overall result + per-check verdicts + reviewer notes (filled in Step 5).

## Promoted specs
Generated specs promoted into the permanent suite (filled in Step 5).
```

---

## What this skill does NOT do

- Does not write credentials anywhere outside the casavault registry.
- Does not commit generated specs automatically — promotion is opt-in and
  leaves the actual `git commit` to the reviewer (repo rule: never commit
  without explicit approval).
- Does not post a PR approval/request-changes without reviewer confirmation.
- Does not modify the source markdown artifacts (`spec.md`, `shipped.md`).
- Does not run if it cannot resolve the target to at least a PR or a diff —
  see Red flags.

---

## Red flags

Stop and surface explicitly:

- **Target can't be resolved** to a ticket+PR (no remote link, ambiguous
  branch) — report what you found and ask the reviewer to disambiguate.
- **QA accounts registry missing** — scaffold the template, continue with
  login-dependent automation disabled, tell the reviewer.
- **No Playwright harness discovered** — route all checks to manual rather
  than inventing a setup.
- **A credential is about to leak** into a spec, log, artifact, or comment —
  never do it; use the env/fixture indirection.
- **Generated spec is flaky** (passes then fails on retry) — record as flaky,
  exclude from promotion, flag it for the reviewer.
- **PR review post would change PR state** — confirm with the reviewer first.

---

## Reference

- `reference/QA-Accounts-Registry.template.md` — the test-account registry
  schema the reviewer fills in (vault root).
