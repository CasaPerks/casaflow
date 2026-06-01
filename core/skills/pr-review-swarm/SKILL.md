---
name: pr-review-swarm
description: >
  Use when you've been added as a reviewer on a pull request and need to review
  it end-to-end — a reviewer-triggered PR review, not a review of your own
  pre-PR diff. Pulls the PR branch down, checks CI status, checks the work
  against its Jira ticket scope, checks coding-guideline adherence, dispatches
  the parallel review swarm (verifying each finding for correctness before
  posting to a teammate's PR), and posts an approval or a request-changes
  review. Approval is gated on mandatory QA whose form adapts to the PR type
  (web e2e, mobile/backend/config) — QA must PASS first. Every outward action
  (posting a review, pushing coverage, approving, merging) is confirmed with
  the reviewer first. Invoked by
  /casaflow:pr-review-swarm <github PR url | PR # | branch>.
tier: workflow
alwaysApply: false
---

# Skill: PR Review Swarm

## Purpose

You've been added as a reviewer on someone else's PR. This skill is the
reviewer's entry point: give it a PR and it pulls the branch, decides whether
the change is **in scope**, whether it **follows the coding guidelines**, and
whether the **code holds up under the swarm** — then posts a verdict. An
approve-worthy change doesn't get approved until it has also **passed QA**.

The intent: by the time a PR merges, it has been reviewed thoroughly **and**
verified by QA. QA is mandatory on every PR, but its *form* adapts to the PR
type — Playwright e2e for web, a manual AC checklist for mobile, the
integration suite for backend, a targeted build-and-check for config/refactor.
Where QA produces durable regression coverage (e.g. new e2e specs), getting
that coverage onto the PR is offered as an opt-in (Step 5a) — not forced onto a
teammate's branch.

This is *not* `code-review` (which reviews *your own* `origin/main...HEAD`
before you open a PR) and it is *not* `qa` alone (functional verification). It
**orchestrates** the existing organs around the reviewer's question: *should
this PR merge?*

```
resolve + checkout PR
   → CI status gate  (failing/pending required check → REQUEST_CHANGES / block)
   → scope check (vs Jira ticket / spec)
   → guidelines check
   → review swarm  (review skill, tier: all) → verify findings for correctness
   → VERDICT
        ├─ changes needed → post REQUEST_CHANGES (confirm) → STOP
        └─ approve-worthy → run QA (form per PR type; mandatory)
                               ├─ QA PASS  → offer to land coverage → post APPROVE (confirm) → offer merge (confirm)
                               └─ QA FAIL  → do NOT approve; report (confirm post)
```

CasaPerks pillars, applied:
- **Speed** — one command runs scope + guidelines + swarm + QA instead of four
  manual passes.
- **Comprehension** — the reviewer sees the verdict and confirms before
  anything is posted; the skill never approves or merges silently.
- **Robustness** — approval is QA-gated. A clean code review is necessary but
  not sufficient; the feature must also work.

**GIT HOST**: Commands below use GitHub (`gh`) as the default. If `git-host` in
`casaflow.config.md` is not `github`, read `framework/GIT_HOST.md` for the
platform equivalents.

---

## Non-negotiables

1. **NEVER post a review, approve, push, or merge without explicit reviewer
   confirmation.** These are outward-facing and hard to reverse — and this is
   *someone else's* PR. Always show the draft and wait for a yes.
2. **VERIFY every finding for correctness before posting it to a teammate's
   PR.** A false-positive REQUEST_CHANGES on a colleague's work is the main
   risk of automating this. Validate placement *and* that the issue is real —
   re-derive it against the code, drop anything you can't stand behind. Lower
   the volume, raise the confidence.
3. **NEVER approve before QA passes.** A clean swarm is not approval. The only
   path to APPROVE is: CI green + swarm clean + in scope + guidelines met
   **and** QA result is PASS.
4. **QA is mandatory but its form is per-PR-type** (Step 5). "No Playwright
   harness" is **not** a reason to block — it routes to the right QA form for
   that PR and can still reach PASS. Only "QA couldn't be performed at all" is a
   genuine block.
5. **The swarm score is mechanical** — don't bump it because the change "looks
   fine." Use the score the `review` skill produces.
6. **Don't reverse-engineer scope from the diff.** Scope is judged against the
   ticket's acceptance criteria and the spec, not invented from the code.
7. **Run against the real checked-out branch**, not a guess of what it
   contains. Pull it down first.

---

## Step 0: Resolve and check out the PR

### 0a. Resolve target → PR + branch + ticket

The argument is normally a GitHub PR URL; also accept a PR number or a branch.

```bash
git fetch origin
gh pr view <url|#|branch> \
  --json number,url,title,body,headRefName,baseRefName,headRefOid,files,state,reviewDecision
```

| Given | Resolve the rest via |
|-------|----------------------|
| PR URL / # | `gh pr view` → head branch, base, ticket key from branch/body |
| Branch | `gh pr list --head <branch>` → PR → ticket key from branch name |

Resolve the **Jira ticket key** from the branch name (`{username}/jig-{number}-...`
or `{type}/{ticket-id}:{title}` per `casaflow.config.md`), the PR body, or Jira
remote issue links (Atlassian MCP). If you can't find it, ask the reviewer —
don't guess.

### 0b. Check out the branch locally

```bash
gh pr checkout <number>          # puts the PR's head branch in the working tree
```

The swarm and QA must run against the actual code. If the working tree is
dirty, stop and tell the reviewer rather than stashing their work.

### 0c. Capture the diff base

```bash
gh api repos/{owner}/{repo}/pulls/{number} --jq '.head.sha'
git diff origin/{baseRefName}...HEAD --name-only
```

Use `origin/{baseRefName}...HEAD` (the PR's own base, which may not be
`main-branch`) as the diff range throughout.

### 0d. CI status — the cheapest gate, checked first

CI status is a gate, independent of the swarm score. Check it before spending
swarm and QA cycles on a red PR:

```bash
gh pr checks <number>          # required checks: pass / fail / pending
```

| CI state | Effect |
|----------|--------|
| A required check is **failing** | Automatic REQUEST_CHANGES — the code review can't override red CI. Surface it and (with confirmation) you can stop here rather than reviewing on top of a broken build. |
| A required check is **still running** | **Block until green** — don't approve against pending checks. Tell the reviewer; offer to wait/re-check or to review now and hold the verdict. |
| All required checks **green** (or none configured) | Proceed. |

CI failure feeds the Step 4 verdict; it does not by itself skip the rest of the
review (the swarm may still surface things worth flagging in the same pass).

---

## Step 1: Scope check — is the work in scope?

Pull what the change *claims* to do, then judge the diff against it. This is a
scope judgment, **not** a line-by-line review (the swarm does that).

1. **Ticket** (Atlassian MCP `getJiraIssue`): description + acceptance criteria.
   - If the ticket has **subtasks**, the PR usually maps to one subtask. Note
     which, and scope against that subtask's AC. (QA in Step 4 also handles
     subtasks one at a time.)
