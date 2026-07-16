---
id: wm-j523sq
type: project
title: NorthPond Data Ingestion
status: active
tags: [northpond]
refs: [Grafana=https://grafana.edgefocuspartners.com/d/qQl7m9cHk/northpond-monitoring]
created: 2026-07-15T14:44Z
updated: 2026-07-16T11:49:07Z
source: dpx-tasks import
label: NorthPond ingestion project
---

Migrate NorthPond off datastores onto Snowflake (dashboards + silver tables)

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-07-16T11:46Z [claude-code] Datastore-deprecation blocker audit (2026-07-16): live purchase path CLEAN (northpond_loan_fl_channel.py + northpond_model.py read no datastores). Billing (bin/northpond/generate_monthly_fee.py) reads DB('stats-efp','northpond') MySQL, NOT datastores -> not a blocker. NorthPond FL 2.0 dashboard (uid qWXsxeWDk) queries northpond.{issued,model_requests,model_responses,performance} gateway MySQL, NOT datastores -> out of scope. northpond absent from configs/datastore_index.txt and warehouse CL configs. Old 3 dashboards already tagged [DEPRECATED]. REMAINING: (1) '[DEV-1024] NorthPond Monitoring - v2 Exp Filter' (uid d2b042d3-7093-41ed-90de-f245a33bb006) still live on mysql datastore tables (positions_, pred_returns_at_orig_) - DEV-1024 closed as Duplicate, so likely abandoned WIP; delete or migrate. (2) ~30 cross-platform/fund dashboards still read datastore positions_ via mysql without naming northpond; northpond.statement_loan_positions feeds the GLOBAL datastore_standardized_positions (lists.py:225), so northpond rows would silently vanish from fund-level dashboards. (3) Chandra dependency audit (Abhijeet's 2026-06-25 ask) never confirmed, no Linear issue.
