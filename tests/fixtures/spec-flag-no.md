---
ticket: FIXTURE-002
work_type: feature
date: 2026-04-28
flag:
  decision: no
  reason: Internal config refactor — no user-facing surface, no behavior change visible to end users.
---

# Spec: Fixture — flag-no path

Fixture for testing the no-flag escape valve.

## Feature Summary
Fixture only — exercises the flag.decision: no branch.

## Acceptance Criteria
1. Given this spec, /casaflow:plan must NOT emit an eng-flags task.
2. Given this spec, /casaflow:verify must NOT require three-evidence checklist.
3. Given this spec, /casaflow:retro must NOT ask Questions F1/F2/F3.

## Non-Goals
- See criteria 1-3 (the no-go list).

## Test Spec
N/A — fixture.

## Architecture Sketch
N/A — fixture.

## Feature Flag Decision
No; reason: Internal config refactor — no user-facing surface.

## Open Questions
None.
