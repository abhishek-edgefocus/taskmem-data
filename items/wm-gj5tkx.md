---
id: wm-gj5tkx
type: task
title: Ingest Oliv's Nelnet loan + transaction files (new servicer, replaces FCC feed; carries investor tag)
status: open
priority: p2
size: l
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [parent:wm-j523sq, relates:wm-5z3pjt]
created: 2026-07-28T11:49:54Z
updated: 2026-07-28T12:35:23Z
source: claude-code
---

Raised by Nate Wong 2026-07-28 in the EDGEX 2026-1NN investor-mapping thread (group DM C0BJ1M304BU, parent ts 1785238591.530479), as point 3 of his proposal.

Oliv has moved servicer from FCC to Nelnet. They have not yet extended the Nelnet loan + transaction files to EF — "for no reason other than prioritization". These are the equivalent of the files we receive today sourced from FCC. Critically, the Nelnet LOAN file carries the investor tag, so this feed is what properly resolves INV103 (EDGEX Grantor Trust) vs INV105 (EDGEX Purchaser I) — see wm-5z3pjt.

Repo state verified 2026-07-28 (~/repos/efp master): nothing consumes Nelnet data. The only "nelnet" reference is configs/default_passwords.json:371, an OUTBOUND sftp block (hostname mft.nelnet.net, remote_directory "To_Nelnet/") unrelated to Oliv ingestion. No parsing rules, no bronze platform config, no silver transformations.

Open questions to settle before scoping:
- Do the Nelnet files REPLACE the current Oliv loan/transaction files or run alongside them? If a cutover, we need a dual-run window and a reconciliation before switching.
- What is the file format / schema, and does it differ from the current FCC-derived tapes?
- Delivery mechanism — same SFTP account as today, or new?

## Log
- 2026-07-28T12:31Z [claude-code] Nate shared samples 2026-07-28 17:56 IST in the 'NN File Sharing' thread (C0BJ1M304BU, parent ts 1785241457.230439). Said start with loan + transaction as most useful. Analysed all three:

LOAN FILE — VELOCITY_SERVICING_DF2_20260728_20260728_030209 (text/plain, 142.7KB)
- Nelnet Velocity servicing daily loan file. Record header 'H|07/28/2026|servicing.pgp' (PGP-encrypted in transit), footer 'F|148' = row count. 148 loans.
- Pipe-delimited, POSITIONAL, NO column-name header. 333 fields per row; 234 of 333 always empty in this sample (99 populated).
- Field 1 = Nelnet loan number (e.g. 403024498414). Field 39 = OLV12563360 = the Oliv loan number, our join key to existing data.
- Economics present: origination date, amount, term, rate, next due date, payment amount, status (repayment/active), payoff/accrual fields.
- Fields 228-252 and 328 carry RAW PII: full name, DOB, SSN (twice: fields 234 and 328), street address, city/state/zip, phone, email.
- NO investor tag in this sample (no INV103/INV105 anywhere in the file).

TRANSACTION FILE — V_Transaction_Detail_Export_Daily_OlivFinancial_<ts>.xlsx (XLSX, not CSV)
- 18 named columns: Lender Name, Investor Number, Borrower Number, Loan Number, Last Name, Loan Program, Transaction Type, NonCash, Eff Date, Rpt Date, Tran Amt, Principal, Int Amt, Int Paid, LF Amt, LF Paid, OF Amt, OF Paid.
- 07-25 file: 110 rows / 60 loans, Eff Date 2026-07-22..24. 07-28 file: 7 rows.
- Transaction Types seen: DISBURSEMENT, INTERESTACCRUAL, PAYMENT. NonCash = 'Non-Cash' on every row incl. PAYMENTs.
- 'Investor Number' column EXISTS but = 'none' on every row — this is the field that would resolve INV103/INV105.
- Dates are Excel serials, not date strings.
- Loan Number is the NELNET 12-digit number, NOT the OLV number. Verified all 60 tx loan numbers join to loan-file field 1 (overlap 60/60). So transactions can only reach the OLV key by bridging through the loan file.

BLOCKERS / asks for Nate:
1. Need the Velocity DF2 record layout / data dictionary — cannot parse 333 unnamed positional fields without it. This is the #1 blocker.
2. Investor Number is 'none' everywhere — when does it get populated?
3. PII: SSN/DOB/address/email/phone. NORTHPOND_CONFIG in bronze/platform_configs/northpond.py has pii_columns={} and no Oliv feed carries PII today. Compliance decision needed — can Nelnet suppress those fields?
4. Add the Oliv loan number (OLV...) to the transaction file so it stands alone.
5. CSV rather than XLSX — the whole northpond pipeline ingests CSV (only the purchase tape is xlsx).
6. Confirm delivery cadence, SFTP path and a stable filename pattern (samples carry two timestamps) for the parsing rules.
7. Clarify NonCash='Non-Cash' on PAYMENT rows.
- 2026-07-28T12:35Z [claude-code] Nate 2026-07-28 18:01: proposes SFTP paths 'nelnet/daily_loan/YYYY/MM' and 'nelnet/daily_transaction/YYYY/MM'. Confirms the samples are '1:1 with what we receive' from Nelnet — Oliv is FORWARDING raw servicer files, not transforming them. That means asks like CSV-instead-of-XLSX, PII suppression, or adding the OLV number to the transaction file require Oliv to build a transform step, not just relay. Nate is queuing the task regardless. Abhishek committed to comparing the samples against the current feeds and getting back.

NOTE on proposed paths: every existing northpond parsing rule is anchored at 's3://.*/statements/northpond/...'. Nate's bare 'nelnet/...' prefix would sit outside that — either ask him to nest under statements/northpond/nelnet/... or extend the sync + rule prefixes.

FIELD COMPARISON vs what we consume today:
- Current FCC positions (silver.northpond_stmt_positions) reads NAMED CSV columns incl. OriginalFicoScore/UpdatedFicoScore(+dates), ChargeOffDate, ChargedOffPrincipalAmt, PrincipalRecoveredAmt/InterestRecoveredAmt/LateFeeRecovered/NsfFeeRecovered, CumulPrincipalPmtLTD/CumulInterestPmtLTD, Beginning/EndingPrincipalBalance, Beginning/EndingTotalBalance, Next*DueDate, LoanState, BoardingDate, ContractDate, APR, InterestAccrualMethod.
- Velocity DF2 sample: profiled all 99 populated fields across 148 rows — NO field holds a FICO-range value (300-850). No charge-off/recovery values either. CAVEAT: the sample is 148 newly-originated loans (statuses only 'repayment'/'active'/'paid in full'), and 234 of 333 fields are empty, so those columns may exist positionally but be unpopulated for this cohort. Cannot distinguish 'absent from layout' vs 'empty for this cohort' without the record layout — reinforces that the DF2 spec is blocker #1.
- Current FCC transactions (silver.northpond_stmt_transactions) reads TransactionId, TransactionDate, EffectiveDate, RemittedDate, SourceCode/Desc, TransactionCode/Desc, Amount, BalanceImpactCode, ReversalIndicator, ReversalReason.
- Nelnet transaction file has NONE of: TransactionId (no idempotency/dedup key), ReversalIndicator/ReversalReason (reversals matter for cashflow correctness), RemittedDate, or the SourceCode/TransactionCode taxonomy — only 3 coarse Transaction Types (DISBURSEMENT/INTERESTACCRUAL/PAYMENT). This is a material downgrade in transaction fidelity and is the second big ask for Nate.
