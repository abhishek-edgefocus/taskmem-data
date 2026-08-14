---
id: wm-rrvgdr
type: followup
title: Answer Nate: spot-check Oliv credit-pull errors to confirm they are the OAuth token issue
status: next
priority: p1
size: s
due: 2026-08-03
people: [Nate]
tags: [northpond, needs-reply, api-health]
links: [relates:wm-u52nd6, parent:wm-3y3ckv, parent:wm-d3qnqe, blocks:wm-u52nd6]
refs: [thread=https://edgefocuspartners.slack.com/archives/C04474NRLP6/p1785434540555299]
created: 2026-07-31T12:55:10Z
updated: 2026-08-14T14:55:30Z
source: claude-code
label: Nate spot-check token errors
---

#team-devops thread 2026-07-30 (parent ts 1785434540.555299), started by Nate:
"Is there a way for us to do another pass at 'errors' being returned from the Experian
Credit Report Pull API?" — on the Oliv end all that arrives is
`errorMessages: ["Internal Server Error", "Server Error: Experian Credit Pull Failed"]`.
He asked whether more extensive messages reach the Edge Focus model and are scrubbed before
flowing through to Oliv, and noted: **"as total volume is picking up, the absolute error
volume is also picking up."**

Abhishek pointed him at the 07-24 #api-offers-daily analysis. Nate's reply — still
UNANSWERED — was: **"is there a way to spot check a few requests to confirm if they are
indeed from the token issue?"**

So there are two things owed here:
1. The spot check itself — pull a handful of recent failing requests and confirm they are
   the Experian OAuth 401, not something else. This is the direct ask.
2. A view on error-message passthrough: Oliv sees only a generic string. Whether we can
   surface a more specific reason to the partner is a separate design question he raised
   first and nobody addressed.

WHY THIS MATTERS MORE THAN THE ORIGINAL TRIAGE SAID: the 07-24 conclusion was "~1-2
apps/day, within normal range, low impact" ([[wm-unzbpr]]). Nate is now reporting error
volume rising with total volume. That erodes the premise the low priority on [[wm-u52nd6]]
(DEV-1478) was set from — the fix and this spot check should be looked at together.
