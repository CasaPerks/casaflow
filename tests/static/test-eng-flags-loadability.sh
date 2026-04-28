#!/usr/bin/env bash
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
file="$repo_root/packs/engineering/skills/eng-flags/SKILL.md"
fail=0

[ -f "$file" ] || { echo "$file does not exist"; exit 1; }

grep -q "^name: eng-flags$" "$file" || { echo "missing 'name: eng-flags'"; fail=1; }
grep -q "^description: " "$file" || { echo "missing description"; fail=1; }
grep -q "^description: Use when" "$file" || { echo "description must start with 'Use when'"; fail=1; }
grep -q "^tier: " "$file" || { echo "missing tier"; fail=1; }
grep -q "^alwaysApply: " "$file" || { echo "missing alwaysApply"; fail=1; }

grep -q "^## When to Use" "$file" || { echo "missing '## When to Use'"; fail=1; }
grep -q "^## Naming Conventions" "$file" || { echo "missing '## Naming Conventions'"; fail=1; }
grep -q "^## Lifecycle" "$file" || { echo "missing '## Lifecycle'"; fail=1; }
grep -q "^## Repo Discovery" "$file" || { echo "missing '## Repo Discovery'"; fail=1; }
grep -q "^## Creation Flow" "$file" || { echo "missing '## Creation Flow'"; fail=1; }
grep -q "^## Validation" "$file" || { echo "missing '## Validation'"; fail=1; }

lines=$(wc -l < "$file")
[ "$lines" -le 500 ] || { echo "SKILL.md exceeds 500 lines ($lines)"; fail=1; }

exit "$fail"
