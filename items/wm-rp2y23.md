---
id: wm-rp2y23
type: task
title: Build EdgeX-2026-1NN Grafana dashboards (zero exist) + promote NorthPond monitoring dashboard out of personal folder
status: open
priority: p2
size: l
tags: [northpond, edgex]
links: [parent:wm-j523sq, blocked-by:wm-ku5sen]
created: 2026-07-17T09:40:24Z
updated: 2026-07-21T09:05:47Z
source: claude-code
---

Verified via Grafana API 2026-07-17: the string "edgex20261NN" appears in ZERO of the 172
dashboards. Every other warehouse is wired into 12-17 dashboards:
  edgex20251NN -> 17    edgex20252NN -> 17    edgex2026PT1 -> 12    edgex20261NN -> 0

## Missing deal dashboards
The EDGEX folder has a Deployment dashboard per deal, and 1NN deals additionally get MOB and
Triggers and P&I:
  EdgeX-1NN 2025 Deployment (aQEY-11Hz) + EdgeX-1NN 2025 MOB (oCUkgojNk)
    + EdgeX-1NN 2025 Triggers and P&I (3hYmgTCHz)
  EdgeX-2NN 2025 Deployment (ng4OnJeNz) + EdgeX-2NN 2025 MOB (abn6rvx)
  EdgeX-2026-PT1 Deployment (abqqftg)
There is NO EdgeX-2026-1NN dashboard of any kind. Clone the 1NN 2025 set as the template
(it is the closest structural match: same deal shape, has the Triggers/P&I page).

BLOCKED until wm-ku5sen lands: with zero rows in GOLD.WAREHOUSE_CL / WAREHOUSE_THRESHOLDS for
edgex20261NN, a cloned dashboard would render empty. Build the dashboards AFTER the warehouse
materializes.

## Separate: the NorthPond monitoring dashboard is still personal + WIP
"NorthPond Monitoring — Snowflake Migration (WIP)" uid 5e958781 sits in the PERSONAL "Abhishek"
folder, titled WIP, 80 panels (per wm-drehnk inventory: 22 work vs PROD today, 31 blocked on
empty gold -> wm-qs96kd, 14 blocked on SILVER.NORTHPOND_AT_PURCHASE_FEATURES which is ABSENT in
PROD -> PR #5884). For the deal it must be promoted out of the personal folder, de-WIP'd, and
the 3 old [DEPRECATED] NorthPond dashboards left as-is (rename convention already applied).

## Log
- 2026-07-21T09:05Z [claude-code] PARTIALLY ADVANCED 2026-07-20/21 — the 'promote out of personal folder' half is essentially settled. Abhishek asked Abhijeet whether to put the new dashboard in the fund-monitoring folder ('Navya Dashbaord la kay fund monitoring valya folder madhe thevu ka? Sahebanni sagla restructure kelay', ts 1784576175); Abhijeet: 'yes chalel, northpond cha ek folder banaw happymoney cha ahe tasa' (ts 1784577334) — create a dedicated northpond folder modelled on the HappyMoney one. Abhishek: 'Ok moving, anyways the dashboard is now updated with prod data' (ts 1784577366). New dashboard: https://grafana.edgefocuspartners.com/d/5e958781-1b47-45fc-a7f7-dd4adf82ef4a. VERIFY the folder move actually landed. The EdgeX-2026-1NN dashboards half of this item is still untouched and still blocked by wm-ku5sen.
