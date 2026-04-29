# Casaflow Tests

This directory contains the static and fixture-based tests for the Casaflow plugin.

## Static tests

`tests/static/run.sh` runs all static structural tests. Each test is a bash script that exits 0 on pass, non-zero on fail.

Run all:

    bash tests/static/run.sh

Run individually:

    bash tests/static/test-config-blocks.sh

### What static tests cover

- Config schema (Feature Flags + Repos blocks present and complete)
- Plugin registration (eng-flags in `.claude-plugin/plugin.json`)
- Skill loadability (eng-flags frontmatter valid, required sections present, < 500 lines)
- Section presence in modified skills (spec/plan/verify/pr-create/retro)
- CAS-577 naming regex behavior (accepts valid keys, rejects malformed)
- Frontmatter parsing references (spec-driven consumer skills branch on `flag.decision`; pr-create uses diff-based detection)

### What static tests do NOT cover

- Behavior of skills when invoked. LLM-driven flows are inherently variable;
  see manual fixtures below.
- Real PostHog MCP integration. The MCP itself is mocked in fixtures.

## Manual fixtures

`tests/fixtures/` contains sample spec files for walking through skill behavior manually. Use these whenever you change a flag-related skill:

1. **spec-flag-yes.md** — exercises the `flag.decision: yes` branch through plan, verify, retro.
2. **spec-flag-no.md** — exercises the no-flag escape valve.

### Manual fixture walkthrough

For a flag-related change to any skill, run this checklist:

- [ ] Copy the appropriate fixture to a temp vault path (`~/Documents/casaflow/fixture-test/spec.md`).
- [ ] Run `/casaflow:plan` against the fixture — confirm output matches expected behavior per the fixture's acceptance criteria.
- [ ] Run `/casaflow:verify` — confirm checklist behavior matches.
- [ ] Run `/casaflow:retro` — confirm question set matches.
- [ ] If any divergence, the underlying skill modification has regressed; investigate before merging.
