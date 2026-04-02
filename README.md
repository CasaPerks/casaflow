<p>
  <img src="assets/jig.png" alt="CasaFlow" width="100">
</p>

**The CasaPerks AI engineering workflow — spec-first, comprehension-gated, Jira-native.**

CasaFlow is built on the [Jig](https://github.com/duronext/jig) framework and tuned for CasaPerks engineering culture. It guides AI agents through a structured pipeline — from Jira ticket to post-mortem — with quality gates at every stage that keep developers in comprehension of what they're building.

**Four priorities**: Speed · Dev comprehension · Code robustness · Developer education

---

## Quick Start — Install on a CasaPerks Repo

### Option A: Project settings (recommended — whole team gets it on clone)

Add to your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "casaflow@casaperks-casaflow": true
  },
  "extraKnownMarketplaces": {
    "casaperks-casaflow": {
      "source": {
        "source": "github",
        "repo": "CasaPerks/casaflow"
      }
    }
  }
}
```

Commit that file. Every teammate who opens the project in Claude Code gets CasaFlow automatically — no manual setup, no plugin install.

### Option B: Install manually via Claude CLI

Run these commands inside Claude Code:

```
/plugin marketplace add CasaPerks/casaflow
/plugin install casaflow@casaperks-casaflow --scope project
```

### Configure the pipeline

Copy the config template into your project root:

```bash
cp .claude-plugin-source/scaffold/casaflow.config.md casaflow.config.md
```

Or create `casaflow.config.md` manually — at minimum, set your team name and Jira project key:

```markdown
## Team
name: your-team-name
platform: claude
git-host: github
ticket-system: jira

## Jira
project-key: CASA
```

### Jira sync setup (optional but recommended)

CasaFlow syncs specs to Jira using the Atlassian MCP server. To enable it,
add this to your **personal** `~/.claude/settings.json` (not the project
settings — each developer configures this for themselves):

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-atlassian"],
      "env": {
        "ATLASSIAN_URL": "https://your-org.atlassian.net",
        "ATLASSIAN_EMAIL": "you@casaperks.com",
        "ATLASSIAN_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

Jira sync is always optional — if the MCP server isn't configured, CasaFlow
skips sync gracefully and proceeds to `/build`.

---

## First Use

```bash
/casaflow:spec kickoff-flow      # Write a spec before any code
/casaflow:kickoff                # Start the full pipeline
/casaflow:explain                # Deep explanation of code just written
/casaflow:review-tests           # Audit test quality with mutation testing
/casaflow:retro my-feature       # Post-feature retrospective
```

Type `/casaflow:` in Claude Code to see all available commands.

---

## What You Get

### The Pipeline

Every feature flows through these stages — the spec gate and approval gates
are CasaFlow additions on top of the Jig core:

```
[SPEC] → DISCOVER → BRAINSTORM → PLAN → EXECUTE → REVIEW → SHIP → LEARN
  ↑                                          ↑
  Hard gate for features              Approve-gate after
  (no code without a spec)            every build stage
```

### CasaFlow Skills

| Command | What It Does |
|---------|-------------|
| `/casaflow:spec` | Guide the developer through writing a feature spec. 6 sections: summary, acceptance criteria, non-goals, test spec, architecture sketch, open questions. **No code until this is done.** |
| `/casaflow:kickoff` | Start the full pipeline. For features/improvements, blocks until a spec exists. |
| `/casaflow:approve` | Pass the stage gate. Requires answering 3 comprehension questions: structural, failure mode, and change impact. |
| `/casaflow:explain` | Deep 5-section explanation: approach & tradeoffs, failure modes, change surface, what to test, what to refactor. |
| `/casaflow:review-tests` | 4-phase test audit: coverage table, mutation testing (the break test), quality rubric, letter-grade summary. |
| `/casaflow:retro` | Post-feature retrospective. 5 conversational questions, saved as a team artifact. Claude detects patterns across retros. |

### Inherited from Jig

| Command | What It Does |
|---------|-------------|
| `/casaflow:build` | Execute a plan — auto-selects parallel (`team-dev`) or serial (`sdd`) |
| `/casaflow:review` | Dispatch the specialist swarm (security, dead-code, error-handling, async-safety, performance) |
| `/casaflow:pr-create` | Review swarm first, then write the PR description |
| `/casaflow:pr-respond` | Fetch comments, fix, commit, push, reply, resolve |
| `/casaflow:debug` | Systematic debugging — root cause before fixes, always |
| `/casaflow:tdd` | Red-green-refactor discipline |
| `/casaflow:finish` | Merge, PR, keep, or discard — your choice |
| `/casaflow:postmortem` | Analyze reviewer patterns, update skills |

### The Approval Gate

Every build stage ends with:

1. **Stage report** — files changed (with coupling notes), how to run, manual
   test checklist, what was deferred, tradeoffs made
2. **Three comprehension questions** — structural, failure-mode, change-impact.
   The developer must answer all three correctly before the next stage begins.

This is the primary mechanism for keeping developers in comprehension as the
codebase grows. It's intentionally uncomfortable. That discomfort is the
learning.

### Jira Integration

After a spec is written, CasaFlow offers to:
- Create a Jira epic + ticket with the spec as a comment
- Update an existing ticket if one already exists
- Update ticket status after each approved stage (In Progress → In Review → Done)
- Post the PR URL as a comment on the ticket when the PR is created

All Jira actions require explicit developer approval before any MCP call is
made. Jira sync failure never blocks development.

---

## How It Works

CasaFlow uses Jig's three-layer discovery system:

```
team/      ← CasaPerks overrides (spec gate, approval gates, education skills)
packs/     ← Jira pack, engineering pack
core/      ← Jig framework defaults (pipeline, review swarm, agents)
```

The `team/` skills take priority. When `team/skills/kickoff` exists, it
replaces `core/skills/kickoff` — the Jig core is unchanged and the override
is self-contained.

---

## Configuration Reference

`casaflow.config.md` in your project root. Copy from
[scaffold/casaflow.config.md](scaffold/casaflow.config.md) as a starting point.

Key sections:

```yaml
## Team
name: your-team-name
ticket-system: jira

## Spec Gate
spec-required-for: [feature, improvement]

## Approval Gates
gates-enabled: true

## Jira
project-key: CASA
auto-sync-spec: true
auto-update-on-stage: true
done-on-merge: true

## Branching
format: "{username}/{ticket-id}-{kebab-title}"
```

---

## Updating

To get the latest version after this repo is updated:

```
/plugin marketplace update casaperks-casaflow
/plugin install casaflow@casaperks-casaflow --scope project
```

---

## Guides

| Guide | What It Covers |
|-------|---------------|
| [Getting the Most Out of CasaFlow](docs/getting-the-most-out-of-casaflow.md) | Philosophy, full pipeline walkthrough, and how to engage every stage for maximum value |

---

## Framework Reference

CasaFlow is built on Jig. The underlying framework docs:

| Document | What It Covers |
|----------|---------------|
| [framework/PIPELINE.md](framework/PIPELINE.md) | The 7-stage development pipeline |
| [framework/DISCOVERY.md](framework/DISCOVERY.md) | How skills are found and loaded |
| [framework/SKILL_SCHEMA.md](framework/SKILL_SCHEMA.md) | Frontmatter spec for writing skills |
| [framework/TIER_SYSTEM.md](framework/TIER_SYSTEM.md) | How tiers control skill activation |
| [team/README.md](team/README.md) | CasaFlow overrides guide |
| [scaffold/casaflow.config.md](scaffold/casaflow.config.md) | Config template |

---

## License

MIT
