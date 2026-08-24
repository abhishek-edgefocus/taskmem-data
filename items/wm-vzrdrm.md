---
id: wm-vzrdrm
type: task
title: Backfill positions_comparison_daily for openroad 2026-03-21..2026-08-09 (board is blank, not stale)
status: open
priority: p1
size: s
tags: [openroad, datastores, data-quality]
links: [relates:wm-4s2sad, parent:wm-jr5bup]
created: 2026-08-24T12:27:48Z
updated: 2026-08-24T12:28:10Z
source: claude-code
---

Found 2026-08-24 answering "why is the OpenRoad SF-vs-Datastore dashboard not updated"
(https://grafana.edgefocuspartners.com/d/openroad-sfvsds-fullhist/, var-database=PROD).

THE BOARD IS FRESH BUT EMPTY. PROD.GOLD.POSITIONS_COMPARISON_DAILY has openroad rows through
as_of 2026-08-21, written today at 06:04 PT. The panels have nothing to draw because
COMMON_COUNT=0 on every date from 2026-03-21 to 2026-08-09 — with 0 loans matched, every
mismatch-pct column is NULL, so all 14 mismatch timeseries render blank. Only 2026-08-10..08-21
(12 dates) carry COMMON_COUNT=35 and real percentages.

WHY THOSE ROWS ARE WRONG AND WON'T SELF-HEAL: they were computed while the openroad silver
chain was dead ([[wm-jr5bup]]), so silver had no positions to match and the comparison booked
all 35 loans as EXTRA_IN_DATASTORE. Silver was rebuilt 2026-08-22 00:42 PT and now covers
2023-07-20..2026-08-24 with no gaps, but the comparison job only rewrites a ~10-day rolling
window (its 2026-08-22 15:56 run touched exactly 08-10..08-19). Everything older keeps its
original 08-06..08-11 UPDATED_AT and its wrong zeros. See [[wm-4s2sad]] for the mechanism.

## Next steps
1. Re-run compare_daily_summary.py for platform=openroad over as_of 2026-03-21..2026-08-09
   (142 dates) in PROD. Confirm COMMON_COUNT goes to 35 across the range.
2. Same check for the other platforms whose sensors were down — innovate, upstart, lc,
   anchored all showed COMMON_COUNT=0 on most dates in the 2026-08-15 audit.
3. Only then read the board's mismatch percentages as meaningful, and only then register the
   by-design differences ([[wm-skvqac]]).

## Provenance
Read-only, 2026-08-24, PROD: freshness and COMMON_COUNT by date on
GOLD.POSITIONS_COMPARISON_DAILY; UPDATED_AT by as-of month on SILVER.POSITIONS.
