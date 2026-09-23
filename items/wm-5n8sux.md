---
id: wm-5n8sux
type: task
title: dumbledore app-error PagerDuty alerts stopped auto-resolving after 2026-09-22
status: open
created: 2026-09-23T19:18:17Z
updated: 2026-09-23T19:18:17Z
source: pd-alert-manager
---

Measured across 1105 incidents 09-05..09-25. Every dumbledore 'Application error' signature historically resolved at a uniform 12.4h (4 reconcile jobs, generate_datastores, populate_grafana_tables). Since 09-22 not one has: #1370 38.7h, #1390 26.1h, #1397 25.2h, #1401 23.7h, #1403/#1404 23.5h, #1419 14.2h vs a 3.1h history — all past their full historical max. Sandbox endpoints ride the same app-error-logged rule and were equally stuck.

By contrast the Dagster 'error logged' family (6h resolve_by_absence window) still works fine — #1427 #1429 #1430 #1432 #1434 #1435 all resolving normally. So this is specific to the app-error rule, not to PagerDuty.

LEAD: session 2107f70c noted a PR (referred to as #123) replaced 'the 12h setting' around 09-21, which matches the 12.4h median exactly. Check that PR first. Impact: every dumbledore alert needs a manual click until this is fixed.
