---
name: finish
description: >
  Use when implementation is complete, all tests pass, and you need to decide
  how to integrate the work. Guides completion of development work by verifying
  tests, presenting structured options (merge, PR, keep, discard), executing the
  choice, and cleaning up worktrees.
tier: workflow
alwaysApply: false
---

# Finishing a Development Branch

**PURPOSE**: Guide the completion of development work through a structured decision flow: verify tests pass, present clear integration options, execute the chosen option, and clean up.

**GIT HOST**: PR creation in Option 2 uses GitHub (`gh`) as the default. If `git-host` in `casaflow.config.md` is not `github`, read `framework/GIT_HOST.md` for the platform-specific command equivalents.

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

**Announce at start:** "I'm using the finish skill to complete this work."

---

## When to Use

Invoke this skill when:
- Implementation is complete and all tasks are done
- `sdd` or `team-dev` reaches the end of execution
- The user says "we're done", "let's wrap up", "finish this branch", or "/finish"
- All planned tasks are implemented and tested

**Do NOT use when:**
- Tests are still failing (fix them first)
- Tasks remain in the implementation plan
- The review stage has not been completed

---

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass.**

Run the project's test suite:
```
<project-test-command>
```

**REQUIRED**: Use `verify` -- run the actual command, read the output, confirm zero failures before proceeding.

**If tests fail:**
```
Tests failing (N failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Do not proceed to Step 2. Fix the failures first.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

Read `main-branch` from `casaflow.config.md` (default: `main`).

```bash
git merge-base HEAD <main-branch>
```

Or ask: "This branch split from `<main-branch>` -- is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. All tests pass. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Do not add explanation** -- keep options concise. Wait for the user's choice.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test-command>

# If tests pass, delete the feature branch
git branch -d <feature-branch>
```

**If merge conflicts occur:**
- Show the conflicts to the user
- Ask how to resolve (do not auto-resolve)
- After resolution, run tests again before completing

**If tests fail after merge:**
- Report the failures
- Ask whether to abort the merge or fix forward

Then: Cleanup worktree (Step 5)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>
```

Then create the PR. Read `casaflow.config.md` for:
- `require-ticket-reference` -- whether to include ticket reference
- `ticket-system` -- which system to reference
- `branching.format` -- to extract ticket number from branch name

```bash
# Create PR with structured description
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

If the project has the `pr-create` skill, defer to it for PR creation.

Then: Cleanup worktree (Step 5)

#### Option 3: Keep As-Is

Report:
```
Keeping branch <name>. Worktree preserved at <path>.
```

**Do not clean up the worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch: <name>
- All commits: <commit-list>
- Worktree at <path> (if applicable)

Type 'discard' to confirm.
```

Wait for exact confirmation. Do not proceed without it.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 5)

### Step 5: Cleanup Worktree

**For Options 1, 2, and 4:**

Check if working in a worktree:
```bash
git worktree list
```

If the current directory is a worktree (not the main working tree):
```bash
# Navigate out of the worktree first
cd <main-working-tree-path>

# Remove the worktree
git worktree remove <worktree-path>
```

If the project uses a worktree management command (check `casaflow.config.md` or project scripts), use that instead.

**For Option 3:** Keep the worktree intact.

---

### Step 6: Generate the shipped artifact (Options 1 and 2 only)

**Skip this step for Option 3 (keep as-is) and Option 4 (discard).**

For work that has actually shipped (merged locally or opened as PR), produce
a `shipped.md` artifact that captures what was built vs what was planned.
This is the document the developer will react to during the retro.

#### Determine the casavault feature folder

Read `vault-path` and `project-name` from `casaflow.config.md`. The feature
folder follows the same pattern as `spec.md`:

```
<vault-path>/<project-name>/<feature-slug>/
```

The spec for this work should already be at:

```
<vault-path>/<project-name>/<feature-slug>/spec.md
```

If `spec.md` does not exist in the expected location, skip the shipped
artifact step — there's nothing to diff against. Report:

> "No spec.md found at <expected-path>. Skipping shipped artifact. Run
> `/casaflow:retro` directly when you're ready."

#### Generate shipped.md by diffing spec vs reality

Compose `shipped.md` in the feature folder. The file is generated at finish
time by diffing the spec against what actually shipped.

Source the diff from:

- **`spec.md`** in the casavault — the original intent
- **`git log` and `git diff <base-branch>..HEAD`** — what changed in code
- **PR description** (if Option 2) — for any decision summaries the developer wrote
- **Recent conversation history** — for divergences that surfaced during the build (e.g., scope changes, AC adjustments, postponements)

Write `shipped.md` with this structure:

```markdown
---
ticket: <from spec frontmatter>
ticket_url: <from spec frontmatter>
work_type: <from spec frontmatter>
spec_date: <from spec>
shipped_date: <today>
pr_url: <if Option 2>
spawned_tickets: [<any new tickets created during the build>]
---

# Shipped: <Feature Name>

Date shipped: <today> (<N days after spec>)

## One-line set-out
<First sentence of the spec's Feature Summary, restated as imperative>

## One-line shipped
<One sentence describing what actually shipped, with changed words highlighted via prose>

## Divergences from spec
### 1. <Label of divergence>
**When:** <Day N · date>
**Why:** <Rationale>
**Spec section affected:** <Acceptance Criteria #N | Non-Goals | Architecture Sketch | ...>

[Repeat for each divergence detected]

## Acceptance criteria — final
1. **KEPT:** / **CHANGED:** / **EXPANDED:** / **DROPPED → <ticket-id>:** / **NEW:** <criterion text>
[Repeat for each AC, with status prefix]

