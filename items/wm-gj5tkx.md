---
id: wm-gj5tkx
type: task
title: Ingest Oliv's Nelnet loan + transaction files (new servicer, replaces FCC feed; carries investor tag)
status: open
priority: p2
size: l
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [parent:wm-j523sq, relates:wm-5z3pjt, relates:wm-nwvcg9]
refs: [DEV-1481=https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction]
created: 2026-07-28T11:49:54Z
updated: 2026-08-12T15:28:55Z
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
- 2026-07-29T13:43Z [claude-code] Intake sweep 2026-07-29: no movement from Nate since the 07-28 samples. DEV-1481 was created 2026-07-28 (Todo, no priority, assigned Abhishek) and has ZERO comments, so nothing new landed on the ticket either. The outstanding piece is not analysis — that is complete in the entries above — it is the reply Abhishek promised Nate ('I will take a look at the data and compare it with what we receive as of now and get back'). Split out as [[wm-nwvcg9]] with the 9 concrete asks so it stops being buried under a large ingest item. This item stays as the ingest work, still blocked on the Velocity DF2 record layout.
- 2026-08-12T15:28Z [claude-code] FULL RE-ANALYSIS 2026-08-12 against LIVE prod data (not the July samples). Two things changed materially and one new fact reframes the whole item.

CHANGED SINCE JULY:
1. The loan file NOW CARRIES THE INVESTOR TAG. Field 40 = 'INV103' on 179 of 353 rows (in the 07-28 sample it was absent entirely). The transaction file's 'Investor Number' column is likewise now populated: 256 of 781 rows across the 12 August files carry INV103, 525 still 'none'. So the tag has started flowing but is only ~half populated on both feeds.
2. BUT INV103 DOES NOT DISCRIMINATE FUND. Of the 179 INV103-tagged loans, 79 appear on our purchase tapes and they split 50 edgex20261NN / 29 efhyf. So one investor tag spans two of our funds — the tag is necessary but NOT sufficient for fund attribution, contrary to the premise in [[wm-5z3pjt]]. Do not build fund logic on it as-is.
3. PAYMENTREVERSAL exists as a Transaction Type (4 rows) plus ADJ-INTERESTACCRUAL (2). The July sample only showed 3 types. So reversals ARE representable, just as a type rather than a ReversalIndicator flag.

THE NEW FACT THAT REFRAMES THIS ITEM — WE ARE MISSING A LIVE AND GROWING BOOK:
- The 353 loans in the 2026-08-12 Nelnet loan file have ZERO overlap with silver.northpond_stmt_positions. Not one. Confirmed against PROD.
- silver.northpond_stmt_positions (the FCC tape) has been FROZEN AT 715 DISTINCT LOANS since 2026-05-01. It has not grown in three months.
- All 353 Nelnet loans ARE in silver.northpond_stmt_issuance, first-seen 2026-05-13 through 2026-08-11. Loans issued per origination month vs how many reach FCC positions: May 14->0, Jun 30->0, Jul 144->0, Aug 174->0. Every loan originated since mid-May is serviced by Nelnet and is invisible to us downstream.
- 79 of these loans are ALREADY ON OUR PURCHASE TAPES (50 edgex20261NN as_of 2026-08-12, 29 efhyf as_of 2026-08-11). We have BOUGHT loans into EDGEX for which we hold no positions, no transactions and no transfers rows. This is a direct EDGEX ABS reporting hole, and it compounds [[wm-tvjjgw]].
- silver.positions / silver.transfers contain 0 of them.

INGESTION MECHANICS, VERIFIED IN THE REPO:
- SFTP->S3 sync ALREADY WORKS. 26 files (13 days x 2 feeds) sit in s3://efp-raw/statements/northpond/nelnet/{daily_loan,daily_transaction}/YYYY/MM/, all registered in bronze.statement_files with STATUS='unknown' and RULE_NAME=NULL. No sync work needed; only parsing rules are missing.
- Loan file S3 key ENDS IN A BARE '.' (no extension). strip_statement_pii._strip_pii_from_file dispatches on extension and returns the bytes UNCHANGED for anything that is not .csv/.xlsx, so the PII stripper is a no-op on this file even if pii_columns were configured.
- pii_columns matches by COLUMN NAME (_columns_to_drop). The DF2 file is headerless and positional, so name-based stripping cannot work on it without a layout. Both the extension dispatch and the name matching need extending.
- S3CsvFile takes a delimiter param, so pipe is free, but pd.read_csv(header=0) would eat the H| control row as a header and the F|353 footer as data. Needs a new FileConfig (headerless + names + skip control/footer rows).
- S3XlsxFile already handles the transaction file shape (single sheet NSTTRANDETDLY).

TRANSACTION FILE IS NOT A CLEAN INCREMENTAL — dedup risk is real:
- Rpt Date is consistently file date minus 1, so a -1 as_of offset is needed (existing northpond rules have no offset).
- Eff Dates lag badly: the 08-12 file carries rows with Eff Date 2026-08-02. Restatements arrive up to 10 days late.
- Across the 12 August files, 5 transaction keys REPEAT on later days (one payment on loan 577145898542 appears in the 08-06, 08-07 AND 08-12 files). With no TransactionId there is no safe idempotency key — a composite (loan, type, eff date, amounts) key is the only option and it cannot distinguish a genuine duplicate payment from a restatement.
- The 2026-08-05 file contains a single all-NULL row.

FIELD GAPS RE-CONFIRMED ON THE LARGER SAMPLE (353 loans, 107 of 333 fields populated):
- NO FICO anywhere. Profiled every field: not one holds a value in the 300-850 range. silver.positions maps FICO/CREDIT_SCORE/FICO_AT_PURCHASE/CREDIT_SCORE_AT_PURCHASE all off UPDATEDFICOSCORE/ORIGINALFICOSCORE. These go NULL for the whole Nelnet cohort.
- No charge-off or recovery fields, no cumulative LTD columns, no bankruptcy block, no APR (only note rate).
- Delinquency IS present but unlabeled: field 33 is DPD-shaped (0/7/8/28/37) and field 192 is a credit-reporting status (Current/PastDue/PaidOrClosed, populated on 163 of 353). Field 33 = 37 on the single PastDue loan, so it reads as DPD, but that is inference, not spec.
- MITIGATION AVAILABLE: silver.northpond_stmt_issuance covers all 353 loans and carries APR, interest rate, origination fee, state, income, Clarity/Prism scores and application_uuid. positions.py already joins issuance as 'i.' for APPLICATION_ID/STATE/INCOME, so several of the gaps can be sourced there. FICO is NOT recoverable from issuance.

ARCHITECTURE CONCLUSION (the cheap path):
Because the Nelnet loan set is DISJOINT from the FCC set and silver.northpond_stmt_positions.LOANNUMBER is already the OLV number (e.g. 'OLV12562766') which is exactly Nelnet field 39, the low-cost design is to normalise Nelnet rows INTO the existing silver.northpond_stmt_positions / _stmt_transactions schema and UNION them. Then positions.py, transactions.py and transfers.py need ZERO changes — EFP_ID = 'northpond_' || LOANNUMBER keeps working and the standardized layer is free. The unmappable columns land as NULL, which is a DQ question, not a modelling one.
The transaction file cannot stand alone: it keys on the Nelnet 12-digit number (field 1), so it must bridge through the loan file to reach the OLV key. That makes the loan feed a hard dependency of the transaction feed.
