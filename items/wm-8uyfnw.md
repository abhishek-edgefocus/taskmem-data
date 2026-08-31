---
id: wm-8uyfnw
type: bug
title: best_est_projections_at_orig has been a prod no-op since 2026-08-27 — all platforms' BEP silently stale in gold
status: next
priority: high
size: m
tags: [northpond, predictions, dev-1498]
links: [relates:wm-79k8df, parent:wm-3sxcre]
created: 2026-08-31T15:33:08Z
updated: 2026-08-31T17:09:38Z
source: claude-code
---

CMOP is fully live end to end in PROD after DEV-1498 ([[wm-79k8df]]). BEP is
generated and reaches `silver.predicted_cashflows_history`, but **stops there** —
it never reaches `silver.best_est_projections_at_orig`, and therefore never
reaches `gold.predicted_cashflows_mob`, which is where consumers read it.

**Verified in PROD 2026-08-31 (~15:00 UTC), by existence probes:**

| Stage | curr_mod | best_est |
|---|---|---|
| `silver.predictions` | ✅ both channels, latest gen 2026-08-30 13:30 PDT | ✅ `northpond_exp_loan_fl`, gen 2026-08-30 14:10 PDT |
| `silver.predicted_cashflows_history` | ✅ | ✅ (`northpond_loan_fl` seen at MOB 10) |
| `silver.predicted_cashflows` (the view) | ✅ | ✅ `northpond_exp_loan_fl`, MOB 1, prediction_date 2026-08-30 |
| `silver.best_est_projections_at_orig` | n/a | ❌ **NONE for northpond** (sofi rows present, so the table itself is fine) |
| `gold.predicted_cashflows_mob` | ✅ as_of 2026-08-31 | ❌ **NONE** |
| `gold.predicted_cashflows_calendar_month` | ✅ as_of 2026-08-31 | not checked |

**It is not "pending".** `best_est_projections_at_orig` materialized in prod at
2026-08-31 14:07 UTC (run `404101b1`), well after the BEP predictions landed on
2026-08-30 21:10 UTC, and still produced no northpond rows. `predicted_cashflows_mob`
ran in the same run at 14:28 UTC.

**So the inputs are all present and the overlay ran and skipped northpond.**
`BestEstProjectionsAtOrig` (`edgefocus/transformations/silver/predictions/best_est_projections_at_orig.py`)
overlays `REALIZED_SOURCE = silver.realized_cashflows_from_origination` with
`PREDICTED_SOURCE = silver.predicted_cashflows` filtered to best_est, FULL OUTER
JOIN on `r.efp_id = p.efp_id AND r.mob = p.mob`. Northpond has realized rows
(11,547 / 1,075 loans). Candidate causes, none checked yet:
- `key_column = "as_of_date"` with `reload_all_on_change=True` on both stream
  sources — northpond's changed keys may not be reaching it
- the per-row `segment_fund` the gold aggregate expects may be null for northpond
- an efp_id / MOB axis mismatch between the realized and predicted sides

**Why this was never caught pre-merge:** this is exactly the stage that could not
be exercised in `DEV_ABHISHEK`, because there `silver.predicted_cashflows` was a
pass-through view to PROD, so nothing written in dev could reach the overlay. The
PR was explicit that the gold layer past `predicted_cashflows` was not claimed.

Blocks closing DEV-1498: the ticket is "Setup NorthPond CMOP/**BEP**", and BEP is
not visible where it is consumed.

## Log
- 2026-08-31T16:17Z [claude-code] 2026-08-31: MECHANISM FOUND at code level; which branch fires for northpond is NOT yet confirmed (prod Snowflake was too contended to run the confirming query — a northpond-scoped aggregate on REALIZED_CASHFLOWS_FROM_ORIGINATION timed out at 240s, and dpx SSH dropped repeatedly).

THE GATE is in loan_state_pred_ctes_sql, edgefocus/transformations/silver/predictions/best_est_projections_base.py:29. A best_est prediction reaches the overlay only if COALESCE(ls.is_active, TRUE):

  frontier   = MAX(bop_date) per PLATFORM over realized rows WHERE valid_mask AND eop_principal > 0
  loan_state = per efp_id, its latest valid realized row (ORDER BY bop_date DESC, mob DESC)
  is_active  = COALESCE(eop_principal,0) > 0
               AND bop_date >= DATEADD(month, -1, platform_frontier)
  pred       = SELECT ... FROM silver.predicted_cashflows p
               LEFT JOIN loan_state ls USING (efp_id)
               WHERE prediction_type='best_est' AND COALESCE(ls.is_active, TRUE)

WHY AN EMPTY pred WIPES THE WHOLE PLATFORM: the `real` CTE is itself scoped to
  efp_id IN (SELECT efp_id FROM pred) OR (platform, canonical_channel(channel)) IN (SELECT platform, channel FROM pred)
so if pred has no northpond rows, real has none either, the FULL OUTER JOIN produces nothing, and the platform is absent from the target — exactly the observed symptom.

