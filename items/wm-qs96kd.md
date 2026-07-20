---
id: wm-qs96kd
type: task
title: Wire 5 orphaned northpond cashflow assets into statements_northpond + backfill (prod gold EMPTY)
status: next
priority: p1
size: m
tags: [northpond, edgex]
links: [parent:wm-j523sq]
created: 2026-07-17T09:39:49Z
updated: 2026-07-20T18:19:42Z
source: claude-code
---

Verified against prod Snowflake + origin/master 2026-07-17. This is the CRITICAL PATH for
including NorthPond in EDGEX-2026-1NN: every gold cashflow panel on the monitoring dashboard
reads tables that are EMPTY in prod.

## Evidence (prod, 2026-07-17)
- PROD.GOLD.POSITIONS_DAILY where platform='northpond'                  -> 0 rows
- PROD.GOLD.REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY platform=northpond  -> 0 rows
- PROD.SILVER.REALIZED_CASHFLOWS_CALENDAR_MONTH platform=northpond      -> 0 rows
- PROD.SILVER.POSITIONS platform=northpond -> 316,326 rows, fresh to 2026-07-15 (upstream HEALTHY)

## Root cause (origin/master)
orchestration/assets/northpond_assets.py defines 25 assets; orchestration/jobs/statements_northpond.py
selects only 13. Missing from the job selection:
  northpond_positions_daily
  northpond_realized_cashflows_from_origination
  northpond_realized_cashflows_from_purchase
  northpond_realized_cashflows_calendar_month
  northpond_realized_cashflows_calendar_month_daily
Because the platform statement sensor runs the JOB, these have never materialized.
Every other platform (upgrade/marlette/prosper/happymoney/sofi) wires these into statements_{platform}.

NOTE: northpond_realized_cashflows_from_first_purchase is orphaned for ALL platforms -> house
pattern (on-demand), NOT a bug. Do not "fix" it.

## Fix
1. Add the 5 asset names to the statements_northpond selection.
2. One-off backfill date='all' in dep order:
   wave1: positions_daily, from_origination, from_purchase, calendar_month
   wave2: calendar_month_daily
3. PR #5884's northpond_at_purchase_features will land in the SAME orphaned state unless it is
   added to the job selection too — check before merging.

## Impact
Unblocks 31 of 80 panels on the NorthPond Monitoring dashboard (per wm-drehnk inventory).

## Log
- 2026-07-20T15:25Z [claude-code] 2026-07-20: ALSO the hard blocker for enabling BEP (best_est) predictions for northpond. Verified prod: SILVER.REALIZED_CASHFLOWS_FROM_ORIGINATION has 0 northpond rows (only happymoney/marlette/prosper/sofi/upgrade). BEP is by definition realized-actuals overlaid on prediction (best_est_projections_base.py), so it yields nothing until these 5 assets materialize. Raises this item's value beyond the 31 dashboard panels.
- 2026-07-20T15:40Z [claude-code] 2026-07-20: Confirmed the mechanism from the dpx local Dagster codebase. (a) ZERO AutoMaterializePolicy/AutomationCondition anywhere in orchestration/ -> a job run NEVER cascades to downstream assets outside its selection. Materializing statements_northpond alone can never materialize the 5 orphans. (b) All northpond assets are UNPARTITIONED (only mirror_trade_files uses partitions_def) -> 'backfill all dates' is a single run with as_of_date:'all' run config, NOT an N-date partition backfill. (c) The 4 cashflow assets set reload_all_on_change=True so they self-rebuild full history; northpond_positions_daily does NOT -> it specifically needs as_of_date:'all' on first backfill. (d) northpond_realized_cashflows_calendar_month_daily's own docstring claims 'Runs as part of the NorthPond statements job' - it does not; docstring is wrong and should be fixed with the selection change.
- 2026-07-20T17:44Z [claude-code] 2026-07-20 CORRECTION: the 'PR #5884 at_purchase_features will land orphaned' note in the Fix section is OBSOLETE. #5884 was CLOSED, not merged. The at-purchase work shipped instead as PR #5917 (DEV-1428, merged 2026-07-17, 52f6684c) which surfaces the features via MODEL_VERSION + PLATFORM_ATTRIBUTES columns ON silver.positions -- no new asset, 'DAG unchanged'. northpond_positions is ALREADY in the statements_northpond selection, so no job change is needed for at-purchase. NEW ISSUE instead: northpond_positions has ZERO reload_all_on_change (only reload_subsequent_on_change on silver.transfers), so it is INCREMENTAL. The 07-17 merge therefore only enriched as_of_dates processed on/after 07-17 -- historical northpond rows in silver.positions still have NULL MODEL_VERSION / PLATFORM_ATTRIBUTES. northpond_positions needs its own as_of_date='all' full rebuild. Useful side effect: because the 4 cashflow assets set reload_all_on_change=True on silver.positions, that full positions rebuild will make them full-rebuild on their next run automatically. Correct order = positions(all) FIRST, then the 5 newly-selected assets; positions_daily still needs explicit as_of_date='all' since it is incremental.
- 2026-07-20T18:19Z [claude-code] 2026-07-20 RE-VERIFIED against FRESH origin/master 11cccc734 (earlier pass used stale e8a80475e + a buggy regex; both corrected). CORRECTIONS: (1) statements_northpond selection is 13 assets, NOT 12 -- it now also includes edgex20261NN_northpond_cl (statements_northpond.py:54). My earlier greps filtered on '^\s+"northpond' and silently dropped it. (2) northpond_assets.py defines 25 assets, and edgex20261NN_northpond_cl IS wired (also in warehouse_data_shared_assets.py:160) -- it is NOT an orphan. CONFIRMED UNCHANGED: exactly 5 true orphans remain -- positions_daily, cashflows_from_origination, from_purchase, calendar_month, calendar_month_daily. Verified by git grep across ALL of orchestration/: they appear ONLY as deps inside northpond_assets.py, in zero jobs/sensors/schedules. from_first_purchase remains an intentional orphan. No AutoMaterializePolicy/AutomationCondition anywhere; no catch-all job (AssetSelection.all() appears only in utils_test.py; operations.py selects group OPERATIONS which excludes SILVER/GOLD). Sensor wiring at definitions.py:375 runs the JOB with max_runtime=2h. So the original fix in this item is still exactly right and still unshipped.
