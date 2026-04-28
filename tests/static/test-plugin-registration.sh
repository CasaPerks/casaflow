#!/usr/bin/env bash
set -u
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
grep -q '"./packs/engineering/skills/eng-flags"' "$repo_root/.claude-plugin/plugin.json"
