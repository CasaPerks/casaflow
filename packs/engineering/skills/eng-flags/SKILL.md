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

A flag's life has four stages. eng-flags handles stages 1 and 2; the developer drives stages 3 and 4 with eng-flags' help.

1. **Create** (this skill) — atomic transaction creates the flag in all configured PostHog environments and writes registry entries to all touched repos. Default value is set per the semantics chosen.
2. **Roll out** — the developer (or PM) flips the flag in the PostHog UI per-cohort, per-percentage, or globally. eng-flags is not involved.
3. **Promote / kill** — once the rollout decision is made, the flag's outcome is locked in code. For an adoption gate, the new behavior becomes the default and the flag is removed. For a kill switch, the safety hatch is retired. Either way, the registry entry is deleted and code that read the flag is simplified.
4. **Archive** — the PostHog flag is archived (not deleted; preserves analytics). eng-flags does not automate archival; this is intentional (spec non-goal #4). The retro question on close-out (criterion 6) surfaces flags ready for archival.

## Repo Discovery

Before creating a flag, eng-flags confirms each touched repo has flag infrastructure. The check is a single signal: does the registry file exist at the path configured in `casaflow.config.md`?

### The check

For each repo in `flag.touched_repos`:

1. Look up the path from the `Feature Flags > registry-paths` block in `casaflow.config.md`.
2. If the repo is not in `registry-paths`, the infra check fails: "no registry path configured for this repo."
3. If the path is configured but the file is missing in the local worktree, distinguish two cases:
   - **Repo not cloned.** The configured path's parent directory does not exist. Surface: "clone <repo> first, then re-run." Do not treat as missing infra.
   - **Repo cloned, file missing.** The repo is checked out but the registry file is absent. Surface as missing infra and offer the two paths below.

### Missing-infra fallback

When infra is missing for a touched repo, eng-flags does not silently skip it. Two options are offered to the developer:

- **(A) Port the pattern from CasaPerks-Web-React inline.** eng-flags scaffolds the registry file shape based on the canonical CAS-577 layout, commits it as a separate prep commit, and includes it in this flag's setup. This is appropriate when the repo will host multiple flags going forward.
- **(B) File an infrastructure ticket and exclude this repo from the flag's scope.** eng-flags drafts a Jira ticket (against the appropriate project) and updates `flag.touched_repos` in the spec to remove the excluded repo. The flag still gets created in the remaining repos.

`FEATURE_FLAGS.md` is **not** part of the infra check. It is documentation, not a gate. If a repo has a registry but no `FEATURE_FLAGS.md`, eng-flags proceeds normally.

## Creation Flow

[FILLED IN BY TASK 9]

## Validation

[FILLED IN BY TASK 10]
