---
id: wm-85nuv4
type: task
title: OpenRoad silver chain stopped at 2026-07-06 while bronze runs to 2026-08-11
status: next
priority: high
size: m
tags: [openroad, datastores]
links: [relates:wm-prm54n, blocks:wm-prm54n, blocks:wm-skvqac, parent:wm-jr5bup, blocks:wm-xe6w4q]
created: 2026-08-12T13:03:24Z
updated: 2026-08-14T19:55:50Z
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

## Log
- 2026-08-12T13:09Z [claude-code] ROOT CAUSE NARROWED 2026-08-12 — the openroad silver job has NOT RUN SINCE 2026-07-07. Every openroad silver table carries the same last-write timestamp cluster on 2026-07-07 ~13:00 PT and nothing after:
  openroad_stmt_positions   2026-07-07 12:59:45 (280 rows)
  openroad_stmt_payments    2026-07-07 12:59:45 (7)
  openroad_stmt_purchase_tapes 2026-07-07 13:00:12 (35)
  silver.transactions openroad 2026-07-07 13:00:21 (7)
  silver.transfers openroad    2026-07-07 13:00:52 (35)
  silver.positions openroad    2026-07-07 13:01:57 (280)
  (and silver.predicted_cashflows openroad loaded_at 2026-07-07 14:02)
Peers write daily: northpond silver.positions last_write 2026-08-11 11:59, sofi 2026-08-12 04:28. So this is openroad-specific, not a platform-wide outage.

NOT A CODE GAP: the sensor IS registered on origin/master exactly like every other platform — definitions.py:406-408 create_platform_statement_sensor('openroad', statements_openroad, max_runtime=2h), job at jobs/statements_openroad.py with 15 documented assets. So the fix is operational, not a PR: either the sensor is toggled OFF in the prod Dagster instance, or the job is erroring on an asset. Check prod Dagster run history for statements_openroad since 2026-07-07 before touching anything.

BRONZE IS HEALTHY — this is important for sequencing: bronze.statement_rows openroad positions has all 44 dates 2026-06-29..2026-08-11 at exactly 35 rows/date (1,540 total). The bronze ingest job is running fine. Only the silver step is dead.

=> ORDERING CONSEQUENCE for [[wm-prm54n]]: running the file-registry backfill FIRST would park ~2,150 files in bronze and produce nothing in silver, because the consumer is dead. Revive/diagnose this job before or alongside the backfill.
- 2026-08-12T13:47Z [claude-code] ROOT CAUSE CONFIRMED FROM PROD DAGSTER 2026-08-12 (read-only GraphQL, https://dagster-prod.edgefocuspartners.com/graphql, version 1.12.14, no writes):

**openroad_statement_sensor is STOPPED and has NEVER TICKED.** sensorState: status=STOPPED, runningCount=0, ticks=0. Not 'it broke on 07-07' — it was never switched on in prod.

**statements_openroad has exactly ONE run in its entire history**: runId 8907d34a-909f-4879-b3a1-f0c174113135, SUCCESS, 2026-07-07 19:59-20:02 UTC (= 12:59-13:02 PT — matches the silver table write timestamps to the minute). Tags show dagster/from_ui=true and NO dagster/sensor_name => it was launched by hand from the Dagster UI during development. openroad silver has therefore never been produced by an automated run, ever.

This closes the diagnosis: the fix is to enable the sensor in the prod Dagster UI (an operational toggle, no PR). The job code and the sensor registration on origin/master are both correct — definitions.py:406-408, minIntervalSeconds=30, target statements_openroad.

CAUTION BEFORE FLIPPING IT: with the sensor off, no one has ever seen this job run unattended. Turning it on will start it consuming the 44 bronze dates already queued, and then whatever the backfill adds. Watch the first tick — three OTHER platform jobs are currently failing every sensor run (see the new sensor audit item).
- 2026-08-14T19:55Z [claude-code] MEASURED IN PROD 2026-08-15 (read-only, PROD.GOLD / PROD.SILVER / PROD.BRONZE) — the gap is now
38 days and this is what it is doing to the comparison board.

STILL DEAD, unchanged since the 2026-08-12 diagnosis:
  PROD.SILVER.POSITIONS openroad    8 as-of dates, 2026-06-29..2026-07-06,   280 rows
  PROD.BRONZE.STATEMENT_ROWS openroad positions   46 dates, through 2026-08-13, 1,610 rows
So bronze has kept ingesting daily and silver has consumed none of it. 38 dates unconsumed, two
more than on 08-12.

THE CONSEQUENCE ABHISHEK REMEMBERED — "the comparison dashboard was off, there was no data inside
OpenRoad" — is real, and it is worse than the board being off:
  PROD.GOLD.POSITIONS_COMPARISON_DAILY, openroad: 142 rows, as_of through 2026-08-09,
  last written 2026-08-11 06:03 PT — and COMMON_COUNT = 0 on 141 of those 142 dates.
The comparison job is HEALTHY and running on schedule. It renders a board every day that reports
nothing in common between the legacy datastore and Snowflake, because Snowflake only has 8 dates
to compare. A dead board would at least look dead; this one looks fine and says zero.

NOT AN OPENROAD-ONLY PATTERN — the zero-common counts line up almost exactly with the never-ticked
sensors from [[wm-hjbt5a]]:
  innovate 142/142 zero    (sensor never ticked)
  openroad 141/142         (sensor never ticked)
  upstart  134/142         (sensor never ticked)
  lc       133/142         (sensor never ticked)
  anchored 102/142         (sensor healthy — so this one needs a different explanation)
  sofi 14, prosper 15, marlette 17, upgrade 30, happymoney 76, northpond 93
That is strong evidence the sensor audit and the comparison-coverage problem are the same problem
seen from two ends, and that fixing the sensors is what makes the boards meaningful.

ALSO WORTH KNOWING BEFORE THE CMOP/BEP WORK: PROD.SILVER.PREDICTED_CASHFLOWS for openroad holds
only prediction_type='at_orig', 2,507 rows, max as_of_date 2024-12-12. OpenRoad predictions are
effectively not being produced at all. Logged on [[wm-xe6w4q]] too.

Query kept at /tmp/or_cmp.py on dpx; run it from ~/repos/efp with .env sourced.
