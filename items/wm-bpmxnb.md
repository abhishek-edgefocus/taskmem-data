---
id: wm-bpmxnb
type: task
title: Ingest OpenRoad model_requests/model_responses stmt files for real credit scores (DEV-1396)
status: open
priority: p2
size: l
tags: [openroad]
links: [parent:wm-su6q4d]
refs: [DEV-1396=https://linear.app/edge-focus/issue/DEV-1396/ingest-openroad-model-requestsmodel-responses-statement-files-for-real]
created: 2026-07-14
updated: 2026-08-21T13:29:40Z
source: dpx-tasks #6
label: OpenRoad model_requests ingest
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #6
- 2026-08-19T19:42Z [claude-code] NOW A CONFIRMED HARD BLOCKER, not just a data-quality gap (2026-08-19/20).
The missing VANTAGE4 credit score is what breaks openroad_api_predictions in PROD — it is no longer only a
comparison/parity nicety.

Measured read-only in PROD, replicating openroad_api_predictions' own matched_loans join:
- ALL 35 openroad loans have VANTAGE4 NULL in PROD.SILVER.OPENROAD_OFFERS
  (whole table: 68,818 non-null of 6,043,026 = 1.1%)
- openroad_api_predictions computes SERVICING_FEE = COALESCE(payload:servicing_fee,
  openroad_servicing_fee_sql(vantage4)); the helper returns NULL for a NULL/out-of-range score by design.
- 19 loans are saved by a gateway-logged payload:servicing_fee (events from 2023-10-27 onward).
- The 16 older 'pre-logging' loans have neither -> SERVICING_FEE NULL -> the transform's own validation
  rejects them -> 1,139 failing period-rows, which is EXACTLY the error count Dagster reported on both
  manual statements_openroad runs (4b394017..., 14320188...).

So DEV-1396 (ingest the flat model_requests/model_responses statement files that carry the real TU score)
is now on the critical path for OpenRoad predictions, not a side quest. Alternative if that ingestion is
far off: decide explicitly whether to relax the SERVICING_FEE rule / park those 16 pre-logging loans —
but note the rule exists precisely to stop NaN servicing fees silently corrupting predicted cashflows
(DEV-1331), so relaxing it needs a deliberate call, not a quiet edit.
Context and the full diagnosis are on [[wm-85nuv4]].
- 2026-08-19T20:53Z [claude-code] *** DEV-1396 NEEDS NO CODE — THE INGESTION AND THE WIRING BOTH ALREADY EXIST. IT IS A BACKFILL. ***
Investigated end to end 2026-08-19/20 (all read-only). The ticket as written says 'ingest the
model_requests/model_responses statement files into bronze and wire the real score into
silver.openroad_offers'. BOTH halves are already done in prod. Correcting the ticket's premise:

1. INGESTION EXISTS. PROD.BRONZE.API_EVENTS already holds openroad model_requests:
   321,363 rows, 1,197 as-of dates, 2023-05-11..2026-08-19, of which 65,244 carry
   payload:transunionCreditAttributes:vantage4Score. Coverage by year (mr_rows / with_v4):
   2023 33,894/16,547 · 2024 93,067/18,098 · 2025 98,166/10,551 · 2026 96,280/20,059.
   So there is nothing to ingest — the flat parquet columns are already exploded into nested
   JSON at bronze ingest, exactly as openroad_offers.py's comment describes.

2. WIRING EXISTS. openroad_offers.py already builds a model_requests CTE and does
   COALESCE(mr.TU_VANTAGE4, payload:...creditInformation:vantage4) AS VANTAGE4.
   It landed 2026-08-01 in 52026b99f — 'DEV-1331: Source OpenRoad RECOVERY_FRAC/SERVICING_FEE
   at source (+ MOB alignment)' (PR #5974). DEV-1396 was largely implemented by DEV-1331.

3. THE ACTUAL DEFECT IS A STALE TABLE. PROD.SILVER.OPENROAD_OFFERS VANTAGE4 non-null by year:
   2023 3,021 of 606,366 · 2024 0 of 1,734,909 · 2025 0 of 1,864,432 · 2026 66,348 of 1,839,675.
   2026 is populated because those dates were processed AFTER 2026-08-01; 2024/2025 and nearly
   all of 2023 were processed BEFORE it and the stream watermark will never revisit them.
   This also proves the DEPLOYED prod image already has the wiring — otherwise 2026 would be 0 too.

PROOF IT IS PURELY STALENESS (read-only, PROD, generate_sql() stripped to a plain SELECT):
   as_of_date 2023-06-30 — prod currently HOLDS 1,311 offer rows, 0 with VANTAGE4.
                           re-running the transform WOULD produce 1,311 rows, 703 with VANTAGE4
                           (range 529..797). Identical row count, so it is not data availability.

AND IT DEMONSTRABLY FIXES THE PREDICTIONS BLOCKER: the 16 loans that fail
openroad_api_predictions all have offer dates 2023-06-30..2023-10-24 (all pre-dating the
2023-10-27 payload-logging cutover, which is why they have no payload:servicing_fee). Their
scores ARE in bronze for the exact (as_of_date, timestamp_ns) join keys the transform uses —
verified 16/16, values 602..831, every one inside the schedule's valid [350,850] domain:
  4841228 671 · 4857417 619 · 4875674 623 · 4923612 719 · 4944444 831 · 4944443 602
  4972236 635 · 4950979 622 · 4994794 666 · 4950980 660 · 4976517 614 · 4981199 731
  4986460 747 · 4998579 720 · 5011302 664 · 5044723 650
Cross-checked independently against the source parquet in
s3://efp-derived/gateway/openroad/openroad_auto_refi/model_requests/<date>/000.parquet — same
16/16, same values. So once offers is backfilled, SERVICING_FEE resolves for all 16 and the
1,139 validation errors go away.

THE FIX (operational, no PR):
  1. Run the ingest_api_output job's openroad_offers asset with as_of_date=all
     (openroad_offers lives in orchestration/jobs/ingest_api_output.py:50, NOT in
     statements_openroad). ~6.0M rows / 1,197 dates — consider a warehouse larger than
     COMPUTE_WH_XS_PROD.
  2. Then re-run statements_openroad; openroad_api_predictions should pass.
  Note openroad_offers_bucketed / openroad_offers_daily sit downstream in the same job.

RECOMMENDATION: rewrite DEV-1396's description to 'backfill silver.openroad_offers so the
already-wired TU vantage4 lands on historical dates', or close it as delivered by DEV-1331 and
track the backfill on the OpenRoad revival thread [[wm-85nuv4]]. As written the ticket sends
whoever picks it up to build an ingestion that is already there.
- 2026-08-20T11:32Z [claude-code] CONCLUSIVE PROOF THE BACKFILL FIXES PREDICTIONS — no code change required (read-only, PROD, 2026-08-19/20).

Replicated openroad_api_predictions' own matched_loans join, computing SERVICING_FEE two ways:
once from the STALE offers VANTAGE4 as prod holds it today, once from the value a REBUILT
openroad_offers would carry (COALESCE(model_requests TU score, partner-supplied vantage4) — the
exact expression openroad_offers.py already uses).

  loans                       35
  loans scored NOW             0 / 35
  loans scored AFTER backfill 35 / 35
  failing rows NOW         1,139  (== the exact Dagster error count on both manual runs)
  failing rows AFTER           0
  total rows               2,507

So a rebuild of silver.openroad_offers takes openroad_api_predictions from 1,139 validation
errors to zero, with no code change anywhere. Every one of the 35 loans resolves a score, and
every resulting servicing fee lands inside the validation's [0, 0.1] band.

This closes the diagnosis: DEV-1396's two stated deliverables (ingest the files, wire the score)
were both already delivered — the ingestion long since, the wiring on 2026-08-01 by DEV-1331 /
PR #5974. The only outstanding work is re-materialising the historical dates.

ORDER OF OPERATIONS (Abhishek validates in DEV_ABHISHEK before prod as a standing habit):
  1. DEV first — rebuild openroad_offers in DEV_ABHISHEK, but SCOPE THE CHECK to the 2023 dates
     that are empty in prod. Dev is NOT a proxy here: DEV_ABHISHEK.SILVER.OPENROAD_OFFERS has
     1,151,134 non-null VANTAGE4 vs prod's 68,818, so a blanket dev pass proves little.
  2. Then prod — openroad_offers asset (ingest_api_output job) with as_of_date=all,
     ~6.0M rows / 1,197 dates; consider a warehouse above COMPUTE_WH_XS_PROD.
  3. Then re-run statements_openroad. With PR #6393 merged too, the whole job should go green:
     transfers 35->0 errors, predictions 1,139->0.
- 2026-08-20T12:12Z [claude-code] DEV-VS-PROD PRE-FLIGHT — DEV_ABHISHEK IS ALREADY IN THE FIXED STATE, WHICH IS WHY DEV TESTING NEVER CAUGHT THIS.
Measured 2026-08-20 on the 15 offer dates behind the 16 failing loans (2023-06-30..2023-10-24):

                                        PROD      DEV_ABHISHEK
  silver.openroad_offers rows          52,915        52,915     <- identical
  ...with VANTAGE4                          0        29,241     <- the entire difference
  bronze.api_events model_requests      2,928         2,928     <- identical
  ...carrying a TU score                1,546         1,546     <- identical

Source data is byte-identical in both environments; only the persisted silver table differs.
Abhishek's dev copy was rebuilt after the DEV-1331 wiring landed (2026-08-01), prod's history
never was. So dev IS the 'after' picture and prod is the 'before'.

CONSEQUENCE WORTH REMEMBERING: this class of bug is structurally invisible in DEV_ABHISHEK.
Abhishek's standing habit is to validate in dev before prod ([[validate-in-dev-abhishek-first]]),
and that habit could not have caught this one — dev was already repaired. It is also why the
predictions transform passed when run against dev and failed in prod with identical code.
When the suspected defect is 'prod table is stale relative to the code', dev proves nothing;
compare PROD against a freshly-computed result instead.

Expected prod outcome after the backfill: ~55% of offer rows on those dates carry a score,
matching dev's 29,241/52,915.

DECISION: skip a full dev rebuild rehearsal. It would spend ~6M rows reproducing a state dev
already holds, and the pre-flight above already establishes the outcome.

PROVENANCE FOR CLOSING DEV-1396 (Abhishek asked when the ingestion was actually completed):
- openroad model_requests first landed in PROD.BRONZE.API_EVENTS 2025-12-28 08:35:49 PST,
  backfilled to as_of 2023-05-11, still loading daily. That is ~6 MONTHS BEFORE DEV-1396 was
  created (2026-07-08) — the ticket was filed for work already running.
- There is NO openroad-specific ingestion PR to link. The parquet model_requests/model_responses
  ingestion is generic, prefix-driven code (originating in PR #4250); platforms were switched on
  by operational backfill runs, one at a time: sofi 2025-11-02, happymoney 12-22,
  upgrade/prosper/openroad/anchored 12-28, northpond 2026-01-02, innovate 01-23, lc 01-24,
  foursight 02-25, marlette 03-26, revolut 06-19.
- The NorthPond precedent Abhishek was recalling is DEV-1290 / PR #5579 ('Northpond positions —
  fund-aware account_id + credit_score/fico parity'), which is the same credit-score-is-NULL
  problem but solved as a silver mapping fix, NOT an ingestion. NorthPond's own model_requests
  ingestion was the same operational rollout, 2026-01-02.
- The PR that actually delivered DEV-1396's second half is #5974 (DEV-1331), merged 2026-08-01.
  That is the one to link when closing.
DO NOT let the openroad_offers backfill die with the closed ticket — no ticket currently owns it;
it belongs on [[wm-85nuv4]] / the OpenRoad revival thread.
- 2026-08-21T13:29Z [claude-code] *** THE OFFERS BACKFILL RAN IN PROD AND WORKED — 2026-08-21. Blocker 2 is CLEARED. ***
Abhishek launched it himself (asset-scoped materialization, per [[no-agent-prod-runs]]).
Dagster run 36bc64b2-ee4c-437c-a344-92f4e7f38a3a, __ASSET_JOB, assetSelection=[openroad_offers],
config as_of_date=all / warehouse=COMPUTE_WH_XS_PROD. STATUS SUCCESS.
Correctly scoped to the single asset — the whole ingest_api_output job would have rebuilt all 14
platforms' offers including upgrade's ~735M model_requests rows.

PROD silver.openroad_offers VANTAGE4 non-null, before -> after:
  2023     3,021 -> 314,013   of   606,366
  2024         0 -> 343,596   of 1,734,909
  2025         0 -> 200,469   of 1,864,432
  2026    73,929 -> 390,735   of 1,864,679
  total   ~77k   -> ~1,248,813
The 2024/2025 zeros — the signature of the staleness — are gone.

PREDICTIONS BLOCKER CONFIRMED CLEARED (same read-only check that previously reproduced Dagster's
error count exactly):
  loans 35 | loans scored 0 -> 35 of 35 | failing rows 1,139 -> 0 | total rows 2,507
So openroad_api_predictions should now pass in prod. The 1,139 figure had matched the Dagster
failure count exactly on both earlier manual runs, which is what makes 0 meaningful here.

RUNTIME — PROD WAS 7x SLOWER THAN THE DEV REHEARSAL, worth recording for future backfills:
  dev  1.8 min  (5,758,444 rows / 1,170 dates)
  prod 13.1 min (startTime 1787318071.79 -> endTime 1787318856.79 = 785s), same XS warehouse
Still cheap in absolute terms, and it succeeded — but do not quote the dev figure as a prod estimate.
Likely warehouse contention or larger prod volume; not investigated.

DEV-1396 can now be closed/repurposed for real: its stated outcome (real TU score present in
silver.openroad_offers) is finally TRUE in prod, which it was not when I drafted the closing comment.
Link PR #5974 (DEV-1331) as the code delivery and this run as the data delivery.
