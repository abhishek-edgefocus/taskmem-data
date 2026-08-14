---
id: wm-ufw7kj
type: task
title: Investigate NULL/missing Clarity attributes in the Experian Activate model container (DEV-1490)
status: next
priority: p2
size: m
people: [Nate]
tags: [northpond, experian-activate, api-health]
links: [parent:wm-j523sq, relates:wm-mmmc9t, follows:wm-9dx47e, parent:wm-d3qnqe]
refs: [DEV-1490=https://linear.app/edge-focus/issue/DEV-1490/investigate-how-the-northpond-experian-model-container-handles-null]
created: 2026-07-31T12:54:52Z
updated: 2026-08-14T19:57:12Z
source: claude-code
label: Activate NULL Clarity attributes
---

Created by Abhishek 2026-07-30 13:48Z off the Activate early-results discussion with Nate
([[wm-9dx47e]], now done). Linear DEV-1490, Todo, unstarted, branch name reserved.

THE FINDING (Nate's, as recorded on the ticket):
- Experian sometimes returns **all Clarity attributes NULL** in the Activate marketing
  environment.
- Those consumers apply with far worse credit grades than expected — likely explains the
  variance Nate saw in the early results.
- **PROD rejects on missing attributes, but the hosted Activate model still returns
  scores.** That divergence is the core of it: the marketing path is scoring applicants the
  production path would refuse, so Activate targeting is being driven by scores computed on
  incomplete input.

WHY THIS IS AWKWARD RIGHT NOW: the container in question is the one Abhishek has just taken
over from Nakula and has **not yet had a formal KT on** — see [[wm-mmmc9t]]. Understanding
how the packaged model handles NULL attributes is close to the first real question anyone
would ask of it, so this and the KT should probably happen together rather than in sequence.

Open, unscoped: whether the fix is in the container (reject/flag like PROD), in what
Experian sends, or in how Activate consumes the score.
