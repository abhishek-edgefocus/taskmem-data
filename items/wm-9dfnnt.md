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
updated: 2026-08-12T13:29:43Z
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
- 2026-08-10T18:53Z [claude-code] DECISION 2026-08-11 (Abhishek): do NOT add a MonitoringSchedule to northpond_purchase_tape_v0_csv yet — the real cadence is not settled (Nate said 'daily' but it is unknown whether that means 7-day or business-day, and no real file has ever landed to observe). Leaving the rule unmonitored deliberately, same as today. TRADE-OFF ACCEPTED: until a schedule exists, a purchase file that silently stops arriving raises no alert; detection is manual. REVISIT once a week or so of real landings shows the actual pattern, then set frequency=DAILY or WEEKDAY with start_date = the first real file's date (grace_days defaults to 3). Do not set start_date earlier than the first real file or it back-alerts for every prior day.
- 2026-08-11T08:48Z [claude-code] VERIFIED NOT LANDED — 2026-08-11 14:17 IST. Checked S3 directly (not inferred from Slack silence): aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive returns ONLY the two 2026-07-23 test stubs — purchase_file/v0/2026/07/purchase_file_v0_20260723_test.csv and the v1 twin. No 2026/08 prefix, no live file.
So Nate's target ('the plan/target is to produce the first live purchase file on Tuesday', 2026-08-08) has not been met as of mid-afternoon IST. Tuesday is US-hours, so it may still arrive tonight IST — this is not yet a slip, just not-yet.
Re-run the same one-liner before assuming anything landed. When it does, do this item and [[wm-jewha5]] in one pass, and note that [[wm-7qqeke]]'s fund fix (PR #6209) is still unmerged, so a file arriving right now would be attributed to efhyf.
- 2026-08-12T13:09Z [claude-code] Verified in S3 + prod 2026-08-12: the first REAL (non-_test) purchase files landed 2026-08-11 22:38 UTC on BOTH paths — purchase_file/v0/2026/08/purchase_file_v0_20260811.csv AND purchase_file/v1/2026/08/purchase_file_v1_20260811.csv. v0 ingested cleanly: bronze.statement_files status=rows_added statement_type=purchase_tape, and silver.northpond_stmt_purchase_tapes has 29 rows at AS_OF_DATE=2026-08-11, ACCOUNT_NAME=northpond_efhyf -> FUND=efhyf. v1 is correctly still status=ignore. v0 header matches the 21-col legacy schema exactly. v1 header confirmed different: oliv_loan_number (not loan_id), accrued_interest_on_purchase_date, principal_on_purchase_date, annual_interest, homeowner, vantage_score_v4, post_dti, days_past_due; and it DROPS borrower_income_annual, prism_cash_score, employment_tenure, application_uuid, remaining_term, interest_rate.
- 2026-08-12T13:29Z [claude-code] PROD RE-CHECK 2026-08-12 evening, extending the 18:39 entry with what the tape actually stored and what is still missing.
(1) FUND IS STALE ON THE 29 ROWS: silver.northpond_stmt_purchase_tapes holds them at AS_OF_DATE=2026-08-11, PURCHASE_DATE=2026-08-11, ACCOUNT_NAME=northpond_efhyf, FUND='efhyf'. PR #6209 merged 2026-08-11T21:48Z — after those rows were written — and its rule sends PURCHASE_DATE >= 2026-08-01 to edgex20261NN. So the tape needs a rebuild; tracked on [[wm-cqgb5n]].
(2) THE LOANS ARE NOT IN POSITIONS YET, AND THAT IS EXPECTED, NOT A BUG: 0 of the 29 loan ids (OLV12563552, OLV12563575, OLV12563554, OLV12563556, OLV12563557, ...) appear in silver.northpond_stmt_positions at any as_of. Nate explained the mechanism in DM the same night: 'No all of our loans are in either the NN or FCC files' / '(once onboarded)' / 'There can be a few day delay to get into the NN file but once there it's always there'. So the validation is not finished until they show up — worth re-checking in a few days.
(3) ONE ASK OF NATE WENT UNANSWERED. In C0BJ1M304BU Abhishek asked, before the live drop, 'is it possible for me to also take a look at today's issuance file which includes these loans?'. Nate's next message was 'confirming that we've uploaded live files' — the issuance file was never provided. Cross-checking the 29 purchases against the issuance file is still the cleanest validation available and it needs a re-ask.
(4) RESOLVED IN THAT THREAD, so no longer open: dti_ratio blank in v0 (Trishit 2026-08-12 00:11 'I don't think we use DTI in the model' then 'We don't use it anywhere'), and Nate committed to bring v0's DTI logic in line with v1 anyway. The dpd -> days_past_due rename question is moot for v0: the landed v0 header matches the 21-col legacy schema exactly.
