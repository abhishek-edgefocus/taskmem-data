---
id: wm-3vkbn9
type: followup
title: Wait for Oliv's Nelnet cutover signal, then chase the agreed backfill to 2026-08-11
status: waiting
size: xs
due: 2026-08-17
waiting_on: Nate
nudge: 2026-08-17
people: [Nate]
tags: [northpond, edgex, nelnet]
created: 2026-08-14T13:52:50Z
updated: 2026-08-14T13:52:55Z
source: claude-code
label: Nelnet cutover + backfill
---

Two loose ends from the 2026-08-14 Nate DM exchange, both now in Oliv's hands.

1. THE CUTOVER SIGNAL. Nate asked "Any concerns if this is live next week?" and noted "We
typically try to avoid deploys Thursday evening into the weekend." Abhishek replied "Ingestion is
dev ready on our end, so just let us know when they start flowing" and "I think we should be good
to wait till Monday." So Oliv switch to the PII-free `olivfinancial_loan_YYYYMMDD.csv` /
`olivfinancial_transaction_YYYYMMDD.csv` exports and tell us; nothing moves on our side until they
do. Monday 2026-08-17 is the target, not a date Nate committed to in those words.

2. THE BACKFILL. Abhishek: "I think it'd be a good idea to backfill both the loan and transaction
files in the new format from the day we received the first purchase file." That day is 2026-08-11
(purchase_file_v0_20260811.csv, the first real purchase file). Nate: "We can definitely backfill
after we go live." Agreed in principle, no date, and it will not happen unless we ask again after
the cutover — the whole EDGEX position history from first purchase depends on it.

Watch for silence: as of 2026-08-14 12:38 the old-format VELOCITY_SERVICING_DF2_* and
V_Transaction_Detail_Export_*.xlsx files were still landing, so nothing has switched yet. Every day
the cutover slips is another day of raw PII arriving in efp-raw ([[wm-8dy9jr]]).

## Next steps
- Monday 2026-08-17: check s3://efp-raw/statements/northpond/nelnet/daily_loan/2026/08/ and
  .../daily_transaction/2026/08/ for the first `olivfinancial_*` keys.
- If they have not appeared by Monday evening IST, ping Nate in the DM.
- Once they are flowing and PR #6277 is deployed, ask Nate to run the backfill from 2026-08-11 and
  confirm which dates he actually re-dropped.

## Links
- Nate DM thread (huddle-time message in the same exchange): https://edgefocuspartners.slack.com/archives/D0BAD46CT27/p1786637376410839
- Feed work item: [[wm-gj5tkx]]
- PR that must be merged first: [[wm-g8p2m2]]
