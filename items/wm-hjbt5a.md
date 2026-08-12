---
id: wm-hjbt5a
type: task
title: Prod Dagster: 5 platform statement sensors never enabled + 3 platform jobs failing every tick
status: open
created: 2026-08-12T13:48:14Z
updated: 2026-08-12T13:48:14Z
source: claude-code
---

Found 2026-08-12 while diagnosing OpenRoad ([[wm-85nuv4]]). Read-only audit of prod
Dagster GraphQL (https://dagster-prod.edgefocuspartners.com/graphql, v1.12.14).
The OpenRoad problem is one instance of a much broader one. Nothing was changed.

## A. SENSORS THAT HAVE NEVER TICKED (status STOPPED, runningCount 0, ticks 0)
  openroad_statement_sensor    -> statements_openroad:  1 run EVER (UI, 2026-07-07)
  lc_statement_sensor          -> statements_lc:        UI-only, last SUCCESS 2026-08-03 13:26
  upstart_statement_sensor     -> statements_upstart:   UI-only, last SUCCESS 2026-07-29 10:45
  innovate_statement_sensor    -> statements_innovate:  UI-only, last SUCCESS 2026-03-04 02:59 (!)
  foursight_statement_sensor   -> statements_foursight: 1 run EVER, FAILURE 2026-08-12 12:16 (UI)
  (also STOPPED: borrowing_base_review_sensor, last tick 2026-06-12)
Every one of these platforms silver layer only advances when a human clicks Launch.
That matches the silver.positions staleness measured the same day: openroad 2026-07-06,
upstart 2026-07-26, lc 2026-08-02, innovate absent from silver.positions entirely.
It also explains gold.positions_comparison_daily reporting COMMON_COUNT=0 for
openroad/lc/upstart/innovate on 2026-08-09 while sofi and anchored match fine.

## B. SENSORS RUNNING BUT THE JOB FAILS EVERY TICK
  statements_northpond   20 consecutive FAILUREs; last SUCCESS 2026-08-05 18:44 UTC
  statements_upgrade     28 consecutive FAILUREs; last SUCCESS 2026-08-07 20:49 UTC
  statements_happymoney   2 consecutive FAILUREs; last SUCCESS 2026-08-11 18:48 UTC (a UI run)
Healthy on sensors: sofi, anchored, prosper, marlette, intex.

ROOT-CAUSE ERRORS (from ExecutionStepFailureEvent cause chains):
  northpond_exp_predictions            AssertionError: .efp_toplevel not found
        ^ this is ERROR-1626, already tracked as [[wm-te4cr2]] — now confirmed to be
          failing the WHOLE northpond statements job on every sensor tick, not just
          one asset. That raises its priority a lot.
  northpond_transfers                  ValueError: Validation failed with 1116 error(s)
  upgrade_transfers                    ValueError: Validation failed with 300 error(s)
  happymoney_fortress_warehouse_positions  ValueError: Validation failed with 35 error(s)

The "Validation failed with N error(s)" text comes from SHARED code —
edgefocus/transformations/transform.py:734 — so northpond_transfers and
upgrade_transfers failing the same way within ~2 days of each other is worth treating
as one candidate regression, not two coincidences.

TIMING (do not over-read this yet): northpond broke between 2026-08-05 18:44 and
2026-08-06 12:44 UTC. upgrade broke after 2026-08-07 20:49 UTC. Commit e056c84c0
"silver: Preserve fund membership when positions lag" (#6189, Abhijeet, shared file
edgefocus/transformations/silver/loans_in_fund.py, +41/-1) merged 2026-08-07 20:01 UTC
— fits upgrade, does NOT fit northpond, so either there are two causes or a single
deploy carried several commits. Deploy time != commit time; check the image rollout
before blaming any commit.

NEXT STEP TO GET THE ACTUAL VALIDATION ERRORS: the detail is in stderr/compute logs in
S3, not the event stream. The repo documents the exact GraphQL chain in
.cursor/skills/dagster-investigation/SKILL.md:107 (LogsCapturedEvent.logKey +
capturedLogsMetadata(logKey:[run_id,"compute_logs",<key>]) -> pre-signed URL).

ALSO WORTH ASKING: run_failure_alerting_sensor is RUNNING, yet 20-28 consecutive
failures on two platforms went unactioned. Either the alerts are not reaching anyone
or they are being ignored. That is arguably the most important finding here.
