---
id: wm-hbujve
type: task
title: Ask Nate for the remaining 2026-08-04 Oliv files (payment_configuration copy-forward, transaction_boards needs real data)
status: blocked
priority: normal
size: ~15m
due: 2026-08-21
tags: [northpond, oliv, nate, statements]
created: 2026-08-19T19:37:08Z
updated: 2026-08-19T22:21:07Z
source: claude-code
---

Follow-up to the 2026-08-04 Oliv file gap. On 2026-08-13 Abhishek asked Nate
only about `issuance_20260804.csv`; Nate fixed it by copying 2026-08-03's file
and relabelling it as 08-04 ("doing as-of is harder than copy/paste"), and
confirmed done. That closed the issuance gap but NOT the other two files that
also never landed that day.

Still flagged missing in PROD.gold.statement_files_missing as of 2026-08-19:
  northpond / transaction_boards     2026-08-04
  northpond / payment_configuration  2026-08-04

## The copy/paste fix is only safe for two of the three (verified)

| file | semantics | copy 08-03 -> 08-04? |
|---|---|---|
| issuance | full cumulative snapshot (re-sends whole loan universe daily) | SAFE — already done |
| payment_configuration | full cumulative daily re-send, row counts track issuance day-for-day | SAFE |
| transaction_boards | TRUE DELTA — each txn reported exactly once, on the day it happened | UNSAFE |

Evidence:
- silver.northpond_stmt_issuance as_of 2026-08-04 = 931 rows / 931 loans,
  byte-identical count to 08-03 (confirms the copy landed); 08-05 jumps to 959.
- silver.northpond_stmt_transaction_boards: 18,566 rows all-time = 18,566
  distinct TRANSACTIONNUMBER. Zero repeats across dates, ever. The transform
  (stmt_transaction_boards.py) dedups on TRANSACTIONNUMBER alone, no date,
  with a comment saying that key alone identifies a row.
- payment_configuration per-day row/loan counts mirror issuance's trajectory
  (865, 869, 873, 879...), avg 282.3 dates per loan vs issuance's 282.9.

Why copy/relabel breaks transaction_boards: the load path is delete_and_insert
scoped per as_of_date, so nothing dedups across dates. 08-03's transactions
would be inserted a SECOND time under 08-04 (double count), and the real 08-04
transactions are lost permanently — this feed never re-sends a transaction on a
later day.

## Mitigating context (why this is not urgent)
transaction_boards and payment_configuration currently have ZERO downstream
consumers (both dead ends per the northpond findings doc). So the duplicate
would not move any live metric today. It would corrupt the raw silver record,
which bites whenever someone wires this feed into transactions/transactions_itd
— already a to-do in that same doc.

## Ask
Draft prepared for Nate: copy-forward is fine for payment_configuration; for
transaction_boards request the REAL 08-04 file, or consciously accept the gap
rather than papering over it with 08-03's data.

## Log
- 2026-08-19T20:16Z [claude-code] Abhishek sent the ask to Nate in Slack (2026-08-20). Now waiting on his reply. Pre-agreed stance for the response: payment_configuration_20260804 may be copy-forwarded, transaction_boards_20260804 must be the real 8/4 file.
- 2026-08-19T22:06Z [claude-code] Nate replied 2026-08-20: 'these are FCC(?) files' + 'to follow up'. He is questioning ownership — believes transaction_boards/payment_configuration may come from FCC rather than Oliv. Needs an answer from our side; the evidence is already in this item's body.
- 2026-08-19T22:14Z [claude-code] 2026-08-20 huddle with Nate (DM D0BAD46CT27, 03:22-03:33 IST, AI notes F0BRFFLN2F3): Abhishek raised both missing files again. Nate's position on the call: a file may simply not be produced when there are no transactions; he opened the AWS account live and saw transaction_boards files for 2026-08-16 and 08-23(?) plus 'two files on the' date in question, said 'that is strange' and could not explain it, and took the action to look back through their side. Agreed outcome: Nate investigates and reports the backfill status for BOTH files by 2026-08-20 (he may check the same night). Abhishek explicitly de-prioritised it on the call ('FCC ones are not in EDGEX, so not super high priority') while asking that it still get patched up. Nate did NOT repeat the 'these are FCC files' ownership challenge on the huddle.
- 2026-08-19T22:21Z [claude-code] Asked Nate in the 1:1 DM (D0BAD46CT27) about the two remaining 2026-08-04 files — deliberately stated the problem only, no proposed fix. Nate will look at it later today US time or tomorrow. Resuming 2026-08-21.
