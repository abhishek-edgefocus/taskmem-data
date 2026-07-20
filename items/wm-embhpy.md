---
id: wm-embhpy
type: followup
title: Await Nate's final Oliv loan-file schema + confirm purchase-tape schema
status: waiting
waiting_on: Nate
nudge: 2026-07-22
people: [Nate]
tags: [northpond]
created: 2026-07-20T22:42:18Z
updated: 2026-07-20T22:42:18Z
source: claude-code
label: Oliv schema proposal
---

Nate (Oliv) in the "Oliv EF Scores" group DM, 2026-07-20 22:44 IST, replying to Abhishek's launch-integration response: (1) confirmed the shared file is the ~issuance file; (2) will finalize some column changes and send a FINAL proposal to confirm the schema; (3) will send the current purchase-tape schema "tomorrow" (~2026-07-21). Open loop: Abhishek flagged that clarity_credit_risk_score was renamed to _score2 and clarity_bank_behavior_score / clarity_fraud_insight_score were dropped from the sample — those populate ~99% of records today and feed the at-origination feature set, so they'd silently go empty; need Nate to confirm whether that drop is intentional.

## Next steps
1. When Nate sends the final loan-file schema, confirm the clarity-score changes are intentional (or push back — at-origination features depend on them).
2. Get the current purchase-tape schema from Nate (last received was Pool 6, June 2025) and reconcile before launch.

## Links
- Oliv EF Scores DM: https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784320007718879
