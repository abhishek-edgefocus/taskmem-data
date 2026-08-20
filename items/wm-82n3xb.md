---
id: wm-82n3xb
type: task
title: Ask Nate to land issuance_v2 before the daily Nelnet loan tape
status: blocked
priority: normal
due: 2026-08-28
people: [Nate]
tags: [northpond, edgex, oliv]
links: [relates:wm-39q8fh]
created: 2026-08-20T20:31:29Z
updated: 2026-08-20T20:46:37Z
source: claude-code
estimate: 15m
next: Nate is making the change next week; until then re-trigger statements_northpond after the issuance files land (~10:20), or land #6394 and stop needing to.
---

## Log
- 2026-08-20T20:31Z [claude-code] Ask drafted 2026-08-20. The request must name the files explicitly: Nate's last reply landed in the thread on the OLD 2026-08-13 issuance message rather than the current one, so an unqualified 'issuance file' is ambiguous — there are two (issuance_v2_YYYYMMDD.csv and the v1 issuance_YYYYMMDD.csv). The one that matters is issuance_v2, since current_investor/intended_investor (added 2026-08-13) are what stamp FUND. The file it needs to precede is the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv. Observed gap: tape lands ~4.5h before issuance_v2, which is the race behind wm-39q8fh. Abhishek's preference is reorder (issuance first), not merely a smaller gap, and he asked to send it without stating the reason.
- 2026-08-20T20:32Z [claude-code] CORRECTION from Abhishek 2026-08-20: the ask covers BOTH issuance files, not just v2. We consume both — issuance_v2_YYYYMMDD.csv for the investor columns that stamp FUND, and the v1 issuance_YYYYMMDD.csv which stays authoritative for loan/borrower attributes (STATE, INCOME, ORIGINATION_FEE_PCT, FIRST_PAYMENT_DUE_DATE). The request to Nate is that both land before the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv, superseding the v2-only framing in the entry above.
- 2026-08-20T20:46Z [claude-code] NATE AGREED 2026-08-21 01:55-02:08 IST in the DM (D0BAD46CT27, thread 1787255159.247399). He asked 'which issuance files might you be referring to?', Abhishek named issuance_YYYYMMDD.csv + issuance_v2_YYYYMMDD.csv, and Nate replied 'I can get this for next week if that's aoky'. Two useful facts from him: 'the issuance files do not require/depend on the loan tape at all' (so the hold-the-tape alternative is unnecessary - a straight reorder works), and 'we definitely have some flexibility in timing, at least for internal system files'. ABHISHEK COMMITTED IN THE THREAD: 'till then I will re-trigger the pipeline whenever the issuance file lands' - a daily manual re-trigger until Oliv's change lands next week. Landing PR #6394 removes the need for that chore entirely.
