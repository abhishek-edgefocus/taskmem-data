---
id: wm-xc58u6
type: correction
title: Verified a dashboard's data source but never its render path, and told Abhishek twice it was fixed
status: inbox
tags: [taskmem-bug, correction]
created: 2026-08-24T14:13:44Z
updated: 2026-08-24T14:13:44Z
source: claude-code
label: Verified a dashboard's data source
---

2026-08-24. Twice today I announced the OpenRoad comparison dashboard was working
("Six months: live now", then "One year is in") and handed over a var-database=DEV_ABHISHEK link.
Every panel on that link errors. Abhishek had to tell me — "when I load the abhishek one it just
shows no data on all the panels... I think you are not doing the due diligence."

WHAT I ACTUALLY VERIFIED: that DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY held 174 then 358
continuous rows with COMMON_COUNT=35. All true, and all irrelevant to the question asked.

WHAT I NEVER VERIFIED: that Grafana could read the table. It cannot. The datasource connects as
GRAFANA_USER (keyPair, database=PROD) and returns "Object 'DEV_ABHISHEK...' does not exist or not
authorized" for every query. One POST to /api/ds/query would have caught it in seconds, and I ran
that call only after being challenged.

THE LESSON, stated as a rule: when the deliverable is something a human LOOKS AT, verifying the
data behind it is not verification. Exercise the same path the viewer will — query the dashboard
API, fetch the page, run the report — before saying it works. "The rows are in the table" and "the
dashboard shows the rows" are different claims, and I asserted the second having tested only the
first. The same applies to a file being on disk vs the app loading it, a row being written vs the
API returning it.

SECOND-ORDER COST: on the strength of that wrong belief I recommended filling DEV_ABHISHEK with the
full 1,120-date history and started a ~2.5-hour job producing data no dashboard can ever display.
Killed it once the render path was tested. A permissions check first would have saved the compute
and, more importantly, would have pointed at the real fix (PROD-only) an hour earlier.

Related: [[wm-2994t7]] (the dashboard's own defects), [[wm-vzrdrm]] (the PROD backfill this now
makes unavoidable).


## Environment
- taskmem: e42bc5b
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-24T14:13:44Z
