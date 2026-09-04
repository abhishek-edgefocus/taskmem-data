---
id: wm-p2qzxg
type: next
title: Prod Dagster deploys blocked: PR #6646 asset-job names collide with their asset names
status: next
priority: high
tags: [efp, dagster, northpond, blocker]
links: [blocks:wm-ytaxsk]
created: 2026-09-04T19:38:14Z
updated: 2026-09-04T20:02:17Z
source: claude-code
estimate: <1h
---

Prod `Deploy Dagster (prod)` run 33909755520 (sha `6854e0d15`, PR #6645 northpond
transfers fix) failed. The image built fine; `deploy/deploy` died on the ECS
`ServicesStable` waiter after 10 min.

Cause is NOT #6645. `dagster-prod-code-server` TD 317 crash-loops at gRPC start:

    DagsterInvalidDefinitionError: Conflicting definitions found in repository
    with name 'positions_transfer_data_quality'. Op/Graph definition names must
    be unique within a repository. GraphDefinition is defined in job
    '__ASSET_JOB' and in job 'positions_transfer_data_quality'.

Bisected by loading `orchestration.definitions` directly:
- `52edcf0a9` — LOADED OK
- `42c6e633a` (PR #6646, DEV-1749, scott-edgefocus, merged 2026-09-04T12:35Z) — FAILS
- `d2921909c` (commit before #6645) — FAILS, so #6645 is exonerated

`define_asset_job(name=X)` where X is also the selected asset's name makes a
GraphDefinition colliding with the asset's op inside `__ASSET_JOB`. Both
`positions_transfer_data_quality` and `transactions_transfer_data_quality` have
this shape. Every other asset job in orchestration/jobs/ uses a distinct name.

Verified fix (2 lines, orchestration/jobs/transfer_data_quality.py): rename the
Dagster `name=` strings to `*_job`. Sensors import the job OBJECTS, not name
strings, so nothing else changes. Definitions then load OK.

CI missed it because no test constructs the real repository — the sensor tests
build small ad-hoc `dg.Definitions(...)`. Worth adding a definitions-load test.

Blast radius: prod code-server still serves TD 316 (`prod-1fe25a23dd`), so prod
Dagster is healthy but frozen at 2026-09-04 12:19Z. All 17 commits merged since
are undeployed. ECS retries ~every 80s and will churn until master is fixed or
the service is pinned back to :316.

Blocks: the northpond_transfers 09-01 replay for the 17 EDGEX loans (wm-ytaxsk).

## Log
- 2026-09-04T20:02Z [claude-code] Opened PR #6673 (branch abhishek/fix-6646-jobname-collision, commit 99c7258dc): 2-line rename to *_job plus orchestration/tests/definitions_test.py which constructs the real repository. Verified the test fails on the unfixed tree with the exact prod error and passes with the rename in 11s; Scott's sensor tests still pass; ruff clean. Not yet reviewed - Scott not pinged yet, Slack draft ready. https://github.com/edgefocus/efp/pull/6673
