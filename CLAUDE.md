# CasaFlow (built on Jig)

CasaFlow is the CasaPerks AI engineering workflow — spec-first,
comprehension-gated, and Jira-native. It is built on the Jig framework and
customized for CasaPerks engineering culture.

**Four priorities**: Speed · Dev comprehension · Code robustness · Developer
education

CasaPerks overrides live in `team/`. The Jig core is untouched in `core/`.
This repo uses itself to develop itself (Consumer Zero).

## Core Philosophy

1. **Convention over configuration.** Jig has opinions. Teams override what they need; everything else just works.
2. **The framework is the nervous system, team skills are organs.** Jig discovers, loads, and orchestrates team-created skills. They're part of the system, not separate from it.
3. **Full lifecycle.** Ticket to post-mortem. Every stage has a skill, every handoff has a quality gate.
4. **Language-agnostic core.** The pipeline works for any stack. Stack-specific expertise comes from team skills and starter packs.

## Architecture

Jig has three discovery layers, in priority order:

```
1. team/           <- Highest priority (team overrides)
2. packs/          <- Pack defaults (starter kits)
3. core/           <- Framework defaults
```

If a team skill has the same name as a core skill, the team version wins. This is how teams customize without editing framework files.

### The Pipeline

Every development task flows through stages. `kickoff` orchestrates the full pipeline:

```
DISCOVER → BRAINSTORM → PLAN → EXECUTE → REVIEW → SHIP → LEARN
```

Work type (bug/feature/improvement/task) determines which stages run and at what depth. Configured in `casaflow.config.md`.

### How Skills Compose

- **Direct invocation** — workflow skills invoke each other by name (`kickoff` → `brainstorm` → `plan`)
- **Concerns checklist** — `casaflow.config.md` maps engineering concerns to skills. `brainstorm` reads the config and loads relevant skills during design.
- **Specialist dispatch** — `review` discovers specialist `.md` files from all three directories, filters by glob match, and dispatches as parallel subagents.

## Inventory

### CasaFlow Team Skills (6) — `team/skills/`

These override or extend the Jig core for CasaPerks.

| Skill | Overrides | Purpose |
|-------|-----------|---------|
| `kickoff` | `core/skills/kickoff` | Adds spec-first gate for features/improvements |
| `spec` | *(new)* | Guides developer through writing a feature spec before code |
| `approve-gate` | *(new)* | Stage report + 3 comprehension questions after each build stage |
| `explain` | *(new)* | 5-section education explanation: approach, failure modes, change surface, tests, refactor |
| `review-tests` | *(new)* | 4-phase test audit: coverage, mutation testing, rubric, letter grade |
| `retro` | *(new)* | Post-feature retrospective with pattern detection across retros |

### Jira Pack — `packs/jira/`

| Skill | Purpose |
|-------|---------|
| `jira-sync` | 7-step spec-to-Jira sync; stage status updates; PR URL comments |

### Core Skills (16)

| Skill | Purpose |
|-------|---------|
| `kickoff` | Pipeline orchestrator — classifies work, routes through stages |
| `brainstorm` | Collaborative design exploration with configurable concerns checklist |
| `prd` | PRD creation with enforceable acceptance checklists (feeds into spec reviewer) |
| `plan` | Spec → implementation plan with bite-sized TDD tasks |
| `build` | Plan execution — analyzes task graph, auto-selects parallel or serial |
| `team-dev` | Parallel agent execution with staggered quality gates (called by `build`) |
| `sdd` | Serial execution with two-stage review per task |
| `review` | Specialist swarm — dispatches parallel reviewers, scores findings |
| `pr-create` | PR creation with voice/tone standards and test plan |
| `pr-respond` | PR comment response — analyze, fix, commit, push, reply, resolve |
| `postmortem` | Post-merge retrospective with specialist/logic reviewer diagnosis |
| `debug` | Systematic debugging — root cause before fixes, always |
| `verify` | Evidence before assertions — run it before claiming it works |
| `tdd` | Red-green-refactor discipline |
| `finish` | Branch completion — merge, PR, keep, or discard |
| `extend` | Framework extension assistant — scaffolds new skills, specialists, packs |

### Core Agents (3)

| Agent | Purpose |
|-------|---------|
| `commit` | Conventional commits with hook awareness |
| `code-review` | Dispatches review swarm, delivers scored report |
| `pr-review` | Posts inline PR comments with suggestion blocks |

### Core Specialists (5)

`security`, `dead-code`, `error-handling`, `async-safety`, `performance` — language-agnostic code review specialists dispatched by `review`.

