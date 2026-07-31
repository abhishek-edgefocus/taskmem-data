---
id: wm-9dfnnt
type: task
title: Validate the new EDGEX purchase tapes for Oliv (first real landing)
status: next
priority: p1
size: s
due: 2026-08-03
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [relates:wm-jewha5]
created: 2026-07-31T14:19:39Z
updated: 2026-07-31T14:19:44Z
source: claude-code
---

Abhishek asked (2026-07-31) to be reminded to validate the new EDGEX purchase tapes
for Oliv on **Monday 2026-08-03** — the first real Oliv purchase files are expected
then (per Frank, some platforms deliberately waited until Monday for next month's
warehouse triggers; Trishit 2026-07-30: Oliv is building a backbook but nothing on
direct EDGEX bookings yet, with Dustin reporting delayed account creation).

This is the REAL-traffic counterpart to [[wm-jewha5]] (which checks that Nate's
`_test` stubs are correctly ignored). Do both in one pass when files land.

What to validate when the tapes arrive:
1. `aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive` — confirm
   real (non-`_test`) files landed at the finalised `purchase_file/v0` path
   (routing matrix logged on [[wm-n7usn7]]).
2. PROD.BRONZE.STATEMENT_FILES — real files should be STATUS=processed with
   statement_type=purchase_tape / correct as_of_date / rule_name set (NOT 'ignore');
   any `_test` files alongside them must still be STATUS=ignore.
3. PROD.BRONZE.STATEMENT_ROWS platform=northpond statement_type=purchase_tape —
   new 2026 rows beyond the 6 x 2025 Pool events.
4. PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES — row/loan counts move past
   372 rows / 372 loans / 6 as_of_dates.
5. EDGEX investor IDs on the new rows: EDGEX Purchaser I = INV105, EDGEX Grantor
   Trust = INV103 — see [[wm-5z3pjt]] for the fund mapping.
6. Legacy datastore feed — the legacy StatementPurchaseTape path that EDGEX ABS
   still reads must not silently starve as Oliv moves files ([[wm-tvjjgw]]).
