---
id: wm-3sxcre
type: task
title: NorthPond data quality, mappings and reporting
status: active
size: xl
people: [Abhijeet]
tags: [northpond, data-quality, reporting]
links: [parent:wm-j523sq]
created: 2026-08-14T19:56:57Z
updated: 2026-08-24T21:05:55Z
source: claude-code
label: NorthPond DQ + reporting
---

Third and last of the Oliv/NorthPond threads, created 2026-08-15 when Abhishek asked for the work
to be clubbed into two or three threads. The other two are deal-driven and error-driven; this one
is everything else — the steady-state correctness and reporting work that has no external date and
no partner waiting on it.

It is deliberately a QUEUE, not a checklist. Nothing in here blocks anything else in here, and
saying otherwise would make the chain view lie. What it does have is two natural clusters:

MAPPING AND BACKFILL CORRECTNESS — silver columns that are wrong, null or derived from the wrong
source. The status_at_purchase nulls, the ACCOUNT_ID derived from the raw tape instead of the
fund, the FULLY_PAID_DATE mapping, the cfframe capture gap going back to Feb/Mar 2025, and the
markup/exposure/purchase_year semantics question. These are the ones that quietly corrupt
downstream reporting, and they are the half worth doing first.

REPORTING SURFACES — the EF-vs-Oliv prediction comparison dashboard, the Fund Monitoring
integration, the fund-returns panel that copies FPM's JV-keyed query where efhyf has no FUND_KEY,
and the 'only unverified' filter on the comparison board. Plus the Linear restructure to split
v1/v2 model reporting out of the deprecation milestone.

Sitting here too: enabling CMOP + BEP for NorthPond, which is the counterpart of the OpenRoad work
and was confirmed outstanding on both platforms in the 2026-07-29 exchange with Abhijeet.

## Next steps
- Pick from the mapping/backfill cluster first — those affect numbers other people read.
- The two backfills (status_at_purchase nulls, ACCOUNT_ID) are the cheapest and the most directly
  wrong.

## Links
- Project: [[wm-j523sq]]
- Sibling threads: [[wm-d7m3xz]] (EDGEX deal) and [[wm-d3qnqe]] (Oliv error surface)

## Log
- 2026-08-20T20:48Z [claude-code] 2026-08-20 Linear tidy-up landed (the [P1] LINEAR-PROJECTS work): DEV-1486 Deprecate OpenRoad Datastores -> Done; DEV-1474, DEV-1468, DEV-1452, DEV-1627, DEV-1290 -> Done; DEV-1565 and DEV-1511 -> Duplicate. Still open: DEV-1396 (Backlog, closing comment drafted but NOT pasted), DEV-1539 (Todo, draft PR #6413), DEV-1516 (In Progress, PR #6401), DEV-1522 (In Progress, PR #6390), DEV-970 (In Review but PR #6223 is CHANGES_REQUESTED).
- 2026-08-24T21:05Z [claude-code] 2026-08-25: DEV-1498 (NorthPond CMOP/BEP + the northpond slice of silver.api_credit_attributes) is implemented and committed on branch abhishek/dev-1498-setup-northpond-cmopbep-and — full detail on [[wm-79k8df]]. Parity gate passed bit-identically on every eligible loan. Not pushed yet, and the PROD backfill of the credit-attributes slice must run before the predictions cron picks up the two new channels.
