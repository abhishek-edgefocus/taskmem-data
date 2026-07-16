---
id: wm-drehnk
type: task
title: Inventory NorthPond monitoring panels; map each query to its Snowflake source
status: next
priority: p1
size: m
scheduled: 2026-07-14
tags: [northpond]
links: [parent:wm-rgwdyu]
created: 2026-07-14
updated: 2026-07-16T19:02:43Z
source: dpx-tasks #2
label: NorthPond panels inventory
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #2
- 2026-07-16T19:02Z [claude-code] Completion check (2026-07-17, requested by Abhishek). No log entry ever written on this item, and no standalone panel->source mapping artifact exists. However the mapping work appears to have been DONE as a byproduct of PR #5884 / wm-unb6pr: (a) ~17 IRR/ROI/CDR/CPR panels traced to shared gold.realized_cashflows_calendar_month_daily incl. its grain; (b) 3 panels traced off the deleted NorthPond gold table and rewritten to silver; (c) a panel-by-panel query audit is implied by the dead-code finding ('gold DPD-bucket cols unused, no panel read them'). Gap: ~20 panels accounted for, but total panel count on the Grafana dashboard is UNVERIFIED — cannot confirm full coverage without the dashboard JSON. Status left as 'next' pending Abhishek's call.
