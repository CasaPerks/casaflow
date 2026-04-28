#!/usr/bin/env bash
# Asserts that consumer skills which gate on the spec branch on flag.decision
# in the spec frontmatter. pr-create is excluded from this check by design —
# at PR creation time, flag detection comes from the registry-path diff, not
# from the spec (the spec may not even live in the branch).
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

# Spec-driven consumers — must mention frontmatter and flag.decision.
for f in core/skills/plan/SKILL.md \
         core/skills/verify/SKILL.md \
         team/skills/retro/SKILL.md; do
  full="$repo_root/$f"
  grep -qi "frontmatter" "$full" || { echo "$f: missing frontmatter mention"; fail=1; }
  grep -q "flag.decision" "$full" || { echo "$f: missing flag.decision branch"; fail=1; }
done

# spec is the writer — must define the schema.
grep -q "flag:" "$repo_root/team/skills/spec/SKILL.md" || { echo "spec: missing flag schema"; fail=1; }

# pr-create — diff-based detection, not frontmatter. Must reference the
# CAS-577 registry convention regex and the diff scan.
prcreate="$repo_root/core/skills/pr-create/SKILL.md"
grep -qi "feature-flags" "$prcreate" || { echo "pr-create: missing feature-flags convention reference (diff-based detection)"; fail=1; }
grep -qi "git diff" "$prcreate" || { echo "pr-create: missing git diff reference (diff-based detection)"; fail=1; }

exit "$fail"
