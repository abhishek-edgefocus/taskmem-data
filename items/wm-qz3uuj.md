---
id: wm-qz3uuj
type: followup
title: Review Scott's PR #6802 (DEV-1850): attribute Nelnet payments to the fund that owned the loan on the payment date
status: next
priority: p1
size: s
due: 2026-09-16
people: [scott]
tags: [needs-reply, northpond, oliv, nelnet, github, dqm]
links: [related:wm-gj5tkx, related:wm-7mtzka, parent:wm-j523sq]
refs: [PR=https://github.com/edgefocus/efp/pull/6802, DEV-1850=https://linear.app/edge-focus/review/dev-1850-attribute-nelnet-payments-to-the-fund-that-owned-the-loan-34166c55059d]
created: 2026-09-15T10:10:11Z
updated: 2026-09-21T11:03:08Z
source: github PR #6802 review request
label: Scott Nelnet payment fund PR
---

Scott opened PR #6802 on 2026-09-11 19:08Z and requested Abhishek's review on 2026-09-14 17:38Z (sole reviewer requested; no reviews yet). It fixes a DQM alert on the northpond rule `transactions-fund-matches-transfer-ownership` (Grafana dqprod4fb883e41daf449cb6): Nelnet payment rows took PLATFORM_TRANSACTION_DATE from EFFDATE but resolved FUND at AS_OF_DATE (the report date). EFFDATE lags the report by a day or two, so a payment that arrived while the loan was still on the Oliv balance sheet got credited to the buying fund when a purchase landed inside the lag. Both now read the payment date. Scott's body ends: "Needs backfill after merge."

This is squarely in the NorthPond/Nelnet ingestion Abhishek owns (wm-gj5tkx) and touches the same FUND-derivation ground as wm-7mtzka (silver.transactions ACCOUNT_ID derived from fund). Review it as the platform owner: does resolving FUND on EFFDATE agree with how silver.transfers dates the purchase, and what does the post-merge backfill look like (as_of_date: all, not a hand range).

## Next steps
1. Open https://github.com/edgefocus/efp/pull/6802 and read the diff against the Nelnet transactions transform.
2. Check in DEV_ABHISHEK that, for the loans behind the DQM alert, FUND at EFFDATE matches silver.transfers ownership on that date.
3. Approve or comment; note in the review that the backfill must run with as_of_date: all.
4. Capture the post-merge backfill as its own item once merged (Scott's PR body is the only place it is written down).

## Links
- PR https://github.com/edgefocus/efp/pull/6802
- Linear review https://linear.app/edge-focus/review/dev-1850-attribute-nelnet-payments-to-the-fund-that-owned-the-loan-34166c55059d
- DQM alert https://grafana.edgefocuspartners.com/d/dqprod4fb883e41daf449cb6/data-quality-e28094-validation-results-prod?var-platform=northpond&var-rule=transactions-fund-matches-transfer-ownership
- Related: wm-gj5tkx (Nelnet ingestion), wm-7mtzka (transactions ACCOUNT_ID from fund)

## Log
- 2026-09-21T11:03Z [claude-code] 2026-09-21 POST-MERGE VERIFICATION of the Nelnet FUND fix (#6836, merged 09-18 17:36Z, deployed 19:45Z in 82968900) — all three of Abhishek's checks pass in PROD:
1. DQM rule transactions-fund-matches-transfer-ownership, northpond: latest evaluation 2026-09-21 02:54 PASSED, VIOLATION_COUNT 0, 1,105 rows evaluated, phase post_insert, scope 09-14..09-21. Previous three evaluations (09-20) also 0. Note the rule evaluates a rolling 7-day window, so 0 is within that scope.
2. The new edge from #6836 exists and runs: watermark SILVER.NORTHPOND_STMT_PURCHASE_TAPES -> SILVER.TRANSACTIONS last processed 2026-09-21 02:51. NELNET_TRANSACTIONS -> TRANSACTIONS last 09-20 05:47.
3. Attribution over ALL Nelnet payment rows (not date-limited), EFFDATE vs tape PURCHASE_DATE:
     same-day as purchase   -> edgex20261NN            33 rows  1,522.32
     day-before purchase    -> northpond_balancesheet  23 rows  5,676.00
     earlier                -> northpond_balancesheet  12 rows  2,782.47
     after purchase         -> edgex20261NN          1307 rows 64,832.12
   Each relation maps to exactly ONE fund — no same-day rows in balancesheet, no day-before rows in edgex. That is Nate's 09-15 ruling (buyer owns purchase-day cash) implemented correctly, and it covers full history, so the backfill (or the reload_all first run) has landed.
This item and wm-73zk9s can move to done once Abhishek confirms; #6802 is CLOSED in favour of #6836.
