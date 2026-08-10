---
id: wm-9dfnnt
type: task
title: Validate the new EDGEX purchase tapes for Oliv (first real landing)
status: next
priority: p1
size: s
due: 2026-08-11
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [relates:wm-jewha5, relates:wm-n7usn7, relates:wm-tvjjgw]
created: 2026-07-31T14:19:39Z
updated: 2026-08-10T14:38:01Z
source: claude-code
---

Abhishek asked (2026-07-31) to be reminded to validate the new EDGEX purchase tapes
for Oliv on **Monday 2026-08-03** — the first real Oliv purchase files are expected
then (per Frank, some platforms deliberately waited until Monday for next month's
warehouse triggers; Trishit 2026-07-30: Oliv is building a backbook but nothing on
direct EDGEX bookings yet, with Dustin reporting delayed account creation).

This is the REAL-traffic counterpart to [[wm-jewha5]] (which checks that Nate's
`_test` stubs are correctly ignored). Do both in one pass when files land.

What to validate when the tapes arrive:
1. `aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive` — confirm
   real (non-`_test`) files landed at the finalised `purchase_file/v0` path
   (routing matrix logged on [[wm-n7usn7]]).
2. PROD.BRONZE.STATEMENT_FILES — real files should be STATUS=processed with
   statement_type=purchase_tape / correct as_of_date / rule_name set (NOT 'ignore');
   any `_test` files alongside them must still be STATUS=ignore.
3. PROD.BRONZE.STATEMENT_ROWS platform=northpond statement_type=purchase_tape —
   new 2026 rows beyond the 6 x 2025 Pool events.
4. PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES — row/loan counts move past
   372 rows / 372 loans / 6 as_of_dates.
5. EDGEX investor IDs on the new rows: EDGEX Purchaser I = INV105, EDGEX Grantor
   Trust = INV103 — see [[wm-5z3pjt]] for the fund mapping.
6. Legacy datastore feed — the legacy StatementPurchaseTape path that EDGEX ABS
   still reads must not silently starve as Oliv moves files ([[wm-tvjjgw]]).

## Log
- 2026-08-05T22:17Z [claude-code] 2026-08-06 S3 CHECK: STILL NOTHING NEW. Full scan of s3://efp-raw/statements/northpond/ for 'purchase' returns 11 objects, newest 2026-07-24: purchase_file/v0/2026/07/purchase_file_v0_20260723_test.csv (1033 B), purchase_file/v1/.../purchase_file_v1_20260723_test.csv (731 B), purchase_file_legacy/2026/07/purchase_file_legacy_20260723.csv (107134 B). Everything else is historical: 6 x 2025 'Pool N Loan Purchase File' xlsx under purchase_tape/ (uploaded 2026-03-09) + 2 x purchase_tape_efhyf_*.csv (2025-02/03). Prod unchanged: bronze.statement_rows northpond/purchase_tape still only the 6 x 2025 as_of_dates (72/111/73/60/59/75); silver.northpond_stmt_purchase_tapes still 372 rows / 372 loans / 6 as_of_dates (2025-02-05..2025-06-17). So the expected Monday 2026-08-03 first real EDGEX purchase-file landing did NOT happen — nothing to validate yet.
- 2026-08-07T21:14Z [claude-code] 2026-08-08 S3 + PROD RE-CHECK: STILL NOTHING REAL. Newest purchase object under s3://efp-raw/statements/northpond/ is still 2026-07-24 (the two _test stubs + purchase_file_legacy_20260723.csv). Bronze rows unchanged (6 x 2025 Pool events), silver unchanged (372 rows / 372 loans / 6 as_of_dates). The expected 2026-08-03 first real EDGEX purchase-file landing has now slipped 5 days with zero arrivals. Prompted by Nate asking in C0BJ1M304BU 2026-08-08 02:39 IST whether the test purchase files are good — see [[wm-jewha5]] for the full verification + the drafted reply.
- 2026-08-10T14:38Z [claude-code] NATE SET A LIVE DATE (C0BJ1M304BU, 2026-08-08 17:01 IST, ts 1786188718.575029): 'the plan/target is to produce the first live purchase file on Tuesday. We will finish setting up proper values for some fields that currently have stubs/placeholders (accrued interest, etc)'. Tuesday from that Saturday = 2026-08-11, i.e. TOMORROW relative to today 2026-08-10. This is the first real purchase file since Pool 6 (June 2025) and it lands at purchase_file/v0/2026/08/purchase_file_v0_YYYYMMDD.csv, ingested by rule northpond_purchase_tape_v0_csv.
Context: Abhishek sent the v0 sign-off 2026-08-08 03:15 IST ('the v0 file looks good - schema matches exactly what we ingest. We're on v0 for now and will move to the v1 schema later'); Nate reacted :thankyou:. Nate's stub-fix note covers accrued_interest and by implication outstanding_principal_balance_as_of_funding_date, but he did NOT mention the empty dti_ratio or the filename/content date skew (file named _20260723_ while purchase_date inside was 2026-07-24) — both still worth watching on the first live file.
