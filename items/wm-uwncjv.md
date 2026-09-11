---
id: wm-uwncjv
type: task
title: Add EF Alpha + EFHYF to the Fund Performance Monitoring dashboard (DEV-1715, DEV-1716) — due 2026-09-29
status: next
priority: p2
size: l
due: 2026-09-29
people: [abhijeet]
tags: [northpond, grafana, fund-monitoring, demise-datastores, linear]
refs: [DEV-1715=https://linear.app/edge-focus/issue/DEV-1715/add-ef-alpha-to-fund-performance-monitoring, DEV-1716=https://linear.app/edge-focus/issue/DEV-1716/add-efhyf-to-fund-performance-monitoring, dm=https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1788968937117249]
created: 2026-09-11T14:26:11Z
updated: 2026-09-11T14:26:11Z
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
