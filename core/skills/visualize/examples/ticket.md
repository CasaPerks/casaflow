---
ticket: CAS-1284
ticket_url: https://casaperks.atlassian.net/browse/CAS-1284
fetched: 2026-05-27T14:32:00Z
issue_type: Story
reporter: sara.kim@casaperks.com
reporter_role: Product
assignee: zak.debrine@casaperks.com
priority: Medium
status: To Do
created: 2026-05-22
---

# Ticket: Reward expiry warnings

## Claude's one-line read

Notify users when their CasaPerks rewards are about to expire so they can use them before they're gone.

## Original description

> Users are complaining that their CasaPerks rewards expire without warning. Support is getting 5-10 tickets per week about this, mostly "I had points/perks I didn't know about and now they're gone."
>
> We should let users know before rewards expire so they can actually use them. Banner in the app or notification or something — push would be ideal, maybe email too. We should think about how to handle multiple rewards expiring at once so we're not blasting people.
>
> The timezone thing might be an issue but I'll let eng figure that out.
>
> AC:
> - Users see warnings for expiring rewards
> - Notifications work
> - Don't be too aggressive about it

## Stated acceptance criteria

1. Users see warnings for expiring rewards.
2. Notifications work.
3. Don't be too aggressive about it.

## Gaps detected

These are the things the ticket doesn't pin down. Each one needs a decision during the spec interview, not during implementation.

- **AC #1 has no threshold.** "Expiring" — within how many days? 3? 7? 14?
- **AC #2 doesn't specify channel.** Push, email, in-app banner, or all three? Description hints at push but doesn't commit.
- **AC #3 is undefined.** "Not too aggressive" has no concrete bound. One push? One per week? Quiet hours?
- **No decision on multiple expiring rewards.** Description flags this as a concern but doesn't resolve it — batch into one notification, or send N separate ones?
- **Timezone explicitly deferred to engineering.** Description says "I'll let eng figure that out." This is a product decision dressed as an engineering decision. Push back during the spec interview.
- **No handling of already-expired rewards.** Ticket only covers the warning. What happens to a reward the day after it expires — does it disappear, move to a section, or stay in place with a label?
- **No design reference.** No link to a Figma file or design system pattern for the warning UI.
- **No success metric.** What does "fewer support tickets" look like as a number? Reduction in expiry-related tickets by X%?

## Context

- **Reporter:** Sara Kim (Product). Sara mentioned in the stakeholder review that retention is the driver. Worth checking whether retention has a metric attached.
- **Linked tickets:** None.
- **Mentioned but not linked:** Support tickets ("5-10 per week"). Worth asking support for 2-3 representative ones to ground the spec in real complaints.
- **Comments:** One comment from Sara on 2026-05-23: "Let's get a quick spec on this before next sprint planning."

## Suggested next step

Run `/casaflow:spec CAS-1284` to start the spec interview. The eight gaps above are the structural questions to expect. Have rough answers in mind before starting — Claude will push on every one.
