---
ticket: FIXTURE-001
work_type: feature
date: 2026-04-28
flag:
  decision: "yes"
  semantics: adoption
  expected_sunset: 2026-09-01
  touched_repos:
    - CasaPerks-Web-React
---

# Spec: Fixture — flag-yes path

Manual-fixture spec for testing eng-flags' happy path. Run /casaflow:plan against this spec and confirm the resulting plan emits an /casaflow:eng-flags task as Task #1.

## Feature Summary
Fixture only — exercises the flag.decision: yes branch end-to-end.

## Acceptance Criteria
1. Given the fixture spec, when /casaflow:plan runs, then the plan must emit eng-flags as Task #1.
2. Given the fixture spec, when /casaflow:verify runs, then the three-evidence checklist must appear.
3. Given the fixture spec, when /casaflow:retro runs, then Question F1/F2/F3 must be asked.

## Non-Goals
- Real flag creation. This fixture is for local skill verification.
- Mobile coverage.

## Test Spec
N/A — fixture.

## Architecture Sketch
N/A — fixture.

## Feature Flag Decision
Yes; adoption gate; sunset 2026-09-01; touched repo CasaPerks-Web-React.

## Open Questions
None.
