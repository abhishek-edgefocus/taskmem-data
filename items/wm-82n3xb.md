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
updated: 2026-08-31T21:11:12Z
source: claude-code
estimate: 15m
next: Nate is making the change next week; until then re-trigger statements_northpond after the issuance files land (~10:20), or land #6394 and stop needing to.
---

## Log
- 2026-08-20T20:31Z [claude-code] Ask drafted 2026-08-20. The request must name the files explicitly: Nate's last reply landed in the thread on the OLD 2026-08-13 issuance message rather than the current one, so an unqualified 'issuance file' is ambiguous — there are two (issuance_v2_YYYYMMDD.csv and the v1 issuance_YYYYMMDD.csv). The one that matters is issuance_v2, since current_investor/intended_investor (added 2026-08-13) are what stamp FUND. The file it needs to precede is the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv. Observed gap: tape lands ~4.5h before issuance_v2, which is the race behind wm-39q8fh. Abhishek's preference is reorder (issuance first), not merely a smaller gap, and he asked to send it without stating the reason.
- 2026-08-20T20:32Z [claude-code] CORRECTION from Abhishek 2026-08-20: the ask covers BOTH issuance files, not just v2. We consume both — issuance_v2_YYYYMMDD.csv for the investor columns that stamp FUND, and the v1 issuance_YYYYMMDD.csv which stays authoritative for loan/borrower attributes (STATE, INCOME, ORIGINATION_FEE_PCT, FIRST_PAYMENT_DUE_DATE). The request to Nate is that both land before the daily Nelnet loan tape olivfinancial_loan_YYYYMMDD.csv, superseding the v2-only framing in the entry above.
- 2026-08-20T20:46Z [claude-code] NATE AGREED 2026-08-21 01:55-02:08 IST in the DM (D0BAD46CT27, thread 1787255159.247399). He asked 'which issuance files might you be referring to?', Abhishek named issuance_YYYYMMDD.csv + issuance_v2_YYYYMMDD.csv, and Nate replied 'I can get this for next week if that's aoky'. Two useful facts from him: 'the issuance files do not require/depend on the loan tape at all' (so the hold-the-tape alternative is unnecessary - a straight reorder works), and 'we definitely have some flexibility in timing, at least for internal system files'. ABHISHEK COMMITTED IN THE THREAD: 'till then I will re-trigger the pipeline whenever the issuance file lands' - a daily manual re-trigger until Oliv's change lands next week. Landing PR #6394 removes the need for that chore entirely.
- 2026-08-21T22:19Z [claude-code] COMMITMENT DISCHARGED 2026-08-22: Abhishek told Nate he would re-trigger the pipeline daily whenever the issuance file lands, until Oliv reorders next week. PR #6394 merged 2026-08-21 and its prod run repaired the stranding (see wm-39q8fh) — 08-19 now reads 200 not 154, and 08-20/08-21 track correctly with no manual re-trigger. The daily chore is no longer needed. Nate's reorder is still worth having as the durable fix, but nothing is required over the weekend.
- 2026-08-31T21:11Z [claude-code] 2026-09-01 measured against PROD: the transfers mislabel is live and wider than recorded. silver.transfers Aug 2026 = 265 loans -> edgex20261NN at markup 0.985 ($672,697.23) vs 160 loans -> efhyf at markup 1.0 ($438,199.41). The wrong fund is ALSO stamped on silver.northpond_stmt_purchase_tapes for the 08-24..08-31 as-of dates (31/28/40/23/19/19 = the same 160 loans), so queries taking EDGEX membership from the purchase-tape table are short too, not just transfers. Blast radius confirmed: the 141 edgex20261NN loans with NULL PRINCIPAL_AT_PURCHASE overlap the mislabelled set 141/141. Note this item's framing (issuance_v2 landing before the tape) only explains the 31 loans on 08-24; for 08-25 onward issuance loaded 2h BEFORE the tape and still said current_investor=oliv, so the real fix is to read intended_investor for a purchase event and stop the fallback returning a real-but-wrong fund. Full write-up: ~/notes/areas/efp/platforms/northpond/incidents.md#i1