## Architecture — files actually touched
| Status | File | Notes |
|--------|------|-------|
| NEW / EDIT | <path> | <notes; if file wasn't in spec architecture, mark as "Unplanned"> |

Planned: <N> files. Touched: <M> files.

## Tickets spawned
- **<TICKET-ID>** — <title> (<reason>)
[Repeat for each follow-up ticket created during the build]

## Tests
- <N> unit tests
- <N> integration tests
- <N> e2e tests
- Mutation tested at <%>

## Open questions emerging from build
- <Question that surfaced during build and didn't have a follow-up ticket>
```

**Detecting divergences.** Walk the spec systematically:

1. **AC by AC:** Compare each acceptance criterion in `spec.md` to the final
   state. Did the threshold change? Did a channel get added? Did one get
   dropped to a follow-up? Mark each as KEPT, CHANGED, EXPANDED, DROPPED,
   or NEW.
2. **Files:** Compare the spec's Architecture Sketch file list to the
   actual touched files (`git diff --name-only <base-branch>..HEAD`).
   Files in the spec but not touched: postponed. Files touched but not in
   the spec: unplanned additions.
3. **Open questions:** For each open question in the spec, did it get
   resolved? If yes, how? If no, was a follow-up ticket created?
4. **Non-goals:** Did any non-goal end up in scope? That's a divergence.
5. **Feature flag:** Did the flag setup match the spec, or did it change
   (e.g., one flag became two)?

Be honest about divergences. They're not failures — they're the record of
real-world build decisions. The retro needs to see them clearly to learn
from them.

If you can identify the date a divergence happened (from commit history or
conversation context), include it. If you can't, omit the "When" line.

#### Offer the HTML view (opt-in)

After writing `shipped.md`, ask the developer whether they want the
interactive HTML view. **Do not invoke visualize without explicit consent
— `shipped.md` is the canonical record; the HTML is opt-in every time.**

> "Wrote `shipped.md` to `<path-to-shipped.md>`. It diffs spec vs reality
> across acceptance criteria, files touched, divergences, and spawned
> tickets.
>
> Want me to render it as an HTML view in your browser? It's laid out as
> set-out-vs-shipped with the divergence log easy to scan — useful as the
> starting point for retro. Reply **html** to open it, or **continue** to
> stay in the terminal."

Wait for the response:

- **html** → invoke `/casaflow:visualize <path-to-shipped.md>`. After it
  returns, set `shipped_view = html` for the post-completion message
  below. Then prompt: "Opened `shipped.html` in your browser. Type
  `ready` when you've reviewed it." Wait for `ready` before continuing.
- **continue** → set `shipped_view = md` and continue immediately.

The retro suggestion below is gated on this step completing — do not
recommend `/casaflow:retro` until the dev has confirmed they've seen the
shipped artifact (either via `ready` after the HTML render, or via
`continue` opting to use the markdown directly).

---

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | Yes | No | No | Yes (soft delete) |
| 2. Create PR | No | Yes | Yes (for PR updates) | No |
| 3. Keep as-is | No | No | Yes | No |
| 4. Discard | No | No | No | Yes (force delete) |

---

## Common Mistakes

| Mistake | Consequence | Fix |
|---------|------------|-----|
| Skipping test verification | Merge broken code, create failing PR | Always verify tests before offering options |
| Open-ended questions | "What should I do next?" is ambiguous | Present exactly 4 structured options |
| Automatic worktree cleanup | Remove worktree when user might need it | Only cleanup for Options 1 and 4 |
| No confirmation for discard | Accidentally delete work | Require typed "discard" confirmation |
| Merging without pulling latest | Merge conflicts discovered after merge | Always pull latest before merging |
| Not running tests after merge | Merge introduced regressions | Test the merged result before deleting branch |

---

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on the merged result
- Delete work without typed confirmation
- Force-push without explicit user request
- Auto-select an option without asking the user
- Clean up worktree for Option 3 (keep as-is)

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Run tests after merge (Option 1) before deleting the branch
- Check for worktree before cleanup

---

## Integration

**Called by:**
- `sdd` (terminal state) -- after all tasks complete and final review passes
- `team-dev` (terminal state) -- after all tasks complete and integration review passes

**Related skills:**
- `verify` -- used in Step 1 to verify tests pass
- `pr-create` -- can be used in Option 2 for more structured PR creation
- `review` -- should have been completed before reaching this skill

---

## Post-Completion

After the chosen option is executed, cleanup is done, and (for Options 1
and 2) the shipped artifact is generated **and the developer has confirmed
they've seen it** (Step 6 — either via `ready` after the HTML render or
via `continue` opting to use the markdown), suggest the retro.

Retro is suggested **after** the shipped artifact moment — never before.
The shipped doc is the retro's starting point; recommending retro before
the dev has read it strips the prompt of its anchor.

**If `shipped_view = html`:**

> "You've got `shipped.html` in front of you. When you want to capture
> what we learned from this feature, run `/casaflow:retro` — it'll
> pick up from the divergences and emergent open questions in the
> shipped doc."

**If `shipped_view = md`:**

> "`shipped.md` is at `<path-to-shipped.md>`. When you want to capture
> what we learned from this feature, run `/casaflow:retro` — it'll
> pick up from the divergences and emergent open questions in the
> shipped doc."

**For Options 3 and 4 (keep or discard, no shipped artifact):**

> "Work complete. If this was a feature or complex improvement, consider
> running `/casaflow:postmortem` to capture lessons learned."

Do not auto-invoke retro or postmortem -- just suggest.
