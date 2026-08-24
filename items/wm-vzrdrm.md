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
updated: 2026-08-24T12:47:54Z
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

## Log
- 2026-08-24T12:39Z [claude-code] HOW TO ACTUALLY RUN IT, investigated 2026-08-24. The next-steps above were too optimistic: the prod job CANNOT do this repair, and we cannot write to prod at all.

THE CODE (edgefocus/transformations/silver/comparison/compare_daily_summary.py, 691 lines):
- Two modes. --backfill auto-detects (date, platform) pairs MISSING from the gold table, inside a
  30-day window (DEFAULT_BACKFILL_DAYS=30). Manual mode (--platform/--start-date/--end-date --write)
  does a DELETE+INSERT for exactly the dates given, so only manual mode can overwrite existing rows.
- The prod Dagster asset positions_comparison_backfill calls run_backfill() only. openroad has zero
  missing dates (154 rows, 2026-03-21..2026-08-21, no gaps), so the prod job will never revisit the
  bad rows no matter how many times it ticks. Repairing prod REQUIRES a code change first — a
  date-range/force path on the asset, or a run config it can take.
- Destination database is NOT a flag: write_to_snowflake always writes to the env-derived database
  (get_database_name(): ENVIRONMENT=dev + USERNAME=ABHISHEK -> DEV_ABHISHEK). --source-database only
  chooses where silver.positions is READ from.

WE CANNOT WRITE TO PROD, FULL STOP. SHOW GRANTS TO USER ABHISHEK returns exactly two roles:
DB_CREATOR (owns the DEV_* databases) and PROD_READONLY. A DELETE against PROD.GOLD would be denied.
So the prod half is not an approval question, it is a permissions wall — it needs the prod Dagster
deployment's own role.

THE DEV RUN IS FULLY OURS, no prod interaction (reads only):
  cd <workspace>/efp
  uv run python -m edgefocus.transformations.silver.comparison.compare_daily_summary \
    --platform openroad --start-date 2026-03-21 --end-date 2026-08-09 \
    --source-database PROD --warehouse COMPUTE_WH_XS_DEV --write
Reads PROD.SILVER.POSITIONS (read-only) plus the datastore parquet from s3://efp-derived/datastores
(read-only, AWS creds present on dpx), writes DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY. Pass
--warehouse explicitly: the script defaults to COMPUTE_WH_XS_PROD but .env is COMPUTE_WH_XS_DEV.
Feasibility confirmed: datastore index 1901 has all 142 dates in range (openroad 1120 dates total,
2023-07-24..2026-08-16). The board reads DEV_ABHISHEK by default, so this alone makes it readable.

BONUS the title implies: the datastore has openroad back to 2023-07-24 and silver back to
2023-07-20, so genuine full history (~1120 dates) is computable into DEV_ABHISHEK — the table
starting at 2026-03-21 is just where someone started, not a data limit. See [[wm-2994t7]] item 3.
- 2026-08-24T12:47Z [claude-code] RUN STARTED 2026-08-24 12:46 PT on dpx, isolated workspace ~/claude-ws/openroad-cmp/efp (fresh clone of main @ 5c0005322, own .venv via uv sync, .env copied from ~/repos/efp). Full range 2026-03-21..2026-08-09, 142 dates, ~11.5s/date measured, so ~27 min. Log: /tmp/or_backfill.log on dpx.

SCHEMA DRIFT HIT ON THE FIRST TRY, worth knowing before anyone else writes this table from dev:
DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY was missing the FULLY_PAID_DATE FLOAT column that
PROD has (added by the DEV-1539 mapping work, [[wm-ay9uu3]]). Every other column matched. The
insert died with 'invalid identifier FULLY_PAID_DATE' — and because write_to_snowflake does
DELETE-then-INSERT, the DELETE had already committed, so the two smoke-test dates were dropped
and not replaced. No data loss in the end (both are inside the repair range and get regenerated),
but the failure mode is worth remembering: a failed write of this table LOSES the old rows.
Fixed with ALTER TABLE DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY ADD COLUMN FULLY_PAID_DATE
FLOAT; the schema diff against PROD is now empty. Re-ran the 2-date smoke test clean:
COMMON_COUNT 35, EXTRA_IN_DATASTORE 0, real mismatch percentages where March previously held
nothing (APPLICATION_ID 97.14, POOL_ID 100, EF_SCORE 97.14).
