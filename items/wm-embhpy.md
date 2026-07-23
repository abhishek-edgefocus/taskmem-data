---
id: wm-embhpy
type: followup
title: Await Nate's final Oliv loan-file schema + confirm purchase-tape schema
status: done
priority: p1
people: [Nate]
tags: [northpond]
links: [parent:wm-j523sq, follows:wm-3gqqxr]
refs: [slack=https://edgefocuspartners.slack.com/archives/C0BJ1M304BU/p1784320007718879]
created: 2026-07-20T22:42:18Z
updated: 2026-07-23T13:02:06Z
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
- 2026-07-23T10:33Z [claude-code] NATE DELIVERED 2026-07-22 (no longer waiting on him). 17:16 IST he confirmed the approach: existing issuance file/process stays UNTOUCHED; a SECOND file 'issuance_v2_{date}.csv' is generated at the same time, superset of loans, some columns dropped/added. He states issuance file + purchase tape together should contain everything, and explicitly asks (a) does that match our objective and (b) is anything missing from either. 20:58 IST he posted both samples: issuance_v2_20260722_example.csv (143.4 KB) and purchase_20260722_example.csv (886 B). BALL IS NOW ON ABHISHEK — review both files and answer his two questions. STILL NEVER ASKED, and still critical path: the 1.36 net-vs-gross question (is Oliv's ANL net of recoveries or effectively gross) and whether the unit loss curve is on default timing or charge-off timing. Neither appears anywhere in the Oliv EF Scores group DM (C0BJ1M304BU); the 07-20 message asked only the 3 delivery/schema questions, which Nate answered.
- 2026-07-23T13:02Z [claude-code] DISCHARGED 2026-07-23 — both awaited deliverables arrived. Nate sent issuance_v2_20260722_example.csv + purchase_20260722_example.csv (2026-07-22 20:58 IST). BOTH ARE SCHEMA SAMPLES ONLY — Abhishek confirmed: do not infer coverage/population from their contents.

ISSUANCE_V2 SCHEMA (18 cols): application_uuid, oliv_loan_number, amount_financed, origination_fee, apr, interest_rate, first_payment_due_date, state, annual_gross_income, backstop_ach, credit_grade, clarity_credit_risk_score2, prism_cash_score, prism_first_detect_score, experian_cashflow_score, iccm_score, cgl, anl. KEY CHANGE: integer loan_id REPLACED by OLV-prefixed oliv_loan_number (same key as the purchase file). Clarity rename + 2 drops confirmed; v1 issuance is UNCHANGED and stays authoritative for all loan attributes. Scope decision: we read ONLY oliv_loan_number + application_uuid + iccm_score/cgl/anl. Shipped in PR #5993 (DEV-1468).

PURCHASE TAPE — SCHEMA HAS MOVED vs Pool 6 (June 2025, last received; 21 cols). New sample = 17 cols: 10 unchanged, 7 renamed (loan_id->oliv_loan_number, vantage_score->vantage_score_v4, is_home_owner->homeowner, dti_ratio->post_dti, dpd->days_past_due, accrued_interest_as_of_funding_date->accrued_interest_on_purchase_date, outstanding_principal_balance_as_of_funding_date->principal_on_purchase_date), 4 dropped (application_uuid, borrower_income_annual, prism_cash_score, employment_tenure). Also xlsx -> csv, and purchase_YYYYMMDD.csv matches NO existing parsing rule.

PROD VERIFICATION (2026-07-23, COMPUTE_WH_XS_PROD): purchase tape LOAN_ID is ALREADY OLV-prefixed (372/372) so Nate's OLV caution does NOT apply to the tape — only to issuance (bare int, 324,185 rows). stmt_positions LOANNUMBER also OLV; tape->positions join 372/372. silver.predictions EFP_ID = northpond_OLV12562547 (800 loans), confirming PR's 'northpond_' || OLIV_LOAN_NUMBER is correct. All 4 dropped cols currently 100% populated (372/372).
COLUMN CONSUMPTION (code-verified): application_uuid used ONCE (transfers.py:138 -> APPLICATION_ID); borrower_income_annual / prism_cash_score / employment_tenure / dti_ratio NEVER read from the purchase tape (positions.py's PRISM_CASH_SCORE reads the ISSUANCE copy via alias ifs). prism_cash_score + application_uuid + AGI all present on issuance (853/853 on 2026-07-22); EMPLOYMENT_TENURE exists ONLY on the purchase tape — no issuance equivalent.
FALLBACK PROVEN: all 372 tape loans resolve to an application_uuid via issuance on loan number, 372/372 UUIDs match, 0 conflicts; uuid unique per loan (855 loans, 0 multi). So dropping application_uuid from the tape is recoverable — provided issuance keeps it.

NATE 2026-07-23 17:16 IST: (1) will keep dropping issuance_v2 at the existing location; asked whether we copy from their SFTP (yes — we pull hourly to EFS then S3, structure preserved; their SFTP path is issuance/YYYY/MM/, host sftp-public-prod.olivfinancial.com user edgefocus per .env.example, secrets in Secrets Manager northpond_sftp_*); (2) offers to generate BOTH a standardized purchase file AND a secondary copy in our legacy format to the existing SFTP. We accepted 2a.
STILL OPEN: Nate to confirm AGI == borrower_income_annual; whether principal_on_purchase_date is a basis change vs outstanding_principal_balance_as_of_funding_date (feeds TAPE_PRINCIPAL/TAPE_PRICE); Trishit to say if employment_tenure is needed for modelling; and a real issuance_v2 file to validate ingestion end to end (asked twice, unanswered).
