---
name: eng-flags
description: Use when creating, modifying, or sunsetting a feature flag for any CasaPerks feature. Drives flag setup as an atomic transaction across PostHog and per-repo registries with bulk consent, retry-once, and manual fallback on persistent MCP failure.
tier: standards
alwaysApply: false
---

# Feature Flag Engineering

**PURPOSE**: Bake the CAS-577 PostHog flag pattern into Casaflow as a deliberate, consent-driven workflow step. Every flag is created with explicit semantics, sunset, and registry parity across all touched repos. No flag without consent. No registry without flag. No partial state without surfacing.

**CONFIGURATION**: Reads `casaflow.config.md` for `Feature Flags` block (registry-paths, posthog-environments, posthog-mcp-namespace) and `Repos` block (in-scope-for-flags).

---

## When to Use

Invoked automatically by `build` when a plan task body contains `/casaflow:eng-flags`. Can also be invoked directly for exploratory flag work.

**Do NOT use when:**
- The feature has no user-facing surface (`spec.md` frontmatter `flag.decision: no`).
- A flag with the desired key already exists and matches the planned semantics — `eng-flags` would refuse anyway, but skip the invocation.

---

## Naming Conventions

[FILLED IN BY TASK 7]

## Lifecycle

[FILLED IN BY TASK 8]

## Repo Discovery

[FILLED IN BY TASK 8]

## Creation Flow

[FILLED IN BY TASK 9]

## Validation

[FILLED IN BY TASK 10]
