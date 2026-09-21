---
id: wm-ugetkj
type: bug
title: PROD FPM sources broken 2026-09-21: GOLD.PREDICTED_CASHFLOWS_CALENDAR_MONTH_FROM_PURCH is 0 rows; SILVER.POSITIONS lost every marlette row (fortress_marlette_hyp 40.7M + hyp_2 8.3M gone)
status: inbox
priority: p1
tags: [grafana, fund-monitoring, prod-incident, marlette]
links: [relates:wm-uwncjv]
created: 2026-09-21T12:09:08Z
updated: 2026-09-21T12:44:45Z
source: claude-code
label: PROD FPM sources broken 2026-09-21
---

Found 2026-09-21 while re-running DEV-1716 panel validation through /api/ds/query (GRAFANA_READER). Both tables were healthy on 2026-09-15 (predicted table had rows for all 24 funds; SILVER.POSITIONS had 40,664,834 fortress_marlette_hyp rows and 8,259,332 hyp_2 rows, plus efhyf/marlette 418 loans/day). Now: predicted table COUNT(*)=0 for every fund -> the 28 predicted-cashflow panels on the live Fund Performance Monitoring dashboard (b7c89f53) are blank for EVERY fund; SILVER.POSITIONS has only 216 to_be_purchased_edgex20261NN marlette rows -> Best Egg 1 / Best Egg 2 pages are blank on all 55 current-book panels and efhyf/paradigm1 lose their marlette platform. Other FPM sources look intact (REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY 6239 rows to 09-20, GOLD.POSITIONS_DAILY 45297 to 09-20 incl. marlette to 09-18; sofi/happymoney/prosper/castlelake/efalpha/efhyf silver counts grew normally). Linear MCP needed re-auth so could not check for an existing ticket; Slack search for 'marlette' after 09-14 only surfaced bot alerts. NOT posted anywhere — Abhishek to raise.

## Environment
- taskmem: c883278
- reported by: claude-code
- host: ip-192-168-1-3.ap-south-1.compute.internal
- when: 2026-09-21T12:09:08Z

## Log
- 2026-09-21T12:44Z [claude-code-critic] 2026-09-21 Abhishek's call: out of scope for DEV-1716 — not chasing; leave for whoever owns prod data. Do not resurface under the dashboard ticket.
