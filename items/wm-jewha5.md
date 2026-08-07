---
id: wm-jewha5
type: task
title: Re-check Oliv test purchase files route to ignore once 2026-07-28 stubs land in S3
status: next
priority: p2
size: xs
nudge: 2026-08-03
people: [Nate]
tags: [northpond]
links: [relates:wm-n7usn7]
created: 2026-07-28T17:28:34Z
updated: 2026-08-07T21:34:54Z
source: claude-code
---

Nate said 2026-07-28 15:49 UTC he was running test purchaser files right then, and
asked us to validate they are not flowing through. As of 17:27 UTC nothing new had
appeared under `s3://efp-raw/statements/northpond/purchase_file/` (still only the two
2026-07-24 stubs, both STATUS=ignore in prod bronze). The northpond SFTP->S3 sync had
already run at 16:36 UTC and saw nothing there.

WHEN THE NEW STUBS LAND, confirm in one pass:

1. `aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive`
2. PROD.BRONZE.STATEMENT_FILES for those keys -> expect STATUS='ignore', STATEMENT_TYPE/AS_OF_DATE/RULE_NAME NULL
3. PROD.BRONZE.STATEMENT_ROWS platform=northpond statement_type=purchase_tape -> still only the 6 x 2025 Pool events
4. PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES -> still 372 rows / 372 loans / 6 as_of_dates

Guard being relied on: the northpond-wide ignore rule
`r"s3://.*/statements/northpond/.*_test\.csv"`, FIRST entry in NORTHPOND_RULES
(find_matching_rule returns the first match). Only bites when Oliv keeps `_test`
immediately before `.csv`.

Verification already done on 2026-07-24 stubs + the full routing matrix is logged on
[[wm-n7usn7]] (2026-07-28 entry).

