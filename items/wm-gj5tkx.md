---
id: wm-gj5tkx
type: task
title: Ingest Oliv's Nelnet loan + transaction files (new servicer, replaces FCC feed; carries investor tag)
status: active
priority: p2
size: l
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [relates:wm-5z3pjt, relates:wm-nwvcg9, parent:wm-d7m3xz]
refs: [DEV-1481=https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction]
created: 2026-07-28T11:49:54Z
updated: 2026-08-14T19:56:16Z
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
- 2026-08-12T16:36Z [claude-code] UPDATE 2026-08-12 after reading the Nate/Abhishek call transcript + consolidated discussion points (both in ~/Downloads, dated 2026-08-12). This resolves most of the blockers logged earlier today and adds two new risks. Read this entry as superseding parts of the 15:28Z entry.

BLOCKERS THAT ARE NOW GONE
1. Velocity DF2 record layout — NO LONGER NEEDED. Decision taken: EF does not ingest PII, so Oliv will deliver a truncated, PII-free file. Nate already produces exactly this shape for other loan buyers ('we are ingesting the file and then I'm saying here's 20 columns from that file that is what we're going to export into a CSV and give to you every day'). A sample is already in Slack (the skinnier 'oliv financial loan_' file). That kills the 333-unnamed-positional-field problem outright.
2. The new headerless/pipe-delimited FileConfig — NOT NEEDED if the delivered file is a named-column CSV. Existing S3CsvFile handles it as-is.
3. The PII code changes I scoped this morning (positional stripping + extension dispatch in strip_statement_pii.py) — NOT NEEDED for the go-forward feed. See [[wm-8dy9jr]], which now narrows to cleaning up the files already sitting in efp-raw.
4. Historical backfill — NOT A CONSTRAINT. Abhishek's call: Oliv is highly accessible (EdgeFocus acquired Oliv), so we can simply ask them to re-drop historical Nelnet position/transaction files and rebuild rather than reconstruct from the 13 daily files we happen to hold. Also relevant: the EDGEX deal only started ~2026-08-11 (first purchase file), so the window that actually has to be right is short.

CORRECTION TO MY OWN EARLIER READ ON INV103
This morning I logged 'INV103 does not discriminate fund, do not build fund logic on it'. The finding was right but the reason was wrong. Nate explained INV103/104/105/106 are COLLATERAL / BUYBACK / WITHHOLDING buckets, not investors or funds: 'the only reason we have these INV 103, 104, 105, 106 is for collateral issues or like buybacks or things where we need to withhold loans'. So one tag spanning both efhyf and edgex20261NN is EXPECTED, not a defect. The authority for fund/ownership is the PURCHASE TAPE plus its effective purchase date. Macquarie is INV101 and is a separate program.

NATE'S DATA MODEL, CONFIRMED AGAINST PROD — the union design is safe
Nate stated the invariant: issuance = FCC population + Nelnet population, disjoint, one active loan per customer and one servicer per active loan. Verified as of 2026-08-11:
  issuance universe 1079 | FCC positions 715 | Nelnet positions 353 | in BOTH servicers 0 | Nelnet loans missing from issuance 0 | in issuance only 11
The 11 break down as 9 issued on 2026-08-11 (the boarding lag Nate described — 'there can be a few day delay to get into the NN file but once there it's always there') and 2 genuine orphans first seen 2024-11-26 and 2025-06-14, which are worth a question to Nate but are not blocking.
715 + 353 + 11 = 1079 exactly. This gives us a permanent DQ assertion: issuance == FCC UNION Nelnet, with the two servicing sets disjoint.
Existing FCC loans are NOT being migrated to Nelnet; they wind down naturally, or a future refinance program closes the FCC loan and opens a new Nelnet one.

NEW RISK 1 — ACCRUED INTEREST IS STALE, AND I QUANTIFIED IT
Nate flagged that Nelnet refreshes accrued interest just-in-time (on a payment, or at month end), never daily, and that the file carries an 'interest accrued through date'. That field is POSITION 22 in the DF2 layout. Measured on the 2026-08-12 file (353 loans):
  within 1 day: 25 loans (7%) | 2-7 days stale: 217 | 8-30 days stale: 111 | median staleness 5 days, max 23 days
Across the 12 August files the max staleness climbs monotonically (12 days on 08-01 to 23 days on 08-12) because the last month-end refresh recedes.
IMPACT: silver.positions.ACCRUED_INTEREST maps off p.CURRENTINTEREST and silver.transfers.INTEREST likewise. If Nelnet is mapped the same way as FCC, ~93% of the Nelnet book carries stale accrued interest with no indication. At minimum the 'through date' must be carried into the silver layer so downstream can tell. Oliv has a live accrued-interest API job (daily ~5am their time, running only a couple of weeks) and can supply an augmented file — that is the real fix, agreed as second priority.

NEW RISK 2 — THE OWNERSHIP BOUNDARY IS NOT IMPLEMENTED FOR NELNET-SHAPED TRANSACTIONS
Nate: the purchase file's effective date is the boundary. 'That is when all the accrued interest, the position and all transactions going forward become EDGEX's. Any transactions before that or accrued interest are Oliv's.' Nelnet loans are originated and then purchased days or weeks later, so the transaction file legitimately contains PRE-PURCHASE activity. Census across the 12 August transaction files (781 rows): INTERESTACCRUAL 368, PAYMENT 215, DISBURSEMENT 192, PAYMENTREVERSAL 4, ADJ-INTERESTACCRUAL 2.
northpond/transactions.py today hardcodes TRANSACTION_TYPE='payment' for every surviving row and applies NO purchase-date filter — it only drops BalanceImpactCode 'LA' and a list of write-off/suspense descs, which are FCC-specific concepts that do not exist in the Nelnet file. Mapped naively, the 192 DISBURSEMENT rows (pre-purchase origination events) and 370 accrual rows (not cash movements at all) would be emitted as EF payments.
Required mapping: PAYMENT -> payment; PAYMENTREVERSAL -> negate; DISBURSEMENT -> drop or model as origination, never a payment; INTERESTACCRUAL / ADJ-INTERESTACCRUAL -> drop, non-cash. Plus a purchase-date floor per loan.

NEW RISK 3 — PURCHASE FILES ARE ABOUT TO BE BACKDATED
Nate: 'we are actually about to backdate some files which I should make sure you're comfortable with.' Since the purchase effective date drives both fund assignment and the ownership boundary above, backdating will retroactively move loans between funds and change which transactions are ours. Anything we build must be safe to re-derive, and we need to know which files and what dates before relying on them.

STILL OPEN, UNCHANGED
- No FICO anywhere in the Nelnet feed. Since Oliv is specifying the truncated file NOW, this is the moment to ask whether Nelnet holds a score at all — if it is not in the raw file it is not recoverable from the truncated one either, and issuance carries Clarity/Prism but not FICO.
- No TransactionId, so no idempotency key; 5 transaction keys repeat across the 12 August files. Backfill lets us rebuild but does not fix daily dedup.
- NonCash='Non-Cash' on 210 of 215 PAYMENT rows (only 5 are 'Cash') — still unexplained and still worth asking.
- Rpt Date is consistently file date minus 1, so a -1 as_of offset is needed.

AGREED PRIORITY ORDER FROM THE CALL
P1 ingest Nelnet positions + transactions (Abhishek committed to 'by tomorrow, highest priority').
P2 support two new issuance V2 columns Nate is deploying: loan_servicer, and current-or-intended-investor. Nate asked Abhishek to confirm the exact string for the EDGEX fund by end of day — Abhishek wants an underscore between 2026 and 1N, and Nate prefers lowercase snake case. THAT CONFIRMATION IS STILL OWED.
P3 resolve the accrued-interest architecture (stale warehouse value vs live API join).
P4 clean up V0/V1/V2 duplication and the date-based cutover hack.
P5 the broader Oliv-EF integration architecture, deferred.
Sweep file: explicitly deferred, EF does not need it now.
Purchase tape: servicer-agnostic, one tape, no Nelnet-specific variant. V1 is the forward version; V0 to be deprecated; transition can wait.

REVISED EFFORT: with a named-column PII-free CSV, bronze parsing rules are ~half a day, the two nelnet stmt_ tables ~1 day, the union into standardized positions/transactions/transfers ~2 days, DQ + backfill ~1-2 days. Roughly a week. Bronze landing 'by tomorrow' is realistic; a correct standardized layer with the ownership boundary and accrued-interest handling is not.
- 2026-08-13T10:24Z [claude-code] WITHDRAWN + ARCHITECTURE DECISION 2026-08-12 (Abhishek challenged the finding and was right).

WITHDRAWN — 'the ownership boundary is not implemented'. It IS implemented and has been working on FCC all along. FUND_WITH_PURCHASE_TAPE_EXPR in northpond/constants.py is literally IFF(loan IN (SELECT LOAN_ID FROM silver.northpond_stmt_purchase_tapes WHERE TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE), 'efhyf', <fund mapping fallback>). That is the purchase-date boundary, evaluated per row per as_of_date. Prod confirms it: silver.transactions for northpond holds 18,021 rows tagged experimental (pre-purchase) vs 62,382 tagged efhyf (post-purchase), plus 12 northpond_balancesheet rows. The FCC tape also covers the full issuance universe including never-purchased loans, so this was never Nelnet-specific and was solved before Nelnet existed. Do not re-raise it.

WHAT SURVIVES, narrower and unrelated to ownership: transaction TYPE mapping. northpond/transactions.py hardcodes TRANSACTION_TYPE='payment' and filters on BALANCEIMPACTCODE='LA' plus a write-off/suspense TRANSACTIONCODEDESC list. Nelnet has NEITHER column, so DISBURSEMENT (192 rows) and INTERESTACCRUAL/ADJ-INTERESTACCRUAL (370) would flow through as EF payments. NOTE this hazard only exists under the stmt-layer-union design I proposed in the 15:28Z entry; under the design actually chosen (below) the Nelnet type mapping is written natively and it never arises.

ARCHITECTURE DECIDED (Abhishek's, supersedes my stmt-layer-union proposal): per-servicer position/transaction queries, each joined to the COMMON purchase tape + issuance files (which both servicers share and we already ingest), unioned into the standardized layer. Keeps each servicer's schema honest instead of forcing Nelnet into FCC column names and lying with NULLs.

CONSTRAINT FOUND WHILE VALIDATING THAT DESIGN — silver.positions has NO SOURCE column. Verified against PROD INFORMATION_SCHEMA: the only candidate discriminators are PLATFORM, ACCOUNT_ID, FUND. And northpond/positions.py sets target_table_where_clause = "platform = 'northpond'" with target_stream_group_by = ["platform","fund"], so a SECOND transform writing northpond rows would clobber the first. FUND cannot discriminate servicer either, because Nelnet loans span both funds (79 purchased -> efhyf, 274 unpurchased -> experimental).
  => For POSITIONS the union must happen INSIDE ONE transform: a single writer whose SOURCE_QUERY is the FCC leg UNION ALL the Nelnet leg, each mapping its own native columns before the union.
  => For TRANSACTIONS two separate transforms are fine, because silver.transactions HAS a SOURCE column and already carries three northpond writers (northpond_stmt_transactions, northpond_stmt_positions, northpond_balancesheet).
  => RECOMMENDED: add an explicit servicer column to silver.positions. Nate is adding loan_servicer to issuance V2 anyway (see [[wm-3s3nkt]]), so it becomes a real source column rather than an inference from file membership, and it supplies the discriminator we currently lack.

ALSO AGREED THIS ROUND
- Accrued-interest staleness is NOT an implementation risk: the fix (Oliv's live-API augmented file) is already agreed in the transcript and sits at P3 behind ingestion. Only ask now is to carry the interest-accrued-through date (DF2 field 22) into silver from day one so it is a column, not a later backfill.
- Purchase-file backdating: parked until Nate says which files and what dates. Transforms are already re-derivable.
- No TransactionId is solvable BECAUSE Oliv can re-drop history: do not append incrementally, re-derive a trailing window (~30 days) nightly so restatements self-correct and dedup stops being a correctness problem.
- NonCash: do not gate any cash logic on it. 210 of 215 PAYMENT rows are 'Non-Cash' and only 5 are 'Cash', which reads like a warehouse accounting flag rather than a cash indicator. Question for Nate, not a blocker.
- 2026-08-13T12:04Z [claude-code] IMPLEMENTATION STARTED 2026-08-13 (DEV-1481). Branch abhishek/dev-1481-ingest-olivs-nelnet-servicer-files-loan-transaction, cut from origin/master f3301c2cb6, in ~/claude-ws/dev-1481/efp (my own workspace, not ~/repos). NOT COMMITTED YET — changes sit in the working tree pending Abhishek's go-ahead.

WHAT LANDED — the Nelnet TRANSACTION feed, end to end through the stmt layer:
1. bronze/platform_configs/northpond.py — first pii_columns entry for northpond: {"v_transaction_detail_export_daily_olivfinancial_*.xlsx": ["Last Name"]}. Routes the transaction export to efp-pii and publishes a _CLEANED sibling to efp-raw. The DF2 loan tape is deliberately NOT listed (headerless/positional/no extension — the stripper cannot act on it; Oliv is fixing it at source).
2. bronze/parsing_rules/northpond.py — three rules: (a) northpond_nelnet_transactions matching only the _CLEANED.xlsx, statement_type='nelnet_transactions', S3XlsxFile on sheet NSTTRANDETDLY, as_of_date_offset=-1, monitoring_schedule=None; (b) ignore rule for the RAW xlsx, anchored on trailing _\d{8}_\d{6}\.xlsx so it cannot also swallow the _CLEANED sibling (this is the happymoney NoSuchKey-lockout guard); (c) ignore rule for the whole nelnet/daily_loan/ prefix so the DF2 files stop accumulating at status='unknown'.
3. NEW silver/statement_rows/northpond/stmt_nelnet_transactions.py — NorthpondStmtNelnetTransactions -> silver.northpond_stmt_nelnet_transactions. 17 ColumnDefs. Follows the marlette_stmt_fortress_purchase_tapes precedent (sibling source table, not a replacement). Two deliberate omissions vs the FCC feed, both documented in the module docstring: no FUND column (FUND_WITH_PURCHASE_TAPE_EXPR keys on the Oliv loan number, which this file does not carry) and no transaction id (Nelnet ships none).
4. orchestration/assets/northpond_assets.py + orchestration/jobs/statements_northpond.py — asset registered and wired into the statements_northpond job.
5. bronze/platform_configs/base_test.py — updated the two guard tests that assert which platforms have PII config; northpond moves from the no-PII set to the PII set.

VERIFIED, not assumed:
- Rule routing: raw xlsx -> ignored; _CLEANED xlsx -> northpond_nelnet_transactions; DF2 loan file -> ignored; FCC loan tape -> still matches northpond_loan_positions unchanged.
- The -1 offset resolves a file dated 2026-08-12 to as_of_date 2026-08-11, which matches that file's actual Rpt Date. platform_as_of_date correctly retains 2026-08-12.
- PII path: ran the real strip_statement_pii._strip_pii_from_file over the real 2026-08-12 xlsx with the real config. Last Name is dropped, the other 17 columns survive, 33 rows intact.
- Column mapping: every one of the 17 ColumnDef source keys is present in the cleaned record, and zero columns are left unmapped. The 'Eff Date ' source key carries a TRAILING SPACE in the servicer header — that is real and is now covered by a comment.
- Generated SQL inspected and well-formed.
- ruff format + ruff check clean; mypy clean; 613 bronze tests pass; 285 northpond-silver + orchestration tests pass.

NOT DONE, deliberately:
- The Nelnet POSITIONS feed. Blocked on Oliv's PII-free replacement for the DF2 tape (Nate, ~1 day). Writing a column mapping against a schema that is about to be replaced would be throwaway. The ignore rule keeps those files quiet meanwhile.
- The standardized leg (silver.northpond_stmt_nelnet_transactions -> silver.transactions). It needs the Nelnet-number -> OLV-number bridge, which only the loan tape supplies, so it follows positions.
- Monitoring for the transaction rule is intentionally off (monitoring_schedule=None): enabling it before the PII cutover would fire missing-file alerts across the whole pre-cutover back-range.

CARRIED FORWARD FOR [[wm-8dy9jr]] — a precise finding: setting pii_columns fixes FUTURE files only. strip_pii_to_raw iterates keys in efp-pii and deletes an efp-raw copy only when the same key also exists in efp-pii. The 13 DF2 files already sitting in efp-raw were routed there when pii_columns was empty, so nothing in efp-pii corresponds to them and the cleanup pass will never touch them. They need a manual move to efp-pii (after which the stripper deletes the raw copies) or an outright purge. That is still Abhishek's call.

DEV-1481 DESCRIPTION IS STALE on two points and should be corrected: (1) it lists transaction-on-board as a third servicer feed to move, but Nelnet delivers only two files (daily_loan, daily_transaction) — there is no NN transaction-on-board equivalent; (2) it says 'run both feeds side by side, reconcile them, then retire the FCC feeds', but Nate confirmed FCC loans are NOT migrating — they stay on FCC and wind down naturally, so the two feeds run permanently side by side over disjoint loan sets.
- 2026-08-13T12:34Z [claude-code] PR OPENED 2026-08-13: https://github.com/edgefocus/efp/pull/6262 — 'DEV-1481: Ingest the Nelnet daily transaction export with efp-pii routing'. Branch abhishek/dev-1481-ingest-olivs-nelnet-servicer-files-loan-transaction, 6 files, +222/-2, base master. Covers the TRANSACTION feed only; positions still waits on Oliv's PII-free replacement for the Velocity DF2 tape.

PR body states explicitly that there is NO Snowflake proof in this PR and why: no _CLEANED file exists in S3 until this pii_columns entry ships and the strip pass runs, so the table cannot be populated pre-merge. Row-level validation + the DAG screenshot are promised in the positions PR. Flagged per the pr-style rule about never merging with 'validations pending' unless you say exactly what is unvalidated and where it is tracked.

NOTE FOR ANY AGENT COMMITTING ON dpx: /tmp is NOT writable by this user (writes fail with Permission denied) AND it contains stale files left by other sessions. 'cat > /tmp/cmsg.txt' silently failed and 'git commit -F /tmp/cmsg.txt' then picked up ANOTHER session's leftover message file, producing a commit titled 'Regenerate models_by_channel_history_git.py'. Caught before the PR existed; fixed by amending with a message file under ~/claude-ws/ and force-pushing with --force-with-lease pinned to the inspected remote tip (3d023dd41c, which was my own commit from two minutes earlier, no other agent's work on the branch). Write commit-message files under ~/claude-ws/, never /tmp.
- 2026-08-13T12:56Z [claude-code] PR #6262 RESCOPED 2026-08-13 on Abhishek's direction — transactions only. Removed the parsing rule that ignored the nelnet/daily_loan/ prefix: it was positions-scoped and did not belong in a transactions PR. Those DF2 files go back to sitting at status='unknown', which is also the more honest signal that positions work is still pending. Now 6 files, +203/-2. Re-verified after the change: raw xlsx ignored, _CLEANED parsed, DF2 matches no rule, FCC loan tape unchanged; 613 bronze tests still pass.

CLARIFIED A MISREADING WORTH KEEPING: the pii_columns entry is scoped to the TRANSACTION export only ('v_transaction_detail_export_daily_olivfinancial_*.xlsx': ['Last Name']). It is NOT the positions file — the DF2 tape is deliberately excluded because the stripper matches by column name and dispatches on file extension, and DF2 is headerless with no extension. Nate's PII commitment likewise covers only the LOAN TAPE (SSN/DOB/address/phone/email/bank routing); the transaction export was never in scope for it and still ships Last Name. The entry cannot simply be dropped on the grounds that 'Nate is removing PII', because RAW_RECORD is persisted wholesale in both bronze.statement_rows and the stmt table — a transform declining to select the column would still store it.

NEW FINDING, PROVEN AGAINST PROD — the standardized silver.transactions leg genuinely cannot be built yet, and this is now evidenced rather than asserted. Checked every candidate table's columns via PROD INFORMATION_SCHEMA: northpond_stmt_issuance.LOAN_ID is the Oliv number, northpond_stmt_purchase_tapes.LOAN_ID is the Oliv number, northpond_stmt_issuance_v2.OLIV_LOAN_NUMBER is the Oliv number. NOTHING we hold carries Nelnet's 12-digit servicer loan number. EFP_ID/POSITION_ID are 'northpond_' || <OLV>, so the bridge is mandatory and it exists ONLY on the Nelnet loan tape (field 1 <-> field 39).
=> Therefore the standardized leg follows EITHER the loan tape OR an added OLV column on the transaction export. The second option is far cheaper and would decouple transactions from positions entirely. It was ask #4 in the original 2026-07-28 list to Nate and has never been answered — and Nate is actively rebuilding these exports right now, so this is the moment to re-raise it.
- 2026-08-13T17:40Z [claude-code] SCHEMA CHANGED 2026-08-13 ~22:00 IST — Oliv replaced BOTH Nelnet feeds with PII-free named-column CSVs, delivered as samples in the DM. PR #6262 reworked against them and force-pushed (now 4 files, +169/-0, purely additive; was 6 files +203/-2).

NEW TRANSACTION FORMAT: olivfinancial_transaction_YYYYMMDD.csv, 13 cols, lowercase, ISO dates:
transactionid, lendername, investornumber, borrowernumber, loannumber, transactiontype, noncash, effdate, rptdate, tranamt, principal, intamt, intpaid.
GAINED transactionid — the idempotency key I previously recorded as absent. CORRECTION TO MY OWN EARLIER FINDING: the '5 repeated transaction keys across daily files' logged on 2026-08-12 was an ARTIFACT of the missing id, not restatement. Loan 577145898542 appears as PAYMENT (id 2966) on 08-12 and PAYMENTREVERSAL (id 3010) on 08-13 — two distinct transactions. The trailing-window rebuild I recommended is NOT needed.
LOST vs the xlsx: Last Name (so NO PII — the whole efp-pii routing, the pii_columns entry and the base_test.py guard change all came back out of the PR), Loan Program, and the LF/OF fee columns. The fee loss costs nothing today (we zero those anyway) but was an upgrade over FCC and is worth asking back since it exists at source.
rptdate is still filename date minus 1, so as_of_date_offset=-1 still verified correct.

NEW LOAN/POSITIONS FORMAT: olivfinancial_loan_YYYYMMDD.csv, 56 named columns, 374 rows, NO PII (no name, SSN, DOB, address, phone, email, bank details), ISO dates, snake_case. This retires the 333-field positional Velocity DF2 problem entirely.
ALL 15 must-have fields are present, including three I had recorded as missing or uncertain:
  - current_apr — APR IS in the file after all
  - interest_accrued_to_date — the staleness field, confirmed present
  - days_past_due, original_term, remaining_term — all explicit
  - loan_external_reference_id = the OLV number (the bridge), loan_number = Nelnet's
Still absent and handled as agreed: charge-off (derive from loan_status='charge off'), bankruptcy (current_loan_period_reporting_status='Bankruptcy Deferment'), FICO (use our own VantageScore).
IMPORTANT OFFSET DIFFERENCE: the loan file carries file_date = its OWN filename date (2026-08-13), so it needs NO as_of offset — unlike the transaction file's -1. Do not copy the -1 across.

TWO DATA ISSUES TO RAISE WITH NATE:
1. current_investor_number = 'INV101' on ALL 374 loan rows, while the SAME-DAY transaction file reports INV103/none. The old DF2 file reported INV103 on 179/353. Nate said on the call that Macquarie is INV101, so all-INV101 looks wrong. Three sources disagreeing reinforces that investor number must NOT drive fund attribution.
2. Ten columns carry the literal string 'NULL' rather than being empty (communcation_suppression, communcation_suppression_suppression_effective_date, is_cease_and_desist_active, cease_and_desist_effective_date, scra_flag_*, death_flag_active, disability_flag_*). VARCHAR mappings would store the four-character string "NULL" unless we coerce. Note also the source column name typos we must mirror verbatim: 'communcation' (missing the i) and the doubled 'suppression' in column 34.

Sample saved at ~/nelnet_look/olivfinancial_loan_20260813.csv on dpx for the positions work.
- 2026-08-13T18:02Z [claude-code] STANDARDIZED TRANSACTIONS LEG ADDED 2026-08-13. PR #6262 now runs bronze -> silver.transactions end to end for the Nelnet transaction feed. 7 files, +376/-15.

KEY DESIGN CHANGE driven by Abhishek's update mid-build: Nate agreed to put BOTH loan numbers in issuance_v2, so the bridge comes from silver.northpond_stmt_issuance_v2 (SERVICER_LOAN_NUMBER = Nelnet's, OLIV_LOAN_NUMBER = ours) and the standardized leg does NOT depend on the Nelnet loan tape at all. That decouples transactions from positions entirely — the thing we had been trying to achieve since the original ask #4 on 2026-07-28. Added SERVICER_LOAN_NUMBER and ISSUANCE_DATE ColumnDefs to stmt_issuance_v2.py.
The join is INNER by design: a transaction whose loan is not yet in issuance_v2 is held back rather than emitted against a wrong or NULL EFP_ID. CONSEQUENCE TO WATCH: until Oliv actually ships servicer_loan_number the transform emits ZERO rows. That is intentional, but if someone sees an empty table this is why.

VALIDATED, not assumed — the amount identity TRANAMT = -PRINCIPAL + INTPAID holds on ALL 17 PAYMENT rows and the 1 PAYMENTREVERSAL row across both delivered samples, and fails only on INTERESTACCRUAL (where the amount sits in INTAMT and principal/intpaid are 0). PRINCIPAL_AMOUNT and INTEREST_AMOUNT are built on that identity. Only PAYMENT and PAYMENTREVERSAL are emitted; INTERESTACCRUAL, ADJ-INTERESTACCRUAL and DISBURSEMENT are dropped as non-cash, mirroring the FCC leg dropping BalanceImpactCode 'LA'.

REFACTOR WORTH KNOWING ABOUT: northpond/constants.py gained fund_with_purchase_tape_expr(loan_id_expr, as_of_expr, account_column). The Oliv loan number arrives under a different name on every feed (raw 'LoanNumber' on FCC, OLIV_LOAN_NUMBER on issuance_v2), so the FUND expression had to be parameterised. FUND_WITH_PURCHASE_TAPE_EXPR now derives from the function and was ASSERTED BYTE-IDENTICAL to master's string before committing, so the FCC positions/transactions transforms are provably unchanged.

ACCOUNT_ID deliberately mirrors the FCC leg (t.ACCOUNT_NAME, the raw statement account) rather than deriving from FUND, so the two sources stay reconcilable in silver.transactions. Both legs should move together when DEV-1522 / [[wm-7mtzka]] switches northpond to fund-derived account_id — do not fix one without the other.

898 tests pass across bronze, northpond silver and orchestration; ruff and mypy clean.

STILL NOT BUILT: the Nelnet loan/positions feed. The sample landed 2026-08-13 (olivfinancial_loan_20260813.csv, 56 named columns, saved on dpx) and ColumnDefs were generated from the real header, but that work belongs in its own PR. Two things already learned for it: the loan file needs NO as_of offset (its file_date equals its filename date, unlike the transaction file's -1), and identifier columns must be typed VARCHAR not INT so loan_number joins cleanly.
- 2026-08-13T18:31Z [claude-code] POSITIONS PR OPENED: https://github.com/edgefocus/efp/pull/6277 'DEV-1481: Ingest the Nelnet daily loan tape into silver', STACKED on the transactions PR #6262 (base = abhishek/dev-1481-ingest-olivs-nelnet-servicer-files-loan-transaction, branch abhishek/dev-1481-nelnet-positions). Review #6262 first.

Contents: parsing rule for olivfinancial_loan_YYYYMMDD.csv (statement_type nelnet_positions), an ignore rule for the superseded raw Velocity DF2 export, and NorthpondStmtNelnetPositions -> silver.northpond_stmt_nelnet_positions with all 56 source columns plus a derived FUND. Asset + job wired.

VERIFIED: 56/56 columns mapped with 0 unmapped and 0 references to non-existent columns, checked against the real file Oliv delivered. Routing confirmed: new loan CSV -> northpond_nelnet_positions as_of 2026-08-13, legacy DF2 -> ignored, transaction CSV still -> northpond_nelnet_transactions as_of 2026-08-12. 898 targeted tests pass. The parent PR's FULL edgefocus/transformations/ sweep also came back green: 2524 passed, 1 skipped, 480s — that clears the fund_with_purchase_tape_expr refactor across every platform, not just northpond.

THREE TRAPS HANDLED, each of which would have failed silently:
1. NO as_of offset on the loan file (file_date == filename date) versus -1 on the transaction file. Copying the offset across would shift every position by a day.
2. LOAN_NUMBER and BORROWER_ACCOUNT_NUMBER forced to VARCHAR, not INT, so LOAN_NUMBER joins the transaction feed's LOANNUMBER without a cast.
3. Thirteen columns arrive as the literal four-character string 'NULL'; _null_coerced() maps them to real NULLs or we would store the word. Also mirrored two source-side column-name typos verbatim ('communcation', doubled 'suppression') since they are the RAW_RECORD keys.

FUND IS derived on this table (unlike the transaction feed) because the loan tape carries the Oliv number directly as loan_external_reference_id — reuses fund_with_purchase_tape_expr() so it agrees with the FCC leg loan for loan.

STILL TO COME (documented as follow-ups on the PR): the standardized silver.positions union, which needs DECISIONS not plumbing — credit score (Nelnet has none; VantageScore recoverable from our own gateway events for ~84%), charge-off derivation from the loan_status run, and whether REMAINING_TERM stays actuarial or takes the servicer's value. Also silver.transfers and northpond_transactions_service_fees both read silver.northpond_stmt_positions directly and will each need the Nelnet leg added explicitly.
- 2026-08-13T19:09Z [claude-code] CONSOLIDATED INTO ONE PR 2026-08-14 on Abhishek's instruction. https://github.com/edgefocus/efp/pull/6277 retargeted to master, 13 files +915/-27, now carries BOTH feeds bronze-through-standardized. #6262 closed as superseded.

WHY ONE PR, recorded so it is not re-split later: splitting by FEED (transactions vs positions) cut straight through the asymmetry. gold.positions_daily FULL OUTER JOINs the positions and transactions aggregates by (as_of_date, platform, fund) — deliberately, so post-charge-off recoveries still produce a row. So had transactions merged without positions, Nelnet cashflow would have landed in the SAME fund buckets (efhyf/experimental/edgex20261NN) as FCC-only exposure, with no error and no null — just a silently inflated numerator on any yield or ROI ratio. Splitting by LAYER, or not at all, is the seam that holds.

ARCHITECTURE: NORTHPOND_POSITIONS_UNION in northpond/constants.py projects the Nelnet feed into the FCC column vocabulary and unions the two. positions.py, transfers.py and transactions_service_fees.py all read it instead of the bare FCC table, so a future consumer picks up both feeds by construction. This is the marlette_stmt_fortress_purchase_tapes pattern applied one level up — and it is what resolves the four-consumer problem logged earlier.

TWO REAL BUGS FOUND WHILE WIRING, both silent-failure class:
1. northpond_transactions_itd and northpond_positions_daily aggregate silver.transactions per PLATFORM, not per source, but waited only on the FCC leg. Both now depend on northpond_nelnet_transactions. Left alone they could materialize first and understate ITD sums, which northpond_positions then consumes.
2. transactions_service_fees filtered WHERE LOANSTATUS = 'Current' — FCC vocabulary. Nelnet says 'repayment'. NO NELNET LOAN WOULD EVER HAVE ACCRUED A SERVICE FEE. Now accepts both; FCC behaviour deliberately unchanged (the other FCC statuses mapping to 'current' stay excluded as before).

DERIVED, not passed through: charge-off date + charged-off principal from the LOAN_STATUS = 'charge off' run (LAG marks the transition, LAST_VALUE carries it forward; principal taken from the row BEFORE the flip since servicers write the balance down at charge-off). IN_BANKRUPTCY from CURRENT_LOAN_PERIOD_REPORTING_STATUS = 'Bankruptcy Deferment', with the filing DATE left NULL rather than fabricated. FICO left NULL — Nelnet ships no score.

Nelnet status values added to NORTHPOND_STATUS_MAP (repayment/paid in full/charge off/deferred). They are lowercase and FCC's are PascalCase, so the two vocabularies are disjoint and one map serves both feeds. Without this every Nelnet row would map to 'unknown' and fail validation.

THREE EXISTING TESTS UPDATED, deliberately not re-pointed blindly: transfers_test x2 and transactions_test x1 asserted the bare FCC table name / the 'Current'-only filter. Replaced with stronger assertions that BOTH feeds are present and that the fee filter spans both vocabularies.

VERIFIED: 13/13 transaction columns and 56/56 positions columns mapped, 0 unmapped, 0 dangling refs; every column the three union consumers reference is emitted by the union (checked programmatically); TRANAMT = -PRINCIPAL + INTPAID holds on all 17 PAYMENT rows + the reversal; fund_with_purchase_tape_expr refactor asserted byte-identical to master. ruff + mypy clean over 20 files, 898 targeted tests pass. Full edgefocus/transformations/ sweep was green (2524 passed) before the standardized layer went in and is re-running now.
- 2026-08-14T13:52Z [claude-code] FILE NAMES AND GO-LIVE DATE LOCKED 2026-08-14 (Nate DM, D0BAD46CT27, 01:33-02:05 IST).
This is the last open design question on the feed; what remains is landing the PR.

NAMING — SETTLED. Abhishek asked Nate to rename the PII-free files to a single-date-token form
because the current names carry two or three date/time tokens and we parse the as-of date out of
the key:
  nelnet/daily_transaction/2026/08/V_Transaction_Detail_Export_Daily_OlivFinancial_2026-08-13-05-28-55_20260813_060201.xlsx
  nelnet/daily_loan/2026/08/VELOCITY_SERVICING_DF2_20260813_20260813_030224.
He proposed nelnet_positions_YYYYMMDD.csv / nelnet_transaction_YYYYMMDD.csv; Nate countered with
the names already used in the samples, and Abhishek accepted them verbatim:
  nelnet/daily_loan/YYYY/MM/olivfinancial_loan_YYYYMMDD.csv
  nelnet/daily_transaction/YYYY/MM/olivfinancial_transaction_YYYYMMDD.csv
Same paths as today, one date token, and Nate confirmed "we would have a singular date / the
schema would be as the samples provided are".
NO CODE CHANGE NEEDED: PR #6277 already parses exactly these names — verified in the diff of
edgefocus/transformations/bronze/parsing_rules/northpond.py, which registers
northpond_nelnet_positions on olivfinancial_loan_(?P<date>\d{8})\.csv and
northpond_nelnet_transactions on olivfinancial_transaction_(?P<date>\d{8})\.csv, plus ignore
rules for the superseded VELOCITY_SERVICING_DF2_* and V_Transaction_Detail_Export_*.xlsx keys.

GO-LIVE — MONDAY 2026-08-17 (target, not a commitment Nate has confirmed in those words).
Nate: "Any concerns if this is live next week?" and "We typically try to avoid deploys Thursday
evening into the weekend." Abhishek: "Ingestion is dev ready on our end, so just let us know when
they start flowing" and "I think we should be good to wait till Monday." So the cutover is
Oliv-side and we are waiting on their signal.

BACKFILL — AGREED IN PRINCIPLE, DATE NOT SET. Abhishek: "I think it'd be a good idea to backfill
both the loan and transaction files in the new format from the day we received the first purchase
file" (that is 2026-08-11, purchase_file_v0_20260811.csv). Nate: "We can definitely backfill after
we go live." Tracked as [[wm-4mhcgw]].

STILL LANDING IN THE OLD FORMAT AS OF TODAY: s3 shows VELOCITY_SERVICING_DF2_20260814_* and
V_Transaction_Detail_Export_..._20260814_*.xlsx both arrived 2026-08-14 12:38. Nothing has cut
over yet, and the PII exposure keeps growing until it does — see [[wm-8dy9jr]].

PR #6277 STATE 2026-08-14: OPEN, mergeStateStatus BLOCKED (branch protection, not conflicts),
reviewDecision REVIEW_REQUIRED — no human has reviewed it since it was opened 2026-08-13. Head is
113fd3a "Fix nested window functions and align the transaction as-of date", which resolves the one
HIGH finding Sentry's bot raised on the PR (LAG() nested inside LAST_VALUE() in
_NELNET_POSITIONS_PROJECTION — illegal in Snowflake, would have blown up the first time a Nelnet
loan charged off). The bot has marked it resolved. Landing this before the cutover is [[wm-xtyzed]].
- 2026-08-14T13:53Z [claude-code] CORRECTION to the entry immediately above (same session, 2026-08-14): I wrote two item ids before the items existed, so [[wm-4mhcgw]] and [[wm-xtyzed]] are not real and resolve to nothing. The backfill/cutover follow-up is [[wm-3vkbn9]] and the PR-landing task is [[wm-g8p2m2]]; both are now children of this item.
- 2026-08-14T13:56Z [claude-code] Fund derivation reworked and pushed (PR #6277, commit 64597180ff). FUND now prefers Oliv's issuance_v2.current_investor over the purchase-tape + hardcoded-date inference.

Verified against prod on the re-pushed 2026-08-13 issuance_v2: current_investor agrees with the purchase-tape hack on all 468 purchased loans, 0 disagreements, and additionally resolves the 648 loans absent from the tape (which all collapsed to northpond_balancesheet before).

Investor -> fund: efhyf, edgex20261NN, northpond -> northpond_balancesheet, oliv -> northpond_balancesheet (Abhishek's call; 'oliv' is 305 post-acquisition Nelnet loans with no fund of their own, and folding them in is a no-op on gold).

NORTHPOND_EDGEX_PURCHASE_START was NOT deleted - see follow-up. INTENDED_INVESTOR is projected but deliberately unused (differs from current on 131 loans; it front-runs unsold sales).

Two real defects found and fixed while doing this:
1. The 5 issuance_v2 ColumnDefs added earlier in the branch had no matching terraform columns - the transform would have failed on an invalid identifier.
2. Nelnet table column types were FLOAT/NUMBER(38,0) vs the house DOUBLE/INTEGER.

CORRECTION to the earlier CI diagnosis: the terraform apply timeout ('context deadline exceeded' on 5 pre-existing views) is NOT caused by the new .tf files. Reproduced the exact CI path (pr_database._apply_terraform against an ephemeral DB): 293 resources, 44s, clean, twice. The CI failure was environmental Snowflake API slowness in that window.
- 2026-08-14T14:16Z [claude-code] CI green on PR #6277 after the fund rework: Run Tests 9m7s pass, Run integration tests 16m51s pass, Seer pass, Select tests pass. The integration job that failed at 27m and 47m in the two prior runs now passes in 16m51s with no change to the 5 views that were timing out - confirming the local reproduction. PR is mergeStateStatus=BLOCKED only on REVIEW_REQUIRED. Ready for review.
- 2026-08-14T18:09Z [claude-code] Added the missing integration coverage (commit 131a4e85b0). The branch had none - the 4 existing northpond md tests all drive the FCC leg and pass over this change because the UNION does not disturb them, which is not the same as the Nelnet path working.

Two fixtures, both passing:
- northpond_nelnet_transactions.md (63s): built from Oliv's real 2026-08-13 sample rows. Pins the type filter, payment/reversal sign conventions, the INNER join dropping unmatched loans, no fan-out across issuance_v2 snapshots, MAX_BY taking the LATEST investor (efhyf on 08-12 -> edgex20261NN on 08-13), oliv -> northpond_balancesheet, and EFFDATE vs RPTDATE.
- northpond_nelnet_positions.md (118s): the derived charge-off columns. Seeds 4 days but processes only 2, so the earlier rows exist purely as window-function history. Pins CHARGE_OFF_DATE = first day of the run (steady on day 2), and PRINCIPAL_AT_CHARGE_OFF = 900 = the balance the day BEFORE charge-off, not the 0 the file reports.

Two corrections to my own expectations while writing these:
1. I put IS_RAW_RECORD_MODIFIED on the nelnet stmt table fixture; the validity test rejected it. The code is right - those tables deliberately do not emit it and terraform matches.
2. I expected PRINCIPAL=0 on charged-off rows; it is NULL. Checked prod before assuming a bug: across silver.positions there is not one non-NULL PRINCIPAL on a charged_off row on ANY platform (165M rows on lc). NULL is the convention; PRINCIPAL_AT_CHARGE_OFF carries the number. Fixture now pins it.

Local: 3774 unit passed, 6 northpond integration passed (4 existing + 2 new).
