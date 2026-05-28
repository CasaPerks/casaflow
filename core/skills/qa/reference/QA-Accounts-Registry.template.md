---
# QA Accounts Registry — TEMPLATE
#
# Copy this file to your casavault ROOT (NOT a feature folder):
#   ~/Documents/<project-name>/QA-Accounts-Registry.md
#
# It lists provisioned TEST accounts for every CasaPerks and WorkPerks user
# type. The /casaflow:qa skill reads it to log generated Playwright flows in
# as the right user type.
#
# SECURITY:
# - These are throwaway QA/staging accounts ONLY. Never put real customer or
#   production credentials here.
# - This file lives in the casavault and must NEVER be committed to any repo,
#   pasted into a ticket/PR comment, or written into a generated test spec.
#   The qa skill injects credentials via env vars / the auth fixture at
#   runtime and refers to accounts by `role` label only in all artifacts.
# - Keep it out of any synced/shared location your team hasn't approved for
#   credentials.
schema: qa-accounts/v1
environment: staging          # staging | qa | local — which env these accounts live in
base_urls:
  casaperks: https://staging.casaperks.com
  workperks: https://staging.workperks.com
---

# QA Accounts Registry

Provisioned test accounts, indexed by `product` and `role`. The `role` value
is the label the qa skill uses everywhere (matrix, qa.md, comments) — it is
safe to expose. The `email` / `password` are used only at test runtime.

## CasaPerks

| role | email | password | notes |
|------|-------|----------|-------|
| casaperks-resident | resident.qa@example.test | ▢▢▢▢ | standard tenant/resident account |
| casaperks-property-manager | pm.qa@example.test | ▢▢▢▢ | manages one or more properties |
| casaperks-owner | owner.qa@example.test | ▢▢▢▢ | property owner / landlord |
| casaperks-admin | admin.qa@example.test | ▢▢▢▢ | internal CasaPerks admin/back-office |
| casaperks-new-user | newuser.qa@example.test | ▢▢▢▢ | freshly registered, empty state |

## WorkPerks

| role | email | password | notes |
|------|-------|----------|-------|
| workperks-employee | employee.qa@example.test | ▢▢▢▢ | standard employee/member account |
| workperks-manager | manager.qa@example.test | ▢▢▢▢ | team manager |
| workperks-hr-admin | hradmin.qa@example.test | ▢▢▢▢ | HR / company admin |
| workperks-vendor | vendor.qa@example.test | ▢▢▢▢ | benefits/perks vendor account |

## How to use

1. Replace every `▢▢▢▢` with the real staging password (or remove the row if
   that user type isn't provisioned yet).
2. Add or rename rows to match the actual user types in your environment —
   the qa skill matches on the `role` label, so keep labels stable.
3. If a check needs a user type that isn't listed, the qa skill will mark
   that check `manual` and tell you which role is missing.
