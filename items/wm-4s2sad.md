---
id: wm-4s2sad
type: task
title: Datastore-vs-Snowflake comparison job dead since 2026-07-20 (all 11 platforms)
status: open
priority: p1
size: s
tags: [data-quality]
links: [relates:wm-srzcyx]
created: 2026-07-29T16:38:34Z
updated: 2026-07-29T16:38:34Z
source: claude-code
---

GOLD.POSITIONS_COMPARISON_DAILY has produced no rows since 2026-07-20 06:03-06:04 PT. Found 2026-07-28 while validating PR #6058.

It is a daily T+1 job: one row per platform per day, written ~06:0x PT for the previous day. Last writes, all within a 90-second window on 2026-07-20:
  upstart, upgrade, sofi, prosper, openroad, northpond, marlette, lc, innovate — 2026-07-20 06:03-06:04, latest AS_OF_DATE 2026-07-18/19
  happymoney — 2026-07-18 (latest as-of 07-16)
  anchored — 2026-07-17 (latest as-of 07-15)
Not a NorthPond problem — every platform stopped together, which points at the job/schedule rather than any one transform.

WHY IT MATTERS: every positions comparison dashboard is now frozen at 2026-07-19 and silently so — the panels render, they are just stale. Anyone reading a board today is looking at 9-day-old data without a warning.

## Next steps
1. Find what writes GOLD.POSITIONS_COMPARISON_DAILY (compare_daily_summary.py) and whether its Dagster schedule/cron is failing or was disabled.
2. Backfill 2026-07-20 onward once it runs again.
3. Consider a freshness alert — a board that stops updating currently looks identical to a board with no new mismatches.

## Provenance
Query: SELECT PLATFORM, MAX(UPDATED_AT), MAX(AS_OF_DATE), COUNT(*) FROM DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY GROUP BY 1. Read-only, 2026-07-28.
