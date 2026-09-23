---
id: wm-gwp79w
type: bug
title: PD #1438: northpond duplicate (efp_id,mob,fund) rows break best_est_projections_at_orig — all-platform gold MOB frozen since 2026-09-21
status: next
priority: high
tags: [northpond, predictions, pagerduty, oncall]
created: 2026-09-23T18:53:20Z
updated: 2026-09-23T18:53:20Z
source: pd-1438
label: PD #1438
---

PD #1438 ([PROD] Dagster Asset best_est_projections_at_orig failed), created
2026-09-23T17:40:31Z, still `triggered`. Same underlying failure as #1253
(Dagster error logged - ingest_prediction_files).

## Root cause (proven 2026-09-23)

`silver.best_est_projections_at_orig` is no longer the silent no-op of
[[wm-8uyfnw]] — it now finds keys and does real work (354 keys, 1050 as_of_date
values, a 96,341,361-row temp table). It then fails its own BLOCKING validation
rule `no-duplicate-efp-id-fund-mob`
(edgefocus/transformations/silver/predictions/best_est_projections_base.py:133)
and aborts with:

    ValueError: Validation failed with 664 error(s).
    transform.py:1145

All 50 sampled failures are `northpond_OLV*` efp_ids at as_of_date 2026-09-23.

Upstream: `silver.realized_cashflows_from_origination` holds 243 duplicate
(efp_id, mob, fund) groups, exactly 2 rows each, **northpond only** — every
other platform is 0. All 243 are at **mob = 1**. Same bop_date, same channel,
same loaded_at, same pool_id. Funds: edgex20261NN (147) and
northpond_balancesheet (96); efhyf is clean.

91 of the 243 pairs disagree on `eop_principal`; the rest are exact dupes.
Worked example, northpond_OLV12563455 / mob 1 / northpond_balancesheet — the two
rows are identical in every other column:

  bop_principal 5000.00, principal_payment 108.86 -> eop_principal 4891.14  (consistent)
  bop_principal 5000.00, principal_payment 108.86 -> eop_principal 5000.00  (INCONSISTENT)

So the 4891.14 row is the correct one; the 5000.00 twin never had the payment
applied. Not a fund-overlap or channel artifact.

Fan-out is NOT upstream of the transform: `silver.positions` has 0 duplicate
(efp_id, fund, as_of_date) for northpond, and OLV12563455 has exactly one
`silver.transfers` row (an inferred purchase event from
s3://efp-raw/statements/northpond/nelnet/daily_loan/2026/08/olivfinancial_loan_20260802.csv).
So the duplication is introduced inside
`build_realized_cashflows_from_origination_query` (shared utils, used by all 12
platforms), at the mob=1 / purchase-month seam.

## Blast radius — this is the serious part

`best_est_projections_at_orig` has failed **141 times between 2026-09-18
20:08:59Z and 2026-09-23 18:37:13Z**, every ~30 min, and is still failing. Per
day: 09-18 x8, 09-19 x48, 09-20 x43, 09-21 x19, 09-22 x20, 09-23 x3 (the
remaining runs in those days failed earlier at `predicted_cashflows` instead, so
ingest_prediction_files has been failing continuously either way).

Because the step fails, `predicted_cashflows_mob`, `predicted_cashflows_mob_from_purch`
and `predicted_cashflows_calendar_month_from_purch` never execute. Verified:
`gold.predicted_cashflows_mob` MAX(as_of_date) = **2026-09-21 for every
platform** (anchored, happymoney, lc, marlette, northpond, openroad, prosper,
sofi, upgrade, upstart, foursight, innovate) and all three prediction types.
`silver.best_est_projections_at_orig` itself still MAX(as_of_date) 2026-08-24,
last written 2026-08-27 — unchanged since [[wm-8uyfnw]].

So a northpond-only data defect is holding the gold MOB prediction layer stale
for ALL platforms.

## The decision (Abhishek's)

The fan-out sits in the shared `build_realized_cashflows_from_origination_query`,
which his standing rule says not to edit. Options:
  (a) northpond-scoped override of `generate_sql` in
      northpond_realized_cashflows_from_origination.py to dedupe mob=1 (QUALIFY
      picking the internally-consistent row) — obeys the no-shared-edits rule,
      unblocks all platforms, leaves the real bug in place for other platforms;
  (b) fix the shared builder — correct, but touches all 12 platforms;
  (c) do nothing — gold MOB keeps aging for every platform.

Both affected funds map to live Oliv deliveries ([[wm-9dfnnt]] EDGEX purchase
tapes first landing, [[wm-rwdnhh]] May-Jul balance-sheet backfill), so the new
deliveries are the likely trigger even though the fan-out is ours.

Evidence scripts: /tmp/diag{2..6}_pd1438.py on dpx; step stderr at
s3://efp-dagster-logs/compute-logs/storage/a9ec6e91-f201-4095-98ed-fea8db53de7a/compute_logs/obgjrvpn.err


## Environment
- taskmem: f3a4f1e
- reported by: pd-1438
- host: ip-192-168-1-3.ap-south-1.compute.internal
- when: 2026-09-23T18:53:20Z
