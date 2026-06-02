---
description: "Reviewer-triggered QA pass that verifies a code-reviewed, merged change works as expected. Runs the feature's existing tests, generates and runs Playwright e2e for the acceptance criteria if none exist, and writes a pass/fail qa.md. QAs subtasks one at a time, offers an opt-in qa.html, and lists any manual checks. On a PASS against a ticket, offers (opt-in) to post the QA summary as a ticket comment and move it to the team's ready-for-release status. Pass a ticket ID, PR URL, or branch name."
---

Use the `casaflow:qa` skill to handle this request.
