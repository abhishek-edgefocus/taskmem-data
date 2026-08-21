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
updated: 2026-08-21T13:55:42Z
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
- 2026-08-19T18:10Z [claude-code] RECONFIRMED IN PROD 2026-08-19 (read-only GraphQL + Snowflake, no changes made). Nothing has moved since the 08-14/15 diagnosis:
- openroad_statement_sensor: still STOPPED, runningCount=0, zero ticks ever (still empty ticks array).
- statements_openroad job run history: still exactly ONE run in its life -- runId 8907d34a-909f-4879-b3a1-f0c174113135, SUCCESS, 2026-07-07, tags show dagster/from_ui=true (manual UI launch, no sensor tag). Confirmed via runsOrError query.
- silver.positions openroad: still 8 as-of dates, 2026-06-29..2026-07-06, 280 rows. Byte-identical to 08-12/08-15 measurements.
- bronze.statement_rows openroad positions: now 51 dates through 2026-08-18 (was 46 through 08-13 on 08-14). Bronze keeps advancing daily as expected -- gap between last silver date (07-06) and current bronze date (08-18) is now 43 days and still growing.
- bronze.statement_files openroad: still only 51 positions + 51 payments + 33 purchase_tape registered, ZERO transactions files. File-registry backfill (ordered-plan step 2) still has not been run.
- silver.predicted_cashflows openroad: unchanged, 2507 rows, prediction_type=at_orig only, max as_of_date 2024-12-12.
- GOLD.POSITIONS_COMPARISON_DAILY openroad: unchanged, 142 rows, ZERO_COMMON=141/142, last write 2026-08-11 06:03:57 PT. NEW OBSERVATION: LAST_RUN for every platform in this table is stuck around 2026-08-06..08-11 -- i.e. the comparison job itself appears to not have produced a fresh row for ANY platform in 8 days as of 2026-08-19. Not yet investigated; may be a separate, newer problem layered on top of [[wm-4s2sad]]. Worth a follow-up if no one is already on it.
- Sibling sensor check: innovate_statement_sensor and foursight_statement_sensor are also STOPPED (openroad is not alone) -- consistent with [[wm-hjbt5a]]'s '5 platform statement sensors never enabled' finding.

Bottom line: nothing has been done since 08-15. The fix is still exactly what was scoped: enable the sensor, watch the first tick, then backfill the file registry. No new blockers found.
- 2026-08-19T19:42Z [claude-code] SENSOR-REVIVAL ATTEMPTED 2026-08-19/20 — TWO REAL BLOCKERS FOUND, BOTH ROOT-CAUSED TO EXACT ERROR COUNTS. Abhishek ran statements_openroad manually from the Dagster UI with as_of_date=all on every op. Twice (runs 4b394017-ce04-47a1-b5a4-1bda1a184c41 and 14320188-8bbd-4ec6-b31e-96fa9e33ddce). Both FAILED identically.

WHAT SUCCEEDED (and this is real progress — the stmt-parsing layer scales):
openroad_stmt_positions, openroad_stmt_payments, openroad_stmt_purchase_tapes, openroad_stmt_transactions,
openroad_transactions, openroad_transactions_itd all SUCCESS across the full 51-date backlog.

WHAT FAILED — deterministic, NOT transient (identical counts on both runs):
1. openroad_transfers  — 35 validation errors
2. openroad_api_predictions — 1139 validation errors
openroad_positions + all gold/cashflow assets never ran (they depend on openroad_transfers).

