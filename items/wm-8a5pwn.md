---
id: wm-8a5pwn
type: followup
title: Ask Nate for two columns on the Nelnet transaction export: the Oliv OLV loan number, and dropping Last Name
status: next
priority: p1
size: xs
people: [Nate]
tags: [northpond, edgex, needs-reply]
links: [relates:wm-gj5tkx]
created: 2026-08-13T12:56:47Z
updated: 2026-08-13T12:56:50Z
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
