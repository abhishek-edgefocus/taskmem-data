---
id: wm-73zk9s
type: task
title: Review Scott's PR #6802 (DEV-1850): Nelnet payment FUND resolved at EFFDATE
status: active
priority: high
tags: [northpond, pr-review]
created: 2026-09-15T10:10:04Z
updated: 2026-09-15T10:10:13Z
source: claude-code
effort: <1h
---

## Log
- 2026-09-15T10:10Z [claude-code] Reviewed at head 9e2e275. Prod check (2026-09-15): fix flips 34 nelnet rows edgex→balancesheet — 14 rows/$76.58 are the real bug (EFFDATE = purchase date − 1, currently failing the DQ rule), 20 rows/$811.64 are EFFDATE = purchase date (DQ rule neutral, boundary is inclusive both sides; issuance_v2 snapshot on tape day still says 'oliv'). Aug 11-14 batch resolves the same boundary to EDGEX via the earliest-investor arm, so settlement-day attribution is inconsistent. EFFDATE never blank in prod (0/2256). Alert stays red after merge: 231 FCC-leg rows (same defect, 2025 efhyf) + 680 service-fee rows. Draft comments handed to Abhishek; he posts.
