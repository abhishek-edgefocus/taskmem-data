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
links: [parent:wm-gj5tkx]
created: 2026-08-14T13:52:50Z
updated: 2026-08-18T18:25:13Z
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

## Log
- 2026-08-14T13:52Z [claude-code] Created 2026-08-14 during the intake sweep from the Nate DM (D0BAD46CT27) exchange of 2026-08-14 01:33-02:05 IST. Waiting on Nate/Oliv for the go-live signal; nudge set to Monday.
- 2026-08-17T09:54Z [claude-code] 2026-08-17 09:53 UTC CUTOVER HAS NOT HAPPENED. Checked S3 directly: s3://efp-raw/statements/northpond/nelnet/daily_loan/2026/08/ and daily_transaction/2026/08/ still end at 2026-08-16 in the OLD formats (VELOCITY_SERVICING_DF2_20260816_* and V_Transaction_Detail_Export_Daily_OlivFinancial_2026-08-16-*.xlsx). No olivfinancial_* keys on either prefix. Today's drop had not landed yet at check time - these files land ~12:37 UTC, so 08-17 was still ~3h out; re-check after 13:00 UTC before pinging Nate. Raw PII keeps arriving meanwhile (see wm-8dy9jr). Also noted: purchase_file/v0 is WEEKDAY-ONLY - last file is purchase_file_v0_20260814.csv, nothing on 08-15/08-16, so the gap is the weekend and not a miss.
- 2026-08-17T14:04Z [claude-code] 2026-08-17 14:03 UTC — CUTOVER STILL HAS NOT HAPPENED, and today's files HAVE landed. s3://efp-raw/statements/northpond/nelnet/daily_loan/2026/08/ shows VELOCITY_SERVICING_DF2_20260817_20260817_030211. (uploaded 13:06 UTC) and daily_transaction shows V_Transaction_Detail_Export_Daily_OlivFinancial_2026-08-17-05-28-45_20260817_060207.xlsx — both still the OLD formats. No olivfinancial_* keys on either prefix. So Monday 2026-08-17, the target Nate and Abhishek agreed on 08-14, has slipped: the day's drop arrived on schedule but in the pre-cutover format. Time to ping Nate in the DM (D0BAD46CT27). SEPARATELY, purchase_file_v0_20260817.csv DID land at 13:39 UTC (2,770 bytes) — a new EDGEX purchase batch, first since 08-14 (08-15/16 were the weekend; purchase files are weekday-only).
- 2026-08-17T15:38Z [claude-code] 2026-08-17 ~15:40 UTC (21:07 IST) — Nate DM'd that he manually uploaded today's loan file via SFTP (GitHub deploy was down, blocking the normal automated push) and asked to double-check it works; said no transaction file today since there were no transactions. Re-checked s3://efp-raw/statements/northpond/nelnet/daily_loan/2026/08/ (recursive, filtered to 2026-08-17) immediately after: still only the old-format VELOCITY_SERVICING_DF2_20260817_... key from the 13:06 UTC automated drop. Nate's manual SFTP upload has NOT synced into efp-raw yet. Likely needs the SFTP->S3 sync job to run again (it already ran for today) or a manual trigger. Do not tell Nate it 'worked' until a new key actually lands.
- 2026-08-18T18:25Z [claude-code] 2026-08-18 ~18:15 UTC — Backfill landed. olivfinancial_loan_*.csv complete for every day 08-01 through 08-18 (18 consecutive files, all written 18:13:13 UTC for the 08-01..08-16 range). olivfinancial_transaction_*.csv covers 08-01..08-16 and 08-18, missing only 08-05, 08-10 and 08-17 — Abhishek confirmed with Nate these three are zero-transaction days (consistent with the 08-17 case already logged above where Nate said the same thing), not sync gaps. Old-format files (VELOCITY_SERVICING_DF2_*, V_Transaction_Detail_Export_*.xlsx) still sit in the same prefixes for those dates but are ignore=True in the parsing rules, so they don't matter. Backfill chase is complete — nothing further to ask Nate. Next: run these through the pipeline (bronze parse -> silver) as end-to-end verification, same drill as the earlier PR #6323/#6324 verification passes.
