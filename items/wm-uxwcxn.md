---
id: wm-uxwcxn
type: question
title: Ask Nate what current_investor_number=INV103 on the Nelnet loan tape means — sold to EDGEX, or earmarked for it?
status: open
created: 2026-08-14T20:18:22Z
updated: 2026-08-19T21:47:21Z
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

## Log
- 2026-08-19T21:36Z [claude-code] 2026-08-20 EdgeX dashboard review raised the same population from the other side: ~400K 'to be purchased' / ~150K DoD jump on the dashboard, cumulative NorthPond principal purchase ~8,005K. Drafted the Slack message to Nate covering (1) confirm EDGEX 2026-1NN takes only Experian-era Oliv loans and NO TU/NorthPond backbook, (2) explicit heads-up on any backbook->EDGEX move, (3) whether the 3-4d issuance->purchase gap fully explains the build-up, (4) whether any of the intended=EDGEX queue could settle into Purchaser I / stay on Oliv balance sheet (Dustin account step still pending), (5) expected Aug/Sep run rate. Abhishek sends it, not the agent. Meeting also flagged separately: principal-balance drop is OUR bug not Nate's; E3/E4 90/10-vs-60/40 is an Eric question gated on the principal balance being fixed; backbook terminology to be aligned with Sean.
- 2026-08-19T21:47Z [claude-code] 2026-08-20 FINAL MESSAGE SENT by Abhishek to Nate (short version, after he cut the draft down): 'From the issuance and positions files, we're seeing about $400-500K of loans coming through over the next 3-4 days, including a sudden ~$150K jump in a single day. Wanted to understand what these loans are - we were expecting only Experian-era Oliv loans in this deal, and no TransUnion / NorthPond backbook loans.' Deliberately left OPEN-ENDED - he did not want bulleted questions ('don't wanna enforce him to just respond to these bullets'). The Purchaser I fallback question and the Aug/Sep run-rate question were cut and remain unasked. Now waiting on Nate's reply.
