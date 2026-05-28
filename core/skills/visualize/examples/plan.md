---
ticket: CAS-1284
ticket_url: https://casaperks.atlassian.net/browse/CAS-1284
spec: ~/Documents/casaflow/reward-expiry-warnings/spec.md
date: 2026-05-28
---

# Reward Expiry Warnings Implementation Plan

> **Spec:** ~/Documents/casaflow/reward-expiry-warnings/spec.md
> **For agents:** Use team-dev (parallel) or sdd (sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface upcoming reward expiry in the rewards list and queue a 3-day-out push for users with push enabled.

**Architecture:** Daily cron in CasaPerks-API reads the rewards table, batches users with rewards expiring in exactly 3 days, calls the existing notification service. The web client reads the same `expires_at` field and renders an `ExpiryBanner` on rewards within 7 days; expired rewards move to a collapsed "Expired" section.

**Tech Stack:** TypeScript, React, Node.js cron, PostgreSQL, existing notification-service client, PostHog feature flags

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `CasaPerks-Shared/rewards.ts` | Modify | Add `isExpiringSoon(reward, days)` helper |
| `CasaPerks-Web-React/src/components/rewards/ExpiryBanner.tsx` | Create | Renders the per-reward warning row |
| `CasaPerks-Web-React/src/components/rewards/RewardsList.tsx` | Modify | Splits list into Active and Expired sections, mounts banner |
| `CasaPerks-API/jobs/reward-expiry-notifier.ts` | Create | Daily cron, batches users, queues pushes |
| `CasaPerks-Shared/tests/rewards.test.ts` | Modify | Unit tests for `isExpiringSoon` |
| `CasaPerks-Web-React/src/components/rewards/__tests__/ExpiryBanner.test.tsx` | Create | Component tests for the banner |
| `CasaPerks-Web-React/src/components/rewards/__tests__/RewardsList.test.tsx` | Modify | Tests for the Active/Expired split |
| `CasaPerks-API/tests/jobs/reward-expiry-notifier.test.ts` | Create | Cron job tests with mocked clock |

---

### Task 1: Create the feature flag

**Files:**
- Modify: paths under each repo's configured `registry-paths` in casaflow.config.md

- [ ] **Step 1: Run /casaflow:eng-flags**

`eng-flags` runs the full creation flow: bulk consent prompt covering all touched repos and PostHog environments, MCP creation per environment with retry-once and manual fallback, registry writes per touched repo. See `packs/engineering/skills/eng-flags/SKILL.md`.

Verification: registry entry exists in each touched repo with key `reward-expiry-warnings` and JSDoc; PostHog flag exists in every environment in `posthog-environments`.

- [ ] **Step 2: Commit**

eng-flags commits the registry writes itself with `feat(scope): add reward-expiry-warnings feature flag`. No manual commit step needed.

---

### Task 2: Shared `isExpiringSoon` helper

**Files:**
- Modify: `CasaPerks-Shared/rewards.ts`
- Test: `CasaPerks-Shared/tests/rewards.test.ts`

**Dependencies:** None (pure function, can run in parallel with Task 3 setup)

- [ ] **Step 1: Write the failing test**

```typescript
import { isExpiringSoon } from '../rewards';

describe('isExpiringSoon', () => {
  it('returns true when expires_at is within window', () => {
    const reward = { expires_at: '2026-06-01T00:00:00Z' };
    const now = new Date('2026-05-28T12:00:00Z');
    expect(isExpiringSoon(reward, 7, now)).toBe(true);
  });

  it('returns false when expires_at is outside window', () => {
    const reward = { expires_at: '2026-06-10T00:00:00Z' };
    const now = new Date('2026-05-28T12:00:00Z');
    expect(isExpiringSoon(reward, 7, now)).toBe(false);
  });

  it('returns false when reward is already expired', () => {
    const reward = { expires_at: '2026-05-20T00:00:00Z' };
    const now = new Date('2026-05-28T12:00:00Z');
    expect(isExpiringSoon(reward, 7, now)).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm --filter @casaperks/shared test rewards.test.ts`
Expected: FAIL with "isExpiringSoon is not a function"

- [ ] **Step 3: Write minimal implementation**

```typescript
export function isExpiringSoon(
  reward: { expires_at: string },
  withinDays: number,
  now: Date = new Date()
): boolean {
  const expiresAt = new Date(reward.expires_at);
  if (expiresAt.getTime() <= now.getTime()) return false;
  const windowEnd = new Date(now.getTime() + withinDays * 86_400_000);
  return expiresAt.getTime() <= windowEnd.getTime();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm --filter @casaperks/shared test rewards.test.ts`
Expected: PASS — 3 tests

- [ ] **Step 5: Commit**

```bash
git add CasaPerks-Shared/rewards.ts CasaPerks-Shared/tests/rewards.test.ts
git commit -m "feat(shared): add isExpiringSoon helper (CAS-1284)"
```

---

### Task 3: ExpiryBanner component

**Files:**
- Create: `CasaPerks-Web-React/src/components/rewards/ExpiryBanner.tsx`
- Test: `CasaPerks-Web-React/src/components/rewards/__tests__/ExpiryBanner.test.tsx`

**Dependencies:** Requires Task 1 (flag must exist), Task 2 (`isExpiringSoon`)

- [ ] **Step 1: Write the failing component test**

```tsx
import { render, screen } from '@testing-library/react';
import { ExpiryBanner } from '../ExpiryBanner';

describe('ExpiryBanner', () => {
  it('renders days remaining when reward is expiring soon', () => {
    render(<ExpiryBanner daysRemaining={6} />);
    expect(screen.getByText(/expires in 6 days/i)).toBeInTheDocument();
  });

  it('renders singular for one day', () => {
    render(<ExpiryBanner daysRemaining={1} />);
    expect(screen.getByText(/expires in 1 day/i)).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm --filter @casaperks/web test ExpiryBanner.test.tsx`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the component**

```tsx
import React from 'react';

interface ExpiryBannerProps {
  daysRemaining: number;
}

export function ExpiryBanner({ daysRemaining }: ExpiryBannerProps) {
  const noun = daysRemaining === 1 ? 'day' : 'days';
  return (
    <div role="alert" className="expiry-banner">
      Expires in {daysRemaining} {noun}
    </div>
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm --filter @casaperks/web test ExpiryBanner.test.tsx`
Expected: PASS — 2 tests

- [ ] **Step 5: Commit**

```bash
git add CasaPerks-Web-React/src/components/rewards/ExpiryBanner.tsx \
        CasaPerks-Web-React/src/components/rewards/__tests__/ExpiryBanner.test.tsx
git commit -m "feat(web): add ExpiryBanner component (CAS-1284)"
```

---

### Task 4: Split RewardsList into Active and Expired

**Files:**
- Modify: `CasaPerks-Web-React/src/components/rewards/RewardsList.tsx`
- Test: `CasaPerks-Web-React/src/components/rewards/__tests__/RewardsList.test.tsx`

**Dependencies:** Requires Task 3 (banner imported here)

- [ ] **Step 1: Write the failing test**

```tsx
import { render, screen } from '@testing-library/react';
import { RewardsList } from '../RewardsList';

const rewards = [
  { id: 1, name: 'A', expires_at: '2026-06-01T00:00:00Z' },
  { id: 2, name: 'B', expires_at: '2026-05-01T00:00:00Z' }, // already expired
];

it('renders expired rewards in collapsed Expired section', () => {
  render(<RewardsList rewards={rewards} flagEnabled now={new Date('2026-05-28')} />);
  expect(screen.getByText('A')).toBeInTheDocument();
  const expiredSection = screen.getByRole('region', { name: /expired/i });
  expect(expiredSection).toHaveAttribute('data-collapsed', 'true');
  expect(screen.queryByText('B')).not.toBeVisible();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm --filter @casaperks/web test RewardsList.test.tsx`
Expected: FAIL — no Expired section yet.

- [ ] **Step 3: Implement the split**

```tsx
import { isExpiringSoon } from '@casaperks/shared/rewards';
import { ExpiryBanner } from './ExpiryBanner';

interface Reward { id: number; name: string; expires_at: string; }

export function RewardsList({ rewards, flagEnabled, now = new Date() }: {
  rewards: Reward[]; flagEnabled: boolean; now?: Date;
}) {
  if (!flagEnabled) {
    return <ul>{rewards.map(r => <li key={r.id}>{r.name}</li>)}</ul>;
  }
  const active = rewards.filter(r => new Date(r.expires_at) > now);
  const expired = rewards.filter(r => new Date(r.expires_at) <= now);

  return (
    <>
      <ul>
        {active.map(r => (
          <li key={r.id}>
            {r.name}
            {isExpiringSoon(r, 7, now) && (
              <ExpiryBanner daysRemaining={Math.ceil(
                (new Date(r.expires_at).getTime() - now.getTime()) / 86_400_000
              )} />
            )}
          </li>
        ))}
      </ul>
      {expired.length > 0 && (
        <section role="region" aria-label="Expired" data-collapsed="true" hidden>
          {expired.map(r => <div key={r.id}>{r.name}</div>)}
        </section>
      )}
    </>
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm --filter @casaperks/web test RewardsList.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CasaPerks-Web-React/src/components/rewards/RewardsList.tsx \
        CasaPerks-Web-React/src/components/rewards/__tests__/RewardsList.test.tsx
git commit -m "feat(web): split rewards list into Active and Expired sections (CAS-1284)"
```

---

### Task 5: Daily cron — reward expiry notifier

**Files:**
- Create: `CasaPerks-API/jobs/reward-expiry-notifier.ts`
- Test: `CasaPerks-API/tests/jobs/reward-expiry-notifier.test.ts`

**Dependencies:** Requires Task 1 (flag), Task 2 (`isExpiringSoon`)

- [ ] **Step 1: Write the failing test**

```typescript
import { runExpiryNotifier } from '../../jobs/reward-expiry-notifier';
import { mockDb, mockNotifier } from '../helpers';

describe('runExpiryNotifier', () => {
  it('queues a push for users with rewards expiring in exactly 3 days', async () => {
    mockDb.rewards = [
      { user_id: 1, expires_at: '2026-05-31T00:00:00Z' }, // 3 days out from 2026-05-28
    ];
    await runExpiryNotifier({ now: new Date('2026-05-28T00:00:00Z') });
    expect(mockNotifier.queued).toHaveLength(1);
    expect(mockNotifier.queued[0].userId).toBe(1);
  });

  it('does not double-send on second run same day', async () => {
    mockDb.rewards = [{ user_id: 1, expires_at: '2026-05-31T00:00:00Z' }];
    await runExpiryNotifier({ now: new Date('2026-05-28T00:00:00Z') });
    await runExpiryNotifier({ now: new Date('2026-05-28T06:00:00Z') });
    expect(mockNotifier.queued).toHaveLength(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm --filter @casaperks/api test reward-expiry-notifier.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the cron**

```typescript
import { db } from '../db';
import { notifier } from '../services/notifier';
import { rewardExpiryWarningsEnabled } from '../flags';

export async function runExpiryNotifier({ now = new Date() } = {}) {
  if (!(await rewardExpiryWarningsEnabled())) return;
  const threeDaysOut = new Date(now.getTime() + 3 * 86_400_000);
  const rewards = await db.rewards.expiringOn(threeDaysOut);
  const sentToday = new Set(await db.notifierLog.todayUserIds(now));
  for (const r of rewards) {
    if (sentToday.has(r.user_id)) continue;
    await notifier.queue({
      userId: r.user_id,
      template: 'reward-expiry-3day',
      payload: { rewardId: r.id },
    });
    await db.notifierLog.record(r.user_id, now);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm --filter @casaperks/api test reward-expiry-notifier.test.ts`
Expected: PASS — 2 tests

- [ ] **Step 5: Commit**

```bash
git add CasaPerks-API/jobs/reward-expiry-notifier.ts \
        CasaPerks-API/tests/jobs/reward-expiry-notifier.test.ts
git commit -m "feat(api): add daily expiry-notifier cron (CAS-1284)"
```

---

### Task 6: Wire cron into job scheduler

**Files:**
- Modify: `CasaPerks-API/jobs/index.ts`

**Dependencies:** Requires Task 5

- [ ] **Step 1: Register the job**

```typescript
import { runExpiryNotifier } from './reward-expiry-notifier';

schedule.daily('reward-expiry-notifier', runExpiryNotifier);
```

- [ ] **Step 2: Verify registration**

Run: `pnpm --filter @casaperks/api jobs:list`
Expected output includes `reward-expiry-notifier (daily)`.

- [ ] **Step 3: Commit**

```bash
git add CasaPerks-API/jobs/index.ts
git commit -m "feat(api): schedule reward-expiry-notifier daily (CAS-1284)"
```
