---
id: wm-7mtzka
type: task
title: Fix silver.transactions ACCOUNT_ID for northpond (derive from fund, not raw tape)
status: next
priority: p2
size: s
tags: [northpond]
created: 2026-07-17T13:50:10Z
updated: 2026-07-17T13:50:36Z
source: claude-code
---

Found 2026-07-17 while doing DEV-1450 (see [[wm-u7d75w]]).

## Problem
edgefocus/transformations/silver/statement_rows/northpond/transactions.py maps
  "ACCOUNT_ID": "t.ACCOUNT_NAME"
and transactions_service_fees.py maps "ACCOUNT_ID": "p.ACCOUNT_NAME".
The NorthPond daily transaction tape ALWAYS arrives under ef_northpond, so silver.transactions
reports ACCOUNT_ID='ef_northpond' for 100% of rows (verified: only value present, 87251 rows).
But 79.4% of those rows (69303/87251) belong to loans that are northpond_efhyf in silver.positions.

The legacy datastore resolves account_name per as-of date against the purchase tape
(base_statement_northpond.adjust_fund_information), so legacy transaction rows correctly
report northpond_efhyf once a loan is purchased into EFHYF.

## Why it matters
silver.positions already does this right: positions.py uses account_id_from_fund_expr(
fund_col='p.FUND', fallback_col='p.ACCOUNT_NAME') mapping fund->account
(NORTHPOND_FUND_ACCOUNT_MAP in northpond/constants.py). transactions.py just never got the
same treatment. So positions and transactions DISAGREE on account identity for the same loan.

## Workaround shipped in DEV-1450
northpond added to PLATFORM_NULL_COLUMNS in transactions_snowflake_map.py so the datastore
Snowflake routing returns account_id=NULL rather than a silently-wrong ef_northpond
(same call as marlette). Fixing silver properly would let that NULLing be removed.

## Fix sketch
Apply account_id_from_fund_expr to northpond transactions.py + transactions_service_fees.py.
Note transactions rows need the fund AS OF the transaction date (not current fund) to match
legacy semantics -- positions.py gets fund per as-of row already; check how t.FUND is sourced.
Requires a silver backfill. Check downstream consumers of transactions.account_id first.

No Linear issue yet -- worth filing under the NorthPond Data Ingestion project.
