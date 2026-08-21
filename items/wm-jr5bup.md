---
id: wm-jr5bup
type: task
title: OpenRoad: revive the dead silver chain, then clear everything stacked behind it
status: active
size: xl
people: [Abhijeet, Frank]
tags: [openroad, datastores, dagster]
links: [parent:wm-su6q4d, relates:wm-hjbt5a]
refs: [DEV-1486=https://linear.app/edge-focus/issue/DEV-1486/deprecate-openroad-datastores]
created: 2026-08-14T14:56:46Z
updated: 2026-08-21T17:53:44Z
source: claude-code
label: OpenRoad revive + deprecate
---

Container for the one genuinely sequential run of OpenRoad work. Created 2026-08-14 while
restructuring the memory into ordered threads: these three steps were siblings under the OpenRoad
project alongside half a dozen unrelated items, so the ordering — which is stated explicitly in
each of their bodies — was invisible in every view.

THE SEQUENCE, and why it is a real dependency and not a preference:

1. The silver chain is dead. `openroad_statement_sensor` is STOPPED in prod Dagster and has NEVER
   ticked; `statements_openroad` has exactly one run in its whole history, launched by hand from
   the UI on 2026-07-07. Silver stops at 2026-07-06 while bronze runs to 2026-08-11 — 36 as-of
   dates sitting unconsumed. The fix is an operational toggle, not a PR.
2. Deprecation has to wait for that, in the item's own words: running the file-registry backfill
   first "would park ~2,150 files in bronze and produce nothing in silver, because the consumer is
   dead."
3. The verified-differences file has to wait for both, because registering by-design differences
   against a table that is a month stale and ~1,070 dates short would paper over the first two
   problems rather than answer Frank's question.

NOT in this sequence, and deliberately so: salvaging the untracked comparison docs is urgent and
unblocked (the only copy is in a stale checkout on dpx), and the FULLY_PAID_DATE mapping, the
CMOP/BEP work and the model_requests ingestion are all independent OpenRoad work that stays
directly under the project.

## Next steps
- Check prod Dagster, then enable `openroad_statement_sensor` — but watch the first tick, since
  three other platform jobs currently fail on every sensor run.
- Render the order with `taskmem chain` on this item (the id is in the frontmatter above).

## Links
- DEV-1486 — https://linear.app/edge-focus/issue/DEV-1486/deprecate-openroad-datastores
- Prod Dagster — https://dagster-prod.edgefocuspartners.com
- Project: [[wm-su6q4d]]
- The broader sensor audit this came out of: [[wm-hjbt5a]]

## Log
- 2026-08-14T19:55Z [claude-code] RESCOPED 2026-08-15 on Abhishek's instruction, after measuring prod. He asked for the OpenRoad
thread to cover what is actually pending — Frank's verified-differences question, CMOP/BEP, and
the comparison board that shows no data — rather than just the deprecation run.

The body above says CMOP/BEP stays outside this sequence. THAT IS NO LONGER TRUE and the title has
been changed to match. The reason is a prod measurement taken today: PROD.SILVER.PREDICTED_CASHFLOWS
for openroad holds only prediction_type='at_orig', 2,507 rows, max as_of_date 2024-12-12.
Predictions are derived downstream of positions, and silver.positions openroad stops at
2026-07-06 — so CMOP/BEP is blocked behind the same dead chain as everything else, not parallel
to it. It is now step 4.

THE COMPARISON BOARD, which is the third thing Abhishek named: it is not off. The job runs daily
and last wrote 2026-08-11 with as_of through 2026-08-09 — but COMMON_COUNT=0 on 141 of 142 dates,
because there is almost no Snowflake data to compare the legacy datastore against. So it is the
same root cause again, and it needs no item of its own: reviving the chain is what fixes the board,
and confirming COMMON_COUNT goes non-zero is the honest completion test for step 1. Full numbers,
including the cross-platform pattern, are on [[wm-85nuv4]] and [[wm-4s2sad]].

FOUR STEPS NOW, all four blocked behind the same operational toggle:
  1. revive the silver chain (enable openroad_statement_sensor, watch the first tick)
  2. deprecate the datastores
  3. write openroad_verified.py and answer Frank
  4. enable CMOP + BEP
Still outside the sequence and genuinely unblocked: salvaging the untracked comparison docs
([[wm-hecgua]] — the only copy is in a stale checkout), the FULLY_PAID_DATE mapping
([[wm-ay9uu3]]) and the model_requests ingestion ([[wm-bpmxnb]]).
- 2026-08-20T18:50Z [claude-code] 2026-08-21 00:18 IST: PR #6393 (openroad_auto_refi CHANNELS constant) posted for review in #platform-data-owners. Dev chain proved end-to-end 15/15 RUN_SUCCESS; offers backfill rehearsed (1.8 min, 5.76M rows, idempotent) but NOT yet run in prod.
- 2026-08-21T17:53Z [claude-code] STEP 1 OF 4 IS DONE 2026-08-21 — the dead silver chain is revived. Steps 2-4 remain.

WHAT LANDED TODAY (full evidence on [[wm-85nuv4]] and [[wm-bpmxnb]]):
  - PR #6393 merged + deployed (CHANNELS constant) -> openroad_transfers 35 errors -> 0.
  - openroad_offers backfilled in prod (as_of_date=all, 13.1 min) -> VANTAGE4 ~77K -> ~1.25M rows,
    which cleared openroad_api_predictions 1,139 errors -> 0.
  - statements_openroad SUCCESS, all 15 assets, first ever completion on the automated path.
  - silver.positions openroad 8 dates/280 rows -> 52 dates/1,820 rows, exactly matching bronze.
  - CREDIT_SCORE 0/280 populated -> 1,768/1,820. predictions<->positions join 0 -> 34 ids.
  - openroad_statement_sensor switched ON and ticking (was STOPPED, 0 ticks ever).

NEXT STEPS, in order:
1. TOMORROW (2026-08-22): confirm the sensor's first REAL tick launches statements_openroad on new
   openroad bronze data and that the run succeeds unattended. So far it has only skipped. This is the
   only part of the revival never tested.
2. Step 2 of this chain — the datastore deprecation ([[wm-prm54n]]) — is still blocked on the
   file-registry backfill. Today's work made silver CURRENT (52 dates) but not DEEP: bronze still
   holds only ~52 of ~1,119 available loan-tape days. Deprecation is meaningless until that runs.
3. Step 3 openroad_verified.py ([[wm-skvqac]]) and step 4 CMOP/BEP ([[wm-xe6w4q]]) are now unblocked
   by the chain being alive, though CMOP/BEP additionally needs silver.predicted_cashflows
   re-materialised (still max as_of_date 2024-12-12 with the NaN fee rows — a separate process from
   openroad_api_predictions).

ALSO OPEN, not owned by any item: GOLD.POSITIONS_COMPARISON_DAILY has not run for ANY platform since
2026-08-06..08-11, so the openroad board still reads 141/142 zero-common and the honest completion
test for this revival cannot be evaluated yet. Tracked at [[wm-4s2sad]].
