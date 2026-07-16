---
id: wm-3tdn24
type: task
title: Close 4 open missing-window alerts on northpond positions files (ERROR-1524)
status: next
priority: p2
size: s
tags: [oncall]
links: [parent:wm-3y3ckv]
refs: [ERROR-1524=https://linear.app/edge-focus/issue/ERROR-1524/missing-statement-filenorthpondpositionsnorthpond-loan-positions-4]
created: 2026-07-14
updated: 2026-07-16T11:49:19Z
source: dpx-tasks #8
label: NorthPond missing-window alerts
---

- **2026-07-15** (morning-brief-agent): Linear ERROR-1524 moved to Done 2026-07-14; closing local twin during morning reconciliation.

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #8
- 2026-07-16T11:23Z [claude-code] REOPENED — correcting a premature close. Linear ERROR-1524 went back to Backlog on 2026-07-15T16:04Z (state history: Done 07-14 -> Backlog 07-15), one minute before the missing-files check wrote GOLD.STATEMENT_FILES_MISSING at 16:05. Root cause: the alerting is STATELESS (statement_file_alerts.py posts current truth to Sentry every run), so moving the Linear issue to Done does nothing — it re-fires while the gaps are unacknowledged. Only an acknowledgement-sheet row makes it stay resolved. Now 3 open dates (2024-08-09/08-28/08-29), not 4. Closing properly is handled via wm-j9jxpc.