2. **`spec.md`** if it exists — the AC the team committed to. Path:
   `~/Documents/<project-name>/<feature-slug>/spec.md` (read `vault-path` /
   `project-name` from `casaflow.config.md`).
3. Map the **changed surfaces** (from `--name-only`) against the AC:

| Outcome | Meaning | Effect on verdict |
|---------|---------|-------------------|
| **In scope** | Every change traces to an AC item | OK |
| **Scope creep** | Changes unrelated to the ticket | flag → leans REQUEST_CHANGES |
| **Incomplete** | AC items with no corresponding change | flag → leans REQUEST_CHANGES |

Report the mapping plainly. If something is ambiguous, ask the reviewer rather
than inferring intent from the code.

---

## Step 2: Coding-guidelines check

Check the diff against the team's written conventions — not taste. Sources, in
priority order:

1. The **target repo's** `CLAUDE.md` (Code Style / Commit Conventions / any
   contributing or style docs it links).
2. Engineering standards skills present in discovery: `eng-copywriting`
   (user-facing text → sentence case), `eng-logging` (log levels), and any
   `standards`-tier team skills.
3. Commit-convention config in `casaflow.config.md`.

Report concrete, citable violations only (`file:line` + which rule). "Doesn't
follow guidelines" with no citation is not a finding. Guideline violations lean
the verdict toward REQUEST_CHANGES.

