```
         ┌──────────────────────────────────┐
         │    ◎          ◎          ◎       │
         └───────────────┬──────────────────┘
                         │
                    ┌────┴────┐
                    │  ◎   ◎  │
                    │         │
                    │  ◎   ◎  │
                    │         │
                    │  ◎   ◎  │
                    └────┬────┘
                         │
                         ▼
```

# Jig

**The AI engineering workflow framework for teams.**

Jig is a full-lifecycle development framework that guides AI agents through a structured pipeline — from ticket to post-mortem. Named after the manufacturing tool that holds workpieces and guides tools to produce consistent results, Jig aligns your entire team around shared conventions, quality gates, and development workflows.

## Why Jig?

Without a framework, teams end up with scattered AI skills, inconsistent workflows, and no shared conventions. Some engineers brainstorm before coding; others don't. Code review quality varies. Nobody's sure which skills exist or when to use them.

Jig fixes this the way Rails fixed web development: with strong opinions, sensible defaults, and a clear structure that everyone follows.

## What You Get

**Full Pipeline** — Every stage of development has a skill:
```
DISCOVER → BRAINSTORM → PLAN → EXECUTE → REVIEW → SHIP → LEARN
```

**Parallel Execution** — `/jig-team-dev` spawns parallel agent teammates with staggered quality gates. Your implementation plan runs in parallel, with spec compliance and code review at every step.

**Review Swarm** — `/jig-review` dispatches specialist reviewers in parallel (security, dead code, error handling, async safety, performance). Teams add their own domain-specific specialists.

**Configurable, Not Rigid** — `jig.config.md` lets you tune the pipeline per work type, define your concerns checklist, choose your ticket system, and set review policies. Override only what you need.

**Extensible** — Add domain skills (`be-database`, `fe-react`), custom specialists (`typeorm.md`, `i18n.md`), and team agents. They wire into the framework's discovery system automatically.

## Quick Start

### Install (Claude Code)

```bash
# Add the Jig marketplace
/plugin marketplace add duronext/jig

# Install for your whole team (writes to .claude/settings.json)
/plugin install jig@duronext-jig --scope project
```

That's it. Your team gets 15 pipeline skills, 3 agents, 5 review specialists, and an engineering starter pack. Type `/jig-` to see all available commands.

### First Use

```bash
/jig-kickoff    # Start working on a task — guides you through the full pipeline
/jig-brainstorm # Design a feature before building it
/jig-extend     # Add your first team skill
```

See [docs/init-experience.md](docs/init-experience.md) for the interactive setup flow that generates your `jig.config.md`.

### Other Platforms (Gemini, Codex)

Clone the repo and reference the skills directly:

```bash
git clone https://github.com/duronext/jig.git .jig
```

See [adapters/](adapters/) for platform-specific integration guides.

## How It Works

Jig skills come from two sources:

```
Plugin (Jig core)        Your project (.claude/skills/)
├── kickoff              ├── be-database/
├── brainstorm           ├── fe-react/
├── plan                 ├── ops-feature-flags/
├── team-dev             └── ... your domain skills
├── review
└── ... 15 total         Discovered automatically by
                         tier, globs, and frontmatter
```

Core skills come from the Jig plugin (auto-updated). Team skills live in your repo's `.claude/skills/` directory — they follow Jig's schema and wire into the framework's discovery, brainstorming, and review systems.

### Configuration

`jig.config.md` in your project root controls the pipeline:

```yaml
## Team
name: Acme
platform: claude
git-host: github
ticket-system: linear
ticket-prefix: ENG

## Concerns Checklist
- i18n: .claude/skills/fe-i18n
- security: core/specialists/security
- test-strategy: manual
```

The concerns checklist surfaces during brainstorming — mapping your team's engineering concerns to specific skills. See [framework/CONCERNS_CHECKLIST.md](framework/CONCERNS_CHECKLIST.md).

### Tier System

| Tier | Activation | Use For |
|------|-----------|---------|
| Standards | Always loaded | Universal rules (copywriting, commit format) |
| Domain | Glob-triggered | Stack expertise (database, frontend, testing) |
| Feature | Narrow globs | Feature-specific knowledge |
| Workflow | Explicit invocation | Pipeline skills (`/jig-kickoff`, `/jig-review`) |

## Updating

Jig is distributed as a Claude Code plugin. To get the latest version:

```bash
/plugin marketplace update duronext-jig
/plugin install jig@duronext-jig --scope project
```

## Platform Support

Jig skills are platform-agnostic markdown. Adapters handle loading for:
- **Claude Code** (primary) — native plugin integration
- **Gemini CLI** — GEMINI.md context loading
- **Codex** — AGENTS.md integration

Teams using GitLab or Bitbucket are supported via the [git host adapter](framework/GIT_HOST.md).

## Framework Reference

| Document | What It Covers |
|----------|---------------|
| [PIPELINE.md](framework/PIPELINE.md) | The 7-stage development pipeline |
| [DISCOVERY.md](framework/DISCOVERY.md) | How Jig finds and loads skills |
| [SKILL_SCHEMA.md](framework/SKILL_SCHEMA.md) | Frontmatter spec for all skills |
| [TIER_SYSTEM.md](framework/TIER_SYSTEM.md) | How tiers control activation |
| [CONCERNS_CHECKLIST.md](framework/CONCERNS_CHECKLIST.md) | Configurable brainstorming checklist |
| [GIT_HOST.md](framework/GIT_HOST.md) | GitHub/GitLab/Bitbucket command mapping |
| [Design Spec](docs/specs/2026-03-28-jig-framework-design.md) | Original design document |
| [Init Experience](docs/init-experience.md) | Interactive setup flow |

## Origin

Jig was extracted from [Duro's](https://www.durolabs.co) Phoenix project, where 31 battle-tested skills, 6 agents, and 10 specialist reviewers evolved into a comprehensive AI-assisted development system. Born from a hardware startup that knows what jigs do.

## License

MIT
