---
id: wm-bpmxnb
type: task
title: Ingest OpenRoad model_requests/model_responses stmt files for real credit scores (DEV-1396)
status: open
priority: p2
size: l
tags: [openroad]
links: [parent:wm-su6q4d]
refs: [DEV-1396=https://linear.app/edge-focus/issue/DEV-1396/ingest-openroad-model-requestsmodel-responses-statement-files-for-real]
created: 2026-07-14
updated: 2026-08-19T19:42:40Z
source: dpx-tasks #6
label: OpenRoad model_requests ingest
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #6
- 2026-08-19T19:42Z [claude-code] NOW A CONFIRMED HARD BLOCKER, not just a data-quality gap (2026-08-19/20).
The missing VANTAGE4 credit score is what breaks openroad_api_predictions in PROD — it is no longer only a
comparison/parity nicety.

Measured read-only in PROD, replicating openroad_api_predictions' own matched_loans join:
- ALL 35 openroad loans have VANTAGE4 NULL in PROD.SILVER.OPENROAD_OFFERS
  (whole table: 68,818 non-null of 6,043,026 = 1.1%)
- openroad_api_predictions computes SERVICING_FEE = COALESCE(payload:servicing_fee,
  openroad_servicing_fee_sql(vantage4)); the helper returns NULL for a NULL/out-of-range score by design.
- 19 loans are saved by a gateway-logged payload:servicing_fee (events from 2023-10-27 onward).
- The 16 older 'pre-logging' loans have neither -> SERVICING_FEE NULL -> the transform's own validation
  rejects them -> 1,139 failing period-rows, which is EXACTLY the error count Dagster reported on both
  manual statements_openroad runs (4b394017..., 14320188...).

So DEV-1396 (ingest the flat model_requests/model_responses statement files that carry the real TU score)
is now on the critical path for OpenRoad predictions, not a side quest. Alternative if that ingestion is
far off: decide explicitly whether to relax the SERVICING_FEE rule / park those 16 pre-logging loans —
but note the rule exists precisely to stop NaN servicing fees silently corrupting predicted cashflows
(DEV-1331), so relaxing it needs a deliberate call, not a quiet edit.
Context and the full diagnosis are on [[wm-85nuv4]].
