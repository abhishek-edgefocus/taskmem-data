---
id: wm-f7egzv
type: followup
title: Request Eshan as reviewer on the open PRs he offered to review
status: done
priority: p1
size: xs
due: 2026-08-24
people: [Eshan]
tags: [northpond, needs-reply]
links: [relates:wm-u52nd6, relates:wm-gp7g82]
created: 2026-08-24T12:28:37Z
updated: 2026-08-31T15:47:54Z
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
- 2026-08-24T15:00Z [claude-code] STILL UNDONE AS OF 2026-08-24 14:5xZ, and the backlog it applies to has grown. #6416 is unchanged since 08-22 — still draft, still zero reviewers, CI still green. Abhishek's new PR #6454 (DEV-1638, his stated #1 for today) was raised at 14:48Z and is ALSO draft with no reviewer.

Full picture of his open PRs today: 6454 (draft, new), 6416 (draft, green, blocked only by draft), 6223 (not draft, CHANGES_REQUESTED, needs a re-review request), 6131 (draft, 24 days stale, needs a base retarget - wm-gp7g82), 5967 (draft since 2026-07-20, tracked on wm-7mtzka), 5925 (draft since 2026-07-17, tracked on wm-unb6pr). Four of the six are drafts that no one can act on, and one willing reviewer has been waiting three days to be assigned.
- 2026-08-26T13:11Z [claude-code] PARTIALLY SATISFIED 2026-08-26, and the shape of what is left has changed — read before working it.

WHAT GOT FIXED: PR #6416 is out of draft and now has THREE reviewers requested (samueli-efp, kabeer0022, nakula-efp). The core purpose of this item — a green PR sitting invisible with nobody able to review it — no longer applies to #6416. Tracked on wm-u52nd6, which is now status=waiting on those three.

WHAT DID NOT HAPPEN: Eshan was not among them. His 2026-08-21 offer ('Mujhe review assign kar dena') is still untaken five days on. Not necessarily wrong — three reviewers is enough for one PR — but the offer was specific and he has been left hanging, which is worth a one-line reply either way.

WHAT IS NEW AND IS NOW THE SHARPER HALF: PR #6459 (DEV-1666, OpenRoad ITD / dedup / IS_JOINT) came OUT of draft on 2026-08-26 12:40Z with ZERO reviewers requested and mergeStateStatus=BLOCKED. That is the identical failure this item was created for, one week later on a different PR. Logged on wm-sn2x5s too.

CURRENT PR PICTURE: 6491 (draft, DEV-1510), 6462 (draft, DEV-1498), 6459 (OUT of draft, NO reviewers - act on this), 6454 (still draft, DEV-1638), 6416 (out of draft, 3 reviewers, waiting), 6131 (draft, 26 days, needs base retarget - wm-gp7g82), 5967 (draft since 2026-07-20 - wm-7mtzka). Note 5925 has closed since the last sweep.

REVISED ACTION: request reviewers on #6459, and give Eshan an answer on his offer. #6416 needs nothing further from him.
- 2026-08-31T15:47Z [claude-code] DONE 2026-08-31 — verified against GitHub, not inferred. The reviewer gap this item was opened for is closed on every PR it named.

- #6416: MERGED 2026-08-27T16:33Z (approved). The 'take it out of draft first' step in this item is now moot.
- #6459 and #6454 both carry three requested reviewers as of 2026-08-26: eshan-edgefocus, abhijeet-edgefocus, sanjali-efp. Eshan was assigned, which was this item's whole ask.
- Abhishek chased them directly in DM 2026-08-26 23:20 IST: 'Hya PR aaj / udya madhe baghshil ka? Eshan la pan assign kelyat.' Abhijeet answered 'Sanjali la taak as reviewer, she is familiar with autos' — which is where sanjali-efp came from, and Abhishek +1'd it.
- #6459 was reviewed by Scott (3 inline comments 08-26, all three answered the same evening) and APPROVED 2026-08-26T20:37Z, then merged 08-27.

WHAT DID NOT GET FIXED BY THIS, and is now carried on [[wm-skvqac]] instead: #6454 has had three reviewers requested for five days and ZERO reviews. Requesting is not reviewing.
