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
updated: 2026-09-23T10:46:21Z
source: claude-code
---

## Log
- 2026-09-23T10:46Z [claude-code] From the on-call review 2026-09-23. populate_grafana_tables runs 44 jobs; failures by night from /mnt/full_efs/data/logs/dumbledore/populate_efp_stats_ubuntu.log: 09-18=1, 09-19=1, 09-20=1, 09-21=5, 09-22=9. Last night's nine: pred_mob_curves_curr_mod_from_purch, pred_returns_at_orig, delta_statuses, pred_mob_curves_best_est_from_purch, pred_mob_curves_from_purch, late_principal, pred_mob_curves_best_est, mob_curves_from_purch, positions. NOT downstream of the spot/datastore failures — 09-18 had zero datastore failures and still lost a table. The wrapper exits 0 regardless, so nothing downstream notices. Per-job failure reason is NOT in the wrapper log; durations vary 78s-2472s and one is nan. Entry points: lib/efp/stats/grafana_tables/base_grafana_tables.py (~line 404 logs 'Failed job', ~251 raises) and bin/stats/populate_grafana_tables.py.
