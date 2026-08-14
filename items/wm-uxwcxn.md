---
id: wm-uxwcxn
type: question
title: Ask Nate what current_investor_number=INV103 on the Nelnet loan tape means — sold to EDGEX, or earmarked for it?
status: open
created: 2026-08-14T20:18:22Z
updated: 2026-08-14T20:18:22Z
source: claude-code
---

Oliv corrected the cleaned loan tape on 2026-08-15. It had been sending current_investor_number=INV101 for every loan while the raw DF2 tape underneath carried INV103 on ~200. Abhishek raised it at 01:26 IST; Nate replied "that is a mistake" and regenerated the file at 01:31 IST.

VERIFIED 2026-08-15 on the regenerated olivfinancial_loan_20260814.csv (392 rows, 56 columns, schema otherwise unchanged):
- INV103 on 218 loans, first disbursement 2026-08-01 .. 2026-08-13
- NULL on 174 loans, first disbursement 2026-05-14 .. 2026-08-01 (the older book Oliv kept)

Cross-checked against every live v0 purchase file (2026-08-11 .. 08-14: 29 + 50 + 17 + 17 rows, 113 distinct loan_id):
- all 113 purchased loans are tagged INV103 - the two sources agree perfectly on the purchased set
- 105 loans are tagged INV103 with NO purchase event ever, disbursed 2026-08-01 .. 08-13, overlapping rather than preceding the purchased range

THE QUESTION. If INV103 means "sold", then 105 loans changed hands with no purchase file and our transfer history is incomplete. If it means "earmarked" (which matches Nate's tagging rule - "if it's predefined who the loan is for, we'll tag it regardless of sale"), the tape is showing the forward pipeline ~2 weeks ahead of settlement, and current_investor_number on the tape carries different semantics from current_investor on issuance_v2 despite the near-identical name.

CONSEQUENCE EITHER WAY. The tape field must NOT become the FUND source: deriving fund from it would book those 105 into EDGEX while they sit on the balance sheet, and silver.transfers would lose the purchase event - exactly what the arm-2 purchase-tape gate prevents. It is a cross-check, and possibly an intended_investor source.

Related: [[wm-abqg3u]] (which purchase categories EDGEX takes) - this is the first hard number on that population question.
Written up in ~/notes/northpond/04-findings.md (finding 1).
