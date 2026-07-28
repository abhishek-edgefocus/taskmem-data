---
id: wm-7mtzka
type: task
title: Fix silver.transactions ACCOUNT_ID for northpond (derive from fund, not raw tape)
status: next
priority: p2
size: s
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-u7d75w]
created: 2026-07-17T13:50:10Z
updated: 2026-07-28T17:42:03Z
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

## Log
- 2026-07-20T15:35Z [claude-code] Full-history data comparison (2026-07-20, repos-2) CONFIRMS this bug with hard numbers. Legacy datastore derives account_id per-fund: fund=efhyf -> 'northpond_efhyf' (66,207 rows), fund=experimental -> 'ef_northpond' (21,476). silver.transactions emits raw tape ACCOUNT_NAME='ef_northpond' for BOTH funds (65,585 + 21,022). Net: 65,574 silver rows carry the wrong ACCOUNT_ID (60,985 payments leg + 4,589 service-fee leg) - every efhyf-fund row. Zero mismatches on the experimental fund. So the fix is exactly as scoped: derive ACCOUNT_ID from FUND ('northpond_' || fund) rather than t.ACCOUNT_NAME, in both transactions.py and transactions_service_fees.py. This is the single largest value-level divergence between the two systems.
- 2026-07-20T19:55Z [claude-code] PROD verification 2026-07-21 (~/repos/efp, database='PROD'). Suspicion CONFIRMED, and now measured on prod rather than dev. (1) silver.transactions PLATFORM='northpond' has exactly ONE distinct ACCOUNT_ID: 'ef_northpond', across all 87,647 rows and both SOURCE legs. (2) silver.positions latest snapshot 2026-07-20 carries BOTH: ef_northpond/experimental (343 loans) and northpond_efhyf/efhyf (372 loans). (3) Join on EFP_ID: 69,534 txn rows / 372 loans = 79.33% DISAGREE with positions; 18,113 rows / 343 loans agree; 0 orphans. (4) Mechanism confirmed in code at HEAD (162a7660a, both sides COMMITTED not local edits): transactions.py:80 'ACCOUNT_ID': 't.ACCOUNT_NAME' and transactions_service_fees.py:76 'p.ACCOUNT_NAME' are raw pass-through, while positions.py:94 uses _ACCOUNT_ID_EXPR = account_id_from_fund_expr(fund_col='p.FUND', fallback_col='p.ACCOUNT_NAME') at line 257. The helper + NORTHPOND_FUND_ACCOUNT_MAP already exist in northpond/constants.py with a docstring stating exactly this rationale - so the fix is to reuse the existing helper in the two transactions transforms, keyed on FUND (which IS correct in transactions). Raw tape verified 100% 'ef_northpond' for both funds in northpond_stmt_transactions AND northpond_stmt_positions, so pass-through can never recover efhyf. SCOPE/URGENCY REVISION: impact today is LATENT, not live. No gold transform, no transactions_itd, no cashflow transform reads transactions.ACCOUNT_ID (grep: zero hits). gold.positions_daily has NO account column at all. Scanned all 174 Grafana dashboards / 8,661 panels / 7,334 SQL queries: ZERO reference silver.transactions in SQL (earlier apparent hits were markdown/text, not queries). And northpond has ZERO entries in datastore_deprecations.py on HEAD, so legacy consumers still read the legacy datastore, which has the CORRECT per-fund account_id. => Nothing is reading a wrong answer today. BUT it becomes live the moment northpond is added to DEPRECATION_REGISTRY, which is exactly wm-u7d75w (status review). SEQUENCING: land this ACCOUNT_ID fix BEFORE the deprecation registry entry, or follow the marlette precedent in transactions_snowflake_map.py PLATFORM_NULL_COLUMNS (marlette returns transactions.account_id as NULL rather than a wrong value, because positions is authoritative). CONTEXT: pass-through is the NORM, not a northpond coding error - marlette/prosper/sofi/innovate transactions.py all use t.ACCOUNT_NAME. NorthPond is uniquely harmed because its tape arrives under one account while its loans span two funds; it is the only platform in silver.transactions with fewer distinct ACCOUNT_IDs (1) than FUNDs (2).
- 2026-07-20T19:57Z [claude-code] 2026-07-21 merge-status check + refinement of my own earlier advice. Verified on branch abhishek/dev-1450-deprecate-northpond-datastores (~/repos-2/efp): northpond IS in datastore_deprecations.py (2 entries) AND the PLATFORM_NULL_COLUMNS workaround IS present, with a full explanatory paragraph in the transactions_snowflake_map.py module docstring. That branch is NOT merged to main - on main HEAD, northpond has zero deprecation entries and PLATFORM_NULL_COLUMNS contains only marlette. So the registry entry and its NULL guard land TOGETHER, in the same PR. CORRECTION to what I said earlier today: I flagged a sequencing risk that this fix must land BEFORE the deprecation registry entry or consumers would start reading a wrong account_id. That risk is already mitigated - the DEV-1450 branch pairs the routing entry with the account_id NULL, so no consumer can ever receive the wrong value via routing, merged or not. This item is therefore genuinely p2/cleanup: its payoff is being able to REMOVE northpond from PLATFORM_NULL_COLUMNS and have transactions.account_id be correct rather than absent, not preventing a live wrong answer. Also note the body's row counts (87,251 total / 69,303 efhyf) are 2026-07-17 DEV figures; PROD on 2026-07-21 gives 87,647 total / 69,534 efhyf / 372 loans / 79.33% - same picture, minor drift from ingestion since.
- 2026-07-20T20:12Z [claude-code] 2026-07-21 FIX IMPLEMENTED + VERIFIED. PR #5967 https://github.com/edgefocus/efp/pull/5967 branch abhishek/fix-northpond-transactions-account-id off origin/master (built in ~/repos-2/efp). Change: both legs now use account_id_from_fund_expr() keyed on FUND - transactions.py fund_col='t.FUND', transactions_service_fees.py fund_col='p.FUND', each with ACCOUNT_NAME as fallback. 46 insertions / 2 deletions across 3 files (2 transforms + transactions_test.py). Added test_account_id_derived_from_fund_not_tape to both SQL test classes. Northpond unit suite 166 passed; ruff check, ruff format --check, mypy all clean. VERIFIED against DEV_ABHISHEK by materializing both assets through the local dockerised dagster (docker exec dagster-webserver-abhishek, dagster asset materialize --select ... --config-json as_of_date=all): efhyf rows now northpond_efhyf (65,585), experimental stay ef_northpond (21,022). REGRESSION-CLEAN: row counts and every amount total byte-identical to pre-fix baseline (payments 77,919 / 1,391,247.26 / prin 888,161.75 / int 503,085.51; fees 8,688 / -18,607.65), FUND split unchanged, no other platform touched - confirming an account_id-only change. Point-in-time agreement with silver.positions went 20.7% -> 99.6%. RESIDUAL 372 rows EXPLAINED AND CORRECT: they are the experimental-portion service-fee rows of the 372 mid-month-purchased loans (purchase offsets 8-23 days before month-end); the fee subquery groups by FUND so such a loan emits two fee rows per month, one per fund, both posted on LAST_DAY - the experimental row differs from the month-end positions row by design. The 3,359 'latest-basis' disagreements = those 372 + 2,987 genuinely pre-purchase experimental-era transactions; 'latest positions' is simply the wrong yardstick post-fix. ENV NOTE (not caused by this change): both dagster materializations report RUN_FAILURE AFTER the data commits, at 'Consuming TRANSACTIONS stream' - DEV_ABHISHEK.SILVER.TRANSACTIONS_STREAM does not exist (only POSITIONS_STREAM and REALIZED_CASHFLOWS_CALENDAR_MONTH_STREAM do). Same class of dev drift as the openroad PREDICTIONS_STREAM issue in wm-bvqkhh. Data is correct; the traceback is a sandbox artifact. Reproduced identically on both assets. PROCESS NOTE: the abhishek dagster containers bind-mount ~/repos/efp (NOT repos-2), so testing required temporarily copying the 2 transforms into ~/repos/efp; they were backed up to ~/tmp/np_acctid_backup and restored afterwards (md5-verified identical), leaving that working tree exactly as found. NEXT: after merge, remove northpond from PLATFORM_NULL_COLUMNS in transactions_snowflake_map.py (see wm-u7d75w), and re-materialize prod silver.transactions for northpond (delete+insert = full replay of 87,647 rows).
- 2026-07-28T17:39Z [claude-code] RECONCILED 2026-07-28 (GitHub): PR #5967 is OPEN and STILL A DRAFT, REVIEW_REQUIRED, no approval, untouched since 2026-07-20T20:16Z — eight days idle. Same pattern as #5704 and #5974: verified work sitting behind a draft flag rather than behind a reviewer. No Linear ticket exists for this one (noted in the body as still worth filing under NorthPond Data Ingestion).
- 2026-07-28T17:42Z [claude-code] review -> next 2026-07-28, same reasoning as [[wm-gxykru]]: PR #5967 is a DRAFT with no review requested, so nobody is holding this but Abhishek. 'review' implied someone else owed a response and made the item look parked when it is actionable in a minute.
