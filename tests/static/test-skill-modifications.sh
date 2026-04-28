#!/usr/bin/env bash
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

spec="$repo_root/team/skills/spec/SKILL.md"
grep -q "^### 6\. Feature Flag Decision" "$spec" || { echo "spec: missing '### 6. Feature Flag Decision'"; fail=1; }
grep -q "^flag:" "$spec" || { echo "spec: missing flag frontmatter contract"; fail=1; }
grep -qi "yaml frontmatter" "$spec" || { echo "spec: missing 'yaml frontmatter' guidance"; fail=1; }

plan="$repo_root/core/skills/plan/SKILL.md"
grep -q "Feature Flag Tasks" "$plan" || { echo "plan: missing 'Feature Flag Tasks' subsection"; fail=1; }
grep -q "/casaflow:eng-flags" "$plan" || { echo "plan: missing /casaflow:eng-flags reference"; fail=1; }
grep -q "flag.decision" "$plan" || { echo "plan: missing flag.decision branch"; fail=1; }

verify="$repo_root/core/skills/verify/SKILL.md"
grep -q "feature_flag_called" "$verify" || { echo "verify: missing feature_flag_called event check"; fail=1; }
grep -qi "flag ON" "$verify" || { echo "verify: missing flag ON evidence"; fail=1; }
grep -qi "flag OFF" "$verify" || { echo "verify: missing flag OFF evidence"; fail=1; }

prcreate="$repo_root/core/skills/pr-create/SKILL.md"
grep -q "## Flags" "$prcreate" || { echo "pr-create: missing '## Flags' section guidance"; fail=1; }
grep -qi "registry" "$prcreate" || { echo "pr-create: missing registry-diff detection"; fail=1; }

retro="$repo_root/team/skills/retro/SKILL.md"
grep -q "Flag-specific questions" "$retro" || { echo "retro: missing 'Flag-specific questions' subsection"; fail=1; }
grep -qi "rollout" "$retro" || { echo "retro: missing rollout question"; fail=1; }
grep -qi "sunset" "$retro" || { echo "retro: missing sunset question"; fail=1; }
grep -qi "close" "$retro" || { echo "retro: missing close-out question"; fail=1; }

exit "$fail"
