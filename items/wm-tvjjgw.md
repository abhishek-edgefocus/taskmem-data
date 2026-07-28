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
updated: 2026-07-28T13:40:36Z
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
