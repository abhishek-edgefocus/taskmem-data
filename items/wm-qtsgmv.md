---
id: wm-qtsgmv
type: task
title: Investigate PagerDuty alert fan-out: one failure -> N incidents (Grafana per-app alert keys)
status: done
priority: p2
size: <1 day
tags: [pagerduty, alerting, grafana, oncall]
links: [relates:wm-w98jug]
created: 2026-09-22T17:34:49Z
updated: 2026-09-22T18:05:52Z
source: claude-code
---

## Log
- 2026-09-22T17:34Z [claude-code] Scoped 2026-09-22 from the on-call incident review. Evidence over 699 incidents (679 resolved 09-08..09-22 + 20 open): (1) FAN-OUT — 66 dumbledore datastore incidents collapse to 40 distinct (created_at,payload) groups; 26 are redundant duplicates, 23 of them the exact pair generate_datastores_ubuntu + populate_efp_stats_ubuntu, 3 populate_efp_stats + populate_grafana_tables. (2) BATCH SECONDS — 298 of 699 incidents (43%) share their created_at second with another; worst is 2026-09-21T03:58:31Z with 8 at once = DatastoreStandardizedPositions x 4 partners (marlette/sofi/prosper/anchored) x 2 apps. 2026-09-17T18:26:03Z had 7 Dagster incidents in one second. (3) LOW CARDINALITY — 699 incidents reduce to 197 distinct normalised titles; top repeaters are dev box CPU (32), fleet host CPU (26), SQS oldest message (25). MECHANISM (confirmed from the alert payloads): integration is 'Grafana (Events API v2)' on service efp-coder; alert_key differs between the paired incidents because the Grafana labels carry app=generate_datastores_ubuntu vs app=populate_efp_stats_ubuntu. Same root failure, same datastore, same partner, same second, two alert keys, two incidents. Alerts point at https://grafana.sterling.edgefocuspartners.com/d/efp-cron-script-logs/cron-script-logs (var-host=dumbledore, var-app=<script>).
- 2026-09-22T17:37Z [claude-code] Alert-body comparison of the 4 open pairs: the error string is byte-identical across both scripts — populate_efp_stats_ubuntu reports '[DatastoreStandardizedPositions] [marlette] Failed to generate datastore', the same 'Failed to generate datastore' wording emitted by generate_datastores_ubuntu, for the same partner in the same second. Both summaries read '1 ERROR line(s) in the last 30m' from the same Grafana log-scrape rule, differing only in host/app prefix. Strong prior for investigation Q1: this is one failure in a shared datastore-generation code path that both cron scripts call, not two independent failures — so collapsing at the alert layer probably does NOT hide a second real problem. Confirm by reading both scripts on dumbledore before recommending. Exception: the credible-sandbox pair Q017CMM9KDQYYO / Q0JH1VAMDQFN2D is NOT a clean duplicate — same app and host 2 min apart, but the first alert carries no error string and the second says 'Error Contacting Limits Server'. Pre-merge snapshots: ~/pagerduty-snapshots/incidents-2026-09-22.json and open-incident-alerts-2026-09-22.json.
- 2026-09-22T17:56Z [claude-code] Investigation complete (read-only). Full write-up: ~/notes/areas/observability/pagerduty-incident-fan-out.md (new area, meta.md stamped in same edit). Working files dp:~/claude-ws/pd-dedup/ + session scratchpad (pull2.py, sim.py).

SAMPLE RECONCILED: the 699 spans ALL FOUR PD services, not just efp-coder — efp-coder 565, efp-devops 103, efp-devbox 32, efp-partner-critical 0 = 700 (2026-09-08..09-23).

FOUR DISTINCT MECHANISMS, not one bug:
(1) WRAPPER DOUBLE-LOGGING — 60 redundant. NOT two failures and NOT a downstream consumer. generate_datastores is not scheduled at all; the only cron entry (existing.cron:251) runs populate_efp_stats.sh with `>> populate_efp_stats_ubuntu.log 2>&1`, and that wrapper runs generate_datastores.py / populate_grafana_tables.py as children. Each child's custom_logging attaches BOTH a syslog handler (-> <app>_ubuntu.log) AND a stream handler (-> stdout -> the wrapper's redirect). One logging.error() lands in two shipped files under two app labels. PROVEN: same line 19us apart, generate_datastores_ubuntu.log 2026-09-20T20:52:48.318836-07:00 vs populate_efp_stats_ubuntu.log 2026-09-21T03:52:48.318817+00:00.
(2) SHARED ROOT CAUSE, TWO INDEPENDENT SCRIPTS — 7 redundant (reconcile_sofi_loan_td + reconcile_upgrade_loan_secondary on "Can't match all the owned positions and xref table", x6).
(3) SCRAPE-GAP FLAPPING — SQS 26 incidents are ALL ONE queue (STAGING-gateway-ingest-dlq, 169h->186h). alert-rules-aws-services.yaml uses noDataState: OK with NO missing-series hold; app-error-logged has missing_series_evals_to_resolve: 1800, the 7 AWS rules have nothing.
(4) CROSS-SERVICE DUPLICATION — 22 of 32 "Dev box CPU saturated" (efp-devbox) overlap a "Fleet host CPU high" (efp-devops) for dexterplus. Two rules, one condition, two PD services. No PD Alert Grouping can fix this (grouping is per-service).

