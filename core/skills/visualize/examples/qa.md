---
ticket: CAS-1407
ticket_url: https://casaperks.atlassian.net/browse/CAS-1407
pr_url: https://github.com/casaperks/CasaPerks-Web-React/pull/3204
branch: jdoe/jig-1407-rent-split
spec_path: ~/Documents/casaflow/rent-split/spec.md
shipped_path: ~/Documents/casaflow/rent-split/shipped.md
reviewer: zak.debrine@casaperks.com
qa_date: 2026-05-28
result: pending
automated: { total: 4, passed: 3, failed: 1, flaky: 0 }
manual: { total: 4, pass: 0, fail: 0, blocked: 0 }
spawned_tickets: []
---

# QA: Rent Split

## What changed
Residents can now split a rent charge across multiple roommates from the
charge detail screen. The PR adds a split editor, a per-roommate share
calculation, and a server-side validation that the shares sum to 100%.
The spec capped a single resident's share at 90% (so no one is on the hook
for the whole charge alone) — the **shipped.md divergence log flags that the
cap moved to a server-side check late in the build**, so the cap is the
highest-risk area to verify.

## Check matrix
- **QA-1** — Resident opens a charge and sees the "Split" action. · src: AC-1 · frontend · automatable · casaperks-resident · normal
- **QA-2** — Adding two roommates splits the charge evenly by default. · src: AC-2 · frontend · automatable · casaperks-resident · normal
- **QA-3** — Shares that don't sum to 100% are rejected with an inline error. · src: AC-3 + diff · frontend · automatable · casaperks-resident · normal
- **QA-4** — `POST /charges/:id/split` rejects a single share over 90% (server-side cap). · src: divergence #2 · backend · automatable · casaperks-resident · high
- **QA-5** — Split editor matches the design spec on mobile widths. · src: AC-4 · frontend · manual · casaperks-resident · normal
- **QA-6** — Property manager viewing the charge sees the split breakdown read-only. · src: AC-5 · frontend · manual · casaperks-property-manager · normal
- **QA-7** — Email notification to each roommate renders correctly in a real inbox. · src: diff (new emailer) · frontend · manual · casaperks-resident · normal
- **QA-8** — `GET /charges/:id/split` reflects the persisted split after a reconciliation job runs. · src: diff (new job) · backend · manual · casaperks-resident · normal

## Automated results
- **QA-1** (frontend) pass · 2.1s · trace: traces/QA-1.zip · spec: e2e/__casaflow_qa__/rent-split/QA-1.spec.ts
- **QA-2** (frontend) pass · 3.4s · trace: traces/QA-2.zip · spec: e2e/__casaflow_qa__/rent-split/QA-2.spec.ts
- **QA-3** (frontend) pass · 2.8s · trace: traces/QA-3.zip · spec: e2e/__casaflow_qa__/rent-split/QA-3.spec.ts
- **QA-4** (backend, APIRequestContext) fail · 1.9s · endpoint: `POST /charges/:id/split` · spec: e2e/__casaflow_qa__/rent-split/QA-4.spec.ts — token minted as casaperks-resident; server returned 200 for a 95% share. The cap is only enforced on the client.

## Manual checks
- **QA-5** (frontend) — On a 375px viewport, open a charge → Split. Expected: editor fits without horizontal scroll, roommate rows stack. Account: casaperks-resident.
- **QA-6** (frontend) — As a property manager, open the same charge. Expected: split breakdown visible, no edit controls. Account: casaperks-property-manager.
- **QA-7** (frontend) — Trigger a split, check the roommate's inbox. Expected: email shows each share amount and a working "view charge" link. Account: casaperks-resident.
- **QA-8** (backend API) — `GET /charges/:id/split` after the nightly reconciliation job. Couldn't be automated — the job only runs on a cron in staging. Run by hand:
  - Request: `GET {{baseUrl}}/charges/8842/split` · Header: `Authorization: Bearer {{token}}` (mint as casaperks-resident)
  - Expected: `200` with `shares` summing to `10000` (cents) and `status: "reconciled"`.
  - Account: casaperks-resident.

## Sign-off
Pending reviewer sign-off.

## Promoted specs
None yet.
