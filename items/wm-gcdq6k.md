---
id: wm-gcdq6k
type: task
title: AI billing tracking to Slack (DEV-970)
status: active
priority: p3
size: l
tags: [ai-billing]
links: [parent:wm-r45vp3]
refs: [DEV-970=https://linear.app/edge-focus/issue/DEV-970/add-tracking-of-ai-billing-to-slack, PR-5880=https://github.com/edgefocus/efp/pull/5880, PR-5388=https://github.com/edgefocus/efp/pull/5388]
created: 2026-07-14
updated: 2026-07-27T18:27:15Z
source: dpx-tasks #10
label: AI billing to Slack
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #10
- 2026-07-27T17:51Z [claude-code] DEV-970 is two stacked PRs, both still DRAFT: #5880 (1/2, ramp -> bronze/silver, branch abhishek/dev-970-ramp-ingestion) and #5388 (2/2, AI-txn filter + Slack, based on 5880). Both created/worked in dpx Claude session 42b66000-9312-4005-a844-573968333bb1 (Jul 13-14, repo ~/repos-3/efp on dpx, working tree dirty). Loose end: last thing raised in that session was test failures on #5388, never resolved. Transcript cloned to local ~/.claude/projects/-Users-abhishek/ for resume.
- 2026-07-27T18:02Z [claude-code] PR #5880 checked out in dpx ~/repos-3/efp (was on DEV-1474; that work is pushed to its own branch, nothing lost). Changed DEFAULT_LOOKBACK_DAYS 45 -> 30 in edgefocus/transformations/bronze/ingest_ramp_transactions.py + docstring + 2 test cases; 4 window tests pass. The 45 had no recorded rationale - the design discussion said 30, the implementation commit silently used 45. Change is UNCOMMITTED on dpx. Gap found: ramp.py docstring points at terraform/dagster/ssm_parameters.tf for /dagster/prod/ramp_client_{id,secret}, but the PR never added those tf entries and neither SSM param exists.
- 2026-07-27T18:27Z [claude-code] Live-tested PR #5880 client against real Ramp API (creds exist at dpx ~/.creds.env; SSM params still absent). FOUND BUG: list_transactions sent from_date/to_date as bare YYYY-MM-DD; Ramp 422s with DEVELOPER_7001 'Not a valid datetime'. Every scheduled run would have failed. Fixed: send UTC ISO datetimes (from 00:00:00Z, to 23:59:59Z, window stays inclusive). Also added as_of_date='all' full-history backfill (verified: omitting from_date returns entire history). Live check: single day 2026-07-24 -> 2 txns; full history -> 2698 txns spanning 2023-02-03..2026-07-27. 20 unit tests pass. All changes uncommitted in dpx repos-3. Blockers for the dagster run: (a) the running webserver serves repos-2, not repos-1 as assumed; (b) DEV_ABHISHEK.BRONZE.RAMP_TRANSACTIONS is a stale pre-redesign shape (FETCH_START_DATE/FETCH_END_DATE, 2431 rows, no AS_OF_DATE), silver table + bronze stream missing entirely - PR terraform needs applying in dev.
