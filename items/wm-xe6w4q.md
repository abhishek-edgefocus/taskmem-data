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
updated: 2026-08-31T20:39:08Z
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
- 2026-08-26T19:11Z [claude-code] REVIEW FIX 2026-08-26 (PR #6496, commit dabfe8f08): removed the missing-LTV guard in openroad/prep.py entirely. Abhishek flagged it as hacky and he was right on two counts.

It defended against nothing. offer_model.py:453 branches on ec.maximum_ltv being ABSENT AS A COLUMN, not on its value -- so a NaN LTV suppresses the 19x fan-out exactly as well as a real one. The guard was protecting an invariant that was never at risk.

It was also on the wrong side of a rule this codebase already documents. northpond/prep.py states it outright: a missing feature VALUE is coerced and left to the model, a missing COLUMN is a query bug and raises. Surveyed every platform prep/predictor: missing-column raises exist (northpond/prep.py:48, prosper/predictor.py:183); missing-VALUE is coerced everywhere -- northpond, sofi, upgrade, happymoney, prosper -- and nobody raises. The single null-value raise is marlette/predictor.py:164 on FUNDED_DATE, an ANCHOR date that misplaces the whole curve on the time axis rather than degrading one feature, and even northpond handles its equivalent MOB anchor by warning and dropping the loan (northpond/predictor.py:429) rather than raising. So the openroad guard was the only one of its kind.

And it contradicted this PR's own position: openroad scores loans with ~89% of model inputs NaN by design (the sparse-back-book finding), so hard-failing the whole channel on ONE NaN input was incoherent.

Structural case still covered with no guard: base.py:810 reads each _EXTRA_CREDIT_COLUMNS entry off the credit table, so a missing MAXIMUM_LTV column (e.g. terraform not applied) raises KeyError naming the column at load time, before the prep runs.

prepare_features is now 3 lines. _MAX_REPORTED_IDS -- added one commit earlier to fix the silent [:10] truncation Abhishek also flagged -- is gone with it, which resolves that comment properly rather than elaborating around it. Tests: swapped the 3 error-message assertions for the invariant that matters (NaN LTV still yields the column so the fan-out stays suppressed; coerced not filled). 40 prediction tests pass, ruff/mypy clean. Re-ran curr_mod after the change: 35 loans, 2,507 rows, same 'Not overwriting provided maximum LTV' branch -- byte-identical behaviour to before the simplification.

LESSON worth carrying: my first response to the [:10] comment was to elaborate the block (named constant + truncation suffix + 2 tests) when the correct response was to delete it. Check whether a flagged construct should exist before improving it.
- 2026-08-26T19:35Z [claude-code] CI FIX 2026-08-26 (PR #6496, commit 6664f14e1). CI 'Run Tests' was failing: prep_test.py imported run.py at module scope, run.py pulls efp.checkin -> sqlalchemy -> termcolor which is conda-only, and the whole module became a collection error (ModuleNotFoundError: termcolor). I introduced this myself when hoisting the in-function imports to satisfy ruff PLC0415 earlier in the session.

THE TRAP I ALMOST FELL INTO, worth remembering. The obvious fix is to copy run_test.py, which module-scope pytest.importorskips the same two conda stacks. That would have made CI green by making the tests DISAPPEAR. ci_tests.yml runs the legacy suite as 'conda python -m pytest . --ignore=edgefocus/ --ignore=orchestration/' (line 165) and the new suite as 'uv run pytest edgefocus/ orchestration/' (line 172). So everything under edgefocus/ is uv-only, and a module-scope importorskip on a conda module means the file never executes in CI. Verified: run_test.py reports '1 skipped' under uv, and conda never sees edgefocus/ -- so its ~40 registry assertions are DEAD IN CI today. Pre-existing repo coverage hole, not mine to fix in this PR, but worth raising separately.

FIX: only the registry test needs run.py, so it now calls pytest.importorskip INSIDE the test. prep, predictor and base all import cleanly under uv (checked individually), so the other 8 tests collect and run there. Result: uv 33 passed / 2 skipped for the predictions dir (was a collection error), conda 40 passed. Full CI command reproduced locally -- 'PYTHONPATH=lib pytest edgefocus/ orchestration/' under uv gives 4,394 passed / 5 skipped. Legacy spot-check lib/efp/modeling/{models,auto} under conda: 202 passed.
- 2026-08-26T19:58Z [claude-code] CI FULLY GREEN 2026-08-26 on PR #6496 head 6664f14e1: Run Tests pass 7m30s, Run integration tests pass 2m6s, Select tests pass 17s. The termcolor collection error is resolved.

MISREPORT WORTH REMEMBERING: 'gh pr checks' rendered a CANCELLED job as 'fail', and I relayed that to Abhishek as a genuine test failure before checking. Integration attempt 1 (job 98299198208) sat 19m30s waiting for a runner and was cancelled, never executing; attempt 2 (98305348333) ran in 2m6s and passed, consistent with the 2m49s baseline. When a check reads as failing, query the conclusion field -- 'gh api repos/edgefocus/efp/commits/<sha>/check-runs' -- before calling it a failure, since cancelled/skipped/timed_out all surface as 'fail' in the summary view.

PR state: draft, 8 files, +275/-5. Remaining before it leaves draft, both needing Abhishek: (1) terraform plan on the shared silver.api_credit_attributes must be confirmed an in-place ALTER rather than a replace, because the tf declares replace_triggered_by on API_CREDIT_ATTRIBUTES_STREAM which every platform's credit-attributes transform consumes; (2) checkin.py --create rows for curr_mod_openroad_openroad_auto_refi and best_est_openroad_openroad_auto_refi. Also still unraised as its own ticket: run_test.py's ~40 registry assertions never execute in CI (module-scope importorskip on conda-only modules + ci_tests.yml running the legacy suite with --ignore=edgefocus/), a pre-existing repo-wide hole deliberately left out of this PR.
- 2026-08-27T13:32Z [claude-code] APPROACH CHANGED 2026-08-27 (PR #6496, commits e6b8e991b + 9b48df22b): the shared-column route is OUT. Abhishek rejected adding MAXIMUM_LTV to silver.api_credit_attributes and asked for the option space. maximum_ltv now rides on the openroad PAYLOAD instead. PR touches NO terraform -- 7 files, +278/-7.

OPTIONS EXPLORED, two killed by measurement not taste:
- Drop the value entirely (all-NaN): RULED OUT. maximum_ltv is in model.get_model_columns(); scoring without it moves cumulative default 17.8% median / 27.4% max. Measured by scoring the same 35 loans with real / NaN / constant LTV.
- Predictor joins silver.openroad_offers on TIMESTAMP_NS: RULED OUT. All 34 funded credit rows match MANY offers on that key and all 34 have CONFLICTING LTVs across matches -- the key hits the whole 19-offer grid. Disambiguating needs unique_offer_key, so the predictor would have to re-implement the transform's purchase-tape -> offers chain incl. the DEV-1393 crosswalk and QUALIFY dedupe; two copies of a subtle join that mis-score silently on drift.
- CHOSEN: OBJECT_INSERT the accepted offer's maximum_ltv onto the payload in openroad_api_credit_attributes. Abhishek noted the precedent himself -- bronze/api_events_utils.py:183-195 rewrites payload keys the same way at ingestion -- and the payload already carries gateway annotations (gateway_time, gateway_transaction_id, _credit_pull_attempt/_success), so it was never a pristine partner request. anchored's prep already depends on gateway_time arriving that way.

THE PAYOFF: json_normalize lands it under exactly ec.maximum_ltv, so the prep's whole prepare_features AND the predictor's _EXTRA_CREDIT_COLUMNS are both DELETED. prep.py is now one method (the raw-key drop) and predictor.py is pure config -- the anchored shape exactly.

THE TRAP, found by testing the edge case: OBJECT_INSERT DROPS a key whose value is a SQL NULL, and a dropped key is precisely the 19x fan-out trigger. So a single future NULL LTV would have broken the whole channel with a confusing 'no efp_id mapping' error. Fix is COALESCE(TO_VARIANT(x), PARSE_JSON('null')) which keeps the key as JSON null -> NaN model input. Verified both branches. Abhishek asked for a test pinning this: md_test gains loan E with a NULL offer LTV asserting payload contains maximum_ltv: null rather than omitting the key, plus a unit test that the prep does not drop the column.

BEHAVIOUR-PRESERVING, proven not asserted: dropped MAXIMUM_LTV from the DEV table entirely so nothing could fall back to it, re-ran the transform (35 rows, key present 35/35, 12 distinct values, no other platform's payload touched) and curr_mod, then diffed the parquet against the column-based run -- 2,507/2,507 rows exact, max_abs_diff 0.0 on default_probability, prepay_probability, term, rate, amount.

MY ERROR WORTH REMEMBERING: I first 'reverted' the terraform with 'git checkout <file>', which restores from HEAD -- and HEAD already carried the column from the earlier commit, so it was a no-op. I then printed the diff vs origin/master, which clearly showed the column still there, and labelled it '(empty = no terraform change)'. Caught it only in the next diffstat. git checkout <path> reverts to the INDEX, not to the base branch; use 'git checkout origin/master -- <path>' to undo a committed change.

Gates: ruff/mypy clean, dagster check_definitions clean, uv edgefocus/+orchestration/ 4,392 passed / 5 skipped, conda predictions 38 passed, md_tests validity 44 passed. PR body rewritten -- no tf-apply step, the two ruled-out options documented, and a new evidence block showing the 0.0-diff refactor proof.
- 2026-08-31T15:50Z [claude-code] SWEEP 2026-08-31 — no movement in four days, and the reason is a reviewer gap that has now bitten three times this month.

PR #6496 state as of today: OPEN, **isDraft=true**, ZERO reviewers requested, ZERO reviews, last update 2026-08-27T13:32Z. Linear DEV-1499 is 'In Progress'. Nothing has been pushed since the 08-27 review fixes.

Abhishek told Nakula in DM on 2026-08-27 00:41 IST that #6496 'is still WIP will ping once done' — captured as [[wm-wzhznq]] so the promise does not die with that DM. Nakula is waiting on that ping; he asked for the CMOP/BEP pipeline, and the NorthPond half he reviewed (#6462) merged the same day.

The pattern worth naming, because [[wm-f7egzv]] and [[wm-sn2x5s]] both recorded it independently: on this repo a PR with no requested reviewer gets no review, and draft status hides it entirely. #6459 got Scott's approval within 90 minutes of being visible with reviewers on it; #6454 has had reviewers but no reviews for five days; #6496 and #6491 have neither and are invisible. Whatever is left to finish here, the last step is 'undraft AND request', not 'undraft'.
- 2026-08-31T18:26Z [claude-code] VALIDATION GAPS CLOSED 2026-08-31, after Abhishek asked whether everything was tested in DEV_ABHISHEK and his local dpx Dagster. Honest answer had been NO; now mostly yes.

REBASED onto master (was 51 behind) -> head ea9b9d35c. PR #6462 (DEV-1498 northpond CMOP/BEP) had MERGED, which is what conflicted: both conflicts were registry additions in run.py and run_test.py, resolved as a UNION so openroad sits alongside northpond_loan_fl and northpond_exp_loan_fl. Gates after rebase: 4,525 passed (uv edgefocus/+orchestration/), 46 conda prediction tests (up from 38, now including northpond's), ruff/mypy/check_definitions clean.

CI FULLY GREEN on the rebased head, and this is the gap that mattered most: 'Run integration tests' PASSED and the log confirms openroad_api_credit_attributes.md::test_snowflake PASSED. So the OBJECT_INSERT SQL and the loan-E NULL case executed against a real ephemeral Snowflake DB for the first time -- previously the md_test had only ever passed on the older column-based version at 6664f14e1.

ISOLATED DAGSTER STACK for this workspace: dagster-{webserver,daemon,postgres}-abhishek-dev1499, webserver port 13099, postgres 15499, launched from ~/claude-ws/dev-1499/efp/orchestration with USERNAME=abhishek-dev1499 for container naming and an override pinning in-container USERNAME=abhishek so DEV_{USERNAME} stays DEV_ABHISHEK. Override at ~/claude-ws/dev-1499/dev1499-override.yml. Base compose mounts are RELATIVE (../edgefocus, ./assets) so running compose from the workspace mounts that branch automatically -- that is the whole trick. It does NOT disturb the ~/repos/efp instance on 13053 or the dev-1498 one on 13098. Base compose does not mount orchestration/agent_env.py or __init__.py and the image copies are stale, so definitions.py fails to import without adding them as mounts (same fix dev-1498 needed).

CHAIN RUN THROUGH DAGSTER IN DEV_ABHISHEK, all RUN_SUCCESS:
- openroad_api_credit_attributes 5783dc4f-134f-4406-95e0-5ef35cd2f049, 35 deleted/35 inserted, stream consumed clean. First time this asset has ever run through Dagster for openroad.
- CMOP+BEP via run.py to s3://efp-sandbox/predictions -> 2,507 and 1,067 rows, both on the 'Not overwriting provided maximum LTV' branch.
- s3_prediction_files b9ba0011-d773-48b6-88ad-b74f36da9374, 2 files found/2 inserted.
- s3_predictions 2e749409-cb3f-4938-809c-04a709a4f12d, 3,574 rows inserted = 2,507 + 1,067 EXACTLY. Zero loss confirmed in silver.predictions: curr_mod 2,507 rows/35 loans, best_est 1,067/15, source=s3, periods 1-72, 0 null DEFAULT_PROBABILITY, 0 null S3_BASE, model = the current 20260623v1 artifact.
- predicted_cashflows still running at time of writing.

PREFIX GOTCHA, cost an hour: ingest_prediction_files' PATH_PATTERN is s3://[^/]+/predictions/... -- bucket root then 'predictions/'. Every earlier dev-1499 run wrote to s3://efp-sandbox/abhishek/dev-1499/, which does NOT parse, so those parquets could never have round-tripped no matter what. dev-1498's full_runs.py docstring already documented this. Our files use PATH_PATTERN_NO_DATE (no date folder), valid for curr_mod/best_est only, with AS_OF_DATE derived from generation_ts.

LATENT BUG FOUND in edgefocus/transformations/bronze/ingest_prediction_files.py sync_prediction_files: scan_prefix = s3_prefix then += f'{platform}/', so an s3_prefix WITHOUT a trailing slash silently becomes 's3://efp-sandbox/predictionsopenroad/' and matches zero files. Combined with force=True that is destructive: zero matches still runs DELETE FROM prediction_files WHERE PLATFORM = ..., then calls insert_df on an EMPTY DataFrame which dies with 'syntax error at position 86 unexpected )'. So a mistyped prefix plus --force wipes a platform's file registry and crashes before reinserting. I hit exactly this; verified no damage because openroad had zero rows there (the 9 listed platforms sum to the table's full 1,100). NOT fixed here -- shared file, out of scope for this PR. Worth its own ticket.

ALSO SPOTTED, not mine: DEV_ABHISHEK.BRONZE.PREDICTION_FILES has a corrupt MAX_LOADED of -238106-11-08 on the northpond slice (timestamp overflow).
- 2026-08-31T18:37Z [claude-code] BLOCKER FOUND 2026-09-01: predicted_cashflows cannot consume openroad CMOP/BEP, and the blocker is SHARED with anchored -- it is not something to fix in the openroad predictor.

WHAT FAILS: predicted_cashflows asset dies with TypeError: float() argument must be a string or a real number, not 'NoneType' at populate_predicted_cashflows.py:294/297, inside _build_config_from_row -> float(row['RECOVERY_FRAC']) / float(row['SERVICING_FEE']). It processed exactly my two openroad s3_bases, so it is my data.

CAUSE: openroad_auto_refi's cfframe config is ConfigSnapshot('2023-11-02', 'recovery_fraction_ltv', 4, 4, 'servicing_fee') -- recovery_frac and servicing_fee are per-loan COLUMN NAMES resolved from the gateway model response, not scalars. base.numeric_or_none() deliberately drops str to None ('those can't be embedded as scalar DOUBLEs'), so the conda predictor writes NULL. Verified: my curr_mod 2,507/2,507 and best_est 1,067/1,067 rows are NULL on both, while the gateway at_orig slice is 0/2,507 null because openroad_api_predictions.py resolves them in SQL from the model_responses payload (which does carry recovery_fraction and servicing_fee as top-level keys).

NOT OPENROAD-SPECIFIC. Channels with string-sentinel configs: anchored_auto_indirect, anchored_indirect, foursight_auto_indirect, innovate_auto_refi, openroad_auto_refi. PROD anchored curr_mod 163,158 rows and best_est 105,318 rows are 100% NULL on RECOVERY_FRAC and SERVICING_FEE, and calling _build_config_from_row on an anchored PROD row with current master RAISES the identical TypeError. So anchored is in exactly the same state.

UNRESOLVED TENSION, stated rather than explained away: anchored's cashflows ARE being written in prod -- PREDICTED_CASHFLOWS_HISTORY LOADED_AT 2026-08-30 14:39 for best_est and 2026-08-27 14:12 for curr_mod, ~30 min after each prediction generation, so those are real recent writes and not stale rows. Yet the same code path on the same data raises here. float(row['RECOVERY_FRAC']) has been in place since #5509 (DEV-1233), so it is not a fresh regression. I could NOT reconcile this and did not invent an explanation. Either prod runs a revision that differs from master, or there is a resolution path I have not found. Worth an independent look -- if prod is about to pick up master's behaviour, anchored's CMOP/BEP cashflows break too.

WHERE A FIX BELONGS, if wanted: not in the openroad predictor. Either the pipeline resolves recovery_fraction_ltv / servicing_fee per loan when embedding (mirroring what openroad_api_predictions.py already does in SQL for at_orig), or _build_config_from_row does that resolution. Both are shared-code changes well outside DEV-1499's scope. Papering over it with a fillna would fabricate a model input -- the at_orig data shows the real values vary per loan (openroad RECOVERY_FRAC 0.32-0.46, anchored 0.226-0.673).

STATE OF THE CHAIN otherwise: everything up to and including silver.predictions works, verified zero-loss. Only the cfframe stage is blocked.
- 2026-08-31T20:39Z [claude-code] RULED OUT while chasing the anchored/openroad predicted_cashflows tension (2026-09-01), so nobody re-derives these:
1. Recent regression -- float(row['RECOVERY_FRAC']) dates to #5509 (DEV-1233) and numeric_or_none to #5620; neither is new. Only recent touches to populate_predicted_cashflows.py are #6206 and #6190 (memory batching).
2. Pandas dtype inference at scale -- ran the real loader over anchored's FULL prod slice, 136,107 rows: dtype=object, nulls=136,107, first=None, float() raises. Not a small-sample artifact.
3. Dated vs dateless S3_BASE (#6285 made curr_mod/best_est stable-dateless) -- anchored's dated bases .../curr_mod/2026-08-14 and /2026-08-13 are ALSO 100% null on RECOVERY_FRAC, so the layout change is not the discriminator.
4. A matching prod Sentry error -- EFP-ERRORS-WK '[Dagster] predicted_cashflows failed' is resolved, last seen 12 days ago. The live one, EFP-ERRORS-WQ (700 occurrences, last 2026-08-31 17:01, ERROR-977), is 'ingest_prediction_files failed -- Exceeded maximum runtime of 7080 seconds' -- a TIMEOUT on the umbrella job, not this TypeError.

So prod is not currently throwing this error, yet anchored's prod data plus master's code reproducibly does. Unexplained. Most likely remaining candidate is that prod's deployed revision differs from master, which needs someone with prod Dagster/deploy visibility to confirm. Not pursued further -- it is orthogonal to DEV-1499 and the openroad chain is blocked either way.
