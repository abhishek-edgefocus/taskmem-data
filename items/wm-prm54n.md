---
id: wm-prm54n
type: task
title: Deprecate OpenRoad datastores by 2026-08-03 (milestone at 0%)
status: next
priority: p1
size: l
due: 2026-08-03
people: [Abhijeet]
tags: [openroad, datastores]
links: [parent:wm-su6q4d, relates:wm-bvqkhh, relates:wm-tvjjgw]
created: 2026-07-29T15:33:30Z
updated: 2026-07-29T16:44:06Z
source: claude-code
label: OpenRoad datastore deprecation
---

Abhijeet asked directly in DM 2026-07-29 19:50 IST (D0B2A3WSJ5N): "openroad deprecate
datastores on track to be done by 3rd aug?" — so he is actively tracking this to a date.

CONFIRMED IN LINEAR 2026-07-29: OpenRoad Data Ingestion project milestones —
- Validate positions   — 100%, target 2026-07-08 (hit)
- Validate predictions —  25%, target 2026-07-31  (= DEV-1331, its only issue, now In
                                                    Review; [[wm-bvqkhh]])
- **Deprecate datastores — 0%, target 2026-08-03**  <- this item
Project lead is Abhijeet. The deprecation milestone has not started.

WHAT ABHISHEK TOLD HIM (same exchange):
- The openroad predictions PR is up and review-requested from Abhijeet ("baghto").
- Abhijeet: "tech urlay na phakta?" (is that the only thing left?) — Abhishek: "Ekda check
  karava lagel I think mostly ho" (need to check once, I think mostly yes). **That check is
  an open action and is the first step here** — the answer given was hedged, and the
  milestone reads 0%, which does not match "mostly only that left".
- Abhijeet then asked whether BEP was added — it is not; CMOP and BEP are outstanding for
  BOTH platforms (OpenRoad and NorthPond). Tracked separately.

SEQUENCING: predictions validation (2026-07-31) gates this (2026-08-03) — three days apart,
and the predictions PR still needs Abhijeet's approval, then prod re-materialisation and a
notebook re-run before DEV-1331 can close. That is a tight chain; if the PR sits, 08-03
slips.

Adjacent risk on the NorthPond side, same theme: [[wm-tvjjgw]] (legacy northpond datastore
silently starving as Oliv moves files).

## Log
- 2026-07-29T16:44Z [claude-code] READINESS AUDIT 2026-07-29 (Linear + master code + PROD Snowflake + S3). The 08-03 milestone is not reachable as scoped; the registry PR is the small part, the data is the blocker.

1. LINEAR: 'Deprecate datastores' milestone (b4cc3095, target 2026-08-03) contains ZERO issues — 0% is 'nothing tracked', not 'not started'. Project target 2026-08-04, lead Abhijeet. Northpond's equivalent was DEV-1450. A ticket has to be created before anything else.

2. PRIMARY BLOCKER — Snowflake does not hold OpenRoad history. S3 s3://efp-raw/statements/openroad/ has 1,101 LoanTape_Edge_Orl files (2023-07-24..2026-07-28), 1,080 Payments_Edge_Orl (2023-08-14..2026-07-28), 29 Transactions_Edge_Orl (2023-07-25..2024-12-18), 33 funding tapes. PROD bronze.statement_rows openroad: positions 1,050 rows/30 dates (2026-06-29..07-28), payments 26 rows/15 dates, purchase_tape 38 rows/33 dates. PROD silver: openroad_stmt_positions 280 rows/8 dates; openroad_stmt_payments 7 rows/4 dates; openroad_stmt_transactions 0 ROWS (empty); openroad_stmt_purchase_tapes 35 rows/31 dates (only healthy one). silver.positions openroad = 280 rows/35 loans/8 dates; silver.transactions openroad = 7 ROWS/6 loans. So source='snowflake' routing would serve 8 of 1,101 days of positions and 7 transaction rows. ~1,070 loan-tape days + ~1,065 payment days + 29 transaction days need bronze ingest then the full silver chain, IN PROD. The pipeline itself is fully wired (orchestration/jobs/statements_openroad.py, 9 assets) — this is a data backfill, not code.

3. PARITY/QUALITY GAPS that a comparison would fail on today:
- silver.positions openroad CREDIT_SCORE + CREDIT_SCORE_AT_PURCHASE 280/280 NULL. Legacy reads vantage4Score via StatementGatewayGetOffers/StatementResponses; that is DEV-1396, still Todo and NOT attached to the project or any milestone. silver.openroad_offers VANTAGE4 = 3,021 non-null of 5,821,315.
- FIRST_PAYMENT_DUE_DATE 280/280 NULL -> MOB = accrual+1; PR #5974's MOB alignment is unverifiable until the history backfill restores early snapshots ([[wm-bvqkhh]] 12:37Z entry).
- silver.transfers openroad: 35 rows, EFP_ID NULL on all 35, FROM_FUND NULL on all 35.
- silver.predictions openroad still APP_ID-keyed (openroad_4675720..5392528), last generation_ts 2026-07-07 13:00 — prod never re-materialized after DEV-1393; joins 0/35 to silver.positions.
- silver.predicted_cashflows openroad: FEES 0/2507, NET_CASH_FLOW 0/2507, RECOVERY 140/2507, loaded_at 2026-07-07 — the NaN-config corruption; PR #5974 fixes it but only post-merge + prod rebuild.
- silver.positions openroad is single account/fund ('Edge - ORL' / efhyf) — no fund movement, unlike northpond.

4. THE DEPRECATION PR ITSELF — NOT STARTED. openroad has ZERO hits in datastore_deprecations.py (sofi/prosper/marlette/happymoney/upgrade/northpond all registered). Needs 2 entries: ('DatastorePositions','openroad') -> silver.positions and ('DatastoreTransactions','openroad') -> silver.transactions, plus the same two judgement calls northpond had (positions_snowflake_map.PLATFORM_RENAMES; HISTORY_DERIVED_PLATFORMS; transactions_snowflake_map.PLATFORM_NULL_COLUMNS). Early read: legacy openroad has no fund/account adjustment at all (DatastoreStandardizedPositionsOpenroad sets channel='openroad_auto_refi', purchase_date='Funded Date' from StatementFunding deduped to one row per loan) => origination/funding-anchored like northpond, NOT history-derived — but confirm with a column diff. Note openroad's classes are DatastoreStandardizedPositionsOpenroad / DatastoreTransactionsOpenroad(BaseDatastoreTransactionsFoursight); maybe_warn_deprecated keys on self.__class__.__name__, so verify the registry key actually fires for the openroad call path (northpond used the base names). No code outside lib/efp/stats/datastores/openroad/ imports the legacy classes — only two docstring/comment mentions in silver openroad transactions.py and orchestration/assets/openroad_assets.py.

5. TRANSACTIONS PARITY HAS NEVER BEEN RUN for openroad. Milestones cover positions (DEV-1350, Done) and predictions (DEV-1331, In Review); northpond had DEV-1275 + DEV-1332 covering BOTH before registering. With silver.transactions at 7 rows there is nothing to compare yet anyway.

6. GATING CHAIN unchanged: DEV-1331 / PR #5974 needs Abhijeet's approval -> merge -> prod rebuild in the mandatory order (openroad_offers FIRST, then a forced full predictions reprocess) -> notebook re-run -> close. Then the backfill, then parity, then the registry PR. CMOP/BEP scope for 08-03 still unresolved ([[wm-xe6w4q]]).
