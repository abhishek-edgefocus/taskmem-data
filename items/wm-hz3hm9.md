---
id: wm-hz3hm9
type: task
title: NorthPond fund-returns panel copies FPM's JV-keyed query; efhyf (Evergreen) has no FUND_KEY
status: open
priority: p3
size: s
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-17T09:33:20Z
updated: 2026-07-17T12:56:40Z
source: claude-code
---

Found 2026-07-17 while analysing the NorthPond -> Fund Monitoring dashboard merge (parent context: wm-rgwdyu).

The NorthPond dashboard's "Annualized Net Return" stat panel queries
`SILVER.FUND_RETURNS WHERE FUND_KEY = '$fund'` with `$fund = efhyf`.
`FUND_KEY` is **NULL** for `FUND_NAME = 'Edge Focus High Yield Fund, LP'` in
**both PROD and DEV_ABHISHEK** — it is populated only for the 5 fortress JV
funds (fortress_sofi / happymoney / prosper / marlette_hyp / marlette_hyp_2).

So the panel is **silently empty today**, and the gold migration will NOT fix
it: FUND_RETURNS is Google-Sheet-sourced (has SHEET_ID / LAST_MODIFIED_AT
cols), so this needs a FUND_KEY mapping/backfill at the sheet or silver-model
level.

The same query shape is used by 2 Fund Performance Monitoring panels, which
work only because their funds have keys.

Also FUND_KEY-null and possibly wanting the same treatment:
'Edge Focus Paradigm Fund I, LP', 'Fortress JV - Aggregate',
'Private Credit Fund - Autos JV'.