*** BLOCKER 1 — CHANNELS constant omission (code defect, one-line fix, no data issue) ***
All 35 transfers errors are the SAME error: 'channel is not a canonical CHANNELS constant'.
OPENROAD_CHANNEL = 'openroad_auto_refi' is defined at
edgefocus/transformations/silver/statement_rows/openroad/constants.py:8 and is written as a hardcoded
literal into every transfers row (CHANNEL: f"'{OPENROAD_CHANNEL}'"), but 'openroad_auto_refi' was NEVER
added to the shared CHANNELS class in edgefocus/transformations/silver/statement_rows/constants.py:87.
prosper/marlette/sofi/happymoney/upgrade/northpond/upstart/anchored/lc/innovate are all registered there;
openroad is simply missing. _canonical_values_validation_sql builds its allowed list from that class via
_constant_values(), so EVERY openroad transfers row fails, in any database. Database-independent, fully
deterministic. FIX: add OPENROAD_AUTO_REFI = 'openroad_auto_refi' to CHANNELS (mirror INNOVATE_AUTO_REFI,
which is the same single-auto-refi-channel shape). Note innovate IS registered and openroad is not —
openroad looks like it was simply skipped when the canonical-values validation was introduced.

*** BLOCKER 2 — VANTAGE4 is NULL for ALL 35 openroad loans in PROD (this is DEV-1396, see [[wm-bpmxnb]]) ***
The 1139 count is EXACTLY reproduced by a read-only PROD query. Mechanism:
  SERVICING_FEE = COALESCE(payload:servicing_fee, openroad_servicing_fee_sql(vantage4))
  openroad_servicing_fee_sql returns NULL when vantage4 IS NULL or outside [350,850] (deliberate —
  'so a bad/missing credit score fails the downstream cashflow-config validation loudly').
  Validation rule requires SERVICING_FEE IS NOT NULL AND BETWEEN 0 AND 0.1.
