---
id: wm-73zk9s
type: task
title: Review Scott's PR #6802 (DEV-1850): Nelnet payment FUND resolved at EFFDATE
status: active
priority: high
tags: [northpond, pr-review]
created: 2026-09-15T10:10:04Z
updated: 2026-09-15T13:57:49Z
source: claude-code
effort: <1h
next: Abhishek posts the review; then follow-up items for the FCC leg + service-fee rows if he agrees
---

## Log
- 2026-09-15T10:10Z [claude-code] Reviewed at head 9e2e275. Prod check (2026-09-15): fix flips 34 nelnet rows edgex→balancesheet — 14 rows/$76.58 are the real bug (EFFDATE = purchase date − 1, currently failing the DQ rule), 20 rows/$811.64 are EFFDATE = purchase date (DQ rule neutral, boundary is inclusive both sides; issuance_v2 snapshot on tape day still says 'oliv'). Aug 11-14 batch resolves the same boundary to EDGEX via the earliest-investor arm, so settlement-day attribution is inconsistent. EFFDATE never blank in prod (0/2256). Alert stays red after merge: 231 FCC-leg rows (same defect, 2025 efhyf) + 680 service-fee rows. Draft comments handed to Abhishek; he posts.
- 2026-09-15T13:57Z [claude-code] Slack re-read: the day-of-transfer flip was agreed with Nate 2026-08-13 02:46 IST ('exact fund on the day of transfer'); 08-14..08-21 honoured it, 08-25+ lags by a day. Abhishek sent the purchase-day-payment question to Nate 2026-09-15 19:04 IST. Also: silver's 08-13 issuance_v2 is the first of two deliveries (no investor cols); raw 19:37 UTC re-delivery has them — needs re-parse. Notes updated (nate-and-oliv.md + meta).
