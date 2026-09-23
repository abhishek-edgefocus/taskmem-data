---
id: wm-9wf6pu
type: task
title: Grafana table population failures escalating: 1 -> 5 -> 9 tables/night (PD #1396/#1397)
status: next
priority: p2
size: <1 day
tags: [oncall, pagerduty, grafana, datastores]
links: [relates:wm-w98jug]
created: 2026-09-23T10:46:21Z
updated: 2026-09-23T11:13:06Z
source: claude-code
---

## Log
- 2026-09-23T10:46Z [claude-code] From the on-call review 2026-09-23. populate_grafana_tables runs 44 jobs; failures by night from /mnt/full_efs/data/logs/dumbledore/populate_efp_stats_ubuntu.log: 09-18=1, 09-19=1, 09-20=1, 09-21=5, 09-22=9. Last night's nine: pred_mob_curves_curr_mod_from_purch, pred_returns_at_orig, delta_statuses, pred_mob_curves_best_est_from_purch, pred_mob_curves_from_purch, late_principal, pred_mob_curves_best_est, mob_curves_from_purch, positions. NOT downstream of the spot/datastore failures — 09-18 had zero datastore failures and still lost a table. The wrapper exits 0 regardless, so nothing downstream notices. Per-job failure reason is NOT in the wrapper log; durations vary 78s-2472s and one is nan. Entry points: lib/efp/stats/grafana_tables/base_grafana_tables.py (~line 404 logs 'Failed job', ~251 raises) and bin/stats/populate_grafana_tables.py.
- 2026-09-23T11:13Z [claude-code] Root-caused 2026-09-23. TWO independent causes, not one.

(1) CHRONIC (the nightly 1): delta_statuses. Real per-job errors live in /mnt/full_efs/data/logs/dumbledore/populate_grafana_tables_ubuntu.log (NOT the populate_efp_stats wrapper log) and in the AWS Batch job's CloudWatch stream (/aws/batch/job, job-definition/default/<id>). delta_statuses fails with 'Essential container in task exited' exit 1 -> AssertionError: Length of dataframe 315655 > 300000, raised at lib/efp/sqlalchemy.py:268 against max_rows=300000 set at grafana_tables_datastores.py:158. Band is delta_statuses_int_rate_band. Growing: 307251 (09-14) -> 307431 -> 315631 -> 315655 (09-21). Unbroken 21/21 runs since 2026-09-03T02:17 PDT; 09-01 runs were clean. Never self-heals.

(2) LAST NIGHT'S OTHER 8: all AWS Batch statusReason 'Host EC2 (instance i-...) terminated.' = spot reclamation on HIGH_URGENCY_QUEUE (SPOT, bidPercentage 55, m7a/m7i/r7a/r7i). Every job requests 118656 MiB / 4 vCPU (base_grafana_tables._initialize_batch_group hardcodes 120 GB 4 CPU) x 44 jobs. Batch-level retryStrategy attempts=2 already ran and BOTH attempts were reclaimed. One instance (i-0f9db4e5440e42a7d) took out 3 jobs at once. On 09-22 delta_statuses was ALSO host-terminated, so its usual assertion was masked that night.

WHY NO RECOVERY: base_grafana_tables._wait_jobs_completion (line ~243) iterates BatchGroup.as_completed() and raises at line 251. The datastore path uses BatchGroup.wait_and_retry_failures (batch.py:1893, max_tries=3) instead, and batch.py:44 RETRY_STATUS_PATTERNS ALREADY contains 'Host\sEC2\s\(instance\s(i-.*)\)\sterminated\.'. The grafana-tables path simply never opted into the retry helper. That asymmetry is the bug.

ESCALATION 1->5->9 is NOT one cause spreading and the sets are NOT nested: 09-21 {delta_statuses,pred_mob_curves_best_est,positions,pred_mob_curves_at_orig,pred_mob_curves_curr_mod_at_orig} vs 09-22 -- only 3 overlap, and pred_mob_curves_at_orig/curr_mod_at_orig SUCCEEDED on 09-22. Sum of job-seconds per run is flat (~4-5 job-hours), so exposure is not growing. The three worst runs in Sept (09-10=9, 09-21b=5, 09-22=9) all started 16:36-19:25 UTC (09:36-12:25 PDT) because generate_datastores overran (13.6h on 09-22, 16.4h on 09-10, vs 2-3h normal), pushing populate_grafana_tables into US business hours. Contributing, not deterministic (09-15 runs failed 2-3 overnight). Verdict: spot reclamation is stochastic and bursty; the count is a random draw, and the absence of retry converts every draw into a permanently missing table.

EXIT CODE: populate_efp_stats.sh is NOT at fault -- it is an && chain and propagates $? correctly. The exit-0 comes from bin/stats/populate_grafana_tables.py: the per-source try/except catches the summary Exception, calls error_framework.post_error, and falls through to process exit 0. Consequence is worse than 'nothing downstream notices': the wrapper then logs 'populate_grafana_tables OK' and runs 'python3 bin/monitoring/checkin.py --update populate_grafana_tables', recording a HEALTHY heartbeat on a night tables went missing.

IMPACT (verified via legacy Grafana /api/ds/query, datasource StatsEFP uid LR_rCfanz): positions and late_principal are NOT stale -- both max as_of_date 2026-09-21 with 13 distinct dates in the last 14 days, identical to tables that succeeded (returns, late_markdowns). Dismissed. delta_statuses also fine: all 40 bands have identical coverage (3346 distinct dates, 2017-06-09..2026-09-21) -- no data loss despite 21 failed runs, even though _delete_dates runs a DELETE before the failing insert (worth confirming whether SQLAlchemy con.execute is committing). SEPARATE PRE-EXISTING PROBLEM: pred_mob_curves_best_est / _best_est_from_purch / _curr_mod_from_purch / _curr_mod_at_orig have ZERO as_of_dates in the last 14 days and top out at 2026-05-19/05-26 (~4 months). pred_mob_curves_curr_mod_at_orig SUCCEEDED on 09-22 (1880s, 69GB) and is still at 2026-05-19, and these are repopulate:True (full TRUNCATE+rewrite), so the upstream derived datastores genuinely stop in May. NOT caused by these failures.

DASHBOARDS (panel-level scan of all 172 legacy dashboards, filtered to StatsEFP datasource): positions 8 (3 non-testing incl. Company: Edge Focus / Dashboard, Dashboard: Secondary Trades), pred_returns_at_orig 9, mob_curves_from_purch 7, pred_mob_curves_from_purch 5, late_principal 3, delta_statuses 2, pred_mob_curves_best_est 2, pred_mob_curves_best_est_from_purch 0, pred_mob_curves_curr_mod_from_purch 0. Nothing is currently serving missing data from last night's failures.
