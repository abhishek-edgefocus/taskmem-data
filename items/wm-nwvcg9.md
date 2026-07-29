---
id: wm-nwvcg9
type: followup
title: Reply to Nate with the Nelnet sample-file verdict + the blocking asks
status: open
priority: p1
size: xs
due: 2026-07-30
people: [Nate, Trishit]
tags: [northpond, edgex, needs-reply]
links: [relates:wm-gj5tkx, relates:wm-5z3pjt]
refs: [thread=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1785241457230439]
created: 2026-07-29T13:42:01Z
updated: 2026-07-29T13:42:01Z
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
