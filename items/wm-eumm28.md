---
id: wm-eumm28
type: task
title: Ask Nate to backfill issuance_v2 current_investor to 2026-08-11 (unblocks deleting the northpond fund date-hack)
status: next
priority: p2
size: xs
people: [Nate]
tags: [northpond, edgex]
links: [relates:wm-4sxy5d]
created: 2026-08-14T13:56:36Z
updated: 2026-08-14T14:56:17Z
source: claude-code
---

Oliv added current_investor / intended_investor / loan_servicer / servicer_loan_number to issuance_v2 on 2026-08-13, and re-pushed that day's file with the new schema. Every earlier snapshot (2026-07-24 .. 2026-08-12) has the columns absent or NULL.

The first EDGEX purchases landed 2026-08-11. So for as_of 2026-08-11 and 2026-08-12 there is a two-day window where 96 loans are EDGEX-purchased but issuance_v2 cannot say so.

That is the ONLY reason NORTHPOND_EDGEX_PURCHASE_START ('2026-08-01') and the whole purchase-tape arm of the fund expression still exist in constants.py. Everything before 2026-08-11 is unambiguous - all efhyf purchases are 2025-02-05..2025-06-17, a 14-month gap from the first EDGEX purchase.

Ask: re-emit issuance_v2 for 2026-08-11 and 2026-08-12 with current_investor populated. Two files.

Once those land and are re-parsed, delete from constants.py:
- NORTHPOND_EDGEX_PURCHASE_START
- the two purchase-tape IN-subquery arms in northpond_fund_expr()
- the IFF(purchase_date >= ...) arm in PURCHASE_TAPE_FUND_EXPR
and the corresponding tests in northpond_constants_test.py.

Note also: bronze ingested the OLD 2026-08-13 issuance_v2 before Nate re-pushed it (prod silver still shows the combined 'current_or_intended_investor' and no servicer_loan_number). That file needs a re-parse regardless, or current_investor is NULL everywhere and FUND silently falls back to the purchase tape for every loan.
