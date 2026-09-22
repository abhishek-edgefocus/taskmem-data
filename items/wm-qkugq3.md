---
id: wm-qkugq3
type: task
title: PagerDuty ownership gap: people don't watch PD when off-call, so reassigned incidents stall
status: open
priority: p2
size: xs
tags: [oncall, pagerduty, process]
links: [relates:wm-w98jug]
created: 2026-09-22T17:26:27Z
updated: 2026-09-22T17:26:44Z
source: claude-code
---

## Log
- 2026-09-22T17:26Z [claude-code] Raised by Abhishek 2026-09-22: 'generally people don't look at these PagerDuty things if they are not on call.' So reassigning an incident to an off-call owner (Kabeer, Eshan) silently parks it. Needs either a convention (PD assignment + a Slack nudge in the same motion), or accept that on-call chases it. Blocks the reassign-to-owner strategy for wm-5vrgzp and wm-kzfksh.
