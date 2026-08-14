---
id: wm-nwvcg9
type: followup
title: Reply to Nate with the Nelnet sample-file verdict + the blocking asks
status: done
priority: p1
size: xs
due: 2026-07-30
people: [Nate, Trishit]
tags: [northpond, edgex, needs-reply]
links: [relates:wm-gj5tkx, relates:wm-5z3pjt]
refs: [thread=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1785241457230439, dm=https://edgefocuspartners.slack.com/archives/D0BAD46CT27/p1786485178274189]
created: 2026-07-29T13:42:01Z
updated: 2026-08-14T13:54:23Z
source: claude-code
label: Nate Nelnet samples reply
---

Nate shared the Nelnet (Velocity) loan + transaction samples on 2026-07-28 17:56 IST in
the "NN File Sharing" thread (C0BJ1M304BU, parent ts 1785241457.230439) and asked:
"let me know if these look ~reasonable (they're 1:1 with what we receive). We can sort
through any mapping/interpretations in parallel as long as these generally/intuitively
make sense."

Abhishek replied 18:02: "I will take a look at the data and compare it with what we
receive as of now and get back." **That comparison is already done** — the full field-level
analysis is logged on [[wm-gj5tkx]] (2026-07-28 entries). Only the reply is outstanding.

What the reply needs to say (all evidenced on [[wm-gj5tkx]]):
1. Velocity DF2 record layout / data dictionary — 333 unnamed positional fields, 234 empty
   in the sample. This is blocker #1; nothing can be parsed without it.
2. "Investor Number" is `none` on every transaction row — when does it get populated?
   (This is the field that resolves INV103 vs INV105 — see [[wm-5z3pjt]].)
3. PII: the loan file carries full name, DOB, SSN (twice), address, phone, email. No Oliv
   feed carries PII today (northpond.py has pii_columns={}). Compliance call needed.
4. Add the Oliv loan number (OLV...) to the transaction file so it stands alone — today the
   transaction file keys on the Nelnet 12-digit number only.
5. CSV rather than XLSX for transactions (whole northpond pipeline ingests CSV).
6. Confirm cadence, SFTP path and a stable filename pattern.
7. Clarify NonCash='Non-Cash' appearing on PAYMENT rows.
8. Fidelity downgrade to flag: no TransactionId (no dedup key), no ReversalIndicator/Reason,
   no RemittedDate, and only 3 coarse transaction types vs the FCC SourceCode/TransactionCode
   taxonomy. Also no FICO and no charge-off/recovery fields visible in the sample.
9. Path nesting: Nate proposed `nelnet/daily_loan/YYYY/MM` and `nelnet/daily_transaction/YYYY/MM`,
   but every northpond parsing rule is anchored at `s3://.*/statements/northpond/...`. Ask to
   nest under `statements/northpond/nelnet/...` or we extend the sync + rule prefixes.

Caveat Nate already flagged: the samples are 1:1 forwards of raw Nelnet files, so asks 3-5
require Oliv to build a transform step, not just relay. He is queuing the task regardless.

## Log
- 2026-08-12T13:09Z [claude-code] Nelnet files are already landing in prod S3 and are unparsed. s3://efp-raw/statements/northpond/nelnet/ has two feeds, both daily: daily_loan/YYYY/MM/VELOCITY_SERVICING_DF2_YYYYMMDD_YYYYMMDD_HHMMSS. (pipe-delimited, headerless, H|MM/DD/YYYY|servicing.pgp control row, key ends in a bare '.') and daily_transaction/YYYY/MM/V_Transaction_Detail_Export_Daily_OlivFinancial_*.xlsx (single sheet NSTTRANDETDLY, 18 cols: Lender Name, Investor Number, Borrower Number, Loan Number, Last Name, Loan Program, Transaction Type, NonCash, Eff Date, Rpt Date, Tran Amt, Principal, Int Amt, Int Paid, LF Amt, LF Paid, OF Amt, OF Paid). 26 files sit at status='unknown' in bronze.statement_files — no ParsingRule matches the nelnet/ prefix. Two things to flag to Nate: (1) both feeds carry Investor Number INV103 (EDGEX grantor trust), i.e. this is the fund-attribution source we do not have on the FFC tapes; (2) daily_transaction carries borrower Last Name — PII on a feed we have not scoped.
- 2026-08-12T13:30Z [claude-code] THIS MOVED A LOT ON 2026-08-12 AND IS NOW THE LIVE BLOCKER, not a stale reply.
Nate opened the DM (D0BAD46CT27) at 01:44 IST with 'hey do you have a minute to connect? we can huddle to save some time possibly', Abhishek agreed, and a Slack huddle followed. HUDDLES LEAVE NO TRANSCRIPT — what was decided in the call itself is unknown; only the typed messages before and after are on the record. Nate's stated agenda was 'purchase files -> nelnet loan file'.
NATE'S OPEN QUESTIONS, ALL STILL UNANSWERED (03:20-03:23 IST):
  - 'There's PII in the loan tape' + 'We're passing the full/raw file right now via sftp.'
  - 'We should decide if you'd prefer a subset... 1. Is the pii going to be a problem? 2. If it's not a basic csv is that a problem?'
  - 'Basically wondering if we should just create a simple csv for you after we've ingested — 1. Removes the formatting nuance 2. Removes the pii'
  - 'The schemas are completely different' (nelnet vs FCC)
ABHISHEK'S OWN PROMISE, the thing actually owed: 'I think we can not ingest pii in our system - I will confirm and get back' (03:24 IST). Earlier he had said 'you can ingest nulls or some placeholder in the pii columns'. So the reply Nate is waiting on is a PII-policy answer plus a format decision, and it decides whether we parse the raw pipe-delimited Velocity DF2 feed or take a clean CSV from Oliv instead — which would retire most of the parsing work this item was originally about.
NEW CONTEXT WORTH KEEPING: 'Macquarie' is 'a bank forward flow partner we're working to close imminently', and 'For Macquarie we are going to produce a very significantly skinny-ed down file' — a third file variant is coming. Nate also confirmed 'No all of our loans are in either the NN or FCC files (once onboarded)' and 'There can be a few day delay to get into the NN file but once there it's always there'.
CALL PENDING: Nate 03:29 'Happy to review more tmrw with you'; Abhishek 03:31 'Cool, lets discuss in detail in tomorrow's call'. Whether that call is 2026-08-12 or 2026-08-13 is not stated in the thread and is not resolvable from the record.
The PII question also touches the open inbox item [[wm-9kvv8c]] on whether Sentry EFP-ERRORS-AW events carry live applicant PII — same underlying 'what are we allowed to hold' policy, worth answering once.
- 2026-08-14T13:54Z [claude-code] CLOSING 2026-08-14 — the reply was made and every blocking ask on it has been resolved, mostly
between 2026-08-12 and 2026-08-14. Walking the nine asks in the body:

RESOLVED AT SOURCE, by Oliv agreeing to send PII-free named-column CSVs instead of raw Velocity
forwards (Nate, 2026-08-12 call; files delivered as samples 2026-08-13 22:35 IST):
  1. Velocity DF2 record layout — moot. The cleaned export has named columns, so the 333
     unnamed positional fields never have to be decoded.
  3. PII — Abhishek gave the policy answer he owed ("we can not ingest pii in our system"); Nate
     agreed to truncate at source. Go-forward is closed; the already-landed raw files are the
     remaining half and live on [[wm-8dy9jr]].
  5. CSV rather than XLSX — yes, both feeds become CSV.
  9. Path nesting — the files already land under s3://efp-raw/statements/northpond/nelnet/…,
     which is inside the prefix every northpond parsing rule is anchored on.

ANSWERED BY NATE in the 2026-08-13 21:32 IST huddle and the DM around it:
  2. Investor attribution — the loan file carries it; issuance_v2 additionally gained
     `servicer_loan_number` and `issuance_date`, deployed 2026-08-14 00:33 IST.
  4. Oliv loan number on the transaction file — declined as a new column, satisfied instead via
     loan.loan_external_reference ("OLV123…") and the issuance_v2 bridge. Detail on [[wm-8a5pwn]].
  6. Cadence, path and filename pattern — locked 2026-08-14:
     nelnet/daily_loan/YYYY/MM/olivfinancial_loan_YYYYMMDD.csv and
     nelnet/daily_transaction/YYYY/MM/olivfinancial_transaction_YYYYMMDD.csv, daily, single date
     token = as-of date. Detail on [[wm-gj5tkx]].

NEVER ANSWERED, and I am closing this item without them rather than pretending otherwise:
  7. Why NonCash='Non-Cash' appears on PAYMENT rows.
  8. The fidelity downgrade versus the FCC feed — no TransactionId (so no dedup key), no
     ReversalIndicator/Reason, no RemittedDate, three coarse transaction types instead of the
     FCC SourceCode/TransactionCode taxonomy, no FICO.
Neither blocks the cutover, but 8 is a real reconciliation risk once both feeds run side by side.
They are worth raising with Nate in the "work through some of the one-off events over the next
week" window he offered on 2026-08-13. Not carried into a new item — raise if wanted.
