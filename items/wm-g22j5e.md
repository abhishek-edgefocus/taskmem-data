---
id: wm-g22j5e
type: followup
title: Give Trishit inputs on PR #6082 (oliv_exp_statement_model) + the Dagster wiring discussion
status: next
priority: p1
size: xs
due: 2026-07-31
people: [Trishit, Nakula, Sean]
tags: [northpond, needs-reply]
links: [relates:wm-9s2mwd, relates:wm-j2prpv]
refs: [PR6082=https://github.com/edgefocus/efp/pull/6082, sean-thread=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1785264036485469]
created: 2026-07-29T13:42:21Z
updated: 2026-08-03T13:44:41Z
source: claude-code
label: PR 6082 oliv statement model
---

RESOLVED SINCE THIS ITEM WAS OPENED (2026-07-29): Trishit took the work, and Sean's
"put it in a real model object" ruling has been implemented as **PR #6082** —
`oliv_exp_statement_model: retarget + ANL floor as a real model artifact`. Status on
2026-07-31: **APPROVED, still open**. Discussion is happening in the new group DM
C0BLXJE8534 (Trishit, Abhijeet, Nakula, Abhishek).

THE AMBIGUITY THIS ITEM FLAGGED IS ALSO RESOLVED: Sean's "statement model" is genuinely a
STATEMENT-side model and is **not** DEV-1452/QR-23 (the purchase-tape model, [[wm-9s2mwd]]).
They are separate pieces of work.

WHAT PR #6082 ACTUALLY DOES — worth reading before replying, because it changes what
DEV-1445 shipped:
- Registers `oliv_exp_statement_model` in models_by_channel.json as a real serialized
  artifact resolved by model_name + git tag, satisfying `ModelProtocol` (patterned on
  `prosper_cde_statement_model`).
- `predict()`: `target = max(oliv_anl if published else our_anl, 6.5%)`, `k = target/our_anl`,
  `default' = clamp(default*k, 0, 1)`, prepay untouched. **The 6.5% ANL floor is new policy**
  — it sits just above the ~6.31% E2/E3 boundary so every exp loan grades minimally E3, and
  it is applied by scaling the curve, never by clamping the ANL.
- **Reverts the inline retarget in `northpond_api_predictions.py` and gates it to
  `api_version=1`**, so exp predictions come only from the model. Exp at_orig moves
  `source='api'` -> `source='s3'`.
- Renames the model in `silver.predictions` from the gateway `northpond_exp` to the Oliv
  statement model — Trishit's deliberate choice so the owned portfolio can be fetched
  directly rather than matched via IDs, and he explicitly asked whether the dev team is OK
  with it.

TWO OPEN ASKS DIRECTED AT ABHISHEK:
1. Trishit, 2026-07-31 16:36 IST: "I have a comment in the last of this updated PR as a
   reply to one of the bots where I'd need your inputs" (@-ing Nakula and Abhishek).
2. Trishit, 2026-07-31 02:34 IST: "had to make changes to the structure here so let's
   connect tomorrow to discuss what else needs to be done. Claude mentioned addition to some
   Dagster assets and all so I'll rely on your expertise on the subject" — i.e. the Dagster
   wiring is the part he wants Abhishek to own.

RISK TO RAISE IF NOBODY HAS: the PR's own verification section says the generator, the
transform revert and the Dagster wiring were **not run** on the authoring box, and that
**shipping the v1-only gate without the generator scheduled would drop exp at_orig rows**.
It also requires a parity gate (generated curves bit-match the old inline retarget on the
same inputs) before promotion. Approved is not the same as safe to merge here.

Nakula's read (C0BLXJE8534, 2026-07-30): largely a refactor; no predictions are actually
made from the model, its only purpose is to mark in silver.predictions that these are not
gateway-derived; no downstream Snowflake consequences beyond the model name. He suggested a
helper in `northpond_api_predictions.py` might do instead of a separate
`oliv_exp_statement_model.py` — Trishit disagreed, wanting tagging and version control.

Knock-on for two existing items: [[wm-etzegu]] (alert on silent k=1 retarget fallback) and
[[wm-vye9hn]] (force ef_scores re-derive of the 33 stale loans) were both written against
the inline SQL retarget this PR removes.

## Log
- 2026-07-31T12:55Z [claude-code] REFRAMED 2026-07-31: created as 'get back to Trishit on ownership + Sean's ruling'. Both halves are now settled — Trishit owns it and has shipped PR #6082 (APPROVED, open), and Sean's 'statement model' is confirmed statement-side, not the purchase tape. The item is retitled to what is actually still owed: inputs on his bot-reply comment (asked 2026-07-31 16:36 IST) and the Dagster-wiring discussion he explicitly wants Abhishek to drive (asked 2026-07-31 02:34 IST). Due set to today since both asks are from today and one is 2 days old.
- 2026-07-31T16:58Z [claude-code] LIVE STATE 2026-07-31 22:27 IST. PR #6082 is APPROVED, mergeable, mergeState CLEAN, checks green (4 SUCCESS / 1 NEUTRAL), last pushed 15:00Z. Sequence this evening in C0BLXJE8534:
- Trishit 20:38: 'Have refreshed the PR to make the changes needed. Feel free to take over' (@Nakula @Abhishek).
- Trishit 21:44: stepping out in 45 mins, back late, will check messages.
- Nakula 22:20: '@Abhishek Let me know if you need any assistance/want me to take over if you are busy' — DIRECT, UNANSWERED ask. Nakula is available and volunteering; a one-line reply either hands it to him or keeps it.
NOTHING IS BLOCKING THE MERGE MECHANICALLY, which is the risk: the PR's own description says the generator, transform revert and Dagster wiring were never run, and that shipping the v1-only gate without the generator scheduled would DROP exp at_orig rows. Green + approved is not the same as safe. If this merges tonight without the generator scheduled and the parity gate run, exp predictions break.
- 2026-07-31T17:35Z [claude-code] 2026-07-31 session (workspace ~/claude-ws/oliv-exp/efp on dpx, branch oliv_exp_statement_model).

VERIFIED IN PROD what actually lands in silver.predictions (the 'are we double-writing?' question):
- api_version 1 and 2 are DISJOINT: 0 applications carry both a v1 and a v2 model_response. The PR's api_version=1 gate therefore cannot double-write a loan; no exp loan gets a TU row alongside its model row.
- The exp slice today = 135 loans / 4,860 rows, all source='api', MODEL_NAME='northpond_exp_model'. No duplicates exist yet.
- Those rows are ALREADY Oliv-retargeted (133 scaled by k=oliv_anl/our_anl; 2 unscaled because Oliv published no ANL). So 'original vs modified' resolves to: the leftovers are the OLD retargeted rows, and they collide with the new source='s3' rows once the generator runs.
- Removal is a TRANSFORM RE-RUN, not a manual DELETE. The swap deletes WHERE as_of_date IN (processed dates) AND source='api' AND platform='northpond', then re-inserts the v1-gated temp table. Checked: the 32 exp as_of_dates contain ONLY exp rows (0 non-exp api rows), so a re-run deletes exactly those 4,860 and re-inserts nothing, leaving the 25,740 TU rows on other dates untouched. Command: northpond_api_predictions.py --date all.

RESTRUCTURED the generator to the SoFi predictor+prep pattern (Abhishek's ask). Committed locally as ed7476c41, NOT pushed:
- deleted northpond/oliv_exp_predictions.py (standalone SQL + main())
- added northpond/prep.py + northpond/predictor.py (OlivExpStatementPredictor) + predictor_test.py
- registered in run.py FORWARD_FLOW_PREDICTORS as 'northpond_exp'
- ANSWERS THE DAGSTER-WIRING QUESTION: no new asset needed. run.py --prediction-type at_orig already runs HOURLY in cron (execution/cron/dumbledore/ubuntu/existing.cron:419) and iterates every registered predictor. Registering = scheduled.

PARITY GATE PASSED (prod inputs -> s3://efp-sandbox/abhishek/oliv_exp_parity): same 135 loans / 4,860 rows, every column bit-matches the api rows except DEFAULT_PROBABILITY on exactly 2 loans, both where the new 6.5% ANL floor binds (oliv_anl 0.0644, 0.0637). That is the intended policy change.

OPEN:
1. Model artifact NOT built -- nothing at s3://efp-derived/modeling/statics/oliv.*. bin/model_backtest/oliv_exp_statement_model_backtest.py --mode production must run before real generation.
2. Pre-existing gap (not this PR's): northpond has no branch in api_predictions_utils._get_dq_strat_for_date, so DQ_STRAT_NAME/VALUE are NULL on every northpond api row; populate_predicted_cashflows falls back to get_dq_strat -> term_band with no per-loan strat value to join on. Affects the TU rows too.
- 2026-07-31T18:03Z [claude-code] Abhishek redirected the scheduling (2026-07-31): the exp generation should be a Dagster asset inside the broader statements_northpond job, NOT the generic hourly run.py predictions cron. Implemented as commit e2c169938:
- new asset northpond_exp_predictions in orchestration/assets/northpond_assets.py, deps=[northpond_stmt_issuance, northpond_stmt_issuance_v2], group SILVER, with an OlivExpPredictionsConfig (force / output_prefix)
- added to the statements_northpond job selection right after northpond_api_predictions
- UNREGISTERED from run.py FORWARD_FLOW_PREDICTORS: two schedulers would each see a loan as unpredicted and write it twice (dedup is at selection time, not write time). The asset is now the single trigger; Dagster materialization is the manual/backfill path.
- predictor now subclasses Predictor directly (ForwardFlowPredictor only supplied the silver.positions universe this channel overrides)
Rationale: the predictions depend on the issuance + issuance_v2 files, so generating them in the job that lands those files orders the work instead of racing it hourly. NOTE the asset writes parquet only -- rows land in silver.predictions when s3_prediction_files -> s3_predictions next run (ingest_prediction_files job).
Verified: Dagster repo loads, asset resolves in the job (21 assets) with both deps, 31 tests pass, parity unchanged.

ALSO CONFIRMED for Abhishek's 'modify once at the top of the DAG' question: after this PR the Oliv ANL is applied in exactly ONE place. northpond_stmt_issuance_v2 is read by only 4 files -- the ingest transform that populates it, its 2 orchestration wirings, and the predictor. Zero other retarget/oliv_anl logic anywhere in the codebase, and no northpond special-casing in the downstream prediction/cashflow/gold transforms. Downstream reads the stored curve as-is.
- 2026-07-31T18:07Z [claude-code] PUSHED to PR #6082 (2026-07-31, Abhishek approved): commits 182e9fe91 (predictor+prep restructure) and 912f350f0 (Dagster asset in statements_northpond). Fast-forward from bb09105c7, remote tip verified unmoved twice before pushing, no force. Both carry the Co-Authored-By trailer per repo convention.

Net effect on the PR file list: run.py and oliv_exp_predictions.py no longer appear at all (added then removed within the branch), so the PR now shows northpond/predictor.py + prep.py + predictor_test.py as the generator, plus the two orchestration files.

STALE: the PR description still describes oliv_exp_predictions.py as the generator and still carries the 'runnable but not wired in Dagster / could drop exp at_orig rows' risk note, both of which are now resolved. Trishit should refresh it (Abhishek to raise -- agents do not edit shared data).
- 2026-07-31T18:26Z [claude-code] CI on PR #6082 failed after the first push -- ruff format --check on the 3 new files. The job aborts at that step, so mypy/pytest/dagster-check never ran; re-running them locally surfaced 2 more real mypy errors (~ on Series.values union type in _issuance_positions_frame, and an unannotated parametrized test arg). Fixed in b386d48d2 and pushed. Note the repo AGENTS.md says not to run ruff, but CI enforces ruff format + ruff check + mypy, so new files must be formatted before pushing -- worth remembering for future PRs here.
Verified locally before pushing: ruff format --check clean tree-wide, ruff check clean, mypy clean on 924 files, orchestration/scripts/check_definitions.py passes, 31 tests pass, parity run byte-identical.

For the DAG screenshot (Abhishek's pr-style.md requires one): the deployed Dagster on :13053 cannot show it, since northpond_exp_predictions only exists on the branch. Started an ISOLATED dagster-webserver for him on dpx: 127.0.0.1:13077, DAGSTER_HOME=~/claude-ws/oliv-exp/dagster_home, webserver only (no daemon, so no sensor/schedule can fire), log at ~/claude-ws/oliv-exp/webserver.log. Reachable via VSCode Remote-SSH port forwarding. Kill with: pkill -f 'dagster-webserver.*13077'.
DAG delta to capture: the issuance_v2 edge MOVES -- northpond_api_predictions goes from [issuance, issuance_v2] to [issuance], and the new northpond_exp_predictions takes [issuance, issuance_v2].
- 2026-07-31T18:53Z [claude-code] CI on PR #6082 fully green after b386d48d2 (Run Tests, integration tests, Select tests, Seer all pass; Bugbot skipped). Integration tests passing confirms the reverted transform agrees with the restored md_test fixture.

NAKULA REVIEW (2026-07-31, 5 comments on predictor.py) -- assessed, NOT yet replied to. Abhishek agrees with some but not all; he asked me to check the silver.positions one specifically:
- :27/:194 'run the predictor off silver.positions instead of overriding load_candidate_loans' -- RIGHT TARGET, NOT FEASIBLE TODAY. Verified in prod: 133 of 135 exp loans have no silver.positions row (the entire July book; only the Jan + Apr loans are there), and silver.northpond_stmt_purchase_tapes is stale since 2025-06-17 (372 rows, no new experimental-fund purchases since 2026-04-16). A positions-gated predictor shipped today emits 2 loans and drops 133 -- the same data loss the Sentry bot flagged as CRITICAL, reached from the other side. Revisit once EDGEX purchase tapes land ([[wm-9dfnnt]]).
- Cycle question, checked properly and do NOT overstate it: adding a positions dep would NOT create a literal Dagster cycle for this asset, because s3_prediction_files has no upstream deps (the ingest path is decoupled). It IS a real cycle for a transform-based path, which is what the repo comment 'not silver.positions, which joins ef_scores and would close a Dagster cycle' refers to. What it does create is lagged coupling exp_predictions -> positions -> ef_scores -> predicted_cashflows.
- :27 also implies a DIFFERENT ARCHITECTURE worth settling explicitly: gateway OP stays as source='api' and the Oliv model adds an 'updated' prediction later. That conflicts with Abhishek's stated ideal state (only the modified curve in silver.predictions, applied once at the top of the DAG).
- :170 CMOP/BEP eventually -- fair follow-up; needs :239 first.
- :239 store model requests in silver.northpond_credit_attributes -- agree as the long-term path for CMOP/BEP; not needed for OPs.
- :286 move the model-spec fallback into base.py -- cuts against Abhishek's no-shared-code-changes rule; also the fallback is only a pre-merge crutch and could simply be DELETED after merge (third option nobody has raised).
Next: Abhishek to decide positions, then I draft the PR replies (he posts them).
- 2026-07-31T19:48Z [claude-code] Refactor comments resolved in-PR (2026-08-01):
- nakula :335 (_to_wide duplicates create_denormalized_preds) -- FIXED in 27799af4e, pushed. Turned out NO shared-code change was needed: create_denormalized_preds keeps only ID/PERIOD/DEFAULT_MONTHLY/PREPAY_MONTHLY and unstacks on period, which is what the hand-rolled pivot did; it just wanted the efp_columns names, so renaming the frame onto them lets us call it directly. Avoided a signature change that would have touched ~30 call sites (every platform producer + rate/price producers + off_market + compute_owned_loans_ef_score).
- nakula :286 (_resolve_model_spec duplicates base) -- DECIDED: do NOT promote to base.py. For the other 10 channels a missing model history is a genuine misconfiguration that should raise loudly; softening it in base would weaken that for all 13 predictors. The override is only a pre-merge shim (get_model_spec_for_date walks models_by_channel.json history on master, and this channel isn't there until merge).
  COMMITMENT: Abhishek decided to REMOVE the override in the SAME PR, as the LAST commit before merge -- after the ANL/EF-score validation run, which depends on it. Do not merge with it still present.

AUTHORSHIP finding (matters for routing review work): the functions Nakula flagged are NOT Trishit's. _resolve_model_spec, _to_wide/_denormalize and _issuance_positions_frame were all written by me in the restructure; they did not exist in Trishit's oliv_exp_predictions.py. What IS Trishit's is the SQL inside the two loader functions (all 5 CTEs, the efp_default_monthly_ unpivot, the payload:anl > 0 filter). Nakula's only comment on Trishit's own file (model.py:60, OfferModel inheritance) was already answered by Sean: 'It does not, it only has to satisfy the protocol... it probably shouldn't.'
- 2026-07-31T20:20Z [claude-code] DEV VALIDATION COMPLETE (2026-08-01, DEV_ABHISHEK) -- the run Nakula asked for. Full chain exercised on committed code 27799af4e; no code changes were needed to run it.
1. Built the artifact: bin/model_backtest/oliv_exp_statement_model_backtest.py --mode production -> s3://efp-derived/modeling/statics/oliv.oliv_exp_statement_model.2026-07-29_production_model...pkl.zst (204 bytes).
2. Materialized the northpond_exp_predictions Dagster asset for real (first exercise of the asset wrapper AND of load_model(); the earlier parity run had faked the model). 4,860 rows / 32 dates, output to s3://efp-sandbox/predictions/.
3. s3_prediction_files + s3_predictions -> 4,860 rows in DEV silver.predictions, source='s3', MODEL_NAME=oliv.oliv_exp_statement_model.2026-07-29_production_model.
4. populate_predicted_cashflows over 32 s3_base keys: 32 ok, 0 failed.
5. populate_ef_scores: 32 ok, 135 loans scored.

RESULT -- rebuilt EF_ANL vs Oliv's published ANL (133 comparable loans):
  mean diff +0.0009 (9bps high), median +0.0005, mean ratio 1.008
  100% within 1pp, 99.2% within 0.5pp, 63.9% within 0.1pp; worst +0.0067 (OLV12563452)
EF GRADES: E3=82, E4=53. Zero loans graded E1 or E2, so the floor's stated purpose holds.

THREE FINDINGS TO RAISE:
a) Grade split is 61/39 E3/E4, but Eric predicted ~90/10. Materially different from forecast -- this is the answer to Sean's question on the PR.
b) Floor headroom is thinner than the PR implies. The PR justifies 6.5% vs a '~6.31% E2/E3 boundary', but the score is ROUNDed before bucketing so the EFFECTIVE boundary is ANL ~5.96%; and the floor is applied to the model payload's ANL while the grade uses the cfframe-REBUILT ANL. OLV12563409 was floored to a 6.5% target and rebuilt at 6.31%. Still E3, but the mechanism is not as tight as '6.5% > 6.31%' reads.
c) Every cashflow build logged 'Failed to add DQ information to cfframe ... Returning cfframe without DQ rows' because dq_strat_value is NULL. So these ANLs are computed WITHOUT DQ roll rates. Pre-existing (prod api rows carry the same NULL), not a regression, but it distorts the ANL comparison and is the strongest argument for adding a northpond branch to api_predictions_utils._get_dq_strat_for_date in the follow-up.

DEV ENV GAP FIXED: DEV_ABHISHEK.BRONZE.PREDICTION_FILES_STREAM did not exist (terraform-managed; the clone predates it). Created just that stream by hand rather than running make tf-apply, because the tf has replace_triggered_by on the table and a full apply could recreate DEV tables. Reversible via DROP STREAM.
GOTCHA worth remembering: the ingest regex is s3://[^/]+/predictions/ -- 'predictions' must come immediately after the BUCKET, so a nested sandbox path like s3://efp-sandbox/abhishek/foo/predictions/ will NOT be parsed. Use s3://efp-sandbox/predictions/.
Also: S3Predictions consumes the silver.predictions target stream itself, so populate_predicted_cashflows sees 0 pending afterwards and must be driven with explicit s3_base keys.
- 2026-08-03T13:44Z [claude-code] STATE 2026-08-03 19:12 IST — PR #6082 is AT THE MERGE BUTTON, WITH ONE UNANSWERED QUESTION.
Review is complete: Trishit 2026-08-01 03:21 'It looks good to me but I'd let Nakula comment'; Nakula today 18:34 'I think it looks okay for now. Will need some refactoring in the follow-up PRs'. Abhishek 18:48: 'I will go ahead and merge.' Then 18:51, to Trishit: 'before merging do we need someone from QR to review? I see you have requested a review from Garvit' — **Trishit has not replied.** That is the only thing between this PR and master right now.
WHAT ABHISHEK STILL OWES ON IT, in his own words (2026-08-01 01:45-01:48):
- 'Testing is in progress - <PR #6082 review comment r3692657199> - this is required for testing will be removed before merge.' **Test-only code is still in the branch and must come out before merging.**
- 'I haven't responded to the PR directly - will respond with appropriate comments and follow up tickets before merging.' Both follow-up tickets now exist (DEV-1498 for credit attributes/CMOP/BEP, and draft PR #6131 for sourcing exp per-loan fields from silver.positions), but whether the PR comments were actually answered on GitHub is unconfirmed.
NAKULA'S PARITY ASK, partially discharged: he asked (08-01 00:19-00:25) for the ANLs and other metrics to be cross-checked against Oliv's loss metrics, since ANL is what determines EF Scores, and suggested checking whether naive multiplication produces equivalent predictions. Abhishek could not use experimental/efhyf loans (no Oliv ANL for them), so he tested against Nate's issuance_v2 sample loans and posted screenshots on 08-01 02:32, landing ~1%% off Oliv's ANL as PR #6015 did. He also flagged the one real logic difference: **the 6.5%% ANL floor**, which Trishit confirmed is intentional — 'we want to min cap ANLs to 6.5%%'. Nakula explicitly said remaining comments can go to follow-up PRs because this is time-sensitive.
UNCHANGED RISK from the PR description: the generator, transform revert and Dagster wiring were never run on the authoring box, and shipping the v1-only gate without the generator scheduled drops exp at_orig rows. [[wm-3rsskm]] is the item that covers building/promoting the artifact and re-running northpond_api_predictions — it should land with or immediately after this merge, not later.
