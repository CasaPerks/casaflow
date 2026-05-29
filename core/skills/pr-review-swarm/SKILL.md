---
name: pr-review-swarm
description: >
  Use when you've been added as a reviewer on a pull request and need to review
  it end-to-end — a reviewer-triggered PR review, not a review of your own
  pre-PR diff. Pulls the PR branch down, checks the work against its Jira
  ticket scope, checks coding-guideline adherence, dispatches the parallel
  review swarm, and posts an approval or a request-changes review. When the
  review is approve-worthy, it gates the approval on the qa skill: QA must
  PASS before the PR is approved to merge. Every outward action (posting a
  review, approving, merging) is confirmed with the reviewer first. Invoked by
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
the `qa` skill has built out e2e coverage for it — and that coverage is
committed onto the PR (Step 5a), so the change merges *with* its regression
tests, not without them.

This is *not* `code-review` (which reviews *your own* `origin/main...HEAD`
before you open a PR) and it is *not* `qa` alone (functional verification). It
**orchestrates** the existing organs around the reviewer's question: *should
this PR merge?*

```
resolve + checkout PR
   → scope check (vs Jira ticket / spec)
   → guidelines check
   → review swarm  (review skill, tier: all)
   → VERDICT
        ├─ changes needed → post REQUEST_CHANGES (confirm) → STOP
        └─ approve-worthy → run QA (qa skill)
                               ├─ QA PASS  → post APPROVE (confirm) → offer merge (confirm)
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

1. **NEVER post a review, approve, or merge without explicit reviewer
   confirmation.** Posting a review and merging are outward-facing and hard to
   reverse. Always show the draft verdict and wait for a yes.
2. **NEVER approve before QA passes.** A clean swarm is not approval. The only
   path to APPROVE is: swarm clean + in scope + guidelines met **and** QA
   result is PASS.
3. **The swarm score is mechanical** — don't bump it because the change "looks
   fine." Use the score the `review` skill produces.
4. **Don't reverse-engineer scope from the diff.** Scope is judged against the
   ticket's acceptance criteria and the spec, not invented from the code.
5. **Run against the real checked-out branch**, not a guess of what it
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

Hand that diff to the `review` pipeline and take its **mechanical score and
findings** verbatim — discover specialists, dispatch in parallel, collect,
deep-review, score, report. Do not re-evaluate or soften the findings.

---

## Step 4: Verdict

Combine the three inputs into one decision. **REQUEST_CHANGES** if any of:

- The swarm reports any **blocking** finding (score ≤ 4), **or**
- The change is **out of scope** (scope creep) or **incomplete** vs AC, **or**
- There are **coding-guideline violations** that the team treats as required.

Otherwise the change is **approve-worthy** — but it is **not approved yet**. It
proceeds to QA (Step 5) before any approval.

Major/minor swarm findings that aren't blocking are reviewer's judgment: note
them in the review body; they don't by themselves force REQUEST_CHANGES.

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

## Step 5: QA gate (approve-worthy changes only)

**REQUIRED**: Use the `qa` skill to verify the feature actually works before
approving. Invoke it on the same target:

```
/casaflow:qa <ticket-id | PR url>
```

`qa` runs the feature's existing tests, generates/runs Playwright e2e for the
AC, writes a pass/fail `qa.md`, and — if the ticket has subtasks — QAs them one
at a time. Let it run its full loop, including its required `qa.html` prompt.
Read the **`result`** from the resulting `qa.md` front matter.

| QA `result` | Next |
|-------------|------|
| **PASS** | → Step 5a (land the e2e coverage on the PR) → Step 6 (approve) |
| **FAIL** | Do **not** approve. Summarize the failing checks; with confirmation, post a REQUEST_CHANGES (or a comment) citing the QA failures and link `qa.md`. STOP. |
| **BLOCKED** | Do **not** approve. Report what blocked QA (e.g. no test harness, login the repo can't provide) and hand back to the reviewer. STOP. |

If QA produced manual checks the reviewer hasn't signed off, surface them — a
PASS that still has unresolved manual checks is not a clean pass; ask the
reviewer before treating it as PASS.

### 5a. Land the e2e coverage on the PR (the point of the gate)

The goal isn't just "QA passed once" — it's that **the PR merges carrying the
regression coverage QA built.** `qa` saves its generated Playwright specs by
default; because Step 0b checked the branch out, those new spec files are now
in the PR's working tree.

1. `git status` to find the e2e specs `qa` generated (and any fixtures it added).
2. If there are new/changed specs, **commit and push them onto the PR branch**
   (with confirmation — this writes to someone else's PR):

   ```bash
   git add <generated e2e spec paths>
   git commit -m "test(e2e): add QA regression coverage for <ticket>"
   git push origin HEAD
   ```
   Follow the repo's commit convention (`casaflow.config.md`). Now the e2e
   coverage is part of what merges, not a throwaway local artifact.
3. If `qa` routed everything to **manual** (no harness, or login it can't
   provide), there's nothing to commit — note in the approval that coverage is
   manual-only so the gap is visible.

---

## Step 6: Approve to merge (QA passed)

Only reachable when the swarm was clean, the work was in scope and on-guideline,
**and** QA result is PASS.

1. Draft the APPROVE review body:
   - Swarm score and that it was clean / non-blocking.
   - Scope: confirmed against `<ticket>` AC.
   - QA: PASS — link `qa.md` (and `qa.html` if generated), note automated vs
     manual counts, and that the generated e2e specs were committed to the
     branch (from Step 5a) so the PR merges with regression coverage.
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
- Does not approve on a clean code review alone — approval is QA-gated.
- Does not post any review, approval, or merge without explicit reviewer
  confirmation.
- Does not re-score or soften swarm findings — the `review` score is
  authoritative.
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
- **Tempted to approve before QA** — never. QA PASS is the only gate to APPROVE.
- **About to post REQUEST_CHANGES / APPROVE / merge without a yes** — stop and
  confirm first.
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
