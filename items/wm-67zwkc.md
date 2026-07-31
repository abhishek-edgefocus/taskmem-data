---
id: wm-67zwkc
type: task
title: Set up gold tables + metrics for OpenRoad (positions_daily + realized cashflows)
status: next
priority: p1
size: m
tags: [openroad, gold]
created: 2026-07-31T18:52:58Z
updated: 2026-07-31T18:53:02Z
source: claude-code
---

Sizing done 2026-08-01 against origin/master (~/repos/efp @ 162a7660a) after Abhishek asked
"how big a deal is it, is it just wiring?". Answer: mostly wiring, ~420-480 LOC additive,
8 files, ZERO shared-code edits. The real cost is backfill + dashboard, not code.

## What OpenRoad already has (gold)
- gold.offers_daily / offers_bucketed via openroad_offers_daily.py, openroad_offers_bucketed.py,
  openroad_config.py — wired into orchestration/jobs/ingest_api_output.py.
- gold predicted cashflows (predicted_cashflows_mob / _calendar_month / _from_purch / aggregate)
  are PLATFORM-AGNOSTIC single assets (GROUPING SETS over platform). openroad_api_predictions is
  already a dep of the `predicted_cashflows` asset -> OpenRoad gets these FOR FREE once PR #5974
  lands and predictions re-materialise. No per-platform file needed.

## What is missing (the actual work)
New files (all thin subclasses of existing shared builders):
  edgefocus/transformations/gold/openroad_positions_daily.py                         ~38 LOC
  edgefocus/transformations/gold/openroad_realized_cashflows_calendar_month_daily.py ~20 LOC
  silver/cashflows/openroad_realized_cashflows_from_origination.py                   ~60
  silver/cashflows/openroad_realized_cashflows_from_purchase.py                      ~60-73
  silver/cashflows/openroad_realized_cashflows_from_first_purchase.py                ~55
  silver/cashflows/openroad_realized_cashflows_calendar_month.py                     ~106-129
Wiring:
  orchestration/assets/openroad_assets.py   — 6 create_transform_asset blocks + imports (~70-90)
  orchestration/jobs/statements_openroad.py — add the 6 asset names to the selection (~15)

## The one part that is NOT copy-paste
openroad_realized_cashflows_calendar_month needs deliberate overrides, unlike northpond's
(northpond took every default because its transactions are 100% description='payment'):
- OpenRoad silver.transactions DOES emit description='recovery' rows
  (silver/statement_rows/openroad/transactions.py: PAYMENT_TYPE='RECOVERY' -> 'recovery').
  -> recovery_amount_expr must be chosen, cf. sofi/marlette/upgrade (115-129 LOC each).
- OpenRoad splits fees into late + collection only; no service-fee accrual asset exists
  (northpond has northpond_transactions_service_fees, OpenRoad has no counterpart)
  -> decide what feeds daily_fees / net_cash_flow in gold.positions_daily.
- transaction_type_filter: check whether OpenRoad transfers/acquisitions leak into
  net_cash_flow the way upgrade's did.
FUND is fine: constant 'EFHYF' for OpenRoad and already in target_stream_group_by on
silver.positions, so the (as_of_date, platform, fund) grain of positions_daily works.

## Backfill (carry the northpond lessons from [[wm-qs96kd]])
- No AutoMaterializePolicy anywhere in orchestration/ -> assets outside a job selection NEVER
  materialise. Adding to statements_openroad is mandatory, not cosmetic.
- All assets unpartitioned -> "backfill all" = one run with as_of_date:'all', not an N-date backfill.
- The 4 cashflow classes set reload_all_on_change=True and self-rebuild; positions_daily does NOT
  -> it specifically needs an explicit as_of_date:'all' first run.
- Dep order: wave1 = positions_daily, from_origination, from_purchase, calendar_month;
  wave2 = calendar_month_daily.

## The bigger cost sits outside the repo
- Grafana: there is no OpenRoad monitoring dashboard. Dashboard JSON lives only in Grafana
  (not in git), so panels are hand-built. NorthPond's equivalent page is ~80 panels, 31 of them
  fed by exactly these gold tables. That, not the Python, is where the days go.
- BEP unblock: best_est overlays realized actuals on predictions, so it reads
  silver.realized_cashflows_from_origination. OpenRoad has 0 rows there today ->
  this item is a hard prerequisite for [[wm-xe6w4q]] (CMOP + BEP for OpenRoad).

## Sequencing
Gated on PR #5974 (DEV-1331) merging + prod re-materialisation ([[wm-bvqkhh]]).
Relevant to the 2026-08-03 deprecation milestone ([[wm-prm54n]]) — UNRESOLVED whether the
gold layer is in scope for that date or follow-on; Abhijeet has not been asked directly.