---

## Step 3: Review swarm

**REQUIRED**: Use the `review` skill for the code review. Dispatch it with
`tier: all` (full swarm + logic reviewer) against the PR diff:

```bash
git diff origin/{baseRefName}...HEAD
git diff origin/{baseRefName}...HEAD --name-only
```

Hand that diff to the `review` pipeline and take its **mechanical score**
verbatim — discover specialists, dispatch in parallel, collect, deep-review,
score, report. Don't *soften* the score because the change looks fine.

### 3a. Verify findings for correctness before they leave the building

The score is mechanical, but **what gets posted to a teammate's PR is not.**
Before any finding becomes an inline comment on someone else's work, verify it
is *real* — not just correctly placed on a diff line:

- For each **blocking/major** finding, re-derive it against the actual code:
  does the bug actually occur, given the surrounding context the specialist may
  not have seen? Read the relevant file, not just the hunk.
- **Drop findings you can't stand behind.** A false-positive REQUEST_CHANGES on
  a colleague's PR is the costliest failure mode here — it erodes trust in the
  whole automated review. When in doubt, downgrade to a question in the body
  rather than a blocking inline comment.
- This *reduces* what's posted; it never adds findings or raises the score.

Carry the verified findings (not the raw swarm output) into the verdict.

---

## Step 4: Verdict

Combine the inputs — CI, scope, guidelines, verified swarm findings — into one
decision. **REQUEST_CHANGES** (or block) if any of:

- A required **CI check is failing** (Step 0d), **or**
- A **verified** swarm finding is **blocking** (score ≤ 4) — verified per Step
  3a, false positives already dropped, **or**
- The change is **out of scope** (scope creep) or **incomplete** vs AC, **or**
- There are **coding-guideline violations** that the team treats as required.

If a required check is **still running**, hold — don't approve against pending
CI (Step 0d).

Otherwise the change is **approve-worthy** — but it is **not approved yet**. It
proceeds to QA (Step 5) before any approval.

Major/minor verified findings that aren't blocking are reviewer's judgment:
note them in the review body; they don't by themselves force REQUEST_CHANGES.

### 4a. Post a REQUEST_CHANGES review (if changes needed)

1. Draft the review: a summary body (scope result, guideline violations, swarm
   score) plus the swarm/guideline findings as inline comments.
2. **REQUIRED**: Use the `pr-review` agent to place the inline comments — it
   validates every `path`/`line` against the diff hunks so the API doesn't
   reject the batch. Pass it the findings; it returns the validated comment
   payload.
