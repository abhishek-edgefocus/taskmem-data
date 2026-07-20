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
updated: 2026-07-20T15:25:30Z
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
