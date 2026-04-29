# CasaFlow Configuration

## Team

```yaml
name: <your-team-name>
platform: claude
git-host: github
ticket-system: jira
```

## Pipeline

```yaml
stages:
  - discover
  - brainstorm
  - plan
  - execute
  - review
  - ship
  - learn
```

### Stage Overrides by Work Type

```yaml
bug:
  skip: [brainstorm-full, learn]
  brainstorm: light
  spec-required: false
task:
  skip: [brainstorm, learn]
  review: light
  spec-required: false
```

## Spec Gate

```yaml
# Work types that require a spec before kickoff proceeds
spec-required-for:
  - feature
  - improvement
spec-dir: specs/
```

## Approval Gates

```yaml
gates-enabled: true

# Default stage definitions (override per project)
stages:
  - name: scaffold
    scope: "Project structure, dependencies, config, CI skeleton"
  - name: backend
    scope: "API endpoints, data layer, auth, validation, security"
  - name: frontend
    scope: "UI components, API integration, error handling, UX"
  - name: polish
    scope: "Tests, docs, edge cases, performance, accessibility"

# Stage 4 (polish) automatically invokes review-tests before gate questions
review-tests-on-polish: true
```

## Jira

```yaml
project-key: <YOUR-PROJECT-KEY>    # e.g. CASA, ENG, PLAT
auto-sync-spec: true               # Invoke jira-sync after spec is saved
auto-update-on-stage: true         # Update ticket status after each approved stage
done-on-merge: true                # Transition ticket to Done on merge
```

## Branching

```yaml
# Branch prefix is determined by work type (feature, fix, task)
# {ticket-id} is parsed from the Jira ticket key
feature: "feature/{ticket-id}:{kebab-title}"
fix: "fix/{ticket-id}:{kebab-title}"
default: "task/{ticket-id}:{kebab-title}"
main-branch: main
```

## Concerns Checklist

```yaml
# Skills or specialists invoked during brainstorm based on work type
# Values: path to skill/specialist, or "manual" for human review
error-handling: core/specialists/error-handling
security: core/specialists/security
test-strategy: packs/engineering/skills/eng-testing
# Add team-specific concerns below:
# accessibility: manual
# i18n: manual
# rate-limiting: manual
```

## Review

```yaml
swarm-tiers:
  fast-pass: [security, dead-code, error-handling]
  full: all
deep-review-model: opus
specialist-model-default: haiku
```

## Execution

```yaml
parallel-threshold: 3
default-strategy: team-dev
teammate-mode: tmux
```

## Commit

```yaml
convention: conventional
format: "type(scope): message"
types: [feat, fix, docs, chore, refactor, test]
scopes: []                          # Fill in your team's scopes
require-ticket-reference: true      # Include Jira ticket key in commit footer
co-author: true
```

## Retro

```yaml
auto-prompt: true      # Prompt for retro after finish/merge
retro-dir: retros/
```

## Feature Flags

```yaml
# Per-repo paths to the feature flag registry. eng-flags writes registry
# entries to these paths and uses them for the repo-discovery infra check.
# Add an entry per repo that participates in flag-gating.
registry-paths:
  CasaPerks-Web-React: src/services/posthog/feature-flags.ts
  # Casaperks-Backend: <fill in once known>
  # WorksPerks-Web-React: <fill in once known>

# PostHog environments where flags must exist with matching key + default.
# eng-flags creates the flag in each listed environment as one transaction.
posthog-environments:
  - dev
  - production

# MCP server name for PostHog flag operations. Used by eng-flags to invoke
# create-feature-flag and equivalent tools.
posthog-mcp-namespace: posthog
```

## Repos

```yaml
# Repos eng-flags will prompt for when a feature spans multiple surfaces.
# A flag with shared key gets registry entries written into each touched repo.
in-scope-for-flags:
  - CasaPerks-Web-React
  # - Casaperks-Backend
  # - WorksPerks-Web-React
  # Mobile clients are aspirational — see CAS-713 spec OQ #5.
```
