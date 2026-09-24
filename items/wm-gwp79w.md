---
id: wm-gwp79w
type: bug
title: PD #1438: northpond duplicate (efp_id,mob,fund) rows break best_est_projections_at_orig — all-platform gold MOB frozen since 2026-09-21
status: active
priority: high
tags: [northpond, predictions, pagerduty, oncall]
links: [relates:wm-8uyfnw]
created: 2026-09-23T18:53:20Z
updated: 2026-09-24T11:50:56Z
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
- 2026-09-24T08:22Z [claude-code] FIX WRITTEN AND VALIDATED ON PROD DATA. Abhishek's call (2026-09-24), asked
twice: NorthPond-scoped, no common-code change. cashflows/utils.py is untouched.

## What the fix does

northpond_realized_cashflows_from_origination.py gains
_resolve_preview_positions(sql): a sqlglot AST pass over the generated SQL that
replaces all 12 `silver.positions` table references with a subquery keeping one
row per (EFP_ID, AS_OF_DATE):

    SELECT * FROM silver.positions
    WHERE PLATFORM = 'northpond'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY EFP_ID, AS_OF_DATE
        ORDER BY IFF(FUND ILIKE 'to_be_purchased_%', 1, 0),
                 UPDATED_AT DESC NULLS LAST, FUND) = 1

Same precedence as gold/predicted_cashflows_aggregate.py:153 on the same pair.
Resolves the pair BEFORE the builder sees it rather than deduplicating the
output - once the cartesian exists, no column records which position row a row
came from, so a post-hoc QUALIFY would be picking by column ordering.

Gotcha found and fixed: an unaliased `silver.positions` is addressed downstream
as `positions.<column>`, so the substituted subquery must be aliased
`node.alias or node.name` - without that the query fails with
"invalid identifier 'POSITIONS.AS_OF_DATE'".

## Validation (PROD read-only, COMPUTE_WH_XS_DEV, dates=['2026-09-23'])

Before/after built in one process (diag/gen_both.py) and both run as CTEs in a
single statement (diag/d9.py), so the comparison is on one data snapshot:

  BEFORE (master): 13,668 rows | 668 dup groups | 1,852 dup rows | 560 loans
  AFTER  (fix)   : 13,118 rows |   0 dup groups |     0 dup rows |   0 loans

  KEYS_ADDED 0 | KEYS_LOST 0 | AFTER_ROWS_NOT_IN_BEFORE 0

668 matches PROD's live dup-group count exactly. The fix only ever removes the
spurious twins: it creates no (efp_id, fund, mob) key, loses none, and every
surviving row already existed in the before set.

Worked loan northpond_OLV12563455 (diag/d10.py): 10 rows -> 2, and only the
survivors balance.
  MOB 1: 5,000.00 - 108.86 = 4,891.14
  MOB 2: 4,891.14 -  51.59 = 4,839.55
The discarded twins carry the payment but never apply it.

## State of the change

dp:~/claude-ws/dev-1909/efp, branch still master @ e24cb02f2, uncommitted.
  M edgefocus/.../cashflows/northpond_realized_cashflows_from_origination.py
ruff format --check: clean. ruff check: clean.

## NOT DONE - dpx went unreachable mid-session (port 22 timing out, ~09:25 PT)

1. The test file is written but NEVER LANDED on dpx and has NEVER RUN. It is at
   ~/dev-1909-pending/northpond_realized_cashflows_from_origination_test.py on
   the Mac (along with a copy of the fix). scp it to
   edgefocus/transformations/silver/cashflows/ and run it.
   It is duckdb row-based per the standing rule (no SQL-substring assertions):
   fixture with an owned+preview pair, a preview-only loan and an upgrade row;
   asserts the owned row wins, a lone preview row survives, one row per
   (efp_id, as_of_date), northpond scoping, and that both aliased and unaliased
   references still resolve. One structural test asserts every surviving
   silver.positions reference sits under a QUALIFY.
2. mypy never completed (first run died with the ssh drop at 600s, cold cache).
3. No commit, no branch, no PR. Branch name from Linear:
   abhishek/dev-1909-601-duplicate-efp_id-fund-mob-groups-for-northpond-in
4. Not validated in DEV_ABHISHEK as a real transform run - the validation above
   is a read-only SELECT against PROD, not a materialization.

## Notes updated (Mac, done)

areas/efp/platforms/northpond/incidents.md: new I22 entry (the fan-out), two
symptom-index rows, and I11 now points at I22 as its second and worse consumer.
meta.md stamped in the same edit, flagging that I22's fix is written but NOT
MERGED. NOT yet pushed to the dpx mirror (sync-to-dpx.sh needs dpx up).
- 2026-09-24T11:50Z [pd-1451] PD #1451 is the SAME alert as #1438, not a new failure. Grafana triggered it independently at 2026-09-24T00:07:31Z (trigger channel=api, Grafana Events API v2) while #1438 was still open and still `triggered` — so the Dagster-asset dedup key is not folding repeats; expect more siblings until the fix lands. He acked #1451 from mobile at 08:45Z.

Re-verified live on 2026-09-24 (PROD, read-only COMPUTE_WH_XS_DEV, from PD-1451 tab):
- silver.realized_cashflows_from_origination: 668 dup (EFP_ID,FUND,MOB) groups / 1,508 rows — IDENTICAL to the pre-fix measurement, unchanged.
- gold.predicted_cashflows_mob: MAX(AS_OF_DATE) = 2026-09-21 for ALL 13 slices (all, anchored, foursight, happymoney, innovate, lc, marlette, northpond, openroad, prosper, sofi, upgrade, upstart). Now 3 days stale.
- silver.best_est_projections_at_orig: still MAX(AS_OF_DATE) 2026-08-24 / 95,424,815 rows.
- CloudWatch /ecs/dagster-prod-run: ingest_prediction_files RUN_FAILURE on best_est_projections_at_orig every ~30 min continuously through 2026-09-24T07:37:21Z, and the duplicate-(efp_id,fund,mob) ERROR lines are still being emitted at 10:07:18 (northpond_OLV* at as_of_date 2026-09-23).
- Note the failing step MOVED: through 09-23 ~09:36Z the step aborted as 'Dependencies for step best_est_projections_at_orig failed: [predicted_cashflows]'; from 09-23 22:02Z onward predicted_cashflows succeeds and best_est_projections_at_orig is itself the head failure. So PD #1433 (predicted_cashflows) is resolved-in-fact and this is now the only blocker.

State of the fix as of 2026-09-24 ~10:40Z (ahead of the 08:22Z log above):
- dp:~/claude-ws/dev-1909/efp is CLEAN on branch abhishek/dev-1909-601-... @ 26b63830f, pushed.
- Test file northpond_realized_cashflows_from_origination_test.py HAS landed in edgefocus/transformations/silver/cashflows/.
- PR #6989 is OPEN, DRAFT, MERGEABLE, reviewDecision REVIEW_REQUIRED. Checks: Run Tests SUCCESS, Select tests SUCCESS, Linear-link SUCCESS, diff-size SUCCESS, integration tests SKIPPED.
- Remaining gates: (1) DEV_ABHISHEK materialization — the 668->0 proof is a read-only SELECT, not a real transform run; (2) Snowflake proof + DAG shot in the PR body per pr-style; (3) mark ready for review.
- ~/dev-1909-pending/shared_variant.py (Mac, 16:30 IST, newest artifact) applies the cashflows/utils.py variant to measure its diff size — so the scoped-vs-shared choice may have been reopened after the commit. utils.py is NOT modified in the workspace.
