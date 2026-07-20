---
id: wm-srzcyx
type: task
title: NorthPond silver ingestion stalled since 2026-07-07 (13 days of transactions missing)
status: open
priority: p1
size: s
tags: [northpond]
created: 2026-07-20T15:35:53Z
updated: 2026-07-20T19:55:07Z
source: claude-code
---

## Problem
Found during the 2026-07-20 full-history transactions comparison (repos-2 on dpx).

- silver.northpond_stmt_transactions: max AS_OF_DATE = 2026-07-07, LAST_ALTERED = 2026-07-07 13:06 PT
- silver.northpond_stmt_positions: max 2026-07-07, LAST_ALTERED 2026-07-07 13:06 PT
- silver.transactions LAST_ALTERED 2026-07-08 01:13 PT

Meanwhile the legacy datastore has daily files through 2026-07-19 (742 files, 2024-07-08..2026-07-19).

Impact: 1,037 legacy transaction rows (as_of 2026-07-07..2026-07-18) have no silver counterpart. This is 100% of the row-count gap on the payments leg - once the stale window is excluded, legacy has ZERO rows missing from silver.

## Why it matters
Any Snowflake-backed NorthPond dashboard (DEV-1395 fund monitoring) is showing data ~13 days stale. Blocks calling the migration validated in prod.

## Next
Find out why the northpond bronze->silver statement ingestion stopped after 2026-07-07 (dagster schedule? sensor? SFTP sync?). Re-run and confirm max AS_OF_DATE catches up to the tape.

## Log
- 2026-07-20T19:55Z [claude-code] CORRECTION (2026-07-21): this item OVERSTATED the impact. I filed it off DEV_ABHISHEK numbers - the earlier comparison ran snowflake.execute() with no database= arg, which defaults to DEV_{USERNAME}, NOT prod. Re-checked against PROD today: silver.transactions, silver.positions AND silver.northpond_stmt_transactions all have max(AS_OF_DATE) = 2026-07-20, i.e. fully current. So there is NO prod ingestion gap and NO stale-dashboard impact - the 'DEV-1395 dashboards serving 13-day-old data' claim in the original body is WRONG. The stall is confined to the DEV_ABHISHEK sandbox copy (stalled 2026-07-07). Downgrading: this is a dev-env refresh chore, not a p1 prod incident. Lesson for future comparisons: always pass database='PROD' explicitly when making claims about prod.
