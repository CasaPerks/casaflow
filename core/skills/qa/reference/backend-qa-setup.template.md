---
# Backend QA Environment — TEMPLATE
#
# Copy this file to your casavault ROOT (NOT a feature folder):
#   ~/Documents/<project-name>/Backend-QA-setup.md
#
# It captures, once, the two capabilities a backend live check needs (Step 2.5
# of the /casaflow:qa skill): how to MINT A TOKEN and how to REACH THE DATA
# LAYER in a test env — plus the project's backend gotchas. Filling it in once
# turns every future backend QA from a rediscovery into a 2-minute job.
#
# SECURITY:
# - Real tokens, passwords, AWS keys, and connection strings are read at RUNTIME
#   from gitignored env files — do NOT paste secret VALUES here. Record the
#   COMMAND / env-var name / file path that produces them, not the secret.
# - This doc lives in the vault. Never commit it to a repo, paste it into a
#   ticket/PR, or write a token into qa.md (refer to accounts by `role` label).
schema: backend-qa/v1
environment: dev              # dev | staging — which env these instructions target
api_base_url: https://<dev-api-host>/api
---

# Backend QA on <env> — setup & runbook

Backend QA needs two capabilities. Record exactly how this project provides each.

## 1. Auth — mint a bearer token

> Many backends validate the **ACCESS** token, not the ID token. Confirm which,
> and record the exact command. Credentials come from a gitignored env file.

- **Token type the backend validates:** `access` | `id`  ← fill in
- **How to mint:** `<command>`  e.g. a project script, an auth-flow call, or a
  client that allows username/password auth.
  ```
  # example shape — replace with the real command:
  # TOKEN=$(node scripts/qa-actions/mint-token.mjs --role <role> 2>/dev/null)
  ```
- **Roles available + where creds live:** `<env file / registry>`
- **Gotcha — env-loader banners:** some loaders (e.g. `dotenv` v17+) print a
  banner to **stdout**, which corrupts a captured token. Use quiet mode / capture
  only the token line.

## 2. Data access — arrange & verify state

> First ask: can the **API itself** set up the precondition and report the
> result? If the endpoint's response already proves the AC, you may not need
> direct DB access at all. Only reach for the DB when the response can't confirm
> persistence.

- **Preferred: via API** — endpoints to arrange/inspect state: `<list>`
- **If the test DB is network-isolated** (PrivateLink / private subnet), record
  the access path — tunnel, VPN, or bastion:
  ```
  # example shape — replace with the real command:
  # ./scripts/qa-actions/qa-tunnel.sh   # SSM port-forward → localhost:<port>
  # then connect with directConnection if it's a single-member forward
  ```
- **DB name / cluster for <env>:** `<name>`
- **Seed/cleanup helper (if any):** `<command>` — and always **re-verify cleanup**.

## 3. Invocation-contract notes (per endpoint, as you learn them)

For each endpoint QA'd, jot how to call it so the next person doesn't re-read the
controller: path, auth, and **where each required param is read from**
(query / header / path / body).

| endpoint | auth | required params (and source) | notes |
|----------|------|------------------------------|-------|
| `POST /api/<…>` | access token, role `<…>` | `<param>` (query), `<param>` (header) | |

## 4. Project gotchas

- Edge vs app errors: an HTML 4xx = the proxy (nginx/ALB), not the app.
- Param source surprises (header vs query vs path) → misleading "not found".
- Per-record feature gates that 4xx the call (e.g. a channel disabled on an
  entity) — list known-good test fixtures here.
- Anything else that cost time once — write it down so it costs nobody time twice.

## 5. Known-good fixtures

Persistent test accounts / entities in known states, so most QA is
mint → call → assert with no per-run seeding.

| fixture | id / identifier | state | use for |
|---------|-----------------|-------|---------|
| `<role/entity>` | `<id>` | `<known state>` | `<which AC>` |
