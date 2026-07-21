---
id: wm-79k8df
type: task
title: Scope: enable CMOP + BEP predictions for NorthPond (~400-550 LOC)
status: open
priority: p2
size: l
tags: [northpond, edgex, predictions]
links: [parent:wm-j523sq, blocked-by:wm-qs96kd]
created: 2026-07-20T15:25:55Z
updated: 2026-07-21T09:04:48Z
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