3. **Show the reviewer the full draft and confirm.** Only on a yes, post:

   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/reviews \
     --method POST --input /tmp/pr-{number}-review.json
   ```
   with `"event": "REQUEST_CHANGES"` and the validated `comments` array.
4. **STOP.** The ball is in the author's court. Do not run QA on a change that
   needs work. Report what was posted and end.

If approve-worthy, continue to Step 5 — **do not post anything yet.**

---

## Step 5: QA gate — mandatory, form adapts to the PR type

**QA is mandatory on every PR.** But "QA" is not a synonym for "Playwright."
A web-only QA gate dead-ends every non-web PR (iOS, backend, infra/config, pure
refactors, docs) at `BLOCKED` — which would make mandatory QA *unachievable*
for a large share of real PRs. So first **classify the PR**, then run the QA
form that fits it. The bar is the same everywhere: *the acceptance criteria are
demonstrably met with the current code.*

| PR type (from changed paths + ticket) | QA form | PASS means |
|----------------------------------------|---------|------------|
| **Web / UI** | `qa` skill → Playwright e2e for the AC | e2e green |
| **Mobile (iOS/Android)** | Manual checklist **derived item-by-item from the ticket AC** (one check per AC item, not free-form) | reviewer signs off **each item** individually |
| **Backend / API** | The feature's existing/integration suite (+ a targeted call if needed) | suite green, AC exercised |
| **Config / refactor / docs** | Relevant **build** + the targeted check that proves the change | build green + the specific behavior confirmed |

**REQUIRED**: Use the `qa` skill to drive this — it already runs the feature's
existing tests, generates/runs Playwright e2e where a web harness exists, and
**routes to a runnable manual checklist where it doesn't**. Invoke it on the
same target:

```
/casaflow:qa <ticket-id | PR url>
```

Let it run its full loop (including its required `qa.html` prompt) and, for a
ticket with subtasks, one subtask at a time. Read the **`result`** from the
resulting `qa.md` front matter.

| QA `result` | Next |
|-------------|------|
| **pending** | QA is mid-flight — manual checks await sign-off (every non-web PR lands here first). Walk them with the reviewer (or via `qa.html`), each AC item signed off individually. **Do not approve while pending**; it resolves to PASS or FAIL. |
| **PASS** | → Step 5a (offer to land any generated coverage) → Step 6 (approve) |
| **FAIL** | Do **not** approve. Summarize the failing checks; with confirmation, post REQUEST_CHANGES (or a comment) citing the QA failures and link `qa.md`. STOP. |
| **BLOCKED** | **Only** when QA *could not be performed at all* — no way to exercise the AC by any form (automated or manual). Report why and hand back. **"No Playwright harness" is NOT blocked** — that routes to the manual / suite / build form above and can still reach PASS. |

A PASS whose evidence is a manual checklist is still a PASS — record the
checklist and the reviewer's sign-off in `qa.md`. **Guard the manual path
against rubber-stamping**, since it's the easiest form to wave through: every
checklist item must trace to a specific AC item (no free-form "looks good"),
and the reviewer signs off **each item individually**, not the checklist as a
whole. If QA produced manual checks the reviewer hasn't signed off yet, surface
them; any unsigned item means it's not a clean pass — ask before treating it as
PASS.

### 5a. Offer to land the generated coverage (opt-in, never the default)

When QA generated durable coverage (new e2e specs/fixtures, now in the working
tree from Step 0b), it's valuable for that coverage to travel with the change.
But **pushing onto the author's branch is a judgment call, not a default** —
it reassigns authorship on someone else's PR, and it simply doesn't work in
common cases. So decide based on the PR, and confirm before doing anything.

First detect whether pushing is even possible:

```bash
gh pr view <number> --json isCrossRepository,maintainerCanModify,headRepositoryOwner
gh pr checks <number>     # branch-protection / required-status context
```

| Situation | What to offer |
|-----------|---------------|
| **Fork PR** (`isCrossRepository: true`) without `maintainerCanModify` | You **cannot** push to the author's branch. Offer a **follow-up PR** with the coverage, or attach the specs to the review for the author to commit. |
| **Branch protection** blocks direct pushes | Don't fight it. Offer the follow-up-PR path. |
| **Same-repo branch, pushable** | Offer to commit + push onto the PR branch **(opt-in)** *or* open a follow-up PR — let the reviewer choose. |

If the reviewer opts to push to the branch:

```bash
git add <generated coverage paths>
git commit -m "test: add QA coverage for <ticket>"   # repo's commit convention
git push origin HEAD
```

If QA produced no durable artifact (manual checklist, or backend suite that
already lived in the repo), there's nothing to land — note in the approval how
the AC was verified so the coverage shape is visible. Either way, **do not block
approval on where the coverage lives** — a PASS is a PASS; coverage delivery is
a separate, opt-in step.

---

## Step 6: Approve to merge (QA passed)

Only reachable when CI was green, the verified swarm findings were clean, the
work was in scope and on-guideline, **and** QA result is PASS.

1. Draft the APPROVE review body:
   - CI: required checks green.
   - Swarm score and that the verified findings were clean / non-blocking.
   - Scope: confirmed against `<ticket>` AC.
   - QA: PASS — which **form** of QA was run (e2e / manual checklist / suite /
     build-and-check), link `qa.md` (and `qa.html` if generated), and where the
     coverage landed (committed to branch, follow-up PR, or manual sign-off
     recorded) per Step 5a.
2. **Show the reviewer and confirm.** On a yes:

   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/reviews \
     --method POST --field event=APPROVE \
     --field body="<approval summary with QA link>" \
     --field commit_id="<head sha>"
   ```
