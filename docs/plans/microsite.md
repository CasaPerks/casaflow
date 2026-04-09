# Plan: Jig Framework Microsite

**Date:** 2026-03-30
**Type:** Feature
**Status:** Draft

## Overview

Build a static one-pager microsite for the Jig framework, deployed to GitHub
Pages. Pure HTML/CSS/JS — single `site/index.html`, zero build step. Dark mode
with blue-violet/indigo accent system, Inter + monospace typography, scroll
fade-up animations, inspired by work.dustindiaz.com aesthetic.

## Design Decisions

- **Tech:** Single HTML file, inline CSS + JS. No build, no dependencies.
- **Color:** Near-black background (`#08080d`), blue-violet accent system
  (shifting from resume's `#8b5cf6` toward indigo `~#6366f1`)
- **Typography:** Inter (Google Fonts) for body, SF Mono/Fira Code for
  code/meta. Fluid sizing via `clamp()`.
- **Layout:** Single column, max-width ~960px, generous vertical rhythm
- **Animations:** Intersection Observer fade-ups (20px translate, 0.7s ease)
- **Background:** Subtle dot grid at ~1.5% opacity, gradient dividers
- **Logo:** Typographic wordmark (graphic TBD)

## Content Sections (in order)

1. **Hero** — "Jig" wordmark, tagline, manufacturing jig metaphor (2 sentences)
2. **Quick Install** — 3-line JSON snippet for `.claude/settings.json`
3. **The Problem** — Why teams need an opinionated AI framework
4. **The Pipeline** — 7-stage flow visualized: DISCOVER → ... → LEARN
5. **Core Skills** — 16 skills grouped by pipeline stage
6. **How It Works** — Install → Configure → Extend (3-layer model)
7. **Origin Story** — Duro, Phoenix project, 31 skills battle-tested, then
   frameworkized. Homage to the engineering team.
8. **Walkthrough** — Terminal mockup: kickoff → brainstorm → PRD → build →
   review
9. **Get Started** — Full install options + CTA + footer

## File Structure

```
site/
├── index.html          # The entire site (HTML + inline CSS + inline JS)
└── assets/
    └── jig.png         # Logo (copied from repo root assets/)
```

GitHub Pages configured to serve from `site/` on `main` branch.

---

## Tasks

### Task 1: Foundation — design system and page skeleton
**Files:** `site/index.html`
**Description:**
Create `site/index.html` with:
- HTML5 document structure, meta tags (viewport, description, OG tags, theme-color)
- Google Fonts load (Inter 300-800)
- `<style>` block with full CSS design system:
  - Custom properties: `--bg`, `--text-primary`, `--text-secondary`,
    `--text-tertiary`, `--accent`, `--accent-hover`, `--accent-glow`,
    accent at various opacities for tags/borders/bullets
  - Base reset (box-sizing, margin, scroll-behavior)
  - Body: background color, dot grid via radial-gradient, font-family,
    antialiased rendering, color
  - Container: max-width 960px, centered
  - Typography scale: h1 (clamp 2.2-3rem, weight 800, tight tracking),
    section labels (monospace, 0.7rem, uppercase, wide tracking),
    body text, small text
  - `.section` with generous vertical padding (~5-6rem)
  - `.divider` — gradient hr that fades right
  - `.fade-in` — initial state for scroll animation (opacity 0, translateY 20px)
  - `.fade-in.visible` — animated state (opacity 1, translateY 0, transition 0.7s)
  - Selection styling with accent color
  - Responsive breakpoints (768px, 480px)
- Empty `<section>` containers for all 9 content sections with IDs
- Minimal `<script>` with Intersection Observer that adds `.visible` to
  `.fade-in` elements on scroll

**Verify:** Open `site/index.html` in browser. Dark background with dot grid
visible, Inter font loading, scroll observer functional (add a test element).

---

### Task 2: Hero + Quick Install sections
**Files:** `site/index.html`
**Description:**
Build the above-the-fold experience:

**Hero section:**
- "Jig" as typographic wordmark — large, weight 800, tight letter-spacing,
  accent color or white with accent glow
- Subtitle: "The AI engineering workflow framework for teams."
- Manufacturing metaphor: 2 sentences about what a jig does → what this
  framework does. Keep it to 3 lines max.
- Subtle gradient divider below

**Quick Install section:**
- Small monospace label: "QUICK START"
- The settings.json snippet in a styled code block:
  ```json
  {
    "enabledPlugins": { "jig@duronext-jig": true },
    "extraKnownMarketplaces": {
      "duronext-jig": { "source": { "source": "github", "repo": "duronext/jig" } }
    }
  }
  ```
- Brief instruction: "Add to `.claude/settings.json` — every teammate gets Jig
  on clone."
- Style the code block: dark inner background, accent-tinted border or glow,
  monospace font, small text

**CSS additions:**
- Hero-specific styles (wordmark sizing, subtitle, metaphor text)
- Code block styles (`.code-block` — background, border, padding, overflow-x)
- All content elements get `.fade-in` class

**Verify:** Above-the-fold looks polished. Wordmark is prominent. Install
snippet is scannable and copy-friendly.

---

### Task 3: Problem + Pipeline sections
**Files:** `site/index.html`
**Description:**

**Problem section:**
- Section label: "THE PROBLEM" (monospace, uppercase, tracked, accent color)
- 2-3 short paragraphs about the chaos without a framework:
  - Scattered AI skills, inconsistent workflows, no shared conventions
  - Some engineers brainstorm; others don't. Review quality varies.
  - The opinionated framework insight: "The best frameworks don't just give you
    tools — they give you opinions." Reference the onboarding speed this enables.
- Keep copy tight. No bullet lists — flowing prose, short sentences.

**Pipeline section:**
- Section label: "THE PIPELINE"
- The 7 stages as a horizontal flow (or wrapped on mobile):
  `DISCOVER → BRAINSTORM → PLAN → EXECUTE → REVIEW → SHIP → LEARN`
- Each stage as a small styled element (monospace, accent border/background)
  with arrows or connectors between them
- One sentence below: "Every stage has a skill. Every handoff has a quality gate."
- Brief note: work type (bug/feature/task) determines which stages run

**CSS additions:**
- Pipeline flow layout (flexbox, wrapping, arrow/connector styling)
- Stage pill/badge styling
- Responsive: stack vertically on mobile

**Verify:** Problem narrative reads cleanly. Pipeline visualization is clear
and attractive. Responsive on narrow viewports.

---

### Task 4: Core Skills + How It Works sections
**Files:** `site/index.html`
**Description:**

**Core Skills section:**
- Section label: "CORE SKILLS"
- Group the 16 skills by pipeline stage. Use a compact layout — NOT a full
  table. Think: stage name as a small heading, then 2-4 skill names with
  one-line descriptions underneath.
- Grouping:
  - **Discover:** kickoff
  - **Brainstorm:** brainstorm, prd
  - **Plan:** plan
  - **Execute:** build, team-dev, sdd, tdd
  - **Review:** review, verify, debug
  - **Ship:** pr-create, pr-respond, finish, commit (agent)
  - **Learn:** postmortem
- Also mention: 5 review specialists + engineering starter pack (one line each)
- Skill names in monospace with accent color. Descriptions in secondary text.

**How It Works section:**
- Section label: "HOW IT WORKS"
- Three steps, each with a short heading and 2-3 sentences:
  1. **Install** — Add to settings.json or CLI install. Whole team gets it.
  2. **Configure** — `casaflow.config.md` tunes the pipeline. Concerns checklist
     maps your team's engineering concerns to skills.
  3. **Extend** — Add domain skills, custom specialists, team agents. They
     wire into discovery automatically. `/casaflow:extend` scaffolds them.
- Keep this section short. The detail is in the skills section above.

**CSS additions:**
- Skills grid/list layout (stage groups)
- Step layout for How It Works (numbered or icon-based)
- Monospace skill name styling

**Verify:** Skills are scannable, grouped logically. How It Works is concise
and actionable.

---

### Task 5: Origin Story section
**Files:** `site/index.html`
**Description:**

- Section label: "ORIGIN"
- Narrative tone — this is the human part of the page:
  - Extracted from Duro's engineering platform (the Phoenix project)
  - 31 battle-tested skills, 6 agents, 10 specialist reviewers evolved over
    real-world usage by the engineering team
  - Born from a hardware startup that knows what jigs do — the name isn't
    metaphorical by accident
  - The team wanted to share what they'd built. So they frameworkized it.
- Homage to Duro Engineering — "Built by engineers who ship hardware and
  software" or similar. Warm but brief.
- Possibly a small quote or pull-quote treatment for emphasis
- Link to durolabs.co

**CSS additions:**
- Pull-quote or highlight styling if used
- Link styling consistent with accent system

**Verify:** Reads as authentic, not corporate. Warm tone. Duro credit is
present but not self-congratulatory.

---

### Task 6: Walkthrough section
**Files:** `site/index.html`
**Description:**

- Section label: "SEE IT IN ACTION"
- A styled terminal mockup showing a condensed workflow:
  ```
  $ /casaflow:kickoff
  ▸ Work type: feature
  ▸ Summary: Add user notification preferences
  ▸ Pipeline: discover → brainstorm → prd → build → review → ship

  $ /casaflow:brainstorm
  ▸ What problem does this solve for users?
  ▸ Approach A: Per-channel toggles with defaults
  ▸ Approach B: Smart digest with frequency control
  ▸ Design approved ✓

  $ /casaflow:prd
  ▸ PRD: User Notification Preferences
  ▸ 12 acceptance criteria defined
  ▸ Layer tags: [API] [DATA] [UI]
  ▸ Approved ✓

  $ /casaflow:build
  ▸ Strategy: parallel (4 tasks, 3 agents)
  ▸ Agent 1: Data model + migrations ████████ done
  ▸ Agent 2: API endpoints          ████████ done
  ▸ Agent 3: UI components          ████████ done
  ▸ Spec compliance: passed ✓
  ▸ Code quality: passed ✓

  $ /casaflow:review
  ▸ Dispatching 7 specialists...
  ▸ security: passed
  ▸ async-safety: passed
  ▸ error-handling: 1 suggestion (minor)
  ▸ Confidence: 94% — ready to ship
  ```
- Terminal styling: dark inner bg, slight glow/border, monospace, green/accent
  for success markers, muted for prompts
- One line of context above: "A feature, from idea to shipped — guided by Jig
  at every step."

**CSS additions:**
- Terminal mockup styles (`.terminal` — background, border-radius, padding,
  monospace, line colors)
- Success/pass markers in green or accent
- Progress bars as unicode blocks

**Verify:** Terminal mockup looks realistic and polished. The workflow story
is clear in under 30 seconds of reading.

---

### Task 7: Get Started + Footer, final polish
**Files:** `site/index.html`
**Description:**

**Get Started section:**
- Section label: "GET STARTED"
- Two install paths:
  1. **Project settings (recommended):** the JSON snippet (reuse from hero,
     or link back up)
  2. **CLI:** `/plugin marketplace add duronext/jig` + install command
- "Type `/casaflow:kickoff` to start your first task."
- Link to GitHub repo: github.com/duronext/jig

**Footer:**
- Small, centered, muted text
- "MIT License" + GitHub link
- Keep minimal — one or two lines

**Final polish pass:**
- Ensure all `.fade-in` classes are applied consistently
- Verify scroll animation timing feels right (stagger delays within sections)
- Check responsive layout at 768px and 480px breakpoints
- Verify all gradient dividers between sections
- Test that code blocks are horizontally scrollable on mobile
- Ensure font loading doesn't cause layout shift (font-display: swap)

**Verify:** Full page scroll from top to bottom is smooth and polished.
Responsive on mobile. All sections have fade-in animations. Links work.
Code blocks are copy-friendly.

---

## Deployment Note

After all tasks complete, configure GitHub Pages:
- Settings → Pages → Source: Deploy from branch, `main`, `/site` folder
- Or add a simple GitHub Actions workflow if `/site` folder isn't supported
  as a source path (GH Pages supports `/` or `/docs` natively — may need
  to use `/docs` instead or a workflow)

Alternative: rename `site/` to `docs/site/` or use a GH Actions deploy.
We'll figure this out at ship time.

## Dependencies

- Google Fonts CDN (Inter)
- No npm packages, no build tools, no frameworks
