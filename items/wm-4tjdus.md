---
id: wm-4tjdus
type: question
title: Ask Nate to keep application_uuid on purchase file v1 before v0 is retired
status: open
created: 2026-08-14T20:09:49Z
updated: 2026-08-14T20:09:49Z
source: claude-code
---

Purchase file v1 is not a superset of v0. It renames most of what silver reads (loan_id -> oliv_loan_number, vantage_score -> vantage_score_v4, dti_ratio -> post_dti, interest_rate -> annual_interest, is_home_owner -> homeowner, dpd -> days_past_due, and the two amount columns) and DROPS application_uuid, prism_cash_score, employment_tenure, borrower_income_annual and remaining_term.

application_uuid is silver.transfers.APPLICATION_ID and the join key into silver.northpond_{tu,exp}_offers, which supply IRR, MODEL_VERSION, credit_grade, credit_grade_version and application_channel on silver.positions. Losing it silently NULLs all of them for every EDGEX loan.

Live rather than hypothetical: Nate said on 2026-08-11 "the v0 logic is outdated... actually I got it, we'll sync it up to v1", so the stated intent is convergence on v1. Today only v0 is ingested; v1 is ignore=True in the bronze parsing rules.

Ask: either keep application_uuid on v1, or agree the offers join moves to oliv_loan_number via issuance_v2 before v0 is retired.

Headers verified 2026-08-15 against the 2026-08-11 files Nate posted (v0 F0BPEAE3T61, v1 F0BPBL1MCBV). Written up in ~/notes/northpond/04-findings.md (finding #1).
