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

Conventions established by CAS-577 (PostHog flag pattern in CasaPerks-Web-React). Embedded here for self-contained reference. Source of truth: [CAS-577](https://casaperks.atlassian.net/browse/CAS-577).

### Key shape

Flag keys are kebab-case, lowercase, and end in one of two suffixes that signal the flag's semantics:

- **Kill switch:** `*-enabled`. Default value `true`. Used for safety hatches that disable a feature in production. Existing behavior continues until the flag is flipped off.
- **Adoption gate:** `*-rollout`. Default value `false`. Used for new features under gradual rollout. New behavior is invisible until the flag is flipped on per-user, per-cohort, or globally.

Canonical regex: `^[a-z][a-z0-9-]*-(enabled|rollout)$`

| Valid | Invalid |
|---|---|
| `redemption-flow-rollout` | `redemption_flow_rollout` (no underscores) |
| `payouts-enabled` | `RedemptionFlow-rollout` (no uppercase) |
| `new-checkout-rollout` | `redemption-flow` (must end with `-enabled` or `-rollout`) |

### Registry entry shape

Each flag is registered in `feature-flags.ts` (or per-repo equivalent) with JSDoc that includes `@owner` and `@expected_sunset` fields:

```typescript
/**
 * Gates the new redemption flow for staged rollout.
 * @owner growth-team
 * @expected_sunset 2026-07-01
 */
'redemption-flow-rollout': {
  key: 'redemption-flow-rollout',
  default: false,
}
```

### Field semantics

- **`@owner`** — engineer, team, or Slack channel responsible for the flag's lifecycle. eng-flags asks the developer to specify; default is the developer's git user.
- **`@expected_sunset`** — ISO date (`YYYY-MM-DD`) when this flag is expected to be removed. Used by retro question 6 to surface stale flags. Sunset dates more than 6 months out trigger a warning.

## Lifecycle

[FILLED IN BY TASK 8]

## Repo Discovery

[FILLED IN BY TASK 8]

## Creation Flow

[FILLED IN BY TASK 9]

## Validation

[FILLED IN BY TASK 10]
