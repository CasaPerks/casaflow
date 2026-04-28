#!/usr/bin/env bash
# Asserts the registry-detection regex in pr-create's Step 1.5 matches the
# CAS-577 convention and rejects unrelated paths.
set -u
fail=0

# The regex from pr-create's Step 1.5
regex='(^|/)feature-flags\.(ts|tsx|js|jsx|py|rb|go)$'

# Should match
for valid in \
  "src/services/posthog/feature-flags.ts" \
  "feature-flags.ts" \
  "apps/web/src/feature-flags.tsx" \
  "lib/feature-flags.py" \
  "feature-flags.go"; do
  echo "$valid" | grep -qE "$regex" || { echo "regex rejects valid path: $valid"; fail=1; }
done

# Should NOT match
for invalid in \
  "feature-flags.md" \
  "feature-flags-helper.ts" \
  "src/feature-flags-fixtures/spec-flag-yes.md" \
  "feature_flags.ts" \
  "FeatureFlags.ts"; do
  echo "$invalid" | grep -qE "$regex" && { echo "regex accepts invalid path: $invalid"; fail=1; }
done

# The pr-create skill must embed this regex literally
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
grep -qF "$regex" "$repo_root/core/skills/pr-create/SKILL.md" || { echo "pr-create SKILL.md must embed the canonical regex literally"; fail=1; }

exit "$fail"
