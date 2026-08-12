---
id: wm-85nuv4
type: task
title: OpenRoad silver chain stopped at 2026-07-06 while bronze runs to 2026-08-11
status: next
priority: high
size: m
tags: [openroad, datastores]
created: 2026-08-12T13:03:24Z
updated: 2026-08-12T13:03:29Z
source: claude-code
effort: half-day
---

Found 2026-08-12 while measuring OpenRoad prod DQ for [[wm-prm54n]]. This is a
SEPARATE defect from the missing history backfill, and it is the more urgent one:
the pipeline is not merely un-backfilled, it has STOPPED ADVANCING.

PROD, measured 2026-08-12 06:00 UTC:
- bronze.statement_rows openroad positions: 1,540 rows / 44 dates, through 2026-08-11.
- silver.positions openroad: 280 rows / 35 loans / 8 dates, 2026-06-29..2026-07-06.
=> 36 as-of dates of bronze positions data sitting unconsumed. Gap opened ~2026-07-07,
now 37 days wide and growing daily.

Not a platform-wide outage — every other platform advanced normally:
anchored/prosper/sofi/northpond 2026-08-11, marlette/happymoney 08-10, upgrade 08-07,
lc 08-02, upstart 07-26. Only openroad froze.

TIMING IS SUSPICIOUS: silver stops 2026-07-06/07; silver.predicted_cashflows openroad
last loaded_at is 2026-07-07 14:02 and silver.predictions max as_of_date is 2024-12-12.
The whole openroad silver/prediction chain looks like it last ran on 2026-07-07 and has
not run since. Check whether the statements_openroad job (orchestration/jobs/
statements_openroad.py, 9 assets) is still in the prod Dagster job selection / has an
active schedule or sensor, or was dropped. [[wm-j523sq]] already flagged
"openroad_* chain uniformly 8d stale (possible dead sensor)" back in July — that
observation was right and nothing was done; it is now 37d.

WHY IT MATTERS NOW: PR #6133 merged 2026-08-03, so DatastorePositions/
DatastoreTransactions for openroad route to Snowflake in prod. A frozen silver chain
means that routing serves an ever-staler 8-date window with no error.

FIRST STEP: find out whether the job is scheduled and when it last ran in prod
Dagster, before assuming a data problem — a dropped schedule and a failing asset need
different fixes.
