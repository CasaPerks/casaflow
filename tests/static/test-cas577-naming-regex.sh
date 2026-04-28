#!/usr/bin/env bash
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
file="$repo_root/packs/engineering/skills/eng-flags/SKILL.md"
fail=0

grep -q '^- \*\*Kill switch:\*\* `\*-enabled`' "$file" || { echo "missing kill-switch convention"; fail=1; }
grep -q '^- \*\*Adoption gate:\*\* `\*-rollout`' "$file" || { echo "missing adoption-gate convention"; fail=1; }
grep -qE 'kebab-case' "$file" || { echo "missing kebab-case mention"; fail=1; }
grep -q '@owner' "$file" || { echo "missing @owner JSDoc field"; fail=1; }
grep -q '@expected_sunset' "$file" || { echo "missing @expected_sunset JSDoc field"; fail=1; }

regex='^[a-z][a-z0-9-]*-(enabled|rollout)$'
echo "redemption-flow-rollout" | grep -qE "$regex" || { echo "regex rejects valid key"; fail=1; }
echo "payouts-enabled" | grep -qE "$regex" || { echo "regex rejects valid kill-switch"; fail=1; }
echo "redemption_flow_rollout" | grep -qE "$regex" && { echo "regex accepts underscores"; fail=1; }
echo "RedemptionFlow-rollout" | grep -qE "$regex" && { echo "regex accepts uppercase"; fail=1; }
echo "redemption-flow" | grep -qE "$regex" && { echo "regex accepts missing suffix"; fail=1; }

grep -qF "$regex" "$file" || { echo "skill body must embed the canonical regex"; fail=1; }

exit "$fail"