CORRECTION TO THE FRAMING: the "43% share a created_at second" stat is NOT duplication evidence — it is a Grafana evaluation-sweep artifact. The four partners in the 03:58:31Z cluster were logged at 03:52:45/:46/:47/:48 (four different seconds); all 8 incidents were created at one identical second 5m43s later (for:5m + 60s interval). 247 of the 298 are within a single rule's sweep.

Q2 — RULE: app-error-logged in edgefocus/efp-k8s-gitops @ apps/sterling/grafana-alerting/alert-rules-app-errors.yaml (GitOps; NOT in efp or efp-infrastructure). group_by: [alertname, app, subject, environment, ec2_tag_Name]. `app` is NOT load-bearing for routing (policy tree matches only team/severity/service; rule pins receiver: pagerduty-coder-low). It IS load-bearing as the query filter `app != ""` (excludes journald). In group_by it is purely the fan-out cause. Reaches PD only via presentation templates efp.pd.group / efp.pd.summary. NOTE: this exact bug class was fixed here once before — the file records collapsing app-error-posted into one rule (31 Aug) because DOPS-684/686 made one failure produce two alerts.

Q4 — PD ALERT GROUPING IS OFF EVERYWHERE: alert_grouping_parameters null AND auto_resolve_timeout null on all four services; GET /event_orchestrations returns none. All grouping in force today is Grafana's group_by.

QUANTIFIED (replay of PD dedup-while-open; BASELINE REPRODUCES 699 EXACTLY):
  (a) drop `app` from group_by     -> 565  (-134)  [all 67 same-second pairs + 63 cross-time threads]
  (c) fix fan-out at source        -> 639  (-60)
  (a)+(c)                          -> 567  (worse than (a) alone)
  (b) PD time-based 5m/30m/60m     -> 165/126/110
  (b') PD content-based 5m         -> 431
  8-at-once cluster: (a) -> 4, (c) -> 4, (b) -> 1
  SQS with 1h missing-series hold  -> 2  (-24)

RECOMMENDATION: (a) drop `app` from group_by + add missing_series_evals_to_resolve to the 7 AWS rules. 699 -> 541 (-158, 23%), no coverage loss. REJECT (b) PD Alert Grouping: blunt (merges unrelated alerts, destroying the is-this-new signal DOPS-799 was built for), console-only with no review trail, and cannot fix the cross-service dexterplus case. REJECT (c) as primary: strictly weaker, cannot touch the reconcile pair, and every safe variant costs coverage — excluding the wrapper log blinds us to checkin.py and max_as_of_date_by_platform.py, which have NO syslog logger and whose only shipped path is that wrapper log. Also populate_efp_stats.sh/custom_logging.py are shared EFP files.
COST OF (a), stated: merged groups have empty CommonLabels.app, so the PD title drops the "- <app>" segment and efp.pd.group falls back to ec2_tag_Name. Script still in custom_details/logs_url; app stays in sum by.

DRAFTED NOT APPLIED: both diffs are in the notes file. Need validating against the provisioning API before merge (file header warns an unknown enum fails the whole alerting reload; Grafana 12.3.1).

FOLLOW-UPS RAISED: (i) exclude dexterplus from Fleet host CPU high (29 dup incidents); (ii) STAGING-gateway-ingest-dlq stuck 186h, alert fix only hides it; (iii) under (a) the reconcile pair becomes one incident — behaviour change, on-call should sign off; (iv) ACCESS GAP: dp:~/.grafana.env creds are for the LEGACY grafana.edgefocuspartners.com (zero alert rules) and are rejected by sterling — no way to read sterling's live alert state; (v) pagerduty MCP server was down all session (502 Bad Gateway), used the REST key instead.
- 2026-09-22T18:05Z [claude-code] LIVE CONFIRMATION of the treadmill, 29 minutes after the merges: PD #1396 (populate_efp_stats_ubuntu) and #1397 (populate_grafana_tables_ubuntu), both created 2026-09-22T17:36:30Z, byte-identical error 'Failed to populate grafana tables for datastores', distinct alert keys 973de5ec / 4e2886a3. This is the second pair variant from the history (populate_efp_stats + populate_grafana_tables, 3x in 15d). NARROWING LEAD: populate_efp_stats_ubuntu is the common member of BOTH pair variants — 23 pairs with generate_datastores_ubuntu emitting 'Failed to generate datastore', and 3+1 pairs with populate_grafana_tables_ubuntu emitting 'Failed to populate grafana tables for datastores'. In each case it re-emits the other script's error verbatim. Strong hypothesis: populate_efp_stats_ubuntu is a wrapper/orchestrator that calls the other scripts' code paths and re-logs their failures, so the Grafana log-scrape rule sees the same ERROR line under two app labels. Read that script FIRST on dumbledore — it likely explains the whole fan-out.
