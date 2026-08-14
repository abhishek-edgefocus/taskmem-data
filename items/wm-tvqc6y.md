---
id: wm-tvqc6y
type: task
title: Set DESCRIPTION='recovery' on the Nelnet transaction leg before the first EDGEX charge-off
status: open
created: 2026-08-14T20:09:37Z
updated: 2026-08-14T20:09:37Z
source: claude-code
---

The Nelnet transactions transform (edgefocus/transformations/silver/statement_rows/northpond/transactions_nelnet.py, PR #6277) hardcodes DESCRIPTION='payment' for every row.

silver.transactions_itd splits ITD_RECOVERY_* from ITD_PAYMENT_* purely on DESCRIPTION='recovery' (transactions_itd.py). Those columns feed the positions ITD block, realized cashflows and CNL. Once a Nelnet loan charges off, its collections are counted as ordinary payments and CNL is wrong for the whole EDGEX book.

Not yet biting: no Nelnet loan has charged off. Oldest was originated 2026-05-13 and charge-off needs ~120 DPD. The first EDGEX charge-off is the deadline.

Complication: Nelnet ships no recovery transaction type - only PAYMENT, PAYMENTREVERSAL, INTERESTACCRUAL, ADJ-INTERESTACCRUAL, DISBURSEMENT. So unlike prosper (IS_CHARGEOFF_RECOVERY) or openroad/anchored (PAYMENT_TYPE='RECOVERY'), the rule has to be positional: description='recovery' when the loan's status is charged_off as of EFFDATE.

Found 2026-08-15 while writing the column-mapping notes (~/notes/northpond/02-standardized-mapping.md, finding #2 in 04-findings.md).
