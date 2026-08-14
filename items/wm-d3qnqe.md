---
id: wm-d3qnqe
type: task
title: Experian / NorthPond API health: confirm the 401 story, then fix it
status: active
size: xl
people: [Nate, Abhijeet, Kabeer]
tags: [northpond, api-health, oncall]
links: [parent:wm-j523sq]
refs: [DEV-1478=https://linear.app/edge-focus/issue/DEV-1478/northpond-experian-credit-pulls-intermittently-fail-with-401-oauth]
created: 2026-08-14T14:54:55Z
updated: 2026-08-14T14:55:14Z
source: claude-code
label: Experian API health
---

Container for the Experian-side API health thread. Created 2026-08-14 while restructuring the
memory into ordered threads; the members were split between the NorthPond project and the on-call
project with no lineage, so the diagnosis and the fix were drifting apart.

THE THREAD. northpond_loan_fl (v2 / Experian) credit pulls intermittently return HTTP 500 to Oliv
because Experian's credit-report POST answers 401 Unauthorized — two gateway workers share one
login and neither refreshes the token nor retries. The July triage sized it at ~1-2 applications a
day and set the fix low. Nate then reported in #team-devops on 2026-07-30 that "as total volume is
picking up, the absolute error volume is also picking up", which undercuts the premise that
priority was set from. He asked, and has not been answered since: "is there a way to spot check a
few requests to confirm if they are indeed from the token issue?"

ORDERING. The spot check comes before the fix, and not just for politeness — it is what confirms
these errors ARE the OAuth 401 rather than something else, and it is what re-prices the fix. It
also discharges a reply owed since 2026-08-03.

Sitting in the thread but not in the chain: triaging the Experian error tickets Abhijeet assigned
(now four, with ERROR-1178 added on 2026-08-14), the NULL Clarity attributes investigation, the
Activate model handover from Nakula, and the July API outage reply owed to Kabeer.

A second question of Nate's is still unaddressed and is not tracked anywhere else: Oliv only ever
sees the generic string "Server Error: Experian Credit Pull Failed". Whether we can pass a more
specific reason through to the partner is a design question he raised first and nobody answered.

## Next steps
- Pull a handful of recent failing northpond_loan_fl requests and confirm the 401 is the cause.
- Reply to Nate in the #team-devops thread with the spot-check result, and say something about
  error-message passthrough while you are there.

## Links
- Nate's thread — https://edgefocuspartners.slack.com/archives/C04474NRLP6/p1785434540555299
- DEV-1478 — https://linear.app/edge-focus/issue/DEV-1478/northpond-experian-credit-pulls-intermittently-fail-with-401-oauth
- Project: [[wm-j523sq]]
