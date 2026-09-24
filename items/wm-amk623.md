---
id: wm-amk623
type: bug
title: PD #1458/#1457: marlette gold assets stale since 2026-09-21 — statements_marlette failed 4 runs straight on transfer-lifecycle validation; transfers now fixed but 16 downstream assets never rebuilt
status: next
tags: [marlette, edgex, oncall]
created: 2026-09-24T12:05:38Z
updated: 2026-09-24T12:05:38Z
source: pd-1458
label: PD #1458/#1457
---

PD #1458 (`[PRODUCTION] Dagster error logged - statements_marlette`, 07:31Z) and #1457
(`[PROD] Dagster Asset marlette_transfers failed`, 07:24Z) are the same 2026-09-24 07:23Z
failure wearing two badges. #1459 (standardized_loan_data_marlette, 07:48Z) is its
downstream consumer. #1455/#1456 (04:02Z DatastoreStandardizedPositions/marlette) predate
today's run and belong to [[wm-5vrgzp]].

## Root cause (proven)
`marlette_transfers` failed its BLOCKING validation `transfer-lifecycle-is-well-formed`
(the rule Scott calibrated — see [[wm-qbrvd4]]) with 82 errors = 41 loans x 2 checks:
- `to_fund does not chain to next from_fund` (date 2026-09-17)
- `purchase before previous lifecycle was sold` (date 2026-09-18)
All 82 were `transfer_date=2026-09-18, event_type=purchase, from_fund=NULL,
to_fund=edgex20261NN`. Cause: the same 41 marlette loans were booked as purchases into
`edgex20261NN` on BOTH 09-17 and 09-18 with no sale between, breaking the ledger chain.
Traceback: `edgefocus/transformations/transform.py:1145` via
`orchestration/assets/common/asset_factories.py:130`.
Evidence: s3://efp-dagster-logs/compute-logs/storage/7fddf1bb-b485-4f35-99ec-10ddbdb5a5d5/compute_logs/nneebwzp.err

Scale is collapsing as someone works it: 09-23 run had 40,620 errors (mostly to_fund=fortress,
transfer_date back to 2024-12-13); 09-24 had only 82.

## The data is now FIXED (verified in PROD, read-only COMPUTE_WH_XS_DEV, 2026-09-24 ~11:50Z)
- Zero consecutive-purchase chain violations remain for platform='marlette' in silver.transfers.
- Zero loan overlap between the 09-17 (64) and 09-18 (41) edgex20261NN purchase sets.
- The 3 sampled failing loans now have exactly one ledger row each.
- Dagster re-materialized marlette_transfers at 08:24Z and ALL 6 validation checks passed.

## The real remaining problem
Last fully successful `statements_marlette` run: **2026-09-21 14:35Z (9e64893d)**.
Every run since FAILED: 09-21 14:50 (e549c8dd), 09-22 13:54 (1da5c173),
09-23 13:51 (922cd666), 09-24 07:23 (7fddf1bb).

Someone is repairing asset-by-asset via the Dagster python client
(`launched_by=dagster_client`, `as_of_date: 2026-09-16:2026-09-24`, COMPUTE_WH_XS_DEV) —
NOT any of Abhishek's local Claude sessions. Done so far: marlette_transfers 08:24,
marlette_positions 08:31, marlette_to_be_purchased_positions 08:34,
edgex20261NN_marlette_cl 11:36, edgex20261NN_marlette_to_be_purchased_cl 11:38,
marlette_positions_daily 11:48.

STILL STALE AT 2026-09-21 (16 assets, all last materialized by run 9e64893d):
edgex20251NN_marlette_cl, edgex20252NN_marlette_cl, edgex2026PT1_marlette_cl,
marlette_realized_cashflows_{from_purchase,from_origination,from_first_purchase,calendar_month},
marlette_realized_cashflows_calendar_month_daily (09-22 23:09),
marlette_goldman_hyp_{warehouse_positions,warehouse_positions_daily,trigger_limits,
purchase_agreement_triggers,basis_test},
marlette_goldman_hyp_2_{warehouse_positions,warehouse_positions_daily,trigger_limits,
purchase_agreement_triggers}

The in-flight repair is only walking the edgex20261NN + positions branch. The goldman-hyp
trigger-limit / covenant and realized-cashflow branches are untouched and 3 days stale.

## NOT a data hole (checked, and my first read of this was wrong)
silver.positions for marlette stops at as_of_date 2026-09-22 for all real funds, with only
`to_be_purchased_edgex20261NN` on 09-23/09-24. That is CORRECT: silver.marlette_stmt_positions
(the servicer tape) has max as_of_date 2026-09-22. By max as_of_date marlette is the FRESHEST
platform (09-24 vs peers 09-23). Do not report a positions gap.

## Recommendation
Blocker is cleared, so one full `statements_marlette` run with the scheduled shape (empty
as_of_date, watermark-driven) rebuilds all 16 from their own 09-21 watermarks. Prefer that over
more hand-computed ranges: the 08:23 re-run itself warned "117,607 rows outside the processing
dates ... will NOT be inserted" — exactly the failure mode in [[backfill-prefer-as-of-date-all]].
Abhishek launches it (agents do not run prod jobs).

## Alert state
Zero `statements_marlette` ERROR lines in CloudWatch in the last 3h (last was 07:23Z), so the
Grafana condition has stopped even though `alert_status` still reads `triggered`. #1458 + #1457
resolve together once the full run is green.


## Environment
- taskmem: 311b993
- reported by: pd-1458
- host: ip-192-168-1-6.ap-south-1.compute.internal
- when: 2026-09-24T12:05:38Z
