---
id: wm-kge8tc
type: task
title: Resolve/reassign the errors backlog for Kushagra (promised today + tomorrow)
status: next
priority: p1
size: s
due: 2026-08-11
people: [Kushagra]
tags: [oncall]
links: [parent:wm-3y3ckv]
refs: [dm=https://edgefocuspartners.slack.com/archives/D0B5ASBDPK7/p1786365993136599]
created: 2026-08-10T14:46:31Z
updated: 2026-08-11T08:48:50Z
source: claude-code
label: Kushagra errors backlog sweep
---

Kushagra DM 2026-08-10 18:16 IST: "bhai thoda errors dekh lena" (have a look at the errors).
Abhishek 18:17: **"Ha Bhai aaj aur kal me thode resolve/reassign kar dunga"** — yes, I'll
resolve/reassign some today and tomorrow. Kushagra: "thanks!"

So this is an explicit two-day commitment (2026-08-10 and 2026-08-11) to work the Errors
queue, made to a named person. Captured because it lived only in that DM.

Scope is the general Errors backlog, not one ticket — "resolve/reassign" means triage:
close what is dead, reassign what belongs to someone else, keep what is genuinely his.

Already-tracked pieces that should be folded into the same pass rather than done twice:
- [[wm-s2f382]] — ERROR-1647 / ERROR-1178 / ERROR-400, assigned by Abhijeet on 07-29, plus
  the still-unassigned ERROR-1264.
- [[wm-qu4cr7]] — ERROR-1231, 15 northpond loans missing gateway model_responses.
- [[wm-u52nd6]] — DEV-1478, the Experian OAuth 401 fix the recurring errors trace back to.

Relevant context: Abhishek was added to the **dev-on-call** user group by Frank on
2026-08-04, so the Errors queue is now formally part of his rota rather than an ad-hoc ask.

## Log
- 2026-08-11T08:48Z [claude-code] IN PROGRESS 2026-08-11 — the sweep promised to Kushagra is underway. Evidence from parallel sessions and Slack:
- ERROR-1660/1661/1663 (statements_lc) verified CLOSEABLE from Dagster prod, correcting an 08-05 guess.
- ERROR-1675 (tare_loan_fl TU hard pull) investigated and found NOT a defect.
- ERROR-1626 (statements_northpond / northpond_transfers) investigated and split out as [[wm-te4cr2]] — it is a real, every-run failure.
- Abhishek to Abhijeet 00:54 IST: 'errors madhe tickets pan tulach assign karto' (I'll assign the error tickets to you as well), re the failed EDGEX jobs; Abhijeet: 'yes mala kar' (yes, assign them to me) and noted he has already self-assigned the corresponding Sentry issues. So the EDGEX-job errors are moving to Abhijeet — that is the 'reassign' half of the commitment, and it is agreed but not confirmed done in Linear.
- Abhishek 00:56: 'errors board var atleast orphan issues clear kartoy' (at minimum I'm clearing orphan issues on the errors board).
Remaining today: finish the reassignments to Abhijeet and the orphan-issue clear-out.
