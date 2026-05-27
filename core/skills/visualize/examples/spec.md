---
ticket: CAS-1284
ticket_url: https://casaperks.atlassian.net/browse/CAS-1284
work_type: feature
date: 2026-05-27
flag:
  decision: "yes"
  semantics: adoption
  expected_sunset: 2026-09-30
  touched_repos:
    - CasaPerks-Web-React
    - CasaPerks-API
---

# Spec: Reward Expiry Warnings

Date: 2026-05-27

## Feature Summary

Currently rewards silently expire — users open the app, find a perk gone, and email support. This change surfaces upcoming expiry in the rewards list and (for users with push enabled) sends a 3-day-out notification. Expired rewards move into a collapsed "Expired" section instead of being hidden.

## Acceptance Criteria

1. Given a reward expiring within 7 days, when the user opens the rewards list, then a warning banner appears anchored to that reward.
2. Given a user with push notifications enabled and a reward expiring in exactly 3 days, when the daily expiry cron runs, then a push notification is queued via the existing notification service.
3. Given a reward past its expiry date, when the rewards list loads, then the reward appears under a collapsed "Expired" section rather than the main list.
4. Given the `reward-expiry-warnings` flag is off, when any of the above runs, then behavior matches current production exactly.

## Non-Goals

- Email expiry warnings. Push only for this iteration.
- User-configurable warning thresholds.
- Reactivating expired rewards.

## Test Spec

### Criterion 1: Banner appears
- Happy: Reward expiring in 6 days → banner renders with "Expires in 6 days".
- Failure: Reward already expired → banner does NOT render (it lives in the Expired section).
- False positive: Mock the date so every reward looks "expiring soon" — banner should NOT render on rewards 8+ days out.

### Criterion 2: Push notification
- Happy: User with push enabled, reward expiring exactly 3 days out → one push queued.
- Failure: User with push disabled → no push queued, no error.
- False positive: Cron ran twice in one day — second run should not double-send.

### Criterion 3: Expired section
- Happy: Past-expiry reward → renders under "Expired", section collapsed by default.
- Failure: No expired rewards → "Expired" section does not render at all.
- False positive: Reward expiring today at 23:59 — should still be active, not in Expired.

### Criterion 4: Flag off
- Happy: Flag off → list renders identical to current production snapshot.
- Failure: Flag flips off mid-session → next render reverts cleanly.
- False positive: Flag check evaluates to "expired" (falsy) → must not pass as "on".

## Architecture Sketch

- NEW: `CasaPerks-Web-React/src/components/rewards/ExpiryBanner.tsx` — renders the warning row
- EDIT: `CasaPerks-Web-React/src/components/rewards/RewardsList.tsx` — splits into Active / Expired sections
- NEW: `CasaPerks-API/jobs/reward-expiry-notifier.ts` — daily cron, queues pushes for 3-day expiry
- EDIT: `CasaPerks-Shared/rewards.ts` — adds `isExpiringSoon(reward, days)`

Data flow: cron reads `rewards` table → filters where `expires_at` is exactly 3 days out → batches by user → calls existing notification service. Frontend reads same `expires_at`, evaluates against client clock, renders banner.

## Feature Flag Decision

Yes. Adoption gate. Key `reward-expiry-warnings`. Sunset 2026-09-30. Touches Web-React and API.

## Open Questions

- Do we evaluate "within 7 days" in the user's local timezone or UTC?
- If a user has 5 rewards all expiring within 3 days, do they get 5 pushes or one batched push?
- Does the design system already have a warning banner pattern we should reuse?
