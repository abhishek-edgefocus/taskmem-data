---
id: wm-cqgb5n
type: task
title: Backfill northpond silver so prod stops holding two fund names at once
status: next
priority: p1
size: m
people: [Abhijeet]
tags: [northpond, edgex, backfill]
links: [follows:wm-qtjmcv, follows:wm-7qqeke, parent:wm-j523sq, parent:wm-4sxy5d]
refs: [PR-6209=https://github.com/edgefocus/efp/pull/6209]
created: 2026-08-12T13:29:24Z
updated: 2026-08-14T14:55:28Z
source: claude-code
label: northpond fund backfill
---

Both northpond fund changes are merged and deployed, but neither migrated existing rows, so PROD currently serves the same fund under two different names and the first live EDGEX purchase sits on the wrong one. Verified directly against PROD 2026-08-12.

Two merged PRs caused this, both by design — silver is written by `snowflake.delete_and_insert` per as_of_date, not a conditional MERGE, so only a full as_of_date backfill rewrites history:

1. **[[wm-qtjmcv]] / PR #6208** (merged 2026-08-11T19:50Z, `42db18e68`) renamed FUNDS.EXPERIMENTAL value `experimental` -> `northpond_balancesheet`. Prod now writes the new name forward only: `silver.northpond_stmt_positions` has 156,155 rows still saying `experimental` (latest as_of 2026-08-11) and 343 saying `northpond_balancesheet` (as_of 2026-08-12). Every downstream group-by splits across the two.

2. **[[wm-7qqeke]] / PR #6209** (merged 2026-08-11T21:48Z, `804310be3`) split the purchase-tape fund on `NORTHPOND_EDGEX_PURCHASE_START = 2026-08-01`. The 29 first-ever live Oliv purchase rows landed 2026-08-11 22:38 UTC with PURCHASE_DATE=2026-08-11 and were written *before* the deploy, so `silver.northpond_stmt_purchase_tapes` stores FUND=`efhyf` for them when the merged rule says `edgex20261NN`. MAX(AS_OF_DATE) on that table is still 2026-08-11.

The second one is the time-sensitive half. The 29 loans are not yet in `silver.northpond_stmt_positions` (0 of 29 matched at any as_of) because Oliv's loan tape has not picked them up — Nate, 2026-08-12: "there can be a few day delay to get into the NN file but once there it's always there". The moment they land, positions evaluates the *new* expression and reports `edgex20261NN` while `transfers.TO_FUND` reads the tape's *stored* `efhyf`. Rebuilding the purchase tape before that happens avoids the disagreement rather than repairing it.

## Next steps
1. Rebuild `silver.northpond_stmt_purchase_tapes` (as_of 2026-08-11 is enough for the EDGEX half) and confirm the 29 rows flip to `edgex20261NN`.
2. Run the full as_of_date backfill for the rename: `northpond_stmt_positions`, `northpond_stmt_transactions`, `silver.positions`, and `silver.transfers` — the transfers leg is easy to forget and is 777 rows with POOL_ID like `%experimental%`, 715 TO_FUND, 372 FROM_FUND.
3. Re-count both funds afterwards; `experimental` should return zero rows and the POOL_IDs should read `..._northpond_northpond_balancesheet` (name repetition is expected — Abhishek decided 2026-08-11 to keep `northpond_balancesheet` over `npbs` knowing this).
4. Scheduled jobs carry a 2h max_runtime kill, so launch these from the Dagster UI launchpad, not the schedule.

## Links
- PR #6208 (rename) — https://github.com/edgefocus/efp/pull/6208
- PR #6209 (EDGEX date split) — https://github.com/edgefocus/efp/pull/6209
- DEV-1509 — https://linear.app/edge-focus/issue/DEV-1509/rename-experimental-northpond-fund
