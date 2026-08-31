---
id: wm-8uyfnw
type: bug
title: NorthPond BEP stops at predicted_cashflows — no rows in best_est_projections_at_orig or gold MOB
status: next
priority: high
size: m
tags: [northpond, predictions, dev-1498]
created: 2026-08-31T15:33:08Z
updated: 2026-08-31T15:33:08Z
source: claude-code
---

CMOP is fully live end to end in PROD after DEV-1498 ([[wm-79k8df]]). BEP is
generated and reaches `silver.predicted_cashflows_history`, but **stops there** —
it never reaches `silver.best_est_projections_at_orig`, and therefore never
reaches `gold.predicted_cashflows_mob`, which is where consumers read it.

**Verified in PROD 2026-08-31 (~15:00 UTC), by existence probes:**

| Stage | curr_mod | best_est |
|---|---|---|
| `silver.predictions` | ✅ both channels, latest gen 2026-08-30 13:30 PDT | ✅ `northpond_exp_loan_fl`, gen 2026-08-30 14:10 PDT |
| `silver.predicted_cashflows_history` | ✅ | ✅ (`northpond_loan_fl` seen at MOB 10) |
| `silver.predicted_cashflows` (the view) | ✅ | ✅ `northpond_exp_loan_fl`, MOB 1, prediction_date 2026-08-30 |
| `silver.best_est_projections_at_orig` | n/a | ❌ **NONE for northpond** (sofi rows present, so the table itself is fine) |
| `gold.predicted_cashflows_mob` | ✅ as_of 2026-08-31 | ❌ **NONE** |
| `gold.predicted_cashflows_calendar_month` | ✅ as_of 2026-08-31 | not checked |

**It is not "pending".** `best_est_projections_at_orig` materialized in prod at
2026-08-31 14:07 UTC (run `404101b1`), well after the BEP predictions landed on
2026-08-30 21:10 UTC, and still produced no northpond rows. `predicted_cashflows_mob`
ran in the same run at 14:28 UTC.

**So the inputs are all present and the overlay ran and skipped northpond.**
`BestEstProjectionsAtOrig` (`edgefocus/transformations/silver/predictions/best_est_projections_at_orig.py`)
overlays `REALIZED_SOURCE = silver.realized_cashflows_from_origination` with
`PREDICTED_SOURCE = silver.predicted_cashflows` filtered to best_est, FULL OUTER
JOIN on `r.efp_id = p.efp_id AND r.mob = p.mob`. Northpond has realized rows
(11,547 / 1,075 loans). Candidate causes, none checked yet:
- `key_column = "as_of_date"` with `reload_all_on_change=True` on both stream
  sources — northpond's changed keys may not be reaching it
- the per-row `segment_fund` the gold aggregate expects may be null for northpond
- an efp_id / MOB axis mismatch between the realized and predicted sides

**Why this was never caught pre-merge:** this is exactly the stage that could not
be exercised in `DEV_ABHISHEK`, because there `silver.predicted_cashflows` was a
pass-through view to PROD, so nothing written in dev could reach the overlay. The
PR was explicit that the gold layer past `predicted_cashflows` was not claimed.

Blocks closing DEV-1498: the ticket is "Setup NorthPond CMOP/**BEP**", and BEP is
not visible where it is consumed.