NOTE the LEFT JOIN + COALESCE(..., TRUE): a loan with NO realized row at all is KEPT, not dropped. So "northpond has fewer realized loans than predicted loans" is NOT sufficient to explain the absence. Something must be actively setting is_active = FALSE.

HYPOTHESIS 1 (leading): northpond's realized chain is stale relative to its own frontier. silver.realized_cashflows_from_origination carries 1,075 northpond loans against 1,310 in the credit slice. If the BEP cohort's latest valid realized rows sit more than a month behind northpond's own MAX(bop_date), every one fails is_active and pred is empty. The frontier is per-platform so it self-normalises — which means this only bites if a few loans sit far ahead of the rest, dragging the frontier past everyone else's newest period.

HYPOTHESIS 2 (worth checking, and it is mine): the realized side does not know the new channel. northpond realized rows are 100% CHANNEL='northpond_loan_fl'; the exp BEP predictions carry CHANNEL='northpond_exp_loan_fl'. canonical_channel_sql only aliases happy_money_loan_td -> happymoney_td, so the `real` CTE's (platform, channel) branch cannot match exp rows. The efp_id branch should still catch them and the final SELECT does COALESCE(r.channel, p.channel), so this should be survivable — but it is the same at_orig/curr_mod channel asymmetry the PR flagged, now showing up one layer deeper, and it deserves ruling out rather than assuming.

CONFIRMING QUERY (staged at dp:~/claude-ws/dev-1498/diag3.py, needs a warehouse that is not saturated): for northpond, compute the frontier and split the loans that have realized rows into is_active TRUE/FALSE. If NOT_ACTIVE is ~everything, hypothesis 1 is confirmed and the fix is upstream in the realized chain, not in DEV-1498's code. Also worth running diag2.py, which additionally reports how many BEP loans have any realized row at all.
- 2026-08-31T17:09Z [claude-code] ROOT CAUSE FOUND 2026-08-31, and it is NOT northpond-specific and NOT caused by DEV-1498.

silver.best_est_projections_at_orig HAS BEEN A NO-OP IN PROD FOR DAYS. Pulled 120 consecutive materializations from prod Dagster spanning 2026-08-28 09:02 -> 2026-08-31 16:32 UTC: EVERY ONE reports rows_inserted 0, rows_deleted 0, dates "none". The asset records a materialization on each run of ingest_prediction_files but never processes a key, so it never rebuilds.

LAST REAL WRITE: the table itself has MAX(LOADED_AT) = 2026-08-27 03:06:49 PDT (10:06 UTC) and MAX(AS_OF_DATE) = 2026-08-24. So the overlay stopped doing real work on 2026-08-27 around 10:06 UTC.

ATTRIBUTION — it predates this change. The DEV-1498 backfill ran at 2026-08-27 13:20 UTC, THREE HOURS AFTER the overlay's last successful write. The northpond BEP predictions did not exist until 2026-08-30 21:10 UTC. So northpond was never in scope on the last occasion the overlay actually rebuilt; it is absent because the overlay has not rebuilt since, not because anything about northpond is rejected.

WHAT THIS REFUTES, both of my earlier hypotheses:
- H1 (realized chain stale, is_active drops northpond): REFUTED TWICE. Of northpond loans with realized rows, 622 of 876 are is_active. And directly on the BEP cohort: 1,149 northpond best_est loans in the view, of which 582 have no realized row (kept via COALESCE(ls.is_active, TRUE)) and 567 are is_active — DROPPED = 0, TOTAL_SURVIVING_PRED = 1,149. The gate drops nothing.
- H2 (realized side does not know northpond_exp_loan_fl): not the cause either; pred is fully populated and the FULL OUTER JOIN would emit pred-only rows regardless.

BLAST RADIUS IS PLATFORM-WIDE, not northpond. gold.predicted_cashflows_mob best_est shows MAX(AS_OF_DATE) = 2026-08-31, i.e. gold is rebuilding daily — but off an upstream frozen at as_of 2026-08-24. So EVERY platform's BEP figures in the gold MOB aggregate have been silently stale since 2026-08-27, presented with a current as_of_date. That is the more serious problem and it is invisible from gold alone.

LIKELY MECHANISM, not yet proven: BestEstProjections sets key_column = "as_of_date", but its stream sources record changed keys under different key columns — PopulatePredictedCashflows keys silver.predicted_cashflows_history on s3_base. get_keys_to_process then finds no as_of_date keys and reports "dates none". The same signature appeared in DEV_ABHISHEK on 2026-08-26 ("Found 35 keys to process" followed by 0 deleted / 0 inserted, dates none).

SUGGESTED NEXT STEP: force one real rebuild in prod with as_of_date: all on best_est_projections_at_orig, then re-run gold predicted_cashflows_mob. That should both surface northpond BEP and un-stale every other platform. Abhishek launches prod jobs. Separately, the key_column mismatch needs a real fix or the asset will go back to no-op immediately.
