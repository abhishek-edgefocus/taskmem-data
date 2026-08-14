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
updated: 2026-08-14T19:56:16Z
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
- Nelnet: get PR #6277 reviewed today — Monday's cutover is the only hard deadline in here.
- Fund attribution: rebuild silver.northpond_stmt_purchase_tapes before the 29 loans land.
- Predictions: ship the one-line Dockerfile fix that is holding up the other two steps.

## Links
- Sub-thread — Nelnet servicer feed: [[wm-gj5tkx]]
- Sub-thread — fund attribution + first purchases: [[wm-4sxy5d]]
- Sub-thread — ANL retarget / prediction chain: [[wm-btu784]]
- DEV-1481 — https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction
- Project: [[wm-j523sq]]
