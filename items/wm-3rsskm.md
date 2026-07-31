---
id: wm-3rsskm
type: task
title: Build + promote the oliv_exp_statement_model artifact, then re-run northpond_api_predictions to drop the stale exp api rows
status: next
priority: p1
size: s
people: [Trishit]
tags: [northpond]
created: 2026-07-31T17:36:11Z
updated: 2026-07-31T17:36:15Z
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