MEASURED IN PROD (read-only, replicating the transform's own matched_loans join):
  35 loans total, 2,507 total periods (= the full row count)
  35/35 loans have VANTAGE4 NULL in PROD.SILVER.OPENROAD_OFFERS
  19 loans survive because the gateway logged payload:servicing_fee (2023-10-27 onward)
  16 loans have NO payload fee AND NULL vantage4 -> SERVICING_FEE NULL
  those 16 loans sum to exactly 1,139 periods == the 1139 Dagster errors. Exact match.
PROD.SILVER.OPENROAD_OFFERS VANTAGE4: 68,818 non-null of 6,043,026 (1.1%).
So the code's designed fallback CANNOT fire in prod because the credit score it depends on was never
ingested. The module docstring claims it 'covers all 16 pre-logging loans from their vantage score alone'
— that is true in dev and FALSE in prod. This is the same DEV-1396 gap already recorded on [[wm-hecgua]]
(#2/#3 credit_score/VANTAGE4) and [[wm-bpmxnb]]: the real TU score lives in flat model_requests/
model_responses statement files that were never ingested to bronze.

METHOD NOTE / TRAP FOR THE NEXT AGENT — dry_run=True IS NOT A VALIDATION TEST.
Transform.generate_temp_table() returns 0 immediately when dry_run=True (transform.py:264-269): it logs the
SQL and never builds the temp table, so _apply_validations is skipped entirely (it is gated on temp_rows>0).
A dry_run therefore ALWAYS 'passes' regardless of the data. I initially reported these failures as transient
on the strength of clean dry-runs; that conclusion was wrong and cost a wasted prod re-run.
ALSO: a bare snowflake.session() with ~/repos/efp/.env resolves to DEV_ABHISHEK, not PROD — dev has
1,151,134 non-null VANTAGE4 vs prod's 68,818, which is exactly why the predictions transform passes in dev
and fails in prod. Always pass database='PROD' explicitly when reproducing a prod failure.

SEQUENCING: blocker 1 is a trivial code fix and unblocks transfers -> openroad_positions -> gold. Blocker 2
gates predictions only, and depends on DEV-1396 ingestion (or an explicit decision to relax/park the
servicing-fee rule for the 16 pre-logging loans). The sensor should NOT be enabled until at least blocker 1
lands, or every tick will fail the same way.
- 2026-08-19T20:53Z [claude-code] PR RAISED FOR BLOCKER 1 + BLOCKER 2 REDIAGNOSED (2026-08-19/20).

BLOCKER 1 — PR #6393 OPEN: https://github.com/edgefocus/efp/pull/6393
  'ERROR-1711: Register openroad_auto_refi as a canonical CHANNELS constant'
  branch abhishek/openroad-channel-constant off master d195816ec, 1 file +3.
  Adds OPENROAD_AUTO_REFI to CHANNELS in statement_rows/constants.py, placed beside
  INNOVATE_AUTO_REFI. Purely additive — only OpenRoad rows carry that value, so no other
  platform's validation changes; efhyf was already in FUNDS. Verified the allowlist now resolves
  it (30 channels, was 29) and pytest edgefocus/transformations/silver/statement_rows/ is
  733 passed / 1 skipped.
  Anchored to ERROR-1711, the Dagster ticket auto-filed 2026-08-19T18:36Z for exactly these
  failing assets. ERROR-1711 covers BOTH failed assets so it should stay open until the
  predictions half is also resolved — the PR body says so explicitly.

BLOCKER 2 — NO PR NEEDED, and my earlier framing of it was incomplete. It is not 'DEV-1396 must
be built'; the ingestion and the silver wiring both already exist and are deployed. The real
defect is that PROD.SILVER.OPENROAD_OFFERS is stale for 2024/2025 and most of 2023 — those dates
were materialized before the vantage4 wiring landed on 2026-08-01 (52026b99f / PR #5974), and the
stream watermark will never revisit them. Full evidence, including a read-only proof that
re-running the transform for 2023-06-30 turns 0 scored rows into 703, is on [[wm-bpmxnb]].
FIX: backfill the openroad_offers asset (ingest_api_output job) with as_of_date=all, then re-run
statements_openroad. Still do NOT enable openroad_statement_sensor until #6393 merges.
- 2026-08-20T12:43Z [claude-code] DEV REHEARSAL 2026-08-20 — PR #6393 VALIDATED, BUT DEV_ABHISHEK CANNOT FULLY REHEARSE OPENROAD (missing Snowflake streams).

Ran the real Dagster execution path locally (dagster asset materialize / dagster job execute against
definitions.py, PYTHONPATH pinned to ~/claude-ws/openroad-fixes/efp) with as_of_date=all, targeting
DEV_ABHISHEK behind a guard that aborts if CURRENT_DATABASE()=PROD.

WHAT PASSED (run directly via the Transform classes, before the Dagster attempt):
  openroad_transfers        SUCCESS  35 inserted / 35 deleted   <- WAS 35 validation errors on master.
                            Log line: 'All validation checks passed'. This is a clean before/after
                            for PR #6393 in the same DB on the same data: 35 errors -> 0.
  openroad_api_predictions  SUCCESS  2,507 inserted / 2,507 deleted.

WHAT FAILED, AND WHY IT IS NOT A PROD RISK:
  openroad_offers               FAILED - Object 'DEV_ABHISHEK.SILVER.OPENROAD_OFFERS_STREAM' does not exist
  openroad_stmt_positions       FAILED - OPENROAD_STMT_POSITIONS_STREAM does not exist
  openroad_stmt_payments        FAILED - OPENROAD_STMT_PAYMENTS_STREAM does not exist
  openroad_stmt_purchase_tapes  FAILED - OPENROAD_STMT_PURCHASE_TAPES_STREAM does not exist

ROOT CAUSE: the Snowflake STREAM objects the Transform framework uses for change tracking are
Terraform-managed (snowflake_stream_on_table, e.g. terraform/snowflake/silver_openroad_offers.tf:428),
NOT created by application code. DEV_ABHISHEK was never provisioned with OpenRoad's.
  PROD.SILVER          117 streams, incl. all 5 OPENROAD_* streams
  DEV_ABHISHEK.SILVER   16 streams, ZERO openroad
Watermarks ARE auto-created by the code ('Ensuring watermark exists for pipeline...'); streams are not.

WHY transfers/predictions still ran in dev: they write to the SHARED tables silver.transfers and
silver.predictions, whose streams do exist in DEV_ABHISHEK. Only the platform-specific
silver.openroad_* targets need the missing streams. That asymmetry is worth remembering — it makes
dev look partially functional for a platform it cannot actually rehearse.

CONSEQUENCE FOR ABHISHEK'S DEV-FIRST HABIT ([[validate-in-dev-abhishek-first]]): for OpenRoad, a full
dev rehearsal is not currently possible. To enable one, the 5 OPENROAD_* streams must be created in
DEV_ABHISHEK (dev-only DDL, mirroring the terraform, reversible via DROP STREAM). Otherwise the
openroad_offers backfill goes to prod without an operational rehearsal — its OUTCOME is well evidenced
(see [[wm-bpmxnb]]) but its RUNTIME behaviour at ~6M rows / 1,197 dates is untested anywhere.

TIMING DATA STILL OBTAINED: the offers attempt failed after 4m24s and the statements job after 2m6s,
both on stream lookup, so neither figure says anything about the real rebuild cost.

NOTE: a first attempt at loading definitions.py resolved the 'orchestration' package to ~/repos/efp
(another agent's live checkout) because that venv has the repo installed editable. Fixed by exporting
PYTHONPATH=<my workspace>:<my workspace>/lib. Nothing was written from that checkout, but any agent
running Dagster from ~/claude-ws must pin PYTHONPATH or it will silently execute another agent's code.
- 2026-08-20T13:58Z [claude-code] DEV REHEARSAL NOW COMPLETE — the gap the previous rehearsal hit is closed, and the openroad_offers
backfill is far cheaper than assumed (2026-08-20).

FIXED THE BLOCKER: created the 5 missing OPENROAD_* streams in DEV_ABHISHEK.SILVER, mirroring the
terraform (plain CREATE STREAM ... ON TABLE, mode=DEFAULT type=DELTA — matching prod exactly).
All 5 base tables already existed in dev; only the streams were absent because they are
Terraform-managed and dev was never provisioned. Dev-only DDL, reversible via DROP STREAM.
  DEV_ABHISHEK.SILVER openroad streams: 0 -> 5
  Verified against PROD.SILVER's 5 (OPENROAD_OFFERS_STREAM, _STMT_POSITIONS_, _STMT_PAYMENTS_,
  _STMT_PURCHASE_TAPES_, _STMT_TRANSACTIONS_STREAM).

THE REHEARSAL — openroad_offers, as_of_date=all, DEV_ABHISHEK, guarded to abort on PROD:
  SUCCESS in 1.8 MINUTES
  rows_inserted 5,758,444 / rows_deleted 5,758,444 across 1,170 as-of dates
  warehouse COMPUTE_WH_XS_PROD (the transform default)
  before/after VANTAGE4 on the 15 prod-empty dates: 29,241 both times -> IDEMPOTENT, as expected
  since dev already held the scores.

WHAT THIS SETTLES:
1. RUNTIME IS A NON-ISSUE. I had advised sizing up the warehouse for ~6M rows; that was wrong.
   The full rebuild is ~2 minutes on XS. Prod is comparable scale (6,043,026 rows / 1,197 dates
   vs dev's 5,758,444 / 1,170), so expect the same order of magnitude. No warehouse change needed.
2. THE OPERATION EXECUTES CLEANLY END TO END at full scale — the one thing that had never been
   tested anywhere. Combined with the read-only outcome proof on [[wm-bpmxnb]] (1,139 -> 0 failing
   rows), both the outcome AND the operation are now evidenced.
3. IT IS IDEMPOTENT — re-running produces identical output, so a prod re-run is safe if interrupted.

WHAT IT STILL DOES NOT PROVE: dev's offers already carried scores, so the rehearsal could not
reproduce prod's 0 -> ~29,241 transition on those dates. That transition is evidenced separately
and read-only (prod would produce 703 scored rows for 2023-06-30 where it currently holds 0).

PROD READINESS: the openroad_offers backfill is now low-risk — ~2 min, XS warehouse, idempotent,
rehearsed at scale. Remaining blockers are unchanged: a REVIEWER on PR #6393, and that PR being
DEPLOYED (not merely merged) before statements_openroad is re-run.
- 2026-08-20T14:42Z [claude-code] *** CLEAN END-TO-END RUN ACHIEVED IN DEV_ABHISHEK 2026-08-20 — 15/15 assets, RUN_SUCCESS, exit 0. ***
runId b649b636-23f4-4050-9df0-60de97bcac7f, full statements_openroad job via the real Dagster
execution path (dagster job execute -f orchestration/definitions.py -j statements_openroad),
as_of_date=all on every op, PYTHONPATH pinned to ~/claude-ws/openroad-fixes/efp, guarded to abort
if the session resolved to PROD.

ALL FIFTEEN GREEN:
  openroad_stmt_purchase_tapes   openroad_stmt_positions   openroad_stmt_payments
  openroad_stmt_transactions     openroad_transactions     openroad_transactions_itd
  openroad_transfers             openroad_positions        openroad_api_predictions
  openroad_positions_daily       openroad_realized_cashflows_from_origination
  openroad_realized_cashflows_from_purchase
  openroad_realized_cashflows_from_first_purchase
  openroad_realized_cashflows_calendar_month
  openroad_realized_cashflows_calendar_month_daily

This is the first time the OpenRoad chain has EVER run end to end anywhere. openroad_positions and
the entire gold/cashflow tail had never executed in any environment before today.

HOW WE GOT THERE — three fixes, only ONE of which is code:
1. CODE: PR #6393 registers openroad_auto_refi in CHANNELS. openroad_transfers went 35 validation
   errors -> SUCCESS. This is the only change that ships to prod.
2. DEV PROVISIONING: created the 5 OPENROAD_* streams in DEV_ABHISHEK.SILVER (offers, stmt_positions,
   stmt_payments, stmt_purchase_tapes, stmt_transactions). Unblocked the 4 stmt_* assets.
3. DEV PROVISIONING: created 2 more streams dev lacked but prod has —
   BRONZE.GOOGLE_SHEET_TRANSFERS_STREAM and SILVER.REALIZED_CASHFLOWS_CALENDAR_MONTH_STREAM.
   Unblocked openroad_realized_cashflows_calendar_month, the last failure (run 1 was 13/15).
Items 2 and 3 are DEV-ONLY provisioning gaps — prod already has all 117 streams. They are not prod
risks and require no PR; they exist because the streams are Terraform-managed and DEV_ABHISHEK was
never provisioned for OpenRoad. All are reversible via DROP STREAM.

METHOD NOTE: run 1 (13/15) and run 2 (15/15) used identical code and config; the only delta was the
2 streams. So the failures were provisioning, not flakiness — and the job is repeatable.

ONE OPEN ASYMMETRY, FLAGGED NOT RESOLVED: SILVER.REALIZED_CASHFLOWS_FROM_ORIGINATION has NO stream in
PROD either (dev lacks it too). openroad_realized_cashflows_from_first_purchase, which sources from
it, passed in dev WITHOUT that stream in both runs — so it appears genuinely unneeded rather than a
latent prod failure. Worth remembering if that asset ever fails in prod on a stream lookup.

PROD PICTURE NOW: both prod blockers are demonstrably fixed. Remaining prod steps unchanged —
  (a) get PR #6393 reviewed, merged AND DEPLOYED (merge alone is not enough; prod Dagster runs an image),
  (b) backfill openroad_offers (ingest_api_output job, as_of_date=all) — rehearsed at 1.8 min /
      5.76M rows on XS, idempotent,
  (c) re-run statements_openroad, then enable openroad_statement_sensor.
- 2026-08-20T18:45Z [pr-manager] PR #6393 description rewritten (pr-manager tab, 2026-08-20). Removed the failure narration Abhishek objected to: the two FAILURE run rows (4b394017 / 14320188), the pasted 'channel is not a canonical CHANNELS constant' log sample, and the Python REPL constant check. Validation section now cites the green DEV_ABHISHEK run b649b636-23f4-4050-9df0-60de97bcac7f — openroad_transfers 35 deleted / 35 inserted, 3m1s, statements_openroad exit 0. NOTE: the earlier rehearsal (reh_stmt.log, run 7a9ce5e6) did NOT validate #6393 — openroad_transfers was skipped there because openroad_stmt_positions/purchase_tapes failed on missing DEV_ABHISHEK streams. The validation comes from the later run only.
- 2026-08-20T21:13Z [claude-code] PR #6393 EXTENDED 2026-08-20 with the channel-literal cleanup, at Abhishek's instruction (relayed from
another agent's suggestion; he wanted it in ONE PR, not a follow-up). Now 2 commits, 5 files, +17/-7.

  f732bd521  Register openroad_auto_refi as a canonical CHANNELS constant
  888cd76a6  Source the OpenRoad channel from CHANNELS instead of repeating the literal

WHERE I DIVERGED FROM THE SUGGESTED PLAN — two things, both worth remembering:
1. THE SUGGESTED LIST MISSED THE ROOT DUPLICATE. It named 6 leaf usages but not
   openroad/constants.py:8 OPENROAD_CHANNEL = 'openroad_auto_refi', which is the literal that feeds
   positions.py and transfers.py — i.e. the CHANNEL value actually written into silver.positions and
   silver.transfers. Following the list verbatim would have cleaned the leaves and left the trunk.
   Fixed by pointing OPENROAD_CHANNEL at CHANNELS.OPENROAD_AUTO_REFI, which single-sources both
   callers without editing either file. No circular import: the shared constants module imports only
   dataclasses, and openroad/constants.py imported nothing.
2. THE SUGGESTED SWEEP WAS INCOMPLETE. It flagged cashflow_config_history_git.py:87 but missed
   cashflow_config_history_overrides.py:23 and modeling/dq_rates/constants.py:74. All three are
   deliberately left alone (channel-keyed config DATA, not references) and the PR body now says so
   explicitly, so it doesn't read as an oversight.

ON cashflow_config_history_git.py:87 — the caution was right but the reason is stronger than 'it is a
dict key': the file header says 'Auto-generated ... DO NOT EDIT THIS FILE MANUALLY', regenerated by
generate_cashflow_config_history.py. Any edit would be silently reverted on the next regeneration.

THE 'PROVE IT IS BYTE-IDENTICAL' CONSTRAINT — satisfied, and the risk it guarded against did not
exist. All three openroad_offers.py SQL hits are inside the single f-string already opened at
generate_sql (line 55), so nothing needed converting to an f-string. Dumped fully-generated SQL
before and after:
  diff -r  ->  IDENTICAL, no differences
  md5 openroad_offers                26702f2ce60af49938cdabfd66d69e4f  MATCH
  md5 openroad_api_predictions       f784668773dce88ed04fcbf625598aef  MATCH
  md5 openroad_api_credit_attributes aaa900a1d02a66e1a4e6f15723821bc7  MATCH
  md5 openroad_transfers             53bd635c87a8c9b54f970eff5e439cc0  MATCH
OpenroadPositions builds via generate_temp_table, not generate_sql, so it is absent from that dump —
checked separately, COLUMN_MAPPING['CHANNEL'] still resolves to "'openroad_auto_refi'".

RE-VALIDATED ON THE EDITED BRANCH (the PR's evidence now matches what is in it):
  openroad_transfers vs DEV_ABHISHEK: '3 validation checks ... All validation checks passed',
  35 inserted / 35 deleted. pytest edgefocus/transformations/silver/ 1,608 passed / 1 skipped.
  ruff check + ruff format --check clean.

JUDGEMENT CALL FLAGGED TO REVIEWERS IN THE PR BODY: this makes OpenRoad the ONLY platform whose
transforms reference CHANNELS — innovate, anchored, lc etc. all still hardcode their own literal.
Better pattern, but inconsistent with its siblings, and it grew the PR from 1 file/+3 to 5 files/+17.

PR retitled to match: 'ERROR-1711: Register openroad_auto_refi in CHANNELS and source every OpenRoad
usage from it'. Still OPEN, mergeStateStatus BLOCKED on review only. A REVIEWER remains the single
bottleneck — no analysis work is outstanding on this PR.
- 2026-08-21T11:48Z [pr-manager] PR #6393 merged 2026-08-21 11:11. Merge alone does not fix prod: needs (1) the prod Dagster image deploy, (2) the independent silver.openroad_offers backfill (as_of_date all, ingest_api_output), then re-run statements_openroad and enable openroad_statement_sensor. ERROR-1711 stays open until the offers backfill lands.
- 2026-08-21T13:10Z [claude-code] PR #6393 MERGED AND DEPLOYED 2026-08-21 — blocker 1 is cleared in prod. Blocker 2 (the offers
backfill) is now the only thing left before statements_openroad can go green.

MERGE + DEPLOY CONFIRMED:
  PR #6393 state=MERGED, mergedAt 2026-08-21T11:11:21Z, merge commit db7676ea7a931545b0d1cb7743923895fceb5e96.
  Prod Dagster code location 'definitions.py' updatedTimestamp 2026-08-21T11:40:44Z, loadStatus=LOADED
  — i.e. it reloaded 29 minutes AFTER the merge, so the CHANNELS fix is live in the running image.
  (Inferred from the reload timestamp, not from reading the image contents; the first
  openroad_transfers run in prod is what will confirm it empirically — expect 35 errors -> 0.)

PROD STILL NOT BACKFILLED, measured 2026-08-21 13:09 UTC — silver.openroad_offers VANTAGE4 by year:
  2023  3,021 of   606,366     (235 dates)
  2024      0 of 1,734,909     (366 dates)   <- still zero
  2025      0 of 1,864,432     (365 dates)   <- still zero
  2026 73,929 of 1,864,375     (233 dates)
Unchanged in shape from 2026-08-19; 2026 has grown (66,348 -> 73,929) purely from daily incremental
runs, which is exactly the pattern predicted: new dates get scores, history never revisits.

NEXT ACTION IS ABHISHEK'S (per [[no-agent-prod-runs]] — agents hand over the Launchpad link and run
config, he launches prod jobs himself):
  Asset: openroad_offers  (job ingest_api_output — NOT statements_openroad)
  Config: as_of_date: all, warehouse: COMPUTE_WH_XS_PROD
  MUST be scoped to openroad_offers alone. Launching the whole ingest_api_output job with
  as_of_date=all would rebuild all 14 platforms' offers, including upgrade's ~735M model_requests rows.
  Expected: ~2 minutes on XS (dev rehearsal did 5,758,444 rows / 1,170 dates in 1.8 min); prod is
  6,043,026 rows / 1,197 dates, same order of magnitude. Idempotent — safe to re-run if interrupted.
  Then re-run statements_openroad (as_of_date=all), then enable openroad_statement_sensor.

WAREHOUSE ADVICE RETRACTED: I earlier recommended sizing up above COMPUTE_WH_XS_PROD for the ~6M-row
rebuild. The dev rehearsal showed that was unnecessary — XS does the full history in under 2 minutes.
Use the default.
- 2026-08-21T13:29Z [claude-code] BOTH PROD BLOCKERS NOW CLEARED 2026-08-21 — only the job re-run and the sensor remain.
1. PR #6393 merged 11:11:21Z and DEPLOYED (prod code location reloaded 11:40:44Z, 29 min later).
2. openroad_offers backfilled in prod — run 36bc64b2-ee4c-437c-a344-92f4e7f38a3a SUCCESS, 13.1 min.
   VANTAGE4 2024/2025 went 0 -> 343,596 / 200,469. Predictions failing rows 1,139 -> 0, 35/35 loans
   scored. Full numbers on [[wm-bpmxnb]].

NEXT, and it is Abhishek's to launch: re-run statements_openroad (as_of_date=all) in prod.
EXPECTED: openroad_transfers 35 validation errors -> 0 (this is also the empirical confirmation that
the deployed image really carries the CHANNELS fix — the 11:40 reload timestamp is strong evidence
but not proof), openroad_api_predictions 1,139 -> 0, and openroad_positions plus the gold/cashflow
tail running in prod for the first time ever. Dev did exactly this at 15/15 (run b649b636).
THEN: enable openroad_statement_sensor, or silver refreezes the moment new bronze lands. The silver
gap is currently 46 days (silver stops 2026-07-06, bronze runs to 2026-08-19).
Watch the first sensor tick — [[wm-hjbt5a]] records other platform sensors failing every tick.
- 2026-08-21T13:55Z [claude-code] *** THE OPENROAD SILVER CHAIN IS ALIVE IN PROD — 2026-08-21. The core defect this item was opened for
is FIXED. ***
statements_openroad run 0790581c-46ec-4f49-9e7e-0f1d0c5a6cae: STATUS SUCCESS, 15/15 assets, 12.1 min.
First time the OpenRoad chain has ever completed in prod, and the first time openroad_positions and
the gold/cashflow tail have run there at all.

THE GAP IS CLOSED — silver now matches bronze exactly:
  PROD.SILVER.POSITIONS openroad   8 dates / 280 rows  ->  52 dates / 1,820 rows, 2026-06-29..2026-08-19
  PROD.BRONZE.STATEMENT_ROWS       52 dates / 1,820 rows, 2026-06-29..2026-08-19
Zero unconsumed dates. The 46-day stall that opened on 2026-07-07 is gone.

OTHER LONG-STANDING DEFECTS THIS RUN ALSO CLEARED (all previously recorded as open on this item):
  silver.transfers openroad: EFP_ID was NULL on 35/35 and FROM_FUND NULL on 35/35 since the 07-29
    audit. Now 35/35 rows with EFP_ID set and TO_FUND set.
  silver.predictions openroad: was 2,507 rows still APP_ID-keyed (openroad_4675720...) with 0 of 35
    ids joining to silver.positions. Now 2,435 rows / 34 ids, GENERATION_TS 2026-08-21 06:43 PT, and
    34 join to positions. The APP_ID/EFP_ID keying mismatch from DEV-1393 is resolved in prod data.
  gold.positions_daily openroad: now populated, 52 rows through 2026-08-19.

TWO THINGS NOT YET DONE — do not close this item on the run alone:
1. openroad_statement_sensor is STILL STOPPED. Nothing has changed about the root cause: the job ran
   because Abhishek launched it by hand, exactly as on 2026-07-07. Silver will refreeze the moment
   tomorrow's bronze lands unless the sensor is enabled. THIS IS THE ACTUAL FIX FOR THIS ITEM.
   Watch the first tick — [[wm-hjbt5a]] records other platform sensors failing on every tick.
2. GOLD.POSITIONS_COMPARISON_DAILY has NOT refreshed: still 142 rows, last run 2026-08-11 06:03 PT,
   ZERO_COMMON 141/142. That is pre-fix state — the comparison job runs on its own daily schedule and
   has not executed since the backfill. The honest completion test recorded on [[wm-jr5bup]] is
   COMMON_COUNT going non-zero, so that is still PENDING and will be answered by the next scheduled
   comparison run (~06:03 PT). Do not claim the board is fixed until it re-runs.

MINOR DISCREPANCY WORTH A LOOK, NOT A BLOCKER: predictions covers 34 ids but silver.positions has 35
loans, so one loan has no prediction row. Unexplained; predictions max as_of_date is 2024-12-12,
consistent with purchase tapes stopping then. Flagging rather than chasing.
