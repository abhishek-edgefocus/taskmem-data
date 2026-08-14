---
id: wm-8a5pwn
type: followup
title: Ask Nate for two columns on the Nelnet transaction export: the Oliv OLV loan number, and dropping Last Name
status: done
priority: p1
size: xs
people: [Nate]
tags: [northpond, edgex, needs-reply]
links: [relates:wm-gj5tkx]
created: 2026-08-13T12:56:47Z
updated: 2026-08-14T13:51:17Z
source: claude-code
---

Two column-level asks for the Nelnet exports, both cheap for Oliv and both worth landing while Nate is actively rebuilding these files (he is already producing a PII-free loan export). Raised off the DEV-1481 work, PR https://github.com/edgefocus/efp/pull/6262.

1. ADD THE OLIV LOAN NUMBER TO THE TRANSACTION EXPORT.
   This is the high-value one. V_Transaction_Detail_Export_Daily_OlivFinancial_*.xlsx keys only on Nelnet's 12-digit `Loan Number`. Verified against PROD INFORMATION_SCHEMA that NO table we hold carries that number: northpond_stmt_issuance.LOAN_ID, northpond_stmt_purchase_tapes.LOAN_ID and northpond_stmt_issuance_v2.OLIV_LOAN_NUMBER are all the Oliv OLV number. Our standardized keys are EFP_ID / POSITION_ID = 'northpond_' || <OLV>, so without an OLV column on this file the transaction feed CANNOT reach silver.transactions except by bridging through the Nelnet loan tape (its field 1 <-> field 39).
   Consequence: transactions are hard-blocked on positions purely for a join key. One extra column decouples them and lets the transaction feed standardize on its own.
   This was ask #4 in the 2026-07-28 list and has never been answered.

2. DROP `Last Name` FROM THE TRANSACTION EXPORT.
   Nate's PII commitment (2026-08-12) covers the LOAN TAPE only — SSN, DOB, address, phone, email, bank routing. The transaction export was never in scope and still ships the borrower surname. PR #6262 works around it by routing the file through efp-pii and ingesting only the _CLEANED sibling, which costs us a pii_columns entry plus a load-bearing ignore rule for the raw .xlsx.
   If Oliv drops the column at source, BOTH of those can be deleted and the file parses directly from efp-raw. Cheaper for us and consistent with the fix-at-source principle Abhishek stated to Nate on the call.

Neither is blocking the merge of #6262; both change how much we build afterwards.

## Log
- 2026-08-14T13:51Z [claude-code] ASKED AND ANSWERED 2026-08-13/14 — closing.

Abhishek put both asks to Nate in the DM at 2026-08-13 19:15 IST
(https://edgefocuspartners.slack.com/archives/D0BAD46CT27/p1786637140000000 — thread reads from
19:15 onward): "1. Transactions file: could you add the Oliv loan number (e.g. OLV12345678)?
2. Positions file: I can't find charge-off date or charged-off principal anywhere in it".

NATE'S ANSWER — he declined to add computed fields to the SERVICER files, on principle:
"I'd prefer not to create fields in the files we send but rather discuss how to derive/get the
fields you need. The files we're sending are a straight subset of what is provided to us. It'd
be better not to introduce multiple levels of transformations." He drew an explicit line: the
issuance file is different, because Oliv derives it in house, so that one CAN take new columns.

WHAT WE GOT INSTEAD, from the 2026-08-13 21:32 IST huddle (no transcript; these are the
messages Nate typed into the DM during it):
- OLV number: loan.loan_external_reference -> "OLV123...." on the Nelnet LOAN file.
- Join between the two Nelnet files: transaction.loannumber ~= loan.loan_number.
- Charge-off: loan_status = 'charge off' (a status flip, not a date column).
- Bankruptcy: current_loan_period_reporting_status = 'Bankruptcy Deferment'.
- Added to issuance_v2 instead: issuance_date and servicer_loan_number. Nate deployed this and
  pushed a regenerated issuance_v2 file at 2026-08-14 00:33 IST; Abhishek checked it and said
  "Data looks good".

So ask 1 is satisfied by a different route than requested: servicer_loan_number on issuance_v2
is the bridge from Nelnet's 12-digit loan number to the OLV key, so the transaction feed no
longer has to bridge through the loan tape. PR #6277 is already built this way.

Ask 2 (drop Last Name) is overtaken rather than refused: the go-forward files are the PII-free
"cleaned" exports, which Nate describes as "a subset of columns, no PII". Last Name should be
gone with the rest of the PII, but that is INFERRED from his description — it is not separately
confirmed and no PII-free transaction file has landed in S3 yet. Verifying it is part of the
Monday cutover check on [[wm-gj5tkx]], not a live ask on Nate.
