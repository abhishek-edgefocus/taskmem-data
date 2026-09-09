---
id: wm-e4nxre
type: followup
title: Reply to Sean: legacy MOB-curves dashboard undercounts Oliv (MySQL/datastore-backed, 372 loans vs ~8.9k on Nelnet tape)
status: done
priority: p1
size: s
due: 2026-09-02
people: [sean-edgefocus]
tags: [northpond, oliv, datastores, needs-reply, grafana]
links: [related:wm-tvjjgw]
created: 2026-09-01T17:37:13Z
updated: 2026-09-09T13:13:04Z
source: claude-code
label: Sean MOB curves Oliv
---

Sean Mills asked in #data-discussion 2026-09-01 22:43 IST (permalink
https://edgefocuspartners.slack.com/archives/C03JR4V1448/p1788282817031149):
he was looking at CDR / N-loans / Dollars for Oliv on the **legacy MOB Curves
dashboard** (`/d/QgyVqSQSz/dashboard3a-mob-curves`, `var-platform=northpond`,
realized only) and the loan count and dollars are far smaller than expected
"given we should have a view of every Oliv/NorthPond loan ever originated".
He explicitly notes he knows datastore deprecation and the Snowflake dashboard
duplication are in flight, but "wasn't sure where the Oliv data ingestion stood /
expectations on correctness". So the ask is really: *what should he trust today,
and by when is it right?*

## What I verified 2026-09-01 (Grafana `/api/ds/query`, so this is what the panel
## itself sees, not a Snowflake query that would prove nothing about the panel)
- The dashboard is **MySQL-backed, not Snowflake**: both panels he linked target
  datasource `{"type":"mysql","uid":"LR_rCfanz"}` — panel-61 (CDR) reads
  `mob_curves_$band_name`, panel-66 (Basic Metrics: Count / Dollars / WAC / WAPX)
  reads `point_metrics_$band_name`. This is the legacy datastore-derived MySQL,
  i.e. exactly the path being deprecated. Nakula is porting this dashboard to
  Snowflake (his 2026-08-24 message in the same channel).
- `point_metrics_none` for `platform='northpond'`: latest `as_of_date` is
  **2026-08-19** (build_timestamp 2026-08-20), max `real_count` **372 loans /
  $1.33M real_dollars** (All Mob Curves, channel `northpond_loan_fl`).
- Staleness is not northpond-specific — max as_of by platform runs 2026-08-11
  (marlette) to 2026-08-19 (northpond); `figure` is frozen at 2024-12.

## The explanation (already documented, see [[wm-tvjjgw]])
372 loans is the legacy FCC-tape population, not the book. Measured in prod
2026-08-24: `PROD.SILVER.NORTHPOND_STMT_POSITIONS` (legacy FCC) has 715 distinct
loans topping out at OLV12563276, while `NORTHPOND_STMT_NELNET_POSITIONS` has
8,891 rows — and all 265 EDGEX 2026-1NN loans purchased 08-11..08-21 are on the
Nelnet tape and **none** on the FCC tape. The legacy purchase tape has also been
frozen at data date 2025-06-16 since Oliv moved to CSV. So the legacy chain feeding
this MySQL is starving exactly as [[wm-tvjjgw]] predicted, silently: the numbers
look alive because the FCC tape still updates daily, but the new book is not in it.

## What the reply needs to say
1. The undercount is real and expected on this dashboard — it is datastore/MySQL
   backed and the legacy NorthPond feed no longer receives the new Oliv loans.
2. Point him at the Snowflake-backed view for correct Oliv numbers (confirm which
   one is the right target today — `vip-mob-curves-snowflake` covers the EDGEX
   funds; Nakula's port of dashboard3a is the general answer).
3. Give a date: either (a) point legacy StatementPurchaseTape at the new CSV, or
   (b) land Nakula's Snowflake port and retire this one. Do not promise (a)
   without deciding it — that decision is the open question on [[wm-tvjjgw]].
4. Before quoting him a "correct" number, run the Snowflake count for
   northpond/Oliv originated-to-date so the reply carries a figure, not a shrug.

## Log
- 2026-09-01T17:37Z [claude-code] Created from reading #data-discussion 2026-09-01. Sean's message is unanswered; panel datasource + point_metrics_none numbers verified same day via Grafana /api/ds/query (basic auth on dpx), not from a Snowflake query.
