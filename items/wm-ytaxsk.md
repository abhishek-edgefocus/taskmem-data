---
id: wm-ytaxsk
type: task
title: Purchase tape lands before the Nelnet positions feed - northpond_transfers fails ~daily until it catches up
status: next
priority: p1
size: s
due: 2026-09-03
tags: [northpond, edgex]
created: 2026-09-01T11:35:00Z
updated: 2026-09-03T15:07:20Z
source: claude-code
---

## Log
- 2026-09-02T19:36Z [claude-code] LINEAR TICKET IDENTIFIED (2026-09-03): this is ERROR-1626 (https://linear.app/edge-focus/issue/ERROR-1626, Sentry EFP-ERRORS-1JB, assignee Abhishek, priority Low, labels Dagster + Data Ingestion). Currently OPEN — reopened 2026-09-01 19:27Z.

The ticket is FLAPPING, which is why it keeps resurfacing: Done -> Backlog six times now (07-19, 08-19, 08-29 20:27, 08-31 21:32, 09-01 15:29, and reopened again 09-01 19:27). Sentry auto-reopens it on each regression, so closing it by hand does not stick while the underlying ~daily failure continues.

Last 7d of EFP-ERRORS-1JB events are all Steps failed: ['northpond_transfers'] — 09-01 09:50, 09-01 13:37, 09-01 18:49, 09-02 11:49, 09-02 13:14, 09-02 18:52 — plus two 'Exceeded maximum runtime of 7080 seconds' runs on 08-29 14:20 and 08-31 16:33 (worth checking whether the timeout is the same tape-vs-positions lag stalling the step, or a separate problem).

Cadence matches this item's thesis exactly: ~2-3 failures/day, clearing and recurring rather than failing permanently.

NOTE the ticket will keep auto-reopening until either the ordering is fixed or the alert is tuned — so 'is it closed' is not a useful signal for this one. See also [[wm-hjbt5a]] (records northpond_transfers ValueError: Validation failed with 1116 error(s)) and the correction [[wm-85vvgw]] (ERROR-1626 is NOT the .efp_toplevel defect in [[wm-te4cr2]]; that one still has no Linear ticket at all).
