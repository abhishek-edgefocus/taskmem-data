---
id: wm-4s2sad
type: task
title: Datastore-vs-Snowflake comparison job dead since 2026-07-20 (all 11 platforms)
status: open
priority: p1
size: s
tags: [data-quality]
links: [relates:wm-srzcyx, relates:wm-rzfews, relates:wm-wcawuj, relates:wm-hjbt5a, relates:wm-85nuv4]
created: 2026-07-29T16:38:34Z
updated: 2026-08-14T19:55:18Z
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

## Log
- 2026-08-12T13:03Z [claude-code] PARTIAL CORRECTION 2026-08-12 — this item says the datastore-vs-Snowflake comparison job has been dead since 2026-07-20 for all 11 platforms. That is no longer true. PROD.gold.positions_comparison_daily last ran 2026-08-11 06:03-06:04 and holds as_of_date through 2026-08-09 for anchored, happymoney, innovate, lc, openroad, sofi, upstart (142 rows each); upgrade to 08-08 (updated 08-10); marlette to 08-05 (updated 08-07); northpond to 08-03 and prosper to 08-02 (both updated 08-06). So the job recovered — but marlette/northpond/prosper are each 4-9 days behind the rest, which may be a second, narrower problem worth a look.
- 2026-08-14T19:55Z [claude-code] SCOPE CORRECTION 2026-08-15, extending the 2026-08-12 partial correction.

This item's title and body are now wrong in both directions and should be read as history, not as
current state. Re-measured PROD.GOLD.POSITIONS_COMPARISON_DAILY today:

The job is NOT dead. It last wrote 2026-08-11 06:03-06:04 PT with as_of_date through 2026-08-09
for anchored, happymoney, innovate, lc, openroad, sofi, upstart (142 rows each). The original
"dead since 2026-07-20, all 11 platforms" finding was true when written and resolved itself.

WHAT IS ACTUALLY WRONG NOW is two narrower things:
1. FOUR PLATFORMS LAG THE REST: northpond as_of 2026-08-03 (written 08-06), prosper 08-02
   (08-06), marlette 08-05 (08-07), upgrade 08-08 (08-10). For northpond that is explained —
   statements_northpond has been failing on every sensor tick ([[wm-te4cr2]], [[wm-hjbt5a]]).
2. THE BOARDS RUN BUT COMPARE NOTHING. COMMON_COUNT=0 on innovate 142/142, openroad 141/142,
   upstart 134/142, lc 133/142, anchored 102/142. The first four are exactly the platforms whose
   statement sensors have never ticked, so silver has almost nothing for the comparison to match
   against. Detail and the full table on [[wm-85nuv4]].

So the freshness alert this item proposed in step 3 is still the right idea, but it would not have
caught either of these — both boards are fresh and both are meaningless. The check that matters is
COMMON_COUNT, not UPDATED_AT. Anchored is the one case not explained by a stopped sensor and is
worth a separate look.
