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

This is the heart of eng-flags: an atomic transaction that takes the developer's consent once and either creates the flag everywhere or surfaces partial state for resolution. Never silently rolls back.

### Inputs

Before this flow runs, the following are known:
- Spec frontmatter: `flag.decision`, `flag.semantics`, `flag.expected_sunset`, `flag.touched_repos`.
- Config: `Feature Flags > registry-paths`, `posthog-environments`, `posthog-mcp-namespace`.
- Validated key (see `## Validation`).

### Steps

1. **Confirm touched repos.** Display the list parsed from spec frontmatter and ask the developer to confirm. Allow editing the list inline. Each confirmed repo proceeds to the infra check.

2. **Run repo discovery on each touched repo.** Apply `## Repo Discovery`. Resolve all infra gaps before proceeding.

3. **Draft the flag.** Build the flag spec from inputs:
   - `key` (validated)
   - `default` (`true` for `*-enabled`, `false` for `*-rollout`)
   - `semantics` (kill-switch | adoption)
   - `expected_sunset`
   - `owner`
   - `description` (one-line, sanitized — see `## Validation`)

4. **Bulk consent prompt.** Render the full plan in one message:

   > "Ready to create the flag.
   >
   > **Key:** `redemption-flow-rollout`
   > **Semantics:** adoption gate (default: `false`)
   > **Owner:** growth-team
   > **Expected sunset:** 2026-07-01
   >
   > **PostHog environments:** dev, production
   > **Registry writes:** CasaPerks-Web-React/src/services/posthog/feature-flags.ts
   >
   > Approve creating the flag in all environments and writing registry entries to all repos? (yes / no)"

   - **no** → exit. No MCP calls, no registry writes.
   - **yes** → continue.

5. **Create flag in each PostHog environment.** Loop over `posthog-environments`. For each env, invoke the PostHog MCP `create-feature-flag` tool with the drafted flag spec.
   - **On success** → record env as created, continue to next env.
   - **On transient failure** (network, rate limit, 5xx) → retry the call once. If retry succeeds, treat as success.
   - **On persistent failure** (retry also fails, 4xx, auth error) → enter manual fallback for that env (step 6).

6. **Manual fallback (per environment that failed).**

   > "PostHog MCP failed for the **production** environment after retry. To proceed, create the flag manually:
   >
   > 1. Open: `https://app.posthog.com/project/<prod-project-id>/feature_flags/new`
   > 2. Set:
   >    - **Key:** `redemption-flow-rollout`
   >    - **Default:** `false`
   >    - **Description:** Gates the new redemption flow for staged rollout
   >    - **Tags:** owner=growth-team, sunset=2026-07-01
   > 3. Save the flag.
   >
   > Reply `done` once created, or `abandon` to stop the workflow."

   - **done** → invoke MCP `feature-flag-get` to verify the flag exists. If verification succeeds, mark env as created. If verification also fails (network, auth), accept the developer's confirmation and log a warning into spec frontmatter (`flag.manual_fallback_envs: [production]`) so retro can surface it.
   - **abandon** → exit. Leave any successfully-created envs in place. Log abandonment in spec frontmatter (`flag.abandoned_envs: [production]`). Block the rest of the build until the developer either re-runs eng-flags or manually completes the env.

7. **Write registry entries.** Only after every PostHog env is in the "created" state (auto or manual). For each touched repo:
   - Open the configured registry file.
   - Insert a new entry following the CAS-577 shape (see `## Naming Conventions`). Position alphabetically among existing entries.
   - Add or update the JSDoc with `@owner` and `@expected_sunset`.

8. **Verify and commit.** Run any repo-local validation (e.g., `tsc --noEmit` if the repo is TypeScript) on each modified file. If validation fails, surface the error and ask whether to revert the registry write for that repo. Do not auto-commit; commit happens as the next plan task.

### Failure semantics

- **No auto-rollback.** If env A succeeds but env B fails persistently and the developer abandons, env A's flag stays in place. The retro will surface this for cleanup decisions. (Spec non-goal #4.)
- **Half-written registries are blocked.** Registry writes only happen after every env is created. If env creation half-fails, no registry entries are written.
- **Repo-local validation failure.** Treated as a soft block — surface the error, let the developer decide whether to revert the registry write or fix the issue inline. eng-flags does not silently swallow validation errors.

## Validation

[FILLED IN BY TASK 10]
