---
id: wm-udqmrm
type: task
title: Backfill openroad api_credit_attributes in PROD before the CMOP cron, or hold it deliberately
status: open
created: 2026-09-01T18:23:19Z
updated: 2026-09-08T14:55:39Z
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
- 2026-09-08T14:55Z [claude-code] CONFIRMED LIVE IN PROD 2026-09-08, and every step of the 2026-09-01 prediction on this item held. This is no longer 'before the CMOP cron' -- the cron has been failing for six consecutive days and has six Linear ERROR tickets on it.

THE SIX TICKETS ARE ONE ROOT CAUSE, in two clusters (Sentry has exactly 6 unresolved openroad issues, 1:1 with Linear, so the backlog is closed-form):
- curr_mod/CMOP, first seen 2026-09-02T20:33Z, 6 occurrences: ERROR-1747 (EFP-ERRORS-1QA, the raise), ERROR-1748 (1QB), ERROR-1749 (1QC). Same run, three Sentry groups -- predictor-level error, run-level error, post_error wrapper.
- best_est/BEP, first seen 2026-09-06T21:10Z, 1 occurrence: ERROR-1778 (1RD), ERROR-1779 (1RF), ERROR-1780 (1RE). Same triple shape.
All six: 'Model output index contains ids with no efp_id mapping in loans parquet'.

EVIDENCE FROM THE PROD CRON LOG (/efs/logs/dumbledore/predictions.log), which is stronger than the Snowflake check because it observes the missing key at the point of use:
  [INFO] Adding maximum LTV factors [0.5, 0.55, ... 1.4]
  [INFO] Predicting on 47633 rows.
  [ERROR] Model output index contains ids with no efp_id mapping in loans parquet
'Adding maximum LTV factors' is the offer_model.py:453 branch that fires ONLY when ec.MAXIMUM_LTV is absent from raw_features. 47,633 = 2,507 x 19. The 2026-08-31 DEV_ABHISHEK run of the same code logged the OTHER branch ('Not overwriting provided maximum LTV') and succeeded on exactly 2,507 rows. Same code, same model artifact, opposite branch -- so this is a data-state difference, not a code defect. Traceback: run.py:201 -> base.py:774 run -> :617 predict_batch -> :641 score_batch -> pipeline.py:145 -> :140 _to_efp_index.

CADENCE AND SCOPE: curr_mod fails daily ~13:32 PT, six straight (09-02,03,04,05,06,07), every run logging '0 of 35 target efp_id(s) already predicted; 35 remain' -- so ZERO openroad CMOP predictions have ever landed in prod. best_est failed once, 2026-09-06 14:10 PT, a --force run, 14 loans after dropping 21 terminal. Contained to openroad_auto_refi: other platforms in the same cron are fine, and openroad at_orig still comes from the separate openroad_api_predictions SQL transform.

WHY A NORMAL TICK WILL NEVER FIX IT -- now measured, not inferred. Prod Dagster openroad_api_credit_attributes materializes every ~31 min (latest 2026-09-08T14:41Z) and EVERY tick reports rows_inserted=0, rows_deleted=0, dates='none'. The stream off silver.openroad_stmt_purchase_tapes is dry (no purchase since 2024-12-12). The asset is green and doing nothing.

DOWNSTREAM RISK RE-CHECKED TODAY, and it looks better than feared: prod predicted_cashflows is HEALTHY -- 2026-09-08T13:32Z inserted/deleted 9,075 rows for foursight. So the float(None) blocker is not currently firing in prod, consistent with the anchored tension recorded on wm-xe6w4q that was never explained. The risk to the backfill is still unproven either way; the honest position is run it and watch the first predicted_cashflows tick that picks up the openroad s3_bases.

NOT RUN -- Abhishek launches prod jobs himself. Precedent for the exact operation is on this item already (northpond_api_credit_attributes, as_of_date: all, __ASSET_JOB, 37.3s, 2026-08-27). target_table_where_clause is platform = 'openroad' so the DELETE+INSERT is scoped to openroad only.

HARDENING GAP WORTH A SEPARATE TICKET: the predictor has no defense when the payload key is missing entirely. The transform already handles a NULL LTV (OBJECT_INSERT + COALESCE(..., PARSE_JSON('null')) keeps the key present as JSON null), and openroad/prep.py documents that the fan-out branch keys on PRESENCE not value -- but nothing injects ec.MAXIMUM_LTV on the predictor side, so one absent key is a hard daily failure instead of a NaN model input.
