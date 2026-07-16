---
id: wm-unb6pr
type: task
title: Decide + implement v1/v2 (TU/Experian) breakdown for NorthPond gold cashflow metrics
status: open
created: 2026-07-16T11:22:33Z
updated: 2026-07-16T11:49:19Z
source: claude
label: TU/Experian breakdown decision
---

Follow-on from DEV-1395 / PR #5884 (which shipped the v1/v2 filter for the
per-loan at-purchase panels only).

The ~17 IRR / ROI / CDR / CPR panels read gold.realized_cashflows_calendar_month_daily,
which is pre-aggregated per (as_of_date, calendar_month, platform, channel, fund).
A per-loan attribute cannot be filtered at query time once summed, so v1/v2 needs
MODEL_VERSION in that table's GRAIN.

Why it's a real decision, not just work:
- The table is SHARED by 6 platforms (sofi, marlette, prosper, happymoney, upgrade, northpond).
- CDR/CPR/IRR/ROI are NON-additive -> the shared base already synthesises channel='ALL'
  rollup rows; a model_version dimension needs the same 'ALL' logic for every platform.
- IRR/MONTHLY_ROI are computed in Python (canonical fns), so they cannot be recomputed
  in panel SQL as a workaround.
- Needs backfill of all platforms + re-verification of every platform's dashboards for
  one-row-per-(as_of_date,fund) assumptions.

Abhishek's constraint: no standardized schema changes, and no platform-specific gold
tables. Both rule out the easy paths -> needs a call from whoever owns the cashflows
base transform.

Context / prior art:
- DEV-1024 "Add a v2 exp filter" (Kabeer) -> marked Duplicate, folded into DEV-1395.
  Its model_version dashboard variable never worked: nothing ever populated
  positions.model_version for northpond (NULL in the datastore too).
- PR #5884 populated silver.positions.MODEL_VERSION for northpond
  ('northpond_model' = v1/TU, 'northpond_exp_model' = v2/Experian), so the per-loan
  source of truth now exists.
- Current book: 706 v1 / 9 v2 loans; all 9 v2 loans are in the 'experimental' fund.

Links:
- DEV-1395: https://linear.app/edge-focus/issue/DEV-1395/migrate-the-northpond-fund-monitoring-page-to-use-snowflake-data
- DEV-1024: https://linear.app/edge-focus/issue/DEV-1024/add-a-v2-exp-filter-on-the-following-dashboard
- PR #5884: https://github.com/edgefocus/efp/pull/5884
