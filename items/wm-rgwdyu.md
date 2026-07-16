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
updated: 2026-07-16T12:48:49Z
source: dpx-tasks #1
label: NorthPond monitoring migration
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #1
- 2026-07-16T12:48Z [claude-code] PR #5884 OPEN and in progress (branch abhishek/dev-1395-northpond-at-purchase-features-and-payment, updated 2026-07-16). Shipped the v1/v2 (TU/Experian) filter for the per-loan at-purchase panels + populated silver.positions.MODEL_VERSION for northpond. The ~17 gold cashflow panels (IRR/ROI/CDR/CPR) are NOT covered by it — that is the follow-on wm-unb6pr.
