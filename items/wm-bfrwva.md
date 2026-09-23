---
id: wm-bfrwva
type: bug
title: FPM Monthly ROI panel understates any month a fund sells loans (EFHYF 2026-03 = -15.8%; prosper platform -35.5%)
status: inbox
priority: p2
tags: [grafana, fund-monitoring, dev-1716]
links: [relates:wm-uwncjv]
created: 2026-09-23T10:24:40Z
updated: 2026-09-23T10:24:40Z
source: claude-code-critic
label: FPM Monthly ROI panel understates
---

Found 2026-09-23 while checking reviewer feedback on the DEV-1716 EFHYF copy ('3/1/2026 monthly return seems off at -36%').

Panels 542 (stat) and 544 (timeseries) compute (TOTAL_EOP_VALUE + TOTAL_NET_CASH_FLOW - TOTAL_BOP_VALUE) / TOTAL_BOP_VALUE from PROD.GOLD.REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY.

In 2026-03 EFHYF sold 226 LC loans (lcx_pm 234 -> 1 current, 214 flip to STATUS='sold'; lcx_sm 15 -> 2). silver.transfers 2026-03-31 has FROM_FUND=efhyf, TO_FUND=NULL x226 (sale outside EF). Value leaves: lcx_pm BOP 2,145,083 -> EOP 29,990, but TOTAL_NET_CASH_FLOW only 183,708 (principal+interest payments) and TOTAL_TRANSACTION_PROFIT = 0 — the sale proceeds are never booked, so the formula reads the disposal as a loss.

Fund level 2026-03: BOP 12,561,222 EOP 9,688,170 NETCF 889,046 -> -15.79%. Per-platform: lc -75.68%, prosper -35.45% (the reviewer's -36% is the prosper platform selection). Same artifact in 2026-05 (-8.05%) and 2026-06 (-8.49%), and on efalpha 2026-03 (-7.01%). Fortress funds never sell, so prod shows +0.2..+1% and nobody noticed.

Legacy datastore's total_returns for efhyf 2026-03 is +12,853 (small positive) — it does not treat the sale as a loss.

NOT a DEV-1716 regression: the panel SQL is unchanged prod SQL; EFHYF is just the first fund on the page that sells loans. Fix belongs with whoever owns realized cashflows (book sale proceeds into TOTAL_NET_CASH_FLOW / TOTAL_TRANSACTION_PROFIT), not in the dashboard.

## Environment
- taskmem: 53d0894
- reported by: claude-code-critic
- host: ip-192-168-1-6.ap-south-1.compute.internal
- when: 2026-09-23T10:24:40Z
