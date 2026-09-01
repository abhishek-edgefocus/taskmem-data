---
id: wm-udqmrm
type: task
title: Backfill openroad api_credit_attributes in PROD before the CMOP cron, or hold it deliberately
status: open
created: 2026-09-01T18:23:19Z
updated: 2026-09-01T18:23:19Z
source: claude-code
---

PROD.SILVER.API_CREDIT_ATTRIBUTES has 35 openroad rows, 0 carrying the maximum_ltv payload key that PR #6496 (merged 54c0b969c) added. The transform is stream-driven off openroad_stmt_purchase_tapes and openroad has had no purchase since 2024-12-12, so a normal tick never re-emits those payloads -- only `openroad_api_credit_attributes --date all`.

Until it runs, the newly-registered predictor fans each of the 35 loans over 19 MAXIMUM_LTV_FACTORS and run_prep_model raises 'Model output index contains ids with no efp_id mapping'. So openroad_auto_refi errors on every curr_mod cron (13:30 UTC) and the Sunday 14:00 best_est cron.

But running it has its own risk: predictions would then land with NULL RECOVERY_FRAC/SERVICING_FEE and prod's predicted_cashflows would process them -- the float(None) blocker on [[wm-xe6w4q]]. Decide which ordering, and also create the two missing checkin rows (curr_mod_openroad_openroad_auto_refi, best_est_openroad_openroad_auto_refi) via checkin.py --create.

Abhishek launches prod jobs himself.
