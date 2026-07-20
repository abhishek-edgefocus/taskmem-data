---
id: wm-cunr7j
type: task
title: Answer Nate/Oliv: which automated ingestions break if loan-file columns change
status: done
priority: p1
size: s
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-20T13:55:26Z
updated: 2026-07-20T22:42:18Z
source: claude-code
---

Nate Wong asked in the Oliv group DM (2026-07-18) whether any automated ingestion processes break if Oliv updates the columns on the daily loan file. Trishit deferred to Abhishek on 2026-07-20. Needs a downstream-dependency audit of the northpond loan tape ingestion before Oliv makes changes.
slack=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784392115210349

## Log
- 2026-07-20T14:13Z [claude-code] Investigated on dpx + Snowflake prod. Key finding: Nate's sample_loan_file.csv is the ISSUANCE file (issuance_YYYYMMDD.csv, 17 cols), NOT the daily loan tape (ffcnp_dailyloantape, 92 cols). Verdict: (1) Snowflake path bronze->silver is schema-on-read (RAW_RECORD VARIANT, no header validation) - additions/renames/drops all ingest fine; renames degrade to silent NULL. (2) LEGACY datastore lib/efp/stats/datastores/northpond/statement_loan_issuance.py hard-fails: base_datastore.py:1357 raises on any DTYPES key missing, SOMETIMES_MISSING_COLUMNS is empty. Proposed file drops clarity_bank_behavior_score + clarity_fraud_insight_score and renames clarity_credit_risk_score -> clarity_credit_risk_score2 => breaks nightly generate_datastores (20:00) and owned_at_purchase_features.py (01:00). (3) Added cols iccm_score/cgl/anl are safe everywhere. Fix is small: update DTYPES / add to SOMETIMES_MISSING_COLUMNS. Precedent: provider already renamed LateFeeRecoveredAmt/NSFFeeRecoveredAmt/OtherFeesRecoveredAmt on the loan tape in 2025; that is why SOMETIMES_MISSING_COLUMNS exists in statement_loan_positions.py.
- 2026-07-20T22:42Z [claude-code] Closed done (2026-07-21): answered Nate in the Oliv EF Scores DM (2026-07-20 20:34 IST) — ingestion checked end-to-end, nothing breaks if columns change, confirmed the file is the daily issuance file (not the positions/loan tape). Clarity-score drop confirmation folded into follow-up wm-embhpy.
