---
id: wm-gwp79w
type: bug
title: PD #1438: northpond duplicate (efp_id,mob,fund) rows break best_est_projections_at_orig — all-platform gold MOB frozen since 2026-09-21
status: active
priority: high
tags: [northpond, predictions, pagerduty, oncall]
links: [relates:wm-8uyfnw]
created: 2026-09-23T18:53:20Z
updated: 2026-09-23T19:55:34Z
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

## Log
- 2026-09-23T19:55Z [claude-code] DEV-1909 = the Linear ticket for this bug (Nakula, 2026-09-22, assigned Abhishek,
Backlog, project "Generic bug fixes"). MECHANISM NOW PROVEN — my earlier
"introduced inside build_realized_cashflows_from_origination_query" note was
right about the location; here is the exact join.

## Root cause (proven 2026-09-24, PROD)

silver.positions carries TWO rows for the same (efp_id, platform, as_of_date)
for northpond only: the real holder row (fund=northpond_balancesheet,
channel=northpond_loan_fl) and the committed-pipeline preview row
(fund=to_be_purchased_edgex20261NN). 5,214 such keys, 670 loans, from
2026-08-14 (the day INTENDED_INVESTOR first populated).

Cross-platform check: dup (efp_id, platform, as_of_date) keys in silver.positions
  northpond 5,214 ... every other platform 0.
And TBP rows that shadow an owned same-day row:
  northpond 5,214 of 6,147 | marlette 0/75,248 | upgrade 0/24,135
  | prosper 0/9,318 | happymoney 0/2,118.

build_realized_cashflows_from_origination_query joins silver.positions three
times on (efp_id, platform, as_of_date) with NO fund predicate —
cashflows/utils.py:1909 (pf / first_position), :1920 (pl / eop_position),
:1926 (psale / pre_sale_position). Each join doubles the row. Then the
prev/curr self-join at :1971 (on efp_id, mob-1) squares it.

Shape matches exactly: 560 groups x2 at mob 1 (eop_position fan-out only —
the TBP row starts mid-month so MIN(as_of_date) is unambiguous but the
period-end date has both funds), 86 groups x4 at mob 2 (pf x2 * prev x2).
668 dup groups / 1,508 rows / 560 loans in PROD today.

Columns that diverge inside a group: BOP_MARKUP (550 groups), EOP_MARKUP (96),
EOP_PRINCIPAL (91), BOP_PRINCIPAL/SCHEDULED_*/EXPECTED_* (86), accrued
interest (67-76). Everything else is constant. The preview row carries
markup 0.985 (the deal price), NULL accrued_interest, NULL pool_id and a
STALE principal (origination amount, by design — no servicing feed covers
the pending window). The owned row carries markup 1.0 and the amortised
principal. So the owned row is always the correct one:
northpond_OLV12563455 mob 1 -> owned eop_principal 4,891.14 (consistent with
principal_payment 108.86 off bop 5,000.00); preview twin says 5,000.00.

## The source is NOT the bug — it is documented design

northpond/to_be_purchased_positions.py docstring, "Coexistence with the
balance sheet is legal; with a real fund it is not": unlike every other
platform the pending loan MAY legitimately appear under
northpond_balancesheet once the Nelnet feed is unioned in, because Oliv
holding it IS our balance-sheet vocabulary. The both-owned-and-to-be-purchased
validation was deliberately written to fire only on funds other than the
balance sheet. gold.positions_daily consumes to_be_purchased_edgex20261NN as
its own fund (~$246-310K/day, 09-15..09-23) — that is the committed-pipeline
number. So removing the overlap at source would delete a live feature to dodge
a join bug. Ruled out.

## Precedent for the fix already exists in shared code

gold/predicted_cashflows_aggregate.py:148-156 hit this exact problem and
solved it with a rank tie-break, naming northpond in the comment:
  "A loan can carry two rows for one date with different funds (a
   to_be_purchased preview row beside the real holder's row - the northpond
   balance-sheet flow does this daily): the real fund is the loan's latest state."
  tie_break = IFF(p.fund ILIKE '{TO_BE_PURCHASED_PREFIX}%', 1, 0),
              p.updated_at DESC NULLS LAST, p.fund
silver.positions has UPDATED_AT, so the same tie-break is reproducible in
cashflows/utils.py. Applying it is a PROVABLE no-op for the other 11
platforms (0 dup keys), and contains no platform conditional.

## Open decision (Abhishek's, 2026-09-24)

He ruled out the source fix path conditionally ("if we can fix the source that
is well and good" — it cannot) and restated the standing rule: do not make
shared/common changes only for NorthPond. Remaining choice is between the
shared tie-break in cashflows/utils.py (correct, precedented, inert elsewhere)
and a northpond-scoped generate_sql override in
northpond_realized_cashflows_from_origination.py (obeys the rule, masks the
defect, leaves the fund-blind joins live for 11 other platforms).

Workspace: dp:~/claude-ws/dev-1909/efp (master @ e24cb02f2).
Diagnostics: dp:~/claude-ws/dev-1909/diag/{sfq,d1..d7}.py
(run with ~/repos/efp/.venv/bin/python; warehouse COMPUTE_WH_XS_DEV).
