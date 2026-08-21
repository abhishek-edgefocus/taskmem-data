---
id: wm-te4cr2
type: task
title: ERROR-1626: northpond_exp_predictions fails every run — .efp_toplevel missing from the Dagster image
status: next
priority: p1
size: s
tags: [northpond, dagster, errors]
links: [relates:wm-3rsskm, parent:wm-btu784, blocks:wm-3rsskm]
created: 2026-08-10T20:05:48Z
updated: 2026-08-21T21:48:23Z
source: claude-code
---

ERROR-1626 / Sentry EFP-ERRORS-1JB. Investigated 2026-08-11.

ROOT CAUSE (confirmed from S3 compute logs, s3://efp-dagster-logs/compute-logs/storage/<run_id>/compute_logs/):

  AssertionError: .efp_toplevel not found
    northpond_assets.py:431 northpond_exp_predictions
    -> predictor.py:186 run -> base.py:657 -> base.py:546 _resolve_model_spec
    -> models_by_channel_history.py:248 get_model_spec_for_date
    -> :197 model_history -> :158 _tags_by_commit -> :106/:89 GitHub API call
    -> :60 _github_token -> Files() -> lib/efp/files.py:94 assert

orchestration/Dockerfile does a SELECTIVE copy (configs, edgefocus, lib/efp,
orchestration, pyproject.toml, uv.lock, README.md) and never copies the
.efp_toplevel marker. Files.__init__ walks up from /app/lib/efp/files.py to /
without finding it and asserts.

The asset has NEVER succeeded in prod. It fails at model-spec resolution before
touching Snowflake data or the model artifact. Verified the identical traceback
on the FIRST failure (run 16c38465, 2026-08-06 13:01Z) and the latest
(8fa70376, 2026-08-10 18:53Z). 292 candidate efp_ids / 41 batches are found,
then it dies immediately.

TIMELINE: PR #6082 merged 2026-08-05 20:07Z -> prod Dagster deploy 2026-08-05
21:57Z -> first failure 2026-08-06 13:01Z. Fails on every scheduled run since
(~3x/day, 13 events through 2026-08-10).

FIX (one line, exact precedent already in the tree):
  lib/efp/json_endpoints/platforms/api/northpond/experian/Dockerfile:41-42 does
    # Copy .efp_toplevel marker file (needed by batch.py)
    COPY .efp_toplevel /app/.efp_toplevel
  Add the same to orchestration/Dockerfile builder stage (the final stage does
  COPY --from=builder /app /app, so the builder stage is enough).

  This is sufficient on its own: configs/ IS already copied to /app/configs and
  configs/default_passwords.json does carry github.token, so get_passwords()
  resolves once the marker is found.

  ALTERNATIVE / arguably better: models_by_channel_history.py:57-60 already
  honours a GITHUB_TOKEN env override before falling back to Files(). Setting
  GITHUB_TOKEN on the Dagster ECS task avoids Files() entirely. GITHUB_TOKEN is
  currently set nowhere in terraform/ or the deploy workflows.

WHY NO OTHER DAGSTER ASSET HITS THIS: northpond_exp_predictions is the first
Dagster asset to go through the Predictor base class. northpond_api_predictions
and the rest are create_transform_asset (pure SQL transforms) and never
construct Files().

BLAST RADIUS: nothing in statements_northpond deps on northpond_exp_predictions,
so no other asset is blocked -- but the whole job is marked failed on every run,
and the exp at_orig slice has never been generated. This is the definitive
answer to the open step-3 question on wm-3rsskm.

STALE LINEAR TITLE: the issue title says failed step northpond_transfers. That
was a DIFFERENT, unrelated failure (2026-07-16..19, 10 events,
"ValueError: Validation failed with 1430 error(s)" in the transfers transform).
It stopped on 07-19 and the issue was closed; Sentry regrouped the new
exp_predictions failures under the same fingerprint and reopened it 08-06.
Consider splitting or retitling.

SIDE OBSERVATION (not this ticket): configs/default_passwords.json has a real
40-char ghp_ classic GitHub PAT committed to git.

## Log
- 2026-08-12T13:48Z [claude-code] ESCALATION 2026-08-12 from prod Dagster (read-only): this is not a single-asset failure. northpond_exp_predictions raising 'AssertionError: .efp_toplevel not found' is failing the ENTIRE statements_northpond job on every sensor tick — 20 consecutive FAILUREs, last SUCCESS 2026-08-05 18:44 UTC. The same runs also fail northpond_transfers with 'ValueError: Validation failed with 1116 error(s)', so there are two independent breakages in the same job. Full audit in [[wm-hjbt5a]].
- 2026-08-18T14:23Z [claude-code] RECONFIRMED 2026-08-18 (read-only prod Dagster + Snowflake). Still failing, nothing fixed.

- statements_northpond: 46 CONSECUTIVE FAILUREs. Last SUCCESS 2026-08-05 18:44Z; streak starts 2026-08-06 12:44Z; latest failure 2026-08-18 13:18Z. 13 days red.
- Latest run 30b5765a: 13 steps SUCCESS, 2 FAILURE - northpond_exp_predictions (AssertionError: .efp_toplevel not found, unchanged) and northpond_transfers (ValueError: Validation failed with 129 error(s); count drifts 1430 -> 1116 -> 129, so it tracks data volume, not a fixed defect).
- FIX STILL NOT LANDED: origin/master orchestration/Dockerfile has no COPY of .efp_toplevel (COPY lines are pyproject/README, configs, edgefocus, lib/efp, orchestration only). Last commit touching that file is 12f619a48, 2026-07-11 - predates the breakage. No PR open for it.
- DOWNSTREAM IMPACT QUANTIFIED: PROD.SILVER.PREDICTED_CASHFLOWS for northpond holds exactly ONE slice - channel northpond_loan_fl / at_orig, all rows sourced from the issuance path (s3://efp-raw/statements/northpond/issuance/...), 25,740 rows / 715 loans, MAX_LOADED 2026-08-17. ZERO rows from the /predictions/ path, i.e. the exp slice has still never written a single row. Confirms the asset has never succeeded.
- northpond_api_predictions SUCCEEDS on every run, so the api at_orig slice is current and 713/715 loans in silver.positions have predictions. The 2 without were purchased 2026-04-16. So this is NOT a total predictions outage - it is the exp slice missing plus a permanently red job.
- Note for [[wm-vye9hn]]: silver.ef_scores rows for northpond carry PLATFORM = NULL (200,926 NULL-platform rows, covering all 715 northpond efp_ids). Filtering ef_scores by platform='northpond' returns 0 - do not read that as the scores being absent.
- 2026-08-21T21:48Z [claude-code] CORRECTION 2026-08-22: this item's TITLE cites the wrong Linear ticket. ERROR-1626 is 'statements_northpond failed — Steps failed: [northpond_transfers]' (Low, Done 2026-08-19 13:28) — Abhishek fixed that, and it is unrelated to this defect. The defect described in this body is tracked only by Sentry EFP-ERRORS-1JB; ERROR-1698 (the other candidate, listing northpond_exp_predictions) is also Done as of 2026-08-18. NO open Linear ticket covers it. VERIFIED STILL BROKEN 2026-08-22 against master via the GitHub contents API: orchestration/Dockerfile builder stage copies pyproject.toml, uv.lock, README.md, configs, edgefocus, lib/efp, orchestration — and still does NOT copy .efp_toplevel. The precedent at lib/efp/json_endpoints/platforms/api/northpond/experian/Dockerfile:41-42 does copy it. So the one-line fix is still outstanding.
