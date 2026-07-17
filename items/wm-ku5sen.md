---
id: wm-ku5sen
type: task
title: EDGEX-2026-1NN warehouse never materialized in prod: thresholds/CL zero rows + missing eligible_loans & trigger_limits
status: open
created: 2026-07-17T09:40:07Z
updated: 2026-07-17T09:40:07Z
source: claude-code
---

Verified against prod Snowflake + origin/master 2026-07-17. The EDGEX-2026-1NN warehouse has
NEVER produced a single row in prod — for ANY of its 5 platforms, not just northpond.

## Evidence (prod, 2026-07-17)
- GOLD.WAREHOUSE_CL           -> ZERO edgex20261NN rows (other warehouses fresh to 07-16/07-17)
- GOLD.WAREHOUSE_THRESHOLDS   -> ZERO edgex20261NN rows (edgex20251NN 55, 20252NN 79, 2026PT1 19)
- GOLD.WAREHOUSE_ELIGIBLE_LOANS -> ZERO edgex20261NN rows
- GOLD.WAREHOUSE_TRIGGER_LIMITS -> ZERO edgex20261NN rows

## What EXISTS on master
PR #5859 "gold: Setup CL and trigger pipeline for edgex20261NN" (Abhijeet Bodas, 2026-07-14):
- edgefocus/warehouses/edgex20261NN/{constants,thresholds,concentration_limits_configs}.py
- PLATFORMS = [upgrade, marlette, prosper, happymoney, northpond]  <- northpond IS included
- edgefocus/transformations/gold/warehouses/edgex20261NN/concentration_limits.py
- Per-platform CL assets incl. edgex20261NN_northpond_cl (northpond_assets.py:271)
- edgex20261NN_northpond_cl IS in the statements_northpond job selection
- EDGEX20261NN_THRESHOLDS IS wired into get_all_thresholds() (warehouse_thresholds.py:116)
- All 5 CL assets are deps of warehouse_cl_combined

## What is MISSING (gaps vs every other mature warehouse)
1. THRESHOLDS NOT IN PROD despite being authored + registered -> the warehouse_thresholds asset
   has not re-run since the 07-14 merge, or the deploy has not shipped. Diagnose first: this is
   the cheapest unblock and gates CL pass/fail status in warehouse_cl_combined.
2. NO eligible_loans.py transform and NO edgex20261NN_eligible_loans asset.
   edgex20251NN / edgex20252NN / edgex2026PT1 / prosper_cde all have one, and all three EDGEX ones
   are in the warehouse_data_shared job selection. edgex20261NN is absent from that job entirely.
3. NO triggers/ dir and NO edgex20261NN_trigger_limits asset (20251NN + 20252NN both have one,
   both in warehouse_data_shared). BLOCKED: constants.py has
   ORIGINAL_PRINCIPAL_BALANCE: float | None = None, with an in-code comment saying it is
   "Not known until the deal closes; set it here ... once the pool is final." -> the CNDR trigger
   metric cannot be built until the EDGEX-2026-1NN pool is final.
4. NO concentration_limits_test.py under transformations/gold/warehouses/edgex20261NN/
   (20251NN, 20252NN, prosper_cde, marlette_goldman_hyp all have one).

## Sequencing
(1) is a deploy/materialization question, not code. (2) and (4) are buildable now.
(3) is genuinely blocked on deal close.
