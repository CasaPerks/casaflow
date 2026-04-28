---
description: Use when creating, modifying, or sunsetting a feature flag in CasaPerks code. Drives flag setup as an atomic transaction across PostHog and per-repo registries.
---

Invoke the `eng-flags` skill from `packs/engineering/skills/eng-flags/SKILL.md`. Read its full content and follow it verbatim. eng-flags is invoked automatically from `/casaflow:plan`-generated tasks during `/casaflow:build`, but can also be invoked directly for exploratory flag work.
