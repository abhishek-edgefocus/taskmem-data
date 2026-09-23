---
id: wm-xppktf
type: task
title: Resolve PD #1253 ingest_prediction_files — acked 4.8d ago, zero recurrence in 15d
status: next
priority: p1
size: xs
due: 2026-09-23
tags: [oncall, pagerduty]
links: [relates:wm-w98jug]
created: 2026-09-22T17:26:27Z
updated: 2026-09-23T17:26:53Z
source: claude-code
---

## Log
- 2026-09-22T17:26Z [claude-code] PD #1253, [PRODUCTION] Dagster error - ingest_prediction_files, created 2026-09-17T21:26Z, acked by Nakula, still open 115.8h later. Zero other ingest_prediction_files incidents in the 679 resolved 09-08..09-22 — single occurrence, never repeated. Best transient candidate in the open set. https://edgefocuspartners.pagerduty.com/incidents/Q0PFTLF52RE2TC
- 2026-09-23T17:26Z [pd-alert-manager] CORRECTION 2026-09-23: this item says PD #1253 ingest_prediction_files was 'acked 4.8d ago, zero recurrence in 15d' and should be resolved. That is wrong and I repeated it twice on the board today. CloudWatch /ecs/dagster-prod-run shows ingest_prediction_files hitting RUN_FAILURE every ~30 minutes continuously: 12:36, 13:07, 13:36, 14:06, 14:36, 15:06, 15:36, 16:07, 16:36, 17:06 UTC on 2026-09-23 alone. 'An exception was thrown during execution' - root cause is not in the run log group, needs the step logs. The reason no NEW PagerDuty incident appeared is that the Grafana dedup_key is unchanged, so every firing dedupes into the still-open #1253. LESSON: an old acknowledged PD incident with no new siblings is NOT evidence of recovery - it can mean the alert has been firing continuously the whole time and the dedup key is holding it in one incident. Always verify recurrence at the source, never from PD incident age. Do NOT resolve #1253; it is an active prod failure.