3. **Offer to merge — never merge automatically.** Merging is outward-facing
   and may hit branch protections.
   > "Approved. Want me to merge it? (`gh pr merge <number> --squash`) — or
   > leave the merge to you / the author?"

   Only merge on an explicit yes, and respect the repo's merge method and
   protections. If branch protection blocks it, report that rather than forcing
   it.

---

## What this skill does NOT do

- Does not review your *own* pre-PR diff — that's the `code-review` agent /
  `review` skill on your branch.
- Does not approve on a clean code review alone — approval is QA-gated, and CI
  must be green.
- Does not post any review, approval, push, or merge without explicit reviewer
  confirmation.
- Does not post **unverified** findings — each blocking/major finding is
  re-derived against the code (Step 3a); false positives are dropped, not
  shipped to a teammate's PR.
- Does not re-score or soften swarm findings — the `review` score is
  authoritative.
- Does not **block a non-web PR for lacking a Playwright harness** — QA's form
  adapts to the PR type; only "couldn't QA at all" is BLOCKED.
- Does not **push coverage onto the author's branch by default** — that's
  opt-in, and forks / protected branches get a follow-up PR instead.
- Does not reverse-engineer scope or acceptance criteria from the diff — it
  judges against the ticket/spec, and asks when unclear.
- Does not build a test harness for QA or mint credentials — `qa` routes those
  to manual.
- Does not bundle a multi-subtask epic into one pass — scope and QA follow the
  subtask the PR maps to.

---

## Red flags — stop and surface

- **Can't resolve the PR's ticket** — report what you found and ask; don't
  invent scope.
- **Working tree is dirty** before `gh pr checkout` — stop; don't stash the
  reviewer's work.
- **About to post a finding you haven't verified** — re-derive it first; a
  false-positive REQUEST_CHANGES on a teammate's PR is the costliest miss here.
- **About to mark a non-web PR BLOCKED for "no Playwright"** — wrong call; pick
  the QA form for that PR type. BLOCKED is only "couldn't QA at all."
- **CI is red or still running** — don't approve over it; failing = changes
  requested, pending = hold.
- **Tempted to approve before QA** — never. QA PASS is the only gate to APPROVE.
- **About to push coverage to a fork or protected branch** — you can't / shouldn't;
  open a follow-up PR instead.
- **About to post REQUEST_CHANGES / APPROVE / push / merge without a yes** —
  stop and confirm first.
- **QA came back FAIL/BLOCKED but the code looked clean** — that's exactly the
  case this skill exists to catch. Do not approve.
- **Diff base isn't the PR's actual base** — use `origin/{baseRefName}`, not
  `main-branch`, when they differ.

---

## Integration notes

| Composes | How |
|----------|-----|
| `review` skill | Step 3 — full swarm (`tier: all`), score taken verbatim |
| `pr-review` agent | Step 4a — validates + places inline comments on the PR |
| `qa` skill | Step 5 — functional QA gate; approval requires its PASS |
| `jira-sync` (optional) | If the team auto-syncs status, a posted verdict can transition the ticket — leave that to `jira-sync`, don't transition here |
