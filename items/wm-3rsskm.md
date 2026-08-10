---
id: wm-3rsskm
type: task
title: Build + promote the oliv_exp_statement_model artifact, then re-run northpond_api_predictions to drop the stale exp api rows
status: next
priority: p1
size: s
people: [Trishit]
tags: [northpond]
links: [relates:wm-g22j5e]
created: 2026-07-31T17:36:11Z
updated: 2026-08-10T14:45:52Z
source: claude-code
---

Sequenced follow-through for PR #6082 once the predictor restructure lands (see [[wm-g22j5e]]).

Order matters -- shipping the api_version=1 gate before the generator produces rows leaves exp loans with no at_orig row at all:

1. Build the artifact: `bin/model_backtest/oliv_exp_statement_model_backtest.py --mode production`. Verified 2026-07-31 that nothing exists at `s3://efp-derived/modeling/statics/oliv.*` yet, so `predictor.load_model()` would fail today.
2. Merge, so `get_model_spec_for_date` resolves the channel from master git history (the predictor logs a loud fallback to the deployed spec until then).
3. Let the hourly cron (`run.py --prediction-type at_orig`) generate the exp slice into s3://efp-raw/predictions -> ingest -> source='s3'.
4. THEN re-run `northpond_api_predictions --date all` to delete the 4,860 stale source='api' exp rows (32 as_of_dates, exp-only, so no TU collateral).

Do NOT do step 4 before step 3: between them the exp loans have no at_orig row.

Also: 2 loans change by design at step 3 (the 6.5% ANL floor binds where oliv_anl is 0.0644 / 0.0637), so silver.ef_scores for those two will move -- related to [[wm-vye9hn]].

## Log
- 2026-08-10T14:45Z [claude-code] STATUS CHECK 2026-08-10 — PR #6082 MERGED 2026-08-05 20:07Z, so steps 1-2 of this sequence are behind us and steps 3-4 are now the live question. This item has had no log entry since it was created on 07-31, so nothing here records whether they ran.
STEP 1 IS DONE — verified on dpx today: s3://efp-derived/modeling/statics/ contains oliv.oliv_exp_statement_model.2026-07-29_production_model.train_on_everything.oliv_exp_statement_model.pkl.zst, 204 bytes, written 2026-07-31 19:52. The body's warning that 'nothing exists at s3://efp-derived/modeling/statics/oliv.* yet, so predictor.load_model() would fail today' is therefore STALE — the artifact was built the same evening the item was created. That removes the worst failure mode (a merged v1-gate with no artifact to load).
STILL UNVERIFIED, and this is what someone needs to check:
- Step 3: has the hourly cron (run.py --prediction-type at_orig) actually generated the exp slice into s3://efp-raw/predictions and ingested it as source='s3'? Five days have passed since the merge.
- Step 4: the 4,860 stale source='api' exp rows across 32 as_of_dates — still there, or cleared by a northpond_api_predictions --date all re-run?
If step 3 silently never ran, exp loans have had no at_orig row since the merge. Not confirmed either way; needs a Snowflake read, which this session could not do.
