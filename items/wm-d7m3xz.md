---
id: wm-d7m3xz
type: task
title: EDGEX 2026-1NN deal readiness (Oliv)
status: active
priority: p1
size: xl
people: [Nate, Trishit, Abhijeet]
tags: [northpond, edgex, oliv]
links: [parent:wm-j523sq]
refs: [DEV-1481=https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction]
created: 2026-08-14T19:56:08Z
updated: 2026-09-11T14:26:12Z
source: claude-code
label: EDGEX deal readiness
---

Umbrella for everything the EDGEX 2026-1NN deal needs from the Oliv/NorthPond side. Created
2026-08-15 on Abhishek's instruction — he asked for the Oliv work to be clubbed into two or three
threads rather than a dozen loose items, with "everything required for the EDGEX deal, including
the Nelnet files" as one of them.

WHAT THE DEAL ACTUALLY NEEDS, and why these three workstreams and not others. EDGEX buys Oliv
loans; for that to be reportable we need three independent things true at once:
  - the loans have to REACH us — that is the Nelnet servicer feed, replacing FCC, which is also
    the only feed carrying the investor tag that resolves INV103 vs INV105;
  - they have to be attributed to the RIGHT FUND — prod currently serves the same fund under two
    names and the first 29 EDGEX purchases on the wrong one;
  - they have to carry an EF GRADE, which is what the deal consumes — and the ANL retarget left
    33 loans with scores derived from un-retargeted cashflows, roughly 10 of them in the wrong
    bucket.

THE THREE SUB-THREADS RUN IN PARALLEL, deliberately. There is no dependency between them and
inventing one would make every chain view lie. What differs is urgency, and it is worth reading in
this order:
  1. Nelnet cutover — hard external date. Oliv go live Monday 2026-08-17.
  2. Fund attribution — time-sensitive for a subtler reason: the 29 purchased loans have not yet
     appeared in silver positions, and the moment they do, positions and transfers start
     disagreeing. Rebuilding first avoids the disagreement instead of repairing it.
  3. Prediction chain — no external date, but it is three deep and nothing in it has moved since
     2026-08-05, because the first step has failed on every prod run since then.

Each sub-thread renders its own ordered checklist; this level is a portfolio, not a sequence, so
do not read its step numbers as an order.

## Next steps
Rewritten 2026-08-24: the previous three steps were all overtaken by events (PR #6277 was
closed rather than merged, the cutover date passed, and the fund rebuild is done). See the
2026-08-24 log entry for the evidence. Sub-threads 1 and 2 are now closed out; everything
live is in sub-thread 3.
- Predictions: ship the one-line Dockerfile fix (.efp_toplevel missing from
  orchestration/Dockerfile) that has northpond_exp_predictions failing every run — [[wm-te4cr2]].
- Predictions: build + promote the oliv_exp_statement_model artifact, then re-run
  northpond_api_predictions to drop the stale exp api rows — [[wm-3rsskm]].
- Predictions: force silver.ef_scores to re-derive the 33 stale Oliv loans after the ANL
  retarget — [[wm-vye9hn]].
- Landed, no action: Nelnet cutover (PRs #6323 + #6324 merged) and fund attribution (all 265
  EDGEX loans read FUND=edgex20261NN, loan-level verified — [[wm-9dfnnt]]).

## Links
- Sub-thread — Nelnet servicer feed: [[wm-gj5tkx]]
- Sub-thread — fund attribution + first purchases: [[wm-4sxy5d]]
- Sub-thread — ANL retarget / prediction chain: [[wm-btu784]]
- DEV-1481 — https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction
- Project: [[wm-j523sq]]

## Log
- 2026-08-24T12:28Z [claude-code] SWEEP 2026-08-24 — THE STORED NEXT STEP ON THIS ITEM IS STALE AND WOULD MISLEAD ANYONE PICKING IT UP. It reads 'Nelnet: get PR #6277 reviewed today — Monday's cutover is the only hard deadline in here.' PR #6277 is CLOSED, not open: it was superseded rather than merged, and the Nelnet work actually landed as PR #6323 (Ingest Oliv's Nelnet servicer feeds into silver, merged 2026-08-17) and PR #6324 (Merge the Nelnet loans into standardized positions and transfers, merged 2026-08-19). The Monday cutover it refers to was 2026-08-17 and has passed. Recorded here rather than rewritten into the body, since the body is a snapshot of what was true when written.

CURRENT STATE OF THE THREE SUB-THREADS, as of this sweep:
1. Nelnet cutover — landed. #6323 and #6324 both merged.
2. Fund attribution — resolved and verified. All 9 business days of EDGEX purchase tapes (08-11..08-21, 265 loans) now read FUND=edgex20261NN in PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES, including the original 29 that were written as efhyf before PR #6209 merged. The concern in the body that 'positions and transfers start disagreeing the moment the purchased loans appear' did not materialise — counts match at 265. Detail on wm-9dfnnt.
3. Prediction chain — this is the one that has NOT moved and is now the live edge of this item. Still tracked on wm-btu784 and wm-3rsskm.

So the umbrella's centre of gravity has shifted entirely to sub-thread 3; whoever picks this up next should start there, not at Nelnet.
- 2026-08-24T15:00Z [claude-code] Rewrote the ## Next steps section (the Log is untouched). All three prior steps were stale and the first one — 'get PR #6277 reviewed today' — was being surfaced verbatim in every SessionStart digest, so the memory was actively pointing Abhishek at a closed PR and an expired deadline several times a day. Replaced with the three live prediction-chain steps and an explicit 'landed, no action' line so the closed sub-threads stay visible rather than looking forgotten.
- 2026-09-11T14:26Z [claude-code] Sync 2026-09-11: Nate + Abhishek huddle in DM D0BAD46CT27 on 2026-09-10 19:01 IST (rescheduled from Nate's ask 'can we do 30min later tomorrow?'). Abhishek's stated agenda: 'discuss the overall integration plan and what all things are we looking forward to from the dev perspective'. Huddle — no transcript, outcome unknown; ask Abhishek what was agreed before treating any Oliv integration item as moved. Possibly overlaps wm-xmufr2 (the Trishit + Nate call) — unverified.
