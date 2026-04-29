---
name: verify
description: >
  Use when about to claim work is complete, fixed, or passing, before committing
  or creating PRs. Requires running verification commands and confirming output
  before making any success claims. Evidence before assertions, always.
tier: workflow
alwaysApply: false
---

# Verification Before Completion

**PURPOSE**: Prevent false completion claims by enforcing fresh verification evidence before any assertion of success. Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

---

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command in this message, you cannot claim it passes.

---

## When to Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction about the work
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to the next task
- Delegating to agents
- Reporting status to the user

**Rule applies to:**
- Exact phrases ("all tests pass", "build succeeds", "bug fixed")
- Paraphrases and synonyms ("everything looks good", "we're green")
- Implications of success ("ready to merge", "ready for review")
- ANY communication suggesting completion or correctness

---

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

### Step-by-Step

**IDENTIFY** -- What would prove the claim you are about to make? A test command, a build command, a lint command, a curl request. Name the exact command.

**RUN** -- Execute the full command. Not a subset. Not a cached result. Not "I ran it earlier." Fresh execution, right now, in this message.

**READ** -- Read the full output. Check the exit code. Count the failures, errors, and warnings. Do not skim. Do not assume.

**VERIFY** -- Does the output actually confirm what you are about to claim? A passing lint check does not confirm a passing build. A passing build does not confirm passing tests. Match the evidence to the specific claim.

**CLAIM** -- Now, and only now, make the claim. Include the evidence: "All 47 tests pass (output above)." Not just "tests pass."

---

## Feature Flag Verification

If `spec.md` frontmatter has `flag.decision: yes`, verify is incomplete until the developer collects three pieces of evidence — one per state. Each must be a distinct artifact (URL, screenshot, log line). Pasting the same evidence three times does not count.

### Required evidence

1. **Flag ON — feature works.** Screenshot, video, or test output showing the gated behavior in its enabled state.
2. **Flag OFF — feature is hidden or disabled.** Screenshot or test output showing the previous behavior is preserved when the flag is off.
3. **`$feature_flag_called` event observed.** A direct link to the PostHog event timeline showing the event firing for the flag key, ideally with a timestamp matching the dev's manual test.

### How to record evidence

In the verify output, record each piece of evidence with:
- Label (ON / OFF / event)
- URL or path
- A one-line description distinguishing it from the others

Example:

```
flag-ON:    https://example.com/screenshots/redemption-on.png — confirms new redemption modal renders
flag-OFF:   https://example.com/screenshots/redemption-off.png — confirms legacy CTA is shown
event:      https://app.posthog.com/events?key=redemption-flow-rollout — event fired at 2026-04-28T15:22Z
```

### Block conditions

- Any of the three slots empty → block.
- Two or three slots have identical URLs → block. Re-prompt for distinct evidence.
- The PostHog event link does not contain the flag key in its query → block; the dev probably linked the wrong event.

---

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| "Tests pass" | Test command output showing 0 failures | Previous run, "should pass", partial run |
| "Linter clean" | Linter output showing 0 errors | Partial check, extrapolation from subset |
| "Build succeeds" | Build command with exit 0 | Linter passing, "logs look good" |
| "Bug fixed" | Test of original symptom passes | Code changed, assumed fixed |
| "Regression test works" | Red-green cycle verified | Test passes once (never saw it fail) |
| "Agent completed task" | VCS diff shows correct changes | Agent reports "success" |
| "Requirements met" | Line-by-line checklist against spec | Tests passing (tests may not cover all requirements) |
| "No regressions" | Full test suite passes | Only new tests run |
| "Works in production" | Production verification (health check, smoke test) | Works locally |

---

## Red Flags -- STOP

If you catch yourself doing any of these, STOP and run the gate function:

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit/push/PR without verification
- Trusting agent success reports without checking the diff
- Relying on partial verification ("I ran the unit tests" when the claim is "all tests pass")
- Thinking "just this once"
- Tired and wanting the work to be over
- **ANY wording implying success without having run verification**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter is not the compiler. Linter is not the test suite. |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion is not an excuse |
| "Partial check is enough" | Partial proves nothing about the whole |
| "Different words so rule doesn't apply" | Spirit over letter |
| "I ran it a few messages ago" | Stale evidence. Run it again. |
| "The change is trivial" | Trivial changes break things too |

---

## Key Patterns

### Tests

```
CORRECT:  [Run test command] -> [See: 47/47 pass] -> "All 47 tests pass"
WRONG:    "Should pass now" / "Looks correct" / "Tests were passing earlier"
```

### Regression Tests (TDD Red-Green)

```
CORRECT:  Write test -> Run (PASS) -> Revert fix -> Run (MUST FAIL) -> Restore -> Run (PASS)
WRONG:    "I've written a regression test" (without red-green verification)
```

### Build

```
CORRECT:  [Run build] -> [See: exit 0, no errors] -> "Build succeeds"
WRONG:    "Linter passed" (linter does not check compilation)
```

### Requirements

```
CORRECT:  Re-read spec -> Create checklist -> Verify each item -> Report gaps or completion
WRONG:    "Tests pass, task complete" (tests may not cover all requirements)
```

### Agent Delegation

```
CORRECT:  Agent reports success -> Check VCS diff -> Verify changes are correct -> Report actual state
WRONG:    Trust agent report at face value
```

### Multi-Step Verification

For claims that span multiple dimensions (e.g., "ready to merge"):

```
CORRECT:
  1. Tests pass (run test suite, show output)
  2. Build succeeds (run build, show exit code)
  3. Linter clean (run linter, show output)
  4. Requirements met (checklist against spec)
  -> "Ready to merge: tests pass (47/47), build clean, lint clean, all 6 requirements verified"

WRONG:
  "Everything looks good, ready to merge"
```

---

## Why This Matters

False completion claims cause:
- Trust broken between agent and user
- Undefined functions shipped -- would crash at runtime
- Missing requirements shipped -- incomplete features
- Time wasted on false completion -> redirect -> rework
- Downstream work built on incorrect assumptions

The cost of running a verification command is seconds. The cost of a false claim is hours of rework and damaged trust.

---

## Integration

**Called by:**
- `debug` -- before claiming a fix works (Phase 4, Step 3)
- `sdd` -- before marking a task complete
- `team-dev` -- before marking a task complete
- `finish` -- before presenting completion options

**Related skills:**
- `tdd` -- TDD's verify-red and verify-green steps are verification instances
- `debug` -- Phase 4 requires verification before claiming fix success

---

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
