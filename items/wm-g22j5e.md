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
updated: 2026-07-31T18:07:52Z
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
