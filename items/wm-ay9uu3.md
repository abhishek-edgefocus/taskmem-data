---
id: wm-ay9uu3
type: task
title: Map FULLY_PAID_DATE for OpenRoad (DEV-1539)
status: active
size: s
people: [Abhijeet]
tags: [openroad, platform-data-owners]
links: [relates:wm-cgftbn, parent:wm-su6q4d]
refs: [DEV-1539=https://linear.app/edge-focus/issue/DEV-1539/add-fully-paid-date-mapping-for-openroad]
created: 2026-08-12T13:30:20Z
updated: 2026-08-20T19:40:15Z
source: claude-code
label: OpenRoad fully-paid date
---

Abhijeet split the FULLY_PAID_DATE mapping ask into one ticket per platform on 2026-08-11 19:22Z and assigned the OpenRoad one to Abhishek (DEV-1539, Backlog, no priority, no due date). The siblings went elsewhere: DEV-1516 NorthPond (Abhishek, tracked as [[wm-cgftbn]]), DEV-1538 Upstart and DEV-1540 LendingClub (both Kushagra). So this is the OpenRoad twin of work already scoped in detail on [[wm-cgftbn]].

Nearly all the analysis carries over — read [[wm-cgftbn]] first. The shared facts: the column exists only as a ColumnDefinition in `positions_constants.py:899` and `terraform/snowflake/silver_positions.tf:832`, no platform has mapped it yet, and the semantic to match is the legacy `datastore_closed_positions.py:70` one — `fully_paid_date` = the as_of_date on which STATUS first became `fully_paid`. The Prosper `RESOLVED_CHARGE_OFF_DATE` pattern (`prosper/positions.py:260-266`) is the precedent: compute the window in a subquery over the UN-date-filtered `silver.openroad_stmt_positions`, because a naive window inside COLUMN_MAPPING only sees the processing window and returns today's date on incremental runs.

What is genuinely OpenRoad-specific and not yet known: whether the OpenRoad tape carries a payoff-date field at all, or whether the date has to be derived from the status history the way NorthPond's does.

Caveat before starting: the OpenRoad silver chain has not run since 2026-07-07 ([[wm-85nuv4]]), so any prod sizing or validation baseline taken from `silver.openroad_stmt_positions` today is five weeks stale. Fix or account for that first, or the numbers will mislead.

## Next steps
1. Flatten RAW_RECORD keys on recent OpenRoad bronze positions rows and check for any payoff/paid-off date field before assuming it must be derived.
2. Read [[wm-cgftbn]]'s implementation notes and mirror them in `edgefocus/transformations/silver/statement_rows/openroad/positions.py`.
3. Count `fully_paid` OpenRoad loans in prod for a validation baseline — but see the staleness caveat above.
4. Decide whether to do this jointly with DEV-1516 in one PR, since the two mappings are near-identical.

## Links
- DEV-1539 — https://linear.app/edge-focus/issue/DEV-1539/add-fully-paid-date-mapping-for-openroad
- DEV-1516 (NorthPond twin) — https://linear.app/edge-focus/issue/DEV-1516/add-fully-paid-date-mapping-for-northpond
- Origin PR #6008 (added the column) — https://github.com/edgefocus/efp/pull/6008

## Log
- 2026-08-20T10:58Z [claude-code] DEV-1516 (the NorthPond twin) is implemented — see wm-cgftbn. Two findings carry over to OpenRoad:

1. Do NOT assume the LAG/LAST_VALUE current-run pattern is right. It is what prosper/anchored/sofi/marlette/figure use, but NorthPond needed MIN because its tape flaps in and out of the paid-off status with the balance already at zero. Check OpenRoad's tape for the same flapping before choosing: count loans with more than one not-paid -> paid transition, and look at whether the balance is already 0 at the first one.

2. The legacy closed_positions datastore is not a trustworthy oracle for this column. It stamps one row per transition and consumers keep the LAST, which produced dates months after the real payoff for NorthPond. Compare against its FIRST row per efp_id, not its last.

The NorthPond implementation is a LEFT JOIN subquery over the un-date-filtered positions source, gated in COLUMN_MAPPING on the row's own mapped status — copyable shape for openroad/positions.py.
