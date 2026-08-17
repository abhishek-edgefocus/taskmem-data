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
updated: 2026-08-17T10:45:44Z
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

## Log
- 2026-08-17T10:13Z [claude-code] MEASURED PER-LOAN 2026-08-17, scoped to the EDGEX 2026-1NN loans only. PROD PROOF: PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES holds exactly 113 rows with PURCHASE_DATE >= 2026-01-01, across 4 dates (08-11:29, 08-12:50, 08-13:17, 08-14:17), all ACCOUNT_NAME=northpond_efhyf. NOTE the 08-11 batch of 29 still carries FUND='efhyf' (stale - written before PR #6209 merged 2026-08-11T21:48Z); 08-12/13/14 correctly carry FUND='edgex20261NN'. Rebuild tracked on [[wm-cqgb5n]]. By the date rule all 113 are EDGEX 2026-1NN. LEAD TIMES (issuance first-sighting -> purchase_date), all 113 matched in issuance, 0 unmatched, 0 clipped at the July-1 staging boundary: overall min=1 median=3 max=4 mean=2.8 days; distribution {1d:8, 2d:47, 3d:15, 4d:43}. Per file: 08-11 = 29 loans, 3-4d, first seen 08-07(27)/08-08(2), $63,700; 08-12 = 50 loans, 1-4d, first seen 08-08(16)/08-09(13)/08-10(17)/08-11(4), $126,800; 08-13 = 17 loans, 1-2d, first seen 08-11(13)/08-12(4), $45,800; 08-14 = 17 loans, all exactly 2d, first seen 08-12(17), $47,700. Total $284,000 across 113 loans. Per-loan CSV saved to ~/edgex_lead_detail.csv on the Mac. Scripts: scratchpad edgex_lead2.py (prod) + final.py (join); staged S3 copies under /tmp on dpx.
- 2026-08-17T10:45Z [claude-code] ISSUANCE_V2 INVESTOR COLUMNS — MEASURED 2026-08-17. issuance_v2 is LIVE, not planned: s3://efp-raw/statements/northpond/issuance_v2/YYYY/MM/issuance_v2_YYYYMMDD.csv, daily ~16:37 UTC, files back to 2026-08-01. 23 cols; the investor columns (loan_servicer, current_investor, intended_investor) plus oliv_loan_number/servicer_loan_number/issuance_date/experian_cashflow_score/iccm_score/cgl/anl are NOT in the v0 issuance file. COLUMN WENT LIVE 2026-08-13: 08-01..08-11 files have no investor columns at all; 08-12 has the columns but 0/1099 populated; 08-13 onward fully populated (edgex intended 227 -> 241 -> 264 -> 278 on 08-13/14/15/16). AS OF 08-16: current_investor edgex20261NN = 113 (exactly the purchase-tape count, ties out); intended_investor edgex20261NN = 278; 165 flagged-but-not-yet-current (forward pipeline); 0 loans bought WITHOUT a prior/simultaneous intended flag (no false negatives so far). LEAD TEST vs purchase_date is CONFOUNDED: all four purchase batches first show the flag on 2026-08-13, the day the column went live, so 08-11 batch reads -2d, 08-12 -1d, 08-13 0d. ONLY THE 08-14 BATCH IS A CLEAN OBSERVATION: 17 loans flagged intended=edgex on 08-13, purchased 08-14 = +1 day lead, and it is the only batch where intended leads current (the other three flip both columns the same day). CONCLUSION: exactly ONE clean day of evidence for a 1-day lead; we CANNOT yet claim intended_investor reliably leads the purchase tape. Re-run this test after ~2 weeks of populated files. WE DO NOT INGEST THESE COLUMNS: 'intended_investor'/'current_investor' return zero hits on efp master via gh search code (local checkout is stale on abhishek/dev-1393 from 2026-07-08, so the local grep is not authoritative, but both agree).
- 2026-08-17T10:45Z [claude-code] NO CONFIRMATION FROM OLIV ON EARLY VISIBILITY — evidence review 2026-08-17 (Nate DM D0BAD46CT27). Nobody has ever asked Oliv whether the issuance file carries a loan as early as possible, and Nate has never committed to it. Three things cut AGAINST relying on it: (1) NATE CANNOT SYSTEMATICALLY IDENTIFY BACKBOOK->EDGEX MOVES, 2026-08-13 02:32 IST ts 1786569148.405539: 'I know we will sell some of these loans that are currently northpond or oliv or efhyf to edgex, but I don't have the ability to actually list which ones in any systematic fashion' / 'so more when it happens, it happens', and ts 1786569183.800299 'what splitting current and intended will do is help bifurcate for ~forward flow, but it won't help with backbook cleanup'. So SECONDARY purchases get NO lead time by construction. (2) ABHISHEK EXPLICITLY TOLD NATE WE DO NOT NEED ADVANCE NOTICE, ts 1786569416.938459: 'As far as our data ingestion is concerned, we just need to know the current fund for a given loan on that date. We don't need to know it in advance, we are fine with knowing the exact fund on the day of transfer.' Oliv is currently building to THAT spec — it must be walked back explicitly now that Kabeer/Eshan want pre-purchase visibility. (3) THE ISSUANCE FILE IS NOT A RELIABLE POINT-IN-TIME RECORD: issuance_20260804.csv is BYTE-IDENTICAL to issuance_20260803.csv (both md5 d8b2fe56e7c812e8f95a9d7da86cbf5f), uploaded 9 days late on 2026-08-12, because Nate copy-pasted it on request — ts 1786568420.492749 'doing as-of is harder than copy/paste', and Abhishek agreed. Tagging logic Nate DID state, ts 1786564973.792759: '1. If it's predefined who the loan is for, we'll tag it regardless of sale 2. If it's been sold then it's tagged. 3. Else Oliv' — point 1 is the forward-looking basis, but it is unverified in data beyond the single 08-14 batch. Also relevant: Nate on the NN/positions file, ts 1786485535.727289, 'There can be a few day delay to get into the NN file but once there it's always there'. And the issuance file is derived in-house by Oliv (ts 1786628915.900029 'we completely derive in house'), unlike the servicer files, so they CAN change its timing/content.
