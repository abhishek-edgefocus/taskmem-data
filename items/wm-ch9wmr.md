---
id: wm-ch9wmr
type: task
title: Fix cfframe capture gap: at-origination pred cashflows missing since Feb/Mar 2025 (DEV-1279)
status: open
priority: p2
size: l
tags: [northpond]
links: [parent:wm-3sxcre]
refs: [DEV-1279=https://linear.app/edge-focus/issue/DEV-1279/at-origination-predicted-cashflows-not-generated-for-loans-originated]
created: 2026-07-14
updated: 2026-08-21T21:56:34Z
source: dpx-tasks #4
label: cfframe capture gap
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #4
- 2026-08-21T21:56Z [claude-code] Verified in prod 2026-08-21 (PROD.SILVER, sqlrun on dpx): DEV-1279's premise no longer holds. The ~230-loan efhyf gap is CLOSED — all 372 efhyf loans on AS_OF_DATE=2026-08-21 have prediction_type='at_orig' rows in silver.predicted_cashflows, including the exact cohort the ticket named (267 efhyf loans originated >= 2025-02-01: 9,612 rows = 36 periods each, NET_CASH_FLOW and CHARGEOFF non-null on every row, LOADED_AT 2026-08-21 07:03 so it is rebuilt daily). Fixed as a side effect of the silver/EDGEX EF-scoring migration (wm-c5jytx, wm-qs96kd, DEV-1395), not by anyone touching the legacy cfframe capture step. gold.predicted_cashflows_mob carries northpond across 4 funds, so the MOB-curve symptom is fed too.

RESIDUAL BUT DIFFERENT GAP: 55 loans on the same as_of have no at_orig — all fund=northpond_balancesheet, all status=current, originated 2026-05 (12), 2026-06 (28), 2026-07 (15), ~125k principal, ANL and EF_SCORE both NULL. Root cause is NOT the cfframe capture step the ticket blames: those 55 have zero rows in silver.predictions and zero bronze.api_events of ANY type — no model_responses, no model_requests, no experian_request. They never entered the decisioning API. Contrast: 1,249/1,249 loans that DO have at_orig all have a model_response, and 519/519 August originations are covered. So May+June 2026 northpond originations are 100% unscored and July is 15/140 unscored.
