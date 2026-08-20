---
id: wm-82n3xb
type: task
title: Ask Nate to land issuance_v2 before the daily Nelnet loan tape
status: next
priority: normal
people: [Nate]
tags: [northpond, edgex, oliv]
links: [relates:wm-39q8fh]
created: 2026-08-20T20:31:29Z
updated: 2026-08-20T20:32:30Z
source: claude-code
estimate: 15m
---

## Log
- 2026-08-20T20:31Z [claude-code] Ask drafted 2026-08-20. The request must name the files explicitly: Nate's last reply landed in the thread on the OLD 2026-08-13 issuance message rather than the current one, so an unqualified 'issuance file' is ambiguous — there are two (issuance_v2_YYYYMMDD.csv and the v1 issuance_YYYYMMDD.csv). The one that matters is issuance_v2, since current_investor/intended_investor (added 2026-08-13) are what stamp FUND. The file it needs to precede is the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv. Observed gap: tape lands ~4.5h before issuance_v2, which is the race behind wm-39q8fh. Abhishek's preference is reorder (issuance first), not merely a smaller gap, and he asked to send it without stating the reason.
- 2026-08-20T20:32Z [claude-code] CORRECTION from Abhishek 2026-08-20: the ask covers BOTH issuance files, not just v2. We consume both — issuance_v2_YYYYMMDD.csv for the investor columns that stamp FUND, and the v1 issuance_YYYYMMDD.csv which stays authoritative for loan/borrower attributes (STATE, INCOME, ORIGINATION_FEE_PCT, FIRST_PAYMENT_DUE_DATE). The request to Nate is that both land before the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv, superseding the v2-only framing in the entry above.
