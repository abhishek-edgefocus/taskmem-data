---
id: wm-tvjjgw
type: task
title: Legacy northpond datastore will silently starve as Oliv moves files (blocks EDGEX ABS)
status: next
priority: p1
size: m
tags: [northpond, datastores, oncall]
links: [related:wm-gxykru]
created: 2026-07-28T13:40:28Z
updated: 2026-07-30T15:40:48Z
source: claude-code
---

Raised by Abhishek 2026-07-28: "we are probably gonna do a lot of changes in NorthPond, I believe all this will cause this old pipeline to break." Checked — he is right, and nothing tracks it.

## The setup
The legacy northpond datastore (lib/efp/stats/datastores/northpond/) is still the source for the EDGEX investor ABS datasets: DatastoreStandPosFirstPassNorthpond -> DatastorePositions -> abs_data_requests.load_datasets() -> bin/abs_datasets_job.py. See [[wm-gxykru]] for why the DEV-1450 deprecation does not change this (routing is opt-in, has zero callers, and is single-platform while EDGEX calls all 7 at once).

## Feed 1 — PURCHASE TAPE, breaks first and matters most
Legacy StatementPurchaseTape is pinned to the OLD shape: STATEMENTS_S3_BUCKET='efp-derived', INCLUDE_PATTERN='*Loan Purchase File & Bulk Pool Purchase Agreement *{DATE}.xlsx', fed by mirror_trade_files.py TRADES['northpond_ff'] from Google Drive folder 1yztwMwTBw9ayQd2XjcuQyiU97v89YVUr, regex '^Pool (\d+) Loan Purchase File & Bulk Pool Purchase Agreement (\d{8}).xlsx$'.
DEV-1474 ([[wm-n7usn7]], PR #6011) moves the purchase tape to Oliv SFTP -> s3://efp-raw/statements/northpond/purchase_file_legacy/YYYY/MM/purchase_file_legacy_{date}.csv, and Abhishek closed out the cutover question with "only CSVs expected going forward, no parallel xlsx feed". The DEV-1474 scope note says explicitly: "lib/efp/stats/datastores/northpond/statement_purchase_tape.py: leave alone (deprecated datastore path, xlsx-only)".
=> When the xlsx stops, the legacy purchase tape FREEZES. It does not error — it just stops seeing new purchases.
WHY THAT PROPAGATES: legacy statement_loan_positions.py:154 and statement_loan_transactions.py:50 both call get_datastore_data(StatementPurchaseTape) for fund/account classification — the legacy twin of silver's FUND_WITH_PURCHASE_TAPE_EXPR. A frozen purchase tape means new EFHYF loans never get classified as efhyf in the legacy positions/transactions, so they are misfunded or missing in the investor deliverable. Silent.

## Feed 2 — ISSUANCE, breaks on the ID type
Legacy StatementLoanIssuance reads issuance/YYYY/MM/issuance_*{DATE}*.csv with loan_id typed pd.Int64Dtype(). DEV-1468 ([[wm-fzbz7m]], PR #5993, merged 2026-07-24) notes v2 "drops the integer loan_id for the OLV-prefixed oliv_loan_number (same key as the purchase file)". An Int64 column cannot hold 'OLV12562550'. So the day Oliv retires issuance v1, the legacy issuance reader breaks outright rather than silently — DatastoreStandPosFirstPassNorthpond takes first_payment_due_date from it.

## Feed 3 — DAILY LOAN TAPE, watch only
StatementLoanPositions reads loan_tape/YYYY/MM/ffcnp_dailyloantape_*{DATE}*.csv. Unchanged so far, but it sits on the same Oliv SFTP tree being restructured, and Nate warned filenames/folders will change "as we enter into more programs". Also note base_statement_northpond.explode_pathname asserts on r'.*_(\d{8}).*.csv' and hardcodes account 'ef_northpond' + MMDDYYYY parsing — brittle to any renaming.

## The actual decision Abhishek needs to make
Every DEV-1474 / DEV-1468 change is silver/Snowflake-side by design; nobody has touched the legacy readers. Meanwhile DEV-1457 (migrate abs_datasets_job off 16 datastores) is HIGH priority and has not started since 2026-07-17, and no cfframe datastore has any Snowflake path at all. So legacy northpond is on track to lose its inputs BEFORE its consumer is migrated. Options:
(a) Point legacy StatementPurchaseTape at the new csv too (keeps legacy alive, costs a small PR) — this is also the natural companion to [[wm-gxykru]]/#5704.
(b) Accept legacy northpond going stale and escalate DEV-1457 so EDGEX moves off it first.
(c) Do nothing and let the investor deliverable silently degrade — the current default, and the reason this item exists.
Not a decision to make silently either way.

## Verification note
All paths/patterns above read off origin/master on 2026-07-28. The xlsx-stops premise comes from Abhishek's own DEV-1474 closeout, not from Oliv directly — worth confirming a cutover date with Nate.

## Log
- 2026-07-30T15:40Z [claude-code] CORRECTION + CONCRETE BLOCKER AUDIT for abs_datasets_job.py (the file Chandra named in his last DEV-503 comment, 2026-06-26). Abhishek pushed back that backwards compat is good and it should be near a one-word change. He is MOSTLY RIGHT, and DEV-1457's framing — repeated by me earlier — is misleading.

WHAT I GOT WRONG: I said the cfframes 'have no Snowflake version, the code was never written'. The ADAPTER was never written; the TABLES exist and are populated. Correcting that here so it does not propagate.

ENUMERATED OFF origin/master 2026-07-28 (git grep over lib/efp/stats/edgex/, non-test): EDGEX constructs exactly 7 Datastore* classes — DatastorePositions, DatastoreTransfers, DatastoreCfframe, DatastoreCfframeFromPurch, DatastoreCalendarMonthCfframe, DatastorePredCfframeFromPurch, DatastoreSimPredCfframeFromPurch — plus 7 platform Statement* readers (lc StatementStatic, marlette StatementOriginations, upgrade StatementLoanCreditAttr, sofi StatementPlServicingReport + StatementPurchaseTape, happymoney StatementLoanBook + StatementLoanOriginations) = 14 distinct classes. Note DatastoreTransactions — one of only two classes with Snowflake support — is NOT used by EDGEX at all.

DATA SIDE (exists in Snowflake):
- silver.positions — yes, and lendingclub IS built (edgefocus/transformations/silver/statement_rows/lendingclub/ has positions.py, transactions.py, transfers.py, stmt_positions.py, stmt_loan_static.py, stmt_activity.py, manager_marks.py).
- silver.transfers — yes, and EDGEX ALREADY queries it directly at abs_data_requests.py:417 for EVENT_TYPE='transfer'.
- silver.realized_cashflows_from_purchase — yes, terraform + per-platform builders for happymoney, marlette, northpond, prosper, sofi, upgrade. CARRIES VALID_MASK as a column, which is precisely what DEV-1457 says EDGEX needs ('.cfframe(ids) to get the realised cashflow frame AND its valid mask'). Grain is EFP_ID x MOB with BOP/EOP principal, accrued interest, payments, chargeoff, recovery, DPD, delinquent-principal buckets, EOP_STATUS.
- silver.realized_cashflows_from_origination, silver.realized_cashflows_calendar_month, silver.realized_cashflows_from_first_purchase — same 6 platforms each.
- silver.predicted_cashflows_from_purch + gold_predicted_cashflows_mob/_from_purch/_calendar_month — exist.
- Statement equivalents: silver/statement_rows/ has lendingclub, marlette, sofi, upgrade, happymoney, prosper, northpond, openroad, upstart, innovate, anchored, intex directories.

ADAPTER SIDE (the actual gap): only TWO of 103 Datastore* classes implement _load_from_snowflake — datastore_positions.py and datastore_transactions.py. Every other class inherits base_datastore.py:310 which raises "source='snowflake' is not supported for %s". So for 13 of EDGEX's 14 classes the flag physically cannot be passed, even though the table is sitting there.

SO THE REAL BLOCKER LIST IS SHORT:
1. ADAPTER PLUMBING x5 cfframe classes + DatastoreTransfers — same shape as positions_snowflake_map.py / transactions_snowflake_map.py. Mechanical, not research. This is the bulk of it and it is NOT one word, but it is also not a data problem.
2. LC NOT REGISTERED — lendingclub has silver positions/transactions/transfers but ZERO entries in DEPRECATION_REGISTRY (12 entries cover sofi/prosper/marlette/happymoney/upgrade/northpond only) and NO lc_realized_cashflows_* builder in edgefocus/transformations/silver/cashflows/. EDGEX needs all 7 platforms, so lc alone blocks it.
3. MULTI-PLATFORM — datastore_positions.py:87 raises unless exactly one platform; EDGEX passes constants.PLATFORMS (all 7). Fix is a loop + concat, and the perf objection is gone: DEV-1398 'make interval=latest faster on snowflake' completed 2026-07-24.
4. GENUINELY UNSOLVED — DatastoreSimPredCfframeFromPurch is pinned at index 1160 so historical EF grades never move under model updates. No Snowflake equivalent found offering that frozen-version guarantee. Only used for pre-Aug-2023 purchases on lc/upgrade/marlette/prosper, so it does not touch northpond.
5. The 7 Statement* readers — silver equivalents exist per platform but no adapters; lowest risk, they only populate tape credit attributes.

WHAT THIS MEANS FOR DEV-503: northpond specifically is clean on 1-4 (registered, has all four cashflow builders, not in the SimPred set). The thing keeping northpond on legacy inside abs_datasets_job is entirely OTHER PLATFORMS' gaps — chiefly lc — plus the missing cfframe adapters. So nobody needs to solve northpond to unblock northpond.

RECOMMENDED REPLY ON DEV-1457 (it asks Eshan 'is there a Snowflake equivalent?' for each row): the answer for rows 1-8 is YES with a named table; row 9 (SimPred, pinned 1160) is the only genuine no. That ticket has sat in Backlog since 2026-07-17 partly because it reads as an open research question when most of it is already answered.
