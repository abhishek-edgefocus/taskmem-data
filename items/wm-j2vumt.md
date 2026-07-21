---
id: wm-j2vumt
type: correction
title: Invented an EdgeX-2026-1NN dashboard-building deliverable from a coverage-gap audit nobody asked about
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-rp2y23]
created: 2026-07-21T12:36:08Z
updated: 2026-07-21T12:36:08Z
source: claude-code
label: Invented an EdgeX-2026-1NN dashboard-building deliverable
---

WHAT WE HAD: wm-rp2y23 tracked 'Build EdgeX-2026-1NN Grafana dashboards (zero exist)' as open work, with a clone-the-1NN-2025-set implementation plan and a blocked-on-wm-ku5sen dependency.

WHAT WAS TRUE: Abhishek never wanted an EDGEX-2026-1NN dashboard (2026-07-21: 'I just didn't want the EDGEX 2026-1NN dashboard. might have been misinterpreted'). The other half of the item — promoting the NorthPond monitoring dashboard out of the personal folder — was real, and he has since done it.

WHY IT SLIPPED: on 2026-07-17 an agent ran a Grafana API audit, observed that edgex20261NN appeared in 0 of 172 dashboards while edgex20251NN/20252NN/2026PT1 appeared in 12-17, and converted that ASYMMETRY into a deliverable. Nobody had asked for it. A gap between what exists and what could exist is an observation, not a commitment.

PATTERN: same family as wm-y7dqmg (six NorthPond items sat open while the work was already done). Both are the audit-to-worklist reflex — findings from a read-only sweep being written up as tasks with owners and plans, then surviving in the working set because they look well-researched.

GUARD: an item created from an audit rather than from a request should say so in its body and start in 'inbox', not 'open', until a human confirms they want it. Bundling a confirmed ask and an inferred one into a single item (as here) also hides the inferred half behind the real one — keep them separate.

## Environment
- taskmem: f4cb0f8
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-21T12:36:08Z
- corrected item: wm-rp2y23
