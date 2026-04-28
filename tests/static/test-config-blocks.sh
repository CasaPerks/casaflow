#!/usr/bin/env bash
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
config="$repo_root/scaffold/casaflow.config.md"
fail=0
grep -q "^## Feature Flags" "$config" || { echo "missing '## Feature Flags' section"; fail=1; }
grep -q "^## Repos" "$config" || { echo "missing '## Repos' section"; fail=1; }
grep -q "registry-paths:" "$config" || { echo "missing 'registry-paths:' key"; fail=1; }
grep -q "posthog-environments:" "$config" || { echo "missing 'posthog-environments:' key"; fail=1; }
grep -q "in-scope-for-flags:" "$config" || { echo "missing 'in-scope-for-flags:' key"; fail=1; }
exit "$fail"
