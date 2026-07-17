---
id: wm-unb6pr
type: task
title: Decide + implement v1/v2 (TU/Experian) breakdown for NorthPond gold cashflow metrics
status: open
links: [follows:wm-rgwdyu]
created: 2026-07-16T11:22:33Z
updated: 2026-07-17T13:03:31Z
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

## Log
- 2026-07-16T12:53Z [claude-code] Scope clarification (2026-07-16): the 3 panels that moved off the now-deleted NorthPond gold table DID gain v1/v2 (they are per-loan silver now). This item is UNAFFECTED — it covers the ~17 IRR/ROI/CDR/CPR panels on the SHARED gold.realized_cashflows_calendar_month_daily, a different, pre-existing, 6-platform table. Still needs MODEL_VERSION in that table's grain; still a decision, not just work.
- 2026-07-17T13:03Z [claude-code] DEV-1024 verification (2026-07-17, prod Snowflake). CLAIM 1 CONFIRMED but MOOT TODAY: gold.realized_cashflows_calendar_month_daily grain=(as_of_date,calendar_month,platform,channel,fund) and gold.predicted_cashflows_calendar_month grain=(prediction_type,+same) — neither carries MODEL_VERSION (verified in TF + transform GROUP BY). BUT northpond has ZERO rows in realized gold (only upgrade/prosper/marlette/happymoney/sofi; 206 rows in predicted). So there are no NP CDR/CPR/ROI/IRR numbers to split — blocked behind wm-qs96kd. FUND-AS-PROXY WORKAROUND KILLED BY DATA: 'experimental' fund is MIXED — 334 v1 + 9 v2 (efhyf = 372 v1). CLAIM 2 PREMISE IS FALSE: zero NULLs — all 715 loans (current book AND all-loans-ever) resolve 706 v1 / 9 v2, every loan has an issuance row + offers match, so v1+v2==all reconciles exactly. Note prod silver.positions.MODEL_VERSION is 100%% NULL today only because PR #5884 is unmerged; 706/9 is what its logic yields. The 'breakdown pass' is NOT a transform — it is the Grafana template var on dash 5e958781 (SF Migration WIP): 'SELECT DISTINCT MODEL_VERSION FROM ...NORTHPOND_AT_PURCHASE_FEATURES WHERE MODEL_VERSION IS NOT NULL', includeAll=true/allValue=null/multi=true -> Grafana expands All to the explicit value list, so panels run MODEL_VERSION IN ('northpond_model','northpond_exp_model') and a NULL row matches NOTHING. NULLs would drop out of 'All' TOO, not just v1/v2 — ticket's 'NULLs contribute to the aggregate all' is wrong for these panels. Real asymmetry = at-purchase panels (filtered, drop NULL) vs gold cashflow panels (unfiltered). Also silver.northpond_at_purchase_features does not exist in PROD yet, so that var query fails in prod. NEW FINDING — v2 BUCKET IS 78%% TIEBREAK ARTIFACT: 227 apps were scored by BOTH APIs; 7 of the 9 owned v2 loans are dual-scored. _MODEL_VERSION_JOIN's MAX_BY(MODEL_VERSION,TIMESTAMP_NS) assigns them v2, but the two offers land ~2 SECONDS apart (6 loans) / 5.2h (1 loan) on the SAME DAY — that is parallel shadow scoring, so 'latest' = which API responded last, NOT 'the API the loan was booked under' as the code comment claims. MIN_BY instead of MAX_BY would give v2=2, not 9. TEMPORAL STABILITY IS FINE though: all offers are 1-3 days PRE-booking (before first_seen in positions), no post-booking offers -> model_version is 1:1 per loan and stable over life. So the mapping is well-defined; the VALUE is not, for 7/9 v2 loans.
