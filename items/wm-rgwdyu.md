---
id: wm-rgwdyu
type: task
title: Migrate NorthPond Fund Monitoring page to Snowflake data (DEV-1395)
status: active
priority: p1
size: xl
due: 2026-07-20
tags: [northpond]
links: [parent:wm-j523sq]
refs: [DEV-1395=https://linear.app/edge-focus/issue/DEV-1395/migrate-the-northpond-fund-monitoring-page-to-use-snowflake-data, Grafana=https://grafana.edgefocuspartners.com/d/qQl7m9cHk/northpond-monitoring, PR5884=https://github.com/edgefocus/efp/pull/5884]
created: 2026-07-14
updated: 2026-07-16T12:53:36Z
source: dpx-tasks #1
label: NorthPond monitoring migration
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #1
- 2026-07-16T12:48Z [claude-code] PR #5884 OPEN and in progress (branch abhishek/dev-1395-northpond-at-purchase-features-and-payment, updated 2026-07-16). Shipped the v1/v2 (TU/Experian) filter for the per-loan at-purchase panels + populated silver.positions.MODEL_VERSION for northpond. The ~17 gold cashflow panels (IRR/ROI/CDR/CPR) are NOT covered by it — that is the follow-on wm-unb6pr.
- 2026-07-16T12:53Z [claude-code] CORRECTION to my 12:48Z entry (read from session ec4fd968 transcript, 12:40-12:47): the new NorthPond gold table is ALREADY REMOVED, not pending. Net diff vs master is now ONE new silver table, ZERO new gold: A silver/statement_rows/northpond/at_purchase_features.py (+test +tf), M northpond/positions.py (MODEL_VERSION +tests), M orchestration/assets/northpond_assets.py. at_purchase_features is a silver companion mirroring the existing per-platform *_credit_attributes convention, not a new pattern. ('gh pr diff' file list is misleading — per-commit, added+deleted within the PR; net diff is clean.) Three panels rewritten gold->silver: match the old gold numbers exactly (83.13% ACH on efhyf) and GAINED the v1/v2 filter the aggregate was structurally blocking (v1 0.8306 / v2 0.8463). Removal also surfaced dead code: gold DPD-bucket cols unused (positions_daily already has DPD buckets, no panel read them) and total_principal duplicated positions_daily.TOTAL_PRINCIPAL — only the connection-type split was ever used. 160 tests pass; both assets materialize green through Dagster; committed+pushed, CI queued 12:47.
