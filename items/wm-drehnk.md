---
id: wm-drehnk
type: task
title: Inventory NorthPond monitoring panels; map each query to its Snowflake source
status: done
priority: p1
size: m
scheduled: 2026-07-14
tags: [northpond]
links: [parent:wm-rgwdyu, blocks:wm-pjhqtk]
created: 2026-07-14
updated: 2026-07-20T21:26:55Z
source: dpx-tasks #2
label: NorthPond panels inventory
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #2
- 2026-07-16T19:02Z [claude-code] Completion check (2026-07-17, requested by Abhishek). No log entry ever written on this item, and no standalone panel->source mapping artifact exists. However the mapping work appears to have been DONE as a byproduct of PR #5884 / wm-unb6pr: (a) ~17 IRR/ROI/CDR/CPR panels traced to shared gold.realized_cashflows_calendar_month_daily incl. its grain; (b) 3 panels traced off the deleted NorthPond gold table and rewritten to silver; (c) a panel-by-panel query audit is implied by the dead-code finding ('gold DPD-bucket cols unused, no panel read them'). Gap: ~20 panels accounted for, but total panel count on the Grafana dashboard is UNVERIFIED — cannot confirm full coverage without the dashboard JSON. Status left as 'next' pending Abhishek's call.
- 2026-07-17T09:22Z [claude-code] Panel inventory COMPLETE via Grafana API (creds: ~/.grafana.env on dpx, basic-auth fallback). NorthPond Monitoring — Snowflake Migration (uid 5e958781, personal Abhishek folder, tagged deprecated) = 80 panels, all on Snowflake ds bqzSrsZvz. Panel->source map: SILVER.POSITIONS 28, GOLD.POSITIONS_DAILY 15, SILVER.NORTHPOND_AT_PURCHASE_FEATURES 14, GOLD.REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY 13, GOLD.PREDICTED_CASHFLOWS_CALENDAR_MONTH 3, SILVER.REALIZED_CASHFLOWS_CALENDAR_MONTH 3, SILVER.NORTHPOND_STMT_PAYMENT_CONFIGURATION 3, SILVER.FUND_RETURNS 1, 13 spacer/text. Closes the 'total panel count UNVERIFIED' gap from the 2026-07-16 entry: 80 total, ~20 previously accounted for. PROD readiness: 22 panels work vs PROD today; 31 blocked (PROD gold has ZERO northpond rows); 14 blocked (SILVER.NORTHPOND_AT_PURCHASE_FEATURES absent in PROD, awaits PR #5884). JSON dumps: dpx ~/tmp/dash-analysis/{northpond,fundmon}.json
- 2026-07-17T09:40Z [claude-code] Closing as DONE (2026-07-17): the 2026-07-17 entry completed the 80-panel inventory via Grafana API and explicitly closed the 'total panel count UNVERIFIED' gap that was holding this open. Panel->source map is recorded on this item; no further work. Downstream blockers it surfaced are now tracked as their own items: 31 panels blocked on empty prod gold -> wm-qs96kd; 14 blocked on SILVER.NORTHPOND_AT_PURCHASE_FEATURES absent in PROD -> PR #5884 / wm-rgwdyu.
