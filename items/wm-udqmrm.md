---
id: wm-udqmrm
type: task
title: Backfill openroad api_credit_attributes in PROD before the CMOP cron, or hold it deliberately
status: open
created: 2026-09-01T18:23:19Z
updated: 2026-09-02T13:06:33Z
source: claude-code
---

PROD.SILVER.API_CREDIT_ATTRIBUTES has 35 openroad rows, 0 carrying the maximum_ltv payload key that PR #6496 (merged 54c0b969c) added. The transform is stream-driven off openroad_stmt_purchase_tapes and openroad has had no purchase since 2024-12-12, so a normal tick never re-emits those payloads -- only `openroad_api_credit_attributes --date all`.

Until it runs, the newly-registered predictor fans each of the 35 loans over 19 MAXIMUM_LTV_FACTORS and run_prep_model raises 'Model output index contains ids with no efp_id mapping'. So openroad_auto_refi errors on every curr_mod cron (13:30 UTC) and the Sunday 14:00 best_est cron.

But running it has its own risk: predictions would then land with NULL RECOVERY_FRAC/SERVICING_FEE and prod's predicted_cashflows would process them -- the float(None) blocker on [[wm-xe6w4q]]. Decide which ordering, and also create the two missing checkin rows (curr_mod_openroad_openroad_auto_refi, best_est_openroad_openroad_auto_refi) via checkin.py --create.

Abhishek launches prod jobs himself.

## Log
- 2026-09-02T13:06Z [claude-code] PRECEDENT SEARCH 2026-09-02, asked for before running anything. All three questions have real answers, and one of my earlier claims was wrong.

Q1 -- has predicted_cashflows been run broadly/as_of_date all? YES, and it FAILED. Sentry EFP-ERRORS-WK carries the run config verbatim: {'ops':{'predicted_cashflows':{'config':{'as_of_date':'all','warehouse':'COMPUTE_WH_XS_PROD'}}}}, prod run 33b4e594-2dc7-484b-9327-9b8d87dacf76, 2026-08-18 21:48 UTC, launched as __ASSET_JOB (asset alone, not the whole job). Failure was DagsterSubprocessError -> ChildProcessCrashException in child process 17 -- a killed child with no python traceback, i.e. the OOM signature, which matches the onboard-prediction-platform skill's written playbook: 'chunk predicted_cashflows runs by s3_base (all-mode OOMs)'. 43 occurrences since 2026-03-24, last 2026-08-18, now resolved. Linear ERROR-971.

Q2 -- has any platform's api_credit_attributes been backfilled --date all after the fact? YES, five days ago, and it is the same operation openroad needs. wm-nyjurp: Abhishek launched northpond_api_credit_attributes in prod Dagster 2026-08-27, run 8ff3a5fa-43b9-4c5c-9243-60e6dbcb4424, config as_of_date: all, scoped to that single asset via __ASSET_JOB rather than the whole ingest_api_output job. SUCCESS in 37.3 seconds, rows_inserted 1310 / rows_deleted 0, matching the predicted acceptance number exactly. Verified independently in Snowflake that every other platform slice was unchanged (anchored 358, happymoney 204, openroad 34, prosper 284, sofi 12,254, upgrade 20,429). So this step has clean, recent, same-shape precedent.

Q3 -- CORRECTION TO MY OWN CLAIM. I told Abhishek a raising slice would leave predicted_cashflows 'permanently wedged for all platforms'. That was inference from reading transform.py (watermark advances only after a successful insert), and the operational record contradicts the 'permanent' half: predicted_cashflows has failed 43 times in prod since March and the pipeline is healthy today -- northpond CMOP is fully live end to end per wm-8uyfnw, and anchored's cashflows are current. It self-recovers. IMPORTANT CAVEAT that keeps the concern alive: every observed failure is a crash/OOM, which is load-dependent and therefore transient, so the next scheduled run succeeds. A deterministic config error would NOT self-recover. So precedent covers transient failures, not this failure mode.

Closest shared-asset precedent is wm-8uyfnw and it is a different mode again: best_est_projections_at_orig has been a SILENT no-op since 2026-08-27, producing zero northpond rows while running green, and nobody noticed for four days. That is the failure shape this codebase actually produces -- silent staleness, not a loud wedge.

STILL UNTESTED, and it is the load-bearing claim: whether one raising slice prevents OTHER platforms' slices from being written in the same run. generate_temp_table is called once with all keys and has no per-slice try/except, so I expect yes -- but I have only ever run it in DEV with openroad keys alone. That experiment is cheap and DEV-only.
