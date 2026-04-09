<p>
  <img src="assets/jig.png" alt="CasaFlow" width="100">
</p>

**The CasaPerks AI engineering workflow — spec-first, comprehension-gated, Jira-native.**

CasaFlow guides you from Jira ticket to merged PR with quality gates that
keep you in comprehension of what you're building. Give it a ticket ID and
it handles the rest — routing features through a spec-first pipeline and
bugs through root-cause-first debugging.

---

## Quick Start

### 1. Install

Add `.claude/settings.json` to your project root and commit it:

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

Then open the **terminal CLI** (not VS Code) and run:

```bash
cd /path/to/your-project
claude
```

```
/plugin marketplace add https://github.com/CasaPerks/casaflow.git
/plugin install casaflow@casaperks-casaflow --scope project
```

Restart your Claude session (`/exit` then `claude`).

> **Important:** Use the terminal CLI for `/plugin` commands. VS Code picks
> up the plugin automatically after install. Always use the full HTTPS URL.

### 2. Connect Jira (optional)

Each developer connects the official Atlassian integration in Claude:

1. Open Claude Code settings (or visit claude.ai/settings)
2. Go to **Integrations**
3. Connect **Atlassian** and authorize access to your Jira workspace

That's it — no API tokens or manual config needed. CasaFlow detects the
Atlassian connector automatically and uses it to read tickets, sync specs,
and update issue status.

Jira is optional — CasaFlow works without it, you'll just enter context
manually instead.

### 3. Configure (optional)

CasaFlow works out of the box with sensible defaults. To customize settings
(team name, Jira project key, branching format, etc.), copy the config
template into your project root:

```bash
cp .claude-plugin-source/scaffold/casaflow.config.md casaflow.config.md
```

A project-root config takes priority over the plugin default. See
[scaffold/casaflow.config.md](scaffold/casaflow.config.md) for all options.

### 4. Verify

Type `/casaflow:` — you should see the full command list autocomplete.

---

## Two Workflows

Everything starts with `/casaflow:spec`. Give it your Jira ticket ID and
CasaFlow reads the ticket, determines the work type, and routes you into
the right workflow automatically.

### Feature Workflow

For Stories, Features, Improvements, Tasks, and all non-bug ticket types.

```
/casaflow:spec          Provide ticket ID → pulls Jira context
     │                  Pre-seeds the spec with ticket details
     │                  You write and refine 6 sections:
     │                  summary, criteria, non-goals, tests, architecture, questions
     ▼
/casaflow:kickoff       Creates ticket + branch (feature/{JIRA-ID}:{name})
     │                  Design exploration (brainstorm)
     │                  Implementation plan (plan)
     ▼
/casaflow:build         Executes the plan stage by stage
     │                  After each stage: 3 comprehension questions (/approve)
     ▼
/casaflow:review        Specialist swarm (security, dead-code, errors, perf)
/casaflow:pr-create     PR with description + test plan
```

### Bug Workflow

For Bug ticket types. Detected automatically from the Jira issue type.

```
/casaflow:spec          Provide ticket ID → pulls Jira context
     │                  Detects "Bug" type
     │                  Redirects automatically to:
     ▼
/casaflow:kickoff       Skips re-fetching ticket (context passed through)
     │                  Creates branch (fix/{JIRA-ID}:{name})
     │                  Light brainstorm (root cause + fix approach)
     │                  Implementation plan
     ▼
/casaflow:build         Uses /debug for root-cause investigation:
     │                  Phase 1: Investigation (no fixes yet)
     │                  Phase 2: Pattern analysis
     │                  Phase 3: Hypothesis testing
     │                  Phase 4: Implementation + failing test
     ▼
/casaflow:review        Same specialist swarm
/casaflow:pr-create     PR with description + test plan
```

### No Jira? No Problem

If Jira isn't configured, `/casaflow:spec` skips the ticket prompt and
you describe the feature from scratch. You can also type **skip** at the
ticket prompt to proceed without Jira context.

---

## Branch and Commit Conventions

Branches are named by work type:

```
feature/{JIRA-ID}:{kebab-name}    # features, improvements
fix/{JIRA-ID}:{kebab-name}        # bugs
task/{JIRA-ID}:{kebab-name}       # tasks, chores
```

Commits follow conventional format and include the Jira ticket ID
automatically (parsed from the branch name):

```
feat(scope): add payment validation endpoint [CASA-123]
```

---

## All Commands

| Command | Purpose |
|---------|---------|
| `/casaflow:spec` | Write a feature spec. Entry point for all work. |
| `/casaflow:kickoff` | Full pipeline orchestrator. |
| `/casaflow:build` | Execute an implementation plan. |
| `/casaflow:approve` | Pass a stage gate (3 comprehension questions). |
| `/casaflow:review` | Specialist review swarm. |
| `/casaflow:pr-create` | Create a PR. |
| `/casaflow:pr-respond` | Respond to PR review feedback. |
| `/casaflow:finish` | Complete a branch (merge, PR, keep, discard). |
| `/casaflow:debug` | Root-cause-first debugging. |
| `/casaflow:explain` | Deep explanation of code just written. |
| `/casaflow:verify` | Run it before claiming it works. |
| `/casaflow:tdd` | Red-green-refactor discipline. |
| `/casaflow:review-tests` | 4-phase test quality audit. |
| `/casaflow:brainstorm` | Design exploration. |
| `/casaflow:plan` | Spec to implementation plan. |
| `/casaflow:prd` | Product requirements document. |
| `/casaflow:ticket` | Create or look up a ticket. |
| `/casaflow:retro` | Post-feature retrospective. |
| `/casaflow:postmortem` | Post-merge analysis. |

---

## Configuration Reference

Key settings in `casaflow.config.md` (see step 3 above):

```yaml
## Team
ticket-system: jira          # enables Jira integration

## Jira
project-key: CASA             # your Jira project key

## Branching
feature: "feature/{ticket-id}:{kebab-title}"
fix: "fix/{ticket-id}:{kebab-title}"
default: "task/{ticket-id}:{kebab-title}"

## Commit
require-ticket-reference: true
```

See [scaffold/casaflow.config.md](scaffold/casaflow.config.md) for all
options.

---

## Updating the Plugin

When a new version of CasaFlow is pushed, each developer needs to pull
the latest. Open the **terminal CLI** and run:

```
/plugin marketplace update casaperks-casaflow
/plugin install casaflow@casaperks-casaflow --scope project
```

Then restart your Claude session (`/exit` then `claude`). In VS Code,
reload the window (Cmd+Shift+P → "Reload Window").

You can check your current version with `/plugins` — it shows which
plugins are installed and their source.

---

## Troubleshooting

**Commands don't show up:** Install from the terminal CLI, not VS Code.
Restart your session after install. In VS Code, reload the window.

**SSH error when adding marketplace:** Use the full HTTPS URL:
`/plugin marketplace add https://github.com/CasaPerks/casaflow.git`

**Claude doesn't follow the workflow:** Start a fresh conversation. Long
sessions can dilute instruction adherence.

**Spec gate blocks me:** The spec gate only applies to features and
improvements. Bugs and tasks skip it automatically.

---

## Further Reading

- [Getting the Most Out of CasaFlow](docs/getting-the-most-out-of-casaflow.md)
- [framework/PIPELINE.md](framework/PIPELINE.md) — the 7-stage pipeline
- [scaffold/casaflow.config.md](scaffold/casaflow.config.md) — config reference

---

## License

MIT
