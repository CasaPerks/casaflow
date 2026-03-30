# Jig Init Experience

The first-run setup experience for teams adopting Jig.

## Design Principles

- **5 questions max.** Beyond that, people abandon the wizard.
- **Auto-detect everything possible.** Only ask what you can't infer.
- **Multiple choice, not free text** (except team name and prefix).
- **Show what was detected** so the user trusts the tool and can override.
- **End with next steps.** Don't dump files and leave.

---

## Auto-Detection (before any questions)

| Signal | Detection Method | Config Field |
|--------|-----------------|--------------|
| Git host | Parse `git remote get-url origin` (github.com, gitlab.com, bitbucket.org) | `git-host` |
| Main branch | `git symbolic-ref refs/remotes/origin/HEAD` or check for main/master | `main-branch` |
| AI platform | Detect existing CLAUDE.md → claude, GEMINI.md → gemini, AGENTS.md → codex | `platform` |
| Commit convention | Read `git log --oneline -20` and detect conventional/angular/other patterns | `convention` |
| Existing hooks | Scan for .husky/, commitlint config, .cz-config | `types`, `scopes` (import from commitlint) |
| Existing skills | Check for `.claude/skills/` directory with existing skills | suggest migration |

**Edge cases:**
- No git remote → skip git-host detection, ask in Q2
- No commit history → skip style detection, default to conventional
- Multiple remotes → use `origin`, note others

---

## Interactive Flow

```
$ jig init

  Detected: github (git host), main (branch), claude (platform)
  Detected: conventional commits via commitlint (.commitlintrc.cjs)

  1. Team name?
     > Duro

  2. Where do you track tickets?
     (a) GitHub Issues
     (b) Linear
     (c) Jira
     (d) Other
     (e) None — we don't use tickets
     > b

  3. Ticket prefix? (e.g., ENG, PROJ — appears in branch names and PR references)
     > ENG

  4. What engineering concerns matter to your team?
     These surface during brainstorming to make sure nothing gets missed.
     You can always add more later in jig.config.md.

     [x] i18n / translations
     [x] Analytics / event tracking
     [ ] Feature flags
     [x] Database migrations
     [x] Caching
     [ ] Webhooks / external notifications
     [ ] Event publishing (NATS, Kafka, etc.)
     [ ] Security / auth
     [x] Responsive layout

  5. Install the engineering starter pack?
     Includes: copywriting standards, logging guidance, test strategy
     (y) Yes — recommended
     (n) No — I'll add my own
     > y

  Done! Created:
    jig.config.md                — pipeline configuration
    .claude/skills/team/         — put your domain skills here
    .claude/skills/team/README.md — extension guide
    CLAUDE.md                    — added Jig declaration (review the diff)

  Next steps:
    /jig:extend    — add your first team skill
    /jig:kickoff   — start working on a task
```

---

## What Each Answer Generates

| Question | Config Field | Example |
|----------|-------------|---------|
| Q1: Team name | `name` | `name: Duro` |
| Q2: Ticket system | `ticket-system` | `ticket-system: linear` |
| Q3: Ticket prefix | `ticket-prefix` | `ticket-prefix: ENG` |
| Q4: Concerns | `## Concerns Checklist` | Each selected concern → a checklist line pointing to `manual` (teams wire to real skills later) |
| Q5: Engineering pack | Pack installation | Copies `packs/engineering/` into discovery path |
| Auto: git host | `git-host` | `git-host: github` |
| Auto: main branch | `main-branch` | `main-branch: main` |
| Auto: platform | `platform` | `platform: claude` |
| Auto: commit style | `convention` | `convention: conventional` |
| Auto: commitlint | `types`, `scopes` | Imported from existing commitlint config |

---

## Branching Format Generation

Derived from ticket system + prefix:

| Ticket System | Generated Format |
|--------------|-----------------|
| GitHub Issues | `{username}/gh-{number}-{kebab-title}` |
| Linear | `{username}/{ticket-prefix}-{number}-{kebab-title}` (lowercase) |
| Jira | `{username}/{ticket-prefix}-{number}-{kebab-title}` (lowercase) |
| None | `{username}/{kebab-title}` |

---

## Existing Project Handling

### Existing CLAUDE.md (or GEMINI.md, AGENTS.md)

Do NOT overwrite. Instead:

1. Read the existing file
2. Identify sections Jig now owns (workflow pipeline, skills framework, parallel development)
3. Append Jig declaration at the top: `This project uses **Jig** for development workflow management.`
4. Show the diff to the user for approval before writing
5. Suggest sections that can be removed (with explanation of what Jig handles instead)

### Existing `.claude/skills/`

If the team already has skills:

1. List discovered skills
2. Suggest: "Found N existing skills. Move them to `.claude/skills/team/` so Jig's discovery system finds them as team extensions?"
3. If yes, move them and update any cross-references
4. If no, leave them in place (they'll still work, just not organized by the Jig convention)

### Existing commit hooks

If commitlint/husky detected:

1. Import `type-enum` and `scope-enum` into `jig.config.md`
2. Note: "Imported commit types and scopes from your commitlint config. The Jig commit agent will respect these."
3. Do NOT modify the existing hook configuration

---

## Generated jig.config.md Example

For a team that answered: Duro, Linear, ENG, selected i18n + analytics + migrations + caching, yes to engineering pack:

```yaml
# Jig Configuration

## Team
name: Duro
platform: claude
git-host: github
ticket-system: linear
ticket-prefix: ENG

## Pipeline
stages:
  - discover
  - brainstorm
  - plan
  - execute
  - review
  - ship
  - learn

### Stage Overrides by Work Type
bug:
  skip: [brainstorm-full, learn]
  brainstorm: light
task:
  skip: [brainstorm, learn]
  review: light

## Branching
format: "{username}/eng-{number}-{kebab-title}"
main-branch: main

## Concerns Checklist
- i18n: manual
- analytics: manual
- migrations: manual
- caching: manual
- error-handling: core/specialists/error-handling
- security: core/specialists/security
- test-strategy: manual

## Review
swarm-tiers:
  fast-pass: [security, dead-code, error-handling]
  full: all
deep-review-model: opus
specialist-model-default: haiku

## Execution
parallel-threshold: 3
default-strategy: team-dev
teammate-mode: tmux

## Commit
convention: conventional
format: "type(scope): message"
types: [feat, fix, docs, chore, refactor, test]
scopes: [web, foundation, gateway]
require-ticket-reference: true
co-author: true
```

Note: concerns pointing to `manual` are placeholders. As the team creates domain skills (e.g., `fe-i18n`), they update the checklist to point to the real skill path.
