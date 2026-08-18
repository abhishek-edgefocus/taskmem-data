---
id: wm-7taumv
type: bug
title: Prod northpond_positions/transfers silently broken for a week, now fixed
status: done
tags: [northpond, edgex, nelnet, prod-incident]
created: 2026-08-18T21:52:08Z
updated: 2026-08-18T21:52:08Z
source: claude-code
label: Prod northpond_positions/transfers silently broken
---

Discovered 2026-08-18 while checking the Nelnet backfill's prod status. Root cause and fix, chronologically:

1. Every scheduled statements_northpond run since 2026-08-12 12:58 UTC failed on northpond_transfers (subprocess silently dies mid-step, no traceback in CloudWatch — likely OOM, never fully diagnosed). This blocked northpond_positions and everything downstream (positions_daily, edgex20261NN_northpond_cl, realized cashflows). silver.positions for northpond held only synthetic to_be_purchased_edgex20261NN rows all week — the real efhyf/northpond_balancesheet/edgex20261NN book was stale since 08-11.
2. Not caused by PR #6324 (merged/deployed 2026-08-18) — predates it by a week. #6324's own deploy did NOT trigger an immediate reprocess since it's downstream of the same broken chain.
3. Manually running northpond_transfers with as_of_date=all succeeded (transfers itself wasn't reliably broken — the OOM theory is inconsistent with a full 823-date run completing while narrow incremental runs kept dying). northpond_positions then failed separately: 1,430 validation errors (Duplicate efp_id found for the same as_of_date).
4. Traced to bronze.statement_rows: the FCC loan tape file ffcnp_dailyloantape_08182026.csv got ingested twice one second apart (13:17:09 and 13:17:10 PDT) — a scheduled ingest racing a manual backfill, no lock. Exact same failure mode as PR #6346 (which fixed it for stmt_nelnet_positions.py/stmt_nelnet_transactions.py only, earlier the same day).
5. Fix: PR #6364 (merged 2026-08-18T21:21Z, deployed) added the same QUALIFY ROW_NUMBER() dedup guard to the other 6 northpond stmt_*.py files that lacked it (stmt_positions, stmt_transactions, stmt_issuance, stmt_payment_configuration, stmt_purchase_tapes, stmt_transaction_boards).
6. Reprocessed in prod: northpond_stmt_positions for 2026-08-18 (1,430->715 rows, clean), then full as_of_date=all backfill of northpond_transfers (1,697 rows, 823 dates) and northpond_positions (335,631 deleted / 346,189 inserted, 782 dates). Verified via Snowflake: silver.positions now shows real funds (efhyf, northpond_balancesheet, edgex20261NN) for every day 08-13 through 08-18, not just the synthetic to_be_purchased rows.

STILL OPEN / not investigated: why northpond_transfers specifically died silently on every narrow incremental run for a week (2026-08-12 through 2026-08-18). CloudWatch showed no exception, just the subprocess going silent mid-step. Worth watching whether it recurs now that the deploy has happened and the dedup fix is live — if scheduled runs keep failing the same way, the root cause is something else (OOM under the multiprocess executor is the leading theory, unconfirmed).

Also flagged but explicitly NOT acted on per Abhishek's call: 54 of 65 total generate_stmt_sql() call sites across ~11 other platforms (happymoney, prosper, innovate, sofi, figure, lendingclub, upgrade, upstart, marlette, openroad, foursight, intex) have the same missing-dedup-guard exposure. Not tracked further at his instruction ('ignore them').

## Environment
- taskmem: 5cf014a
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-18T21:52:08Z