### Engineering Pack

`eng-copywriting` (sentence case standards), `eng-logging` (level guidance), `eng-testing` (test strategy), `test-coverage` (specialist).

## Self-Hosting Model

Jig eats its own dogfood. This repo installs itself as a plugin via `.claude/settings.json` — the same way any consumer project would. Skills, agents, and commands all come from the plugin. No symlinks, no special treatment.

When developing Jig, edit the source in `core/`. After pushing to GitHub, run `/plugin marketplace update duronext-jig` and `/reload-plugins` to see changes locally.

**When adding a new core skill:**
1. Create `core/skills/{name}/SKILL.md`
2. Add to the `skills` array in `.claude-plugin/plugin.json`
3. Add a command file in `commands/{name}.md` for `/casaflow:` namespace browsing

## Project Structure

```
jig/
├── framework/           How Jig works (pipeline, schema, tiers, discovery, checklist, git host adapters)
├── core/
│   ├── skills/          15 pipeline skills
│   ├── agents/          3 agents (commit, code-review, pr-review)
│   └── specialists/     5 review specialists
├── packs/
│   └── engineering/     Starter pack (3 skills + 1 specialist)
├── adapters/            Platform integration (claude/, gemini/, codex/)
├── scaffold/            jig init templates (config, team dir, skill template)
├── docs/                Specs and documentation
├── team/                Jig's own extensions (for developing Jig itself)
├── .claude/             Plugin self-install (settings.json)
├── CLAUDE.md            This file
├── scaffold/casaflow.config.md  CasaFlow pipeline configuration template
└── README.md            Public-facing README
```

## Commands

| Task | Command |
|------|---------|
| List all skills | `find core/skills -name "SKILL.md" \| sort` |
| List specialists | `ls core/specialists/` |
| List agents | `ls core/agents/` |
| Verify plugin | `cat .claude/settings.json` |
| Check for stale refs | `grep -rn 'superpowers:' core/` (should return nothing) |
| Count lines | `find . -not -path './.git/*' -name '*.md' \| xargs wc -l \| tail -1` |

## Code Style

- Markdown: 80 char line width where practical
- YAML frontmatter: 2 space indent
- Skill names: lowercase with hyphens (`eng-` prefix for engineering pack, no prefix for core)
- Descriptions: MUST start with "Use when..."
- SKILL.md: under 500 lines. Heavy content goes in `reference/` subdirectory.
- No language-specific references in core skills (TypeScript, Python, etc.) — core is stack-agnostic

## Commit Conventions

- Conventional commits: `type(scope): message`
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- Scopes: `core`, `framework`, `packs`, `adapters`, `scaffold`, `docs`, `agents`, `specialists`
- **Never commit or push without explicit user approval**
- Use the commit agent at `.claude/agents/commit.md`

## Contributing to Jig

### Modifying an existing skill
1. Edit the source at `core/skills/{name}/SKILL.md`
2. Validate: frontmatter has `name`, `description` (starts with "Use when..."), `tier`, `alwaysApply`
3. Check cross-references: `grep -rn '{skill-name}' core/` — update any references if you renamed or split
4. Verify no language-specific content leaked into core skills

### Adding a new core skill
1. Read `framework/SKILL_SCHEMA.md` for the frontmatter spec
2. Read `framework/TIER_SYSTEM.md` to choose the right tier
3. Create `core/skills/{name}/SKILL.md`
4. Create symlink: `ln -s ../../core/skills/{name} .claude/skills/{name}`
5. Add to the `skills` array in `.claude-plugin/plugin.json`
6. If the skill should surface during brainstorming, add it to the concerns checklist in `casaflow.config.md`

### How consumers install Jig
Teams add this to their project's `.claude/settings.json`:
```json
{
  "enabledPlugins": { "jig@duronext-jig": true },
  "extraKnownMarketplaces": {
    "duronext-jig": {
      "source": { "source": "github", "repo": "duronext/jig" }
    }
  }
}
```
This gives every teammate on the project the full Jig framework on clone — no manual marketplace add or plugin install needed.

### Adding a specialist
1. Create `core/specialists/{name}.md` with frontmatter: `name`, `description`, `model`, `tier`, `globs`, `severity`
2. The body below the frontmatter IS the specialist's prompt
3. `review` discovers it automatically — no config needed

### Key documents to read first
- `framework/GIT_HOST.md` — git host adapter (GitHub/GitLab/Bitbucket command mapping)
- `framework/PIPELINE.md` — the 7-stage development pipeline
- `framework/DISCOVERY.md` — how Jig finds and loads skills
- `framework/SKILL_SCHEMA.md` — frontmatter spec for all skills
- `docs/specs/2026-03-28-jig-framework-design.md` — the original design spec

