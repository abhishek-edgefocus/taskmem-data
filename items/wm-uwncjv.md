---
id: wm-uwncjv
type: task
title: Add EF Alpha + EFHYF to the Fund Performance Monitoring dashboard (DEV-1715, DEV-1716) — due 2026-09-29
status: active
priority: p2
size: l
due: 2026-09-29
people: [abhijeet]
tags: [northpond, grafana, fund-monitoring, demise-datastores, linear]
links: [related:wm-hz3hm9, parent:wm-j523sq]
refs: [DEV-1715=https://linear.app/edge-focus/issue/DEV-1715/add-ef-alpha-to-fund-performance-monitoring, DEV-1716=https://linear.app/edge-focus/issue/DEV-1716/add-efhyf-to-fund-performance-monitoring, dm=https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1788968937117249]
created: 2026-09-11T14:26:11Z
updated: 2026-09-15T14:24:48Z
source: slack DM D0B2A3WSJ5N + Linear
label: EF Alpha EFHYF fund monitoring
---

Two Linear tickets Abhijeet filed 2026-09-01 under the "Demise datastores" project, milestone "Port old dashboards to snowflake": add the EF Alpha fund and the EFHYF fund to the Fund Performance Monitoring dashboard and validate what each shows. Both are marked "a blocker for demising datastores" and both block DEV-1031 (Ingestion of roll rates into edgefocus/). Branch names Linear reserved: abhishek/dev-1715-… and abhishek/dev-1716-….

Deadline was negotiated in the Abhijeet DM on 2026-09-09 (in Marathi): Abhijeet proposed 25 Sept; Abhishek said he is likely on leave on the 25th (maybe before too) and asked for Tuesday the 29th; Abhijeet set both tickets to 2026-09-29 and added "don't start at the very end, this is not work that finishes in a day or two". Abhishek: "yes, will mostly start from Monday" — i.e. 2026-09-14. So the start date is itself a commitment (see the linked reminder).

Prior art worth reusing: the NorthPond Fund Monitoring migration (wm-rgwdyu, DEV-1395) already ported NorthPond panels to Snowflake and matched the old gold numbers for efhyf; wm-hz3hm9 records that efhyf (Evergreen) has no FUND_KEY in the FPM JV-keyed fund-returns query, which will bite here.

## Next steps
1. Open DEV-1715 and DEV-1716 and read the description + milestone; move both to In Progress on 2026-09-14.
2. Open the Fund Performance Monitoring dashboard (folder dfomia5rnkvlsd, uid ffdec6db) and list how a fund gets added (fund variable, FUND_NAME_TO_KEY, silver.fund_returns sheet) — check wm-hz3hm9 first for the efhyf FUND_KEY gap.
3. Add EFHYF first (NorthPond, data already validated in wm-rgwdyu), then EF Alpha; validate each fund's panels against the legacy datastore dashboard numbers.
4. Verify panels through /api/ds/query as GRAFANA_READER, not by running the SQL yourself.

## Links
- DEV-1715 https://linear.app/edge-focus/issue/DEV-1715/add-ef-alpha-to-fund-performance-monitoring
- DEV-1716 https://linear.app/edge-focus/issue/DEV-1716/add-efhyf-to-fund-performance-monitoring
- Deadline negotiation (Abhijeet DM) https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1788968937117249
- Related: wm-rgwdyu (NorthPond FPM migration, done), wm-hz3hm9 (efhyf FUND_KEY gap), wm-j523sq (NorthPond Data Ingestion project)

## Log
- 2026-09-11T14:26Z [claude-code] Captured in the 2026-09-11 sync from the Abhijeet DM of 2026-09-09 21:18-22:21 IST ('Hya donhi la due date takaychi ahe' → 29th set) and Linear (both tickets dueDate 2026-09-29, assigned to Abhishek, project Demise datastores, blocking DEV-1031).
- 2026-09-15T14:24Z [claude-code] 2026-09-15 started DEV-1716 (EFHYF first). Prod FPM is uid b7c89f53-932d-4495-b8d9-04a289fff3eb (folder Fund Monitoring dfomia5rnkvlsd, v17, last edit kushagra 2026-09-04) — the ffdec6db uid in earlier notes is stale. Verbatim copy created at https://grafana.edgefocuspartners.com/d/dev1716-fpm-efhyf in Testing Dashboards/Devs/Abhishek (ffmmyvk05io74f); prod untouched (still v17). Copy v2: added 'EFHYF : efhyf' to the fund custom variable (castlelake_auto precedent). Findings: efhyf is a FUND value in every fund-keyed table (SILVER.POSITIONS 2.1B rows across 9 platforms, lc = 1.99B — perf risk on the 55 SILVER.POSITIONS panels); no warehouse for efhyf → ~31 warehouse/PA panels structurally empty (same as castlelake); FUND_RETURNS FUND_KEY still NULL for EFHYF (castlelake_auto DID get FUND_KEY='castlelake_auto' as 'Joint Venture'). Snapshot ~/fpm_prod_snapshot.json + panel run results ~/dev1716_efhyf_panel_results.json on dpx.
