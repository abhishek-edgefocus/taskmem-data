---
id: wm-dfec2v
type: followup
title: Answer Eshan's Oliv file-cadence question in #platform-data-owners (PR #6306 thread)
status: next
priority: p1
size: xs
due: 2026-08-17
people: [Eshan, Kabeer]
tags: [northpond, edgex]
links: [relates:wm-gj5tkx, parent:wm-d7m3xz]
created: 2026-08-17T09:54:13Z
updated: 2026-08-17T09:54:19Z
source: claude-code
---

Eshan asked in the #platform-data-owners PR #6306 thread (C0B6M0AQKB5, parent ts 1786784577.793839, his msg ts 1786838096.651199, 2026-08-16 05:24 IST):
"When do we get the issuance tape? What I want to confirm is that what's the first time we know that we are going to have these loans with us. Purchase tapes are generally pretty close to day we get positions files. It's not about ingesting the positions that have been delayed but understanding on regular flow what files do we get and when."

Context: he is looking for the Oliv analogue of Upgrade's allocation tape (which arrives 3-4 days before the purchase tape). Kabeer's PR #6306 (now MERGED) excluded northpond from to-be-purchased on the stated rationale "loans are in positions from day one under northpond_balancesheet; fund entry is a same-day purchase-tape relabel. No window exists."

## Answer measured 2026-08-17 (S3 + the 4 real purchase files)
The issuance file IS the lead indicator, so the PR's "no window exists" line does not hold.

Four daily Oliv feeds under s3://efp-raw/statements/northpond/:
- `issuance/YYYY/MM/issuance_YYYYMMDD.csv` - daily incl weekends, lands ~16:37 UTC
- `purchase_file/v0/YYYY/MM/purchase_file_v0_YYYYMMDD.csv` - WEEKDAYS ONLY, ~13:38 UTC
- `nelnet/daily_loan/` VELOCITY_SERVICING_DF2_* - daily incl weekends, ~12:37 UTC
- `nelnet/daily_transaction/` V_Transaction_Detail_Export_*.xlsx - daily incl weekends, ~12:37 UTC

All 113 loans across the 4 real purchase files (08-11..08-14) appeared in the issuance file FIRST, lead 1-4 days (per-file medians 4 / 3 / 2 / 2).
Precision since Oliv actually started selling to us: of loans first issued 2026-08-07..08-12, 113 of 114 were purchased = 99.1%. Loans first issued 08-01..08-06 (56 of them) were never purchased - pre-EDGEX-purchasing era, so do not quote the naive 67.7% all-August hit rate.
Join key: issuance `loan_id` is bare numeric (12563552), purchase tape is OLV-prefixed (OLV12563552).

CAVEAT to state plainly: the issuance file carries NO investor/fund tag. Header is application_uuid, loan_id, amount_financed, origination_fee, apr, interest_rate, first_payment_due_date, state, annual_gross_income, backstop_ach, clarity_credit_risk_score, clarity_bank_behavior_score, clarity_fraud_insight_score, prism_cash_score, prism_first_detect_score, argyle_hire_date, highline_hire_date. So it predicts THAT a loan is coming, not WHICH fund (INV103 vs INV105) - that still needs the Nelnet loan file's investor tag, see [[wm-gj5tkx]].

Analysis scripts: scratchpad lead.py / hitrate.py (session 10c34cf0).
Draft prepared 2026-08-17; Abhishek posts it, not the agent (no agent-initiated writes).