## Command Adherence — MANDATORY

When the user runs ANY `/casaflow:` command, Claude MUST follow the
instructions in the corresponding command file exactly. Never improvise,
freestyle, or invent a workflow. If a command file references another skill,
load and follow that skill's SKILL.md verbatim.

**If you cannot load the command's instructions, tell the user:**
> "I can't load the full instructions for this command. Try running it again."

### Critical Command Contracts

| Command | Source | Non-Negotiable Requirements |
|---------|--------|-----------------------------|
| `/casaflow:spec` | `commands/spec.md` | 6 sections (summary, criteria, non-goals, test spec, architecture, open questions). Claude proposes test paths (happy, failure, false positive) for dev review. Mandatory comprehension check before handoff. Saves to `~/Documents/<project-name>/<feature-slug>/spec.md`. Hands off to `/kickoff`. |
| `/casaflow:kickoff` | `commands/kickoff.md` | Classify work type first. Spec gate for features/improvements (hard stop if no spec). 9-stage pipeline: classify → spec gate → discover → brainstorm → plan → execute → review → ship → learn. Reads `casaflow.config.md`. |
| `/casaflow:build` | `commands/build.md` | Find plan → analyze task graph → choose strategy (team-dev/sdd/direct) → execute → verify → finish. Never skip the strategy analysis. Announce the decision before executing. |
| `/casaflow:review` | `commands/review.md` | 7-stage swarm pipeline: discover specialists → prepare diff → dispatch parallel → collect → deep review (pre-PR only) → score mechanically → report. All specialists dispatched in parallel. Score is mechanical — no exceptions. |
| `/casaflow:brainstorm` | `core/skills/brainstorm/SKILL.md` | Hard gate: no code until design approved. Run concerns checklist from config. Save design doc. |
| `/casaflow:plan` | `core/skills/plan/SKILL.md` | Spec → implementation plan. Tasks scoped 2-5 min. File paths per task. Dependencies. Verification steps. Save to `~/Documents/<project-name>/<feature-slug>/plan.md`. |
| `/casaflow:approve` | `team/skills/approve-gate/SKILL.md` | Stage report + 3 comprehension questions (structural, failure mode, change impact). Not optional. |
| `/casaflow:explain` | `team/skills/explain/SKILL.md` | 5-section explanation: approach, failure modes, change surface, tests, refactor. |
| `/casaflow:review-tests` | `team/skills/review-tests/SKILL.md` | 4-phase test audit: coverage, mutation testing, rubric, letter grade. |
| `/casaflow:retro` | `team/skills/retro/SKILL.md` | Post-feature retrospective with pattern detection across retros. |
| `/casaflow:debug` | `core/skills/debug/SKILL.md` | Root cause before fixes, always. |
| `/casaflow:verify` | `core/skills/verify/SKILL.md` | Evidence before assertions — run it before claiming it works. |
| `/casaflow:tdd` | `core/skills/tdd/SKILL.md` | Red-green-refactor discipline. |
| `/casaflow:pr-create` | `core/skills/pr-create/SKILL.md` | Voice/tone standards. Test plan required. |
| `/casaflow:pr-respond` | `core/skills/pr-respond/SKILL.md` | Analyze, fix, commit, push, reply, resolve. |
| `/casaflow:finish` | `core/skills/finish/SKILL.md` | Branch completion — merge, PR, keep, or discard. |
| `/casaflow:prd` | `core/skills/prd/SKILL.md` | PRD creation with enforceable acceptance checklists. |
| `/casaflow:ticket` | `core/skills/ticket/SKILL.md` | Ticket creation/lookup. |
| `/casaflow:extend` | `core/skills/extend/SKILL.md` | Framework extension — scaffolds new skills, specialists, packs. |
| `/casaflow:postmortem` | `core/skills/postmortem/SKILL.md` | Post-merge retrospective with specialist/logic reviewer diagnosis. |
| `/casaflow:eng-copywriting` | `packs/engineering/skills/eng-copywriting/SKILL.md` | Sentence case standards. |
| `/casaflow:eng-logging` | `packs/engineering/skills/eng-logging/SKILL.md` | Log level guidance. |
| `/casaflow:eng-testing` | `packs/engineering/skills/eng-testing/SKILL.md` | Test strategy. |

## Git Workflow

- Main branch: `main`
- Branch naming: `{username}/jig-{number}-{kebab-title}`
- **Never commit or push without explicit user approval**
