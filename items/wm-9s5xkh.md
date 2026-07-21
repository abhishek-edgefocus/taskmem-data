---
id: wm-9s5xkh
type: task
title: Integrate NorthPond/Oliv dashboard into Fund Monitoring: represent EFHYF + platform breakdown on a JV-keyed page
status: open
priority: p2
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-21T12:32:03Z
updated: 2026-07-21T12:32:13Z
source: claude-code
---

Frank's follow-up ask, from a live discussion with Abhishek on 2026-07-21 (the original "how is the Oliv page different?" question was answered in that conversation — see [[wm-jxuaum]], now closed).

WHAT FRANK ASKED: can we find a way to integrate the current Oliv / NorthPond dashboard into the Fund Monitoring dashboard, rather than keeping two pages whose panels overlap significantly. He explicitly acknowledged Fund Monitoring is meant for JOINT VENTURES, and asked whether we can nonetheless represent EFHYF (Edge Focus High Yield Fund) there, WITH ITS PLATFORM-LEVEL BREAKDOWN, so NorthPond is viewable from that page.

WHY THIS IS A DESIGN DECISION, NOT A MERGE: Fund Monitoring is keyed on FUND_KEY, and per the analysis in [[wm-hz3hm9]], FUND_KEY is effectively THE JV KEY — in PROD.SILVER.FUND_RETURNS it is populated only for the 5 Fortress JV funds (fortress_sofi / happymoney / prosper / marlette_hyp / marlette_hyp_2), all FUND_TYPE='Joint Venture'. EFHYF is FUND_TYPE='Evergreen' and its FUND_KEY is correctly NULL. So every JV-keyed panel returns nothing for EFHYF by construction. Same is true of 'Edge Focus Paradigm Fund I, LP' (Closed-end), 'Fortress JV - Aggregate' and 'Private Credit Fund - Autos JV'.

This means wm-hz3hm9 — previously dropped to low priority as "one stat panel" — is actually the crux of Frank's ask. Its conclusion (scope panels by FUND_NAME / FUND_TYPE instead of FUND_KEY) generalises from one panel to the whole integration.

## Options to weigh
1. Re-scope the shared panels by FUND_NAME or FUND_TYPE instead of FUND_KEY, making them fund-generic. Cleanest conceptually; touches panels that other JV funds rely on, so needs verification per panel.
2. Add a fund selector / separate row on Fund Monitoring covering Evergreen funds, leaving JV panels untouched. Lower blast radius, but leaves two query shapes on one page.
3. Backfill a synthetic FUND_KEY='efhyf'. EXPLICITLY WARNED AGAINST in wm-hz3hm9 — do not do this without first checking what else keys off FUND_KEY meaning "is a JV".

## Open questions
- Which platforms sit under EFHYF besides northpond? The "platform-level breakdown" Frank wants needs that list; if EFHYF is northpond-only today the breakdown is degenerate now but will not stay that way.
- Does Frank want the NorthPond page RETIRED after integration, or kept as a drill-down? He said "integrate ... along with", which is ambiguous.
- The newly migrated dashboard is d/5e958781-1b47-45fc-a7f7-dd4adf82ef4a (DEV-1395, shipped 2026-07-20); the old qQl7m9cHk is deprecated. Trishit confirmed on 2026-07-21 that the new link need not preserve the old URL.

## Context
- Migration that created the current page: [[wm-rgwdyu]]
- Gating technical question: [[wm-hz3hm9]]
- Also still unresolved on this dashboard family: [[wm-unb6pr]] (v1/v2 breakdown needs MODEL_VERSION in the gold grain)
