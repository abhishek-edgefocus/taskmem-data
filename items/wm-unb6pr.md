---
id: wm-unb6pr
type: task
title: Decide + implement v1/v2 (TU/Experian) breakdown for NorthPond gold cashflow metrics
status: open
links: [follows:wm-rgwdyu]
created: 2026-07-16T11:22:33Z
updated: 2026-07-17T13:17:18Z
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
- 2026-07-17T13:17Z [claude-code] DEV-1024 part 2 (2026-07-17) — Abhishek: v2 loans imminent + it IS a business requirement, so aggregate-only is OFF the table. Four new prod findings that reshape the design. (1) DUAL-SCORING IS CLOSED, NOT THE RAMP DESIGN: dual-scored apps confined to 2025-11 (74%%), 2025-12 (98.3%%), 2026-01 (51%%) then ZERO from 2026-02 onward. So the MAX_BY tiebreak defect is bounded to exactly 7 legacy loans — a one-time fixable data issue, NOT systemic. Fix on booking evidence (match booked rate/term/IRR to the offer) BEFORE any backfill so wrong labels aren't baked in. (2) V2 IS ALREADY AT SCALE IN APPS: 100%% exp-only since 2026-02, ~10.7k/11.9k/11.6k apps in May/Jun/Jul 2026. Owned book hasn't caught up (last first_seen 2026-01-13) — purchases lag. So future book is ~100%% v2 and unambiguous. (3) MODEL_VERSION IS ALREADY STANDARDIZED + POPULATED: sofi has 14,263/14,263 non-null with 3 values (sofi_1.2, sofi_1.6, sofi_phase_two) and sofi IS in gold realized. So a model_version dimension is a GENERAL cross-platform feature, not a northpond hack — this materially weakens the 'no standardized schema changes' objection; the concept already exists in silver.positions, it just isn't propagated to cashflows. All other platforms 0%% non-null. (4) VINTAGE CONFOUND — THE BIGGEST RISK: v1 = 706 frozen legacy loans seasoned since 2024-07/2025; v2 = brand-new cohort. Gold realized exists ONLY in CALENDAR space (REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY); MOB-space realized exists only per-loan in silver (FROM_PURCHASE 6.4M / FROM_ORIGINATION 6.6M rows) with NO gold aggregate, while PREDICTED already has MOB gold (PREDICTED_CASHFLOWS_MOB, _MOB_FROM_PURCH). A calendar-space v1-vs-v2 CDR/IRR read will flatter v2 purely from seasoning. A fair comparison needs MOB-space realized gold + model_version — bigger than DEV-1024 states but it is what actually answers 'how is v2 performing'. (5) FUND-AS-PROXY DOUBLY DEAD: fund is TIME-VARYING — all 715 loans passed through 'experimental' (first_seen 2024-07-10), 372 now in efhyf; loans migrate experimental->efhyf. model_version by contrast is static per loan, so it is a better-behaved grain addition than fund. DESIGN OPTIONS (no decision yet, needs cashflows-base owner): A) model_version in shared gold grain + 'all' rollup row (mirrors channel='ALL') — existing panels must add model_version='all' or SILENTLY DOUBLE-COUNT; blast radius = every panel on 5 platforms. B) superset table + redefine existing table as a VIEW filtered to model_version='all' — zero panel changes, one source of truth, no dup compute; caveat DEV-1071 converted view->table for Python IRR, but that binds the WRITER not a read-only view. C) additive generic companion gold table by model_version — existing table untouched, zero regression risk, satisfies both constraints, cost = dup compute + reconciliation drift. D) generic config-driven BREAKDOWN_KEY/VALUE dimension — most reusable but cardinality x expanding-window IRR compute blowup. Sequence: wm-qs96kd (NP realized gold EMPTY) -> merge PR5884 -> fix 7 tiebreaks + NULL guard -> grain decision -> MOB realized gold.
