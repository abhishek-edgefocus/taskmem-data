---
id: wm-79k8df
type: task
title: Scope: enable CMOP + BEP predictions for NorthPond (~400-550 LOC)
status: open
priority: p3
size: l
tags: [northpond, edgex, predictions]
links: [blocked-by:wm-qs96kd, parent:wm-3sxcre]
refs: [DEV-1498=https://linear.app/edge-focus/issue/DEV-1498/setup-northpond-cmopbep-and-silvernorthpond-api-credit-attributes]
created: 2026-07-20T15:25:55Z
updated: 2026-08-24T21:15:21Z
source: claude-code
---

Sizing done 2026-07-20 against origin/master 8ad84e1cf + prod Snowflake. Not yet committed work —
this is the estimate, recorded so it doesn't need re-deriving.

## Current state
northpond_loan_fl has at_orig ONLY (28,152 rows -> 2026-07-19), sourced from the gateway via
northpond_api_predictions.py (PREDICTION_TYPE = "at_orig" hardcoded). No curr_mod, no best_est.
Same for openroad_auto_refi (at_orig only, and stale -> 2024-12-12).

CMOP/BEP are produced ONLY by the conda predictor path (edgefocus/modeling/predictions/run.py,
cron lines 425/426), driven by the hardcoded FORWARD_FLOW_PREDICTORS / TURNDOWN_PREDICTORS
registries. northpond is in neither. There is no per-client config flag — enablement == having a
registered predictor class.

## Prereqs ALREADY met
- deployed model northpond_loan_fl (lib/efp/model_microservice/models_by_channel.json:132)
- cfframe config entry (edgefocus/cashflow_config_history_git.py:81)
- bronze.api_events: 1.53M northpond rows, fresh to 2026-07-20
- silver.positions: 715 northpond loans, fresh to 2026-07-20

## Gap + estimate
Main cost is the MISSING northpond slice of silver.api_credit_attributes (today only sofi /
upgrade / prosper / happymoney have rows there).

  northpond_api_credit_attributes.py     100-140  (peers: prosper 83, hm 93, sofi 96, upgrade 134)
  asset registration in northpond_assets   ~12    (all 4 peers were exactly 12)
  northpond/predictor.py                  40-60   (sofi 25 / upgrade 29 + universe override)
  northpond/prep.py                        0-50   (0 if no gateway quirks; sofi needed 48)
  run.py registry entry                     1-3
  int test + JSON fixtures                 ~185
  md_tests                                  ~65
  BEP marginal (predictor/cron/registry)      0   <- best_est_variant() synthesizes it
  BEP md_test                               ~50
  TOTAL                                 ~400-550  (~55% is test/fixture)

## Design wrinkle
northpond is forward-flow (northpond_loan_fl) but its features come from gateway api_events like a
turndown channel. Fits neither base cleanly: ForwardFlowPredictor gives the right universe but needs
a bespoke load_credit_features (why FF predictors are 235-412 lines vs sofi's 25); TurndownPredictor
gives the feature path free but its universe is "funded loans in the credit table". Cheapest correct
route: subclass TurndownPredictor, override load_candidate_loans.

## BLOCKER for BEP
wm-qs96kd. silver.realized_cashflows_from_origination has 0 northpond rows. BEP is realized-actuals
overlaid on prediction, so it cannot produce anything until those orphaned assets materialize.
CMOP is NOT blocked by this.

## Legacy datastore comparison (asked for, worth keeping)
Old system gated CMOP/BEP on hardcoded VALID_PLATFORMS + VALID_CHANNELS in
lib/efp/stats/datastores/base_datastore_sim_pred_cfframe.py (both CMOP and BEP inherit it).
northpond WAS enabled there for 10 days: added 25364e625 (2026-06-03, DEV-1035, 4 files +10-1),
removed a93355077 (2026-06-13, #5537) with rationale "northpond gets its predicted cfframes from
s3://efp-derived/gateway/northpond/northpond_loan_fl via DatastoreTruePredCfframeAtOrig, so it
needn't be in the platform list."

KEY POINT: the legacy 2-line flip looked cheap only because it presumed an upstream S3 producer was
already emitting CMOP/BEP frames for that platform — for northpond nothing ever was. northpond has
only ever had gateway response capture (at_orig), never a model-rerun path. Today's gap is the same
structural absence, not a migration oversight.

Also: legacy had a 2nd independent gate CMOP_VALID_PLATFORMS = [lc, upgrade, marlette, prosper]
(lib/efp/stats/edgex/constants.py:10) consumed by EDGEX with frozen index=1160. northpond was never
in it. Could NOT find where that frozen-index pinning is preserved on the Snowflake side — open
question if EDGEX scoring is in scope (relates to wm-c5jytx).

## Log
- 2026-07-21T09:04Z [claude-code] DEPRIORITISED per Abhijeet DM 2026-07-20 (ts 1784564371/1784564375): CMOP+BEP predictions for NorthPond are 'not needed for EDGEX, at least immediately'. Critically, the EDGEX 'OP' ask is NOT this item — Abhijeet clarified 'OP for edgex is te integrated model vala' (the Oliv integrated model, tracked as wm-c5jytx). Do not conflate the two. This stays scoped but off the EDGEX critical path.
- 2026-07-21T12:20Z [claude-code] 2026-07-21, from the raw 2026-07-16 Oliv call transcript (full log on wm-qjkp3x): CMOP and BEP CANNOT be sourced from Oliv's model — Nakula asked directly, "using their model we can't generate BPS or COP right, like using our model we can", and Trishit confirmed "Exactly. Exactly." Oliv outputs a single loss score per loan, scaled by fixed constants into CGL and ANL; there is no per-month, per-loan model output on their side to derive current-model or best-estimate projections from. This item's premise therefore stands and is now positively confirmed rather than assumed: enabling CMOP/BEP for NorthPond requires OUR model, which is the same machinery Sean's QR-23/DEV-1452 would need (see wm-9s2mwd). Worth scoping the two together rather than separately — they share the predictor, prep and cfframe config.
- 2026-07-29T15:33Z [claude-code] STILL OPEN, CONFIRMED BY ABHISHEK 2026-07-29 (Abhijeet DM 19:52 IST): asked whether BEP had been added, Abhishek said no — 'Cmop and bep doni platforms cha baki aaje' (CMOP and BEP pending for both platforms), and confirmed 'ho' when Abhijeet asked specifically about NorthPond. So this item's premise is intact and Abhijeet is now tracking it. Created the OpenRoad counterpart, which had no item — see the relates link.
- 2026-08-03T13:44Z [claude-code] Linear ticket now exists: DEV-1498 'Setup NorthPond CMOP/BEP and silver.northpond_api_credit_attributes' (Todo, created 2026-07-31 20:25Z). Ref added. Scope is wider than this item's title: it bundles the credit-attributes table with CMOP/BEP, which matches what Abhishek told Nakula on PR #6082 (2026-08-01 01:45) — 'same for silver.northpond_silver_credit_attributes / CMOP / BEP - will add in a separate PR - as I am trying to limit the scope of this PR'. So this is now a promised follow-up to a merged/merging PR, not just backlog.
- 2026-08-24T21:04Z [claude-code] IMPLEMENTED 2026-08-25 on branch abhishek/dev-1498-setup-northpond-cmopbep-and (dpx workspace ~/claude-ws/dev-1498/efp, commit db56ed48c, NOT pushed). Scope re-derived against origin/master 99c70e725 -- the 2026-07-20 estimate is superseded on three points.

WHAT CHANGED SINCE THE ESTIMATE.
1. The BEP blocker is GONE. wm-qs96kd landed: PROD silver.realized_cashflows_from_origination now has 11,547 northpond rows / 1,075 loans fresh to 2026-08-23, so best_est runs. Confirmed by an actual BEP run (it dropped 3 of 8 sampled TU loans as terminal, which is the intended behaviour).
2. The design wrinkle in the old estimate ('fits neither base cleanly; subclass TurndownPredictor and override load_candidate_loans') did NOT materialise. TurndownPredictor needed NO override: its universe IS the credit table, which is exactly what the new transform emits. Both predictors are ~20 lines of CONFIG.
3. TWO channels, not one -- this is the real scope discovery and it was not in the estimate. Northpond funds through ONE gateway channel (northpond_loan_fl) but TWO bureau generations separated only by api_version: v1 = TransUnion, 715 funded loans, last origination 2026-01-12, model northpond_loan_fl; v2 = Experian, 579 loans, live, model northpond_exp_loan_fl. Payload shapes are disjoint (v1 nests primaryBorrower.transunionCreditAttributes.*, v2 is flat clall*/p13_*/t11_*). Each has its own registered current model AND its own cfframe config, both already present. So the transform writes the MODEL channel into CHANNEL and there are two predictors. Abhishek chose 'both channels' over 'v2 only' when asked. Coverage: 1,294 of 1,349 funded loans.

WHAT SHIPPED (9 files, ~600 LOC incl. tests -- the 400-550 estimate was close).
- edgefocus/transformations/silver/api_events/northpond_api_credit_attributes.py (new)
- edgefocus/modeling/predictions/northpond/td_prep.py + td_predictor.py + td_predictor_test.py (new)
- edgefocus/integration_tests/md_tests/northpond_api_credit_attributes.md (new)
- run.py + run_test.py, orchestration/assets/northpond_assets.py, orchestration/jobs/ingest_api_output.py (registration)

JOIN PATH (differs from every peer -- worth not re-deriving). Peers go purchase tape -> {platform}_offers -> api_events on (as_of_date, timestamp_ns). Northpond CANNOT: neither v1 nor v2 model_requests carry a top-level application_uuid -- it is nested at applicationInformation.applicationUuid on BOTH versions, while model_responses carry it top-level as application_uuid. So the transform joins issuance -> model_requests on the nested uuid and -> model_responses on the flat one, matched on api_version. Offer terms come from the RESPONSE (the request only has requestedAmount/requestedTerm).

THE ONE HARD BUG, and why the naive port fails. base TurndownPrep pins the funded amount/term/rate onto ec.AMOUNT/ec.TERM/ec.RATE. Both northpond NORTHPOND_MAPs already rename a raw request key onto those same columns (v1: applicationInformation.requestedAmount/requestedTerm; v2: mp_loanamount -> c_loan_amount and applicationInformation.applicationUuid -> c_loan_id), so rename_raw_data emits a duplicate column and the model dies with 'Transforming different columns than fitted: c_loan_amount, c_loan_amount'. Dropping the raw key does NOT fix it -- both northpond adapters RE-DERIVE the amount inside transform_raw_data (the exp one substitutes a flat 4000 default when mp_loanamount is absent, which would re-score every exp loan at a fabricated amount). Fix: write the funded value INTO the raw key the map reads, and pin directly only where there is no map entry. Safe because across all 1,294 funded loans requestedAmount == accepted amount and requestedTerm == accepted term EXACTLY, and mp_loanamount is null on every one. td_predictor_test.py mutation-tests both directions.

PARITY GATE PASSED, on every eligible loan not a sample (the .claude/skills/onboard-prediction-platform gate: CMOP must bit-match the logged gateway curves for loans decided under the model the predictor loads). Exp channel 19,296/19,296 rows exact; TU channel 4,680/4,680 exact; max abs diff 0.0 on both DEFAULT_PROBABILITY and PREPAY_PROBABILITY. TU eligibility is only 130 of 715 loans because the current northpond_loan_fl model is effective 2025-08-04 and only those were decided under it (model_policy_version v4); the rest legitimately differ, which is the point of CMOP.

DELIBERATE NON-FILTER, do not 'fix' it later. _credit_pull_success=false is NOT filtered out. It covers 433 of the 715 v1 funded loans, and every one still carries a complete transunionCreditAttributes block with a non-null vantage4Score (numMissingFeatures is 1 or 2). It means 'some features were defaulted', not 'no credit data'. Filtering would drop 61% of the TU back book. Contrast openroad_api_credit_attributes which DOES filter, because there the block itself is absent.

CONSUMER-VISIBLE ASYMMETRY, flagged in the commit message. The exp at_orig rows written by OlivExpStatementPredictor stay under CHANNEL northpond_loan_fl, while exp CMOP/BEP land under northpond_exp_loan_fl. Anything joining at_orig to curr_mod for a northpond loan must key on EFP_ID and not assume a single CHANNEL. Re-channelling the live at_orig rows is a data migration and was deliberately left out.

VERIFIED: transform SQL over PROD emits 1,294 rows (715 TU + 579 Exp), 0 duplicate (EFP_ID, AS_OF_DATE) keys, no null offer terms or payloads. CMOP+BEP run end to end for both channels against DEV_ABHISHEK writing to s3://efp-sandbox/abhishek/dev-1498/. ruff + mypy + dagster check_definitions clean; 38 prediction tests and 3,124 edgefocus/orchestration tests pass.

NOT DONE, and it is ordered. (a) Push + open the PR as draft. (b) PROD BACKFILL of the credit-attributes slice must run BEFORE the predictions cron picks up the new channels -- the transform is stream-driven so a normal tick only sees new issuance dates, and the 1,294 historical loans need a --date all run of northpond_api_credit_attributes. Abhishek launches prod jobs himself. (c) Only after that will the 13:30 UTC curr_mod cron and the Sunday 14:00 best_est cron produce northpond rows.
- 2026-08-24T21:15Z [claude-code] PR OPEN AS DRAFT 2026-08-25: https://github.com/edgefocus/efp/pull/6462 (branch pushed, base master, 9 files +667/-0, isDraft=true). Description written to ~/pr-style.md shape: what changed -> why two channels -> the non-standard join -> the deliberate _credit_pull_success non-filter -> why the preps are not empty -> Testing/Validation table -> verification SQL in a <details> block -> numbered Deployment/Setup with the backfill-before-crons order -> the at_orig/curr_mod CHANNEL asymmetry for consumers.

PARITY EVIDENCE IS NOW RE-READABLE, not just a console log: persisted to DEV_ABHISHEK.SILVER.NP1498_CMOP_PARITY, 23,976 rows, one per (efp_id, period), columns SCORED_DEFAULT / LOGGED_DEFAULT / SCORED_PREPAY / LOGGED_PREPAY / MATCHES. Aggregate reads 19,296/19,296 matching on northpond_exp_loan_fl and 4,680/4,680 on northpond_loan_fl, MAX_ABS_DIFF 0.0 on both curves for both channels. Builder script dp:~/claude-ws/dev-1498/parity_table.py, screenshot-ready queries in dp:~/claude-ws/dev-1498/proof.sql.

STAYS DRAFT ON TWO GAPS, both stated in the PR body: (1) DAG screenshot -- the asset graph changed, northpond_api_credit_attributes was added to ingest_api_output; (2) Snowflake screenshots with query-and-result in frame for the three assertions (parity, coverage, grain). The SQL is pasted in the body ready to run; only the captures are missing. Abhishek flips draft state himself -- 'gh pr ready 6462' once those are attached.

Linear DEV-1498 left in Todo deliberately; ticket state is his to move.
