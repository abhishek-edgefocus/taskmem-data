---
id: wm-zm8cww
type: task
title: PD #1253 ingest_prediction_files fails every ~30min in prod — root cause not in the run log group
status: open
created: 2026-09-23T19:18:17Z
updated: 2026-09-23T19:18:17Z
source: pd-alert-manager
---

Failing continuously: 12:36, 13:07, 13:36, 14:06, 14:36, 15:06, 15:36, 16:07, 16:36, 17:06, 17:40, 18:09 UTC on 2026-09-23 alone. 'An exception was thrown during execution' — the reason is NOT in /ecs/dagster-prod-run at run level, needs the step logs.

Escalating, not static: PD #1433 (predicted_cashflows_calendar_month_from_purch) and #1438 (predicted_cashflows_mob) are downstream dependency failures inside ingest_prediction_files runs 67a15ccb and a9ec6e91 — same root cause. Fixing this closes 3 open incidents.

Structurally cannot auto-resolve: the Grafana rule needs 6h with no ERROR line and the job fails every 30min, so #1253 has been open 141h.
