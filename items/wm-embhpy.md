---
id: wm-embhpy
type: followup
title: Await Nate's final Oliv loan-file schema + confirm purchase-tape schema
status: waiting
waiting_on: Nate
nudge: 2026-07-21
people: [Nate]
tags: [northpond]
links: [parent:wm-j523sq, follows:wm-3gqqxr]
refs: [slack=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784320007718879]
created: 2026-07-20T22:42:18Z
updated: 2026-07-21T09:05:26Z
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
