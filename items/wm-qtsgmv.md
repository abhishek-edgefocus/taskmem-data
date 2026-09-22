---
id: wm-qtsgmv
type: task
title: Investigate PagerDuty alert fan-out: one failure -> N incidents (Grafana per-app alert keys)
status: next
priority: p2
size: <1 day
tags: [pagerduty, alerting, grafana, oncall]
links: [relates:wm-w98jug]
created: 2026-09-22T17:34:49Z
updated: 2026-09-22T17:34:49Z
source: claude-code
---

## Log
- 2026-09-22T17:34Z [claude-code] Scoped 2026-09-22 from the on-call incident review. Evidence over 699 incidents (679 resolved 09-08..09-22 + 20 open): (1) FAN-OUT — 66 dumbledore datastore incidents collapse to 40 distinct (created_at,payload) groups; 26 are redundant duplicates, 23 of them the exact pair generate_datastores_ubuntu + populate_efp_stats_ubuntu, 3 populate_efp_stats + populate_grafana_tables. (2) BATCH SECONDS — 298 of 699 incidents (43%) share their created_at second with another; worst is 2026-09-21T03:58:31Z with 8 at once = DatastoreStandardizedPositions x 4 partners (marlette/sofi/prosper/anchored) x 2 apps. 2026-09-17T18:26:03Z had 7 Dagster incidents in one second. (3) LOW CARDINALITY — 699 incidents reduce to 197 distinct normalised titles; top repeaters are dev box CPU (32), fleet host CPU (26), SQS oldest message (25). MECHANISM (confirmed from the alert payloads): integration is 'Grafana (Events API v2)' on service efp-coder; alert_key differs between the paired incidents because the Grafana labels carry app=generate_datastores_ubuntu vs app=populate_efp_stats_ubuntu. Same root failure, same datastore, same partner, same second, two alert keys, two incidents. Alerts point at https://grafana.sterling.edgefocuspartners.com/d/efp-cron-script-logs/cron-script-logs (var-host=dumbledore, var-app=<script>).
