---
id: wm-f7egzv
type: followup
title: Request Eshan as reviewer on the open PRs he offered to review
status: next
priority: p1
size: xs
due: 2026-08-24
people: [Eshan]
tags: [northpond, needs-reply]
links: [relates:wm-u52nd6, relates:wm-gp7g82]
created: 2026-08-24T12:28:37Z
updated: 2026-08-24T12:29:57Z
source: claude-code
label: Eshan reviewer assignment
---

Eshan volunteered to review Abhishek's PRs and the offer was never taken up.

In #platform-data-owners (C0B6M0AQKB5) on 2026-08-21 01:30 IST Abhishek joked that there
should be a "reviewer-on-call" alongside dev-on-call. In the thread that followed he and
Kushagra agreed to swap reviews ("apan mutually kar lete he, me tera bada wala pr review
karta, tu mere 3 chote wale review kar le"), and Abhishek pointed out his were small —
"Mere to dekh lo, 3 me se 2 to bas 1 or 2 liners he (ignoring tests)". Kushagra deferred to
Eshan, and at 02:26 IST Eshan said plainly: **"Mujhe review assign kar dena I can take a
look into them later today!"** — assign them to me and I will look today.

Verified on 2026-08-24, three days later: **no reviewer has been requested on any of them.**
`gh pr view 6416` returns zero reviewRequests and zero assignees. PR #6131 likewise has none.
PR #6223 is the exception — it already has kushagrashukla2904 and nakula-efp requested.

This is the cheapest unblock on the board: a willing reviewer asked to be assigned and
nobody assigned him, while [[wm-u52nd6]]'s PR sits green and unreviewed.

Note the ordering trap on #6416: requesting a reviewer while the PR is still a draft does
not surface it for review. Take it out of draft first, then request.

## Next steps
1. Take PR #6416 out of draft (see [[wm-u52nd6]] — CI is fully green).
2. Request `eshan-edgefocus` as reviewer on #6416, and ping the existing
   #platform-data-owners thread so he sees it landed.
3. PR #6131 is NOT ready to hand him — it still needs a base retarget before it is
   reviewable at all. That is tracked separately on [[wm-gp7g82]]; do not assign him that
   one until the retarget is done.

## Links
- Eshan's offer — https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1787259360976439
- Thread parent — https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1787256050911219
- PR #6416 — https://github.com/edgefocus/efp/pull/6416

## Log
- 2026-08-24T12:29Z [claude-code] Captured by the 2026-08-24 sync sweep from the #platform-data-owners thread of 2026-08-21. Eshan's offer was explicit and time-bound ('later today'); three days on, gh reports zero reviewRequests on #6416 and #6131. Filed as needs-reply because a named person is waiting on Abhishek, not because the work is large.
