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
updated: 2026-07-21T12:34:14Z
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

## Log
- 2026-07-17T12:56Z [claude-code] REFRAMED 2026-07-17 after Abhishek's call that Fund Monitoring is a JV dashboard. Evidence: PROD.SILVER.FUND_RETURNS.FUND_TYPE — all 5 FPM funds are 'Joint Venture' and are the ONLY rows with a populated FUND_KEY; efhyf = 'Edge Focus High Yield Fund, LP' = FUND_TYPE 'Evergreen', FUND_KEY null (as are Paradigm 'Closed-end', 'Fortress JV - Aggregate', 'Private Credit Fund - Autos JV'). So FUND_KEY is effectively the JV key and its nullness for efhyf is CORRECT, not a gap — my original 'backfill FUND_KEY' framing was wrong. The actual defect is in the dashboard: the NP WIP's 'Annualized Net Return' panel is byte-identical to FPM's (copy-pasted from the JV dashboard), so it inherits WHERE FUND_KEY='$fund' and returns nothing for efhyf. Fix belongs in the query — scope by FUND_NAME='Edge Focus High Yield Fund, LP' (or FUND_TYPE='Evergreen') instead of FUND_KEY. Do NOT backfill FUND_KEY='efhyf' without checking whether anything else keys off FUND_KEY meaning 'is a JV'. Dropped to low priority: one stat panel.
- 2026-07-21T12:32Z [claude-code] PRIORITY REFRAME 2026-07-21. This was dropped to low on 2026-07-17 as 'one stat panel'. Frank has now asked (live discussion with Abhishek, 2026-07-21) to integrate the NorthPond/Oliv dashboard INTO Fund Monitoring, representing EFHYF and its platform-level breakdown there — see new item wm-9s5xkh. That makes the FUND_KEY-vs-FUND_NAME/FUND_TYPE scoping question in this item the CRUX of that integration rather than a minor panel bug: every JV-keyed panel on Fund Monitoring returns nothing for EFHYF by construction, because FUND_KEY is effectively the JV key and EFHYF is FUND_TYPE='Evergreen'. The conclusion recorded here — scope by FUND_NAME='Edge Focus High Yield Fund, LP' or FUND_TYPE='Evergreen' instead of FUND_KEY, and do NOT backfill a synthetic FUND_KEY without checking what else keys off it meaning 'is a JV' — now generalises from one panel to the whole page. Re-prioritise alongside wm-9s5xkh rather than fixing in isolation.
