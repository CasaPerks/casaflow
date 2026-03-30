# Claude Code Adapter

How Jig integrates with Claude Code's native loading mechanism.

## Mapping

| Jig Concept | Claude Code Equivalent |
|-------------|----------------------|
| Skills (`*/skills/*/SKILL.md`) | `.claude/skills/` directory |
| Agents (`*/agents/*.md`) | `.claude/agents/` directory |
| `jig.config.md` | Read directly by skills (no translation) |
| `CLAUDE.md` | Project instructions file |

## Tier Mapping

Jig tiers map 1:1 to Claude Code's native skill activation:

| Jig Tier | Claude Code Mechanism |
|----------|----------------------|
| Standards (`alwaysApply: true`) | Claude auto-loads the skill for every interaction |
| Domain (globs) | Claude's native glob matching triggers the skill when editing matching files |
| Feature (narrow globs) | Same as domain — narrower globs, same mechanism |
| Workflow (explicit) | Slash commands (`/skill-name`) — user or skill invokes explicitly |

No adapter translation is needed for activation. Claude Code reads the `alwaysApply` and `globs` frontmatter fields directly from SKILL.md files.

## Distribution Channels

### Channel 1: Claude Marketplace Plugin (Primary)

The Marketplace plugin injects core and pack skills into Claude Code's discovery path automatically. Framework files never touch the consuming project's repository.

**Plugin-managed files:**
```
~/.claude/plugins/cache/jig-framework/
├── core/
│   ├── skills/           # 14 pipeline skills
│   ├── agents/           # 3 core agents
│   └── specialists/      # 5 generic reviewers
├── packs/
│   └── engineering/      # Starter pack
└── adapters/claude/
```

**What the consuming project contains:**
```
your-project/
├── jig.config.md         # Team configuration
├── CLAUDE.md             # Project-specific context (not framework)
└── team/                 # Team extensions
    ├── skills/
    ├── specialists/
    └── agents/
```

Claude Code discovers skills from both the plugin cache and the project's `team/` directory. The priority order is preserved: team > pack > core.

**Updates:** Plugin updates are automatic. Core skills and packs stay current without team action. Team skills are unaffected.

### Channel 2: npm / CLI (Secondary)

```bash
npm install --save-dev @jig-framework/core
npm install --save-dev @jig-framework/pack-engineering
```

Or standalone (no Node required):
```bash
jig sync
```

**How it works:**

1. `jig sync` copies core skills, agents, and specialists into `.jig/` (gitignored)
2. `.jig/` is symlinked or referenced by `.claude/skills/` and `.claude/agents/`
3. Version is pinned in `package.json` or `.jig-version`
4. Updates are explicit: run `jig sync` again after version bump

**Directory layout after sync:**
```
your-project/
├── .jig/                 # Gitignored. Managed by jig sync.
│   ├── core/
│   ├── packs/
│   └── .jig-version
├── .claude/
│   ├── skills/           # Symlinks or references into .jig/
│   └── agents/           # Symlinks or references into .jig/
├── jig.config.md
├── CLAUDE.md
└── team/
```

### Channel 3: Vendored (Escape Hatch)

```bash
jig eject
```

**How it works:**

1. Copies everything from `.jig/` (or plugin cache) into `.claude/skills/` and `.claude/agents/`
2. Files are now part of the project — committed to version control
3. No auto-updates. Team owns and maintains all framework files.
4. For strict compliance environments or heavy customization needs.

**Directory layout after eject:**
```
your-project/
├── .claude/
│   ├── skills/
│   │   ├── kickoff/
│   │   │   └── SKILL.md
│   │   ├── brainstorm/
│   │   │   └── SKILL.md
│   │   ├── ...           # All core + pack skills
│   │   └── team/         # Team skills alongside
│   └── agents/
│       ├── commit.md
│       ├── code-reviewer.md
│       └── pr-reviewer.md
├── jig.config.md
└── CLAUDE.md
```

## CLAUDE.md Integration

`jig init` generates a CLAUDE.md (or modifies the existing one) with a single declaration line that tells Claude Code this project uses Jig:

```markdown
This project uses **Jig** for development workflow management.
See `jig.config.md` for pipeline configuration.
```

The rest of CLAUDE.md is project-specific context: team name, tech stack, commands, code style, library gotchas. None of that belongs in Jig — it stays in CLAUDE.md where it always lived.

See `CLAUDE.md.template` for the full template that `jig init` generates.

## Config Integration

`jig.config.md` requires no adapter translation. Skills read it directly as markdown context. Claude Code loads the file when skills reference it (e.g., `kickoff` reads pipeline stages, `review` reads swarm-tiers).

The config file lives in the project root alongside CLAUDE.md. Both are committed to version control.

## Discovery Flow

When Claude Code starts a session in a Jig project:

1. **CLAUDE.md** is loaded (always). Contains the Jig declaration and project-specific context.
2. **Standards-tier skills** are loaded (always). Their `alwaysApply: true` frontmatter triggers Claude Code's auto-load.
3. **Domain/Feature skills** are loaded when the user edits files matching their globs.
4. **Workflow skills** are loaded when the user types a slash command (e.g., `/jig:kickoff`).
5. **Agents** are available for invocation by skills or by the user.
6. **jig.config.md** is read on-demand by skills that need configuration values.

## Multi-Platform

A project can target multiple platforms. `jig init --platform claude,gemini` generates both `CLAUDE.md` and `GEMINI.md` from their respective templates. The same `jig.config.md` and `team/` directory serve all platforms.
