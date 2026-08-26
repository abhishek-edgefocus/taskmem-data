---
id: wm-xe6w4q
type: task
title: Enable CMOP + BEP predictions for OpenRoad
status: active
priority: low
size: l
people: [Abhijeet]
tags: [openroad, predictions]
links: [relates:wm-79k8df, relates:wm-prm54n, relates:wm-85nuv4, parent:wm-jr5bup]
refs: [DEV-1499=https://linear.app/edge-focus/issue/DEV-1499/setup-openroad-cmopbep]
created: 2026-07-29T15:33:45Z
updated: 2026-08-26T18:06:38Z
source: claude-code
label: OpenRoad CMOP + BEP
---

Surfaced by Abhijeet in DM 2026-07-29 19:52 IST (D0B2A3WSJ5N), while checking on the
2026-08-03 OpenRoad datastore deprecation ([[wm-prm54n]]).

- Abhijeet: "BEP pan add keles?" (did you add BEP as well?)
- Abhishek: "Nahi" (no) — then "Cmop and bep doni platforms cha baki aaje" (CMOP and BEP
  are pending for both platforms).
- Abhijeet: "northpond che pan?" (NorthPond's too?) — Abhishek: "Ho" (yes).
- Abhijeet: "acha okay".

So CMOP and BEP are confirmed outstanding on BOTH platforms. The NorthPond half already has
an item — [[wm-79k8df]], "Scope: enable CMOP + BEP predictions for NorthPond (~400-550
LOC)". This is the OpenRoad counterpart, which had none.

UNRESOLVED — whether CMOP/BEP is IN SCOPE for the 2026-08-03 deprecation milestone or
separate follow-on work. Abhijeet raised it immediately after asking "is that the only
thing left?", which reads as him checking deprecation completeness, but he did not say it
blocks 08-03 and he closed with a neutral "acha okay". Settle this before sizing — it is
the difference between a p1 sprint item and background work.

Sizing note: no OpenRoad-specific analysis has been done here. The ~400-550 LOC figure on
[[wm-79k8df]] is the NorthPond estimate for the same machinery (predictor + prep + cfframe
config + registry entry) and is carried over only as a rough analogue.

## Log
- 2026-08-03T13:44Z [claude-code] Linear ticket now exists: DEV-1499 'Setup OpenRoad CMOP/BEP' (Todo, created 2026-07-31 20:27Z). Ref added. The NorthPond counterpart got its own ticket the same evening — DEV-1498, on [[wm-79k8df]] — so the 'both platforms pending' state Abhishek described to Abhijeet on 07-29 is now formally tracked on each side.
- 2026-08-14T19:55Z [claude-code] PREREQUISITE FOUND 2026-08-15 (PROD, read-only) — this is not a greenfield build on a working
pipeline, and sizing it off the NorthPond analogue understates it.

PROD.SILVER.PREDICTED_CASHFLOWS for openroad holds ONE prediction_type, 'at_orig', 2,507 rows,
max as_of_date 2024-12-12. Nothing else. So OpenRoad predictions have not been produced for
roughly twenty months, and adding CMOP + BEP means standing up production on top of a pipeline
that is not currently producing anything at all.

That reframes the "unresolved: is CMOP/BEP in scope for the 2026-08-03 deprecation milestone"
question in the body. The deprecation retires the legacy datastores in favour of Snowflake; if
Snowflake carries no current OpenRoad predictions, the two are more entangled than "separate
follow-on work" implies. Worth settling with Abhijeet as one question rather than two.

Sequencing consequence: the silver chain has to be alive first ([[wm-85nuv4]]) — predictions are
derived downstream of positions, and silver.positions openroad stops at 2026-07-06.
- 2026-08-20T11:52Z [claude-code] 2026-08-20 17:20 IST: Abhishek de-prioritised CMOP+BEP for OpenRoad — low priority.
- 2026-08-26T17:32Z [claude-code] IMPLEMENTED 2026-08-26 on branch abhishek/dev-1499-setup-openroad-cmopbep (dpx workspace
~/claude-ws/dev-1499/efp, commit 406779f45, NOT pushed). Much smaller than the northpond
analogue on [[wm-79k8df]] -- but the useful output is a finding, not the code.

WHAT WAS ALREADY DONE, contrary to the sizing note on this item. openroad_api_credit_attributes.py
exists on master, targets the SHARED silver.api_credit_attributes (the new preferred table -- there
is no per-platform openroad credit table), has a Dagster asset, and is already in the
ingest_api_output job selection. The cfframe config for openroad_auto_refi is in both the git
history and the overrides file, and the current model is registered in models_by_channel.json. So
the only gap was the predictor package. Answering the question directly: yes, api_credit_attributes
is the right table and openroad already uses it -- no new table needed.

SCOPE REALITY. OpenRoad is a 35-loan pilot. All 35 purchased, last purchase 2024-12-12, nothing
since. realized_cashflows_from_origination covers all 35 fresh to 2026-08-21, so BEP was never
blocked here the way it was for northpond.

WHAT SHIPPED (8 files, +243). openroad/{prep,predictor,prep_test}.py, run.py + run_test.py
registration, one column on the shared credit table (terraform + transform), md_test updated.

TWO PLATFORM-SPECIFIC BUGS, both measured not guessed.
1. MAXIMUM_LTV fan-out. OpenRoadOfferModel is a MultiOfferModel with 19 MAXIMUM_LTV_FACTORS. With
   ec.maximum_ltv absent it treats LTV as an offer axis: 35 loans -> 665 rows, ids rewritten to
   "openroad_4841228-0.5", and run_prep_model then cannot map back to efp_id. The LTV is NOT in the
   gateway payload, so silver.api_credit_attributes gained a nullable openroad-only MAXIMUM_LTV
   (same shape as the existing upgrade-only RATE_MEAN) read via _EXTRA_CREDIT_COLUMNS. Real
   per-loan input: 12 distinct values 0.70..1.40 across 34 loans -- not hardcodable. Abhishek chose
   the shared-column route over overriding load_credit_features when asked.
2. Duplicate c_term. OPENROAD_MAP renames applicationInformation.requestedTerm/requestedAmount onto
   ec.TERM/ec.AMOUNT which the base prep already pins; features_from_credit then sums over a
   DataFrame slice and dies with "unsupported operand type(s) for +: 'int' and 'str'". Prep drops
   the raw keys. The openroad adapter never re-derives amount/term, so unlike northpond nothing has
   to be written back into the raw key.

THE PARITY GATE IS IMPOSSIBLE HERE -- established, not assumed. All 34 funded loans were decided
2023-06-30..2024-11-13 under openroad_model/policy v1; the registered model is the 2026-06-23
artifact. Date-pinning per loan does not rescue it: 8 of 9 historical cohorts (32 loans) have no
offer_model artifact left in s3://efp-derived/modeling/statics, and the 9th (20241004v1, 2 loans)
raises ModelStaticUnloadable against the current lib/ checkout. Evidence substituted: 9 unit tests
that mutation-test both behaviours without an artifact, plus the DEV run.

THE FINDING THAT ACTUALLY MATTERS, and it is a go/no-go question for Abhijeet. Only 3 of 35 loans
(decided 2024-07-13 onward) carry the credit attributes the current model reads -- 146 of its 148
source keys populated. The other 32 populate 14. The pulls are not thin overall (~917
transunionCreditAttributes fields each); the gateway simply pulled a narrower set before
2024-07-13. So 32 of 35 loans would score with ~89% of model inputs imputed, above the model's own
NULL_PER_LOAN = 0.5 threshold. CMOP mean monthly default comes out 2.3x the logged at_orig curves,
consistent with that. The pipeline works; the numbers it produces for the back book should not be
trusted. Future originations get full coverage.

VALIDATED IN DEV_ABHISHEK: transform --date all = 35 rows, LTV 35/35 populated, other platforms
still NULL, stream consumed clean; curr_mod 35 loans/2,507 rows; best_est 20 terminal dropped, 15
scored/1,067 rows; pinned columns non-duplicated, zero nulls. ruff + mypy + dagster
check_definitions clean; 39 prediction tests, 3,090 transformations/orchestration tests, 44 md_test
validity tests pass.

NOT DONE. (a) Not pushed, no PR -- waiting on the go/no-go above, since a PR that enables scoring
for 32 untrustworthy loans may not be what is wanted. (b) Dagster materialize of the asset and the
parquet round trip into silver.predictions not run (the dev-1498 gaps). (c) checkin rows missing:
both runs ended with "Invalid checkin predictions ... for platform curr_mod_openroad_openroad_auto_refi"
and the best_est equivalent -- needs a checkin.py --create before the cron runs. (d) PROD terraform
apply for the new column not planned yet; worth confirming the column add does not recreate the
shared API_CREDIT_ATTRIBUTES_STREAM, since that stream is shared by every platform.
- 2026-08-26T17:49Z [claude-code] CORRECTION 2026-08-26, to my own log entry above. The "back book is untrustworthy" framing was
wrong on both halves, and the answer to DEV-1499 is that there is nothing further to build.

1. NULL_PER_LOAN IS NOT ENFORCED IN THE CMOP/BEP PATH, and that is not a framework bug. The only
enforcement site in the repo is OfferModel.offers_from_preds (lib/efp/modeling/models/offer_model.py
:202). The predictions framework never calls offers_from_preds, make_decisions or the offer
producer -- grep across edgefocus/modeling/predictions/ returns one comment in sofi/prep.py and no
call. pipeline.run_prep_model goes straight to model.predict(). So the threshold is structurally
unreachable from this path.

More importantly it would not do the hoped-for thing even if reachable. It does not exclude a loan
from scoring: it sets oc.DECISION=False, nulls oc.RATE and prepends an adverse-action reason
"High NaNs in loan: >50%|". It is an UNDERWRITING DECLINE for a new applicant -- we cannot see
enough of the file to make an offer -- and it runs AFTER predictions are produced, which are still
logged via log_predictions. It was never a prediction-coverage gate. upgrade_loan_td has
null_per_loan=None, disabled outright, which confirms it is a per-model underwriting knob rather
than a data-quality invariant.

2. THIS IS NOT AN OPENROAD PROBLEM -- anchored has the identical cliff and already ships. Measured
the exact offers_from_preds nan_mask (features[model.get_model_columns()].isnull().mean(axis=1) >
null_per_loan) across all six TD channels on PROD:
  sofi 0/120 over threshold (thr 0.3), happymoney 0/59 (0.25), prosper 0/167 (0.5),
  upgrade 0/117 (thr None), anchored 23/146 (0.5), openroad 32/34 (0.5).
Anchored's median null fraction is 0.881 for 2023 loans and 0.000 from 2025 -- the same
credit-pull-depth cliff openroad has at 2024-07-13.

And anchored SCORES them, in production, today: for its 23 sparse loans PROD.SILVER.PREDICTIONS
holds curr_mod 23/23 fresh to 2026-08-24 and best_est 12/23; all 23 reach
predicted_cashflows_history and all 23 reach silver.ef_scores, the table people actually read. So
passing sparse loans through is the established, live behaviour of this pipeline, not an oversight.

3. THE 2.3x RATIO WAS NOT EVIDENCE OF ANYTHING. I claimed openroad's curr_mod mean monthly default
running 2.3x its logged at_orig was "consistent with" 89% imputation. The anchored control refutes
the causal link: anchored's SPARSE cohort ratio is 1.006 while its DENSE cohort is 1.439. Sparsity
is not what moves the ratio. Openroad's 2.3x is model drift between the 2023/24 models that decided
the loans and the 2026-06-23 model CMOP loads -- which is precisely what CMOP exists to show.

CONSEQUENCE. No coverage filter, no input changes, no openroad-side workaround. Abhishek directed
"pass what we have and let the pipeline handle it", which is what the committed code already does
and what every other platform does. Commit 406779f45 stands as the complete answer to DEV-1499; the
remaining work is only the deployment items in the previous entry (checkin rows, terraform apply +
stream check, Dagster materialize / parquet round trip), plus push and open the PR.
- 2026-08-26T18:06Z [claude-code] PR OPEN AS DRAFT 2026-08-26: https://github.com/edgefocus/efp/pull/6496 (branch pushed, base master, 8 files +243/-5, isDraft=true). Body follows ~/pr-style.md: what changed -> 'DAG - unchanged.' (no orchestration/ file touched; the asset and its job entry already existed) -> Validation. Each evidence piece is a titled claim with the SQL in a <details> block and the result table visible outside it. States plainly that the transform ran via its module CLI and the predictors via the run.py CLI, NOT through local Dagster, so there are no Dagster run URLs, and that the parquet round trip into silver.predictions was not exercised. Includes the anchored comparison as the precedent argument, plus the two named non-bugs (null_per_loan is an underwriting decline not a prediction gate; the 2.30x ratio is model drift, with anchored's 1.006 sparse vs 1.439 dense as the control). Deployment/Setup is 4 numbered steps: tf-apply with the in-place-vs-replace check on the shared API_CREDIT_ATTRIBUTES_STREAM, backfill the openroad slice, create the two checkin rows, then watch the first ingest_prediction_files tick.