## Log
- 2026-07-28T17:40Z [claude-code] next -> waiting 2026-07-28: the next movement is Nate's, not ours. He said at 15:49 UTC (21:19 IST) he was running the test purchaser files 'at this moment' and asked us to validate they are not flowing through, but as of 17:27 UTC nothing new had landed under s3://efp-raw/statements/northpond/purchase_file/. Nothing to check until his files appear, so waiting on Nate with a nudge tomorrow rather than sitting in next as if it were actionable.
- 2026-07-29T13:41Z [claude-code] 2026-07-29T13:45Z RE-CHECK (~20h after Nate's 'running test purchaser files' message): NOTHING NEW LANDED, PROD STILL CLEAN.

S3: s3://efp-raw/statements/northpond/purchase_file/ still holds ONLY the two 2026-07-24 objects (purchase_file_v0_20260723_test.csv 1033 B, purchase_file_v1_20260723_test.csv 731 B). A full scan of the whole northpond prefix for 'purchase' and for 'test|latest' returns nothing else new — no 20260728/20260729 stubs at all. So whatever Nate ran on their side never reached Oliv's SFTP, hence never reached our mirror.

PROD UNCHANGED: bronze.statement_files — both stubs still STATUS=ignore (statement_type/as_of_date/rule_name NULL); purchase_file_legacy_20260723.csv still STATUS=unknown. bronze.statement_rows northpond/purchase_tape — only the 6 x 2025 Pool events (72/111/73/60/59/75), zero 2026. silver.northpond_stmt_purchase_tapes — 372 rows / 372 loans / same 6 as_of_dates. Byte-for-byte the same as the 2026-07-28 check.

PIPELINE IS ALIVE (so absence is real, not a stalled sensor): northpond registered 6 files on 2026-07-28 across three runs (05:43, 09:41, 11:42 PT). The 2026-07-29 loan tape + transaction tape landed in S3 at 13:38 UTC (06:38 PT) and were not yet registered at 13:40 UTC — that is the normal ~5 min lag, not a stall. Other platforms (lc, upgrade, prosper, anchored, openroad, sofi) all registered on 2026-07-29. The mirror demonstrably covers purchase_file/ since the 07-24 stubs arrived through it.

SLACK: no further message from Nate in C0BJ1M304BU since 2026-07-28 21:19 IST.

CONCLUSION: nothing to catch. The guard was never exercised by yesterday's run because no file arrived. Item stays waiting on Nate — either his test drop did not go to SFTP, or it goes to a path/environment we do not mirror. Worth asking him which, since 'we ran test files' with zero S3 arrival is itself information about their delivery path.
- 2026-07-29T13:44Z [claude-code] NUDGE FIRED 2026-07-29, still waiting. Re-read the full C0BJ1M304BU thread (parent ts 1785253752.403349): Nate posted at 21:19:12 IST 'we're running some of those test purchaser files at this moment' and at 21:19:28 'just calling out so you can validate they're not accidentally flowing through the system in any way'. There has been NO further message from him in that thread or that group DM since — the last message in the channel is still his 21:19 heads-up. So no new signal that the stubs landed; the S3/bronze checks in the body have not been re-run in this sweep.
Leaving status=waiting rather than flipping to next, because the trigger condition (new files under s3://efp-raw/statements/northpond/purchase_file/) is still unverified. Two ways to close it: run check 1 in the body directly, or ask Nate whether the test run actually produced files.
- 2026-07-31T12:56Z [claude-code] STILL WAITING, AND NOW WITH A REASON (2026-07-31). The trigger for this check was Nate's 07-28 test purchase files. Two days on, no purchase activity of ANY kind has appeared — a parallel session verified this on 07-30 ([[wm-n7usn7]]), and the business reason is now known: Trishit 2026-07-30 23:08 IST said Oliv is 'sort of already building a backbook but nothing so far on direct edgex bookings', with Dustin reporting a delay in account creation; Abhishek added that per Frank some platforms are deliberately waiting until Monday for next month's warehouse triggers.
So this is not Nate being slow — the files genuinely are not coming yet. The ignore-rule guard remains unexercised against real traffic. Practical read: fold this check into the first real purchase-file landing (expected Monday 2026-08-03) rather than nudging Nate again. Nudge moved accordingly.
- 2026-07-31T14:19Z [claude-code] Abhishek asked 2026-07-31 for a Monday reminder to validate the new EDGEX purchase tapes for Oliv — captured as [[wm-9dfnnt]] (due 2026-08-03). That item covers the real-traffic validation; this item's _test-ignore re-check should be done in the same pass when files land.
- 2026-08-07T21:14Z [claude-code] 2026-08-08 NATE ASKED FOR THE VERDICT — and it is available. Nate posted in C0BJ1M304BU at 2026-08-08 02:39 IST (ts 1786136943.015079): 'can you confirm that our test purchase files are good?' — the follow-up to his 07-28 21:19 heads-up ('validate they're not accidentally flowing through the system in any way').

RE-VERIFIED TODAY, PROD CLEAN: (1) S3 scan of s3://efp-raw/statements/northpond/ for 'purchase' returns 11 objects, newest still 2026-07-24 — ONLY the two stubs purchase_file/v0/2026/07/purchase_file_v0_20260723_test.csv (1033 B) and purchase_file/v1/2026/07/purchase_file_v1_20260723_test.csv (731 B). NOTHING from his 07-28 test run ever reached our mirror, and nothing has landed since. (2) PROD.BRONZE.STATEMENT_FILES: both stubs STATUS='ignore', statement_type/as_of_date/rule_name all NULL, loaded_at 2026-07-24 13:43:29 PT — the northpond-wide ignore rule s3://.*/statements/northpond/.*_test\\.csv is holding. purchase_file_legacy_20260723.csv (107134 B) still STATUS='unknown' (PR #6011 not merged). (3) PROD.BRONZE.STATEMENT_ROWS northpond/purchase_tape: still only the 6 x 2025 Pool events (72/111/73/60/59/75), zero 2026. (4) PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES: still 372 rows / 372 loans / 6 as_of_dates (2025-02-05..2025-06-17). Zero contamination.

BALL IS BACK WITH US — flipping waiting -> next. Reply drafted for Abhishek to send (agent does not post).
- 2026-08-07T21:23Z [claude-code] 2026-08-08 SCHEMA REVIEW OF THE TWO _test STUBS (Abhishek clarified Nate's ask is about SCHEMA, not just routing). Pulled both files from S3 and diffed against NorthpondStmtPurchaseTapes.COLUMNS.

V0 SCHEMA IS AN EXACT MATCH: purchase_file_v0_20260723_test.csv header is 21 cols, identical NAMES AND ORDER to the silver source columns (loan_id, loan_amount, purchase_date, funding_date, origination_fee, accrued_interest_as_of_funding_date, vantage_score, outstanding_principal_balance_as_of_funding_date, is_home_owner, original_term, remaining_term, interest_rate, borrower_income_annual, dti_ratio, credit_grade, state, modified, dpd, application_uuid, prism_cash_score, employment_tenure). Same header as the legacy 589-row file. 4 data rows (OLV12563419-422). Nothing to change on our side for v0.

V0 VALUE PROBLEMS (stub artifacts, but must be real on live files): (1) accrued_interest_as_of_funding_date = 1 on EVERY row and outstanding_principal_balance_as_of_funding_date = 2 on EVERY row — placeholders, not amounts (legacy real row had 4.38 / 915.31). outstanding_principal drives TAPE_PRINCIPAL and transfer amounts. (2) dti_ratio = unquoted NULL on every row, yet v1 carries a real post_dti (0.1197/0.0437/0.1880/0.2533) for the SAME loans — so the value exists on Oliv's side but v0 does not populate it. (3) FILENAME/CONTENT DATE SKEW: file is _20260723_test.csv but every purchase_date inside is 2026-07-24 (Nate renamed the file to 'yesterday' on 07-24 without changing content). Our as_of_date comes from the FILENAME, so a real file with that skew lands under the wrong as_of_date. (4) The same 4 loans appear in v0 and v1 with CONTRADICTORY funding_dates — v0 says 2026-07-22/23, v1 says 2026-07-25 for all four, and v1's funding_date is AFTER its purchase_date (2026-07-24), which is backwards. (5) numeric quoting inconsistent across fields (harmless, we read dtype=str, but signals an unstable generator).

V1 NOT INGESTIBLE AS-IS (already ignored by rule): 17 cols. Renames 9 — oliv_loan_number->loan_id, accrued_interest_on_purchase_date->accrued_interest_as_of_funding_date, principal_on_purchase_date->outstanding_principal_balance_as_of_funding_date, annual_interest->interest_rate, homeowner->is_home_owner, vantage_score_v4->vantage_score, post_dti->dti_ratio, days_past_due->dpd, and a column literally named 'coalesce' (value 36 == original_term, almost certainly an unaliased COALESCE(remaining_term, original_term)). DROPS 4 columns silver reads: borrower_income_annual, application_uuid, prism_cash_score, employment_tenure. Also shifts semantics from funding-date to purchase-date on the accrued-interest/principal pair, and post_dti is post-loan DTI, a different measure from dti_ratio.

CORRECTION TO MY EARLIER ENTRY TODAY: I wrote that PR #6011 was unmerged and that this blocked legacy-path ingestion. Wrong on both counts. #6011 merged 2026-07-24T11:46:47Z, and master has since SUPERSEDED the purchase_file_legacy/ path entirely — origin/master b08aace7b now has rule northpond_purchase_tape_v0_csv on s3://.*/statements/northpond/purchase_file/v0/\\d{4}/\\d{1,2}/purchase_file_v0_(?P<date>\\d{8})(_\\d+)?\\.csv (priority=1), an explicit ignore rule on purchase_file/v1/.*\\.csv, and the _test ignore as the FIRST rule. purchase_file_legacy_20260723.csv sitting at STATUS='unknown' is therefore EXPECTED (its rule was removed, Oliv abandoned that path), not a defect. Note the dpx working copy ~/repos/efp is parked on branch abhishek/dev-1393-fixes-in-openroad-positions and is stale — read origin/master, not the worktree.
- 2026-08-07T21:34Z [claude-code] 2026-08-08 PRIOR-THREAD CROSS-REFERENCE (C0BJ1M304BU, 2026-07-20 -> 07-28). Nate's 08-08 'are our test purchase files good?' is the close-out of a schema negotiation that is already fully on record, and it has FOUR UNANSWERED QUESTIONS sitting in it — three of them OURS, unanswered by Nate since 2026-07-23.

WHAT WAS AGREED: (a) Abhishek 07-23 16:54 listed the exact v1 renames (loan_id->oliv_loan_number, vantage_score->vantage_score_v4, is_home_owner->homeowner, dti_ratio->post_dti, dpd->days_past_due, accrued_interest_as_of_funding_date->accrued_interest_on_purchase_date, outstanding_principal_balance_as_of_funding_date->principal_on_purchase_date) and the 4 dropped columns (application_uuid, borrower_income_annual, prism_cash_score, employment_tenure) and asked Oliv to keep sending the legacy layout. (b) Nate 07-23 17:16 offered OPTION 2a — generate the standard file AND a legacy-shaped copy — and said 'the missing fields (ASIDE FROM AGI) are not ones we would likely populate for other purchasers'. (c) Abhishek 07-23 18:32 accepted 2a. (d) Nate 07-23 23:56 stated the grain: 'A given loan should appear on only one file ever' — this is the incremental/no-dupes confirmation wm-n7usn7 had only second-hand from Abhishek; it is now sourced in-channel. (e) Nate 07-24 18:09 finalised paths v0=legacy schema, v1=new, plus regular _test stubs, and 07-24 18:12 stated the stubs' PURPOSE: 'to be 100% confident what our engineering team is implementing right now matches your expectation (as far as schema)'. So the 08-08 question is exactly that sign-off request.

V0 HONOURS THE AGREEMENT — verified against the file: all four 'dropped' columns are present AND populated (application_uuid, borrower_income_annual 65000.00, prism_cash_score 259, employment_tenure 60), and loan_id keeps the OLV prefix Abhishek said was fine to retain. The ONLY column of ours empty in v0 is dti_ratio (unquoted NULL on all 4 rows) while the SAME loans carry a populated post_dti in v1 — so their generator maps post_dti into v1 but does not map it back into v0's dti_ratio. That is a mapping bug, not missing data.

V1 CONTRADICTS NATE'S OWN COMMITMENT: he said the standard file would still carry AGI, but the v1 stub has NO income column at all (17 cols, no borrower_income_annual / annual_gross_income equivalent). Worth raising directly.

STILL UNANSWERED FROM 07-23 18:32 (Abhishek asked, never answered): (1) 'by AGI you mean borrower_income_annual — and that is the one you'd keep providing?' — v0 answers it implicitly, v1 does not. (2) Trishit was asked whether employment_tenure is needed on the purchase tape for modelling — no reply in channel; v0 ships it anyway. (3) 'Is principal_on_purchase_date the same number as today's outstanding_principal_balance_as_of_funding_date? It feeds our transfer amounts.' — STILL OPEN and the stubs CANNOT answer it (v0 flat 2, v1 flat 1). This is the single most important open item because it drives TAPE_PRINCIPAL/transfers. ALSO UNANSWERED BY US: Nate 07-23 23:56 'we'll produce a daily purchase file (both legacy and new) and upload to sftp each day. Does this match your understanding?' — never confirmed, and master deliberately has NO MonitoringSchedule on northpond_purchase_tape_v0_csv pending exactly that confirmation.

DO NOT re-ask items 1 and 3 as if new — reference them as outstanding since 23 July.
