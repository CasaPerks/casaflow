---
ticket: CAS-1284
ticket_url: https://casaperks.atlassian.net/browse/CAS-1284
work_type: feature
spec_date: 2026-05-27
shipped_date: 2026-06-04
pr_url: https://github.com/casaperks/CasaPerks-Web-React/pull/3127
spawned_tickets:
  - CAS-1305
  - CAS-1312
  - CAS-1318
---

# Shipped: Reward Expiry Warnings

Date shipped: 2026-06-04 (8 days after spec)

## One-line set-out
Warn users about rewards expiring within 7 days, via push, behind one flag.

## One-line shipped
Warn users about rewards expiring within 14 days, via push **and** email, behind two flags. Per-reward dismiss added. Expired-section postponed.

## Divergences from spec

This is the running log Claude maintained throughout the build. Each entry records what changed, when, and why.

### 1. Threshold extended: 7 days → 14 days
**When:** Day 2 of build (2026-05-29)
**Why:** Sara (product) shared user research mid-sprint showing average user engagement was bi-weekly, not weekly. 7-day warning would miss users who only opened the app every 10 days. Extended to 14.
**Spec section affected:** Acceptance Criteria #1.

### 2. Email added back into scope
**When:** Day 3 (2026-05-30)
**Why:** iOS push delivery was unreliable in QA — about 30% of test pushes failed silently in TestFlight. Email added as a fallback channel so users on iOS still got notified. Spawned CAS-1305 to investigate the underlying push issue.
**Spec section affected:** Non-Goals (email was explicitly a non-goal), Acceptance Criteria #2.

### 3. Flag count: 1 → 2
**When:** Day 4 (2026-05-31)
**Why:** Decided to split the in-app banner and the notifications into separate flags for safer rollout. Banner rollout can be aggressive; notification rollout needs to be careful (you can't undo a sent push).
**Spec section affected:** Feature Flag Decision.
**New flags:** `reward-expiry-banner` (kill-switch), `reward-expiry-notifications` (adoption).

### 4. AC dropped: Expired section postponed
**When:** Day 5 (2026-06-01)
**Why:** Implementing the "Expired" section required broader changes to RewardsList layout than originally estimated. To hit the ship date, postponed to CAS-1318 as a follow-up. The "warning before expiry" piece (the core ask) ships now.
**Spec section affected:** Acceptance Criteria #3 (dropped).

### 5. AC added: Per-reward dismiss
**When:** Day 5 (2026-06-01)
**Why:** Sara asked for it after seeing the design in the staging build. "If a user knows they're going to use it, the warning becomes noise." Added a dismiss button with per-reward state persistence.
**Spec section affected:** Acceptance Criteria (new #5).

### 6. Open question resolved: Banner component
**When:** Day 1 (2026-05-28)
**Why:** Design system already had a `<WarningBanner>` component. Reused. Saved roughly half a day.
**Spec section affected:** Open Questions #3.

### 7. Open question partially resolved: Timezone
**When:** Day 4 (2026-05-31)
**Why:** Shipped using UTC for the cron evaluation, with a one-line note in the README that this is a known approximation. Spawned CAS-1312 for a proper local-timezone implementation. Acceptable for v1 because the 14-day threshold makes boundary errors low-impact.
**Spec section affected:** Open Questions #1.

### 8. Open question resolved: Batching
**When:** Day 3 (2026-05-30)
**Why:** Shipped with one daily digest push per user, listing all rewards expiring in the next 14 days. Decision made in PR review — multiple pushes felt spammy.
**Spec section affected:** Open Questions #2.

## Acceptance criteria — final

1. **KEPT (modified):** Given a reward expiring within **14** days (was: 7), banner appears anchored to that reward.
2. **EXPANDED:** Given a user with push or email enabled and a reward expiring in 3 days, a notification is queued via the appropriate channel(s).
3. **DROPPED → CAS-1318:** Expired rewards section.
4. **KEPT (modified):** Given both flags off, behavior matches current production.
5. **NEW:** Given a user dismisses an expiry warning for a specific reward, the warning does not reappear for that reward.

## Architecture — files actually touched

| Status | File | Notes |
|--------|------|-------|
| NEW | `CasaPerks-Web-React/src/components/rewards/ExpiryBanner.tsx` | As planned, but wraps existing design-system `<WarningBanner>` |
| EDIT | `CasaPerks-Web-React/src/components/rewards/RewardsList.tsx` | As planned, minus the Expired section split |
| EDIT | `CasaPerks-Web-React/src/components/rewards/RewardCard.tsx` | **Unplanned** — added dismiss button |
| NEW | `CasaPerks-Web-React/src/state/dismissed-rewards.ts` | **Unplanned** — dismiss state persistence |
| NEW | `CasaPerks-API/jobs/reward-expiry-notifier.ts` | As planned (push) |
| NEW | `CasaPerks-API/jobs/reward-expiry-emailer.ts` | **Unplanned** — email fallback channel |
| EDIT | `CasaPerks-Shared/rewards.ts` | As planned (`isExpiringSoon()` added) |

Planned: 4 files. Touched: 7 files.

## Tickets spawned

- **CAS-1305** — iOS push reliability investigation (root cause for the 30% silent-fail rate)
- **CAS-1312** — Timezone-aware expiry evaluation (follow-up to UTC shortcut)
- **CAS-1318** — Expired rewards section (postponed AC #3)

## Tests

- 14 unit tests
- 4 integration tests
- 2 e2e tests
- Mutation tested at 87%

## Open questions emerging from build

- Should the email channel be on by default for new users, or opt-in?
- How do we measure whether the warnings actually reduced support tickets? (Original ticket asked for "fewer support tickets" but no metric was attached.)
- The dismiss state is currently per-device. Should it sync across devices?
