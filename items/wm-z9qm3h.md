---
id: wm-z9qm3h
type: task
title: lc silver positions + realized cashflows 10 days stale — no ticket, statements_lc failing every run
status: open
links: [relates:wm-8avh6w]
created: 2026-09-03T16:02:39Z
updated: 2026-09-03T16:02:44Z
source: claude-code
---

Found 2026-09-03 while verifying the data-freshness architecture doc ([[wm-8avh6w]]).
Not a doc finding — a live incident nobody has raised.

PROD, measured 2026-09-03:
  silver.positions                         lc newest 2026-08-24 = 10 days behind
  silver.realized_cashflows_calendar_month lc newest 2026-08-24 = 10 days behind
  silver.transactions                      lc newest 2026-09-01 =  2 days behind
Every other ACTIVE platform is <= 3 days on positions (upgrade/openroad/anchored 0,
happymoney/sofi/prosper 1, foursight/marlette/upstart/innovate 2, northpond 3).
Only figure is worse, and figure is wound down (last rows_added 2024-12-31).

LIKELY CAUSE, same reading: prod Dagster statements_lc has 3 FAILUREs and 0 SUCCESSes
in the 2026-08-31 22:33 -> 2026-09-03 15:36 UTC window. lc_statement_sensor itself is
RUNNING — the 2026-08-12 stopped-sensor finding in [[wm-hjbt5a]] has been fixed for all
13 platforms — so this is the job failing, not the sensor never firing.
statements_northpond is in the same state, 7 failed / 0 succeeded.

WHY IT MATTERS BEYOND lc: transactions is only 2 days behind while positions is 10, so a
freshness check reading any single table would call lc healthy. It is exactly the
partial-coverage false green the freshness pane is being built to catch.

NEXT: open a ticket, and pull the failure reason off one statements_lc run before
assuming it shares a root cause with statements_northpond.
