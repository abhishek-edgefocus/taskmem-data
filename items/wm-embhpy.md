---
id: wm-embhpy
type: followup
title: Await Nate's final Oliv loan-file schema + confirm purchase-tape schema
status: next
priority: p1
people: [Nate]
tags: [northpond]
links: [parent:wm-j523sq, follows:wm-3gqqxr]
refs: [slack=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784320007718879]
created: 2026-07-20T22:42:18Z
updated: 2026-07-23T10:33:08Z
source: claude-code
label: Oliv schema proposal
---

Nate (Oliv) in the "Oliv EF Scores" group DM, 2026-07-20 22:44 IST, replying to Abhishek's launch-integration response: (1) confirmed the shared file is the ~issuance file; (2) will finalize some column changes and send a FINAL proposal to confirm the schema; (3) will send the current purchase-tape schema "tomorrow" (~2026-07-21). Open loop: Abhishek flagged that clarity_credit_risk_score was renamed to _score2 and clarity_bank_behavior_score / clarity_fraud_insight_score were dropped from the sample — those populate ~99% of records today and feed the at-origination feature set, so they'd silently go empty; need Nate to confirm whether that drop is intentional.

## Next steps
1. When Nate sends the final loan-file schema, confirm the clarity-score changes are intentional (or push back — at-origination features depend on them).
2. Get the current purchase-tape schema from Nate (last received was Pool 6, June 2025) and reconcile before launch.

## Links
- Oliv EF Scores DM: https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784320007718879

## Log
- 2026-07-21T09:05Z [claude-code] Nate replied in the group DM 2026-07-20 22:44 IST (ts 1784567693.159499), answering all three points: (1) confirmed the file we reviewed IS the issuance file; (2) he is finalizing changes and will send a FINAL schema proposal for us to confirm — he had some done while generating the sample but stopped as it was a secondary objective; (3) 'we will get you one tomorrow, no problem' re the purchase tape — i.e. due TODAY 2026-07-21. Still waiting on Nate; nudge moved to today since his own commitment lands today.
- 2026-07-21T12:20Z [claude-code] 2026-07-21, from the raw 2026-07-16 call transcript (full log on wm-qjkp3x): the purchase-tape question in step 2 of this item was already partly settled on that call — Nate agreed purchase files for securitization WILL carry ANL + CGL + model score for originated loans, while explicitly declining to add full monthly curves to them for now ("I won't plan on updating any purchase tapes with curves at this time"). So what is still genuinely outstanding from Nate is the CURRENT SCHEMA of that file (last received Pool 6, June 2025), not whether the fields will be there. Also unaddressed anywhere on the call: BACKFILL — the daily loan-file change was described as go-forward only, and nothing covers loans already originated, which EDGEX needs. Add that to the nudge.
- 2026-07-21T12:23Z [claude-code] 2026-07-21: nudge content refined after reading the 2026-07-16 call transcript. Only TWO things are genuinely still owed by Nate: (1) the CURRENT purchase-file schema (last received Pool 6, June 2025) — he promised it 2026-07-21; (2) BACKFILL — whether anything covers loans already originated, since the daily loan-file change was described as go-forward only and EDGEX needs the existing book. Cadence, refresh behaviour, curve shape and the 1.82/1.36 constants are all ANSWERED on the call and should NOT be re-asked. The clarity-score confirmation (score2 rename + the two dropped columns) remains open and unaffected.
- 2026-07-21T12:39Z [claude-code] RECONCILIATION 2026-07-21 (transcript + notes + Slack cross-check, requested by Abhishek). Nate's last message anywhere is 2026-07-20 22:44 IST — verified via channel read of C0BJ1M304BU and a from:<@U0AU8TU03HU> after:2026-07-19 search. BOTH of his commitments are now OVERDUE: (a) the FINAL loan-file schema proposal, (b) the current purchase-tape schema, which he said we would get 'tomorrow' = today 2026-07-21. Last purchase file we hold remains Pool 6, June 2025.

CLARITY QUESTION STILL UNANSWERED: Nate's 07-20 reply addressed points 1 (yes, it is the issuance file) and 3 (purchase tape coming), but never answered point 2 — whether the clarity_credit_risk_score -> _score2 rename and the DROP of clarity_bank_behavior_score / clarity_fraud_insight_score are intentional. Those are ~99% populated and feed the at-origination feature set. Must be re-asked explicitly, not assumed folded into his 'final proposal'.

BACKFILL still never raised with anyone, on the call or in Slack. Daily-file change is go-forward only; EDGEX needs already-originated loans.

CONFIRMED and NOT to be re-asked: file identity (daily issuance file, not the positions/loan tape); columns iccm_score/cgl/anl appended to a file we already receive, no new feed; portfolio-wide coverage incl. Macquarie; at-origination values never refreshed; 1.82*iccm=cgl, cgl/1.36=anl; one static unit loss curve rescaled by terminal CGL; flat 20% CPR; all loans 36-month; purchase tape WILL carry ANL+CGL+score but NOT monthly curves; our ingestion is clear for him to change columns. Nate's worked example (sample_loan_file.csv + monthly_curves.xlsx, 07-18) is DELIVERED — that action item is closed.
- 2026-07-21T17:38Z [claude-code] PRIORITY RAISED 2026-07-21. The modelling method was settled today (wm-j2prpv): we retarget our own OP curves by k = anl_oliv/anl_ours per loan. That makes one of the pending Nate questions CRITICAL PATH rather than a clarification:

*** What is inside the 1.36? *** If Nate's ANL carries no recovery assumption (cgl/1.36 is arithmetically consistent with 1.36 being a pure WAL divisor for a 36-month amortising loan at 20% CPR — i.e. their 'net' loss may actually be gross), then dividing OUR net-of-recovery ANL into THEIR gross-basis ANL biases k upward and we systematically inflate losses across the whole EDGEX book. Must be answered before the retarget is coded, not after.

Second, lower-priority modelling question for the same message: is the unit loss curve on default timing or charge-off timing.

The three delivery items (final loan-file schema, current purchase-tape schema, backfill) are unchanged and still overdue — Nate has sent nothing since 2026-07-20 22:44 IST.
